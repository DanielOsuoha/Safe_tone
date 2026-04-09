//
//  WebRTCClient.swift
//  SafeTone
//
//  Lower-level WebRTC boundary used by WebRTCCallEngine.
//

import Foundation
import WebRTC

enum WebRTCConnectionState: Equatable {
    case new
    case connecting
    case connected
    case disconnected
    case failed
    case closed
}

@MainActor
protocol WebRTCClientDelegate: AnyObject {
    func webRTCClient(_ client: any WebRTCClient, didGenerate description: WebRTCSessionDescriptionPayload)
    func webRTCClient(_ client: any WebRTCClient, didGenerate candidate: ICECandidatePayload)
    func webRTCClient(_ client: any WebRTCClient, didChangeConnectionState state: WebRTCConnectionState, callID: UUID)
}

protocol WebRTCClient: AnyObject {
    var delegate: (any WebRTCClientDelegate)? { get set }

    func startOutgoingCall(callID: UUID, participantID: String)
    func answerIncomingCall(callID: UUID, participantID: String)
    func applyRemoteDescription(_ payload: WebRTCSessionDescriptionPayload)
    func applyRemoteCandidate(_ payload: ICECandidatePayload)
    func setMuted(_ isMuted: Bool)
    func setSpeakerEnabled(_ isSpeakerEnabled: Bool)
    func tearDown()
}

final class NativeWebRTCClient: NSObject, WebRTCClient {
    weak var delegate: (any WebRTCClientDelegate)?

    private let factory: RTCPeerConnectionFactory
    private var peerConnection: RTCPeerConnection?
    private var audioTrack: RTCAudioTrack?
    private var currentCallID: UUID?
    private var currentParticipantID: String?

    override init() {
        RTCInitializeSSL()

        let encoderFactory = RTCDefaultVideoEncoderFactory()
        let decoderFactory = RTCDefaultVideoDecoderFactory()
        self.factory = RTCPeerConnectionFactory(encoderFactory: encoderFactory, decoderFactory: decoderFactory)

        super.init()
    }

    deinit {
        RTCCleanupSSL()
    }

    func startOutgoingCall(callID: UUID, participantID: String) {
        currentCallID = callID
        currentParticipantID = participantID
        preparePeerConnectionIfNeeded()
        createLocalAudioTrackIfNeeded()

        Task { @MainActor in
            delegate?.webRTCClient(self, didChangeConnectionState: .connecting, callID: callID)
        }

        makeOffer()
    }

    func answerIncomingCall(callID: UUID, participantID: String) {
        currentCallID = callID
        currentParticipantID = participantID
        preparePeerConnectionIfNeeded()
        createLocalAudioTrackIfNeeded()

        Task { @MainActor in
            delegate?.webRTCClient(self, didChangeConnectionState: .connecting, callID: callID)
        }
    }

    func applyRemoteDescription(_ payload: WebRTCSessionDescriptionPayload) {
        guard let peerConnection else { return }

        currentCallID = payload.callID
        currentParticipantID = payload.participantID

        let description = RTCSessionDescription(
            type: payload.type == .offer ? .offer : .answer,
            sdp: payload.sdp
        )

        peerConnection.setRemoteDescription(description) { [weak self] error in
            guard let self else { return }

            if let error {
                self.log("Failed to apply remote description: \(error.localizedDescription)")
                Task { @MainActor in
                    self.delegate?.webRTCClient(self, didChangeConnectionState: .failed, callID: payload.callID)
                }
                return
            }

            self.log("Applied remote \(payload.type.rawValue) for call \(payload.callID)")

            if payload.type == .offer {
                self.makeAnswer()
            } else {
                Task { @MainActor in
                    self.delegate?.webRTCClient(self, didChangeConnectionState: .connected, callID: payload.callID)
                }
            }
        }
    }

    func applyRemoteCandidate(_ payload: ICECandidatePayload) {
        guard let peerConnection else { return }

        let candidate = RTCIceCandidate(
            sdp: payload.candidate,
            sdpMLineIndex: payload.sdpMLineIndex ?? 0,
            sdpMid: payload.sdpMid
        )

        peerConnection.add(candidate)
        log("Applied remote ICE candidate for call \(payload.callID)")
    }

    func setMuted(_ isMuted: Bool) {
        audioTrack?.isEnabled = !isMuted
        log("Local WebRTC mute set to \(isMuted)")
    }

    func setSpeakerEnabled(_ isSpeakerEnabled: Bool) {
        let override: AVAudioSession.PortOverride = isSpeakerEnabled ? .speaker : .none

        do {
            try AVAudioSession.sharedInstance().overrideOutputAudioPort(override)
        } catch {
            log("Failed to set speaker output: \(error.localizedDescription)")
        }
    }

    func tearDown() {
        peerConnection?.close()
        peerConnection = nil
        audioTrack = nil
        currentCallID = nil
        currentParticipantID = nil
        log("Tearing down WebRTC session")
    }

    private func preparePeerConnectionIfNeeded() {
        guard peerConnection == nil else { return }

        let config = RTCConfiguration()
        config.sdpSemantics = .unifiedPlan
        config.iceServers = [
            RTCIceServer(urlStrings: ["stun:stun.l.google.com:19302"])
        ]

        let constraints = RTCMediaConstraints(
            mandatoryConstraints: nil,
            optionalConstraints: ["DtlsSrtpKeyAgreement": kRTCMediaConstraintsValueTrue]
        )

        peerConnection = factory.peerConnection(with: config, constraints: constraints, delegate: self)
    }

    private func createLocalAudioTrackIfNeeded() {
        guard audioTrack == nil, let peerConnection else { return }

        let constraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let source = factory.audioSource(with: constraints)
        let track = factory.audioTrack(with: source, trackId: "audio0")
        let streamId = currentCallID?.uuidString ?? "SafeToneStream"

        peerConnection.add(track, streamIds: [streamId])
        audioTrack = track
    }

    private func makeOffer() {
        guard let peerConnection else { return }

        let constraints = RTCMediaConstraints(
            mandatoryConstraints: [
                kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue
            ],
            optionalConstraints: nil
        )

        peerConnection.offer(for: constraints) { [weak self] description, error in
            guard let self, let description else {
                if let error {
                    self?.log("Failed to create offer: \(error.localizedDescription)")
                }
                return
            }

            self.setLocalDescriptionAndEmit(description)
        }
    }

    private func makeAnswer() {
        guard let peerConnection else { return }

        let constraints = RTCMediaConstraints(
            mandatoryConstraints: [
                kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue
            ],
            optionalConstraints: nil
        )

        peerConnection.answer(for: constraints) { [weak self] description, error in
            guard let self, let description else {
                if let error {
                    self?.log("Failed to create answer: \(error.localizedDescription)")
                }
                return
            }

            self.setLocalDescriptionAndEmit(description)
        }
    }

    private func setLocalDescriptionAndEmit(_ description: RTCSessionDescription) {
        guard let peerConnection, let callID = currentCallID, let participantID = currentParticipantID else { return }

        peerConnection.setLocalDescription(description) { [weak self] error in
            guard let self else { return }

            if let error {
                self.log("Failed to set local description: \(error.localizedDescription)")
                Task { @MainActor in
                    self.delegate?.webRTCClient(self, didChangeConnectionState: .failed, callID: callID)
                }
                return
            }

            let payload = WebRTCSessionDescriptionPayload(
                callID: callID,
                participantID: participantID,
                type: description.type == .offer ? .offer : .answer,
                sdp: description.sdp,
                sentAt: Date()
            )

            Task { @MainActor in
                self.delegate?.webRTCClient(self, didGenerate: payload)
            }
        }
    }

    private func map(_ state: RTCPeerConnectionState) -> WebRTCConnectionState {
        switch state {
        case .new:
            return .new
        case .connecting:
            return .connecting
        case .connected:
            return .connected
        case .disconnected:
            return .disconnected
        case .failed:
            return .failed
        case .closed:
            return .closed
        @unknown default:
            return .failed
        }
    }

    private func log(_ message: String) {
        print("[NativeWebRTCClient] \(message)")
    }
}

extension NativeWebRTCClient: RTCPeerConnectionDelegate {
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {}

    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        guard let callID = currentCallID, let participantID = currentParticipantID else { return }

        let payload = ICECandidatePayload(
            callID: callID,
            participantID: participantID,
            candidate: candidate.sdp,
            sdpMid: candidate.sdpMid,
            sdpMLineIndex: Int32(candidate.sdpMLineIndex),
            sentAt: Date()
        )

        Task { @MainActor in
            delegate?.webRTCClient(self, didGenerate: payload)
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {}

    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCPeerConnectionState) {
        guard let callID = currentCallID else { return }

        let mappedState = map(stateChanged)

        Task { @MainActor in
            delegate?.webRTCClient(self, didChangeConnectionState: mappedState, callID: callID)
        }
    }

    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd rtpReceiver: RTCRtpReceiver, streams: [RTCMediaStream]) {
        log("Received remote RTP receiver with \(streams.count) stream(s)")
    }
}

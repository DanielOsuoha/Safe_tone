//
//  WebRTCCallEngine.swift
//  SafeTone
//
//  Real-call engine skeleton that will own WebRTC negotiation and media transport.
//

import Foundation

final class WebRTCCallEngine: CallEngine {
    weak var delegate: (any CallEngineDelegate)?

    private let signalingClient: any SignalingClient
    private let audioSessionManager: AudioSessionManager
    private let webRTCClient: any WebRTCClient
    private let localParticipant = CallParticipant(
        id: "local-user",
        displayName: "You",
        handle: "local-user",
        role: .caller
    )

    private var activeCallID: UUID?
    private var remoteParticipant: CallParticipant?

    init(
        signalingClient: any SignalingClient,
        audioSessionManager: AudioSessionManager,
        webRTCClient: any WebRTCClient
    ) {
        self.signalingClient = signalingClient
        self.audioSessionManager = audioSessionManager
        self.webRTCClient = webRTCClient
        self.webRTCClient.delegate = self
    }

    func startOutgoingCall(callID: UUID, handle: String, displayName: String) {
        activeCallID = callID
        remoteParticipant = CallParticipant(
            id: handle,
            displayName: displayName,
            handle: handle,
            role: .callee
        )

        signalingClient.connect()
        signalingClient.send(
            .callInvite(
                CallInvitePayload(
                    callID: callID,
                    caller: localParticipant,
                    callee: remoteParticipant!,
                    createdAt: Date()
                )
            )
        )

        delegate?.callEngine(self, didChangeState: .ringing, for: callID)
        webRTCClient.startOutgoingCall(callID: callID, participantID: localParticipant.id)
        log("Started outgoing WebRTC call setup for \(displayName) [\(handle)]")
    }

    func answerIncomingCall(callID: UUID) {
        activeCallID = callID
        signalingClient.connect()
        signalingClient.send(
            .callAnswer(
                CallAnswerPayload(
                    callID: callID,
                    participantID: localParticipant.id,
                    answeredAt: Date()
                )
            )
        )
        audioSessionManager.activateCallAudio()
        webRTCClient.answerIncomingCall(callID: callID, participantID: localParticipant.id)
        log("Answering WebRTC call \(callID)")
    }

    func endCall(callID: UUID) {
        guard activeCallID == callID || activeCallID == nil else { return }

        signalingClient.send(
            .callEnd(
                CallEndPayload(
                    callID: callID,
                    participantID: localParticipant.id,
                    endedAt: Date()
                )
            )
        )
        audioSessionManager.deactivateAudioSession()
        webRTCClient.tearDown()
        activeCallID = nil
        remoteParticipant = nil
        delegate?.callEngine(self, didChangeState: .ended, for: callID)
        log("Ended WebRTC call \(callID)")
    }

    func setMuted(_ isMuted: Bool, for callID: UUID) {
        guard activeCallID == callID else { return }

        webRTCClient.setMuted(isMuted)
        signalingClient.send(
            .mute(
                CallControlPayload(
                    callID: callID,
                    participantID: localParticipant.id,
                    value: isMuted,
                    sentAt: Date()
                )
            )
        )
    }

    func setSpeakerEnabled(_ isSpeakerEnabled: Bool, for callID: UUID) {
        guard activeCallID == callID else { return }

        webRTCClient.setSpeakerEnabled(isSpeakerEnabled)
        signalingClient.send(
            .speaker(
                CallControlPayload(
                    callID: callID,
                    participantID: localParticipant.id,
                    value: isSpeakerEnabled,
                    sentAt: Date()
                )
            )
        )
    }

    func handleRemoteMessage(_ message: SignalingMessage) {
        switch message {
        case let .callInvite(payload):
            activeCallID = payload.callID
            remoteParticipant = payload.caller
            log("Received inbound invite for call \(payload.callID)")
        case let .callAnswer(payload):
            guard activeCallID == payload.callID else { return }
            log("Received remote call answer for call \(payload.callID)")
        case let .callEnd(payload):
            guard activeCallID == payload.callID else { return }
            webRTCClient.tearDown()
            activeCallID = nil
            remoteParticipant = nil
            delegate?.callEngine(self, didChangeState: .ended, for: payload.callID)
            log("Received remote call end for call \(payload.callID)")
        case let .sessionDescription(payload):
            guard activeCallID == payload.callID else { return }
            webRTCClient.applyRemoteDescription(payload)
        case let .iceCandidate(payload):
            guard activeCallID == payload.callID else { return }
            webRTCClient.applyRemoteCandidate(payload)
        case let .mute(payload):
            log("Received remote mute state \(payload.value) for call \(payload.callID)")
        case let .speaker(payload):
            log("Received remote speaker state \(payload.value) for call \(payload.callID)")
        }
    }

    private func log(_ message: String) {
        print("[WebRTCCallEngine] \(message)")
    }
}

extension WebRTCCallEngine: WebRTCClientDelegate {
    func webRTCClient(_ client: any WebRTCClient, didGenerate description: WebRTCSessionDescriptionPayload) {
        signalingClient.send(.sessionDescription(description))
        log("Sent local \(description.type.rawValue) for call \(description.callID)")
    }

    func webRTCClient(_ client: any WebRTCClient, didGenerate candidate: ICECandidatePayload) {
        signalingClient.send(.iceCandidate(candidate))
        log("Sent local ICE candidate for call \(candidate.callID)")
    }

    func webRTCClient(_ client: any WebRTCClient, didChangeConnectionState state: WebRTCConnectionState, callID: UUID) {
        switch state {
        case .connected:
            audioSessionManager.activateCallAudio()
            delegate?.callEngine(self, didChangeState: .connected, for: callID)
            log("WebRTC connection established for call \(callID)")
        case .failed, .closed, .disconnected:
            delegate?.callEngine(self, didChangeState: .ended, for: callID)
            log("WebRTC connection ended with state \(state) for call \(callID)")
        case .new, .connecting:
            log("WebRTC connection state \(state) for call \(callID)")
        }
    }
}

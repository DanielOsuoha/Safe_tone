//
//  WebRTCClient.swift
//  SafeTone
//
//  Lower-level WebRTC boundary used by WebRTCCallEngine.
//

import Foundation

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

final class StubWebRTCClient: WebRTCClient {
    weak var delegate: (any WebRTCClientDelegate)?

    func startOutgoingCall(callID: UUID, participantID: String) {
        log("Preparing outgoing WebRTC session for call \(callID)")

        let payload = WebRTCSessionDescriptionPayload(
            callID: callID,
            participantID: participantID,
            type: .offer,
            sdp: "stub-offer-sdp",
            sentAt: Date()
        )

        Task { @MainActor in
            delegate?.webRTCClient(self, didChangeConnectionState: .connecting, callID: callID)
            delegate?.webRTCClient(self, didGenerate: payload)
        }
    }

    func answerIncomingCall(callID: UUID, participantID: String) {
        log("Preparing incoming WebRTC answer for call \(callID)")

        let payload = WebRTCSessionDescriptionPayload(
            callID: callID,
            participantID: participantID,
            type: .answer,
            sdp: "stub-answer-sdp",
            sentAt: Date()
        )

        Task { @MainActor in
            delegate?.webRTCClient(self, didChangeConnectionState: .connecting, callID: callID)
            delegate?.webRTCClient(self, didGenerate: payload)
        }
    }

    func applyRemoteDescription(_ payload: WebRTCSessionDescriptionPayload) {
        log("Applied remote \(payload.type.rawValue) for call \(payload.callID)")

        Task { @MainActor in
            delegate?.webRTCClient(self, didChangeConnectionState: .connected, callID: payload.callID)
        }
    }

    func applyRemoteCandidate(_ payload: ICECandidatePayload) {
        log("Applied remote ICE candidate for call \(payload.callID)")
    }

    func setMuted(_ isMuted: Bool) {
        log("Local WebRTC mute set to \(isMuted)")
    }

    func setSpeakerEnabled(_ isSpeakerEnabled: Bool) {
        log("Local WebRTC speaker set to \(isSpeakerEnabled)")
    }

    func tearDown() {
        log("Tearing down WebRTC session")
    }

    private func log(_ message: String) {
        print("[StubWebRTCClient] \(message)")
    }
}

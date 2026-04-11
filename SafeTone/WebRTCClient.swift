//
//  WebRTCClient.swift
//  SafeTone
//
//  Lightweight boundary for future WebRTC work. This stub keeps the app buildable
//  without the CocoaPods WebRTC dependency.
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
        log("Stub start outgoing call for \(callID)")
        Task { @MainActor in
            delegate?.webRTCClient(self, didChangeConnectionState: .connecting, callID: callID)
        }
    }

    func answerIncomingCall(callID: UUID, participantID: String) {
        log("Stub answer incoming call for \(callID)")
        Task { @MainActor in
            delegate?.webRTCClient(self, didChangeConnectionState: .connecting, callID: callID)
        }
    }

    func applyRemoteDescription(_ payload: WebRTCSessionDescriptionPayload) {
        log("Stub applied remote \(payload.type.rawValue) for \(payload.callID)")
    }

    func applyRemoteCandidate(_ payload: ICECandidatePayload) {
        log("Stub applied remote ICE candidate for \(payload.callID)")
    }

    func setMuted(_ isMuted: Bool) {
        log("Stub mute set to \(isMuted)")
    }

    func setSpeakerEnabled(_ isSpeakerEnabled: Bool) {
        log("Stub speaker set to \(isSpeakerEnabled)")
    }

    func tearDown() {
        log("Stub torn down")
    }

    private func log(_ message: String) {
        print("[StubWebRTCClient] \(message)")
    }
}

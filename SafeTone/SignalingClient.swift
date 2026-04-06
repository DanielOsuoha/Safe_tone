//
//  SignalingClient.swift
//  SafeTone
//
//  Signaling boundary for call invites and realtime call events.
//

import Foundation

protocol SignalingClient: AnyObject {
    var isConnected: Bool { get }

    func connect()
    func disconnect()
    func send(_ message: SignalingMessage)
}

final class MockSignalingClient: SignalingClient {
    private(set) var isConnected = false

    func connect() {
        guard !isConnected else { return }
        isConnected = true
        log("Connected mock signaling session")
    }

    func disconnect() {
        guard isConnected else { return }
        isConnected = false
        log("Disconnected mock signaling session")
    }

    func send(_ message: SignalingMessage) {
        if !isConnected {
            connect()
        }

        log("Sent message: \(describe(message))")
    }

    private func describe(_ message: SignalingMessage) -> String {
        switch message {
        case let .callInvite(payload):
            return "callInvite callID=\(payload.callID) caller=\(payload.caller.id) callee=\(payload.callee.id)"
        case let .callAnswer(payload):
            return "callAnswer callID=\(payload.callID) participantID=\(payload.participantID)"
        case let .callEnd(payload):
            return "callEnd callID=\(payload.callID) participantID=\(payload.participantID)"
        case let .mute(payload):
            return "mute callID=\(payload.callID) participantID=\(payload.participantID) value=\(payload.value)"
        case let .speaker(payload):
            return "speaker callID=\(payload.callID) participantID=\(payload.participantID) value=\(payload.value)"
        case let .sessionDescription(payload):
            return "sessionDescription callID=\(payload.callID) participantID=\(payload.participantID) type=\(payload.type.rawValue)"
        case let .iceCandidate(payload):
            return "iceCandidate callID=\(payload.callID) participantID=\(payload.participantID)"
        }
    }

    private func log(_ message: String) {
        print("[MockSignalingClient] \(message)")
    }
}

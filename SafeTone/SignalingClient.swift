//
//  SignalingClient.swift
//  SafeTone
//
//  Signaling boundary for call invites and realtime call events.
//

import Foundation

@MainActor
protocol SignalingClientDelegate: AnyObject {
    func signalingClientDidConnect(_ client: any SignalingClient)
    func signalingClientDidDisconnect(_ client: any SignalingClient, error: Error?)
    func signalingClient(_ client: any SignalingClient, didReceive message: SignalingMessage)
}

protocol SignalingClient: AnyObject {
    var delegate: (any SignalingClientDelegate)? { get set }
    var isConnected: Bool { get }

    func connect()
    func disconnect()
    func send(_ message: SignalingMessage)
}

final class MockSignalingClient: SignalingClient {
    weak var delegate: (any SignalingClientDelegate)?
    private(set) var isConnected = false

    func connect() {
        guard !isConnected else { return }
        isConnected = true
        log("Connected mock signaling session")
        Task { @MainActor in
            self.delegate?.signalingClientDidConnect(self)
        }
    }

    func disconnect() {
        guard isConnected else { return }
        isConnected = false
        log("Disconnected mock signaling session")
        Task { @MainActor in
            self.delegate?.signalingClientDidDisconnect(self, error: nil)
        }
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

final class RealtimeSignalingClient: SignalingClient {
    weak var delegate: (any SignalingClientDelegate)?
    private(set) var isConnected = false

    private let endpoint: URL
    private let session: URLSession
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var socketTask: URLSessionWebSocketTask?

    init(endpoint: URL, session: URLSession = .shared) {
        self.endpoint = endpoint
        self.session = session
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }

    func connect() {
        guard socketTask == nil else { return }

        let task = session.webSocketTask(with: endpoint)
        socketTask = task
        task.resume()
        isConnected = true
        log("Connected realtime signaling session to \(endpoint.absoluteString)")

        Task { @MainActor in
            self.delegate?.signalingClientDidConnect(self)
        }

        listenForMessages()
    }

    func disconnect() {
        socketTask?.cancel(with: .goingAway, reason: nil)
        socketTask = nil
        isConnected = false
        log("Disconnected realtime signaling session")

        Task { @MainActor in
            self.delegate?.signalingClientDidDisconnect(self, error: nil)
        }
    }

    func send(_ message: SignalingMessage) {
        if !isConnected {
            connect()
        }

        guard let socketTask else { return }

        do {
            let data = try encoder.encode(message)
            socketTask.send(.data(data)) { [weak self] error in
                if let error {
                    self?.handleDisconnect(error: error)
                }
            }
        } catch {
            log("Failed to encode outgoing signaling message: \(error.localizedDescription)")
        }
    }

    private func listenForMessages() {
        socketTask?.receive { [weak self] result in
            guard let self else { return }

            switch result {
            case let .failure(error):
                self.handleDisconnect(error: error)
            case let .success(message):
                self.handle(message)
                if self.isConnected {
                    self.listenForMessages()
                }
            }
        }
    }

    private func handle(_ message: URLSessionWebSocketTask.Message) {
        do {
            let data: Data

            switch message {
            case let .data(payload):
                data = payload
            case let .string(text):
                data = Data(text.utf8)
            @unknown default:
                log("Received unknown websocket message type")
                return
            }

            let decoded = try decoder.decode(SignalingMessage.self, from: data)
            Task { @MainActor in
                self.delegate?.signalingClient(self, didReceive: decoded)
            }
        } catch {
            log("Failed to decode incoming signaling message: \(error.localizedDescription)")
        }
    }

    private func handleDisconnect(error: Error?) {
        socketTask = nil
        isConnected = false
        log("Realtime signaling disconnected: \(error?.localizedDescription ?? "unknown error")")

        Task { @MainActor in
            self.delegate?.signalingClientDidDisconnect(self, error: error)
        }
    }

    private func log(_ message: String) {
        print("[RealtimeSignalingClient] \(message)")
    }
}

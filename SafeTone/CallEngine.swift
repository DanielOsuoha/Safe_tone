//
//  CallEngine.swift
//  SafeTone
//
//  Transport boundary for call behavior. Replace MockCallEngine with a real engine later.
//

import Foundation
import Combine

enum CallEngineState: Equatable {
    case ringing
    case connected
    case ended
}

@MainActor
protocol CallEngineDelegate: AnyObject {
    func callEngine(_ engine: any CallEngine, didChangeState state: CallEngineState, for callID: UUID)
}

protocol CallEngine: AnyObject {
    var delegate: (any CallEngineDelegate)? { get set }

    func startOutgoingCall(callID: UUID, handle: String, displayName: String)
    func answerIncomingCall(callID: UUID)
    func endCall(callID: UUID)
    func setMuted(_ isMuted: Bool, for callID: UUID)
    func setSpeakerEnabled(_ isSpeakerEnabled: Bool, for callID: UUID)
}

final class MockCallEngine: CallEngine {
    weak var delegate: (any CallEngineDelegate)?

    private let signalingClient: any SignalingClient
    private let audioSessionManager: AudioSessionManager
    private let localParticipant = CallParticipant(
        id: "local-user",
        displayName: "You",
        handle: "local-user",
        role: .caller
    )
    private var connectWorkItem: DispatchWorkItem?
    private var ringTimer: AnyCancellable?
    private var activeCallID: UUID?
    private let outgoingConnectDelay: TimeInterval = 4

    init(signalingClient: any SignalingClient, audioSessionManager: AudioSessionManager) {
        self.signalingClient = signalingClient
        self.audioSessionManager = audioSessionManager
    }

    func startOutgoingCall(callID: UUID, handle: String, displayName: String) {
        reset()
        activeCallID = callID
        let remoteParticipant = CallParticipant(
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
                    callee: remoteParticipant,
                    createdAt: Date()
                )
            )
        )
        log("Mock engine starting outgoing call to \(displayName) [\(handle)]")
        emit(.ringing, for: callID)
        startRingingLoop(for: callID)

        let workItem = DispatchWorkItem { [weak self] in
            guard let self, self.activeCallID == callID else { return }
            self.stopRingingLoop()
            self.log("Mock engine marked call connected")
            self.emit(.connected, for: callID)
        }
        connectWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + outgoingConnectDelay, execute: workItem)
    }

    func answerIncomingCall(callID: UUID) {
        activeCallID = callID
        stopRingingLoop()
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
        log("Mock engine answering incoming call")
        emit(.connected, for: callID)
    }

    func endCall(callID: UUID) {
        guard activeCallID == callID || activeCallID == nil else { return }
        stopRingingLoop()
        connectWorkItem?.cancel()
        connectWorkItem = nil
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
        activeCallID = nil
        log("Mock engine ending call")
        emit(.ended, for: callID)
    }

    func setMuted(_ isMuted: Bool, for callID: UUID) {
        guard activeCallID == callID else { return }
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
        log("Mock engine mute set to \(isMuted)")
    }

    func setSpeakerEnabled(_ isSpeakerEnabled: Bool, for callID: UUID) {
        guard activeCallID == callID else { return }
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
        log("Mock engine speaker set to \(isSpeakerEnabled)")
    }

    private func startRingingLoop(for callID: UUID) {
        stopRingingLoop()
        audioSessionManager.playOutgoingRingBurst()

        ringTimer = Timer.publish(every: 2.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.activeCallID == callID else { return }
                self.log("Ring...")
                self.audioSessionManager.playOutgoingRingBurst()
            }
    }

    private func stopRingingLoop() {
        ringTimer?.cancel()
        ringTimer = nil
    }

    private func emit(_ state: CallEngineState, for callID: UUID) {
        Task { @MainActor in
            self.delegate?.callEngine(self, didChangeState: state, for: callID)
        }
    }

    private func reset() {
        connectWorkItem?.cancel()
        connectWorkItem = nil
        stopRingingLoop()
    }

    private func log(_ message: String) {
        print("[MockCallEngine] \(message)")
    }
}

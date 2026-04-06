//
//  CallManager.swift
//  SafeTone
//
//  Central source of truth for the app's call lifecycle and UI-facing call state.
//

import Foundation
import Combine

@MainActor
final class CallManager: ObservableObject {
    static let shared = CallManager()

    private enum EngineMode {
        case mock
        case webRTC
    }

    private static let engineMode: EngineMode = .mock

    enum CallPhase: Equatable {
        case idle
        case incoming
        case outgoing
        case connected
        case ended
    }

    enum CallDirection: Equatable {
        case incoming
        case outgoing
    }

    struct ActiveCall: Equatable, Identifiable {
        let id: UUID
        let displayName: String
        let handle: String
        let direction: CallDirection
    }

    @Published private(set) var activeCall: ActiveCall?
    @Published private(set) var phase: CallPhase = .idle
    @Published private(set) var callDuration: Int = 0
    @Published var verificationStatus: CallVerificationStatus = .analyzing
    @Published var isMuted = false
    @Published var isSpeakerOn = false
    @Published var isAnalysisPaused = false
    @Published var showPauseMessage = false
    @Published private(set) var isRingingOut = false
    @Published private(set) var isIncomingRinging = false

    private let signalingClient: any SignalingClient
    private let audioSessionManager: AudioSessionManager
    private let engine: any CallEngine
    private var durationTimer: AnyCancellable?
    private var analysisTimer: AnyCancellable?
    private var incomingRingTimer: AnyCancellable?
    private var accumulatedAnalysisTime: TimeInterval = 0
    private let analysisThreshold: TimeInterval = 15
    private var previousVerificationStatus: CallVerificationStatus?

    var callerName: String {
        activeCall?.displayName ?? "Unknown Caller"
    }

    var isCallScreenVisible: Bool {
        activeCall != nil && (phase == .outgoing || phase == .connected)
    }

    var formattedDuration: String {
        let minutes = callDuration / 60
        let seconds = callDuration % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var callStatusText: String {
        switch phase {
        case .outgoing:
            return "Ringing..."
        case .connected:
            return formattedDuration
        case .incoming:
            return "Incoming Call"
        case .ended, .idle:
            return ""
        }
    }

    var securityStatusText: String {
        phase == .outgoing ? "Calling..." : verificationStatus.text
    }

    var securityStatusColor: CallVerificationStatus {
        phase == .outgoing ? .analysisPaused : verificationStatus
    }

    private init(
        signalingClient: any SignalingClient = MockSignalingClient(),
        audioSessionManager: AudioSessionManager = AudioSessionManager(),
        engine: (any CallEngine)? = nil
    ) {
        self.signalingClient = signalingClient
        self.audioSessionManager = audioSessionManager
        self.engine = engine ?? Self.makeEngine(
            mode: Self.engineMode,
            signalingClient: signalingClient,
            audioSessionManager: audioSessionManager
        )
        self.signalingClient.delegate = self
        self.engine.delegate = self
    }

    private static func makeEngine(
        mode: EngineMode,
        signalingClient: any SignalingClient,
        audioSessionManager: AudioSessionManager
    ) -> any CallEngine {
        switch mode {
        case .mock:
            return MockCallEngine(
                signalingClient: signalingClient,
                audioSessionManager: audioSessionManager
            )
        case .webRTC:
            return WebRTCCallEngine(
                signalingClient: signalingClient,
                audioSessionManager: audioSessionManager,
                webRTCClient: StubWebRTCClient()
            )
        }
    }

    func startOutgoingCall(to handle: String, displayName: String? = nil) {
        let name = (displayName?.isEmpty == false ? displayName : handle) ?? handle
        resetCallSession()
        let call = ActiveCall(id: UUID(), displayName: name, handle: handle, direction: .outgoing)
        activeCall = call
        phase = .outgoing
        log("Starting outgoing call to \(name) [\(handle)]")
        engine.startOutgoingCall(callID: call.id, handle: handle, displayName: name)
    }

    func receiveIncomingCall(id: UUID = UUID(), handle: String, displayName: String? = nil) {
        let name = (displayName?.isEmpty == false ? displayName : handle) ?? handle
        resetCallSession()
        signalingClient.connect()
        activeCall = ActiveCall(id: id, displayName: name, handle: handle, direction: .incoming)
        phase = .incoming
        log("Incoming call received from \(name) [\(handle)]")
        startIncomingRinging()
    }

    func answerCall() {
        guard let call = activeCall else { return }
        log("Answering call")
        stopIncomingRinging()
        engine.answerIncomingCall(callID: call.id)
    }

    func declineCall() {
        log("Declining call")
        endCall()
    }

    func endCall() {
        log("Ending call")
        if let callID = activeCall?.id {
            engine.endCall(callID: callID)
        } else {
            transitionToEndedState()
        }
    }

    private func transitionToEndedState() {
        isRingingOut = false
        stopIncomingRinging()
        stopDurationTimer()
        stopAnalysisTimer()
        audioSessionManager.deactivateAudioSession()
        phase = .ended
        showPauseMessage = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.resetCallSession()
        }
    }

    func toggleMute() {
        isMuted.toggle()
        log("Mute toggled: \(isMuted ? "ON" : "OFF")")
        if let callID = activeCall?.id {
            engine.setMuted(isMuted, for: callID)
        }
    }

    func toggleSpeaker() {
        isSpeakerOn.toggle()
        log("Speaker toggled: \(isSpeakerOn ? "ON" : "OFF")")
        if let callID = activeCall?.id {
            engine.setSpeakerEnabled(isSpeakerOn, for: callID)
        }
    }

    func toggleAnalysisPause() {
        isAnalysisPaused.toggle()

        if isAnalysisPaused {
            previousVerificationStatus = verificationStatus
            verificationStatus = .analysisPaused
            stopAnalysisTimer()
            log("Analysis paused")
        } else {
            verificationStatus = previousVerificationStatus ?? .analyzing
            if phase == .connected {
                startAnalysisTimerIfNeeded()
            }
            log("Analysis resumed")
        }

        withAnimationState {
            showPauseMessage = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.withAnimationState {
                self.showPauseMessage = false
            }
        }
    }

    func setVerificationStatus(_ status: CallVerificationStatus) {
        verificationStatus = status
        log("Verification status updated: \(status.text)")
        if status == .analyzing {
            startAnalysisTimerIfNeeded()
        } else {
            stopAnalysisTimer()
        }
    }

    private func connectCurrentCall() {
        isRingingOut = false
        stopIncomingRinging()
        audioSessionManager.activateCallAudio()
        phase = .connected
        callDuration = 0
        verificationStatus = .analyzing
        log("Call connected")
        startDurationTimer()
        startAnalysisTimerIfNeeded()
    }

    private func startDurationTimer() {
        stopDurationTimer()
        durationTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.callDuration += 1
            }
    }

    private func stopDurationTimer() {
        durationTimer?.cancel()
        durationTimer = nil
        callDuration = 0
    }

    private func startAnalysisTimerIfNeeded() {
        guard phase == .connected, !isAnalysisPaused, verificationStatus == .analyzing else { return }

        stopAnalysisTimer()
        analysisTimer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self else { return }
                self.accumulatedAnalysisTime += 1

                if self.accumulatedAnalysisTime >= self.analysisThreshold {
                    self.verificationStatus = .deepFakeDetected
                    self.log("Analysis threshold reached: Deep fake warning triggered")
                    self.stopAnalysisTimer()
                }
            }
    }

    private func stopAnalysisTimer() {
        analysisTimer?.cancel()
        analysisTimer = nil
    }

    private func resetCallSession() {
        stopIncomingRinging()
        stopDurationTimer()
        stopAnalysisTimer()
        audioSessionManager.deactivateAudioSession()
        activeCall = nil
        phase = .idle
        verificationStatus = .analyzing
        isMuted = false
        isSpeakerOn = false
        isAnalysisPaused = false
        showPauseMessage = false
        isRingingOut = false
        isIncomingRinging = false
        accumulatedAnalysisTime = 0
        previousVerificationStatus = nil
        log("Call session reset")
    }

    private func startIncomingRinging() {
        stopIncomingRinging()
        isIncomingRinging = true
        log("Incoming ringing started")
        audioSessionManager.playIncomingRingBurst()

        incomingRingTimer = Timer.publish(every: 3.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self, self.phase == .incoming else { return }
                self.log("Incoming ring...")
                self.audioSessionManager.playIncomingRingBurst()
            }
    }

    private func stopIncomingRinging() {
        guard isIncomingRinging || incomingRingTimer != nil else { return }
        incomingRingTimer?.cancel()
        incomingRingTimer = nil
        isIncomingRinging = false
        log("Incoming ringing stopped")
    }

    private func log(_ message: String) {
        print("[CallManager] \(message)")
    }

    private func withAnimationState(_ updates: () -> Void) {
        updates()
    }
}

extension CallManager: CallEngineDelegate {
    func callEngine(_ engine: any CallEngine, didChangeState state: CallEngineState, for callID: UUID) {
        guard activeCall?.id == callID else { return }

        switch state {
        case .ringing:
            isRingingOut = true
            phase = .outgoing
            log("Outgoing ringing started")
        case .connected:
            connectCurrentCall()
        case .ended:
            if isRingingOut {
                log("Outgoing ringing stopped")
            }
            transitionToEndedState()
        }
    }
}

extension CallManager: SignalingClientDelegate {
    func signalingClientDidConnect(_ client: any SignalingClient) {
        log("Signaling connected")
    }

    func signalingClientDidDisconnect(_ client: any SignalingClient, error: Error?) {
        if let error {
            log("Signaling disconnected with error: \(error.localizedDescription)")
        } else {
            log("Signaling disconnected")
        }
    }

    func signalingClient(_ client: any SignalingClient, didReceive message: SignalingMessage) {
        log("Received inbound signaling message")

        switch message {
        case let .callInvite(payload):
            receiveIncomingCall(
                id: payload.callID,
                handle: payload.caller.handle,
                displayName: payload.caller.displayName
            )
        case let .callEnd(payload):
            guard activeCall?.id == payload.callID else { return }
            engine.handleRemoteMessage(message)
        case let .callAnswer(payload):
            guard activeCall?.id == payload.callID else { return }
            engine.handleRemoteMessage(message)
        case let .sessionDescription(payload):
            guard activeCall?.id == payload.callID else { return }
            engine.handleRemoteMessage(message)
        case let .iceCandidate(payload):
            guard activeCall?.id == payload.callID else { return }
            engine.handleRemoteMessage(message)
        case let .mute(payload):
            guard activeCall?.id == payload.callID else { return }
            engine.handleRemoteMessage(message)
        case let .speaker(payload):
            guard activeCall?.id == payload.callID else { return }
            engine.handleRemoteMessage(message)
        }
    }
}

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
    @Published private(set) var voiceAnalysisDetail = "Listening for live speech..."
    @Published private(set) var voiceAnalysisProgress: Double = 0

    private let signalingClient: any SignalingClient
    private let audioSessionManager: AudioSessionManager
    let localAudioStreamManager: LocalAudioStreamManager
    private let voiceAnalysisClient: any VoiceAnalysisClient
    private let engine: any CallEngine
    private var durationTimer: AnyCancellable?
    private var analysisTimer: AnyCancellable?
    private var incomingRingTimer: AnyCancellable?
    private var voiceAnalysisTask: Task<Void, Never>?
    private var accumulatedAnalysisTime: TimeInterval = 0
    private var accumulatedSpeechTime: TimeInterval = 0
    private var ambientLevel: Float?
    private var hasCompletedVoiceAnalysis = false
    private let analysisThreshold: TimeInterval = 10
    private let minimumSpeechLevel: Float = 0.06
    private let speechLevelMargin: Float = 0.05
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
        signalingClient: (any SignalingClient)? = nil,
        audioSessionManager: AudioSessionManager? = nil,
        localAudioStreamManager: LocalAudioStreamManager? = nil,
        voiceAnalysisClient: (any VoiceAnalysisClient)? = nil,
        engine: (any CallEngine)? = nil
    ) {
        let resolvedSignalingClient = signalingClient ?? MockSignalingClient()
        let resolvedAudioSessionManager = audioSessionManager ?? AudioSessionManager()
        let resolvedLocalAudioStreamManager = localAudioStreamManager ?? LocalAudioStreamManager()
        let resolvedVoiceAnalysisClient = voiceAnalysisClient ?? DemoVoiceAnalysisClient()

        self.signalingClient = resolvedSignalingClient
        self.audioSessionManager = resolvedAudioSessionManager
        self.localAudioStreamManager = resolvedLocalAudioStreamManager
        self.voiceAnalysisClient = resolvedVoiceAnalysisClient
        self.engine = engine ?? Self.makeEngine(
            mode: Self.engineMode,
            signalingClient: resolvedSignalingClient,
            audioSessionManager: resolvedAudioSessionManager
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
        localAudioStreamManager.stopStreaming()
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
        localAudioStreamManager.startStreaming()
        phase = .connected
        callDuration = 0
        verificationStatus = .analyzing
        voiceAnalysisDetail = "Listening for live speech..."
        voiceAnalysisProgress = 0
        accumulatedSpeechTime = 0
        accumulatedAnalysisTime = 0
        ambientLevel = nil
        hasCompletedVoiceAnalysis = false
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
                let recentPeak = max(
                    self.localAudioStreamManager.consumeRecentInputPeak(),
                    self.localAudioStreamManager.inputLevel
                )
                let levelPercent = Int(recentPeak * 100)

                if self.accumulatedAnalysisTime <= 2 {
                    self.ambientLevel = max(self.ambientLevel ?? 0, recentPeak)
                    self.voiceAnalysisProgress = 0
                    self.voiceAnalysisDetail = "Calibrating room noise... level \(levelPercent)%"
                    return
                }

                let threshold = max(self.minimumSpeechLevel, (self.ambientLevel ?? 0) + self.speechLevelMargin)
                let isSpeechLike = recentPeak >= threshold

                if isSpeechLike {
                    self.accumulatedSpeechTime += 1
                }

                self.voiceAnalysisProgress = min(self.accumulatedSpeechTime / self.analysisThreshold, 1)
                self.voiceAnalysisDetail = self.voiceAnalysisProgress < 1
                    ? "Keep speaking... \(Int(self.accumulatedSpeechTime))/\(Int(self.analysisThreshold))s captured • level \(levelPercent)%"
                    : "Running AI voice check..."

                if self.accumulatedSpeechTime >= self.analysisThreshold, !self.hasCompletedVoiceAnalysis {
                    self.runVoiceAnalysis()
                }
            }
    }

    private func stopAnalysisTimer() {
        analysisTimer?.cancel()
        analysisTimer = nil
    }

    private func runVoiceAnalysis() {
        guard !hasCompletedVoiceAnalysis else { return }

        hasCompletedVoiceAnalysis = true
        voiceAnalysisDetail = "Running AI voice check..."
        log("Voice analysis threshold reached: running analyzer")

        let recordingURL = localAudioStreamManager.lastRecordingURL
        let speechDuration = accumulatedSpeechTime
        voiceAnalysisTask?.cancel()
        voiceAnalysisTask = Task { [voiceAnalysisClient] in
            do {
                let result = try await voiceAnalysisClient.analyzeSpeechSample(
                    recordingURL: recordingURL,
                    speechDuration: speechDuration
                )

                await MainActor.run {
                    self.applyVoiceAnalysisResult(result)
                }
            } catch {
                await MainActor.run {
                    self.verificationStatus = .analyzing
                    self.voiceAnalysisDetail = "Voice check failed: \(error.localizedDescription)"
                    self.hasCompletedVoiceAnalysis = false
                    self.log("Voice analysis failed: \(error.localizedDescription)")
                }
            }
        }
    }

    private func applyVoiceAnalysisResult(_ result: VoiceAnalysisResult) {
        switch result.verdict {
        case .human:
            verificationStatus = .voiceVerified
            voiceAnalysisDetail = "Human voice detected • \(Int(result.confidence * 100))% confidence"
            log("Voice analysis result: human (\(result.detail))")
        case .aiGenerated:
            verificationStatus = .deepFakeDetected
            voiceAnalysisDetail = "AI-generated voice suspected • \(Int(result.confidence * 100))% confidence"
            log("Voice analysis result: AI generated (\(result.detail))")
        case .inconclusive:
            verificationStatus = .analyzing
            voiceAnalysisDetail = "Inconclusive. Keep speaking."
            hasCompletedVoiceAnalysis = false
            log("Voice analysis result: inconclusive (\(result.detail))")
        }
    }

    private func resetCallSession() {
        stopIncomingRinging()
        stopDurationTimer()
        stopAnalysisTimer()
        voiceAnalysisTask?.cancel()
        voiceAnalysisTask = nil
        localAudioStreamManager.stopStreaming()
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
        accumulatedSpeechTime = 0
        ambientLevel = nil
        hasCompletedVoiceAnalysis = false
        voiceAnalysisProgress = 0
        voiceAnalysisDetail = "Listening for live speech..."
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

//
//  InCallScreen.swift
//  SafeTone
//
//  In-progress call screen with security verification and call controls
//

import SwiftUI

nonisolated enum CallVerificationStatus: Sendable, Equatable {
    case voiceVerified
    case aiDetected
    case analyzing
    case deepFakeDetected
    case analysisPaused
    
    nonisolated var text: String {
        switch self {
        case .voiceVerified: return "Voice Verified"
        case .aiDetected: return "AI Detected"
        case .analyzing: return "Analyzing for scams..."
        case .deepFakeDetected: return "Deep Fake Identified"
        case .analysisPaused: return "Analysis Paused"
        }
    }
    
    nonisolated var color: Color {
        switch self {
        case .voiceVerified: return .blue
        case .aiDetected: return .red
        case .analyzing: return .orange
        case .deepFakeDetected: return .red
        case .analysisPaused: return .white.opacity(0.6)
        }
    }
    
    nonisolated var shadowColor: Color {
        switch self {
        case .voiceVerified: return .blue
        case .aiDetected: return .red
        case .analyzing: return .orange
        case .deepFakeDetected: return .red
        case .analysisPaused: return .white.opacity(0.3)
        }
    }
}

struct CallControlButton: Identifiable {
    let id = UUID()
    let title: String
    let icon: String
    let action: () -> Void
}

struct InCallScreen: View {
    let callerName: String
    let verificationStatus: CallVerificationStatus
    let onEndCall: () -> Void
    
    @StateObject private var timerManager = TimerManager()
    @State private var isMuted = false
    @State private var isSpeakerOn = false
    @State private var isGuardPaused = false
    @State private var showPauseMessage = false
    @State private var pulseAnimation = false
    @State private var currentStatus: CallVerificationStatus
    @State private var previousStatus: CallVerificationStatus?
    @State private var analysisTimer: Timer?
    @State private var accumulatedAnalysisTime: TimeInterval = 0
    @State private var analysisTimeThreshold: TimeInterval = 15.0
    @State private var warningPulse: Bool = false
    @State private var warningBlink: Bool = true
    
    init(callerName: String, verificationStatus: CallVerificationStatus, onEndCall: @escaping () -> Void) {
        self.callerName = callerName
        self.verificationStatus = verificationStatus
        self.onEndCall = onEndCall
        _currentStatus = State(initialValue: verificationStatus)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                topSection
                    .padding(.top, 40)
                
                Spacer()
                
                securitySection
                    .padding(.top, 15)
                
                Spacer()
                
                VStack {
                    Spacer()
                    callControlsGrid
                        .padding(.bottom, 40)
                }
            }
            
            if showPauseMessage {
                VStack {
                    Text(isGuardPaused ? "Scam analysis paused for this call" : "Scam analysis resumed")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            Capsule()
                                .fill(Color(white: 0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.blue.opacity(0.5), lineWidth: 1)
                                )
                        )
                        .padding(.top, 80)
                    Spacer()
                }
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .onAppear {
            timerManager.start()
            startPulseAnimation()
            
            // Start analysis timer if status is analyzing
            if currentStatus == .analyzing {
                startAnalysisTimer()
            }
        }
        .onDisappear {
            timerManager.stop()
            stopAnalysisTimer()
        }
    }
    
    // MARK: - Top Section
    private var topSection: some View {
        VStack(spacing: 10) {
            Text(callerName)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.white)
            
            Text(timerManager.formattedDuration)
                .font(.system(size: 18, weight: .regular, design: .default))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
    
    // MARK: - Security Section
    private var securitySection: some View {
        VStack(spacing: 20) {
            Image("SafetoneShield")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .cornerRadius(35)
                .shadow(color: currentStatus.shadowColor.opacity(0.6), radius: 40, x: 0, y: 0)
                .scaleEffect(currentStatus == .deepFakeDetected && warningPulse ? 1.1 : 1.0)
                .animation(
                    currentStatus == .deepFakeDetected ? 
                        .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default,
                    value: warningPulse
                )
            
            Text(currentStatus.text)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(currentStatus.color)
                .scaleEffect(currentStatus == .deepFakeDetected && warningPulse ? 1.15 : 1.0)
                .opacity(currentStatus == .deepFakeDetected ? (warningBlink ? 1.0 : 0.4) : 1.0)
                .animation(
                    currentStatus == .deepFakeDetected ? 
                        .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default,
                    value: warningPulse
                )
        }
    }
    
    // MARK: - Call Controls Grid
    private var callControlsGrid: some View {
        Grid(horizontalSpacing: 30, verticalSpacing: 30) {
            // Row 1: Mute, Keypad, Speaker
            GridRow {
                callButton(title: "mute", icon: isMuted ? "mic.slash.fill" : "mic.fill", isActive: isMuted) {
                    isMuted.toggle()
                }
                callButton(title: "keypad", icon: "circle.grid.3x3.fill", isActive: false) {
                }
                callButton(title: "speaker", icon: "speaker.wave.3.fill", isActive: isSpeakerOn) {
                    isSpeakerOn.toggle()
                }
            }
            
            GridRow {
                callButton(title: "add call", icon: "plus", isActive: false) {
                }
                callButton(title: "FaceTime", icon: "video.fill", isActive: false) {
                }
                callButton(title: "contacts", icon: "person.crop.circle.fill", isActive: false) {
                }
            }

            GridRow {
                callButton(
                    title: isGuardPaused ? "Resume" : "Pause Analysis",
                    icon: isGuardPaused ? "shield.fill" : "shield.slash.fill",
                    isActive: isGuardPaused
                ) {
                    isGuardPaused.toggle()
                    
                    if isGuardPaused {
                        // Save current status and pause
                        previousStatus = currentStatus
                        currentStatus = .analysisPaused
                        stopAnalysisTimer()
                    } else {
                        // Restore previous status
                        if let previous = previousStatus {
                            currentStatus = previous
                            // Resume timer if we're still analyzing
                            if currentStatus == .analyzing {
                                startAnalysisTimer()
                            }
                        }
                    }
                    
                    showPauseMessage = true
                    
                    // Hide message after 2 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            showPauseMessage = false
                        }
                    }
                }
                
                endCallButton
                
                Color.clear
                    .gridCellUnsizedAxes([.horizontal, .vertical])
            }
        }
    }
    
    private func callButton(title: String, icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isActive ? Color.white : Color(white: 0.15))
                        .frame(width: 75, height: 75)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(isActive ? .black : .white)
                }
                
                Text(title)
                    .font(.system(size: 18, weight: .medium, design: .default))
                    .foregroundStyle(.white.opacity(0.8))
            }
            .frame(minWidth: kMinTouchTarget, minHeight: kMinTouchTarget)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - End Call Button
    private var endCallButton: some View {
        Button(action: onEndCall) {
            Image(systemName: "phone.down.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 75, height: 75)
        }
        .background(Circle().fill(Color.red))
        .buttonStyle(.plain)
    }
    
    private func startPulseAnimation() {
        pulseAnimation = true
    }
    
    private func startAnalysisTimer() {
        // Stop any existing timer
        stopAnalysisTimer()
        
        // Start new timer that fires every second
        analysisTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            accumulatedAnalysisTime += 1.0
            
            // Check if we've reached the threshold
            if accumulatedAnalysisTime >= analysisTimeThreshold {
                withAnimation {
                    currentStatus = .deepFakeDetected
                }
                stopAnalysisTimer()
                
                // Trigger warning animations and haptics
                triggerDeepFakeWarning()
            }
        }
    }
    
    private func stopAnalysisTimer() {
        analysisTimer?.invalidate()
        analysisTimer = nil
    }
    
    private func triggerDeepFakeWarning() {
        warningPulse = true
        
        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { timer in
            if currentStatus == .deepFakeDetected {
                warningBlink.toggle()
            } else {
                timer.invalidate()
            }
        }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            let impact = UIImpactFeedbackGenerator(style: .heavy)
            impact.impactOccurred()
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        }
    }
}

// MARK: - Preview
#Preview {
    InCallScreen(
        callerName: "Alice Chen",
        verificationStatus: .analyzing,
        onEndCall: {}
    )
}

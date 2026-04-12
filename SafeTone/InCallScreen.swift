//
//  InCallScreen.swift
//  SafeTone
//
//  In-progress call screen with security verification and call controls.
//

import SwiftUI

nonisolated enum CallVerificationStatus: Sendable, Equatable {
    case voiceVerified
    case analyzing
    case suspiciousAudioDetected
    case analysisPaused

    nonisolated var text: String {
        switch self {
        case .voiceVerified: return "Voice Verified"
        case .analyzing: return "Analyzing for scams..."
        case .suspiciousAudioDetected: return "Suspicious Audio Detected"
        case .analysisPaused: return "Analysis Paused"
        }
    }

    nonisolated var color: Color {
        switch self {
        case .voiceVerified: return .blue
        case .analyzing: return .orange
        case .suspiciousAudioDetected: return .red
        case .analysisPaused: return .white.opacity(0.6)
        }
    }

    nonisolated var shadowColor: Color {
        switch self {
        case .voiceVerified: return .blue
        case .analyzing: return .orange
        case .suspiciousAudioDetected: return .red
        case .analysisPaused: return .white.opacity(0.3)
        }
    }
}

struct InCallScreen: View {
    @EnvironmentObject private var callManager: CallManager
    @State private var warningPulse = false
    @State private var warningBlink = true

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

            if callManager.showPauseMessage {
                VStack {
                    Text(callManager.isAnalysisPaused ? "Scam analysis paused for this call" : "Scam analysis resumed")
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
        .onChange(of: callManager.verificationStatus) { _, newValue in
            if newValue == .suspiciousAudioDetected {
                triggerSuspiciousAudioWarning()
            } else {
                warningPulse = false
                warningBlink = true
            }
        }
    }

    private var topSection: some View {
        VStack(spacing: 10) {
            Text(callManager.callerName)
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.white)

            Text(callManager.callStatusText)
                .font(.system(size: 18, weight: .regular, design: .default))
                .foregroundStyle(.white.opacity(0.7))
        }
    }

    private var securitySection: some View {
        VStack(spacing: 20) {
            Image("SafetoneShield")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
                .cornerRadius(35)
                .shadow(color: callManager.securityStatusColor.shadowColor.opacity(0.6), radius: 40, x: 0, y: 0)
                .scaleEffect(callManager.verificationStatus == .suspiciousAudioDetected && warningPulse ? 1.1 : 1.0)
                .animation(
                    callManager.verificationStatus == .suspiciousAudioDetected ?
                        .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default,
                    value: warningPulse
                )

            if callManager.localAudioStreamManager.isStreaming {
                VStack(spacing: 10) {
                    HStack(spacing: 8) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                            .scaleEffect(0.8 + CGFloat(callManager.localAudioStreamManager.inputLevel * 0.8))
                        Text("Mic Live")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white.opacity(0.75))
                    }

                    audioLevelMeter
                }
            }

            Text(callManager.securityStatusText)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(callManager.securityStatusColor.color)
                .scaleEffect(callManager.verificationStatus == .suspiciousAudioDetected && warningPulse ? 1.15 : 1.0)
                .opacity(callManager.verificationStatus == .suspiciousAudioDetected ? (warningBlink ? 1.0 : 0.4) : 1.0)
                .animation(
                    callManager.verificationStatus == .suspiciousAudioDetected ?
                        .easeInOut(duration: 0.6).repeatForever(autoreverses: true) : .default,
                    value: warningPulse
                )

            if callManager.phase == .connected {
                voiceAnalysisStatus
            }
        }
    }

    private var voiceAnalysisStatus: some View {
        VStack(spacing: 8) {
            Text(callManager.voiceAnalysisDetail)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(.white.opacity(0.72))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 28)

            if callManager.verificationStatus == .analyzing {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.12))

                        Capsule()
                            .fill(Color.orange.opacity(0.9))
                            .frame(width: max(10, geometry.size.width * CGFloat(callManager.voiceAnalysisProgress)))
                    }
                }
                .frame(width: 190, height: 7)
            }
        }
    }

    private var audioLevelMeter: some View {
        VStack(spacing: 8) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(Color.white.opacity(0.12))

                    Capsule()
                        .fill(Color.green.opacity(0.9))
                        .frame(width: max(12, geometry.size.width * CGFloat(callManager.localAudioStreamManager.inputLevel)))
                }
            }
            .frame(width: 140, height: 8)

            if callManager.localAudioStreamManager.hasRecording {
                Button {
                    if callManager.localAudioStreamManager.isPlayingRecording {
                        callManager.localAudioStreamManager.stopPlayback()
                    } else {
                        callManager.localAudioStreamManager.playLastRecording()
                    }
                } label: {
                    Text(callManager.localAudioStreamManager.isPlayingRecording ? "Stop Playback" : "Play Last Recording")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            Capsule()
                                .fill(Color.white.opacity(0.12))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.16), lineWidth: 1)
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var callControlsGrid: some View {
        Grid(horizontalSpacing: 30, verticalSpacing: 30) {
            GridRow {
                callButton(title: "mute", icon: callManager.isMuted ? "mic.slash.fill" : "mic.fill", isActive: callManager.isMuted) {
                    callManager.toggleMute()
                }
                callButton(title: "keypad", icon: "circle.grid.3x3.fill", isActive: false) {
                }
                callButton(title: "speaker", icon: "speaker.wave.3.fill", isActive: callManager.isSpeakerOn) {
                    callManager.toggleSpeaker()
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
                    title: callManager.isAnalysisPaused ? "Resume" : "Pause Analysis",
                    icon: callManager.isAnalysisPaused ? "shield.fill" : "shield.slash.fill",
                    isActive: callManager.isAnalysisPaused
                ) {
                    callManager.toggleAnalysisPause()
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

    private var endCallButton: some View {
        Button(action: callManager.endCall) {
            Image(systemName: "phone.down.fill")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 75, height: 75)
        }
        .background(Circle().fill(Color.red))
        .buttonStyle(.plain)
    }

    private func triggerSuspiciousAudioWarning() {
        warningPulse = true

        Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { timer in
            if callManager.verificationStatus == .suspiciousAudioDetected {
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

#Preview {
    InCallScreen()
        .environmentObject(CallManager.shared)
}

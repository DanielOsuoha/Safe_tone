//
//  InCallScreen.swift
//  SafeTone
//
//  In-progress call screen with security verification and call controls
//

import SwiftUI

enum CallVerificationStatus {
    case voiceVerified
    case aiDetected
    case analyzing
    
    var text: String {
        switch self {
        case .voiceVerified: return "Voice Verified"
        case .aiDetected: return "AI Detected"
        case .analyzing: return "Analyzing for scams..."
        }
    }
    
    var color: Color {
        switch self {
        case .voiceVerified: return .blue
        case .aiDetected: return .red
        case .analyzing: return .orange
        }
    }
    
    var shadowColor: Color {
        switch self {
        case .voiceVerified: return .blue
        case .aiDetected: return .red
        case .analyzing: return .orange
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
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                topSection
                    .padding(.top, 40)
                
                Spacer()
                
                securitySection
                
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
        }
        .onDisappear {
            timerManager.stop()
        }
    }
    
    // MARK: - Top Section
    private var topSection: some View {
        VStack(spacing: 8) {
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
                .shadow(color: verificationStatus.shadowColor.opacity(0.6), radius: 40, x: 0, y: 0)
            
            Text(verificationStatus.text)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(verificationStatus.color)
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
}

// MARK: - Preview
#Preview {
    InCallScreen(
        callerName: "Alice Chen",
        verificationStatus: .analyzing,
        onEndCall: {}
    )
}

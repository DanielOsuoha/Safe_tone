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
        case .analyzing: return "Analyzing..."
        }
    }
    
    var color: Color {
        switch self {
        case .voiceVerified: return .green
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
    @State private var pulseAnimation = false
    
    var body: some View {
        ZStack {
            Color.safeToneBackground.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Top Section: Caller Info & Timer
                topSection
                    .padding(.top, 60)
                
                Spacer()
                
                // Middle Section: Security Shield
                securitySection
                
                Spacer()
                
                // Bottom Section: Call Controls
                callControlsGrid
                    .padding(.horizontal, 20)
                
                // End Call Button
                endCallButton
                    .padding(.horizontal, 20)
                    .padding(.bottom, 40)
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
                .font(.system(size: 18, weight: .regular))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
    
    // MARK: - Security Section
    private var securitySection: some View {
        VStack(spacing: 20) {
            // Pulsing Shield Icon
            ZStack {
                Circle()
                    .fill(verificationStatus.color.opacity(0.2))
                    .frame(width: pulseAnimation ? 140 : 120, height: pulseAnimation ? 140 : 120)
                    .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseAnimation)
                
                Image(systemName: "shield.fill")
                    .font(.system(size: 60, weight: .medium))
                    .foregroundStyle(verificationStatus.color)
            }
            
            // Status Label
            Text(verificationStatus.text)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(verificationStatus.color)
        }
    }
    
    // MARK: - Call Controls Grid
    private var callControlsGrid: some View {
        VStack(spacing: 24) {
            // Row 1
            HStack(spacing: 24) {
                callButton(title: "mute", icon: isMuted ? "mic.slash.fill" : "mic.fill", isActive: isMuted) {
                    isMuted.toggle()
                }
                callButton(title: "keypad", icon: "circle.grid.3x3.fill", isActive: false) {
                    // Show keypad
                }
                callButton(title: "speaker", icon: "speaker.wave.3.fill", isActive: isSpeakerOn) {
                    isSpeakerOn.toggle()
                }
            }
            
            // Row 2
            HStack(spacing: 24) {
                callButton(title: "add call", icon: "plus", isActive: false) {
                    // Add call
                }
                callButton(title: "FaceTime", icon: "video.fill", isActive: false) {
                    // Switch to FaceTime
                }
                callButton(title: "contacts", icon: "person.crop.circle.fill", isActive: false) {
                    // Show contacts
                }
            }
        }
    }
    
    private func callButton(title: String, icon: String, isActive: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(isActive ? Color.white : Color(white: 0.2))
                        .frame(width: 75, height: 75)
                    
                    Image(systemName: icon)
                        .font(.system(size: 28, weight: .medium))
                        .foregroundStyle(isActive ? .black : .white)
                }
                
                Text(title)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
            }
            .frame(minWidth: kMinTouchTarget, minHeight: kMinTouchTarget)
        }
        .buttonStyle(.plain)
    }
    
    // MARK: - End Call Button
    private var endCallButton: some View {
        Button(action: onEndCall) {
            HStack(spacing: 12) {
                Image(systemName: "phone.down.fill")
                    .font(.system(size: 24, weight: .semibold))
                
                Text("End Call")
                    .font(.system(size: 20, weight: .semibold))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.red)
            )
        }
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
        verificationStatus: .voiceVerified,
        onEndCall: {}
    )
}

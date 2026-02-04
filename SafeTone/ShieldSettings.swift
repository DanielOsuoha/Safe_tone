//
//  ShieldSettings.swift
//  SafeTone
//
//  Dashboard with System Guard toggle. Black background, system typography.
//

import SwiftUI

struct ShieldSettings: View {
    @State private var systemGuardActive: Bool = true
    @State private var showUpgradeOverlay: Bool = false
    @State private var simulationTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Spacer()
                
                Image("SafetoneShield")
                .resizable()
                .scaledToFit()
                .frame(width: 230, height: 240)
                .cornerRadius(65)
                .shadow(color: .blue.opacity(0.6), radius: 50, x: 0, y: 0)
                            
                // Header Text
                HStack(spacing: 4) {
                    Text("SafeTone Protection:")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.white)
                    
                    Text("ON")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundStyle(.blue)
                }
                .padding(.top, 12)
                
                Spacer().frame(height: 40)
                
                socialProofCard
                
                Spacer().frame(height: 24)
                
                serviceStatusSection
                
                Spacer().frame(height: 20)
                
                Text("SafeTone AI is currently monitoring your line.")
                    .font(.system(size: 12, weight: .regular))
                    .foregroundStyle(.blue.opacity(0.5))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                Spacer()
            }
            .padding(.horizontal, 24)
            
            VStack {
                HStack {
                    Spacer()
                    Button {
                        showUpgradeOverlay = true
                    } label: {
                        Image(systemName: "person.crop.circle")
                            .font(.system(size: 32))
                            .foregroundStyle(.white)
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 10)
                    .padding(.trailing, 25)
                }
                Spacer()
            }
            
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Button {
                        triggerDelayedCallKitSimulation()
                    } label: {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 30))
                            .foregroundStyle(.white)
                            .background(
                                Circle()
                                    .fill(Color.blue)
                                    .frame(width: 38, height: 38)
                            )
                    }
                    .buttonStyle(.plain)
                    .opacity(0.8)
                    .padding(.trailing, 24)
                    .padding(.bottom, 40)
                }
            }
            
            // Upgrade Overlay
            if showUpgradeOverlay {
                upgradeOverlay
            }
        }
    }
    
    private var socialProofCard: some View {
        HStack(spacing: 24) {
            // Large Number on Left
            Text("4")
                .font(.system(size: 70, weight: .bold))
                .foregroundStyle(.blue)
            
            // Text on Right - Stacked
            VStack(alignment: .leading, spacing: 4) {
                Text("scams prevented")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.9))
                
                Text("this month")
                    .font(.system(size: 20, weight: .regular))
                    .foregroundStyle(.white.opacity(0.7))
            }
            
            Spacer()
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 28)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(white: 0.15))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.blue.opacity(0.5), lineWidth: 1.5)
                )
        )
        .padding(.horizontal, 8)
    }
    
    private var serviceStatusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            statusRow(text: "AI Voice Analysis Active")
            statusRow(text: "Caller Identity Verified")
            statusRow(text: "Secure Bank Monitoring")
        }
        .padding(.horizontal, 24)
    }
    
    private func statusRow(text: String) -> some View {
        HStack(spacing: 12) {
            Text("✓")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.blue)
            
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.white.opacity(0.7))
            
            Spacer()
        }
    }
    
    private var upgradeOverlay: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .onTapGesture {
                    showUpgradeOverlay = false
                }
            
            VStack(spacing: 32) {
                // Premium Membership Card
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("SafeTone Premium")
                                .font(.system(size: 24, weight: .bold))
                                .foregroundStyle(.white)
                            
                            Text("Free Plan")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        Image("SafetoneShield")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                    }
                    
                    Divider()
                        .background(Color.white.opacity(0.2))
                    
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Premium Benefits:")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.white)
                        
                        premiumFeature("Unlimited scam protection")
                        premiumFeature("Advanced AI voice analysis")
                        premiumFeature("Priority customer support")
                        premiumFeature("Call recording & transcripts")
                    }
                    
                    Button {
                        // Upgrade action
                    } label: {
                        Text("Upgrade Now")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color.blue)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(28)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color(white: 0.12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 32)
                
                Button {
                    showUpgradeOverlay = false
                } label: {
                    Text("Close")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.white.opacity(0.7))
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    private func premiumFeature(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 16))
                .foregroundStyle(.blue)
            
            Text(text)
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(.white.opacity(0.8))
            
            Spacer()
        }
    }    
    private func triggerDelayedCallKitSimulation() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        simulationTask?.cancel()
        
        // Create a new background task that survives app backgrounding
        simulationTask = Task {
            // Wait 5 seconds
            try? await Task.sleep(nanoseconds: 5_000_000_000)
            
            // Check if task wasn't cancelled
            guard !Task.isCancelled else { return }
            
            // Trigger CallKit incoming call on main thread
            await MainActor.run {
                CallKitManager.shared.simulateIncomingCall(from: "SafeTone Guard")
            }
        }
    }
}

#Preview {
    ShieldSettings()
}

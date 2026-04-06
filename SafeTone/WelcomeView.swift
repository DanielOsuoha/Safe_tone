
//  WelcomeView.swift
//  SafeTone
import SwiftUI

struct WelcomeView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentPage: Int = 1
    @State private var showBlackTransition: Bool = false
    @State private var buttonActivated: Bool = false
    
    var body: some View {
        ZStack {
            if currentPage == 1 {
                splashPage
                    .transition(.opacity)
            } else {
                setupPage
                    .transition(.opacity)
            }
            if showBlackTransition {
                Color.black
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: currentPage)
        .animation(.easeInOut(duration: 0.5), value: showBlackTransition)
    }
    private var splashPage: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer()
                Image("SafetoneShield")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 40))
                Text("SafeTone")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(.black)
                    .tracking(0.5)
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: Color(white: 0.6)))
                    .scaleEffect(0.8)
                    .padding(.top, 12)
                
                Spacer()
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                currentPage = 2
            }
        }
    }
    private var setupPage: some View {
        ZStack {
            Color.white.ignoresSafeArea()
            
            VStack(spacing: 0) {
                Text("Step 1 of 1")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color(red: 0.0, green: 0.48, blue: 1.0))
                    .padding(.top, 60)
                
                Spacer()
                
                VStack(spacing: 28) {
                    Image("SafetoneShield")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    
                    Text("Almost There!")
                        .font(.system(size: 38, weight: .bold))
                        .foregroundStyle(.black)
                        .multilineTextAlignment(.center)
                        .lineSpacing(4)
                        .padding(.horizontal, 32)
                    
                    Text("Tap below to activate call protection and block scam calls automatically")
                        .font(.system(size: 19, weight: .regular))
                        .foregroundStyle(Color(white: 0.3))
                        .multilineTextAlignment(.center)
                        .lineSpacing(8)
                        .padding(.horizontal, 40)
                    
                    VStack(spacing: 16) {
                        trustFeature(icon: "checkmark.shield.fill", text: "Easy to use")
                        trustFeature(icon: "checkmark.shield.fill", text: "Always protected")
                        trustFeature(icon: "checkmark.shield.fill", text: "Your trust matters")
                    }
                    .padding(.top, 12)
                }
                
                Spacer()
                Spacer()
                
                Button {
                    completeSetup()
                } label: {
                    Text(buttonActivated ? "Protection Active ✓" : "Activate Protection")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 22)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(buttonActivated ? Color.green : Color(red: 0.0, green: 0.48, blue: 1.0))
                        )
                        .shadow(color: (buttonActivated ? Color.green : Color(red: 0.0, green: 0.48, blue: 1.0)).opacity(0.35), radius: 16, x: 0, y: 6)
                }
                .buttonStyle(.plain)
                .disabled(buttonActivated)
                .padding(.horizontal, 28)
                .padding(.bottom, 50)
            }
        }
    }
    private func trustFeature(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 22))
                .foregroundStyle(Color(red: 0.0, green: 0.48, blue: 1.0))
                .frame(width: 28)
            
            Text(text)
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(.black)
            
            Spacer()
        }
        .padding(.horizontal, 60)
    }
    
    private func completeSetup() {
        buttonActivated = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            showBlackTransition = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                hasCompletedOnboarding = true
            }
        }
    }
}

#Preview {
    WelcomeView()
}

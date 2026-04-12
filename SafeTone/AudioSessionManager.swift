//
//  AudioSessionManager.swift
//  SafeTone
//
//  Centralized audio-session ownership for ringing and live call audio.
//

import Foundation
import AudioToolbox
import AVFoundation

final class AudioSessionManager {
    func activateRingingAudio() {
        configureSession(category: .playback, mode: .default, options: [.mixWithOthers], context: "ringing")
    }

    func activateCallAudio() {
        configureSession(
            category: .playAndRecord,
            mode: .measurement,
            options: [.defaultToSpeaker],
            context: "call audio"
        )
    }

    func deactivateAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setActive(false, options: [.notifyOthersOnDeactivation])
        } catch {
            log("Failed to deactivate audio session: \(error.localizedDescription)")
        }
    }

    func playOutgoingRingBurst() {
        activateRingingAudio()
        playToneBurst(secondToneDelay: 0.35)
    }

    func playIncomingRingBurst() {
        activateRingingAudio()
        playToneBurst(secondToneDelay: 0.45)
    }

    private func configureSession(
        category: AVAudioSession.Category,
        mode: AVAudioSession.Mode,
        options: AVAudioSession.CategoryOptions,
        context: String
    ) {
        let session = AVAudioSession.sharedInstance()

        do {
            try session.setCategory(category, mode: mode, options: options)
            try session.setActive(true, options: [])
        } catch {
            log("Failed to configure \(context): \(error.localizedDescription)")
        }
    }

    private func playToneBurst(secondToneDelay: TimeInterval) {
        AudioServicesPlaySystemSound(1003)
        DispatchQueue.main.asyncAfter(deadline: .now() + secondToneDelay) {
            AudioServicesPlaySystemSound(1003)
        }
    }

    private func log(_ message: String) {
        print("[AudioSessionManager] \(message)")
    }
}

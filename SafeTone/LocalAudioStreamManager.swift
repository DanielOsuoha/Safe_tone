//
//  LocalAudioStreamManager.swift
//  SafeTone
//
//  Local microphone capture pipeline used to verify the live audio path before WebRTC transport is wired in.
//

import Foundation
import Combine
import AVFoundation
import Accelerate

final class LocalAudioStreamManager: NSObject, ObservableObject {
    @Published private(set) var isStreaming = false
    @Published private(set) var inputLevel: Float = 0
    @Published private(set) var recentInputPeak: Float = 0
    @Published private(set) var permissionStatus = AVAudioApplication.shared.recordPermission
    @Published private(set) var hasRecording = false
    @Published private(set) var isPlayingRecording = false

    var lastRecordingURL: URL? {
        recordingURL
    }

    @MainActor
    func consumeRecentInputPeak() -> Float {
        let peak = recentInputPeak
        recentInputPeak = 0
        return peak
    }

    private let engine = AVAudioEngine()
    private let audioSession = AVAudioSession.sharedInstance()
    private let processingQueue = DispatchQueue(label: "SafeTone.LocalAudioStreamManager")
    private var recordingFile: AVAudioFile?
    private var recordingURL: URL?
    private var audioPlayer: AVAudioPlayer?

    func startStreaming() {
        permissionStatus = AVAudioApplication.shared.recordPermission

        switch permissionStatus {
        case .granted:
            configureAndStartEngine()
        case .undetermined:
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                DispatchQueue.main.async {
                    self?.permissionStatus = granted ? .granted : .denied
                    if granted {
                        self?.configureAndStartEngine()
                    } else {
                        self?.log("Microphone permission denied")
                    }
                }
            }
        case .denied:
            log("Microphone permission denied")
        @unknown default:
            log("Unknown microphone permission status")
        }
    }

    func stopStreaming() {
        guard engine.isRunning || isStreaming else { return }

        finishRecording()
        log("Stopped local audio stream")
    }

    func finalizeRecordingForAnalysis() -> URL? {
        finishRecording()
        return recordingURL
    }

    private func finishRecording() {
        guard engine.isRunning || isStreaming || recordingFile != nil else { return }

        let inputNode = engine.inputNode
        inputNode.removeTap(onBus: 0)
        if engine.isRunning {
            engine.stop()
        }
        recordingFile = nil

        let recorded = recordingURL != nil

        DispatchQueue.main.async {
            self.isStreaming = false
            self.inputLevel = 0
            self.recentInputPeak = 0
            self.hasRecording = recorded
        }
    }

    func playLastRecording() {
        guard let recordingURL else {
            log("No local recording available to play")
            return
        }

        stopPlayback()

        do {
            try audioSession.setCategory(.playback, mode: .default, options: [.mixWithOthers])
            try audioSession.setActive(true, options: [])

            audioPlayer = try AVAudioPlayer(contentsOf: recordingURL)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()

            DispatchQueue.main.async {
                self.isPlayingRecording = true
            }

            log("Playing back local recording")
        } catch {
            log("Failed to play local recording: \(error.localizedDescription)")
        }
    }

    func stopPlayback() {
        guard isPlayingRecording || audioPlayer?.isPlaying == true else { return }

        audioPlayer?.stop()
        audioPlayer = nil

        DispatchQueue.main.async {
            self.isPlayingRecording = false
        }

        log("Stopped recording playback")
    }

    private func configureAndStartEngine() {
        guard !engine.isRunning else {
            log("Local audio stream already running")
            return
        }

        do {
            try audioSession.setCategory(
                .playAndRecord,
                mode: .measurement,
                options: [.defaultToSpeaker]
            )
            try audioSession.setActive(true, options: [])
        } catch {
            log("Failed to activate audio session for local streaming: \(error.localizedDescription)")
        }

        let inputNode = engine.inputNode
        let inputFormat = inputNode.inputFormat(forBus: 0)
        prepareRecordingFile(for: inputFormat)

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: inputFormat) { [weak self] buffer, _ in
            self?.processingQueue.async {
                if let recordingFile = self?.recordingFile {
                    do {
                        try recordingFile.write(from: buffer)
                    } catch {
                        self?.log("Failed writing local recording buffer: \(error.localizedDescription)")
                    }
                }

                let normalized = Self.calculateSignalLevel(from: buffer)

                DispatchQueue.main.async {
                    self?.inputLevel = normalized
                    self?.recentInputPeak = max(self?.recentInputPeak ?? 0, normalized)
                }
            }
        }

        engine.prepare()

        do {
            try engine.start()
            DispatchQueue.main.async {
                self.isStreaming = true
                self.hasRecording = false
            }
            log("Started local audio stream")
        } catch {
            inputNode.removeTap(onBus: 0)
            log("Failed to start local audio stream: \(error.localizedDescription)")
        }
    }

    private func prepareRecordingFile(for format: AVAudioFormat) {
        let recordingsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first ?? FileManager.default.temporaryDirectory
        let url = recordingsDirectory.appendingPathComponent("SafeTone-LastCallRecording.wav")
        let settings: [String: Any] = [
            AVFormatIDKey: kAudioFormatLinearPCM,
            AVSampleRateKey: format.sampleRate,
            AVNumberOfChannelsKey: Int(format.channelCount),
            AVLinearPCMBitDepthKey: 16,
            AVLinearPCMIsFloatKey: false,
            AVLinearPCMIsBigEndianKey: false
        ]

        do {
            if FileManager.default.fileExists(atPath: url.path) {
                try FileManager.default.removeItem(at: url)
            }

            recordingFile = try AVAudioFile(forWriting: url, settings: settings)
            recordingURL = url
            log("Prepared local recording at path: \(url.path)")
        } catch {
            recordingFile = nil
            recordingURL = nil
            log("Failed to prepare local recording file: \(error.localizedDescription)")
        }
    }

    private static func calculateSignalLevel(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 }

        let channel = channelData[0]
        let frameCount = Int(buffer.frameLength)
        guard frameCount > 0 else { return 0 }

        var rms: Float = 0
        var peak: Float = 0
        vDSP_rmsqv(channel, 1, &rms, vDSP_Length(frameCount))
        vDSP_maxmgv(channel, 1, &peak, vDSP_Length(frameCount))

        return min(max((rms * 28) + (peak * 2), 0), 1)
    }

    private func log(_ message: String) {
        print("[LocalAudioStreamManager] \(message)")
    }
}

extension LocalAudioStreamManager: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        DispatchQueue.main.async {
            self.isPlayingRecording = false
        }
        audioPlayer = nil
        log("Finished recording playback")
    }
}

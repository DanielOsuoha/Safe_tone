//
//  VoiceAnalysisClient.swift
//  SafeTone
//
//  Model boundary for voice authenticity analysis.
//

import Foundation

enum VoiceAnalysisVerdict: Equatable {
    case human
    case aiGenerated
    case inconclusive
}

struct VoiceAnalysisResult: Equatable {
    let verdict: VoiceAnalysisVerdict
    let confidence: Double
    let detail: String
}

protocol VoiceAnalysisClient: Sendable {
    func analyzeSpeechSample(recordingURL: URL?, speechDuration: TimeInterval) async throws -> VoiceAnalysisResult
}

struct DemoVoiceAnalysisClient: VoiceAnalysisClient {
    func analyzeSpeechSample(recordingURL: URL?, speechDuration: TimeInterval) async throws -> VoiceAnalysisResult {
        try await Task.sleep(for: .milliseconds(700))

        if speechDuration >= 8 {
            return VoiceAnalysisResult(
                verdict: .human,
                confidence: 0.91,
                detail: "Live speech detected for \(Int(speechDuration)) seconds."
            )
        }

        return VoiceAnalysisResult(
            verdict: .inconclusive,
            confidence: 0.44,
            detail: "Not enough speech captured yet."
        )
    }
}

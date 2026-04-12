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

enum VoiceAnalysisClientFactory {
    static func makeDefault() -> any VoiceAnalysisClient {
        if let apiKey = configuredRealityDefenderAPIKey {
            return RealityDefenderVoiceAnalysisClient(apiKey: apiKey)
        }

        return DemoVoiceAnalysisClient()
    }

    private static var configuredRealityDefenderAPIKey: String? {
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "REALITY_DEFENDER_API_KEY") as? String,
           !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return apiKey
        }

        if let apiKey = ProcessInfo.processInfo.environment["REALITY_DEFENDER_API_KEY"],
           !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return apiKey
        }

        return nil
    }
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

struct RealityDefenderVoiceAnalysisClient: VoiceAnalysisClient {
    enum RealityDefenderError: LocalizedError {
        case missingRecording
        case invalidPresignedResponse
        case analysisTimedOut
        case invalidMediaResponse
        case httpFailure(statusCode: Int, body: String)

        var errorDescription: String? {
            switch self {
            case .missingRecording:
                return "No recording was available to analyze."
            case .invalidPresignedResponse:
                return "Reality Defender did not return an upload URL."
            case .analysisTimedOut:
                return "Reality Defender analysis timed out."
            case .invalidMediaResponse:
                return "Reality Defender returned an unexpected result."
            case let .httpFailure(statusCode, body):
                return "Reality Defender HTTP \(statusCode): \(body)"
            }
        }
    }

    private let apiKey: String
    private let baseURL: URL
    private let urlSession: URLSession
    private let maxPollAttempts: Int
    private let pollDelay: Duration

    init(
        apiKey: String,
        baseURL: URL = URL(string: "https://api.prd.realitydefender.xyz")!,
        urlSession: URLSession = .shared,
        maxPollAttempts: Int = 60,
        pollDelay: Duration = .seconds(2)
    ) {
        self.apiKey = apiKey
        self.baseURL = baseURL
        self.urlSession = urlSession
        self.maxPollAttempts = maxPollAttempts
        self.pollDelay = pollDelay
    }

    func analyzeSpeechSample(recordingURL: URL?, speechDuration: TimeInterval) async throws -> VoiceAnalysisResult {
        guard let recordingURL else {
            throw RealityDefenderError.missingRecording
        }

        let upload = try await requestUploadURL(for: recordingURL.lastPathComponent)
        try await uploadRecording(recordingURL, to: upload.uploadURL)

        for attempt in 1...maxPollAttempts {
            let (response, rawBody) = try await fetchMediaDetail(requestID: upload.requestID)

            if let result = mapMediaDetail(response, rawBody: rawBody) {
                return result
            }

            print("[RealityDefenderVoiceAnalysisClient] Poll \(attempt)/\(maxPollAttempts): \(response.progressSummary)")
            try await Task.sleep(for: pollDelay)
        }

        throw RealityDefenderError.analysisTimedOut
    }

    private func requestUploadURL(for fileName: String) async throws -> PresignedUpload {
        let url = baseURL.appending(path: "/api/files/aws-presigned")
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(
            PresignedUploadRequest(fileName: fileName, contentType: "audio/wav")
        )

        let (data, response) = try await urlSession.data(for: request)
        try validate(response, data: data, context: "presigned URL")

        let decoded = try JSONDecoder().decode(PresignedUploadResponse.self, from: data)
        guard let uploadURL = decoded.uploadURL, let requestID = decoded.requestID else {
            if let body = String(data: data, encoding: .utf8) {
                print("[RealityDefenderVoiceAnalysisClient] presigned URL response did not include expected fields: \(body)")
            }
            throw RealityDefenderError.invalidPresignedResponse
        }

        print("[RealityDefenderVoiceAnalysisClient] Reality Defender requestId: \(requestID)")
        return PresignedUpload(uploadURL: uploadURL, requestID: requestID)
    }

    private func uploadRecording(_ recordingURL: URL, to uploadURL: URL) async throws {
        var request = URLRequest(url: uploadURL)
        request.httpMethod = "PUT"
        request.setValue("audio/wav", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await urlSession.upload(for: request, fromFile: recordingURL)
        try validate(response, data: data, context: "recording upload")
    }

    private func fetchMediaDetail(requestID: String) async throws -> (MediaDetailResponse, String?) {
        let url = baseURL.appending(path: "/api/media/users/\(requestID)")
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let (data, response) = try await urlSession.data(for: request)
        try validate(response, data: data, context: "media detail")

        return (try JSONDecoder().decode(MediaDetailResponse.self, from: data), String(data: data, encoding: .utf8))
    }

    private func mapMediaDetail(_ response: MediaDetailResponse, rawBody: String?) -> VoiceAnalysisResult? {
        guard response.isComplete else { return nil }

        if response.isUnableToEvaluate {
            if let rawBody {
                print("[RealityDefenderVoiceAnalysisClient] Reality Defender could not evaluate recording: \(rawBody)")
            }

            return VoiceAnalysisResult(
                verdict: .inconclusive,
                confidence: 0.5,
                detail: response.failureMessage ?? "Reality Defender could not evaluate this recording."
            )
        }

        if let verdict = response.bestVerdict {
            return VoiceAnalysisResult(
                verdict: verdict,
                confidence: 0.75,
                detail: "Reality Defender returned \(verdict)."
            )
        }

        if let isGenerated = response.isGenerated {
            return VoiceAnalysisResult(
                verdict: isGenerated ? .aiGenerated : .human,
                confidence: 0.75,
                detail: "Reality Defender returned isGenerated=\(isGenerated)."
            )
        }

        if let score = response.explicitManipulationScore {
            let normalizedScore = score > 1 ? score / 100 : score

            if normalizedScore >= 0.70 {
                return VoiceAnalysisResult(
                    verdict: .aiGenerated,
                    confidence: normalizedScore,
                    detail: "Reality Defender manipulation probability \(Int(normalizedScore * 100))%."
                )
            }

            if normalizedScore <= 0.40 {
                return VoiceAnalysisResult(
                    verdict: .human,
                    confidence: 1 - normalizedScore,
                    detail: "Reality Defender manipulation probability \(Int(normalizedScore * 100))%."
                )
            }

            return VoiceAnalysisResult(
                verdict: .inconclusive,
                confidence: 0.5,
                detail: "Reality Defender manipulation probability \(Int(normalizedScore * 100))% is in the review zone."
            )
        }

        if let score = response.bestScore {
            let normalizedScore = score > 1 ? score / 100 : score
            return VoiceAnalysisResult(
                verdict: .inconclusive,
                confidence: 0.5,
                detail: "Reality Defender returned score \(Int(normalizedScore * 100))%, but no clear verdict."
            )
        }

        throwIfFailed(response)
        if let rawBody {
            print("[RealityDefenderVoiceAnalysisClient] completed media detail response had no score/verdict: \(rawBody)")
        }

        return VoiceAnalysisResult(
            verdict: .inconclusive,
            confidence: 0.5,
            detail: "Reality Defender completed without a clear score."
        )
    }

    private func throwIfFailed(_ response: MediaDetailResponse) {
        if response.status?.localizedCaseInsensitiveContains("fail") == true {
            print("[RealityDefenderVoiceAnalysisClient] Analysis failed status: \(response.status ?? "unknown")")
        }
    }

    private func validate(_ response: URLResponse, data: Data, context: String) throws {
        guard let response = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        guard (200..<300).contains(response.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "<non-text response>"
            print("[RealityDefenderVoiceAnalysisClient] \(context) failed with HTTP \(response.statusCode): \(body)")
            throw RealityDefenderError.httpFailure(statusCode: response.statusCode, body: body)
        }
    }
}

private struct PresignedUpload {
    let uploadURL: URL
    let requestID: String
}

private struct PresignedUploadRequest: Encodable {
    let fileName: String
    let contentType: String
}

private struct PresignedUploadResponse: Decodable {
    let response: PresignedUploadResponseBody?
    let signedURL: URL?
    let signedURLSnakeCase: URL?
    let uploadURLValue: URL?
    let uploadURLSnakeCase: URL?
    let url: URL?
    let requestIDValue: String?
    let requestId: String?
    let mediaID: String?
    let mediaId: String?
    let id: String?
    let fileName: String?

    enum CodingKeys: String, CodingKey {
        case response
        case signedURL = "signedUrl"
        case signedURLSnakeCase = "signed_url"
        case uploadURLValue = "uploadUrl"
        case uploadURLSnakeCase = "upload_url"
        case url
        case requestIDValue = "request_id"
        case requestId
        case mediaID = "media_id"
        case mediaId
        case id
        case fileName
    }

    var uploadURL: URL? {
        response?.uploadURL ?? signedURL ?? signedURLSnakeCase ?? uploadURLValue ?? uploadURLSnakeCase ?? url
    }

    var requestID: String? {
        requestIDValue ?? requestId ?? mediaID ?? mediaId ?? id ?? fileName
    }
}

private struct PresignedUploadResponseBody: Decodable {
    let signedURL: URL?
    let signedURLSnakeCase: URL?
    let uploadURLValue: URL?
    let uploadURLSnakeCase: URL?
    let url: URL?

    enum CodingKeys: String, CodingKey {
        case signedURL = "signedUrl"
        case signedURLSnakeCase = "signed_url"
        case uploadURLValue = "uploadUrl"
        case uploadURLSnakeCase = "upload_url"
        case url
    }

    var uploadURL: URL? {
        signedURL ?? signedURLSnakeCase ?? uploadURLValue ?? uploadURLSnakeCase ?? url
    }
}

private struct MediaDetailResponse: Decodable {
    let status: String?
    let score: Double?
    let probability: Double?
    let manipulationProbability: Double?
    let ensembleScore: Double?
    let result: String?
    let verdict: String?
    let isGenerated: Bool?
    let overallStatus: String?
    let resultsSummary: ResultsSummary?
    let models: [ModelResult]?
    let results: [ModelResult]?

    enum CodingKeys: String, CodingKey {
        case status
        case score
        case probability
        case manipulationProbability = "manipulation_probability"
        case ensembleScore = "ensemble_score"
        case result
        case verdict
        case isGenerated = "is_generated"
        case overallStatus
        case resultsSummary
        case models
        case results
    }

    var isComplete: Bool {
        let statuses = [status, overallStatus, resultsSummary?.status]
            .compactMap { $0?.lowercased() }

        if statuses.contains(where: Self.isTerminalStatus) {
            return true
        }

        if statuses.contains(where: { $0 == "analyzing" || $0 == "queued" || $0 == "processing" || $0 == "pending" }) {
            return false
        }

        let modelStatuses = (models ?? []) + (results ?? [])
        if modelStatuses.contains(where: { $0.isAudioModel && $0.isAnalyzing }) {
            return false
        }

        if statuses.isEmpty {
            return bestScore != nil || bestVerdict != nil
        }

        return statuses.contains(where: Self.isTerminalStatus)
    }

    var isUnableToEvaluate: Bool {
        [status, overallStatus, resultsSummary?.status]
            .compactMap { $0?.lowercased() }
            .contains(where: { $0 == "unable_to_evaluate" || $0 == "error" || $0 == "failed" || $0 == "failure" })
    }

    var failureMessage: String? {
        resultsSummary?.error?.message
    }

    var progressSummary: String {
        let topLevelStatus = overallStatus ?? resultsSummary?.status ?? status ?? "unknown"
        let audioStatuses = ((models ?? []) + (results ?? []))
            .filter(\.isAudioModel)
            .compactMap { model in
                guard let name = model.name else { return nil }
                return "\(name)=\(model.status ?? "unknown")"
            }
            .joined(separator: ", ")

        return "overall=\(topLevelStatus), audioModels=[\(audioStatuses)]"
    }

    var bestScore: Double? {
        return [
            score,
            probability,
            manipulationProbability,
            ensembleScore,
            resultsSummary?.bestScore,
            models?.compactMap(\.bestScore).max(),
            results?.compactMap(\.bestScore).max()
        ]
        .compactMap { $0 }
        .first
    }

    var explicitManipulationScore: Double? {
        manipulationProbability
    }

    var bestVerdict: VoiceAnalysisVerdict? {
        [
            verdict,
            result,
            overallStatus,
            resultsSummary?.status,
            models?.compactMap(\.bestVerdictText).first,
            results?.compactMap(\.bestVerdictText).first
        ]
            .compactMap { $0 }
            .compactMap(Self.mapVerdict)
            .first
    }

    private static func mapVerdict(_ raw: String) -> VoiceAnalysisVerdict? {
        let normalized = raw
            .lowercased()
            .replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: " ", with: "_")

        if normalized == "fake" || normalized == "manipulated" {
            return .aiGenerated
        }

        if normalized == "authentic" || normalized == "real" {
            return .human
        }

        if normalized == "inconclusive" || normalized == "unable_to_evaluate" {
            return .inconclusive
        }

        return nil
    }

    private static func isTerminalStatus(_ status: String) -> Bool {
        [
            "authentic",
            "fake",
            "inconclusive",
            "unable_to_evaluate"
        ].contains(status)
    }
}

private struct ResultsSummary: Decodable {
    let status: String?
    let score: Double?
    let finalScore: Double?
    let normalizedPredictionNumber: Double?
    let predictionNumber: Double?
    let error: RealityDefenderAPIError?

    enum CodingKeys: String, CodingKey {
        case status
        case score
        case finalScore
        case normalizedPredictionNumber
        case predictionNumber
        case error
    }

    var bestScore: Double? {
        score ?? finalScore ?? normalizedPredictionNumber ?? predictionNumber
    }
}

private struct RealityDefenderAPIError: Decodable {
    let code: String?
    let message: String?
}

private struct ModelResult: Decodable {
    let name: String?
    let score: Double?
    let finalScore: Double?
    let normalizedPredictionNumber: Double?
    let predictionNumber: Double?
    let verdict: String?
    let result: String?
    let status: String?

    var bestVerdictText: String? {
        verdict ?? result ?? status
    }

    var bestScore: Double? {
        score ?? finalScore ?? normalizedPredictionNumber ?? predictionNumber
    }

    var isAudioModel: Bool {
        name?.lowercased().contains("aud") == true
    }

    var isAnalyzing: Bool {
        guard let status else { return false }
        return ["analyzing", "queued", "processing", "pending"].contains(status.lowercased())
    }

    enum CodingKeys: String, CodingKey {
        case name
        case score
        case finalScore
        case normalizedPredictionNumber
        case predictionNumber
        case verdict
        case result
        case status
    }
}

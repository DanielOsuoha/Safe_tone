//
//  CallSignalingModels.swift
//  SafeTone
//
//  Shared signaling models for call-session lifecycle and realtime transport messages.
//

import Foundation

enum CallSessionState: String, Codable, Equatable {
    case inviting
    case ringing
    case connected
    case ended
    case rejected
    case failed
}

enum ParticipantRole: String, Codable, Equatable {
    case caller
    case callee
}

struct CallParticipant: Codable, Equatable, Identifiable {
    let id: String
    let displayName: String
    let handle: String
    let role: ParticipantRole
}

struct CallSession: Codable, Equatable, Identifiable {
    let id: UUID
    let caller: CallParticipant
    let callee: CallParticipant
    var state: CallSessionState
    let createdAt: Date
}

struct CallInvitePayload: Codable, Equatable {
    let callID: UUID
    let caller: CallParticipant
    let callee: CallParticipant
    let createdAt: Date
}

struct CallAnswerPayload: Codable, Equatable {
    let callID: UUID
    let participantID: String
    let answeredAt: Date
}

struct CallEndPayload: Codable, Equatable {
    let callID: UUID
    let participantID: String
    let endedAt: Date
}

struct CallControlPayload: Codable, Equatable {
    let callID: UUID
    let participantID: String
    let value: Bool
    let sentAt: Date
}

struct WebRTCSessionDescriptionPayload: Codable, Equatable {
    enum DescriptionType: String, Codable, Equatable {
        case offer
        case answer
    }

    let callID: UUID
    let participantID: String
    let type: DescriptionType
    let sdp: String
    let sentAt: Date
}

struct ICECandidatePayload: Codable, Equatable {
    let callID: UUID
    let participantID: String
    let candidate: String
    let sdpMid: String?
    let sdpMLineIndex: Int32?
    let sentAt: Date
}

enum SignalingMessage: Codable, Equatable {
    case callInvite(CallInvitePayload)
    case callAnswer(CallAnswerPayload)
    case callEnd(CallEndPayload)
    case mute(CallControlPayload)
    case speaker(CallControlPayload)
    case sessionDescription(WebRTCSessionDescriptionPayload)
    case iceCandidate(ICECandidatePayload)
}

//
//  CommunityChallenge.swift
//  Racq App
//
//  Created by Deets on 10/29/25.
//

import Foundation

enum ChallengeTrackedStat: String, Codable, CaseIterable, Identifiable {
    case forehands
    case backhands
    case shots
    case durationSec

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .forehands: return "Forehands"
        case .backhands: return "Backhands"
        case .shots: return "Shots"
        case .durationSec: return "Duration (sec)"
        }
    }
}

struct Challenge: Identifiable, Codable, Equatable {
    var id: String?                 // keeping optional to match your existing store
    var title: String
    var goal: Int
    var progress: Int

    /// participantId -> progress
    var participants: [String: Int]

    /// participantId -> display name
    var participantNames: [String: String]

    var sponsor: String?

    var trackedStat: ChallengeTrackedStat
    var minPerSession: Int?

    var updatedAt: Date = Date()

    func isJoined(participantId: String) -> Bool {
        participants[participantId] != nil
    }

    func participantProgress(participantId: String) -> Int {
        participants[participantId] ?? 0
    }

    func participantName(participantId: String) -> String {
        participantNames[participantId] ?? "Unknown"
    }
}

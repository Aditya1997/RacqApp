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
    var id: String?                 // NOTE: you currently treat id as optional in addChallenge
    var title: String
    var goal: Int
    var progress: Int
    var participants: [String: Int]

    // ✅ sponsor optional (already used by your UI)
    var sponsor: String?

    // ✅ NEW: auto-update fields
    var trackedStat: ChallengeTrackedStat
    var minPerSession: Int?

    // ✅ keep updatedAt (you already read/write it)
    var updatedAt: Date = Date()
}

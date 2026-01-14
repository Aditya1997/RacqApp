//
//  UserProfile.swift
//  Racq App
//
//  Created by Deets on 1/12/26.
//

import Foundation
import FirebaseFirestore

struct UserProfile {
    var displayName: String
    var dateJoined: Date
    var sessionsCompleted: Int
    var totalHits: Int
    var totalForehands: Int
    var totalBackhands: Int
    var totalDurationSec: Int
    var fastestSwing: Double

    static func empty(displayName: String) -> UserProfile {
        UserProfile(
            displayName: displayName,
            dateJoined: Date(),
            sessionsCompleted: 0,
            totalHits: 0,
            totalForehands: 0,
            totalBackhands: 0,
            totalDurationSec: 0,
            fastestSwing: 0.00
        )
    }
}

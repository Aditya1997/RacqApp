//
//  SessionSummary.swift
//  Racq App
//
//  Created by Deets on 1/9/26.
//

import Foundation

struct SessionSummary: Equatable {
    let timestampISO: String
    let durationSec: Int
    let heartRate: Double
    let avgHeartRate: Double
    let shotCount: Int
    let forehandCount: Int
    let backhandCount: Int
    let fastestSwing: Double

    func value(for stat: ChallengeTrackedStat) -> Int {
        switch stat {
        case .forehands: return forehandCount
        case .backhands: return backhandCount
        case .shots: return shotCount
        case .durationSec: return durationSec
        }
    }
}

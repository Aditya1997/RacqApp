//
//  UserStats.swift
//  Racq App
//
//  Created by Deets on 2/5/26.
//


import Foundation

struct UserStats: Equatable {
    var sessionsCompleted: Int
    var totalHits: Int
    var totalForehands: Int
    var totalBackhands: Int
    var totalDurationSec: Int
    var fastestSwing: Double

    static let zero = UserStats(
        sessionsCompleted: 0,
        totalHits: 0,
        totalForehands: 0,
        totalBackhands: 0,
        totalDurationSec: 0,
        fastestSwing: 0.0
    )
}

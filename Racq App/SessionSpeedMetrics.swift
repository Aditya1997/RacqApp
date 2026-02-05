//
//  SessionSpeedMetrics.swift
//  Racq App
//
//  Created by Deets on 2/4/26.
//


import Foundation

struct SessionSpeedMetrics {
    let fhMaxMph: Double
    let fhAvgMph: Double
    let bhMaxMph: Double
    let bhAvgMph: Double

    var overallMaxMph: Double { max(fhMaxMph, bhMaxMph) }
}

enum SessionSpeedBuilder {
    static func build(swings: [SwingSummaryCSV], heightInInches: Double) -> SessionSpeedMetrics {
        let fhMax = SwingMath.maxFHSpeed(swings: swings, height: heightInInches)
        let fhAvg = SwingMath.avgFHSpeed(swings: swings, height: heightInInches)
        let bhMax = SwingMath.maxBHSpeed(swings: swings, height: heightInInches)
        let bhAvg = SwingMath.avgBHSpeed(swings: swings, height: heightInInches)

        return SessionSpeedMetrics(
            fhMaxMph: fhMax,
            fhAvgMph: fhAvg,
            bhMaxMph: bhMax,
            bhAvgMph: bhAvg
        )
    }
}

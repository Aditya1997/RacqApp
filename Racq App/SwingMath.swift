//
//  SwingMath.swift
//  Racq App
//
//  Created by Deets on 12/5/25.
//

import Foundation

struct SwingMath {
    
    static func avgRHSpeed(swings: [SwingSummaryCSV], height: Double) -> Double {
        guard !swings.isEmpty else { return 0 }
        let avgGyro = swings.map { $0.peakGyro }.reduce(0, +) / Double(swings.count)
        return avgGyro * ((height * 0.38) + 11.5) / 17.6
    }
    
    static func maxRHSpeed(swings: [SwingSummaryCSV], height: Double) -> Double {
        guard !swings.isEmpty else { return 0 }
        let peakGyro = swings.map { $0.peakGyro }.max() ?? 0
        return peakGyro * ((height * 0.38) + 11.5) / 17.6
    }
    
    static func avgPeakAcc(swings: [SwingSummaryCSV]) -> Double {
        guard !swings.isEmpty else { return 0 }
        return swings.map { $0.peak }.reduce(0, +) / Double(swings.count)
    }
    
    static func avgPeakRotVelocity(swings: [SwingSummaryCSV]) -> Double {
        guard !swings.isEmpty else { return 0 }
        return swings.map { $0.peakGyro }.reduce(0, +) / Double(swings.count)
    }
    
    static func peakRotVelocity(swings: [SwingSummaryCSV]) -> Double {
        swings.map { $0.peakGyro }.max() ?? 0
    }
    
    static func avgDuration(swings: [SwingSummaryCSV]) -> Double {
            guard !swings.isEmpty else { return 0 }
            return swings.map { $0.duration }.reduce(0, +) / Double(swings.count)
        }
}

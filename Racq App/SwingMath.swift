//
//  SwingMath.swift
//  Racq App
//
//  Created by Deets on 12/5/25.
//

import Foundation

struct SwingMath {
    
    // MARK: - Helper
    
    // gyro speed to racket head MPH
    private static func gyroToMPH(_ gyro: Double, height: Double) -> Double {
        gyro * ((height * 0.38) + 11.5) / 17.6
    }
    
    // Filter swings based on type
    private static func filterSwings(ofType type: String, from swings: [SwingSummaryCSV]) -> [SwingSummaryCSV] {
        swings.filter { $0.type.lowercased() == type.lowercased() }
    }
    
    // MARK: - ALL SWINGS
    
    static func avgRHSpeed(swings: [SwingSummaryCSV], height: Double) -> Double {
        guard !swings.isEmpty else { return 0 }
        let avgGyro = swings.map { $0.peakGyro }.reduce(0, +) / Double(swings.count)
        return gyroToMPH(avgGyro, height: height)
    }
    
    static func maxRHSpeed(swings: [SwingSummaryCSV], height: Double) -> Double {
        guard !swings.isEmpty else { return 0 }
        let maxGyro = swings.map { $0.peakGyro }.max() ?? 0
        return gyroToMPH(maxGyro, height: height)
    }
    
    
    // MARK: - FOREHANDS ONLY
    
    static func avgFHSpeed(swings: [SwingSummaryCSV], height: Double) -> Double {
        let fh = filterSwings(ofType: "forehand", from: swings)
        guard !fh.isEmpty else { return 0 }
        let avgGyro = fh.map { $0.peakGyro }.reduce(0, +) / Double(fh.count)
        return gyroToMPH(avgGyro, height: height)
    }
    
    static func maxFHSpeed(swings: [SwingSummaryCSV], height: Double) -> Double {
        let fh = filterSwings(ofType: "forehand", from: swings)
        guard !fh.isEmpty else { return 0 }
        let maxGyro = fh.map { $0.peakGyro }.max() ?? 0
        return gyroToMPH(maxGyro, height: height)
    }
    
    
    // MARK: - BACKHANDS ONLY
    
    static func avgBHSpeed(swings: [SwingSummaryCSV], height: Double) -> Double {
        let bh = filterSwings(ofType: "backhand", from: swings)
        guard !bh.isEmpty else { return 0 }
        let avgGyro = bh.map { $0.peakGyro }.reduce(0, +) / Double(bh.count)
        return gyroToMPH(avgGyro, height: height)
    }
    
    static func maxBHSpeed(swings: [SwingSummaryCSV], height: Double) -> Double {
        let bh = filterSwings(ofType: "backhand", from: swings)
        guard !bh.isEmpty else { return 0 }
        let maxGyro = bh.map { $0.peakGyro }.max() ?? 0
        return gyroToMPH(maxGyro, height: height)
    }
    
    
    // MARK: - Other Existing Metrics
    
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

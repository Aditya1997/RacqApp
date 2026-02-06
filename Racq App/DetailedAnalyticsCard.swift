//
//  DetailedAnalyticsCard.swift
//  Racq App
//
//  Created by Deets on 1/30/26.
//


import SwiftUI

let cardBG = Color(red: 0.05, green: 0.12, blue: 0.28)

struct DetailedAnalyticsCard: View {
    let swings: [SwingSummaryCSV]
    let userHeightInInches: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Detailed Analytics")
                .font(.headline)

            if swings.isEmpty {
                Text("No swing CSV data available yet.")
                    .foregroundColor(.secondary)
                    .font(.subheadline)
            } else {
                Divider()

                VStack(alignment: .leading, spacing: 8) {
                    Text("Avg Peak Acc: \(avgPeakAcc(), specifier: "%.2f") g")
                    Text("Avg Peak Angular Velocity: \(avgPeakRotVelocity(), specifier: "%.2f") rad/s")
                    Text("Avg Peak RH Velocity (est): \(String(format: "%.2f", SwingMath.avgRHSpeed(swings: swings, height: userHeightInInches))) mph")
                    Text("Maximum Angular Velocity: \(peakRotVelocity(), specifier: "%.2f") rad/s")
                    Text("Maximum RH Velocity (est): \(String(format: "%.2f", SwingMath.maxRHSpeed(swings: swings, height: userHeightInInches))) mph")
                    Text("Avg Duration: \(avgDuration(), specifier: "%.2f") s")
                    Text("Total Swings: \(swings.count)")
                }
                .font(.subheadline)
                .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(cardBG)
        )
        .cornerRadius(16)
    }

    private func peakRotVelocity() -> Double {
        swings.map { $0.peakGyro }.max() ?? 0
    }

    private func avgPeakRotVelocity() -> Double {
        guard !swings.isEmpty else { return 0 }
        return swings.map { $0.peakGyro }.reduce(0, +) / Double(swings.count)
    }

    private func avgPeakAcc() -> Double {
        guard !swings.isEmpty else { return 0 }
        return swings.map { $0.peak }.reduce(0, +) / Double(swings.count)
    }

    private func avgDuration() -> Double {
        guard !swings.isEmpty else { return 0 }
        return swings.map { $0.duration }.reduce(0, +) / Double(swings.count)
    }
}

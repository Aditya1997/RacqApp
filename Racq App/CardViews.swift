//
//  CardViews.swift
//  Racq App
//
//  Created by Deets on 12/11/25.
//

import SwiftUI

// MARK: - SummaryBlock (single value)
struct SummaryBlock: View {
    var title: String
    var value: String
    var icon: AnyView? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                if let icon = icon {
                    icon
                        .frame(width: 25, height: 25)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(value)
                        .foregroundColor(.white)
                        .font(.system(size: 20, weight: .bold))
                        .lineLimit(1)
                        .layoutPriority(1) // Set priority to this
                        .fixedSize(horizontal: true, vertical: false)
                    Text(title)
                        .foregroundColor(.white.opacity(0.85))
                        .font(.system(size: 14, weight: .medium))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                        .allowsTightening(true)
                }
                .padding(.horizontal, 3)
                .multilineTextAlignment(.trailing)
            }
            .padding(.horizontal, 2)
        }
        .padding(.vertical, 3)
        .padding(.horizontal, 3)
        .frame(height: 85)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(cardBG)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.orange.opacity(0.85), lineWidth: 0.75)
        )
        .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Combined Speed Card (max + avg + bar + both hands)

struct CombinedSpeedCard: View {
    var fhTitle: String
    var fhMaxValue: String
    var fhAvgValue: String
    var fhRatio: CGFloat
    var fhColor: Color
    var fhIcon: AnyView? = nil

    var bhTitle: String
    var bhMaxValue: String
    var bhAvgValue: String
    var bhRatio: CGFloat
    var bhColor: Color
    var bhIcon: AnyView? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // forehand row
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fhTitle)
                            .foregroundColor(.white.opacity(0.75))
                            .font(.subheadline)
                        if let icon = fhIcon {
                            icon
                                .frame(width: 30, height: 30)
                        }
                    }
                    Spacer()
                    Text(fhMaxValue)
                        .foregroundColor(.white)
                        .font(.system(size: 24, weight: .bold))
                }
                // forehand bar
                ZStack(alignment: .leading) {
                    // Background bar (always visible)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 16)
                    GeometryReader { geo in
                        let clamped = max(min(fhRatio, 1), 0)
                        let barWidth = geo.size.width * clamped
                        // Foreground colored bar
                        RoundedRectangle(cornerRadius: 6)
                            .fill(fhColor)
                            .frame(width: barWidth, height: 16)
                    }
                }
                .overlay(
                    Text("\(fhAvgValue) avg")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.leading, 4)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7),
                )
                .frame(maxWidth: .infinity)
                .frame(height: 16)
            }
            //Divider()
            //    .background(Color.white.opacity(0.3))
            // backhand row
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bhTitle)
                            .foregroundColor(.white.opacity(0.75))
                            .font(.subheadline)
                        if let icon = bhIcon {
                            icon
                                .frame(width: 30, height: 30)
                        }
                    }
                    Spacer()
                    Text(bhMaxValue)
                        .foregroundColor(.white)
                        .font(.system(size: 24, weight: .bold))
                }
                // backhand bar
                ZStack(alignment: .leading) {
                    // Background bar (always visible)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 16)
                    GeometryReader { geo in
                        let clamped = max(min(bhRatio, 1), 0)
                        let barWidth = geo.size.width * clamped
                        // Foreground colored bar
                        RoundedRectangle(cornerRadius: 6)
                            .fill(bhColor)
                            .frame(width: barWidth, height: 16)
                    }
                }
                .overlay(
                    Text("\(bhAvgValue) avg")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.leading, 4)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7),
                )
                .frame(maxWidth: .infinity)
                .frame(height: 16)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(cardBG)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.orange.opacity(0.85), lineWidth: 0.75)
        )
        .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
    }
}

// MARK: - One Hand Speed (max + avg + bar) (UNUSED)

struct OneHandSpeedCard: View {
    var title: String
    var maxValue: String
    var avgValue: String
    var avgRatio: CGFloat
    var barColor: Color = .blue
    var icon: AnyView? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Title + Max Value Row
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .foregroundColor(.white.opacity(0.75))
                        .font(.subheadline)
                    if let icon = icon {
                        icon.frame(width: 30, height: 30)
                    }
                }
                Spacer()
                Text(maxValue)
                    .foregroundColor(.white)
                    .font(.system(size: 28, weight: .bold))
            }
            // Avg Bar
            VStack(alignment: .leading, spacing: 6) {
                // Background bar
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 8)
                    .overlay(
                        // Foreground bar
                        GeometryReader { geo in
                            let clamped = max(min(avgRatio, 1), 0)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(barColor)
                                .frame(width: geo.size.width * clamped)
                        }
                    )
                Text("\(avgValue) avg")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Detailed Summary Card (UNUSED)
private struct DetailedSummaryCard: View {
    let shots: Int
    let durationSec: Int
    let heartRate: Double
    let csvURL: URL?
    // 🟢 NEW:
    let forehandCount: Int
    let backhandCount: Int
    let swings: [SwingSummaryCSV]
    @AppStorage("userHeightInInches") private var userHeight: Double = 70
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            
            Text("Session Summary")
                .font(.title2).bold()
            
            HStack {
                stat(title: "Shots", value: "\(shots)")
                Spacer()
                stat(title: "Duration", value: format(durationSec))
                Spacer()
                stat(title: "Heart", value: "\(Int(heartRate)) BPM")
            }
            
            // 🟢 NEW: Add FH/BH row
            HStack {
                stat(title: "Forehands", value: "\(forehandCount)")
                    .foregroundColor(.yellow)
                Spacer()
                stat(title: "Backhands", value: "\(backhandCount)")
                    .foregroundColor(.cyan)
            }
            
            if !swings.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 8) {
                    Text("Swing Details")
                        .font(.headline)
                    Text("Avg Peak Acc: \(avgPeakAcc(), specifier: "%.2f") g")
                    Text("Avg Peak Angular Velocity: \(avgPeakRotVelocity(), specifier: "%.2f") rad/s")
                    Text("Avg Peak RH Velocity (est): \(String(format: "%.2f", SwingMath.avgRHSpeed(swings: swings, height: userHeight))) mph")
                    Text("Maximum Angular Velocity: \(peakRotVelocity(), specifier: "%.2f") rad/s")
                    Text("Maximum RH Velocity (est): \(String(format: "%.2f", SwingMath.maxRHSpeed(swings: swings, height: userHeight))) mph")
                    Text("Avg Duration: \(avgDuration(), specifier: "%.2f") s")
                    Text("Total Swings: \(swings.count)")
                }
            }
            if let url = csvURL {
                Button {
                    shareCSV(url)
                } label: {
                    Label("Share CSV", systemImage: "square.and.arrow.up")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            } else {
                HStack {
                    ProgressView()
                    Text("Preparing CSV…")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
    
    private func peakRotVelocity() -> Double {
        guard !swings.isEmpty else { return 0 }
        return swings.map { $0.peakGyro }.max() ?? 0
    }
    
    private func avgPeakRotVelocity() -> Double {
        guard !swings.isEmpty else { return 0 }
        return swings.map { $0.peakGyro }.reduce(0, +) / Double(swings.count)
    }
    
    private func avgPeakAcc() -> Double {
        guard !swings.isEmpty else { return 0 }
        return swings.map { $0.peak }.reduce(0, +) / Double(swings.count)
    }
    
    private func peakAcc() -> Double {
        guard !swings.isEmpty else { return 0 }
        return swings.map { $0.peak }.max() ?? 0
    }

    private func avgDuration() -> Double {
        guard !swings.isEmpty else { return 0 }
        return swings.map { $0.duration }.reduce(0, +) / Double(swings.count)
    }
    
    private func avgRHSpeed() -> Double {
        guard !swings.isEmpty else { return 0 }
        let avgPeakRotVelocity = swings.map { $0.peakGyro }.reduce(0, +) / Double(swings.count)
        return avgPeakRotVelocity * ((userHeight * 0.38) + 11.5) / 17.6
    }

    private func maxRHSpeed() -> Double {
        guard !swings.isEmpty else { return 0 }
        let peakRotVelocity = swings.map { $0.peakGyro }.max() ?? 0
        return peakRotVelocity * ((userHeight * 0.38) + 11.5) / 17.6
    }
    
    private func stat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundColor(.secondary)
            Text(value).font(.headline)
        }
    }

    private func format(_ sec: Int) -> String {
        let m = sec / 60
        let s = sec % 60
        return String(format: "%02d:%02d", m, s)
    }
    
    private func shareCSV(_ url: URL) {
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.rootViewController?
            .present(vc, animated: true)
    }
}

//
//  RecordView.swift
//  Racq App
//
//  Created by Deets on 1/12/26.
//

//
//  RecordView.swift
//  Racq App
//
//  Created by Deets on 1/12/26.
//

import SwiftUI
import UIKit

func loadSwingSummaryCSV(from url: URL) -> [SwingSummaryCSV] {
    guard let raw = try? String(contentsOf: url, encoding: .utf8) else { return [] }

    let rows = raw
        .replacingOccurrences(of: "\r", with: "")
        .components(separatedBy: "\n")
        .filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }

    guard rows.count > 1 else { return [] }

    var results: [SwingSummaryCSV] = []

    for row in rows.dropFirst() {
        // split, but tolerate extra columns
        let cols = row.components(separatedBy: ",")
        if cols.count < 5 { continue }

        let timestamp = cols[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let typeRaw = cols[1].trimmingCharacters(in: .whitespacesAndNewlines)

        let peak = Double(cols[2].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let peakGyro = Double(cols[3].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
        let duration = Double(cols[4].trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0

        // skip clearly bad rows
        if timestamp.isEmpty { continue }

        results.append(
            SwingSummaryCSV(
                timestamp: timestamp,
                type: typeRaw,
                peak: peak,
                peakGyro: peakGyro,
                duration: duration
            )
        )
    }

    print("📄 Parsed swings:", results.count, "from", url.lastPathComponent)
    if let first = results.first { print("🔎 first swing row type=", first.type) }
    if let last = results.last { print("🔎 last swing row type=", last.type) }

    return results
}

struct RecordView: View {
    @ObservedObject var wc = PhoneWCManager.shared
    @State private var swings: [SwingSummaryCSV] = []

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 18) {

                    // Connection pill (non-blocking)
                    HStack(spacing: 8) {
                        Circle().fill(wc.isConnected ? Color.green : Color.orange)
                            .frame(width: 10, height: 10)

                        Text(wc.isConnected ? "Watch Connected" : "Phone-only mode")
                            .foregroundColor(.secondary)
                            .font(.subheadline)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    if wc.summaryTimestampISO.isEmpty {
                        emptyState
                    } else {
                        heartRateCard(bpm: wc.summaryHeartRate)
                        detailedSummaryCardView
                    }

                    Spacer(minLength: 10)
                }
                .padding()
                .onAppear {
                    if let url = wc.summaryCSVURL {
                        swings = loadSwingSummaryCSV(from: url)
                    }
                }
                .onChange(of: wc.summaryCSVURL) { newURL in
                    if let url = newURL {
                        swings = loadSwingSummaryCSV(from: url)
                    } else {
                        swings = []
                    }
                }
            }
            .navigationTitle("Record")
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Text("No session data yet.")
                .foregroundColor(.gray)
            Text("Complete a session to see your stats here.")
                .font(.footnote)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
    }

    private var detailedSummaryCardView: some View {
        DetailedSummaryCard(
            shots: wc.summaryShotCount,
            durationSec: wc.summaryDurationSec,
            heartRate: wc.summaryHeartRate,
            csvURL: wc.csvURL,
            forehandCount: wc.summaryforehandCount,
            backhandCount: wc.summarybackhandCount,
            swings: swings
        )
    }

    private func heartRateCard(bpm: Double) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Heart Rate Chart?")
                .font(.headline)

            HStack(alignment: .firstTextBaseline) {
                Text(bpm > 0 ? "\(Int(bpm))" : "--")
                    .font(.system(size: 44, weight: .bold))
                Text("BPM")
                    .font(.headline)
                    .foregroundColor(.secondary)

                Spacer()

                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                    .font(.title2)
            }

            Text("Session average heart rate")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - Detailed Summary Card
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
// MARK: - Record Summary Card (unique name to avoid collisions)
//private struct RecordSummaryCard: View {
//    let shots: Int
//    let durationSec: Int
//    let heartRate: Double
//    let csvURL: URL?
//    let forehandCount: Int
//    let backhandCount: Int
//    let swings: [SwingSummaryCSV]
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 14) {
//            Text("Session Summary")
//                .font(.title2).bold()
//
//            HStack {
//                stat(title: "Shots", value: "\(shots)")
//                Spacer()
//                stat(title: "Duration", value: format(durationSec))
//                Spacer()
//                stat(title: "HR", value: "\(Int(heartRate)) BPM")
//            }
//
//            HStack {
//                stat(title: "Forehands", value: "\(forehandCount)")
//                    .foregroundColor(.yellow)
//                Spacer()
//                stat(title: "Backhands", value: "\(backhandCount)")
//                    .foregroundColor(.cyan)
//            }
//
//            if let url = csvURL {
//                Button {
//                    share(url)
//                } label: {
//                    Label("Share CSV", systemImage: "square.and.arrow.up")
//                        .frame(maxWidth: .infinity)
//                        .padding()
//                        .background(Color.blue)
//                        .foregroundColor(.white)
//                        .cornerRadius(12)
//                }
//            } else {
//                HStack {
//                    ProgressView()
//                    Text("Preparing CSV…")
//                        .foregroundColor(.secondary)
//                }
//            }
//        }
//        .padding()
//        .frame(maxWidth: .infinity)
//        .background(Color(UIColor.secondarySystemBackground))
//        .cornerRadius(16)
//    }
//
//    private func stat(title: String, value: String) -> some View {
//        VStack(alignment: .leading, spacing: 4) {
//            Text(title).font(.caption).foregroundColor(.secondary)
//            Text(value).font(.headline)
//        }
//    }
//
//    private func format(_ sec: Int) -> String {
//        let m = sec / 60
//        let s = sec % 60
//        return String(format: "%02d:%02d", m, s)
//    }
//
//    private func share(_ url: URL) {
//        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
//        UIApplication.shared.connectedScenes
//            .compactMap { $0 as? UIWindowScene }
//            .first?.keyWindow?.rootViewController?
//            .present(vc, animated: true)
//    }
//}

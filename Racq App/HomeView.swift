//
//  HomeView.swift
//  RacqApp
//  10/29/2025 updates for proper homeview
//  11/13/2025 Adding swing summary tab
//  11/19/2025 Using height in swing speed calc

import SwiftUI
import UIKit
import WatchConnectivity

struct SwingSummaryCSV: Identifiable {
    let id = UUID()
    let timestamp: String
    let type: String
    let peak: Double
    let peakGyro: Double
    let duration: Double
}

func loadSwingSummaryCSV(from url: URL) -> [SwingSummaryCSV] {
    guard let raw = try? String(contentsOf: url, encoding: .utf8) else { return [] }
    let rows = raw.components(separatedBy: .newlines)
    guard rows.count > 1 else { return [] }

    var results: [SwingSummaryCSV] = []

    for row in rows.dropFirst() {
        let cols = row.components(separatedBy: ",")
        guard cols.count == 5 else { continue }

        if let peak = Double(cols[2]), let peakGyro = Double(cols[3]),
           let duration = Double(cols[4]) {

            results.append(
                SwingSummaryCSV(
                    timestamp: cols[0],
                    type: cols[1],
                    peak: peak,
                    peakGyro: peakGyro,
                    duration: duration
                )
            )
        }
    }

    return results
}



struct HomeView: View { // Renamed from ContentView
    @ObservedObject var wc = PhoneWCManager.shared
    @State private var swings: [SwingSummaryCSV] = []

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // connection pill
                HStack(spacing: 8) {
                    Circle().fill(wc.isConnected ? Color.green : Color.red)
                        .frame(width: 12, height: 12)
                    Text(wc.isConnected ? "Watch Connected" : "Watch Not Connected")
                        .foregroundColor(.secondary)
                        .font(.subheadline)
                }
                Divider()
                // PLAYER HEIGHT SECTION (always visible)
                PlayerHeightView()

                Divider()
                // SUMMARY (shown automatically when data arrives)
                if wc.summaryTimestampISO.isEmpty {
                    VStack(spacing: 8) {
                        Text("No session data yet.")
                            .foregroundColor(.gray)
                        Text("Stop a session on your Watch to see the summary here.")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    SummaryCard(
                        shots: wc.summaryShotCount,
                        durationSec: wc.summaryDurationSec,
                        heartRate: wc.summaryHeartRate,
                        csvURL: wc.csvURL,
                        forehandCount: wc.summaryforehandCount,
                        backhandCount: wc.summarybackhandCount,
                        swings: swings,
                        userHeight: wc.userHeight
                    )
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Racq Tracker")
            .onAppear {
                let userHeight = UserDefaults.standard.double(forKey: "userHeightInInches")
                WCSession.default.sendMessage(["height": userHeight], replyHandler: nil)
                if let url = wc.summaryCSVURL {
                    swings = loadSwingSummaryCSV(from: url)
                }
            }
        }
    }
}

// MARK: - Player Height Slider

struct PlayerHeightView: View {
    @AppStorage("userHeightInInches") var userHeight: Double = 70

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Player Height")
                .font(.headline)

            HStack {
                Slider(value: $userHeight, in: 55...80, step: 1)
                Text("\(Int(userHeight)) in")
                    .frame(width: 50)
            }
            .onChange(of: userHeight) { newValue in
                WCSession.default.sendMessage(["height": newValue], replyHandler: nil)
            }
        }
    }
}

// MARK: - Summary Card
private struct SummaryCard: View {
    let shots: Int
    let durationSec: Int
    let heartRate: Double
    let csvURL: URL?
    // 🟢 NEW:
    let forehandCount: Int
    let backhandCount: Int
    let swings: [SwingSummaryCSV]
    let userHeight: Double
       
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
                    Text("Avg Peak Racket Head Velocity (estimated): \(String(format: "%.2f", avgPeakRotVelocity() * ((userHeight * 0.38) + 10) / 17.6)) mph")
                    Text("Maximum Angular Velocity: \(peakRotVelocity(), specifier: "%.2f") rad/s")
                    Text("Maximum Racket Head Velocity (estimated): \(String(format: "%.2f", peakRotVelocity() * ((userHeight * 0.38) + 10) / 17.6)) mph")
                    Text("Avg Duration: \(avgDuration(), specifier: "%.2f") s")
                    //Text("Total Swings: \(swings.count)")
                }
            }
            if let url = csvURL {
                Button {
                    share(url)
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

    private func share(_ url: URL) {
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.rootViewController?
            .present(vc, animated: true)
    }
}

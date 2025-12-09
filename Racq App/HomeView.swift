//
//  HomeView.swift
//  RacqApp
//  10/29/2025 updates for proper homeview
//  11/13/2025 Adding swing summary tab
//  11/19/2025 Using height in swing speed calc

import SwiftUI
import UIKit
import WatchConnectivity

//struct SwingSummaryCSV: Identifiable {
//    let id = UUID()
//    let timestamp: String
//    let type: String
//    let peak: Double
//    let peakGyro: Double
//    let duration: Double
//}
//
//func loadSwingSummaryCSV(from url: URL) -> [SwingSummaryCSV] {
//    guard let raw = try? String(contentsOf: url, encoding: .utf8) else { return [] }
//    let rows = raw.components(separatedBy: .newlines)
//    guard rows.count > 1 else { return [] }
//
//    var results: [SwingSummaryCSV] = []
//
//    for row in rows.dropFirst() {
//        let cols = row.components(separatedBy: ",")
//        guard cols.count == 5 else { continue }
//
//        if let peak = Double(cols[2]), let peakGyro = Double(cols[3]),
//           let duration = Double(cols[4]) {
//
//            results.append(
//                SwingSummaryCSV(
//                    timestamp: cols[0],
//                    type: cols[1],
//                    peak: peak,
//                    peakGyro: peakGyro,
//                    duration: duration
//                )
//            )
//        }
//    }
//
//    return results
//}

// MARK: - Colors and Icons
private let blueGradient = LinearGradient(
    colors: [.blue.opacity(0.8), .blue],
    startPoint: .topLeading, endPoint: .bottomTrailing
)

private let greenGradient = LinearGradient(
    colors: [.green.opacity(0.8), .green],
    startPoint: .topLeading, endPoint: .bottomTrailing
)
private let yellowGradient = LinearGradient(
    colors: [.yellow.opacity(0.8), .yellow],
    startPoint: .topLeading, endPoint: .bottomTrailing
)

private let purpleGradient = LinearGradient(
    colors: [.purple.opacity(0.8), .purple],
    startPoint: .topLeading, endPoint: .bottomTrailing
)

private let orangeGradient = LinearGradient(
    colors: [.orange.opacity(0.8), .orange],
    startPoint: .topLeading, endPoint: .bottomTrailing
)

private let grayGradient = LinearGradient(
    colors: [.gray.opacity(0.8), .gray],
    startPoint: .topLeading, endPoint: .bottomTrailing
)

private let redGradient = LinearGradient(
    colors: [.red.opacity(0.8), .red],
    startPoint: .topLeading, endPoint: .bottomTrailing
)

private func letterIcon(_ letter: String) -> some View {
    Text(letter)
        .font(.system(size: 18, weight: .bold))
        .foregroundColor(.white)
        .frame(width: 32, height: 32)
        .background(Color.white.opacity(0.25))
        .clipShape(Circle())
}

private func sfIcon(_ name: String) -> some View {
    Image(systemName: name)
        .font(.system(size: 20, weight: .semibold))
        .foregroundColor(.white.opacity(0.9))
}

// MARK: - Struct
struct HomeView: View { // Renamed from ContentView
    @ObservedObject var wc = PhoneWCManager.shared
    @State private var swings: [SwingSummaryCSV] = []
    @AppStorage("userHeightInInches") private var userHeight: Double = 70

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
    // MOST RECENT SESSION STATS
                    VStack(spacing: 12) {
                        Text("Latest Session")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Image("tennis_court")
                            .resizable()
                            .scaledToFill()
                            .frame(height: 180)
                            .clipped()
                            .cornerRadius(16)
                            .overlay(
                                LinearGradient(
                                    colors: [.black.opacity(0.4), .clear],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .padding(.horizontal)
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16),
                                GridItem(.flexible(), spacing: 16)
                            ],
                            spacing: 16
                        ) {
                            summaryCard(
                                title: "Shots",
                                value: "\(wc.summaryShotCount)",
                                iconView: sfIcon("tennisball.fill"),
                                gradient: greenGradient
                            )
                            summaryCard(
                                title: "Forehands",
                                value: "\(wc.summaryforehandCount)",
                                iconView: letterIcon("F"),
                                gradient: blueGradient
                            )
                            summaryCard(
                                title: "Backhands",
                                value: "\(wc.summarybackhandCount)",
                                iconView: letterIcon("B"),
                                gradient: yellowGradient
                            )
                            summaryCard(
                                title: "Duration",
                                value: format(wc.summaryDurationSec),
                                iconView: sfIcon("clock.fill"),
                                gradient: orangeGradient
                            )
                            summaryCard(
                                title: "Avg Speed",
                                value: String(format: "%.1f mph",
                                              SwingMath.avgRHSpeed(swings: swings, height: userHeight)),
                                iconView: sfIcon("gauge.high"),
                                gradient: purpleGradient
                            )
                            summaryCard(
                                title: "Max Speed",
                                value: String(format: "%.1f mph",
                                              SwingMath.maxRHSpeed(swings: swings, height: userHeight)),
                                iconView: sfIcon("bolt.fill"),
                                gradient: redGradient
                            )
                        }
                        .padding()
                        .background(Color(UIColor.secondarySystemBackground))
                        .cornerRadius(20)
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                    }
                }
                Spacer()
            }
            .padding()
            .navigationTitle("Racq Tracker")
            .navigationBarTitleDisplayMode(.inline)  // FIXES OVERLAP
            .onAppear {
                let userHeight = UserDefaults.standard.double(forKey: "userHeightInInches")
                WCSession.default.sendMessage(["height": userHeight], replyHandler: nil)

                if let url = wc.summaryCSVURL {
                    swings = loadSwingSummaryCSV(from: url)
                }
            }
            .onChange(of: wc.summaryCSVURL) { newURL in
                if let url = newURL {
                    swings = loadSwingSummaryCSV(from: url)
                }
            }
        }
    }
}

private func format(_ sec: Int) -> String {
    let m = sec / 60
    let s = sec % 60
    return String(format: "%02d:%02d", m, s)
}


// MARK: - summaryBox

private func summaryCard(
    title: String,
    value: String,
    iconView: some View,
    gradient: LinearGradient
) -> some View {

    ZStack {   // ← FIXED SIZE OUTER CONTAINER
        RoundedRectangle(cornerRadius: 16)
            .fill(gradient)
            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)

        VStack(alignment: .leading, spacing: 8) {
            HStack {
                iconView
                    .frame(width: 28, height: 28)     // FORCE FIXED ICON SIZE
                Spacer()
            }

            Text(value)
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.85))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding()
    }
    .frame(height: 135)
}

// MARK: - Player Height Slider

//struct PlayerHeightView: View {
//    @AppStorage("userHeightInInches") var userHeight: Double = 70
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 8) {
//            Text("Player Height")
//                .font(.headline)
//
//            HStack {
//                Slider(value: $userHeight, in: 55...80, step: 1)
//                Text("\(Int(userHeight)) in")
//                    .frame(width: 50)
//            }
//            .onChange(of: userHeight) { newValue in
//                WCSession.default.sendMessage(["height": newValue], replyHandler: nil)
//            }
//        }
//    }
//}

//// MARK: - Summary Card
//private struct SummaryCard: View {
//    let shots: Int
//    let durationSec: Int
//    let heartRate: Double
//    let csvURL: URL?
//    // 🟢 NEW:
//    let forehandCount: Int
//    let backhandCount: Int
//    let swings: [SwingSummaryCSV]
//    @AppStorage("userHeightInInches") private var userHeight: Double = 70
//
//    var body: some View {
//        VStack(alignment: .leading, spacing: 14) {
//            
//            Text("Session Summary")
//                .font(.title2).bold()
//            
//            HStack {
//                stat(title: "Shots", value: "\(shots)")
//                Spacer()
//                stat(title: "Duration", value: format(durationSec))
//                Spacer()
//                stat(title: "Heart", value: "\(Int(heartRate)) BPM")
//            }
//
//            // 🟢 NEW: Add FH/BH row
//            HStack {
//               stat(title: "Forehands", value: "\(forehandCount)")
//                   .foregroundColor(.yellow)
//               Spacer()
//               stat(title: "Backhands", value: "\(backhandCount)")
//                   .foregroundColor(.cyan)
//           }
//            
//            if !swings.isEmpty {
//                Divider()
//                VStack(alignment: .leading, spacing: 8) {
//                    Text("Swing Details")
//                        .font(.headline)
//                    Text("Avg Peak Acc: \(avgPeakAcc(), specifier: "%.2f") g")
//                    Text("Avg Peak Angular Velocity: \(avgPeakRotVelocity(), specifier: "%.2f") rad/s")
//                    Text("Avg Peak RH Velocity (est): \(String(format: "%.2f", avgPeakRotVelocity() * ((userHeight * 0.38) + 11.5) / 17.6)) mph")
//                    Text("Maximum Angular Velocity: \(peakRotVelocity(), specifier: "%.2f") rad/s")
//                    Text("Maximum RH Velocity (est): \(String(format: "%.2f", peakRotVelocity() * ((userHeight * 0.38) + 11.5) / 17.6)) mph")
//                    Text("Avg Duration: \(avgDuration(), specifier: "%.2f") s")
//                    //Text("Total Swings: \(swings.count)")
//                }
//            }
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
//    private func peakRotVelocity() -> Double {
//        guard !swings.isEmpty else { return 0 }
//        return swings.map { $0.peakGyro }.max() ?? 0
//    }
//    
//    private func avgPeakRotVelocity() -> Double {
//        guard !swings.isEmpty else { return 0 }
//        return swings.map { $0.peakGyro }.reduce(0, +) / Double(swings.count)
//    }
//    
//    private func avgPeakAcc() -> Double {
//        guard !swings.isEmpty else { return 0 }
//        return swings.map { $0.peak }.reduce(0, +) / Double(swings.count)
//    }
//    
//    private func peakAcc() -> Double {
//        guard !swings.isEmpty else { return 0 }
//        return swings.map { $0.peak }.max() ?? 0
//    }
//
//    private func avgDuration() -> Double {
//        guard !swings.isEmpty else { return 0 }
//        return swings.map { $0.duration }.reduce(0, +) / Double(swings.count)
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

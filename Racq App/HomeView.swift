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
            ScrollView(showsIndicators: false) {
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
                                    GridItem(.flexible(), spacing: 16)
                                ],
                                spacing: 16
                            ) {
                                SummaryCard(
                                    title: "Duration",
                                    value: format(wc.summaryDurationSec),
                                    icon: AnyView(Image(systemName: "clock.fill").foregroundColor(.white))
                                    //gradient: orangeGradient
                                )
                                SummaryCard(
                                    title: "Shots",
                                    value: "\(wc.summaryShotCount)",
                                    icon: AnyView(Image(systemName: "tennisball.fill").foregroundColor(.white))
                                    //gradient: greenGradient
                                )
                                SummaryCard(
                                    title: "Forehands",
                                    value: "\(wc.summaryforehandCount)",
                                    icon: AnyView(letterIcon("F"))
                                    //gradient: blueGradient
                                )
                                SummaryCard(
                                    title: "Backhands",
                                    value: "\(wc.summarybackhandCount)",
                                    icon: AnyView(letterIcon("B"))
                                    //gradient: yellowGradient
                                )
                            }
                            CombinedSpeedCard(
                                fhTitle: "Forehand Speed",
                                fhMaxValue: String(
                                    format: "%.0f mph",
                                    SwingMath.maxFHSpeed(swings: swings, height: userHeight)
                                ),
                                fhAvgValue: String(
                                    format: "%.0f",
                                    SwingMath.avgFHSpeed(swings: swings, height: userHeight)
                                ),
                                fhRatio: CGFloat(
                                    SwingMath.avgFHSpeed(swings: swings, height: userHeight) /
                                    max(SwingMath.maxFHSpeed(swings: swings, height: userHeight), 1)
                                ),
                                fhColor: .blue,
                                fhIcon: AnyView(letterIcon("F")),

                                bhTitle: "Backhand Speed",
                                bhMaxValue: String(
                                    format: "%.0f mph",
                                    SwingMath.maxBHSpeed(swings: swings, height: userHeight)
                                ),
                                bhAvgValue: String(
                                    format: "%.0f",
                                    SwingMath.avgBHSpeed(swings: swings, height: userHeight)
                                ),
                                bhRatio: CGFloat(
                                    SwingMath.avgBHSpeed(swings: swings, height: userHeight) /
                                    max(SwingMath.maxBHSpeed(swings: swings, height: userHeight), 1)
                                ),
                                bhColor: .red,
                                bhIcon: AnyView(letterIcon("B"))
                            )
                            .frame(maxWidth: .infinity)
                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 4)
                        }
                    }
                    Spacer()
                }
                .padding(.bottom,40)
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

//private func summaryCard(
//    title: String,
//    value: String,
//    iconView: some View,
//    gradient: LinearGradient
//) -> some View {
//
//    ZStack {   // ← FIXED SIZE OUTER CONTAINER
//        RoundedRectangle(cornerRadius: 16)
//            .fill(gradient)
//            .shadow(color: .black.opacity(0.15), radius: 8, x: 0, y: 4)
//
//        VStack(alignment: .leading, spacing: 8) {
//            HStack {
//                iconView
//                    .frame(width: 28, height: 28)     // FORCE FIXED ICON SIZE
//                Spacer()
//            }
//
//            Text(value)
//                .font(.system(size: 22, weight: .bold))
//                .foregroundColor(.white)
//                .lineLimit(1)
//                .minimumScaleFactor(0.5)
//
//            Text(title)
//                .font(.caption)
//                .foregroundColor(.white.opacity(0.85))
//                .lineLimit(1)
//                .minimumScaleFactor(0.8)
//        }
//        .padding()
//    }
//    .frame(height: 135)
//}

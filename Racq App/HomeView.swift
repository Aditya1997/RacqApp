//
//  HomeView.swift
//  RacqApp
//  10/29/2025 updates for proper homeview
//  11/13/2025 Adding swing summary tab
//  11/19/2025 Using height in swing speed calc

import SwiftUI
import UIKit
import WatchConnectivity


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
    @AppStorage("displayName") private var displayName: String = ""
    @State private var showNameSetup = false
    @StateObject private var profileStore = UserProfileStore()
    
    private var participantId: String {
        UserIdentity.participantId()
    }
    
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
                                SummaryBlock(
                                    title: "Duration",
                                    value: format(wc.summaryDurationSec),
                                    icon: AnyView(Image(systemName: "clock.fill").foregroundColor(.white))
                                    //gradient: orangeGradient
                                )
                                SummaryBlock(
                                    title: "Shots",
                                    value: "\(wc.summaryShotCount)",
                                    icon: AnyView(Image(systemName: "tennisball.fill").foregroundColor(.white))
                                    //gradient: greenGradient
                                )
                                SummaryBlock(
                                    title: "Forehands",
                                    value: "\(wc.summaryforehandCount)",
                                    icon: AnyView(letterIcon("F"))
                                    //gradient: blueGradient
                                )
                                SummaryBlock(
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
            // below contains the code for manual user height and name input (before profile-based height/wingspan and apple ID)
            .onAppear {
                let userHeight = UserDefaults.standard.double(forKey: "userHeightInInches")
                WCSession.default.sendMessage(["height": userHeight], replyHandler: nil)
                if let url = wc.summaryCSVURL {
                    swings = loadSwingSummaryCSV(from: url)
                }
                let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
                if trimmed.isEmpty {
                    showNameSetup = true
                }
            }
            .sheet(isPresented: $showNameSetup) {
                NameSetupView()
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


// MARK: - SummaryBlock (single value)

//struct SummaryBlock: View {
//    var title: String
//    var value: String
//    var icon: AnyView? = nil
//    
//    var body: some View {
//        VStack(alignment: .leading, spacing: 6) {
//            HStack {
//                if let icon = icon {
//                    icon
//                        .frame(width: 30, height: 30)
//                }
//                Spacer()
//                Text(value)
//                    .foregroundColor(.white)
//                    .font(.system(size: 24, weight: .bold))
//                    .minimumScaleFactor(0.7)
//                    .lineLimit(1)
//            }
//            Text(title)
//                .foregroundColor(.white.opacity(0.85))
//                .font(.system(size: 14, weight: .medium))
//                .lineLimit(1)
//                .minimumScaleFactor(0.7)
//        }
//        .padding(.vertical,6)
//        .padding(.horizontal,12)
//        .frame(height: 85)
//        .background(
//            RoundedRectangle(cornerRadius: 15).fill(.ultraThinMaterial)
//        )
//        .overlay(
//            RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.08), lineWidth: 1)
//        )
//        .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 3)
//    }
//}

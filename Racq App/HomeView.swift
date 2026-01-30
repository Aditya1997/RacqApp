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
    @StateObject private var homeFeedStore = HomeGroupFeedStore()

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
//                    Divider()
//                    // PLAYER HEIGHT SECTION (always visible)
//                    PlayerHeightView()
//                    Divider()
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
                        SessionCardView(
                            title: "Latest Session",
                            durationSec: wc.summaryDurationSec,
                            avgHR: wc.summaryAvgHeartRate,
                            shotCount: wc.summaryShotCount,
                            forehandCount: wc.summaryforehandCount,
                            backhandCount: wc.summarybackhandCount,
                            swings: swings,
                            userHeightInInches: userHeight
                        )
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Community Feed")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .leading)

                        if homeFeedStore.feed.isEmpty {
                            Text("No recent posts from your groups yet.")
                                .foregroundColor(.secondary)
                                .font(.subheadline)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(homeFeedStore.feed) { item in
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(item.groupName)
                                            .font(.caption.weight(.semibold))
                                            .foregroundColor(.secondary)
                                        TinyPostCard(post: item.post, context: .group)
                                    }
                                }
                            }
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
            .task {
                await homeFeedStore.start()
            }
            .onDisappear {
                homeFeedStore.stop()
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



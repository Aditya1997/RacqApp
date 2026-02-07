//
//  RecordView.swift
//  Racq App
//
//  Created by Deets on 1/12/26.
//

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

struct RecordView: View {
    @ObservedObject var wc = PhoneWCManager.shared
    @State private var swings: [SwingSummaryCSV] = []
    @State private var showCreatePost = false
    @StateObject private var sessionStore = UserSessionStore()
    @State private var showPostSession: UserSession?
    private var participantId: String { UserIdentity.participantId() }
    
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
                    Divider()
                    // PLAYER HEIGHT SECTION (always visible)
                    PlayerHeightView()
                    Divider()
                    // Checking if a session exists
                    if wc.summaryTimestampISO.isEmpty {
                        emptyState
                    } else {
                        SessionCardView(
                            title: "Latest Session",
                            durationSec: wc.summaryDurationSec,
                            avgHR: wc.summaryAvgHeartRate,
                            shotCount: wc.summaryShotCount,
                            forehandCount: wc.summaryforehandCount,
                            backhandCount: wc.summarybackhandCount,
                            swings: swings,
                            userHeightInInches: UserDefaults.standard.double(forKey: "userHeightInInches")
                        )
                        Button {
                           // ✅ capture session at tap time
                           showPostSession = latestStoredSession()
                        } label: {
                           Label("Post", systemImage: "square.and.arrow.up")
                               .frame(maxWidth: .infinity)
                        }
                        if let url = wc.csvURL {
                            Button {
                                shareCSV(url)
                            } label: {
                                Label("Share CSV", systemImage: "square.and.arrow.up")
                            }
                        }
                        
                        // Your detailed analytics below, as requested
                        DetailedAnalyticsCard(
                            swings: swings,
                            userHeightInInches: UserDefaults.standard.double(forKey: "userHeightInInches")
                        )
                        // Heart rate card
                        heartRateCard(bpm: wc.summaryHeartRate)
                    }
                    Spacer(minLength: 10)
                }
                .padding()
                .onAppear {
                    if let url = wc.summaryCSVURL {
                        swings = loadSwingSummaryCSV(from: url)
                    }
                    Task { await sessionStore.fetchSessions(participantId: participantId) }
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
            .sheet(item: $showPostSession) { session in
                CreateSessionPostView(session: session)
            }
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
    
    private func latestStoredSession() -> UserSession? {
        // If your store is already sorted newest-first, you can just do:
        // return sessionStore.sessions.first
        // This is safer in case order changes:
        return sessionStore.sessions.max(by: { $0.timestamp < $1.timestamp })
    }
    
//  private var detailedSummaryCardView: some View { // UNUSED
//      DetailedSummaryCard(
//            shots: wc.summaryShotCount,
//            durationSec: wc.summaryDurationSec,
//            heartRate: wc.summaryHeartRate,
//            csvURL: wc.csvURL,
//            forehandCount: wc.summaryforehandCount,
//            backhandCount: wc.summarybackhandCount,
//            swings: swings
//        )
//    }

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

            Text("Session heart rate chart")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(UIColor.secondarySystemBackground))
        .cornerRadius(16)
    }
}

// MARK: - load Swing Summary CSV
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

// MARK: - Player Height Card
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

public func shareCSV(_ url: URL) {
    let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
    UIApplication.shared.connectedScenes
        .compactMap { $0 as? UIWindowScene }
        .first?.keyWindow?.rootViewController?
        .present(vc, animated: true)
}

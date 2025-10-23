//
//  ContentView.swift
//  RacqApp
//

import SwiftUI
import UIKit

struct ContentView: View {
    @ObservedObject var wc = PhoneWCManager.shared

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
                        csvURL: wc.csvURL
                    )
                }

                Spacer()
            }
            .padding()
            .navigationTitle("Racq Tracker")
        }
    }
}

// MARK: - Summary Card
private struct SummaryCard: View {
    let shots: Int
    let durationSec: Int
    let heartRate: Double
    let csvURL: URL?

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

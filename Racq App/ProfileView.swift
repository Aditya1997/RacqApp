//
//  SettingsView.swift
//  RacqApp
//

import SwiftUI

struct ProfileView: View {
    @ObservedObject var wc = PhoneWCManager.shared

    var body: some View {
        NavigationView {
            Form {
                // Connection Status
                Section(header: Text("Connection")) {
                    HStack {
                        Circle()
                            .fill(wc.isConnected ? Color.green : Color.red)
                            .frame(width: 10, height: 10)
                        Text(wc.isConnected ? "Watch Connected" : "Watch Not Connected")
                            .foregroundColor(.secondary)
                    }
                }

                // Session Summary (inline display)
                Section(header: Text("Last Session Summary")) {
                    if wc.summaryTimestampISO.isEmpty {
                        Text("No session data available yet.")
                            .foregroundColor(.secondary)
                    } else {
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                stat(title: "Shots", value: "\(wc.summaryShotCount)")
                                Spacer()
                                stat(title: "Duration", value: formatTime(wc.summaryDurationSec))
                                Spacer()
                                stat(title: "Heart Rate", value: "\(Int(wc.summaryHeartRate)) BPM")
                            }

                            if let url = wc.csvURL {
                                Button {
                                    shareCSV(url)
                                } label: {
                                    Label("Share CSV", systemImage: "square.and.arrow.up")
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                }
                            } else {
                                Text("CSV file not received yet.")
                                    .font(.footnote)
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                }

                // App Info
                Section(header: Text("App Info")) {
                    Text("Racq Tracker v1.0.2")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Settings")
        }
    }

    // MARK: - Helpers
    private func stat(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
        }
    }

    private func formatTime(_ sec: Int) -> String {
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

#Preview {
    ProfileView()
}

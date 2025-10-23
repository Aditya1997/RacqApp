//
//  RecordView.swift
//  RacqApp
//

import SwiftUI

struct RecordView: View {
    @ObservedObject var wc = PhoneWCManager.shared

    var body: some View {
        VStack(spacing: 20) {
            HStack(spacing: 8) {
                Circle()
                    .fill(wc.isConnected ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                Text(wc.isConnected ? "Watch Connected" : "Watch Not Connected")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            Divider()

            if wc.summaryTimestampISO.isEmpty {
                VStack(spacing: 6) {
                    Text("No session data yet.")
                        .foregroundColor(.gray)
                    Text("Start and stop a session on your Watch to record data.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .multilineTextAlignment(.center)
                .padding()
            } else {
                // live session summary pulled directly from PhoneWCManager
                VStack(spacing: 10) {
                    Text("Session Summary")
                        .font(.headline)
                        .padding(.bottom, 4)

                    HStack {
                        stat(title: "Shots", value: "\(wc.summaryShotCount)")
                        Spacer()
                        stat(title: "Duration", value: format(wc.summaryDurationSec))
                        Spacer()
                        stat(title: "Heart Rate", value: "\(Int(wc.summaryHeartRate)) BPM")
                    }

                    if let url = wc.csvURL {
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
                        HStack(spacing: 8) {
                            ProgressView()
                            Text("Preparing CSV…")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding()
                .background(Color(UIColor.secondarySystemBackground))
                .cornerRadius(12)
            }

            Spacer()
        }
        .padding()
    }

    // MARK: - Helpers
    private func stat(title: String, value: String) -> some View {
        VStack(alignment: .center, spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.headline)
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

#Preview {
    RecordView()
}

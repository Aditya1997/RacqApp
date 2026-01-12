//
//  RecordView.swift
//  RacqApp
//

import SwiftUI
import WatchConnectivity

struct SwingSummaryCSV: Identifiable {
    let id = UUID()
    let timestamp: String
    let type: String
    let peak: Double
    let peakGyro: Double
    let duration: Double
}

struct SessionView: View {
    @ObservedObject var wc = PhoneWCManager.shared
    @State private var swings: [SwingSummaryCSV] = []
    
    var body: some View {
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
                Text("No need for detailed card.")
//                DetailedSummaryCard(
//                    shots: wc.summaryShotCount,
//                    durationSec: wc.summaryDurationSec,
//                    heartRate: wc.summaryHeartRate,
//                    csvURL: wc.csvURL,
//                    forehandCount: wc.summaryforehandCount,
//                    backhandCount: wc.summarybackhandCount,
//                    swings: swings
                //)
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
        .onChange(of: wc.summaryCSVURL) { newURL in
            if let url = newURL {
                swings = loadSwingSummaryCSV(from: url)
            }
        }
    
//    VStack(spacing: 20) {
//            HStack(spacing: 8) {
//                Circle()
//                    .fill(wc.isConnected ? Color.green : Color.red)
//                    .frame(width: 10, height: 10)
//                Text(wc.isConnected ? "Watch Connected" : "Watch Not Connected")
//                    .font(.footnote)
//                    .foregroundColor(.secondary)
//            }
//
//            Divider()
//
//            if wc.summaryTimestampISO.isEmpty {
//                VStack(spacing: 6) {
//                    Text("No session data yet.")
//                        .foregroundColor(.gray)
//                    Text("Start and stop a session on your Watch to record data.")
//                        .font(.caption)
//                        .foregroundColor(.secondary)
//                }
//                .multilineTextAlignment(.center)
//                .padding()
//            } else {
//                // live session summary pulled directly from PhoneWCManager
//                VStack(spacing: 10) {
//                    Text("Session Summary")
//                        .font(.headline)
//                        .padding(.bottom, 4)
//
//                    HStack {
//                        stat(title: "Shots", value: "\(wc.summaryShotCount)")
//                        Spacer()
//                        stat(title: "Duration", value: format(wc.summaryDurationSec))
//                        Spacer()
//                        stat(title: "Heart Rate", value: "\(Int(wc.summaryHeartRate)) BPM")
//                    }
//
//                    if let url = wc.csvURL {
//                        Button {
//                            shareCSV(url)
//                        } label: {
//                            Label("Share CSV", systemImage: "square.and.arrow.up")
//                                .frame(maxWidth: .infinity)
//                                .padding()
//                                .background(Color.blue)
//                                .foregroundColor(.white)
//                                .cornerRadius(12)
//                        }
//                    } else {
//                        HStack(spacing: 8) {
//                            ProgressView()
//                            Text("Preparing CSV…")
//                                .foregroundColor(.secondary)
//                        }
//                    }
//                }
//                .padding()
//                .background(Color(UIColor.secondarySystemBackground))
//                .cornerRadius(12)
//            }
//
//            Spacer()
//        }
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
    
    private func shareCSV(_ url: URL) {
        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?.keyWindow?.rootViewController?
            .present(vc, animated: true)
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

//// MARK: - Summary Card
//private struct DetailedSummaryCard: View {
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
//                    Text("Avg Peak RH Velocity (est): \(String(format: "%.2f", SwingMath.avgRHSpeed(swings: swings, height: userHeight))) mph")
//                    Text("Maximum Angular Velocity: \(peakRotVelocity(), specifier: "%.2f") rad/s")
//                    Text("Maximum RH Velocity (est): \(String(format: "%.2f", SwingMath.maxRHSpeed(swings: swings, height: userHeight))) mph")
//                    Text("Avg Duration: \(avgDuration(), specifier: "%.2f") s")
//                    Text("Total Swings: \(swings.count)")
//                }
//            }
//            if let url = csvURL {
//                Button {
//                    shareCSV(url)
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
//    private func avgRHSpeed() -> Double {
//        guard !swings.isEmpty else { return 0 }
//        let avgPeakRotVelocity = swings.map { $0.peakGyro }.reduce(0, +) / Double(swings.count)
//        return avgPeakRotVelocity * ((userHeight * 0.38) + 11.5) / 17.6
//    }
//
//    private func maxRHSpeed() -> Double {
//        guard !swings.isEmpty else { return 0 }
//        let peakRotVelocity = swings.map { $0.peakGyro }.max() ?? 0
//        return peakRotVelocity * ((userHeight * 0.38) + 11.5) / 17.6
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
//    private func shareCSV(_ url: URL) {
//        let vc = UIActivityViewController(activityItems: [url], applicationActivities: nil)
//        UIApplication.shared.connectedScenes
//            .compactMap { $0 as? UIWindowScene }
//            .first?.keyWindow?.rootViewController?
//            .present(vc, animated: true)
//    }
//}

#Preview {
    SessionView()
}

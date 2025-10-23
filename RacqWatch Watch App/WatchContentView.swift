//
//  WatchContentView.swift
//  RacqWatch Watch App
//

import SwiftUI
import Combine

struct WatchContentView: View {
    @ObservedObject private var motion = MotionManager.shared
    @ObservedObject private var wc = WatchWCManager.shared

    @State private var elapsedTime: TimeInterval = 0
    @State private var timer: Timer?

    var body: some View {
        VStack(spacing: 8) {
            Text("🎾 Racq Tracker")
                .font(.headline)

            if wc.isPhoneConnected {
                Label("Connected", systemImage: "checkmark.circle.fill")
                    .foregroundColor(.green)
            } else {
                Label("Not Connected", systemImage: "xmark.circle.fill")
                    .foregroundColor(.red)
            }

            Divider()

            VStack(spacing: 4) {
                Text("Shots: \(motion.shotCount)")
                    .font(.title)
                    .bold()
                Text("Time: \(formatTime(elapsedTime))")
                    .font(.footnote)
            }

            Divider()

            Button(action: {
                if motion.isActive {
                    stopSession()
                } else {
                    startSession()
                }
            }) {
                Label(
                    motion.isActive ? "Stop" : "Start",
                    systemImage: motion.isActive ? "stop.circle" : "play.circle"
                )
                .frame(maxWidth: .infinity)
            }
            .tint(motion.isActive ? .red : .green)
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onDisappear { stopTimer() }
    }

    // MARK: - Session Control
    private func startSession() {
        motion.startMotionUpdates()
        SensorLogger.shared.startLogging()
        startTimer()
    }

    private func stopSession() {
        motion.stopMotionUpdates()
        SensorLogger.shared.stopLoggingAndExport()
        stopTimer()
    }

    // MARK: - Timer
    private func startTimer() {
        elapsedTime = 0
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let mins = Int(t) / 60
        let secs = Int(t) % 60
        return String(format: "%02d:%02d", mins, secs)
    }
}

#Preview {
    WatchContentView()
}

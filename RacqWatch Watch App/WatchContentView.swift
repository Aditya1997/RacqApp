//
//  WatchContentView.swift
//  RacqWatch Watch App
//

import SwiftUI
import Combine

struct WatchContentView: View {
    @ObservedObject private var motionManager = MotionManager.shared
    @ObservedObject private var healthManager = HealthManager.shared
    @ObservedObject private var watchWCManager = WatchWCManager.shared

    @State private var isRecording = false
    @State private var timerCount: TimeInterval = 0
    @State private var timerCancellable: AnyCancellable?

    private var formattedTime: String {
        let hours = Int(timerCount) / 3600
        let minutes = (Int(timerCount) % 3600) / 60
        let seconds = Int(timerCount) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 10) {
            // Timer
            Text(formattedTime)
                .font(.system(size: 28, weight: .bold, design: .monospaced))

            // Heart rate
            HStack {
                Image(systemName: "heart.fill")
                    .foregroundColor(.red)
                Text("\(Int(healthManager.heartRate)) bpm")
                    .font(.system(size: 16, weight: .semibold))
            }

            // Shots
            HStack {
                Text("🎾 Shots: \(motionManager.shotCount)")
                    .font(.system(size: 16, weight: .semibold))
            }

            // Start/Stop Button
            Button(action: toggleRecording) {
                Text(isRecording ? "Stop Recording" : "Start Recording")
                    .frame(maxWidth: .infinity)
                    .padding(8)
                    .background(isRecording ? Color.red : Color.green)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            // Connection status
            HStack {
                Image(systemName: watchWCManager.isReachable ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(watchWCManager.isReachable ? .green : .orange)
                Text(watchWCManager.isReachable ? "Connected to iPhone" : "Waiting for iPhone…")
                    .font(.footnote)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .onAppear {
            healthManager.requestAuthorization()
        }
    }

    // MARK: - Recording Controls
    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        isRecording = true
        timerCount = 0
        motionManager.startMotionUpdates()
        healthManager.startHeartRateUpdates()

        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                timerCount += 1
            }

        print("🎬 Recording started.")
    }

    private func stopRecording() {
        isRecording = false
        motionManager.stopMotionUpdates()
        healthManager.stopHeartRateUpdates()
        timerCancellable?.cancel()
        print("🛑 Recording stopped.")
    }
}

#Preview {
    WatchContentView()
}

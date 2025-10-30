//
//  WatchContentView.swift
//  RacqWatch Watch App
//
//  Updated 10/30 to correct watch screen size

import SwiftUI

struct WatchContentView: View {
    @ObservedObject var motionManager = MotionManager.shared
    @ObservedObject var healthManager = HealthManager.shared

    @State private var startTime: Date?
    @State private var elapsedTime: TimeInterval = 0.0
    @State private var timer: Timer?

    var body: some View {
        GeometryReader { geo in
            let width = geo.size.width
            let height = geo.size.height
            let scale = min(width / 200, 1.0) // scales nicely for 41–49mm watches

            VStack(spacing: height * 0.02) {

                // MARK: - Stopwatch
                Text(formatTime(elapsedTime))
                    .font(.system(size: 18 * scale, weight: .medium, design: .monospaced))
                    .foregroundColor(.green)
                    .padding(.top, height * 0.02)

                // MARK: - Shots Count
                Text("Shots: \(motionManager.shotCount)")
                    .font(.system(size: 28 * scale, weight: .bold))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                // MARK: - Forehand / Backhand
                HStack(spacing: width * 0.1) {
                    VStack {
                        Text("FH")
                            .font(.system(size: 14 * scale, weight: .semibold))
                            .foregroundColor(.yellow)
                        Text("\(motionManager.forehandCount)")
                            .font(.system(size: 16 * scale, weight: .bold))
                            .foregroundColor(.white)
                    }
                    VStack {
                        Text("BH")
                            .font(.system(size: 14 * scale, weight: .semibold))
                            .foregroundColor(.cyan)
                        Text("\(motionManager.backhandCount)")
                            .font(.system(size: 16 * scale, weight: .bold))
                            .foregroundColor(.white)
                    }
                }

                // MARK: - Heart Rate
                Text(heartRateText())
                    .font(.system(size: 14 * scale, weight: .regular))
                    .foregroundColor(healthManager.heartRate > 0 ? .red : .gray)

                // MARK: - Status
                Text(motionManager.isActive ? "Tracking…" : "Ready")
                    .font(.system(size: 14 * scale, weight: .medium))
                    .foregroundColor(motionManager.isActive ? .green : .gray)

                Spacer()

                // MARK: - Start/Stop Button
                Button(action: toggleSession) {
                    Text(motionManager.isActive ? "Stop" : "Start")
                        .font(.system(size: 18 * scale, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, height * 0.06)
                        .background(motionManager.isActive ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 8)

                Spacer(minLength: height * 0.01)
            }
            .frame(width: width, height: height)
            .background(Color.black.ignoresSafeArea())
        }
        .onAppear {
            healthManager.requestAuthorization()
        }
    }

    // MARK: - Stopwatch
    private func startStopwatch() {
        startTime = Date()
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if let start = startTime {
                elapsedTime = Date().timeIntervalSince(start)
            }
        }
    }

    private func stopStopwatch() {
        timer?.invalidate()
        timer = nil
    }

    private func resetStopwatch() {
        timer?.invalidate()
        timer = nil
        elapsedTime = 0.0
        startTime = Date()
    }

    // MARK: - Actions
    private func toggleSession() {
        if motionManager.isActive {
            // 🛑 Stop Session
            motionManager.stopMotionUpdates()
            healthManager.stopHeartRateUpdates()
            stopStopwatch()

            // Ensure UI updates before resetting timer
            DispatchQueue.main.async {
                motionManager.isActive = false
            }

            // 🟢 Send stop message to phone
            //motionManager.sendSessionStatusUpdate(isActive: false) removed due to errors

        } else {
            // ▶️ Start Session
            motionManager.startMotionUpdates()
            healthManager.startHeartRateUpdates()
            resetStopwatch()
            startStopwatch()

            DispatchQueue.main.async {
                motionManager.isActive = true
            }

            // 🟢 Send start message to phone
            //motionManager.sendSessionStatusUpdate(isActive: true) removed due to errors
        }
    }

    private func heartRateText() -> String {
        let bpm = Int(healthManager.heartRate)
        return bpm > 0 ? "\(bpm) BPM ❤️" : "-- BPM ❤️"
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    Group {
        WatchContentView()
            .previewDevice("Apple Watch Series 9 (41mm)")
        WatchContentView()
            .previewDevice("Apple Watch Series 9 (45mm)")
        WatchContentView()
            .previewDevice("Apple Watch Ultra 2 (49mm)")
    }
}

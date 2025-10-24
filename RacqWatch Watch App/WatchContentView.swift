//
//  WatchContentView.swift
//  RacqWatch Watch App
//

import SwiftUI

struct WatchContentView: View {
    @ObservedObject var motionManager = MotionManager.shared
    @ObservedObject var healthManager = HealthManager.shared

    @State private var startTime: Date?
    @State private var elapsedTime: TimeInterval = 0.0
    @State private var timer: Timer?

    var body: some View {
        GeometryReader { g in
            VStack(spacing: g.size.height * 0.04) {

                // MARK: - Stopwatch (top, small)
                Text(formatTime(elapsedTime))	
                    .font(.system(size: g.size.width * 0.10, weight: .medium, design: .monospaced))
                    .foregroundColor(.green)
                    .onAppear {
                        if motionManager.isActive { startStopwatch() }
                    }

                // MARK: - Shots (main focus)
                Text("Shots: \(motionManager.shotCount)")
                    .font(.system(size: g.size.width * 0.20, weight: .bold))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)

                // 🟢 NEW: Forehand / Backhand counters
                HStack(spacing: g.size.width * 0.1) {
                    VStack {
                        Text("FH")
                            .font(.system(size: g.size.width * 0.08, weight: .semibold))
                            .foregroundColor(.yellow)
                        Text("\(motionManager.forehandCount)")
                            .font(.system(size: g.size.width * 0.10, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                                    
                // MARK: - Heart Rate (below shots)
                Text(heartRateText())
                    .font(.system(size: g.size.width * 0.11, weight: .regular))
                    .foregroundColor(healthManager.heartRate > 0 ? .red : .gray)
                    .animation(.easeInOut(duration: 0.3), value: healthManager.heartRate)

                // MARK: - Status
                Text(motionManager.isActive ? "Tracking…" : "Ready")
                    .font(.system(size: g.size.width * 0.10, weight: .regular))
                    .foregroundColor(motionManager.isActive ? .green : .gray)
                    .animation(.easeInOut, value: motionManager.isActive)

                Spacer()

                // MARK: - Start/Stop Button (smaller, static)
                Button(action: toggleSession) {
                    Text(motionManager.isActive ? "Stop" : "Start")
                        .font(.system(size: g.size.width * 0.14, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, g.size.height * 0.09)
                        .background(motionManager.isActive ? Color.red : Color.blue)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                }
                .buttonStyle(.plain)
                .padding(.horizontal)

                Spacer(minLength: g.size.height * 0.02)
            }
            .frame(width: g.size.width, height: g.size.height)
            .padding()
            .background(Color.black.edgesIgnoringSafeArea(.all))
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
            motionManager.stopMotionUpdates()
            stopStopwatch()
            healthManager.stopHeartRateUpdates()
        } else {
            motionManager.startMotionUpdates()
            resetStopwatch()
            startStopwatch()
            healthManager.startHeartRateUpdates()
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
    WatchContentView()
        .previewDevice("Apple Watch SE (44mm)")
}

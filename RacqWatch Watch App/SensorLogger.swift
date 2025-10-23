import Foundation
import Combine

@MainActor
final class SensorLogger: ObservableObject {
    static let shared = SensorLogger()
    private let motionManager = MotionManager.shared
    @Published var logEntries: [String] = []
    @Published var isLogging: Bool = false
    private var timer: Timer?
    private init() {}

    func startLogging() {
        guard !isLogging else { return }
        isLogging = true
        logEntries.removeAll()
        motionManager.startMotionUpdates()   // ✅ Correct method
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.appendLogEntry()
        }
    }

    func stopLogging() {
        guard isLogging else { return }
        isLogging = false
        timer?.invalidate()
        timer = nil
        motionManager.stopMotionUpdates()    // ✅ Correct method
    }

    private func appendLogEntry() {
        let entry = "Shots: \(motionManager.shotCount), Magnitude: \(String(format: "%.2f", motionManager.lastMagnitude))"
        logEntries.append(entry)
        print("📄 \(entry)")
    }
}

//
//  MotionManager.swift
//  RacqWatch Watch App
//

import Foundation
import CoreMotion
import Combine
import WatchKit

@MainActor
final class MotionManager: ObservableObject {
    static let shared = MotionManager()

    private let motionManager = CMMotionManager()
    private var timer: Timer?
    private var dataLog: [MotionData] = []

    @Published var lastMagnitude: Double = 0.0
    @Published var shotCount: Int = 0
    @Published var motionSensitivity: Double = 2.2
    @Published var hapticsEnabled: Bool = true
    @Published var isActive: Bool = false

    private init() {}

    // MARK: - Motion Data Model
    struct MotionData: Codable {
        let timestamp: Date
        let magnitude: Double
        let accX: Double
        let accY: Double
        let accZ: Double
        let gyroX: Double
        let gyroY: Double
        let gyroZ: Double
        let heartRate: Double?
    }

    // MARK: - Start motion tracking
    func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("❌ Motion sensors unavailable.")
            return
        }

        dataLog.removeAll()
        shotCount = 0
        lastMagnitude = 0.0
        isActive = true

        motionManager.deviceMotionUpdateInterval = 1.0 / 50.0 // 50 Hz
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 50.0, repeats: true) { [weak self] _ in
            self?.captureMotionData()
        }

        print("✅ Started motion updates.")
    }

    // MARK: - Stop tracking + Export CSV
    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
        timer?.invalidate()
        timer = nil
        isActive = false

        print("🛑 Motion updates stopped.")

        // Export and send file to phone
        if let fileURL = exportCSV() {
            WatchWCManager.shared.sendFileToPhone(fileURL)
        }
    }

    // MARK: - Capture motion data
    private func captureMotionData() {
        guard let data = motionManager.deviceMotion else { return }

        let acc = data.userAcceleration
        let gyro = data.rotationRate
        let magnitude = sqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z)
        lastMagnitude = magnitude

        // Shot detection (simple threshold)
        if magnitude > motionSensitivity {
            shotCount += 1
            if hapticsEnabled { WKInterfaceDevice.current().play(.click) }
        }

        let record = MotionData(
            timestamp: Date(),
            magnitude: magnitude,
            accX: acc.x, accY: acc.y, accZ: acc.z,
            gyroX: gyro.x, gyroY: gyro.y, gyroZ: gyro.z,
            heartRate: HealthManager.shared.heartRate
        )

        dataLog.append(record)
    }

    // MARK: - Export CSV
    func exportCSV() -> URL? {
        let fileName = "Session_\(Int(Date().timeIntervalSince1970)).csv"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        var csv = "timestamp,magnitude,accX,accY,accZ,gyroX,gyroY,gyroZ,heartRate\n"

        for entry in dataLog {
            csv.append("\(entry.timestamp.timeIntervalSince1970),\(entry.magnitude),\(entry.accX),\(entry.accY),\(entry.accZ),")
            csv.append("\(entry.gyroX),\(entry.gyroY),\(entry.gyroZ),\(entry.heartRate ?? 0)\n")
        }

        do {
            try csv.write(to: fileURL, atomically: true, encoding: .utf8)
            print("✅ Exported CSV file: \(fileURL.lastPathComponent)")
            return fileURL
        } catch {
            print("❌ Failed to export CSV:", error.localizedDescription)
            return nil
        }
    }
}

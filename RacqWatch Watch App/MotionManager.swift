//
//  MotionManager.swift
//  RacqWatch Watch App
//

import Foundation
import CoreMotion
import Combine
import WatchKit
import WatchConnectivity

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

    // peak detection
    private var isSwinging = false
    private var lastShotTime: Date = .distantPast
    private let shotCooldown: TimeInterval = 0.12

    // duration
    private var sessionStart: Date?

    private init() {
        WatchWCManager.shared.activateSession()
    }

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

    // MARK: - Start
    func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("❌ Motion sensors unavailable.")
            return
        }
        dataLog.removeAll()
        shotCount = 0
        lastMagnitude = 0.0
        isActive = true
        isSwinging = false
        lastShotTime = .distantPast
        sessionStart = Date()

        motionManager.deviceMotionUpdateInterval = 1.0 / 50.0
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 50.0, repeats: true) { [weak self] _ in
            self?.captureMotionData()
        }
        print("✅ Started motion updates.")
    }

    // MARK: - Stop + export + notify phone
    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
        timer?.invalidate()
        timer = nil
        isActive = false

        let durationSec = max(0, Date().timeIntervalSince(sessionStart ?? Date()))
        let hr = HealthManager.shared.heartRate

        print("🛑 Motion updates stopped. shots=\(shotCount) duration=\(Int(durationSec))s hr=\(hr)")

        // 1) send summary immediately
        let summary: [String: Any] = [
            "shotCount": shotCount,
            "duration": Int(durationSec),
            "heartRate": hr,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        WatchWCManager.shared.sendData(summary)

        // 2) export and transfer CSV
        if let fileURL = exportCSV() {
            WatchWCManager.shared.sendFileToPhone(fileURL)
        }
    }

    // MARK: - Capture data
    private func captureMotionData() {
        guard let data = motionManager.deviceMotion else { return }
        let acc = data.userAcceleration
        let gyro = data.rotationRate
        let magnitude = sqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z)
        lastMagnitude = magnitude

        let now = Date()
        let gap = now.timeIntervalSince(lastShotTime)

        if magnitude > motionSensitivity {
            if !isSwinging && gap > shotCooldown {
                shotCount += 1
                lastShotTime = now
                isSwinging = true
                if hapticsEnabled { WKInterfaceDevice.current().play(.click) }
            }
        } else if isSwinging && magnitude < (motionSensitivity * 0.7) {
            isSwinging = false
        }

        let record = MotionData(
            timestamp: now,
            magnitude: magnitude,
            accX: acc.x, accY: acc.y, accZ: acc.z,
            gyroX: gyro.x, gyroY: gyro.y, gyroZ: gyro.z,
            heartRate: HealthManager.shared.heartRate
        )
        dataLog.append(record)
    }

    // MARK: - CSV
    private func exportCSV() -> URL? {
        let fileName = "Session_\(Int(Date().timeIntervalSince1970)).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        var csv = "timestamp,magnitude,accX,accY,accZ,gyroX,gyroY,gyroZ,heartRate\n"
        for e in dataLog {
            csv.append("\(e.timestamp.timeIntervalSince1970),\(e.magnitude),\(e.accX),\(e.accY),\(e.accZ),\(e.gyroX),\(e.gyroY),\(e.gyroZ),\(e.heartRate ?? 0)\n")
        }
        do {
            try csv.write(to: url, atomically: true, encoding: .utf8)
            print("✅ Exported CSV: \(url.lastPathComponent)")
            return url
        } catch {
            print("❌ CSV export failed: \(error.localizedDescription)")
            return nil
        }
    }
}

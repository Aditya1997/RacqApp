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

    // 🟢 NEW: Separate counters for forehand / backhand
    @Published var forehandCount: Int = 0
    @Published var backhandCount: Int = 0
    
    // Peak detection
    private var isSwinging = false
    private var lastShotTime: Date = .distantPast
    private let shotCooldown: TimeInterval = 0.12

    // Duration tracking
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
        // Orientation tracking
        let roll: Double
        let pitch: Double
        let yaw: Double
        let facingForward: Bool
        let wrist: String
        // 🟢 NEW: stroke classification
        let isForehand: Bool
    }

    // MARK: - Start
    func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("❌ Motion sensors unavailable.")
            return
        }

        dataLog.removeAll()
        shotCount = 0
        forehandCount = 0    // 🟢 Reset new counters
        backhandCount = 0
        lastMagnitude = 0.0
        isActive = true
        isSwinging = false
        lastShotTime = .distantPast
        sessionStart = Date()

        motionManager.deviceMotionUpdateInterval = 1.0 / 50.0
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical)

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 50.0, repeats: true) { [weak self] _ in
            guard let self else { return }
            Task { @MainActor [weak self] in
                self?.captureMotionData()
            }
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

        // 1) Send summary immediately
        let summary: [String: Any] = [
            "shotCount": shotCount,
            "duration": Int(durationSec),
            "heartRate": hr,
            "forehandCount": forehandCount,   // 🟢 Include new counters
            "backhandCount": backhandCount,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        WatchWCManager.shared.sendData(summary)

        // 2) Export and transfer CSV
        if let fileURL = exportCSV() {
            WatchWCManager.shared.sendFileToPhone(fileURL)
        }
    }

    // MARK: - Capture data (includes roll/pitch/yaw + facing direction)
    private func captureMotionData() {
        guard let data = motionManager.deviceMotion else { return }

        let acc = data.userAcceleration
        let gyro = data.rotationRate
        let attitude = data.attitude

        // Orientation angles
        let roll = attitude.roll
        let pitch = attitude.pitch
        let yaw = attitude.yaw

        // Determine whether the watch face is forward or backward
        let facingForward = abs(pitch) < .pi / 4
        
        // 🟢 Determine forehand/backhand classification
        let isForehand = !facingForward

        // Get which wrist the watch is on
        let wristLoc = WKInterfaceDevice.current().wristLocation
        let wristSide = wristLoc == .left ? "Left Wrist" : "Right Wrist"

        // Magnitude and swing detection
        let magnitude = sqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z)
        lastMagnitude = magnitude

        let now = Date()
        let gap = now.timeIntervalSince(lastShotTime)

        if magnitude > motionSensitivity {
            if !isSwinging && gap > shotCooldown {
                shotCount += 1
                lastShotTime = now
                isSwinging = true
                // 🟢 Increment appropriate swing type counter
                if isForehand {
                    forehandCount += 1
                } else {
                    backhandCount += 1
                }
                
                if hapticsEnabled { WKInterfaceDevice.current().play(.click) }
            }
        } else if isSwinging && magnitude < (motionSensitivity * 0.7) {
            isSwinging = false
        }

        // Append data with full orientation info
        let record = MotionData(
            timestamp: now,
            magnitude: magnitude,
            accX: acc.x, accY: acc.y, accZ: acc.z,
            gyroX: gyro.x, gyroY: gyro.y, gyroZ: gyro.z,
            heartRate: HealthManager.shared.heartRate,
            roll: roll,
            pitch: pitch,
            yaw: yaw,
            facingForward: facingForward,
            wrist: wristSide,
            isForehand: isForehand // 🟢 NEW field
        )
        dataLog.append(record)

        // Optional debug print
        print("🧭 \(wristSide) | Facing: \(facingForward ? "Forward" : "Backward") | Roll: \(String(format: "%.2f", roll)) | Pitch: \(String(format: "%.2f", pitch)) | Yaw: \(String(format: "%.2f", yaw))")
    }

    // MARK: - CSV Export (includes new orientation columns)
    private func exportCSV() -> URL? {
        let fileName = "Session_\(Int(Date().timeIntervalSince1970)).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        var csv = "timestamp,magnitude,accX,accY,accZ,gyroX,gyroY,gyroZ,heartRate,roll,pitch,yaw,facingForward,wrist\n"

        for e in dataLog {
            csv.append(
                "\(e.timestamp.timeIntervalSince1970),"
                + "\(e.magnitude),"
                + "\(e.accX),\(e.accY),\(e.accZ),"
                + "\(e.gyroX),\(e.gyroY),\(e.gyroZ),"
                + "\(e.heartRate ?? 0),"
                + "\(e.roll),\(e.pitch),\(e.yaw),"
                + "\(e.facingForward),"
                + "\(e.wrist)\n"
                + "\(e.isForehand)\n" // 🟢 New column	
            )
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

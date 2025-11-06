//
//  MotionManager.swift
//  RacqWatch Watch App
//
// 10/28/2025 Update to modify classification structure to add new variables, rotational direction instead of facingForward/pitch only, smoothing and cooldown handling

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

    // 🟢 UPDATED: Separate counters and state tracking
    @Published var forehandCount: Int = 0
    @Published var backhandCount: Int = 0
    @Published var lastGyroZ: Double = 0.0
    @Published var lastYaw: Double = 0.0
    @Published var lastPitch: Double = 0.0
    @Published var lastRoll: Double = 0.0
    @Published var lastSwingType: String = "None"
    
    // Peak detection
    private var isSwinging = false
    private var lastShotTime: Date = .distantPast
    private let shotCooldown: TimeInterval = 0.2

    // Duration tracking
    private var sessionStart: Date?

    // 🟢 UPDATED: Smoothing buffer
    private var magnitudeBuffer: [Double] = []
    private let bufferSize = 5
    
    
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
        // 🟢 UPDATED: keep for logging, not used in classification
        let facingForward: Bool
        let wrist: String
        let isForehand: Bool
        let isBackhand: Bool // 🟢 NEW
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

        // 🟢 UPDATED: Keep original facingForward for CSV compatibility
        let facingForward = abs(pitch) < .pi / 4

        // Determine wrist side OVERRIDDEN FOR NOW
        // let wristLoc = WKInterfaceDevice.current().wristLocation
        // let isLeftWrist = wristLoc == .left
        // let wristSide = isLeftWrist ? "Left Wrist" : "Right Wrist"

        // ✅ Override: always assume right wrist
        let isLeftWrist = false        // Force right wrist assumption
        let wristSide = "Right Wrist"        // Determine rotation
        
        let yawDeg = attitude.yaw * 180.0 / .pi
        let gyroZDeg = gyro.z * 180.0 / .pi
        let gyroYDeg = gyro.y * 180.0 / .pi     // 🟢 NEW

        // Flip signs if on left wrist 🟢 NEW
        let effectiveYaw = isLeftWrist ? -yawDeg : yawDeg
        let effectiveGyroZ = isLeftWrist ? -gyroZDeg : gyroZDeg
        let effectiveGyroY = isLeftWrist ? -gyroYDeg : gyroYDeg     // 🟢 NEW

        // Classify based on effective rotation
        let isForehand = (effectiveYaw > 0 && effectiveGyroZ > 0) || (effectiveGyroY > 35 && effectiveGyroZ > 0)
        let isBackhand = (effectiveYaw < 0 && effectiveGyroZ < 0) || (effectiveGyroY < -35 && effectiveGyroZ < 0)
        
        // 🟢 UPDATED: Apply smoothing filter to magnitude
        let magnitude = sqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z)
        magnitudeBuffer.append(magnitude)
        if magnitudeBuffer.count > bufferSize { magnitudeBuffer.removeFirst() }
        let smoothedMagnitude = magnitudeBuffer.reduce(0, +) / Double(magnitudeBuffer.count)

        lastMagnitude = smoothedMagnitude
        lastGyroZ = gyro.z
        lastYaw = yaw
        lastPitch = pitch
        lastRoll = roll
        lastSwingType = isForehand ? "Forehand" : (isBackhand ? "Backhand" : "Unknown")

        let now = Date()
        let gap = now.timeIntervalSince(lastShotTime)

        if smoothedMagnitude > motionSensitivity {
            if !isSwinging && gap > shotCooldown {
                shotCount += 1
                lastShotTime = now
                isSwinging = true
                // 🟢 UPDATED: New classification logic
                if isForehand {
                    forehandCount += 1
                } else if isBackhand {
                    backhandCount += 1
                }

                if hapticsEnabled { WKInterfaceDevice.current().play(.click) }
            }
        } else if isSwinging && smoothedMagnitude < (motionSensitivity * 0.7) {
            isSwinging = false
        }

        // 🟢 UPDATED: Log with new classification
        let record = MotionData(
            timestamp: now,
            magnitude: smoothedMagnitude,
            accX: acc.x, accY: acc.y, accZ: acc.z,
            gyroX: gyro.x, gyroY: gyro.y, gyroZ: gyro.z,
            heartRate: HealthManager.shared.heartRate,
            roll: roll, pitch: pitch, yaw: yaw,
            facingForward: facingForward,
            wrist: wristSide,
            isForehand: isForehand,
            isBackhand: isBackhand
        )
        dataLog.append(record)

        // Optional debug print
        print("🎾 \(wristSide) | \(lastSwingType) | GyroZ: \(String(format: "%.2f", gyroZDeg)) | GyroY: \(String(format: "%.2f", gyroYDeg)) | Yaw: \(String(format: "%.2f", yawDeg)) | Mag: \(String(format: "%.2f", smoothedMagnitude))") // 🟢 CHANGED
    }

    // MARK: - CSV Export (includes new orientation columns)
    private func exportCSV() -> URL? {
        let fileName = "Session_\(Int(Date().timeIntervalSince1970)).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        var csv = "timestamp,magnitude,accX,accY,accZ,gyroX,gyroY,gyroZ,heartRate,roll,pitch,yaw,facingForward,wrist,isForehand,isBackhand\n" // 🟢 UPDATED header

        for e in dataLog {
            csv.append(
                "\(e.timestamp.timeIntervalSince1970),"
                + "\(e.magnitude),"
                + "\(e.accX),\(e.accY),\(e.accZ),"
                + "\(e.gyroX),\(e.gyroY),\(e.gyroZ),"
                + "\(e.heartRate ?? 0),"
                + "\(e.roll),\(e.pitch),\(e.yaw),"
                + "\(e.facingForward),"
                + "\(e.wrist),"
                + "\(e.isForehand),"
                + "\(e.isBackhand)\n"
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

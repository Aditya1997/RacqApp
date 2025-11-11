//
//  MotionManager.swift
//  RacqWatch Watch App
//
// 10/28/2025 Update to modify classification structure to add new variables, rotational direction instead of facingForward/pitch only, smoothing and cooldown handling
// 11/10/2025 Update to improve swing determination using change in acceleration instead of pure acceleration, 3 point smoothing instead of 5, 100 Hz rate, and new csv data
// 11/11/2025 Switched to Coremotion timer, updated sensitivity, variables added

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
        swingSummaries.removeAll()
        shotCount = 0
        forehandCount = 0
        backhandCount = 0
        lastMagnitude = 0.0
        isActive = true
        isSwinging = false
        lastShotTime = .distantPast
        sessionStart = Date()
        
        // 🔧 Sampling rate 100 Hz, (11/11 switched to CoreMotion timer)
        
        //timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 100.0, repeats: true) { [weak self] _ in
        //    guard let self else { return }
        //    Task { @MainActor [weak self] in self?.captureMotionData() }
        //}
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 100.0
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical,
                                               to: OperationQueue.main) { [weak self] data, error in
            guard let self, let data else { return }
            self.captureMotionData()
        }
        
        print("✅ Started motion updates at 100 Hz.")
    }
    
    // MARK: - Stop + export + notify phone (11/11 removed timer)
    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
        //timer?.invalidate()
        //timer = nil
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
        
        // --- Extract attitude / rotation ---
        let acc = data.userAcceleration
        let gyro = data.rotationRate
        let attitude = data.attitude
        
        let rollDeg  = attitude.roll  * 180.0 / .pi
        let pitchDeg = attitude.pitch * 180.0 / .pi
        let yawDeg   = attitude.yaw   * 180.0 / .pi
        
        let gyroYDeg = gyro.y * 180.0 / .pi
        let gyroZDeg = gyro.z * 180.0 / .pi
        
        let isLeftWrist = false
        let wristSide = "Right Wrist"
        
        let effectiveGyroY = isLeftWrist ? -gyroYDeg : gyroYDeg
        let effectiveGyroZ = isLeftWrist ? -gyroZDeg : gyroZDeg
        let effectiveYaw   = isLeftWrist ? -yawDeg   : yawDeg
        
        // --- Classification (degrees) ---
        let isForehand = (effectiveYaw > 0 && effectiveGyroZ > 0) ||  (effectiveGyroY > 35 && effectiveGyroZ > 0)
        let isBackhand = (effectiveYaw < 0 && effectiveGyroZ < 0) ||  (effectiveGyroY < -35 && effectiveGyroZ < 0)
        
        //let yawThreshold: Double = 10.0
        //let angularSpeed = sqrt(effectiveGyroY * effectiveGyroY + effectiveGyroZ * effectiveGyroZ)

        //let isForehand = (effectiveGyroZ > 40 && effectiveGyroY > 0 && effectiveYaw > yawThreshold)
        //let isBackhand = (effectiveGyroZ < -40 && effectiveGyroY < 0 && effectiveYaw < -yawThreshold)
        
        // --- Magnitude smoothing (5-sample moving average) ---
        let rawMagnitude = sqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z)
        magnitudeBuffer.append(rawMagnitude)
        if magnitudeBuffer.count > 5 { magnitudeBuffer.removeFirst() }
        let smoothedMagnitude = magnitudeBuffer.reduce(0, +) / Double(magnitudeBuffer.count)
        lastMagnitude = smoothedMagnitude
        var accelDeltaLimit: Double = 0.05
        var smoothedMagnitudeLimit: Double = 0.3
        
        var accelDelta: Double = 0.0
        if magnitudeBuffer.count == 5 {
            accelDelta = abs(magnitudeBuffer.last! - magnitudeBuffer.first!)
        }
        
        let now = Date()
                
        // --- Swing state memory ---
        struct SwingState {
            static var peakMagnitude: Double = 0.0
            static var startTime: Date? = nil
            static var type: String = ""
        }
        
        // ✅ Swing start
        if !isSwinging {
            if accelDelta > accelDeltaLimit || smoothedMagnitude > smoothedMagnitudeLimit {
                isSwinging = true
                SwingState.peakMagnitude = smoothedMagnitude
                SwingState.startTime = now
                SwingState.type = isForehand ? "Forehand" : (isBackhand ? "Backhand" : "Unknown")
                shotCount += 1
                lastShotTime = now
                if isForehand { forehandCount += 1 }
                else if isBackhand { backhandCount += 1 }
                
                if hapticsEnabled { WKInterfaceDevice.current().play(.click) }
            }
        } else {
            // Update running peak
            if smoothedMagnitude > SwingState.peakMagnitude {
                SwingState.peakMagnitude = smoothedMagnitude
            }
            
            // ✅ Swing end
            if (SwingState.peakMagnitude - smoothedMagnitude >= 0.2) || (smoothedMagnitude <= SwingState.peakMagnitude * 0.5) {
                isSwinging = false
                if let start = SwingState.startTime {
                    let duration = now.timeIntervalSince(start)
                    let summary = SwingSummary(timestamp: now,
                                               peakMagnitude: SwingState.peakMagnitude,
                                               duration: duration,
                                               type: SwingState.type)
                    swingSummaries.append(summary)
                    appendSwingToCSV(summary)
                    print(String(format: "🏁 Swing End | Type: %@ | Peak: %.3f g | Duration: %.2f s",
                                 SwingState.type, SwingState.peakMagnitude, duration))
                }
                SwingState.peakMagnitude = 0.0
                SwingState.startTime = nil
            }
        }
        
        // --- Log frame data ---
        let record = MotionData(
            timestamp: now,
            magnitude: smoothedMagnitude,
            accX: acc.x, accY: acc.y, accZ: acc.z,
            gyroX: gyro.x, gyroY: gyro.y, gyroZ: gyro.z,
            heartRate: HealthManager.shared.heartRate,
            roll: rollDeg, pitch: pitchDeg, yaw: yawDeg,
            facingForward: abs(pitchDeg) < 45,
            wrist: wristSide,
            isForehand: isForehand,
            isBackhand: isBackhand
        )
        dataLog.append(record)
        
        print(String(format: "🎾 %@ | %@ | Mag: %.3f | Peak: %.3f",
                     wristSide,
                     isForehand ? "Forehand" : (isBackhand ? "Backhand" : "Unknown"),
                     smoothedMagnitude, SwingState.peakMagnitude))
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
    
    struct SwingSummary: Codable {
        let timestamp: Date
        let peakMagnitude: Double
        let duration: Double
        let type: String
    }
    
    private var swingSummaries: [SwingSummary] = []
    
    private func appendSwingToCSV(_ summary: SwingSummary) {
        let csvLine = "\(summary.timestamp),\(summary.type),\(String(format: "%.3f", summary.peakMagnitude)),\(String(format: "%.2f", summary.duration))\n"
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SwingSummaries.csv")
        
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let header = "Timestamp,Type,PeakMagnitude(g),Duration(s)\n"
            try? header.write(to: fileURL, atomically: true, encoding: .utf8)
        }
        
        if let handle = try? FileHandle(forWritingTo: fileURL) {
            handle.seekToEndOfFile()
            if let data = csvLine.data(using: .utf8) {
                handle.write(data)
            }
            try? handle.close()
        }
    }
}

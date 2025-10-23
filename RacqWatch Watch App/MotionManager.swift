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
    
    // Published properties for UI
    @Published var lastMagnitude: Double = 0.0
    @Published var shotCount: Int = 0
    @Published var motionSensitivity: Double = 2.2
    @Published var hapticsEnabled: Bool = true
    @Published var isActive: Bool = false
    
    // Peak detection and timing
    private var isSwinging = false
    private var lastShotTime: Date = .distantPast
    private var sessionStartTime: Date?
    private let shotCooldown: TimeInterval = 0.3
    
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
    
    // MARK: - Start Motion Updates
    func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else { return }
        dataLog.removeAll()
        shotCount = 0
        lastMagnitude = 0.0
        isActive = true
        isSwinging = false
        lastShotTime = .distantPast
        sessionStartTime = Date()
        
        motionManager.deviceMotionUpdateInterval = 1.0 / 50.0
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical)
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 50.0, repeats: true) { [weak self] _ in
            self?.captureMotionData()
        }
    }
    
    // MARK: - Stop Motion Updates
    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
        timer?.invalidate()
        timer = nil
        isActive = false
        
        guard let sessionStart = sessionStartTime else { return }
        let duration = Date().timeIntervalSince(sessionStart)
        let totalShots = shotCount
        
        if let fileURL = exportCSV() {
            WatchWCManager.shared.sendFileToPhone(fileURL, duration: duration, totalShots: totalShots)
            print("📤 Motion data CSV sent to iPhone (duration: \(Int(duration))s, shots: \(totalShots))")
        } else {
            print("⚠️ Failed to export motion CSV file")
        }
    }
    
    // MARK: - Capture Data
    private func captureMotionData() {
        guard let data = motionManager.deviceMotion else { return }
        let acc = data.userAcceleration
        let gyro = data.rotationRate
        let magnitude = sqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z)
        lastMagnitude = magnitude
        
        let now = Date()
        let timeSinceLastShot = now.timeIntervalSince(lastShotTime)
        
        if magnitude > motionSensitivity {
            if !isSwinging && timeSinceLastShot > shotCooldown {
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
            return fileURL
        } catch {
            print("❌ CSV export error: \(error.localizedDescription)")
            return nil
        }
    }
}

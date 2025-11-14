//
//  MotionManager.swift
//  RacqWatch Watch App
//
// 10/28/2025 Update to modify classification structure to add new variables, rotational direction instead of facingForward/pitch only, smoothing and cooldown handling
// 11/10/2025 Update to improve swing determination using change in acceleration instead of pure acceleration, 3 point smoothing instead of 5, 100 Hz rate, and new csv data
// 11/11/2025 Switched to Coremotion timer, updated sensitivity, variables added, added workout session, modified type classificationa and limits
// 11/12/2025 Updates to hopefully collect data consistently whether screen is on or off, 7 sample moving average, modified code for forehand and backhand using peak values, added gyro req
// 11/13/2025 Updates to frequency down to 80 Hz, modification of prints and csv data, modifying the motion code, change queue

import Foundation
import CoreMotion
import Combine
import WatchKit
import WatchConnectivity
import HealthKit

//@MainActor
final class MotionManager: NSObject, ObservableObject, HKWorkoutSessionDelegate {
    private var workoutSession: HKWorkoutSession?
    private var healthStore = HKHealthStore()
    private let backgroundQueue = OperationQueue()
    
    static let shared = MotionManager()
    
    private let motionManager = CMMotionManager()
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
    private let shotCooldown: TimeInterval = 0.4
    
    // Duration tracking
    private var sessionStart: Date?
    private var lastCSVLogTime = Date()
    
    // 🟢 UPDATED: Smoothing buffer
    private var magnitudeBuffer: [Double] = []
    
    override init() {
        super.init()
        WatchWCManager.shared.activateSession()
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession,
                        didChangeTo toState: HKWorkoutSessionState,
                        from fromState: HKWorkoutSessionState,
                        date: Date) {
        if toState == .running {
            print("🏃 Workout session is now running – motion updates safe to start.")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("❌ Workout session failed: \(error.localizedDescription)")
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
        //let pitch: Double
        //let yaw: Double
        // 🟢 UPDATED: keep for logging, not used in classification
        let facingForward: Bool
        let wrist: String
        let isForehand: Bool
        let isBackhand: Bool
    }
    
    // MARK: - HealthKit Sessions
    func beginWorkoutSession() {
        let config = HKWorkoutConfiguration()
        config.activityType = .tennis        // your sport type
        config.locationType = .indoor        // or .outdoor
        
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            workoutSession?.delegate = self  // 🟩 FIX: assign delegate properly
            workoutSession?.startActivity(with: Date())
            print("🏃‍♂️ Workout session started – background motion enabled.")
        } catch {
            print("❌ Failed to start workout session: \(error.localizedDescription)")
        }
    }
    // MARK: - Start
    func startMotionUpdates() {
        beginWorkoutSession()
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
                
        
        // 🔧 Sampling rate 80 Hz, (11/11 switched to CoreMotion timer)

        motionManager.deviceMotionUpdateInterval = 1.0 / 80.0

        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical,
                                               to: backgroundQueue) { [weak self] _, _ in
            //Task { @MainActor in
                self?.captureMotionData()
            //}
        }
        
        print("✅ Started motion updates at 100 Hz.")
    }
    
    // MARK: - Stop + export + notify phone (11/11 removed timer)
    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
        endWorkoutSession()
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
            "forehandCount": forehandCount,
            "backhandCount": backhandCount,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        WatchWCManager.shared.sendData(summary)
        
        // 2) Export and transfer CSV
        if let fileURL = exportCSV() {
            WatchWCManager.shared.sendFileToPhone(fileURL)
        }
        
        if let summaryURL = getSwingSummaryCSVFile() {
            WatchWCManager.shared.sendFileToPhone(summaryURL)
        }
        
        func endWorkoutSession() {
            workoutSession?.end()
            workoutSession = nil
            print("🛑 Workout session ended.")
        }
    }
    
    // MARK: - Capture data (and unfreeze)
    private var lastMotionTimestamp: TimeInterval = 0
    private var frozenFrameCount = 0

    private func captureMotionData() {
        guard let data = motionManager.deviceMotion else { return }
        
        // 🟩 Detect frozen motion data
        if data.timestamp == lastMotionTimestamp {
            frozenFrameCount += 1

            if frozenFrameCount >= 5 {
                print("⚠️ Motion frozen for 5 frames — restarting deviceMotion")
                frozenFrameCount = 0
                restartDeviceMotion()
            }

            return
        } else {
            // Data is fresh → reset counter
            frozenFrameCount = 0
        }
        lastMotionTimestamp = data.timestamp
        
        // --- Extract attitude / rotation ---
        let acc = data.userAcceleration
        let gyro = data.rotationRate
        let attitude = data.attitude
        
        // UNUSED
        let rollDeg  = attitude.roll  * 180.0 / .pi
        //let pitchDeg = attitude.pitch * 180.0 / .pi
        //let yawDeg   = attitude.yaw   * 180.0 / .pi
        
        let gyroXDeg = gyro.x * 180.0 / .pi
        let gyroYDeg = gyro.y * 180.0 / .pi
        let gyroZDeg = gyro.z * 180.0 / .pi
        
        // wrist override
        let isLeftWrist = false
        let wristSide = "Right Wrist"
        
        let effectiveGyroX = isLeftWrist ? -gyroXDeg : gyroXDeg
        let effectiveGyroY = isLeftWrist ? -gyroYDeg : gyroYDeg
        let effectiveGyroZ = isLeftWrist ? -gyroZDeg : gyroZDeg
        //let effectiveYaw   = isLeftWrist ? -yawDeg   : yawDeg
        
        // --- Classification (degrees) ---
        var isForehand = false
        var isBackhand = false

        // UNUSED
        //let yawThreshold: Double = 10.0
        //let angularSpeed = sqrt(effectiveGyroY * effectiveGyroY + effectiveGyroZ * effectiveGyroZ)
        
        //let isForehand = (effectiveGyroZ > 40 && effectiveGyroY > 0 && effectiveYaw > yawThreshold)
        //let isBackhand = (effectiveGyroZ < -40 && effectiveGyroY < 0 && effectiveYaw < -yawThreshold)
        
        // --- Magnitude smoothing (4-sample moving average) ---
        let rawMagnitude = sqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z)
        let gyroMagnitude = gyro.x*gyro.x + gyro.y*gyro.y + gyro.z*gyro.z
        magnitudeBuffer.append(rawMagnitude)
        if magnitudeBuffer.count > 4 { magnitudeBuffer.removeFirst() }
        let smoothedMagnitude = magnitudeBuffer.reduce(0, +) / Double(magnitudeBuffer.count)
        lastMagnitude = smoothedMagnitude
        let accelDeltaLimit: Double = 0.9 // 1.1
        let smoothedMagnitudeLimit: Double = 1.9 // 2.1
        let SQeffectiveGyroXY = effectiveGyroX * effectiveGyroX + effectiveGyroY * effectiveGyroY
        let smoothedgyroLimit: Double = 144.0
        
        var accelDelta: Double = 0.0
        if magnitudeBuffer.count == 4 {
            accelDelta = magnitudeBuffer.last!-magnitudeBuffer.first!
        }
        
        let now = Date()
        
        // --- Swing state memory ---
        struct SwingState {
            static var peakMagnitude: Double = 0.0
            static var startTime: Date? = nil
            static var type: String = ""
            static var pendingType: String = ""
            static var peakGyroYPos: Double = 0.0
            static var peakGyroYNeg: Double = 0.0
            static var peakGyroMagnitude: Double = 0.0
            static var peakRMSGyroMagnitude: Double = 0.0
        }
        
        // adding minimum magnitude check
        if rawMagnitude > 0.4   {
            // ✅ Swing start
            if !isSwinging {
                if accelDelta > accelDeltaLimit && smoothedMagnitude > smoothedMagnitudeLimit && SQeffectiveGyroXY > smoothedgyroLimit { //
                    isSwinging = true
                    SwingState.peakMagnitude = smoothedMagnitude
                    SwingState.startTime = now
                    SwingState.peakGyroYPos = effectiveGyroY
                    SwingState.peakGyroYNeg = effectiveGyroY
                    SwingState.peakGyroMagnitude = gyroMagnitude
                    if hapticsEnabled { WKInterfaceDevice.current().play(.click) }
                }
            } else {
                // Update running peak
                if smoothedMagnitude > SwingState.peakMagnitude {
                    SwingState.peakMagnitude = smoothedMagnitude
                }
                if effectiveGyroY > SwingState.peakGyroYPos {
                    SwingState.peakGyroYPos = effectiveGyroY
                }
                if effectiveGyroY < SwingState.peakGyroYNeg {
                    SwingState.peakGyroYNeg = effectiveGyroY
                }
                if gyroMagnitude > SwingState.peakGyroMagnitude {
                    SwingState.peakGyroMagnitude = gyroMagnitude
                }
                // ✅ Swing end
                if (SwingState.peakMagnitude - smoothedMagnitude >= 3) || (smoothedMagnitude <= SwingState.peakMagnitude * 0.5) {
                    isSwinging = false
                    if let start = SwingState.startTime {
                        let duration = now.timeIntervalSince(start)
                        if abs(effectiveGyroX) > 5 && abs(SwingState.peakGyroYPos) > abs(SwingState.peakGyroYNeg) {
                            isBackhand = true
                        }
                        else if abs(effectiveGyroX) > 5 && abs(SwingState.peakGyroYPos) < abs(SwingState.peakGyroYNeg) {
                            isForehand = true
                        }
                        SwingState.pendingType = isForehand ? "Forehand" : (isBackhand ? "Backhand" : "Unknown")
                        let type = SwingState.pendingType
                        DispatchQueue.main.async {
                            self.shotCount += 1
                            if type == "Forehand" { self.forehandCount += 1 }
                            if type == "Backhand" { self.backhandCount += 1 }
                            self.lastSwingType = type
                            self.lastMagnitude = smoothedMagnitude
                        }
                        SwingState.peakRMSGyroMagnitude = sqrt(SwingState.peakGyroMagnitude)
                        //if type == "Forehand" { forehandCount += 1 }
                        //else if type == "Backhand" { backhandCount += 1 }
                        //lastSwingType = type
                        //lastShotTime = now
                        let summary = SwingSummary(timestamp: now,
                                                   peakMagnitude: SwingState.peakMagnitude,
                                                   peakRMSGyroMagnitude: SwingState.peakRMSGyroMagnitude,
                                                   duration: duration,
                                                   type: SwingState.type)
                        swingSummaries.append(summary)
                        appendSwingToCSV(summary)
                        // print(String(format: "🏁 Swing End | Type: %@ | Peak: %.3f g | Duration: %.2f s", SwingState.type, SwingState.peakMagnitude, duration)) // NO MORE PRINTS
                    }
                    SwingState.peakMagnitude = 0.0
                    SwingState.peakGyroMagnitude = 0.0
                    SwingState.peakRMSGyroMagnitude = 0.0
                    SwingState.startTime = nil
                }
            }
        }
        
        // --- Log frame data ---
        let record = MotionData(
            timestamp: now,
            magnitude: smoothedMagnitude,
            accX: acc.x, accY: acc.y, accZ: acc.z,
            gyroX: gyro.x, gyroY: gyro.y, gyroZ: gyro.z,
            heartRate: HealthManager.shared.heartRate,
            roll: rollDeg, //pitch: pitchDeg, yaw: yawDeg,
            facingForward: abs(rollDeg) > 0,
            wrist: wristSide,
            isForehand: isForehand,
            isBackhand: isBackhand
        )
        //dataLog.append(record)

        if now.timeIntervalSince(lastCSVLogTime) > 0.05 {   // log at 20Hz, not 80Hz
            dataLog.append(record)
            lastCSVLogTime = now
        }
        
        // UNUSED NO MORE PRINTS
        //print(String(format: "🎾 %@ | %@ | Mag: %.3f | Peak: %.3f",
        //             wristSide,
        //             isForehand ? "Forehand" : (isBackhand ? "Backhand" : "Unknown"),
        //             smoothedMagnitude, SwingState.peakMagnitude))
    }
    
    // MARK: - 🟩 4. Restart motion stream if frozen
    private func restartDeviceMotion() {
        motionManager.stopDeviceMotionUpdates()
        motionManager.startDeviceMotionUpdates(using: .xArbitraryZVertical,
                                               to: backgroundQueue) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }
            //Task { @MainActor in
                self.captureMotionData() }
        //}
        print("🔄 Restarted motion updates.")
    }
    
    // MARK: - CSV Export (includes new orientation columns)
    private func exportCSV() -> URL? {
        let fileName = "Session_\(Int(Date().timeIntervalSince1970)).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        var csv = "timestamp,magnitude,accX,accY,accZ,gyroX,gyroY,gyroZ,heartRate,roll,facingForward,wrist,isForehand,isBackhand\n" // 🟢 UPDATED header, 11/13 removed roll,pitch,yaw,facingForward,
        
        for e in dataLog {
            csv.append(
                "\(e.timestamp.timeIntervalSince1970),"
                + "\(e.magnitude),"
                + "\(e.accX),\(e.accY),\(e.accZ),"
                + "\(e.gyroX),\(e.gyroY),\(e.gyroZ),"
                + "\(e.heartRate ?? 0),"
                + "\(e.roll),"
                //+\(e.pitch),\(e.yaw),"
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
    
    // MARK: - SwingSummary Export
    private func getSwingSummaryCSVFile() -> URL? {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SwingSummaries.csv")

        return FileManager.default.fileExists(atPath: url.path) ? url : nil
    }
    
    struct SwingSummary: Codable {
        let timestamp: Date
        let peakMagnitude: Double
        let peakRMSGyroMagnitude: Double
        let duration: Double
        let type: String
    }
    
    private var swingSummaries: [SwingSummary] = []
    
    private func appendSwingToCSV(_ summary: SwingSummary) {
        let csvLine = "\(summary.timestamp),\(summary.type),\(String(format: "%.3f", summary.peakMagnitude)),\(String(format: "%.3f", summary.peakRMSGyroMagnitude)),\(String(format: "%.2f", summary.duration))\n"
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SwingSummaries.csv")
        
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let header = "Timestamp,Type,PeakMagnitude(g),PeakRMSGyroMagnitude(rad/s),Duration(s)\n"
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

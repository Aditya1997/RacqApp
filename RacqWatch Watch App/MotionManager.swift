//
//  MotionManager.swift
//  RacqWatch Watch App
//
// 10/28/2025 Update to modify classification structure to add new variables, rotational direction instead of facingForward/pitch only, smoothing and cooldown handling
// 11/10/2025 Update to improve swing determination using change in acceleration instead of pure acceleration, 3 point smoothing instead of 5, 100 Hz rate, and new csv data
// 11/11/2025 Switched to Coremotion timer, updated sensitivity, variables added, added workout session, modified type classificationa and limits
// 11/12/2025 Updates to hopefully collect data consistently whether screen is on or off, 7 sample moving average, modified code for forehand and backhand using peak values, added gyro req
// 11/13/2025 Updates to frequency down to 80 Hz, modification of prints and csv data, modifying the motion code, change queue
// 11/19/2025 Updates to incorporate cooldown check and tighten limits slightly
// 12/9/2025 Added lock to swing end, added gyro smoothing

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
    private let motionQueue: OperationQueue = {
        let q = OperationQueue()
        q.name = "com.racqwatch.motion"
        q.maxConcurrentOperationCount = 1
        q.qualityOfService = .userInitiated
        return q
    }()

    private let logQueue = DispatchQueue(label: "com.racqwatch.motionlog")

    static let shared = MotionManager()
    
    private let motionManager = CMMotionManager()
    private var dataLog: [MotionData] = []

    // 🟢 UPDATED: Published variables - separate counters and state tracking
    @Published var isActive: Bool = false
    @Published var shotCount: Int = 0
    @Published var forehandCount: Int = 0
    @Published var backhandCount: Int = 0
    @Published var lastSwingType: String = "None"
    
    // Peak detection
    private(set) var lastMagnitude: Double = 0.0
    private(set) var smoothedMagnitudeLimit: Double = 1.2
    private(set) var hapticsEnabled: Bool = true
    //@Published var userHeight: Double = 70.0   // default
    
    // Swing detection and duration tracking
    private var isSwinging = false
    private var swingFinishedLock = false
    private var lastShotTime: Date = .distantPast
    private let shotCooldown: TimeInterval = 0.4
    private var sessionStart: Date?
    private var lastCSVLogTime = Date()

    // 🟢 UPDATED: Smoothing buffer
    private var magnitudeBuffer: [Double] = []
    private var accelDeltaBuffer: [Double] = []
    private var gyroWindow: [Double] = []

    override init() {
        super.init()
        //backgroundQueue.maxConcurrentOperationCount = 1
        //backgroundQueue.qualityOfService = .userInitiated
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
        let heartRate: Double
        // Orientation tracking
        let roll: Double
        let pitch: Double
        let yaw: Double
        // 🟢 UPDATED: keep for logging, not used in classification
        let facingForward: Bool
        let wrist: String
        let isForehand: Bool
        let isBackhand: Bool
    }
    
    // MARK: - Heart Rate Functions
    private var cachedHeartRate: Double = 0
    private var heartRateTimer: DispatchSourceTimer?
    
    func startHeartRateUpdates() {
        heartRateTimer?.cancel()
        
        let timer = DispatchSource.makeTimerSource(queue: DispatchQueue.global(qos: .utility))
        timer.schedule(deadline: .now(), repeating: 1.0) // 1 Hz
        
        timer.setEventHandler { [weak self] in
            guard let self = self else { return }
            let heartRate = HealthManager.shared.heartRate
            if heartRate > 0 {
                self.cachedHeartRate = heartRate
            }
        }
        
        timer.resume()
        heartRateTimer = timer
    }
    
    func stopHeartRateUpdates() {
        heartRateTimer?.cancel()
        heartRateTimer = nil
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
        
        guard motionManager.isDeviceMotionAvailable else {
            print("❌ Motion sensors unavailable.")
            return
        }
        
        beginWorkoutSession()
        if sessionStart == nil {
            sessionStart = Date()
        }
        startHeartRateUpdates()
      
        // 🔧 Sampling rate 80 Hz, (11/11 switched to CoreMotion timer)
        motionManager.showsDeviceMovementDisplay = false
        motionManager.deviceMotionUpdateInterval = 1.0 / 80.0
        motionManager.startDeviceMotionUpdates(
            using: .xArbitraryZVertical,
            to: motionQueue
        ) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }
            self.captureMotionData(motion)
        }
        print("✅ Started motion updates at 80 Hz.")
        
        dataLog.removeAll()
        swingSummaries.removeAll()
        resetSwingSummaryCSV()

        shotCount = 0
        forehandCount = 0
        backhandCount = 0
        lastMagnitude = 0.0
        isActive = true
        isSwinging = false
        lastShotTime = .distantPast

    }

    // MARK: - Stop + export + notify phone (11/11 removed timer)
    func stopMotionUpdates() {
        motionManager.stopDeviceMotionUpdates()
        stopHeartRateUpdates()
        endWorkoutSession()
        //timer?.invalidate()
        //timer = nil
        isActive = false
        
        let start = sessionStart ?? Date()
        let durationSec = Int(Date().timeIntervalSince(start))
        let hr = HealthManager.shared.heartRate
        
        print("🛑 Motion updates stopped. shots=\(shotCount) duration=\(Int(durationSec))s hr=\(hr)")
        
        // 1) Send summary immediately
        let summary: [String: Any] = [
            "shotCount": shotCount,
            "duration": Int(durationSec),
            "heartRate": cachedHeartRate,
            "forehandCount": forehandCount,
            "backhandCount": backhandCount,
            "timestamp": ISO8601DateFormatter().string(from: Date())
        ]
        
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(summary, replyHandler: nil)
            print("📤 Sent summary via sendMessage")
        } else {
            print("❌ Phone not reachable — summary not sent")
        }
        
        // 2) Export and transfer CSV
        if let fileURL = exportCSV() {
            WatchWCManager.shared.sendFileToPhone(fileURL)
        }
        
        if let summaryURL = getSwingSummaryCSVFile() {
            WatchWCManager.shared.sendFileToPhone(summaryURL)
        }
        
        sessionStart = nil

        func endWorkoutSession() {
            workoutSession?.end()
            workoutSession = nil
            print("🛑 Workout session ended.")
        }
    }
    
    // MARK: - Capture data (and unfreeze)
    private var lastMotionTimestamp: TimeInterval = 0
    private var frozenFrameCount = 0
    // Store the last ~20 gyro magnitudes for impact window
    
    // --- Swing state memory ---
    struct SwingState {
        var peakMagnitude: Double = 0.0
        var startTime: Date? = nil
        var type: String = ""
        var pendingType: String = ""
        var peakGyroYPos: Double = 0.0
        var peakGyroYNeg: Double = 0.0
        var peakGyroMagnitudeSQ: Double = 0.0
        var peakRMSGyroMagnitude: Double = 0.0
        var impactDetected: Bool = false
        var peakLocked: Bool = false
        var peakGyroFiltered: Double = 0.0
    }
    
    private var swingState = SwingState()
    
    private func captureMotionData(_ data: CMDeviceMotion) {
        // 🟩 Detect frozen motion data
        if data.timestamp == lastMotionTimestamp {
            frozenFrameCount += 1
            if frozenFrameCount >= 3 {
                print("⚠️ Motion frozen for 3 frames — restarting deviceMotion")
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
        let pitchDeg = attitude.pitch * 180.0 / .pi
        let yawDeg   = attitude.yaw   * 180.0 / .pi
        
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
        
        // --- Magnitude smoothing (4-sample moving average) ---
        let rawMagnitude = sqrt(acc.x * acc.x + acc.y * acc.y + acc.z * acc.z)
        magnitudeBuffer.append(rawMagnitude)
        if magnitudeBuffer.count > 4 { magnitudeBuffer.removeFirst() }
        let smoothedMagnitude = magnitudeBuffer.reduce(0, +) / Double(magnitudeBuffer.count)
        lastMagnitude = smoothedMagnitude
        
        // adding new 7 size array to manage accelDelta
        accelDeltaBuffer.append(rawMagnitude)
        if accelDeltaBuffer.count > 7 { accelDeltaBuffer.removeFirst() }
        var accelDelta: Double = 0.0
        if accelDeltaBuffer.count == 7 {
            accelDelta = accelDeltaBuffer.last!-accelDeltaBuffer.first!
        }
        
        // gyro calculations
        let gyroMagnitudeSQ = gyro.x*gyro.x + gyro.y*gyro.y + gyro.z*gyro.z
        let effectiveGyroXYSQ = effectiveGyroX * effectiveGyroX + effectiveGyroY * effectiveGyroY // remove? Replace with gyroMagnitudeSQ
        
        // limits
        let accelDeltaLimit: Double = 0.8 //
        let smoothedMagnitudeLimit: Double = 1.2 // 1.9
        let rawMagnitudeLimit: Double = 4 // 1.9
        let smoothedgyroLimit: Double = 42 // 144
                
        let now = Date()
        
        // adding minimum magnitude check	
        if rawMagnitude > 0.6   {
            // ✅ Swing start
            if !isSwinging {
                if accelDelta > accelDeltaLimit && smoothedMagnitude > smoothedMagnitudeLimit && effectiveGyroXYSQ > smoothedgyroLimit && rawMagnitude > rawMagnitudeLimit { //
                    isSwinging = true
                    swingFinishedLock = false   // swing lock to prevent extra counts
                    swingState.startTime = now
                    swingState.peakMagnitude = smoothedMagnitude
                    swingState.peakGyroYPos = effectiveGyroY
                    swingState.peakGyroYNeg = effectiveGyroY
                    swingState.peakGyroMagnitudeSQ = gyroMagnitudeSQ
                    gyroWindow.removeAll()
                    if hapticsEnabled { WKInterfaceDevice.current().play(.click) }
                }
            } else {
                // Update running peaks (can move this below swing end section)
                if smoothedMagnitude > swingState.peakMagnitude {
                    swingState.peakMagnitude = smoothedMagnitude
                }
                if effectiveGyroY > swingState.peakGyroYPos {
                    swingState.peakGyroYPos = effectiveGyroY
                }
                if effectiveGyroY < swingState.peakGyroYNeg {
                    swingState.peakGyroYNeg = effectiveGyroY
                }
                if isSwinging {
                    if gyroMagnitudeSQ > swingState.peakGyroMagnitudeSQ {
                        swingState.peakGyroMagnitudeSQ = gyroMagnitudeSQ
                    }
                    // stop tracking peak when the swing decelerates
                    if gyroMagnitudeSQ < swingState.peakGyroMagnitudeSQ * 0.65 {
                        swingState.impactDetected = true
                    }
                    if !swingState.peakLocked {
                        // --- gyro mag smoothing (8 samples stored) ---
                        gyroWindow.append(sqrt(gyroMagnitudeSQ))
                        if gyroWindow.count > 8 {
                            gyroWindow.removeFirst()
                        }
                    }
                }
                // gyro 5 sample smoothing calc
                if swingState.impactDetected && !swingState.peakLocked {
                    swingState.peakLocked = true
                    // 1. Find impact index
                    let impactIndex = gyroWindow.firstIndex(of: gyroWindow.max() ?? 0) ?? (gyroWindow.count - 1)
                    // 2. Define window range, uses a 3 samples
                    let windowStart = max(0, impactIndex - 1)
                    let windowEnd   = min(gyroWindow.count - 1, impactIndex + 1)
                    // 3. Compute average rad/s in impact window
                    let windowSlice = gyroWindow[windowStart...windowEnd]
                    swingState.peakGyroFiltered = windowSlice.reduce(0, +) / Double(windowSlice.count)
                }
                // ✅ Swing end
                if (swingState.peakMagnitude - smoothedMagnitude >= 3) || (smoothedMagnitude <= swingState.peakMagnitude * 0.5) {
                    if !swingFinishedLock {
                        swingFinishedLock = true
                        isSwinging = false
                        if now.timeIntervalSince(lastShotTime) > shotCooldown {     // cooldown check passed
                            if let start = swingState.startTime {
                                let duration = now.timeIntervalSince(start)
                                if abs(effectiveGyroX) > 5 && abs(swingState.peakGyroYPos) > abs(swingState.peakGyroYNeg) {
                                    isBackhand = true
                                }
                                else if abs(effectiveGyroX) > 5 && abs(swingState.peakGyroYPos) < abs(swingState.peakGyroYNeg) {
                                    isForehand = true
                                }
                                swingState.pendingType = isForehand ? "Forehand" : (isBackhand ? "Backhand" : "Unknown")
                                let type = swingState.pendingType
                                let shotType = type
                                DispatchQueue.main.async {
                                    self.shotCount += 1
                                    if shotType == "Forehand" { self.forehandCount += 1 }
                                    if shotType == "Backhand" { self.backhandCount += 1 }
                                }
                                lastShotTime = now
                                let summary = SwingSummary(timestamp: now,
                                                           peakMagnitude: swingState.peakMagnitude,
                                                           peakGyroFiltered: swingState.peakGyroFiltered,
                                                           duration: duration,
                                                           type: type)
                                swingSummaries.append(summary)
                                appendSwingToCSV(summary)
                                // print(String(format: "🏁 Swing End | Type: %@ | Peak: %.3f g | Duration: %.2f s", swingState.type, swingState.peakMagnitude, duration)) // NO MORE PRINTS
                            }
                        }
//                        swingState.peakMagnitude = 0.0
//                        swingState.peakGyroMagnitudeSQ = 0.0
//                        swingState.peakRMSGyroMagnitude = 0.0
//                        swingState.startTime = nil
//                        swingState.impactDetected = false
//                        swingState.peakLocked = false
//                        swingState.peakGyroFiltered = 0.0
                        swingState = SwingState()
                        gyroWindow.removeAll()
                    }
                }
            }
        }
        // --- Log frame data ---
        if now.timeIntervalSince(lastCSVLogTime) >= 0.05 { // 20 Hz
            lastCSVLogTime = now
            let record = MotionData(
                timestamp: now,
                magnitude: lastMagnitude,     // or smoothedMagnitude you computed
                accX: data.userAcceleration.x,
                accY: data.userAcceleration.y,
                accZ: data.userAcceleration.z,
                gyroX: data.rotationRate.x,
                gyroY: data.rotationRate.y,
                gyroZ: data.rotationRate.z,
                heartRate: cachedHeartRate,
                roll: data.attitude.roll * 180.0 / .pi,
                pitch: data.attitude.pitch * 180.0 / .pi,
                yaw: data.attitude.yaw * 180.0 / .pi,
                facingForward: abs(data.attitude.roll * 180.0 / .pi) > 0,
                wrist: "Right Wrist",
                isForehand: false,
                isBackhand: false
                )
            
            dataLog.append(record)   // ✅ ALSO 20 Hz now
        }
    }
    
    // MARK: - 🟩 4. Restart motion stream if frozen
    private func restartDeviceMotion() {
        motionManager.stopDeviceMotionUpdates()
        motionManager.showsDeviceMovementDisplay = false
        motionManager.startDeviceMotionUpdates(
            using: .xArbitraryZVertical,
            to: motionQueue
        ) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }
            self.captureMotionData(motion)
        }
        print("🔄 Restarted motion updates.")
    }
    
    // MARK: - CSV Export (includes new orientation columns)
    private func exportCSV() -> URL? {
        let fileName = "Session_\(Int(Date().timeIntervalSince1970)).csv"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        
        var csv = "timestamp,magnitude,accX,accY,accZ,gyroX,gyroY,gyroZ,heartRate,roll,pitch,yaw,facingForward,wrist,isForehand,isBackhand\n"
        
        for e in dataLog {
            csv.append(
                "\(e.timestamp.timeIntervalSince1970),"
                + "\(e.magnitude),"
                + "\(e.accX),\(e.accY),\(e.accZ),"
                + "\(e.gyroX),\(e.gyroY),\(e.gyroZ),"
                + "\(e.heartRate),"
                + "\(e.roll),"
                + "\(e.pitch),\(e.yaw),"
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
        //let peakRMSGyroMagnitude: Double
        let peakGyroFiltered: Double
        let duration: Double
        let type: String
    }
    
    private var swingSummaries: [SwingSummary] = []

    private func appendSwingToCSV(_ summary: SwingSummary) {
        let formatter = ISO8601DateFormatter()
        let ts = formatter.string(from: summary.timestamp)

        let csvLine = "\(ts),\(summary.type),\(String(format: "%.3f", summary.peakMagnitude)),\(String(format: "%.3f", summary.peakGyroFiltered)),\(String(format: "%.2f", summary.duration))\n"
        
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SwingSummaries.csv")
        
        if !FileManager.default.fileExists(atPath: fileURL.path) {
            let header = "Timestamp,Type,PeakMagnitude(g),peakGyroFiltered(rad/s),Duration(s)\n"
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
    
    private func resetSwingSummaryCSV() {
        let fileURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            .appendingPathComponent("SwingSummaries.csv")
        
        if FileManager.default.fileExists(atPath: fileURL.path) {
            do {
                try FileManager.default.removeItem(at: fileURL)
                print("🧹 Cleared old SwingSummaries.csv")
            } catch {
                print("⚠️ Failed to delete old SwingSummaries.csv: \(error.localizedDescription)")
            }
        }
    }
}

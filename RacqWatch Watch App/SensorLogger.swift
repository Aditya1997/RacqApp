//
//  SensorLogger.swift
//  RacqWatch Watch App
//
//  Logs CoreMotion and HealthKit data during a session
//

import Foundation
import CoreMotion
import HealthKit
import Combine

@MainActor
final class SensorLogger: ObservableObject {
    static let shared = SensorLogger()

    private let motionManager = CMMotionManager()
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKQuery?
    private var timer: Timer?

    @Published var isRecording = false
    @Published var latestHeartRate: Double = 0.0
    @Published var logCount: Int = 0

    private var dataLog: [String] = []
    private var sessionStart: Date?

    // MARK: - Start Recording
    func startLogging() {
        guard !isRecording else { return }
        isRecording = true
        sessionStart = Date()
        dataLog.removeAll()

        // CSV Header
        dataLog.append("timestamp,accelX,accelY,accelZ,gyroX,gyroY,gyroZ,gravX,gravY,gravZ,roll,pitch,yaw,heartRate")

        print("🟢 Starting motion + heart rate logging...")
        startMotionUpdates()
        startHeartRateStreaming()
    }

    // MARK: - Stop Recording
    func stopLogging() -> URL? {
        guard isRecording else { return nil }
        isRecording = false

        motionManager.stopDeviceMotionUpdates()
        timer?.invalidate()
        timer = nil

        if let query = heartRateQuery {
            healthStore.stop(query)
        }

        // Write CSV file
        let fileURL = createCSV()
        print("🟣 Logging stopped. CSV file ready at \(fileURL.path)")

        // ✅ NEW: send file to iPhone automatically
        WatchWCManager.shared.sendFileToPhone(fileURL)

        return fileURL
    }


    // MARK: - Motion Updates
    private func startMotionUpdates() {
        guard motionManager.isDeviceMotionAvailable else {
            print("⚠️ Device motion not available.")
            return
        }

        motionManager.deviceMotionUpdateInterval = 1.0 / 50.0 // 50 Hz
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, error in
            guard let self = self, let motion = motion else { return }

            let accel = motion.userAcceleration
            let gyro = motion.rotationRate
            let grav = motion.gravity
            let attitude = motion.attitude

            let timestamp = Date().timeIntervalSince1970
            let hr = self.latestHeartRate

            let row = String(format: "%.3f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%.5f,%.1f",
                             timestamp,
                             accel.x, accel.y, accel.z,
                             gyro.x, gyro.y, gyro.z,
                             grav.x, grav.y, grav.z,
                             attitude.roll, attitude.pitch, attitude.yaw,
                             hr)

            self.dataLog.append(row)
            self.logCount += 1
        }
    }

    // MARK: - Heart Rate Streaming
    private func startHeartRateStreaming() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("⚠️ Health data unavailable.")
            return
        }

        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let typesToShare: Set = [HKQuantityType.workoutType()]
        let typesToRead: Set = [hrType]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [weak self] success, error in
            guard success, error == nil else {
                print("❌ HealthKit auth failed:", error?.localizedDescription ?? "Unknown")
                return
            }
            self?.startHeartRateQuery()
        }
    }

    private func startHeartRateQuery() {
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)

        heartRateQuery = HKAnchoredObjectQuery(type: hrType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) {
            [weak self] _, samples, _, _, _ in
            guard let self = self,
                  let samples = samples as? [HKQuantitySample],
                  let latest = samples.last else { return }

            let bpm = latest.quantity.doubleValue(for: HKUnit(from: "count/min"))
            DispatchQueue.main.async {
                self.latestHeartRate = bpm
            }
        }

        if let query = heartRateQuery {
            healthStore.execute(query)
        }
    }

    // MARK: - CSV Export
    private func createCSV() -> URL {
        let fileName = "Racq_Session_\(ISO8601DateFormatter().string(from: Date())).csv"
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)

        do {
            let csvData = dataLog.joined(separator: "\n")
            try csvData.write(to: fileURL, atomically: true, encoding: .utf8)
            return fileURL
        } catch {
            print("❌ Failed to write CSV:", error.localizedDescription)
            return fileURL
        }
    }
}

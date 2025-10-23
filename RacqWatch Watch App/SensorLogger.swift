//
//  SensorLogger.swift
//  RacqWatch Watch App
//

import Foundation
import CoreMotion
import Combine
import WatchConnectivity

@MainActor
final class SensorLogger: ObservableObject {
    static let shared = SensorLogger()
    private let motion = MotionManager.shared
    private let wc = WatchWCManager.shared

    private var startTime: Date?
    private var endTime: Date?
    private var sessionNumber: Int = 0

    // ✅ FIX: no 'override' here
    private init() {}

    // MARK: - Start Logging
    func startLogging() {
        guard !motion.isActive else { return }
        startTime = Date()
        sessionNumber += 1
        print("📈 Starting Sensor Logger - Session #\(sessionNumber)")
        motion.startMotionUpdates()
    }

    // MARK: - Stop Logging & Export
    func stopLoggingAndExport() {
        guard motion.isActive else { return }
        motion.stopMotionUpdates()
        endTime = Date()

        // Calculate duration
        let duration = endTime?.timeIntervalSince(startTime ?? Date()) ?? 0
        let totalShots = motion.shotCount

        // Export CSV
        if let fileURL = motion.exportCSV() {
            let formattedDate = Date().formatted(date: .abbreviated, time: .standard)
            let sessionFileName = "\(formattedDate) - Session \(sessionNumber).csv"
            let destination = FileManager.default.temporaryDirectory.appendingPathComponent(sessionFileName)

            do {
                try FileManager.default.moveItem(at: fileURL, to: destination)
                print("✅ CSV renamed to: \(destination.lastPathComponent)")

                // Send to iPhone
                if WCSession.default.isReachable {
                    WCSession.default.transferFile(destination, metadata: [
                        "sessionNumber": "\(sessionNumber)",
                        "duration": "\(Int(duration))",
                        "totalShots": "\(totalShots)"
                    ])
                    print("📤 CSV sent to iPhone for session \(sessionNumber)")
                } else {
                    print("⚠️ iPhone not reachable, file saved locally")
                }

            } catch {
                print("❌ Failed to rename or send CSV: \(error)")
            }
        } else {
            print("⚠️ No CSV file available to export")
        }

        startTime = nil
        endTime = nil
    }
}

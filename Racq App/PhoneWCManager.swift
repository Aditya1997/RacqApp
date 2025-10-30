//
//  PhoneWCManager.swift
//  RacqApp
//  Updated 10/30 to reflect small updates to CSV importation and allow for phone app operation without watch

import Foundation
import Combine
import WatchConnectivity

@MainActor
final class PhoneWCManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = PhoneWCManager()

    @Published var isConnected: Bool = false

    // Summary data for dashboard
    @Published var summaryShotCount: Int = 0
    @Published var summaryDurationSec: Int = 0
    @Published var summaryHeartRate: Double = 0
    @Published var summaryTimestampISO: String = ""
    @Published var summaryforehandCount: Int = 0
    @Published var summarybackhandCount: Int = 0

    // CSV file received from watch
    @Published var csvURL: URL?

    private override init() {
        super.init()
        setupSession()
    }

    // MARK: - Session Setup
    private func setupSession() {
        guard WCSession.isSupported() else {
            print("⚠️ WatchConnectivity not supported — running in phone-only mode.")
            isConnected = false
            return
        }

        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    // MARK: - WCSessionDelegate
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        DispatchQueue.main.async {
            self.isConnected = (activationState == .activated && session.isPaired)
            if let e = error {
                print("❌ Phone activate error: \(e.localizedDescription)")
            } else {
                print("✅ Phone session activated — paired: \(self.isConnected)")
            }
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isConnected = session.isReachable
            print("📡 Reachability changed — reachable: \(self.isConnected)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {
        DispatchQueue.main.async { self.isConnected = false }
    }

    func sessionDidDeactivate(_ session: WCSession) {
        DispatchQueue.main.async { self.isConnected = false }
    }

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        DispatchQueue.main.async {
            self.applySummary(message)
        }
    }

    // MARK: - Handle Summary Data
    private func applySummary(_ dict: [String: Any]) {
        if let shots = dict["shotCount"] as? Int { summaryShotCount = shots }
        if let dur = dict["durationSec"] as? Int ?? dict["duration"] as? Int { summaryDurationSec = dur }
        if let hr = dict["heartRate"] as? Double { summaryHeartRate = hr }
        if let ts = dict["timestampISO"] as? String ?? dict["timestamp"] as? String { summaryTimestampISO = ts }
        if let fh = dict["forehandCount"] as? Int { summaryforehandCount = fh }
        if let bh = dict["backhandCount"] as? Int { summarybackhandCount = bh }

        print("📥 Summary received: shots=\(summaryShotCount), dur=\(summaryDurationSec), hr=\(summaryHeartRate)")
    }

    // MARK: - File Transfer
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dest = docs.appendingPathComponent(file.fileURL.lastPathComponent)

        do {
            if fm.fileExists(atPath: dest.path) {
                try fm.removeItem(at: dest)
            }
            try fm.copyItem(at: file.fileURL, to: dest)
            DispatchQueue.main.async { // ✅ Critical fix
                self.csvURL = dest
                print("📄 CSV received and saved at: \(dest.path)")
            }
        } catch {
            print("❌ Failed to move CSV: \(error.localizedDescription)")
        }
    }
}

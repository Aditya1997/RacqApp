//
//  PhoneWCManager.swift
//  RacqApp
//

import Foundation
import Combine
import WatchConnectivity

@MainActor
final class PhoneWCManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = PhoneWCManager()

    @Published var isConnected: Bool = false

    // summary shown on dashboard
    @Published var summaryShotCount: Int = 0
    @Published var summaryDurationSec: Int = 0
    @Published var summaryHeartRate: Double = 0
    @Published var summaryTimestampISO: String = ""

    // csv file received from watch
    @Published var csvURL: URL?

    private override init() {
        super.init()
        activate()
    }

    private func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
        print("📱 WC activated (phone)")
    }

    // MARK: - WCSessionDelegate
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        isConnected = (activationState == .activated)
        if let e = error { print("❌ phone activate error: \(e.localizedDescription)") }
    }

    func sessionDidBecomeInactive(_ session: WCSession) { }
    func sessionDidDeactivate(_ session: WCSession) { WCSession.default.activate() }

    // summary via message or applicationContext
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        applySummary(message)
    }
    func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String : Any]) {
        applySummary(applicationContext)
    }

    private func applySummary(_ dict: [String: Any]) {
        if let shots = dict["shotCount"] as? Int { summaryShotCount = shots }
        if let dur = dict["duration"] as? Int { summaryDurationSec = dur }
        if let hr = dict["heartRate"] as? Double { summaryHeartRate = hr }
        if let ts = dict["timestamp"] as? String { summaryTimestampISO = ts }
        print("📥 summary updated: shots=\(summaryShotCount) dur=\(summaryDurationSec) hr=\(summaryHeartRate)")
    }

    // file transfer
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dest = docs.appendingPathComponent(file.fileURL.lastPathComponent)
        try? fm.removeItem(at: dest)
        do {
            try fm.copyItem(at: file.fileURL, to: dest)
            csvURL = dest
            print("📄 CSV received at \(dest.path)")
        } catch {
            print("❌ failed to move CSV: \(error.localizedDescription)")
        }
    }
}

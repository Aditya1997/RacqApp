//
//  WatchWCManager.swift
//  RacqWatch Watch App
//

import Foundation
import WatchConnectivity

final class WatchWCManager: NSObject, WCSessionDelegate {
    static let shared = WatchWCManager()
    private override init() { super.init() }

    func activateSession() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
        print("⌚️ WC activated (watch)")
    }

    func sendData(_ dict: [String: Any]) {
        guard WCSession.default.activationState == .activated else { return }
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(dict, replyHandler: nil) { err in
                print("❌ sendMessage error: \(err.localizedDescription)")
            }	
        } else {
            try? WCSession.default.updateApplicationContext(dict)
        }
    }

    func sendFileToPhone(_ url: URL) {
        let meta = ["fileName": url.lastPathComponent]
        WCSession.default.transferFile(url, metadata: meta)
        print("📤 queued file transfer: \(url.lastPathComponent)")
    }

    // MARK: delegate
    func session(_ session: WCSession,
                 activationDidCompleteWith activationState: WCSessionActivationState,
                 error: Error?) {
        if let e = error { print("❌ WC activate fail: \(e.localizedDescription)") }
        else { print("✅ WC active: \(activationState == .activated)") }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        print("🔄 reachability: \(session.isReachable)")
    }
}

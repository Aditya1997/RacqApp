//
//  WatchWCManager.swift
//  RacqWatch Watch App
//  11/19/2025 adding height variable and receiving it

import Foundation
import WatchConnectivity

final class WatchWCManager: NSObject, WCSessionDelegate {
    static let shared = WatchWCManager()
    private override init() { super.init() }

    private var liveTimer: DispatchSourceTimer?
    var userHeight: Double = UserDefaults.standard.double(forKey: "userHeightInInches")

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

    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let height = message["height"] as? Double {
            DispatchQueue.main.async {
                self.userHeight = height
                UserDefaults.standard.set(height, forKey: "userHeightInInches")
            }
            print("📩 Watch received height: \(height)")
        }
    }
    
    // MARK: - Live update functions for RecordView
    
    func startLiveUpdates(provider: @escaping () -> [String: Any]) {
        stopLiveUpdates()

        let timer = DispatchSource.makeTimerSource(queue: .global(qos: .utility))
        timer.schedule(deadline: .now(), repeating: 1.0)

        timer.setEventHandler {
            var payload = provider()
            payload["live"] = true
            self.sendData(payload)
        }

        timer.resume()
        liveTimer = timer
    }
    
    func stopLiveUpdates() {
        liveTimer?.cancel()
        liveTimer = nil
    }
    
    // MARK: - delegate
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

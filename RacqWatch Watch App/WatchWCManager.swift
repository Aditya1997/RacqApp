//
//  WatchWCManager.swift
//  RacqWatch Watch App
//

import Foundation
import WatchConnectivity
import Combine

@MainActor
final class WatchWCManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchWCManager()

    @Published var isReachable = false
    @Published var lastEvent: String = "Waiting…"
    private var session: WCSession?

    private override init() {
      
        super.init()
        activate()
    }

    private func activate() {
        guard WCSession.isSupported() else {
            lastEvent = "WC not supported"
            return
        }
        let s = WCSession.default
        s.delegate = self
        s.activate()
        session = s
        print("⌚️ WCSession activated on Watch.")
    }

    func sendMessage(_ payload: [String: Any]) {
        guard let s = session, s.isReachable else {
            print("📵 iPhone not reachable.")
            return
        }
        s.sendMessage(payload, replyHandler: nil) { error in
            print("❌ Watch send error:", error.localizedDescription)
        }
    }

    // MARK: - File Sending
    func sendFileToPhone(_ fileURL: URL) {
        let session = WCSession.default

        if session.isReachable {
            session.transferFile(fileURL, metadata: ["type": "motionCSV"])
            print("📤 File transfer started immediately:", fileURL.lastPathComponent)
        } else {
            print("📦 Queued file transfer — phone not reachable.")
            session.transferFile(fileURL, metadata: ["type": "motionCSV"])
        }
    }

    // MARK: - Delegates
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        if let error = error {
            print("❌ Activation error:", error.localizedDescription)
        } else {
            print("✅ Activation state:", activationState.rawValue)
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isReachable = session.isReachable
            print("🔄 Reachability changed:", session.isReachable)
        }
    }
}

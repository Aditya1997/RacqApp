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

    @Published var isPhoneConnected: Bool = false
    @Published var lastMessage: String = ""
    @Published var liveShotCount: Int = 0

    private var pingTimer: Timer?

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
        startPingTimer()
    }

    // MARK: - Send live shot updates
    func sendShotCount(_ count: Int) {
        guard WCSession.default.isReachable else { return }
        WCSession.default.sendMessage(["shotCount": count], replyHandler: nil)
        print("📤 Sent shot count: \(count)")
    }

    // MARK: - Send CSV to phone
    func sendFileToPhone(_ fileURL: URL, duration: TimeInterval, totalShots: Int) {
        guard WCSession.default.activationState == .activated else {
            print("⚠️ WCSession not active")
            return
        }

        let metadata: [String: Any] = [
            "fileName": fileURL.lastPathComponent,
            "shots": totalShots,
            "duration": duration,
            "date": Date().timeIntervalSince1970
        ]

        WCSession.default.transferFile(fileURL, metadata: metadata)
        print("📤 Sent file to phone with metadata: \(metadata)")
    }

    // MARK: - Connection Ping
    private func startPingTimer() {
        pingTimer?.invalidate()
        pingTimer = Timer.scheduledTimer(withTimeInterval: 8, repeats: true) { [weak self] _ in
            self?.pingPhone()
        }
    }

    private func pingPhone() {
        guard WCSession.default.isReachable else {
            isPhoneConnected = false
            return
        }

        WCSession.default.sendMessage(["ping": "watchActive"], replyHandler: { _ in
            self.isPhoneConnected = true
        }, errorHandler: { _ in
            self.isPhoneConnected = false
        })
    }

    // MARK: - WCSessionDelegate
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("❌ Activation failed: \(error.localizedDescription)")
        } else {
            print("✅ Watch session activated")
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isPhoneConnected = session.isReachable
        }
    }

    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let reset = message["resetShots"] as? Bool, reset == true {
            Task { @MainActor in self.liveShotCount = 0 }
        }
    }
}

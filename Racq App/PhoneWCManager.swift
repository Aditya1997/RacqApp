//
//  PhoneWCManager.swift
//  Racq App
//

import Foundation
import WatchConnectivity
import Combine
import SwiftUI

@MainActor
final class PhoneWCManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = PhoneWCManager()

    @Published var isWatchConnected: Bool = false
    @Published var lastFileName: String = ""
    @Published var receivedFiles: [URL] = []

    private var session: WCSession?

    private override init() {
        super.init()
        activate()
    }

    // MARK: - Activation
    private func activate() {
        guard WCSession.isSupported() else {
            print("⚠️ WatchConnectivity not supported on this device.")
            return
        }

        let s = WCSession.default
        s.delegate = self
        s.activate()
        session = s

        // Immediate initial state check
        Task { @MainActor in
            self.isWatchConnected = s.isPaired && s.isWatchAppInstalled
            print("📱 Initial WC state -> Watch connected:", self.isWatchConnected)
        }

        print("📱 WCSession activated on iPhone.")
    }

    // MARK: - WCSession Delegate Methods
    nonisolated func session(_ session: WCSession,
                             activationDidCompleteWith activationState: WCSessionActivationState,
                             error: Error?) {
        if let error = error {
            print("❌ Activation error:", error.localizedDescription)
        } else {
            print("✅ WCSession activation state:", activationState.rawValue)
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {
        print("⚙️ sessionDidBecomeInactive()")
    }

    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        print("⚙️ sessionDidDeactivate() → reactivating")
        WCSession.default.activate()
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isWatchConnected = session.isPaired && session.isWatchAppInstalled
            print("🔄 Watch state changed:", self.isWatchConnected)
        }
    }

    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isWatchConnected = session.isReachable
            print("📶 Reachability changed:", session.isReachable)
        }
    }

    // MARK: - File Transfer Handling
    nonisolated func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let destination = FileManager.default.temporaryDirectory.appendingPathComponent(file.fileURL.lastPathComponent)

        do {
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.copyItem(at: file.fileURL, to: destination)
            Task { @MainActor in
                self.receivedFiles.append(destination)
                self.lastFileName = destination.lastPathComponent
                print("📥 Received file:", destination.lastPathComponent)
            }
        } catch {
            print("❌ Error saving received file:", error.localizedDescription)
        }
    }
}

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
    @Published var receivedFiles: [URL] = []
    @Published var lastFileName: String = "No files received"
    @Published var completedSessions: [SessionSummary] = []

    private var sessionNumber: Int = 0
    private let session = WCSession.default

    struct SessionSummary: Identifiable {
        let id = UUID()
        let date: Date
        let duration: TimeInterval
        let shots: Int
        let fileURL: URL
    }

    private override init() {
        super.init()
        if WCSession.isSupported() {
            session.delegate = self
            session.activate()
        }
    }

    // MARK: - WCSession Delegate
    nonisolated func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            print("❌ WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("✅ iPhone WCSession activated: \(activationState.rawValue)")
        }

        Task { @MainActor in
            self.isWatchConnected = session.isPaired && session.isWatchAppInstalled
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        Task { @MainActor in self.isWatchConnected = false }
    }

    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in
            self.isWatchConnected = session.isPaired && session.isWatchAppInstalled
            print("⌚️ Watch connection updated → \(self.isWatchConnected)")
        }
    }

    // MARK: - File Reception
    nonisolated func session(_ session: WCSession, didReceive file: WCSessionFile) {
        Task { @MainActor in
            handleReceivedFile(file)
        }
    }

    private func handleReceivedFile(_ file: WCSessionFile) {
        let fileManager = FileManager.default
        let docsDir = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]

        sessionNumber += 1

        // ✅ Match keys from Watch metadata
        let duration = Double(file.metadata?["duration"] as? String ?? "0") ?? 0
        let totalShots = Int(file.metadata?["shots"] as? String ?? "0") ?? 0
        let sessionNum = file.metadata?["sessionNumber"] as? String ?? "\(sessionNumber)"

        // ✅ Clean filename
        let formattedDate = Date().formatted(date: .abbreviated, time: .standard)
        let newFileName = "\(formattedDate) - Session \(sessionNum).csv"
        let destination = docsDir.appendingPathComponent(newFileName)

        // Save CSV file
        do {
            if fileManager.fileExists(atPath: destination.path) {
                try fileManager.removeItem(at: destination)
            }
            try fileManager.copyItem(at: file.fileURL, to: destination)

            let summary = SessionSummary(
                date: Date(),
                duration: duration,
                shots: totalShots,
                fileURL: destination
            )

            receivedFiles.append(destination)
            lastFileName = destination.lastPathComponent
            completedSessions.append(summary)

            print("✅ Received and saved CSV: \(destination.lastPathComponent)")
            print("📊 Shots: \(totalShots), Duration: \(duration)s")
        } catch {
            print("❌ Failed to save received CSV: \(error.localizedDescription)")
        }
    }

    // MARK: - File Sharing Helper
    func shareFile(_ fileURL: URL, from controller: UIViewController? = nil) {
        let activityVC = UIActivityViewController(activityItems: [fileURL], applicationActivities: nil)
        let presentingVC = controller ?? UIApplication.shared.connectedScenes
            .compactMap { ($0 as? UIWindowScene)?.windows.first?.rootViewController }
            .first

        presentingVC?.present(activityVC, animated: true)
    }
}

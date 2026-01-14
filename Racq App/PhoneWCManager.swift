//
//  PhoneWCManager.swift
//  RacqApp
//  10/30/2025 to reflect small updates to CSV importation and allow for phone app operation without watch
//  11/19/2025 pushing height variable

import Foundation
import Combine
import WatchConnectivity

@MainActor
final class PhoneWCManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = PhoneWCManager()

    @Published var isConnected: Bool = false
    @Published var userHeight: Double = UserDefaults.standard.double(forKey: "userHeightInInches")

    // Summary data for dashboard
    @Published var summaryShotCount: Int = 0
    @Published var summaryDurationSec: Int = 0
    @Published var summaryHeartRate: Double = 0
    @Published var summaryTimestampISO: String = ""
    @Published var summaryforehandCount: Int = 0
    @Published var summarybackhandCount: Int = 0
    @Published var summaryFastestSwing: Double = 0
    
    // CSV file received from watch
    @Published var csvURL: URL?
    @Published var summaryCSVURL: URL?

    private var lastAppliedSessionTimestampISO: String = ""

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
        print("📩 FULL MESSAGE RECEIVED:", message)
        if let height = message["height"] as? Double {
            DispatchQueue.main.async {
                self.userHeight = height
            }
            print("📩 Phone received height: \(height)")
        }
        DispatchQueue.main.async {
            self.applySummary(message)
        }
    }
    
    // MARK: - Handle Summary Data
    private func applySummary(_ dict: [String: Any]) {
        if let shots = dict["shotCount"] as? Int { summaryShotCount = shots }
        if let fast = dict["fastestSwing"] as? Double { summaryFastestSwing = fast}
        if let dur = dict["durationSec"] as? Int ?? dict["duration"] as? Int { summaryDurationSec = dur }
        if let hr = dict["heartRate"] as? Double { summaryHeartRate = hr }
        if let ts = dict["timestampISO"] as? String ?? dict["timestamp"] as? String { summaryTimestampISO = ts }
        if let fh = dict["forehandCount"] as? Int { summaryforehandCount = fh }
        if let bh = dict["backhandCount"] as? Int { summarybackhandCount = bh }

        print("📥 Summary received: shots=\(summaryShotCount), dur=\(summaryDurationSec), hr=\(summaryHeartRate)")
        
        // Applying session summary to challenges
        let ts = summaryTimestampISO
        if !ts.isEmpty, ts != lastAppliedSessionTimestampISO {
            lastAppliedSessionTimestampISO = ts
            let summary = SessionSummary(
                shotCount: summaryShotCount,
                forehandCount: summaryforehandCount,
                backhandCount: summarybackhandCount,
                durationSec: summaryDurationSec,
                fastestSwing: 0,
                heartRate: summaryHeartRate,
                timestampISO: summaryTimestampISO
            )
            let pid = UserIdentity.participantId()
            let name = UserIdentity.displayName()
            Task { @MainActor in
                let store = ChallengeStore()
                await store.applySessionToJoinedChallenges(summary, participantId: pid, displayName: name)

            }
            let groupIds = GroupMembership.getGroupIds()
            Task { @MainActor in
                await GroupStore.shared.applySessionToGroupLeaderboards(
                    summary: summary,
                    participantId: pid,
                    displayName: name,
                    groupIds: groupIds)
                await UserSessionStore().saveSessionAndIncrementStats(
                    participantId: UserIdentity.participantId(),
                    displayName: name,
                    summary: summary,
                    csvURL: csvURL,
                    timestampISO: ts)
            }
        }
    }
    
    

    // MARK: - File Transfer
    func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let fm = FileManager.default
        let docs = fm.urls(for: .documentDirectory, in: .userDomainMask).first!
        let dest = docs.appendingPathComponent(file.fileURL.lastPathComponent)

        let swings = loadSwingSummaryCSV(from: dest)
        let height = UserDefaults.standard.double(forKey: "userHeightInInches")

        let fhMax = SwingMath.maxFHSpeed(swings: swings, height: height)
        let bhMax = SwingMath.maxBHSpeed(swings: swings, height: height)
        let fastest = max(fhMax, bhMax)

        summaryFastestSwing = fastest

        // ✅ Patch Firestore for this session + profile fastest
        Task {
            let participantId = UserIdentity.participantId()
            let sessionId = self.lastAppliedSessionTimestampISO.isEmpty ? self.lastAppliedSessionTimestampISO : self.lastAppliedSessionTimestampISO
            if !sessionId.isEmpty {
                await UserSessionStore().updateFastestSwingForSession(
                    participantId: participantId,
                    sessionId: sessionId,
                    fastestSwing: fastest
                )
            } else {
                print("⚠️ No sessionId available to patch fastest swing")
            }
        }
        
        do {
            if fm.fileExists(atPath: dest.path) {
                try fm.removeItem(at: dest)
            }
            try fm.copyItem(at: file.fileURL, to: dest)

            DispatchQueue.main.async {
                if dest.lastPathComponent.contains("SwingSummaries") {
                    self.summaryCSVURL = dest     // <-- summary file
                    print("📄 SUMMARY CSV received: \(dest.lastPathComponent)")
                } else {
                    self.csvURL = dest            // <-- session file
                    print("📄 SESSION CSV received: \(dest.lastPathComponent)")
                }
            }

        } catch {
            print("❌ Failed moving CSV: \(error.localizedDescription)")
        }
    }
}

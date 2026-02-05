//
//  UserSessionStore.swift
//  Racq App
//
//  Created by Deets on 1/12/26.
//  Saves off the source of truth for all session data (UserSession.swift)

import Foundation
import Combine
import Firebase
import FirebaseFirestore

@MainActor
final class UserSessionStore: ObservableObject {
    @Published var sessions: [UserSession] = []
    
    private var db: Firestore { FirebaseManager.shared.db }
    
    func saveSessionAndIncrementStats(
        participantId: String,
        displayName: String,
        summary: SessionSummary,
        csvURL: URL?,
        timestampISO: String,
    ) async {
        guard FirebaseApp.app() != nil else {
            print("⚠️ Firebase not configured yet")
            return
        }
        
        let cleanISO = timestampISO.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanISO.isEmpty else {
            print("⚠️ timestampISO missing; not saving session")
            return
        }
        
        let userRef = db.collection("users").document(participantId)
        let sessionRef = userRef.collection("sessions").document(cleanISO)
        
        do {
            // Ensure user doc exists
            try await userRef.setData([
                "displayName": displayName,
                "updatedAt": Timestamp(date: Date())
            ], merge: true)
            
            // 1) Save session document (includes fastestSwing)
            try await sessionRef.setData([
                "timestampISO": cleanISO,
                "timestamp": Timestamp(date: Date()),
                "shotCount": summary.shotCount,
                "forehandCount": summary.forehandCount,
                "backhandCount": summary.backhandCount,
                "durationSec": summary.durationSec,
                "heartRate": summary.heartRate,
                "fastestSwing": summary.fastestSwing,
                "csvFileName": csvURL?.lastPathComponent as Any,
                "updatedAt": Timestamp(date: Date())
            ], merge: true)
            
            // 2) Increment user stats atomically
            try await userRef.updateData([
              "stats.sessionsCompleted": FieldValue.increment(Int64(1)),
              "stats.totalHits": FieldValue.increment(Int64(summary.shotCount)),
              "stats.totalForehands": FieldValue.increment(Int64(summary.forehandCount)),
              "stats.totalBackhands": FieldValue.increment(Int64(summary.backhandCount)),
              "stats.totalDurationSec": FieldValue.increment(Int64(summary.durationSec))
            ])
            
            print("✅ Saved session + updated stats)")
        } catch {
            print("❌ saveSessionAndIncrementStats error:", error.localizedDescription)
        }
    }
    
    func fetchSessions(participantId: String, limit: Int = 50) async {
        guard FirebaseApp.app() != nil else {
            print("⚠️ Firebase not configured yet")
            return
        }
        
        do {
            let snapshot = try await db.collection("users")
                .document(participantId)
                .collection("sessions")
                .order(by: "timestamp", descending: true)
                .limit(to: limit)
                .getDocuments()
            
            let parsed: [UserSession] = snapshot.documents.compactMap { doc in
                let d = doc.data()
                
                let ts = (d["timestamp"] as? Timestamp)?.dateValue() ?? Date()
                let shotCount = d["shotCount"] as? Int ?? 0
                let forehandCount = d["forehandCount"] as? Int ?? 0
                let backhandCount = d["backhandCount"] as? Int ?? 0
                let durationSec = d["durationSec"] as? Int ?? 0
                let fastestSwing = d["fastestSwing"] as? Double ?? 0.0
                let fhMaxMph = d["fhMaxMph"] as? Double ?? 0
                let fhAvgMph = d["fhAvgMph"] as? Double ?? 0
                let bhMaxMph = d["bhMaxMph"] as? Double ?? 0
                let bhAvgMph = d["bhAvgMph"] as? Double ?? 0
                let heartRate = d["heartRate"] as? Double ?? 0
                let csvFileName = d["csvFileName"] as? String
                
                return UserSession(
                    id: doc.documentID,
                    timestamp: ts,
                    shotCount: shotCount,
                    forehandCount: forehandCount,
                    backhandCount: backhandCount,
                    durationSec: durationSec,
                    fastestSwing: fastestSwing,
                    fhMaxMph: fhMaxMph,
                    fhAvgMph: fhAvgMph,
                    bhMaxMph: bhMaxMph,
                    bhAvgMph: bhAvgMph,
                    heartRate: heartRate,
                    csvFileName: csvFileName
                )
            }
            
            self.sessions = parsed
            print("✅ Loaded \(parsed.count) user sessions")
        } catch {
            print("❌ Failed to fetch sessions: \(error)")
        }
    }
    
    /// ✅ Fetch a single session doc (used by feed/detail views when a post doesn't carry the session payload)
    func fetchSession(participantId: String, sessionId: String) async -> UserSession? {
        guard FirebaseApp.app() != nil else {
            print("⚠️ Firebase not configured yet")
            return nil
        }
        
        do {
            let doc = try await db.collection("users")
                .document(participantId)
                .collection("sessions")
                .document(sessionId)
                .getDocument()
            
            guard let d = doc.data() else {
                print("⚠️ No session doc data for", participantId, sessionId)
                return nil
            }
            
            let ts = (d["timestamp"] as? Timestamp)?.dateValue() ?? Date()
            let shotCount = d["shotCount"] as? Int ?? 0
            let forehandCount = d["forehandCount"] as? Int ?? 0
            let backhandCount = d["backhandCount"] as? Int ?? 0
            let durationSec = d["durationSec"] as? Int ?? 0
            let fastestSwing = d["fastestSwing"] as? Double ?? 0.0
            let fhMaxMph = d["fhMaxMph"] as? Double ?? 0
            let fhAvgMph = d["fhAvgMph"] as? Double ?? 0
            let bhMaxMph = d["bhMaxMph"] as? Double ?? 0
            let bhAvgMph = d["bhAvgMph"] as? Double ?? 0
            let heartRate = d["heartRate"] as? Double ?? 0
            let csvFileName = d["csvFileName"] as? String
            
            return UserSession(
                id: sessionId,
                timestamp: ts,
                shotCount: shotCount,
                forehandCount: forehandCount,
                backhandCount: backhandCount,
                durationSec: durationSec,
                fastestSwing: fastestSwing,
                fhMaxMph: fhMaxMph,
                fhAvgMph: fhAvgMph,
                bhMaxMph: bhMaxMph,
                bhAvgMph: bhAvgMph,
                heartRate: heartRate,
                csvFileName: csvFileName
            )
        } catch {
            print("❌ fetchSession error:", error.localizedDescription)
            return nil
        }
    }
}
    
extension UserSessionStore {
    /// Patch per-hand speeds into an existing session doc.
    func updateSpeedMetricsForSession(
        participantId: String,
        sessionId: String,
        metrics: SessionSpeedMetrics
    ) async {
        guard FirebaseApp.app() != nil else { return }

        let sessionRef = FirebaseManager.shared.db
            .collection("users")
            .document(participantId)
            .collection("sessions")
            .document(sessionId)

        do {
            try await sessionRef.setData([
                "fhMaxMph": metrics.fhMaxMph,
                "fhAvgMph": metrics.fhAvgMph,
                "bhMaxMph": metrics.bhMaxMph,
                "bhAvgMph": metrics.bhAvgMph,

                // keep your existing single fastestSwing aligned
                "fastestSwing": metrics.overallMaxMph,

                "updatedAt": Timestamp(date: Date())
            ], merge: true)

            print("✅ Patched speed metrics for session:", sessionId)
        } catch {
            print("❌ updateSpeedMetricsForSession error:", error.localizedDescription)
        }
    }
}


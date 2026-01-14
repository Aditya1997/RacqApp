//
//  UserSessionStore.swift
//  Racq App
//
//  Created by Deets on 1/12/26.
//

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
        timestampISO: String
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

            // 1) Save session document (includes fastestSwingMph)
            try await sessionRef.setData([
                "timestampISO": cleanISO,
                "timestamp": Timestamp(date: Date()),
                "shotCount": summary.shotCount,
                "forehandCount": summary.forehandCount,
                "backhandCount": summary.backhandCount,
                "durationSec": summary.durationSec,
                "fastestSwing": summary.fastestSwing,
                "heartRate": summary.heartRate,
                "csvFileName": csvURL?.lastPathComponent as Any,
                "updatedAt": Timestamp(date: Date())
            ], merge: true)

            // 2) Increment user stats atomically
            try await userRef.setData([
                "stats.sessionsCompleted": FieldValue.increment(Int64(1)),
                "stats.totalHits": FieldValue.increment(Int64(summary.shotCount)),
                "stats.totalForehands": FieldValue.increment(Int64(summary.forehandCount)),
                "stats.totalBackhands": FieldValue.increment(Int64(summary.backhandCount)),
                "stats.totalDurationSec": FieldValue.increment(Int64(summary.durationSec))
            ], merge: true)

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
    
    func updateFastestSwingForSession(
        participantId: String,
        sessionId: String,
        fastestSwing: Double
    ) async {
        guard FirebaseApp.app() != nil else { return }
        guard fastestSwing > 0 else { return }

        let userRef = db.collection("users").document(participantId)
        let sessionRef = userRef.collection("sessions").document(sessionId)

        do {
            // 1) Patch session doc
            try await sessionRef.setData([
                "fastestSwing": fastestSwing,
                "updatedAt": Timestamp(date: Date())
            ], merge: true)

            // 2) Update profile fastest only if higher (transaction-safe)
            try await db.runTransaction { transaction, errorPointer in
                do {
                    let snapshot = try transaction.getDocument(userRef)

                    let stats = snapshot.data()?["stats"] as? [String: Any] ?? [:]
                    let current = stats["fastestSwing"] as? Double ?? 0.0

                    if fastestSwing > current {
                        transaction.setData(
                            ["stats.fastestSwing": fastestSwing],
                            forDocument: userRef,
                            merge: true
                        )
                    }

                    return nil
                } catch {
                    // Tell Firestore the transaction failed
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }

            print("✅ Patched fastestSwing for session:", sessionId)
        } catch {
            print("❌ updateFastestSwingForSession error:", error.localizedDescription)
        }
    }
}

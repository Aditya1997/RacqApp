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

        let userRef = db.collection("users").document(participantId)
        let sessionRef = userRef.collection("sessions").document(timestampISO)

        do {
            // 1) Save session document
            try await sessionRef.setData([
                "timestamp": Timestamp(date: Date()),
                "shotCount": summary.shotCount,
                "forehandCount": summary.forehandCount,
                "backhandCount": summary.backhandCount,
                "durationSec": summary.durationSec,
                //"fastestSwing": summary.fastestSwing,
                "heartRate": summary.heartRate,
                "csvFileName": csvURL?.lastPathComponent as Any
            ], merge: true)

            // 2) Increment user stats atomically
            try await userRef.setData([
                "displayName": displayName,
                "stats.sessionsCompleted": FieldValue.increment(Int64(1)),
                "stats.totalHits": FieldValue.increment(Int64(summary.shotCount)),
                "stats.totalForehands": FieldValue.increment(Int64(summary.forehandCount)),
                "stats.totalBackhands": FieldValue.increment(Int64(summary.backhandCount)),
                "stats.totalDurationSec": FieldValue.increment(Int64(summary.durationSec))
            ], merge: true)

            print("✅ Saved session + incremented stats")
        } catch {
            print("❌ saveSessionAndIncrementStats error: \(error)")
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
                let heartRate = d["heartRate"] as? Double ?? 0
                let csvFileName = d["csvFileName"] as? String

                return UserSession(
                    id: doc.documentID,
                    timestamp: ts,
                    shotCount: shotCount,
                    forehandCount: forehandCount,
                    backhandCount: backhandCount,
                    durationSec: durationSec,
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
}

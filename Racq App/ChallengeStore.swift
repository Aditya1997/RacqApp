//
//  ChallengeStore.swift
//  Racq App
//
//  Created by Deets on 10/29/25.
//  10/30/2025 - Added Firebase backend functionality

import Foundation
import Combine
import Firebase
import FirebaseFirestore

@MainActor
final class ChallengeStore: ObservableObject {
    @Published var challenges: [Challenge] = []

    private var db: Firestore {
        FirebaseManager.shared.db
    }

    // MARK: - Fetch
    func fetchChallenges() async {
        guard FirebaseApp.app() != nil else {
            print("⚠️ Firebase not configured yet")
            return
        }

        do {
            let snapshot = try await db.collection("challenges").getDocuments()
            self.challenges = snapshot.documents.compactMap { doc in
                let data = doc.data()

                guard
                    let title = data["title"] as? String,
                    let goal = data["goal"] as? Int,
                    let progress = data["progress"] as? Int
                else { return nil }

                let participants = data["participants"] as? [String: Int] ?? [:]
                let sponsor = data["sponsor"] as? String
                let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()

                // ✅ NEW: tracked stat + minPerSession
                let trackedRaw = data["trackedStat"] as? String ?? "forehands"
                let tracked = ChallengeTrackedStat(rawValue: trackedRaw) ?? .forehands
                let minPerSession = data["minPerSession"] as? Int

                return Challenge(
                    id: doc.documentID,
                    title: title,
                    goal: goal,
                    progress: progress,
                    participants: participants,
                    sponsor: sponsor,
                    trackedStat: tracked,
                    minPerSession: minPerSession,
                    updatedAt: updatedAt
                )
            }

            print("✅ Loaded \(self.challenges.count) challenges")
        } catch {
            print("❌ Error fetching challenges: \(error.localizedDescription)")
        }
    }

    // MARK: - Create
    func addChallenge(_ challenge: Challenge) async {
        do {
            let docID = challenge.id ?? UUID().uuidString

            var payload: [String: Any] = [
                "title": challenge.title,
                "goal": challenge.goal,
                "progress": challenge.progress,
                "participants": challenge.participants,
                "trackedStat": challenge.trackedStat.rawValue,
                "minPerSession": challenge.minPerSession as Any,
                "updatedAt": Timestamp(date: Date())
            ]

            // ✅ only store sponsor if non-empty
            if let sponsor = challenge.sponsor?.trimmingCharacters(in: .whitespacesAndNewlines),
               !sponsor.isEmpty {
                payload["sponsor"] = sponsor
            }

            try await db.collection("challenges").document(docID).setData(payload)
        } catch {
            print("Error saving challenge: \(error)")
        }
    }

    // MARK: - Join (so only joined challenges auto-update for this user)
    func joinChallenge(challengeId: String, participantName: String = "You") async {
        do {
            try await db.collection("challenges")
                .document(challengeId)
                .updateData([
                    "participants.\(participantName)": 0,
                    "updatedAt": Timestamp(date: Date())
                ])
            await fetchChallenges()
        } catch {
            print("❌ joinChallenge failed: \(error)")
        }
    }

    // MARK: - Auto apply a completed session to joined challenges
    func applySessionToJoinedChallenges(_ summary: SessionSummary, participantName: String = "You") async {
        do {
            let snapshot = try await db.collection("challenges").getDocuments()

            for doc in snapshot.documents {
                let data = doc.data()

                // tracked stat required
                let trackedRaw = data["trackedStat"] as? String ?? "forehands"
                guard let tracked = ChallengeTrackedStat(rawValue: trackedRaw) else { continue }

                // only apply if joined
                let participants = data["participants"] as? [String: Int] ?? [:]
                guard participants[participantName] != nil else { continue }

                let goal = data["goal"] as? Int ?? 0
                let currentProgress = data["progress"] as? Int ?? 0
                if goal > 0, currentProgress >= goal { continue }

                let minPerSession = data["minPerSession"] as? Int ?? 0
                let delta = summary.value(for: tracked)

                // qualify session
                if delta < minPerSession { continue }
                if delta <= 0 { continue }

                // cap at goal (optional but recommended)
                var applied = delta
                if goal > 0 {
                    applied = min(delta, max(0, goal - currentProgress))
                    if applied <= 0 { continue }
                }

                try await db.collection("challenges").document(doc.documentID).updateData([
                    "progress": FieldValue.increment(Int64(applied)),
                    "participants.\(participantName)": FieldValue.increment(Int64(applied)),
                    "updatedAt": Timestamp(date: Date())
                ])
            }

            await fetchChallenges()
        } catch {
            print("❌ applySessionToJoinedChallenges failed: \(error)")
        }
    }
}

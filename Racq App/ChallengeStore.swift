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

    private var db: Firestore { FirebaseManager.shared.db }

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
                let participantNames = data["participantNames"] as? [String: String] ?? [:]

                let sponsor = data["sponsor"] as? String
                let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()

                let trackedRaw = data["trackedStat"] as? String ?? "forehands"
                let tracked = ChallengeTrackedStat(rawValue: trackedRaw) ?? .forehands
                let minPerSession = data["minPerSession"] as? Int

                return Challenge(
                    id: doc.documentID,
                    title: title,
                    goal: goal,
                    progress: progress,
                    participants: participants,
                    participantNames: participantNames,
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
                "participantNames": challenge.participantNames,
                "trackedStat": challenge.trackedStat.rawValue,
                "minPerSession": challenge.minPerSession as Any,
                "updatedAt": Timestamp(date: Date())
            ]

            if let sponsor = challenge.sponsor?.trimmingCharacters(in: .whitespacesAndNewlines),
               !sponsor.isEmpty {
                payload["sponsor"] = sponsor
            }

            try await db.collection("challenges").document(docID).setData(payload)
        } catch {
            print("❌ Error saving challenge: \(error)")
        }
    }

    // MARK: - Join (per user)
    func joinChallenge(challengeId: String, participantId: String, displayName: String) async {
        do {
            try await db.collection("challenges")
                .document(challengeId)
                .updateData([
                    "participants.\(participantId)": 0,
                    "participantNames.\(participantId)": displayName,
                    "updatedAt": Timestamp(date: Date())
                ])
            await fetchChallenges()
        } catch {
            print("❌ joinChallenge failed: \(error)")
        }
    }

    // MARK: - Auto apply a completed session to joined challenges
    func applySessionToJoinedChallenges(_ summary: SessionSummary, participantId: String, displayName: String) async {
        do {
            let snapshot = try await db.collection("challenges").getDocuments()

            for doc in snapshot.documents {
                let data = doc.data()

                let trackedRaw = data["trackedStat"] as? String ?? "forehands"
                guard let tracked = ChallengeTrackedStat(rawValue: trackedRaw) else { continue }

                let participants = data["participants"] as? [String: Int] ?? [:]
                guard participants[participantId] != nil else { continue } // joined only

                let goal = data["goal"] as? Int ?? 0
                let currentProgress = data["progress"] as? Int ?? 0
                if goal > 0, currentProgress >= goal { continue }

                let minPerSession = data["minPerSession"] as? Int ?? 0
                let delta = summary.value(for: tracked)

                if delta < minPerSession { continue }
                if delta <= 0 { continue }

                // cap at goal (optional)
                var applied = delta
                if goal > 0 {
                    applied = min(delta, max(0, goal - currentProgress))
                    if applied <= 0 { continue }
                }

                try await db.collection("challenges").document(doc.documentID).updateData([
                    "progress": FieldValue.increment(Int64(applied)),
                    "participants.\(participantId)": FieldValue.increment(Int64(applied)),
                    "participantNames.\(participantId)": displayName,
                    "updatedAt": Timestamp(date: Date())
                ])
            }

            await fetchChallenges()
        } catch {
            print("❌ applySessionToJoinedChallenges failed: \(error)")
        }
    }
}

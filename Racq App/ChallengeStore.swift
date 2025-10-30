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
final class ChallengeStore: ObservableObject {   // <-- must be a class (not struct)
    @Published var challenges: [Challenge] = []  // <-- at least one @Published property

    private var db: Firestore {
        FirebaseManager.shared.db
    }
    
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
                return Challenge(
                    id: doc.documentID,
                    title: title,
                    goal: goal,
                    progress: progress,
                    participants: participants
                )
            }
            print("✅ Loaded \(self.challenges.count) challenges")
        } catch {
            print("❌ Error fetching challenges: \(error.localizedDescription)")
        }
    }

    func addChallenge(_ challenge: Challenge) async {
        do {
            try await db.collection("challenges").document(challenge.id).setData([
                "title": challenge.title,
                "goal": challenge.goal,
                "progress": challenge.progress,
                "participants": challenge.participants
            ])
        } catch {
            print("Error saving challenge: \(error)")
        }
    }
}

//
//  ChallengeStore.swift
//  Racq App
//
//  Created by Deets on 10/29/25.
//

import Foundation
import Combine
import Firebase
import FirebaseFirestore

@MainActor
final class ChallengeStore: ObservableObject {   // <-- must be a class (not struct)
    @Published var challenges: [Challenge] = []  // <-- at least one @Published property

    private let db = FirebaseManager.shared.db

    func fetchChallenges() async {
        do {
            let snapshot = try await db.collection("challenges").getDocuments()
            let fetched: [Challenge] = snapshot.documents.compactMap { doc in
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
            self.challenges = fetched
        } catch {
            print("Error fetching challenges: \(error)")
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

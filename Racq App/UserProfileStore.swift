//
//  UserProfileStore.swift
//  Racq App
//
//  Created by Deets on 1/12/26.
//

import Foundation
import Combine
import Firebase
import FirebaseFirestore

@MainActor
final class UserProfileStore: ObservableObject {
    @Published var profile: UserProfile?

    private var db: Firestore { FirebaseManager.shared.db }

    func ensureUserExists(participantId: String, displayName: String) async {
        guard FirebaseApp.app() != nil else {
            print("⚠️ Firebase not configured yet")
            return
        }

        let cleanName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = cleanName.isEmpty ? "Anonymous" : cleanName

        let ref = db.collection("users").document(participantId)

        do {
            let snap = try await ref.getDocument()
            if snap.exists {
                // Keep displayName fresh
                try await ref.setData(["displayName": finalName], merge: true)
                return
            }

            // Create new user
            try await ref.setData([
                "displayName": finalName,
                "dateJoined": Timestamp(date: Date()),
                "stats": [
                    "sessionsCompleted": 0,
                    "totalHits": 0,
                    "totalForehands": 0,
                    "totalBackhands": 0,
                    "totalDurationSec": 0
                    //"fastestSwing": 0.00
                ]
            ], merge: true)

            print("✅ Created user doc for \(participantId)")
        } catch {
            print("❌ ensureUserExists error: \(error)")
        }
    }

    func fetchProfile(participantId: String) async {
        guard FirebaseApp.app() != nil else {
            print("⚠️ Firebase not configured yet")
            return
        }

        do {
            let snap = try await db.collection("users").document(participantId).getDocument()
            guard let data = snap.data() else {
                print("⚠️ No user doc found")
                return
            }

            let displayName = data["displayName"] as? String ?? "Anonymous"
            let dateJoined = (data["dateJoined"] as? Timestamp)?.dateValue() ?? Date()

            let stats = data["stats"] as? [String: Any] ?? [:]
            let sessionsCompleted = stats["sessionsCompleted"] as? Int ?? 0
            let totalHits = stats["totalHits"] as? Int ?? 0
            let totalForehands = stats["totalForehands"] as? Int ?? 0
            let totalBackhands = stats["totalBackhands"] as? Int ?? 0
            let totalDurationSec = stats["totalDurationSec"] as? Int ?? 0
            //let fastestSwing = stats["fastestSwing"] as? Double ?? 0.00

            self.profile = UserProfile(
                displayName: displayName,
                dateJoined: dateJoined,
                sessionsCompleted: sessionsCompleted,
                totalHits: totalHits,
                totalForehands: totalForehands,
                totalBackhands: totalBackhands,
                totalDurationSec: totalDurationSec
                //fastestSwing: fastestSwing
            )
        } catch {
            print("❌ fetchProfile error: \(error)")
        }
    }
}

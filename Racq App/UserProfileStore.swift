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
    @Published var stats: UserStats = .zero

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
                    "totalDurationSec": 0,
                    "fastestSwing": 0.0
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

            self.profile = UserProfile(displayName: displayName, dateJoined: dateJoined)

            // pull stats
            self.stats = UserStats(
                sessionsCompleted: readIntStat(data, key: "sessionsCompleted"),
                totalHits: readIntStat(data, key: "totalHits"),
                totalForehands: readIntStat(data, key: "totalForehands"),
                totalBackhands: readIntStat(data, key: "totalBackhands"),
                totalDurationSec: readIntStat(data, key: "totalDurationSec"),
                fastestSwing: readDoubleStat(data, key: "fastestSwing")
            )

            print("👤 Loaded stats: sessions=\(stats.sessionsCompleted) hits=\(stats.totalHits)")
        } catch {
            print("❌ fetchProfile error: \(error)")
        }
    }

    // MARK: - Helpers

    private func readIntStat(_ data: [String: Any], key: String) -> Int {
        // Normal case: nested stats map
        if let statsMap = data["stats"] as? [String: Any] {
            if let v = statsMap[key] as? Int { return v }
            if let v = statsMap[key] as? Int64 { return Int(v) }
            if let v = statsMap[key] as? Double { return Int(v) }
        }
        // Fallback: literal dotted key exists in doc (rare but matches your symptom)
        if let v = data["stats.\(key)"] as? Int { return v }
        if let v = data["stats.\(key)"] as? Int64 { return Int(v) }
        if let v = data["stats.\(key)"] as? Double { return Int(v) }

        return 0
    }

    private func readDoubleStat(_ data: [String: Any], key: String) -> Double {
        if let statsMap = data["stats"] as? [String: Any] {
            if let v = statsMap[key] as? Double { return v }
            if let v = statsMap[key] as? Int { return Double(v) }
            if let v = statsMap[key] as? Int64 { return Double(v) }
        }
        if let v = data["stats.\(key)"] as? Double { return v }
        if let v = data["stats.\(key)"] as? Int { return Double(v) }
        if let v = data["stats.\(key)"] as? Int64 { return Double(v) }

        return 0.0
    }
}


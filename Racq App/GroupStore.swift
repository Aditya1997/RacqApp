//
//  GroupStore.swift
//  Racq App
//
//  Created by Deets on 1/9/26.
//

//
//  GroupStore.swift
//  Racq App
//
//  Created by Deets on 1/9/26.
//

import Foundation
import Firebase
import FirebaseFirestore
import Combine

@MainActor
final class GroupStore: ObservableObject {
    static let shared = GroupStore()

    @Published var groups: [PlayerGroup] = []
    @Published var joinedGroupIds: [String] = []

    private var db: Firestore { FirebaseManager.shared.db }

    private init() {}

    // MARK: - Join Group (NEW)
    /// Adds this device/user to the group's membership in Firestore
    /// and stores the groupId locally so sessions update this group's leaderboards.
    func joinGroup(groupId: String, displayName: String) async {
        guard FirebaseApp.app() != nil else {
            print("⚠️ Firebase not configured yet")
            return
        }

        let participantId = UserIdentity.participantId()
        let cleanName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = cleanName.isEmpty ? "Anonymous" : cleanName

        do {
            let groupRef = db.collection("groups").document(groupId)

            // Upsert membership + name
            try await groupRef.setData([
                "members.\(participantId)": true,
                "memberNames.\(participantId)": finalName,
                "updatedAt": Timestamp(date: Date())
            ], merge: true)

            // Store locally for future session updates
            GroupMembership.addGroupId(groupId)

            print("✅ Joined group \(groupId) as \(finalName)")
        } catch {
            print("❌ Failed to join group \(groupId): \(error)")
        }
    }

    // MARK: - Leave Group (OPTIONAL)
    // Removes groupId locally and removes membership fields in Firestore.
    func leaveGroup(groupId: String) async {
        guard FirebaseApp.app() != nil else {
            print("⚠️ Firebase not configured yet")
            return
        }
        let participantId = UserIdentity.participantId()
        do {
            let groupRef = db.collection("groups").document(groupId)

            try await groupRef.updateData([
                // Delete nested shape if it exists
                FieldPath(["members", participantId]): FieldValue.delete(),
                FieldPath(["memberNames", participantId]): FieldValue.delete(),
                // Delete literal dotted-field shape (what Firebase uses)
                FieldPath(["members.\(participantId)"]): FieldValue.delete(),
                FieldPath(["memberNames.\(participantId)"]): FieldValue.delete(),
                "updatedAt": Timestamp(date: Date())
            ])
            GroupMembership.removeGroupId(groupId) // :contentReference[oaicite:2]{index=2}
            print("✅ Left group \(groupId)")
        } catch {
            print("❌ Failed to leave group \(groupId): \(error)")
        }
    }

    // MARK: - Joined helper (OPTIONAL)
    func isJoined(groupId: String) -> Bool {
        GroupMembership.getGroupIds().contains(groupId)
    }
    
    // MARK: - Fetch groups from Firebase Firestore
    func fetchGroups() async {
        guard FirebaseApp.app() != nil else {
            print("⚠️ Firebase not configured yet")
            return
        }

        do {
            let snapshot = try await db.collection("groups").getDocuments()
            print("📦 Firestore groups docs found: \(snapshot.documents.count)")

            let fetched: [PlayerGroup] = snapshot.documents.compactMap { doc -> PlayerGroup? in
                let data = doc.data()
                print("🧾 group doc id=\(doc.documentID) data=\(data)")

                guard
                    let name = data["name"] as? String,
                    let icon = data["icon"] as? String
                else {
                    print("⚠️ Skipping group \(doc.documentID): missing name or icon")
                    return nil
                }

                // Description and updatedAt is optional
                let description = (data["description"] as? String)

                let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()

                let location = data["location"] as? String
                let backgroundImageURL = data["backgroundImageURL"] as? String
                let memberCount = GroupMemberCount.count(from: data)
                
                return PlayerGroup(
                id: doc.documentID,
                name: name,
                description: description,
                icon: icon,
                updatedAt: updatedAt,
                location: location,
                backgroundImageURL: backgroundImageURL,
                memberCount: memberCount
                )
            }
            self.groups = fetched.sorted(by: { $0.updatedAt > $1.updatedAt })
            print("✅ Loaded \(self.groups.count) groups into GroupStore")
        } catch {
            print("❌ Error fetching groups: \(error)")
        }
    }

    // MARK: - Update group leaderboards from a completed session (YOUR EXISTING CODE)
    /// Call this once per completed session.
    ///
    /// - Parameters:
    ///   - summary: The completed session summary.
    ///   - participantId: Stable per-device ID.
    ///   - displayName: User's name (stored on phone).
    ///   - groupIds: Which groups this user belongs to (for MVP you can pass a hardcoded list).
    func applySessionToGroupLeaderboards(
        summary: SessionSummary,
        participantId: String,
        displayName: String,
        groupIds: [String]
    ) async {
        guard FirebaseApp.app() != nil else {
            print("⚠️ Firebase not configured yet")
            return
        }

        // Deltas we want to increment in group leaderboards
        let deltas: [String: Int] = [
            "forehands_total": summary.forehandCount,
            "backhands_total": summary.backhandCount,
            "shots_total": summary.shotCount,
            "durationSec_total": summary.durationSec,
            "sessions_total": 1
        ]

        for groupId in groupIds {
            let groupRef = db.collection("groups").document(groupId)

            // 1) Ensure membership + name stored on group doc (idempotent)
            do {
                try await groupRef.setData([
                    "members.\(participantId)": true,
                    "memberNames.\(participantId)": displayName,
                    "updatedAt": Timestamp(date: Date())
                ], merge: true)
            } catch {
                print("❌ Failed to upsert group membership for \(groupId): \(error)")
                continue
            }

            // 2) For each metric, increment that group's leaderboard doc
            for (metricKey, delta) in deltas {
                // Don't write zero increments (keeps docs smaller)
                if delta == 0 { continue }

                let lbRef = groupRef.collection("leaderboards").document(metricKey)
                do {
                    try await lbRef.setData([
                        "scores.\(participantId)": FieldValue.increment(Int64(delta)),
                        "updatedAt": Timestamp(date: Date()),
                        "metricKey": metricKey
                    ], merge: true)
                } catch {
                    print("❌ Failed to update leaderboard \(metricKey) for group \(groupId): \(error)")
                }
            }
        }
    }
}

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

    private var db: Firestore { FirebaseManager.shared.db }

    private init() {}

    // MARK: - Create Group (NEW)
    //
    // ✅ Works now WITHOUT Firebase Storage:
    // - profileImageURL/backgroundImageURL remain nil
    //
    // 🔜 When you enable Firebase Storage:
    // - uncomment the StorageService code below
    // - pass in profile/cover image data from CreateNewGroupView
    //
    func createGroup(
        name: String,
        location: String?,
        tagline: String?,
        description: String?,
        profileImageData: Data?,         // optional; used later for Storage
        backgroundImageData: Data?       // optional; used later for Storage
    ) async throws -> String {
        guard FirebaseApp.app() != nil else {
            throw NSError(domain: "FirebaseNotConfigured", code: 1)
        }

        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedName.isEmpty else {
            throw NSError(domain: "InvalidGroupName", code: 2)
        }

        let doc = db.collection("groups").document()
        let now = Date()

        // Keep icon for older UI that expects it
        let defaultIcon = "person.3.fill"

        var data: [String: Any] = [
            "name": trimmedName,
            "icon": defaultIcon,
            "tagline": tagline ?? "",
            "description": description ?? "",
            "updatedAt": Timestamp(date: now)
        ]

        if let location, !location.isEmpty {
            data["location"] = location
        }

        data["tagline"] = tagline?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        data["description"] = description?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        // ---------------------------
        // 🔜 Firebase Storage integration (COMMENTED OUT)
        // ---------------------------
        // If you want to store images later, do:
        //
        // var uploadedProfileURL: String?
        // var uploadedBackgroundURL: String?
        //
        // if let profileImageData {
        //     let urls = try await StorageService.shared.uploadJPEGs(
        //         datas: [profileImageData],
        //         pathPrefix: "groups/\(doc.documentID)/profile"
        //     )
        //     uploadedProfileURL = urls.first
        // }
        //
        // if let backgroundImageData {
        //     let urls = try await StorageService.shared.uploadJPEGs(
        //         datas: [backgroundImageData],
        //         pathPrefix: "groups/\(doc.documentID)/background"
        //     )
        //     uploadedBackgroundURL = urls.first
        // }
        //
        // if let uploadedProfileURL { data["profileImageURL"] = uploadedProfileURL }
        // if let uploadedBackgroundURL { data["backgroundImageURL"] = uploadedBackgroundURL }
        // ---------------------------

        try await doc.setData(data)
        return doc.documentID
    }

    // MARK: - Fetch Groups
    func fetchGroups() async {
        guard FirebaseApp.app() != nil else { return }

        do {
            let snap = try await db.collection("groups").getDocuments()

            let fetched: [PlayerGroup] = snap.documents.compactMap { doc -> PlayerGroup? in
                let data = doc.data()

                // REQUIRED
                guard let name = data["name"] as? String else {
                    return nil   // skip malformed group docs
                }
                let tagline = (data["tagline"] as? String) ?? ""
                let description = (data["description"] as? String) ?? ""
                
                // OPTIONALS
                let location = data["location"] as? String
                let profileImageURL = data["profileImageURL"] as? String
                let backgroundImageURL = data["backgroundImageURL"] as? String

                let icon = (data["icon"] as? String) ?? "person.3.fill"
                let updatedAt = (data["updatedAt"] as? Timestamp)?.dateValue() ?? Date()
                let memberCount = GroupMemberCount.count(from: data)

                return PlayerGroup(
                    id: doc.documentID,
                    name: name,                 // ✅ now String
                    location: location,
                    tagline: tagline,
                    description: description,
                    profileImageURL: profileImageURL,
                    backgroundImageURL: backgroundImageURL,
                    icon: icon,
                    updatedAt: updatedAt,
                    memberCount: memberCount
                )
            }

            self.groups = fetched.sorted(by: { $0.updatedAt > $1.updatedAt })
        } catch {
            print("❌ fetchGroups error:", error)
        }
    }

    // MARK: - Join / Leave (unchanged)
    func joinGroup(groupId: String, displayName: String) async {
        guard FirebaseApp.app() != nil else { return }

        let participantId = UserIdentity.participantId()
        let cleanName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let finalName = cleanName.isEmpty ? "Anonymous" : cleanName

        do {
            let groupRef = db.collection("groups").document(groupId)
            try await groupRef.setData([
                "members.\(participantId)": true,
                "memberNames.\(participantId)": finalName,
                "updatedAt": Timestamp(date: Date())
            ], merge: true)

            GroupMembership.addGroupId(groupId)
        } catch {
            print("❌ joinGroup error:", error)
        }
    }

    func leaveGroup(groupId: String) async {
        guard FirebaseApp.app() != nil else { return }

        let participantId = UserIdentity.participantId()
        do {
            let groupRef = db.collection("groups").document(groupId)
            try await groupRef.updateData([
                FieldPath(["members", participantId]): FieldValue.delete(),
                FieldPath(["memberNames", participantId]): FieldValue.delete(),
                "updatedAt": Timestamp(date: Date())
            ])

            GroupMembership.removeGroupId(groupId)
        } catch {
            print("❌ leaveGroup error:", error)
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

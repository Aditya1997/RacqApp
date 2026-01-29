//
//  GroupPostStore.swift
//  Racq App
//
//  Created by Deets on 1/28/26.
//

import Foundation
import Firebase
import FirebaseFirestore
import Combine

@MainActor
final class GroupPostStore: ObservableObject {
    @Published var posts: [GroupPost] = []

    private var db: Firestore { FirebaseManager.shared.db }
    private var listener: ListenerRegistration?

    func startListening(groupId: String) async {
        guard FirebaseApp.app() != nil else { return }

        stopListening()

        listener = db.collection("groups")
            .document(groupId)
            .collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                if let err {
                    print("❌ group posts listen error:", err)
                    return
                }
                let docs = snap?.documents ?? []
                self.posts = docs.compactMap { doc in
                    let d = doc.data()

                    let authorId = d["authorId"] as? String ?? ""
                    let authorName = d["authorName"] as? String ?? "Anonymous"
                    let caption = d["caption"] as? String ?? ""
                    let createdAt = (d["createdAt"] as? Timestamp)?.dateValue() ?? Date()

                    let typeRaw = d["type"] as? String ?? "text"
                    let type = GroupPostType(rawValue: typeRaw) ?? .text

                    let locationText = d["locationText"] as? String
                    let tagged = d["taggedUsernames"] as? [String] ?? []
                    let imageURLs = d["imageURLs"] as? [String] ?? []

                    let shotCount = d["shotCount"] as? Int
                    let durationSec = d["durationSec"] as? Int
                    let avgHR = d["avgHeartRate"] as? Int
                    let fhMax = d["forehandMax"] as? Int
                    let bhMax = d["backhandMax"] as? Int

                    return GroupPost(
                        id: doc.documentID,
                        authorId: authorId,
                        authorName: authorName,
                        caption: caption,
                        createdAt: createdAt,
                        type: type,
                        locationText: locationText,
                        taggedUsernames: tagged,
                        imageURLs: imageURLs,
                        shotCount: shotCount,
                        durationSec: durationSec,
                        avgHeartRate: avgHR,
                        forehandMax: fhMax,
                        backhandMax: bhMax
                    )
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
}

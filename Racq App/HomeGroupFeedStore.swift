//
//  HomeGroupFeedStore.swift
//  Racq App
//
//  Created by Deets on 1/30/26.
//

import Foundation
import Combine
import Firebase
import FirebaseFirestore

struct GroupFeedItem: Identifiable {
    let id: String               // unique per (groupId + postId)
    let groupId: String
    let groupName: String
    let post: AppPost
}

@MainActor
final class HomeGroupFeedStore: ObservableObject {
    @Published var feed: [GroupFeedItem] = []

    private var db: Firestore { FirebaseManager.shared.db }
    private var listeners: [String: ListenerRegistration] = [:] // groupId -> listener
    private var groupNameById: [String: String] = [:]
    private var postsByCompositeId: [String: GroupFeedItem] = [:]

    func start() async {
        guard FirebaseApp.app() != nil else { return }
        stop()

        // Ensure GroupStore has the groups loaded (names)
        await GroupStore.shared.fetchGroups()
        groupNameById = Dictionary(uniqueKeysWithValues: GroupStore.shared.groups.map { ($0.id, $0.name) })

        let joinedIds = GroupMembership.getGroupIds()
        for gid in joinedIds {
            startListening(groupId: gid)
        }
    }

    func stop() {
        for (_, l) in listeners { l.remove() }
        listeners.removeAll()
        postsByCompositeId.removeAll()
        feed = []
    }

    private func startListening(groupId: String) {
        let groupName = groupNameById[groupId] ?? groupId

        let listener = db.collection("groups")
            .document(groupId)
            .collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: 25)
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                if let err {
                    print("❌ home group feed listen error groupId=\(groupId):", err)
                    return
                }
                let docs = snap?.documents ?? []
                for d in docs {
                    guard let post = PostParsing.parsePost(docId: d.documentID, data: d.data()) else { continue }
                    let composite = "\(groupId)_\(post.id)"
                    self.postsByCompositeId[composite] = GroupFeedItem(
                        id: composite,
                        groupId: groupId,
                        groupName: groupName,
                        post: post
                    )
                }

                // Sort newest first across all groups
                self.feed = self.postsByCompositeId.values
                    .sorted(by: { $0.post.createdAt > $1.post.createdAt })
            }

        listeners[groupId] = listener
    }
}

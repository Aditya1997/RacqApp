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

struct HomeFeedItem: Identifiable {
    let id: String                // unique: "\(groupId)_\(postId)"
    let post: AppPost
    let ref: PostContextRef       // ALWAYS .group for Home feed
    let groupId: String
    let postId: String
    let groupName: String
}

@MainActor
final class HomeGroupFeedStore: ObservableObject {
    @Published var feed: [HomeFeedItem] = []

    private var db: Firestore { FirebaseManager.shared.db }
    private var listeners: [String: ListenerRegistration] = [:] // groupId -> listener
    private var groupNameById: [String: String] = [:]
    private var postsByCompositeId: [String: HomeFeedItem] = [:]

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
                var updated: [String: HomeFeedItem] = [:]

                for d in docs {
                    guard let post = PostParsing.parsePost(docId: d.documentID, data: d.data()) else { continue }

                    let postId = post.id
                    let composite = "\(groupId)_\(postId)"

                    let item = HomeFeedItem(
                        id: composite,
                        post: post,
                        ref: .group(groupId: groupId, postId: postId),
                        groupId: groupId,
                        postId: postId,
                        groupName: groupName
                    )

                    updated[composite] = item
                }

                // Because we are @MainActor, ensure we update state on the main actor.
                Task { @MainActor in
                    // Remove old items for this group from the global dictionary
                    // then insert the latest snapshot for this group.
                    for (key, value) in self.postsByCompositeId where value.groupId == groupId {
                        self.postsByCompositeId.removeValue(forKey: key)
                    }
                    for (k, v) in updated {
                        self.postsByCompositeId[k] = v
                    }

                    self.feed = self.postsByCompositeId.values
                        .sorted(by: { $0.post.createdAt > $1.post.createdAt })
                }
            }

        listeners[groupId] = listener
    }
}

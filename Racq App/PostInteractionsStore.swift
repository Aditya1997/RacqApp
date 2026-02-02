//
//  PostInteractionsStore.swift
//  Racq App
//
//  Created by Deets on 1/30/26.
//

import Foundation
import Combine
import Firebase
import FirebaseFirestore

final class PostInteractionsStore: ObservableObject {
    @Published var comments: [PostComment] = []
    @Published var reactionCounts: [String: Int] = [:] // emoji -> count
    @Published var myReactions: Set<String> = []

    private var commentsListener: ListenerRegistration?
    private var reactionsListener: ListenerRegistration?

    private var db: Firestore { FirebaseManager.shared.db }

    func startListening(ref: PostContextRef, myUserId: String) {
        stopListening()

        let postRef = db.document(ref.postPath)

        commentsListener = postRef.collection("comments")
            .order(by: "createdAt", descending: false)
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                if let err { print("❌ comments listen:", err); return }
                let docs = snap?.documents ?? []

                let parsed: [PostComment] = docs.compactMap { doc in
                    let d = doc.data()
                    guard
                        let authorId = d["authorId"] as? String,
                        let authorName = d["authorName"] as? String,
                        let text = d["text"] as? String,
                        let createdAt = d["createdAt"] as? Timestamp
                    else { return nil }

                    return PostComment(
                        id: doc.documentID,
                        authorId: authorId,
                        authorName: authorName,
                        text: text,
                        createdAt: createdAt
                    )
                }

                DispatchQueue.main.async {
                    self.comments = parsed
                }
            }

        reactionsListener = postRef.collection("reactions")
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                if let err { print("❌ reactions listen:", err); return }
                let docs = snap?.documents ?? []

                var counts: [String: Int] = [:]
                var mine: Set<String> = []

                for doc in docs {
                    let d = doc.data()
                    let emojis = (d["emojis"] as? [String]) ?? []
                    for e in emojis { counts[e, default: 0] += 1 }
                    if doc.documentID == myUserId {
                        mine = Set(emojis)
                    }
                }

                DispatchQueue.main.async {
                    self.reactionCounts = counts
                    self.myReactions = mine
                }
            }
    }

    func stopListening() {
        commentsListener?.remove()
        commentsListener = nil
        reactionsListener?.remove()
        reactionsListener = nil
    }
}

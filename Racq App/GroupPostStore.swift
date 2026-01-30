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
    @Published var posts: [AppPost] = []

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
                    PostParsing.parsePost(docId: doc.documentID, data: doc.data())
                }
            }
    }

    func stopListening() {
        listener?.remove()
        listener = nil
    }
}

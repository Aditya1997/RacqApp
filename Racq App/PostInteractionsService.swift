//
//  PostInteractionsService.swift
//  Racq App
//
//  Created by Deets on 1/30/26.
//


import Foundation
import Firebase
import FirebaseFirestore

final class PostInteractionsService {
    static let shared = PostInteractionsService()
    private init() {}

    private var db: Firestore { FirebaseManager.shared.db }

    private func postDocRef(_ ref: PostContextRef) -> DocumentReference {
        return db.document(ref.postPath)
    }

    // MARK: - Comments

    func addComment(to ref: PostContextRef, authorId: String, authorName: String, text: String) async throws {
        guard FirebaseApp.app() != nil else { return }
        let clean = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        let commentRef = postDocRef(ref).collection("comments").document()
        try await commentRef.setData([
            "authorId": authorId,
            "authorName": authorName,
            "text": clean,
            "createdAt": Timestamp(date: Date())
        ], merge: true)
    }

    // MARK: - Reactions

    /// Toggle a reaction emoji for a user on a post.
    /// Stores per-user reaction doc: reactions/{authorId} with `emojis: [String]`.
    func toggleReaction(on ref: PostContextRef, authorId: String, emoji: String) async throws {
        guard FirebaseApp.app() != nil else { return }

        let reactionRef = postDocRef(ref).collection("reactions").document(authorId)

        try await db.runTransaction { txn, _ in
            let snap: DocumentSnapshot
            do {
                snap = try txn.getDocument(reactionRef)
            } catch {
                return nil
            }

            var emojis = (snap.data()?["emojis"] as? [String]) ?? []
            if let idx = emojis.firstIndex(of: emoji) {
                emojis.remove(at: idx)
            } else {
                emojis.append(emoji)
            }

            txn.setData([
                "emojis": emojis,
                "updatedAt": Timestamp(date: Date())
            ], forDocument: reactionRef, merge: true)

            return nil
        }
    }
}

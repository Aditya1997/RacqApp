//
//  PostService.swift
//  Racq App
//
//  Created by Deets on 1/30/26.
//  Integrates post storage into Firestore

import Foundation
import Firebase
import FirebaseFirestore

final class PostService {
    static let shared = PostService()
    private init() {}

    private var db: Firestore { FirebaseManager.shared.db }

    /// Creates a simple text post and writes it to the user's profile.
    /// If `shareToGroupIds` is non-empty, it also copies the post into each group's `/posts` subcollection.
    func createTextPost(
        participantId: String,
        displayName: String,
        caption: String,
        shareToGroupIds: [String]
    ) async throws {
        guard FirebaseApp.app() != nil else { return }

        let cleanCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleanCaption.isEmpty else { return }

        let postId = db.collection("users")
            .document(participantId)
            .collection("posts")
            .document().documentID
        let createdAt = Timestamp(date: Date())

        let payload: [String: Any] = [
            "authorId": participantId,
            "authorName": displayName,
            "createdAt": createdAt,

            "type": "text",
            "caption": cleanCaption,
            "locationText": NSNull(),
            "taggedUsernames": [],
            "imageURLs": []
        ]

        // 1) Save to profile
        try await db.collection("users")
            .document(participantId)
            .collection("posts")
            .document(postId)
            .setData(payload, merge: true)

        // 2) Copy to groups
        for gid in shareToGroupIds {
            try await db.collection("groups")
                .document(gid)
                .collection("posts")
                .document(postId)
                .setData(payload, merge: true)
        }
    }

    func createSessionPost(
        participantId: String,
        displayName: String,
        session: UserSession,
        caption: String,
        locationText: String?,
        taggedUsernames: [String],
        imageURLs: [String],
        shareToGroupIds: [String]
    ) async throws {
        guard FirebaseApp.app() != nil else { return }

        let postId = db.collection("users").document(participantId).collection("posts").document().documentID
        let createdAt = Timestamp(date: Date())

        let payload: [String: Any] = [
            "authorId": participantId,
            "authorName": displayName,
            "createdAt": createdAt,

            "type": "session",
            "caption": caption,
            "locationText": locationText as Any,
            "taggedUsernames": taggedUsernames,
            "imageURLs": imageURLs,

            "sessionId": session.id,
            "shotCount": session.shotCount,
            "forehandCount": session.forehandCount,
            "backhandCount": session.backhandCount,
            "durationSec": session.durationSec,
            "heartRate": session.heartRate,
            "fastestSwing": session.fastestSwing,
            "fhAvgMph": session.fhAvgMph,
            "fhMaxMph": session.fhMaxMph,
            "bhAvgMph": session.bhAvgMph,
            "bhMaxMph": session.bhMaxMph
        ]

        // 1) Save to profile
        try await db.collection("users")
            .document(participantId)
            .collection("posts")
            .document(postId)
            .setData(payload, merge: true)

        // 2) Copy to groups
        for gid in shareToGroupIds {
            try await db.collection("groups")
                .document(gid)
                .collection("posts")
                .document(postId)
                .setData(payload, merge: true)
        }
    }
}

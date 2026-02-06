//
//  UserPostStore.swift
//  Racq App
//
//  Created by Deets on 1/30/26.
//


import Foundation
import Combine
import Firebase
import FirebaseFirestore

@MainActor
final class UserPostStore: ObservableObject {
    @Published var posts: [AppPost] = []

    private var db: Firestore { FirebaseManager.shared.db }
    private var listener: ListenerRegistration?

    func startListening(participantId: String) async {
        guard FirebaseApp.app() != nil else { return }
        stopListening()

        listener = db.collection("users")
            .document(participantId)
            .collection("posts")
            .order(by: "createdAt", descending: true)
            .limit(to: 50)
            .addSnapshotListener { [weak self] snap, err in
                guard let self else { return }
                if let err {
                    print("❌ user posts listen error:", err)
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

    static func parsePost(docId: String, data: [String: Any]) -> AppPost? {
        let authorId = data["authorId"] as? String ?? ""
        let authorName = data["authorName"] as? String ?? "Anonymous"
        let createdAt = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        let type = PostType(rawValue: data["type"] as? String ?? "text") ?? .text

        let caption = data["caption"] as? String ?? ""
        let locationText = data["locationText"] as? String
        let tagged = data["taggedUsernames"] as? [String] ?? []
        let imageURLs = data["imageURLs"] as? [String] ?? []
        let commentCount = data["commentCount"] as? Int ?? 0
        let lastCommentAt = (data["lastCommentAt"] as? Timestamp)?.dateValue()
        
        let sessionId = data["sessionId"] as? String
        let shotCount = data["shotCount"] as? Int
        let forehandCount = data["forehandCount"] as? Int
        let backhandCount = data["backhandCount"] as? Int
        let durationSec = data["durationSec"] as? Int
        let heartRate = data["heartRate"] as? Double
        let fastestSwing = data["fastestSwing"] as? Double
        let fhAvgMph = data["fhAvgMph"] as? Double
        let fhMaxMph = data["fhMaxMph"] as? Double
        let bhAvgMph = data["bhAvgMph"] as? Double
        let bhMaxMph = data["bhMaxMph"] as? Double

        return AppPost(
            id: docId,
            authorId: authorId,
            authorName: authorName,
            createdAt: createdAt,
            type: type,
            caption: caption,
            locationText: locationText,
            taggedUsernames: tagged,
            imageURLs: imageURLs,
            commentCount: commentCount,
            lastCommentAt: lastCommentAt,
            sessionId: sessionId,
            shotCount: shotCount,
            forehandCount: forehandCount,
            backhandCount: backhandCount,
            durationSec: durationSec,
            heartRate: heartRate,
            fastestSwing: fastestSwing,
            fhAvgMph: fhAvgMph,
            fhMaxMph: fhMaxMph,
            bhAvgMph: bhAvgMph,
            bhMaxMph: bhMaxMph
        )
    }
}

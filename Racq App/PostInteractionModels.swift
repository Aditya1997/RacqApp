//
//  PostInteractionModels.swift
//  Racq App
//
//  Created by Deets on 1/30/26.
//

import Foundation
import FirebaseFirestore

struct PostComment: Identifiable, Codable {
    var id: String
    var authorId: String
    var authorName: String
    var text: String
    var createdAt: Timestamp
}

struct PostReactions: Identifiable, Codable {
    var id: String            // authorId (doc id)
    var emojis: [String]
    var updatedAt: Timestamp
}

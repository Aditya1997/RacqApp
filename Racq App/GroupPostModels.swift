//
//  GroupPostModels.swift
//  Racq App
//
//  Created by Deets on 1/28/26.
//

import Foundation
import FirebaseFirestore

enum GroupPostType: String {
    case text
    case session
}

struct GroupPost: Identifiable {
    let id: String
    let authorId: String
    let authorName: String
    let caption: String
    let createdAt: Date

    // optional session/share fields (for later steps)
    let type: GroupPostType
    let locationText: String?
    let taggedUsernames: [String]
    let imageURLs: [String]

    // Optional session summary fields
    let shotCount: Int?
    let durationSec: Int?
    let avgHeartRate: Int?
    let forehandMax: Int?
    let backhandMax: Int?
}

//
//  PostType.swift
//  Racq App
//
//  Created by Deets on 1/30/26.
//  Determines post type (text post, session post, etc.)


import Foundation
import FirebaseFirestore

enum PostType: String {
    case text
    case session
}

struct AppPost: Identifiable {
    let id: String
    let authorId: String
    let authorName: String
    let createdAt: Date

    let type: PostType
    let caption: String
    let locationText: String?
    let taggedUsernames: [String]
    let imageURLs: [String]

    // comments
    let commentCount: Int
    let lastCommentAt: Date?
    
    // Session payload (optional)
    let sessionId: String?
    let shotCount: Int?
    let forehandCount: Int?
    let backhandCount: Int?
    let durationSec: Int?
    let heartRate: Double?
    let fastestSwing: Double?
    let fhAvgMph: Double?
    let fhMaxMph: Double?
    let bhAvgMph: Double?
    let bhMaxMph: Double?

}

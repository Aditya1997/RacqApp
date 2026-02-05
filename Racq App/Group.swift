//
//  PlayerGroup.swift
//  Racq App
//
//  Created by Deets on 1/9/26.
//

import Foundation

struct PlayerGroup: Identifiable {
    let id: String
    let name: String

    // Text
    let location: String?
    let tagline: String
    let description: String

    // Images (Firebase Storage URLs later)
    let profileImageURL: String?
    let backgroundImageURL: String?

    // Legacy fallback (still used by Community list rows)
    let icon: String

    // Meta
    let updatedAt: Date
    let memberCount: Int
}

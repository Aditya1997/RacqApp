//
//  CommunityChallenge.swift
//  Racq App
//
//  Created by Deets on 10/29/25.
//

import Foundation

struct Challenge: Identifiable, Codable {
    var id: String?
    var title: String
    var goal: Int
    var progress: Int
    var participants: [String: Int]
    var sponsor: String?
    var updatedAt: Date
}

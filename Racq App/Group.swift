//
//  PlayerGroup.swift
//  Racq App
//
//  Created by Deets on 1/9/26.
//

import Foundation

struct PlayerGroup: Identifiable {
    let id: String          // Firestore doc id
    let name: String
    let description: String?
    let icon: String
    let updatedAt: Date
}

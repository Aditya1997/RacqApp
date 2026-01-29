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
    let description: String?
    let icon: String
    let updatedAt: Date
    
    // Added 1/28/26
    let location: String?
    let backgroundImageURL: String?
    let memberCount: Int
}

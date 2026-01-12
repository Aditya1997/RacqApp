//
//  UserSession.swift
//  Racq App
//
//  Created by Deets on 1/12/26.
//

import Foundation
import FirebaseFirestore

struct UserSession: Identifiable {
    let id: String
    let timestamp: Date
    let shotCount: Int
    let forehandCount: Int
    let backhandCount: Int
    let durationSec: Int
    let heartRate: Double
    let csvFileName: String?
}

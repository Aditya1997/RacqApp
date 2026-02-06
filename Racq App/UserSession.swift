//
//  UserSession.swift
//  Racq App
//
//  Created by Deets on 1/12/26.
//  Source of truth for all session data

import Foundation
import FirebaseFirestore

struct UserSession: Identifiable {
    let id: String
    let timestamp: Date
    let shotCount: Int
    let forehandCount: Int
    let backhandCount: Int
    let durationSec: Int
    let fastestSwing: Double
    let fhMaxMph: Double
    let fhAvgMph: Double
    let bhMaxMph: Double
    let bhAvgMph: Double
    let heartRate: Double
    let csvFileName: String?
}

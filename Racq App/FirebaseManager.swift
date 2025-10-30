//
//  FirebaseManager.swift
//  Racq App
//
//  Created by Deets on 10/29/25.
//  Added on 10/29 to support backend

import Foundation
import Firebase
import FirebaseFirestore

final class FirebaseManager {
    static let shared = FirebaseManager()
    let db: Firestore

    private init() {
        // Initialize Firebase once at app launch
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
        db = Firestore.firestore()
    }
}

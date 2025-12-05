//
//  Racq_AppApp.swift
//  Racq App
//
//  Created by Brian on 10/20/25.
//  10/30/2025 - Added Firebase functionality, also added googleservice-info.plsit

import SwiftUI
import CoreData
import FirebaseCore
import FirebaseAuth

@main
struct Racq_AppApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        // ✅ Force the WCSession manager to initialize immediately
        _ = PhoneWCManager.shared
        FirebaseApp.configure()
        ensureFirebaseAuth()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .preferredColorScheme(.dark)   // Dark Mode
        }
    }
    
    func ensureFirebaseAuth() {
        if Auth.auth().currentUser == nil {
            Auth.auth().signInAnonymously { result, error in
                if let error = error {
                    print("❌ Firebase Auth error: \(error.localizedDescription)")
                } else {
                    print("✅ Signed in anonymously with UID: \(result?.user.uid ?? "")")
                }
            }
        }
    }
}



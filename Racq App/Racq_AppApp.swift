//
//  Racq_AppApp.swift
//  Racq App
//
//  Created by Brian on 10/20/25.
//  10/30/2025 - Added Firebase functionality, also added googleservice-info.plsit

import SwiftUI
import CoreData
import FirebaseCore

@main
struct Racq_AppApp: App {
    let persistenceController = PersistenceController.shared

    init() {
        // ✅ Force the WCSession manager to initialize immediately
        _ = PhoneWCManager.shared
        FirebaseApp.configure()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}



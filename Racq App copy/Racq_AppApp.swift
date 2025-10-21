//
//  Racq_AppApp.swift
//  Racq App
//
//  Created by Brian on 10/20/25.
//

import SwiftUI
import CoreData

@main
struct Racq_AppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}

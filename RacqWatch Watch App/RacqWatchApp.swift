//
//  RacqWatchApp.swift
//  RacqWatch Watch App
//
//  Created by Brian on 10/20/25.
//

import SwiftUI

@main
struct RacqWatchApp: App {
    init() {
            // Force the WatchWCManager singleton to initialize and activate WCSession
            _ = WatchWCManager.shared
        }
    var body: some Scene {
        WindowGroup {
            WatchContentView()   // ✅ Use the new name
        }
    }
}


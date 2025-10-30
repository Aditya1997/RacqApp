//
//  ContentView.swift
//  Racq App
//
//  Created by Deets on 10/29/25.
//  10/29/2025 Updates to create tabs for navigation

import SwiftUI

struct ContentView: View {
    var body: some View {
        TabView {
            // 🏠 HOME DASHBOARD
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house")
                }

            // 🎯 RECORD (you can swap in RecordView.swift here)
            RecordView()
                .tabItem {
                    Label("Record", systemImage: "record.circle")
                }

            // 👥 COMMUNITY TAB
            CommunityView()
                .tabItem {
                    Label("Community", systemImage: "person.3.fill")
                }

            // ⚙️ SETTINGS
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
        }
    }
}

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
            SessionView()
                .tabItem {
                    Label("Sessions", systemImage: "record.circle")
                }

            // 👥 COMMUNITY TAB
            CommunityView()
                .tabItem {
                    Label("Groups", systemImage: "person.3.fill")
                }

            // ⚙️ SETTINGS
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
    }
}

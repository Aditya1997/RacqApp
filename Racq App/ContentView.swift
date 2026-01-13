//
//  ContentView.swift
//  Racq App
//
//  Created by Deets on 10/29/25.
//  10/29/2025 Updates to create tabs for navigation

import SwiftUI

struct ContentView: View {
    
    // Ensuring profile exists
    @StateObject private var profileStore = UserProfileStore()
    @AppStorage("displayName") private var displayName: String = "Anonymous"
    private var participantId: String { UserIdentity.participantId() }
    
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

            // 🎯 MAP (you can swap in MapView.swift here)
            //MapView()
            //    .tabItem {
            //        Label("Map", systemImage: "map")
            //    }
            
            // 👥 COMMUNITY TAB
            CommunityView()
                .tabItem {
                    Label("Community", systemImage: "person.3.fill")
                }

            // ⚙️ SETTINGS
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
        }
        .task {
               let id = participantId
               print("👤 participantId:", id)

               await profileStore.ensureUserExists(participantId: id, displayName: displayName)
               await profileStore.fetchProfile(participantId: id)
        }
    }
}

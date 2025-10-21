//
//  SettingsView.swift
//  Racq App
//

import SwiftUI

struct SettingsView: View {
    @ObservedObject private var wcManager = PhoneWCManager.shared

    var body: some View {
        VStack(spacing: 16) {
            Text("Settings")
                .font(.largeTitle)
                .bold()

            // Watch Connection Status
            HStack(spacing: 8) {
                Image(systemName: wcManager.isWatchConnected ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(wcManager.isWatchConnected ? .green : .red)
                    .imageScale(.large)

                Text(wcManager.isWatchConnected ? "Watch Connected" : "Watch Not Connected")
                    .font(.headline)
            }

            Divider()

            // Last file info
            if !wcManager.lastFileName.isEmpty {
                Label("Last File: \(wcManager.lastFileName)", systemImage: "doc.text")
                    .font(.body)
            } else {
                Text("No file transfers yet.")
                    .foregroundColor(.gray)
            }

            Spacer()

            // Debug info
            VStack(spacing: 6) {
                Text("Session Status")
                    .font(.headline)
                Text(wcManager.isWatchConnected ? "✅ Active Connection" : "🕓 Waiting for Watch")
                    .foregroundColor(.secondary)
            }
            .padding(.top, 20)
        }
        .padding()
    }
}

#Preview {
    SettingsView()
}

//
//  CommunityView.swift
//  Racq App
//  Created by Deets on 10/29/2025
//  12/9/2025 - Updated to fill out dummy view

import SwiftUI

struct CommunityView: View {
    @StateObject private var store = ChallengeStore()

    var body: some View {
        NavigationView {
            List {

                // MARK: - CHALLENGES (Your Original Code)
                Section(header: Text("Challenges").font(.headline)) {
                    ForEach(store.challenges) { challenge in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(challenge.title)
                                .font(.headline)

                            ProgressView(
                                value: Double(challenge.progress),
                                total: Double(challenge.goal)
                            )

                            HStack {
                                Text("\(challenge.progress)/\(challenge.goal)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Spacer()

                                let pct = Int(
                                    (Double(challenge.progress) /
                                     max(1.0, Double(challenge.goal))) * 100
                                )

                                Text("\(pct)%")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(.vertical, 8)
                    }
                }

                // MARK: - GROUPS (New Section)
                Section(header: Text("Groups").font(.headline)) {

                    groupRow(
                        imageName: "person.3.fill",
                        groupName: "Racq Players",
                        preview: "Welcome to the group! New session this weekend…"
                    )

                    groupRow(
                        imageName: "tennisball.fill",
                        groupName: "Boston Tennis Crew",
                        preview: "Who's playing tomorrow? We have 3 open spots…"
                    )

                    groupRow(
                        imageName: "figure.run.circle.fill",
                        groupName: "Beginners League",
                        preview: "Reminder: Drills start at 6pm tonight!"
                    )
                }
            }
            .navigationTitle("Community")
            .task { await store.fetchChallenges() }
        }
    }

    // MARK: - GROUP ROW COMPONENT
    private func groupRow(imageName: String, groupName: String, preview: String) -> some View {
        HStack(spacing: 14) {

            // Group icon placeholder
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: imageName)
                    .font(.title3)
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(groupName)
                    .font(.headline)

                Text(preview)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.secondary)
                .font(.caption)
        }
        .padding(.vertical, 6)
    }
}

//
//  CommunityView.swift
//  Racq App
//  Created by Deets on 10/29/2025
//  12/9/2025 - Updated to fill out dummy view
//
import SwiftUI

struct CommunityView: View {
    @StateObject private var store = ChallengeStore()
    @State private var showCreate = false

    private let participantName = "You" // MVP identity for joined challenges

    var body: some View {
        NavigationView {
            List {
                // MARK: - CHALLENGES
                Section(header: Text("Challenges").font(.headline)) {
                    ForEach(store.challenges) { challenge in
                        VStack(alignment: .leading, spacing: 8) {

                            // TITLE + OPTIONAL SPONSOR + JOIN/STATUS
                            HStack {
                                Text(challenge.title)
                                    .font(.headline)

                                Spacer()

                                // Join button / Joined label (NEW)
                                if (challenge.participants[participantName] == nil) {
                                    Button("Join") {
                                        Task {
                                            if let id = challenge.id {
                                                await store.joinChallenge(challengeId: id, participantName: participantName)
                                            }
                                        }
                                    }
                                    .font(.caption)
                                    .buttonStyle(.bordered)
                                } else {
                                    Text("Joined")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                }

                                if let sponsor = challenge.sponsor,
                                   !sponsor.isEmpty {
                                    Text(sponsor)
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .foregroundColor(.white)
                                        .background(Color.blue.opacity(0.75))
                                        .cornerRadius(6)
                                }
                            }

                            // PROGRESS BAR
                            ProgressView(
                                value: Double(challenge.progress),
                                total: Double(challenge.goal)
                            )

                            // PROGRESS NUMBERS
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

                // MARK: - GROUPS  (UNCHANGED)
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
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showCreate = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showCreate) {
                CreateChallengeView(store: store)
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

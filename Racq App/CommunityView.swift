//
//  CommunityView.swift
//  Racq App
//  Created by Deets on 10/29/2025
//  12/9/2025 - Updated to fill out dummy view
//

import SwiftUI

struct CommunityView: View {
    @StateObject private var store = ChallengeStore()
    @StateObject private var groupStore = GroupStore.shared
    @State private var showCreate = false

    @AppStorage("displayName") private var displayName: String = "Anonymous"
    private var participantId: String { UserIdentity.participantId() }

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

                                if challenge.isJoined(participantId: participantId) {
                                    Text("Joined")
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                } else {
                                    Button("Join") {
                                        Task {
                                            if let id = challenge.id {
                                                let name = displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Anonymous" : displayName
                                                await store.joinChallenge(challengeId: id, participantId: participantId, displayName: name)
                                            }
                                        }
                                    }
                                    .font(.caption)
                                    .buttonStyle(.bordered)
                                }

                                if let sponsor = challenge.sponsor, !sponsor.isEmpty {
                                    Text(sponsor)
                                        .font(.caption2)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 3)
                                        .foregroundColor(.white)
                                        .background(Color.blue.opacity(0.75))
                                        .cornerRadius(6)
                                }
                            }

                            ProgressView(value: Double(challenge.progress),
                                         total: Double(challenge.goal))

                            HStack {
                                Text("\(challenge.progress)/\(challenge.goal)")
                                    .font(.caption)
                                    .foregroundColor(.secondary)

                                Spacer()

                                let pct = Int((Double(challenge.progress) / max(1.0, Double(challenge.goal))) * 100)
                                Text("\(pct)%")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }

                            // Optional: show user's personal contribution if joined
                            if challenge.isJoined(participantId: participantId) {
                                let you = challenge.participantProgress(participantId: participantId)
                                Text("You: \(you)")
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                            // Challenge Leaderboard (top 3 participants)
                            ChallengeLeaderboardView(
                                participants: challenge.participants,
                                participantNames: challenge.participantNames,
                                maxRows: 3
                            )
                            
                        }
                        .padding(.vertical, 8)
                    }
                }

                // MARK: - GROUPS (UNCHANGED)
                Section(header: Text("Groups").font(.headline)) {
                    ForEach(GroupStore.shared.groups) { g in
                        groupRow(
                            imageName: g.icon,
                            groupName: g.name,
                            description: g.description ?? "",
                            groupId: g.id
                        )
                    }
                }
            }
            .navigationTitle("Community")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showCreate = true } label: { Image(systemName: "plus") }
                }
            }
            .sheet(isPresented: $showCreate) {
                CreateChallengeView(store: store)
            }
            .task {
                await store.fetchChallenges()
                await groupStore.fetchGroups()
            }
            .refreshable {
                await store.fetchChallenges()
                await groupStore.fetchGroups()
            }
        }
    }

    private func groupRow(imageName: String, groupName: String, description: String, groupId: String) -> some View {
        let joined = GroupMembership.getGroupIds().contains(groupId)

        return HStack(spacing: 14) {

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

            if joined {
                Text("Joined")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            } else {
                Button("Join") {
                    Task {
                        await GroupStore.shared.joinGroup(
                            groupId: groupId,
                            displayName: displayName.isEmpty ? "Anonymous" : displayName
                        )
                    }
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 6)
    }
}

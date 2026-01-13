//
//  CommunityView.swift
//  Racq App
//  Created by Deets on 10/29/2025
//  12/9/2025 - Updated to fill out dummy view
//

//
//  CommunityView.swift
//  Racq App
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
                challengesSection
                groupsSection
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

    // MARK: - Sections

    private var challengesSection: some View {
        Section(header: Text("Challenges").font(.headline)) {
            ForEach(store.challenges) { challenge in
                challengeRow(challenge)
            }
        }
    }

    private var groupsSection: some View {
        Section(header: Text("Groups").font(.headline)) {
            if groupStore.groups.isEmpty {
                Text("No eligible groups found.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(groupStore.groups) { g in
                    groupRow(
                        imageName: g.icon,
                        groupName: g.name,
                        description: g.description ?? "",
                        groupId: g.id
                    )
                }
            }
        }
    }
    
    // MARK: - Group Row

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

                Text(description)
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
                    Task { await joinGroup(groupId: groupId) }
                }
                .font(.caption)
                .buttonStyle(.bordered)
            }
        }
        .padding(.vertical, 6)
    }

    private func joinGroup(groupId: String) async {
        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "Anonymous" : trimmed
        await GroupStore.shared.joinGroup(groupId: groupId, displayName: name)
        await groupStore.fetchGroups()
    }

    // MARK: - Challenge Row

    private func challengeRow(_ challenge: Challenge) -> some View {
        VStack(alignment: .leading, spacing: 8) {

            // TITLE + OPTIONAL SPONSOR + JOIN/STATUS
            HStack {
                Text(challenge.title)
                    .font(.headline)

                Spacer()
                
                if let sponsor = challenge.sponsor, !sponsor.isEmpty {
                    Text(sponsor)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .foregroundColor(.white)
                        .background(Color.blue.opacity(0.75))
                        .cornerRadius(6)
                }
                
                if challenge.isJoined(participantId: participantId) {
                    Text("Joined")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                } else {
                    Button("Join") {
                        Task { await joinChallengeIfPossible(challenge) }
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                }

            }

            ProgressView(value: Double(challenge.progress), total: Double(challenge.goal))

            // PROGRESS NUMBERS
            HStack {
                Text("\(challenge.progress)/\(challenge.goal)")
                    .font(.caption)
                    .foregroundColor(.secondary)

                Spacer()

                Text("\(challengePercent(challenge))%")
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }

            // Optional: show user's personal contribution if joined
            if challenge.isJoined(participantId: participantId) {
                Text("You: \(challenge.participantProgress(participantId: participantId))")
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

    private func challengePercent(_ challenge: Challenge) -> Int {
        let goal = max(1, challenge.goal)
        let pct = Int((Double(challenge.progress) / Double(goal)) * 100.0)
        return pct
    }

    private func joinChallengeIfPossible(_ challenge: Challenge) async {
        guard let id = challenge.id else { return }

        let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "Anonymous" : trimmed

        await store.joinChallenge(
            challengeId: id,
            participantId: participantId,
            displayName: name
        )
    }
}

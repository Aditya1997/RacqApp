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

    @State private var showCreateChallenge = false
    @State private var showCreateGroup = false

    @AppStorage("displayName") private var displayName: String = "Anonymous"
    private var participantId: String { UserIdentity.participantId() }

    var body: some View {
        NavigationView {
            List {
                groupsSection
                challengesSection
            }
            .navigationTitle("Community")
            .sheet(isPresented: $showCreateChallenge) {
                CreateChallengeView(store: store)
            }
            .sheet(isPresented: $showCreateGroup) {
                // ✅ CreateNewGroupView no longer takes a trailing closure
                CreateNewGroupView()
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

    private var groupsSection: some View {
        Section {
            if groupStore.groups.isEmpty {
                Text("No eligible groups found.")
                    .foregroundColor(.secondary)
            } else {
                ForEach(groupStore.groups) { g in
                    NavigationLink {
                        GroupDetailView(group: g)
                    } label: {
                        groupRow(
                            imageName: g.icon,          // ✅ icon is String (non-optional)
                            groupName: g.name,
                            description: g.description, // ✅ description is String (non-optional)
                            groupId: g.id,
                            memberCount: g.memberCount
                        )
                    }
                }
            }
        } header: {
            sectionHeader(title: "Groups") {
                showCreateGroup = true
            }
        }
    }

    private var challengesSection: some View {
        Section {
            ForEach(store.challenges) { challenge in
                challengeRow(challenge)
            }
        } header: {
            sectionHeader(title: "Challenges") {
                showCreateChallenge = true
            }
        }
    }

    private func sectionHeader(title: String, onCreate: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.headline)
                .textCase(nil)

            Spacer()

            Button(action: onCreate) {
                Text("Create")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.blue)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Group Row

    private func groupRow(
        imageName: String,
        groupName: String,
        description: String,
        groupId: String,
        memberCount: Int
    ) -> some View {
        let joined = GroupMembership.getGroupIds().contains(groupId)

        return HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.15))
                    .frame(width: 48, height: 48)

                Image(systemName: imageName.isEmpty ? "person.3.fill" : imageName)
                    .font(.title3)
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(groupName)
                    .font(.headline)

                if !description.isEmpty {
                    Text(description)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }

                Text("\(memberCount) member\(memberCount == 1 ? "" : "s")")
                    .font(.caption)
                    .foregroundColor(.secondary)
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
        NavigationLink {
            ChallengeDetailView(challenge: challenge, store: store)
        } label: {
            HStack(alignment: .top, spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: "trophy.fill") // (swap later if you want per-metric icons)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.blue)
                }
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(challenge.title)
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        if challenge.isJoined(participantId: participantId) {
                            Text("Joined")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        } else {
                            Button("Join") {
                                Task { await joinChallengeIfPossible(challenge) }
                            }
                            .font(.caption2.weight(.semibold))
                            .buttonStyle(.borderless)
                        }
                    }
                    // Optional sponsor line (compact)
                    if let sponsor = challenge.sponsor, !sponsor.isEmpty {
                        Text(sponsor)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }

                    // Compact progress
                    ProgressView(value: Double(challenge.progress), total: Double(challenge.goal))
                        .scaleEffect(x: 1.0, y: 0.8, anchor: .center)
                    HStack {
                        Text("\(challenge.progress)/\(challenge.goal)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text("\(challengePercent(challenge))%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 6)
            }
        }
    }

    private func challengeIconName(_ challenge: Challenge) -> String {
        // If your Challenge model has a metric/type field, swap logic here.
        // Default: trophy icon
        return "trophy.fill"
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


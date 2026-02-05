//
//  GroupDetailView.swift
//  Racq App
//
//  Created by Deets on 1/28/26.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct GroupDetailView: View {
    let group: PlayerGroup

    @Environment(\.dismiss) private var dismiss
    @AppStorage("displayName") private var displayName: String = "Anonymous"

    @State private var showCreatePost = false
    @State private var showMembers = false
    @State private var liveMemberCount: Int = 0
    @State private var isJoined: Bool = false

    // Posts
    @State private var groupListener: ListenerRegistration?
    @StateObject private var postStore = GroupPostStore()

    private struct SelectedPostNav: Identifiable, Hashable {
        let id: String
        let post: AppPost
        let ref: PostContextRef

        init(post: AppPost, ref: PostContextRef) {
            self.post = post
            self.ref = ref
            self.id = ref.postPath
        }

        static func == (lhs: SelectedPostNav, rhs: SelectedPostNav) -> Bool { lhs.id == rhs.id }
        func hash(into hasher: inout Hasher) { hasher.combine(id) }
    }

    @State private var selectedNav: SelectedPostNav?

    private var db: Firestore { FirebaseManager.shared.db }
    private var participantId: String { UserIdentity.participantId() }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 14) {
                    header

                    VStack(alignment: .leading, spacing: 10) {
                        if !group.description.isEmpty {
                            Text(group.description)
                        }
                        Button {
                            showMembers = true
                        } label: {
                            Text("See All Members (\(liveMemberCount))")
                                .font(.subheadline.weight(.semibold))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                    .padding(.horizontal)

                    recentActivityHeader
                    Divider().padding(.horizontal)

                    if postStore.posts.isEmpty {
                        Text("No recent activity yet.")
                            .foregroundColor(.secondary)
                            .padding(.top, 8)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(postStore.posts) { p in
                                let ref: PostContextRef = .group(groupId: group.id, postId: p.id)
                                FeedPostRow(post: p, ref: ref) {
                                    selectedNav = SelectedPostNav(post: p, ref: ref)
                                }
                            }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(item: $selectedNav) { nav in
                PostDetailView(post: nav.post, ref: nav.ref)
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(isJoined ? "Leave" : "Join") {
                        Task { await toggleMembership() }
                    }
                }
            }
            .sheet(isPresented: $showCreatePost) {
                CreateGroupPostView(groupId: group.id)
            }
            .sheet(isPresented: $showMembers) {
                GroupMembersView(groupId: group.id)
            }
            .onAppear {
                isJoined = GroupMembership.getGroupIds().contains(group.id)
                startGroupListener()
            }
            .task {
                await postStore.startListening(groupId: group.id)
            }
            .onDisappear {
                postStore.stopListening()
                stopGroupListener()
            }
        }
    }

    // MARK: - Header with cover + profile overlay
    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            headerBackground

            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .bottom, spacing: 12) {
                    profileImageCircle

                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.name)
                            .font(.title.bold())
                            .foregroundColor(.white)

                        if let loc = group.location, !loc.isEmpty {
                            Text(loc)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.85))
                        }

                        if !group.tagline.isEmpty {
                            Text(group.tagline)
                        }
                    }
                }
            }
            .padding()
        }
        .frame(height: 220)
        .clipped()
    }

    private var profileImageCircle: some View {
        Group {
            if let urlString = group.profileImageURL,
               !urlString.isEmpty,
               let url = URL(string: urlString) {
                AsyncImage(url: url) { img in
                    img.resizable().scaledToFill()
                } placeholder: {
                    Circle()
                        .fill(Color.white.opacity(0.15))
                        .overlay(
                            Image(systemName: "person.2.fill")
                                .foregroundColor(.white.opacity(0.8))
                        )
                }
            } else {
                Circle()
                    .fill(Color.white.opacity(0.15))
                    .overlay(
                        Image(systemName: "person.2.fill")
                            .foregroundColor(.white.opacity(0.8))
                    )
            }
        }
        .frame(width: 74, height: 74)
        .clipShape(Circle())
        .overlay(
            Circle().stroke(Color.white.opacity(0.35), lineWidth: 2)
        )
        .shadow(color: .black.opacity(0.35), radius: 10, x: 0, y: 4)
    }

    @ViewBuilder
    private var headerBackground: some View {
        if let urlString = group.backgroundImageURL,
           !urlString.isEmpty,
           let url = URL(string: urlString) {
            AsyncImage(url: url) { img in
                img.resizable().scaledToFill()
            } placeholder: {
                Image("tennis_court")
                    .resizable()
                    .scaledToFill()
            }
        } else {
            Image("tennis_court")
                .resizable()
                .scaledToFill()
        }
    }

    private var recentActivityHeader: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                Button { showCreatePost = true } label: {
                    Label("Create Text Post", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)

                Button {
                    // placeholder hook (need to implement)
                } label: {
                    Label("Invite Friends", systemImage: "person.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            Text("Recent Activity")
                .font(.headline)
        }
        .padding(.horizontal)
    }

    private func startGroupListener() {
        guard FirebaseApp.app() != nil else { return }

        groupListener?.remove()

        groupListener = FirebaseManager.shared.db
            .collection("groups")
            .document(group.id)
            .addSnapshotListener { snap, err in
                if let err {
                    print("❌ group listener error:", err)
                    return
                }
                guard let data = snap?.data() else { return }
                liveMemberCount = GroupMemberCount.count(from: data)
            }
    }

    private func stopGroupListener() {
        groupListener?.remove()
        groupListener = nil
    }

    private func toggleMembership() async {
        if isJoined {
            await GroupStore.shared.leaveGroup(groupId: group.id)
            isJoined = false
        } else {
            let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = trimmed.isEmpty ? "Anonymous" : trimmed
            await GroupStore.shared.joinGroup(groupId: group.id, displayName: name)
            isJoined = true
        }
        await GroupStore.shared.fetchGroups()
    }
}

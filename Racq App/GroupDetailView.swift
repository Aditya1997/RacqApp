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
            // Stable id for navigation; do NOT rely on post fields changing
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
                        if let desc = group.description, !desc.isEmpty {
                            Text(desc)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
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
                    Divider().padding(.horizontal)
                    recentActivityHeader
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
                isJoined = GroupMembership.getGroupIds().contains(group.id)  // :contentReference[oaicite:6]{index=6}
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

    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            headerBackground

            VStack(alignment: .leading, spacing: 6) {
                Text(group.name)
                    .font(.title.bold())
                    .foregroundColor(.white)

                if let loc = group.location, !loc.isEmpty {
                    Text(loc)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.85))
                }

                // NOTE: You asked to remove the "0 members" line at the top.
                // So we do NOT show member count here. Only the "See All Members" button.
            }
            .padding()
        }
        .frame(height: 220)
        .clipped()
        .overlay(
            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
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
            Text("Recent Activity")
                .font(.headline)
            HStack(spacing: 12) {
                Button { showCreatePost = true } label: {
                    Label("Create Text Post", systemImage: "plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                Button {
                    // placeholder hook
                } label: {
                    Label("Invite Friends", systemImage: "person.badge.plus")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
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
            await GroupStore.shared.leaveGroup(groupId: group.id)  // :contentReference[oaicite:7]{index=7}
            isJoined = false
        } else {
            let trimmed = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
            let name = trimmed.isEmpty ? "Anonymous" : trimmed
            await GroupStore.shared.joinGroup(groupId: group.id, displayName: name) // :contentReference[oaicite:8]{index=8}
            isJoined = true
        }
        // re-pull count from Firestore and refresh list screen store
        await GroupStore.shared.fetchGroups()
    }
}

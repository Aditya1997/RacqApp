//
//  PostInteractionsView.swift
//  Racq App
//
//  Created by Deets on 1/30/26.
//


import SwiftUI
import FirebaseCore

struct PostInteractionsView: View {
    let postRef: PostContextRef

    private let emojiPalette = ["🔥", "💪", "❤️", "👍", "👎", "🎾"]

    @StateObject private var store = PostInteractionsStore()
    @State private var commentText: String = ""

    private var myUserId: String { UserIdentity.participantId() }
    @AppStorage("displayName") private var displayName: String = "Anonymous"

    var body: some View {
        VStack(spacing: 14) {
            reactionsBar
            Divider()
            commentsList
            commentComposer
        }
        .onAppear {
            store.startListening(ref: postRef, myUserId: myUserId)
        }
        .onDisappear {
            store.stopListening()
        }
    }

    private var reactionsBar: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Reactions")
                .font(.headline)

            HStack(spacing: 10) {
                ForEach(emojiPalette, id: \.self) { emoji in
                    Button {
                        Task {
                            try? await PostInteractionsService.shared.toggleReaction(
                                on: postRef,
                                authorId: myUserId,
                                emoji: emoji
                            )
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(emoji)
                            let c = store.reactionCounts[emoji, default: 0]
                            if c > 0 { Text("\(c)").font(.caption) }
                        }
                        .padding(.vertical, 6)
                        .padding(.horizontal, 10)
                        .background(store.myReactions.contains(emoji) ? Color.accentColor.opacity(0.25) : Color.white.opacity(0.06))
                        .cornerRadius(999)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.horizontal)
    }

    private var commentsList: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Comments")
                .font(.headline)
                .padding(.horizontal)

            if store.comments.isEmpty {
                Text("No comments yet.")
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 10) {
                    ForEach(store.comments) { c in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(c.authorName).font(.subheadline).bold()
                                Spacer()
                                Text(c.createdAt.dateValue(), style: .time)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Text(c.text)
                                .font(.subheadline)
                        }
                        .padding(10)
                        .background(Color.white.opacity(0.06))
                        .cornerRadius(12)
                        .padding(.horizontal)
                    }
                }
            }
        }
    }

    private var commentComposer: some View {
        HStack(spacing: 10) {
            TextField("Add a comment…", text: $commentText, axis: .vertical)
                .textFieldStyle(.roundedBorder)

            Button("Send") {
                let text = commentText.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { return }
                commentText = ""
                Task {
                    try? await PostInteractionsService.shared.addComment(
                        to: postRef,
                        authorId: myUserId,
                        authorName: displayName,
                        text: text
                    )
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(.horizontal)
        .padding(.bottom, 6)
    }
}

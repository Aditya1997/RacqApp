//
//  ReactionsBarView.swift
//  Racq App
//
//  Created by Deets on 1/30/26.
//


import SwiftUI

struct ReactionsBarView: View {
    let postRef: PostContextRef

    private let palette = ["🔥", "👏", "😂", "❤️", "😮", "🎾"]

    @StateObject private var store = PostInteractionsStore()

    private var myUserId: String { UserIdentity.participantId() }

    var body: some View {
        HStack {
            Spacer(minLength: 0)

            HStack(spacing: 10) {
                ForEach(palette, id: \.self) { emoji in
                    reactionChip(emoji)
                }
            }

            Spacer(minLength: 0)
        }
        .onAppear {
            store.startListening(ref: postRef, myUserId: myUserId)
        }
        .onDisappear {
            store.stopListening()
        }
    }

    private func reactionChip(_ emoji: String) -> some View {
        let count = store.reactionCounts[emoji, default: 0]
        let isMine = store.myReactions.contains(emoji)

        return Button {
            Task {
                try? await PostInteractionsService.shared.toggleReaction(
                    on: postRef,
                    authorId: myUserId,
                    emoji: emoji
                )
            }
        } label: {
            HStack(spacing: 4) {
                Text(emoji)
                    .font(.system(size: 15))

                if count > 0 {
                    Text("\(count)")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(isMine ? Color.accentColor.opacity(0.18) : Color.white.opacity(0.04))
            .cornerRadius(999)
            .contentShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}

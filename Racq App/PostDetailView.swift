//
//  PostDetailView.swift
//  Racq App
//
//  Created by Deets on 1/30/26.
//

import SwiftUI

struct PostDetailView: View {
    let post: AppPost
    let ref: PostContextRef

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if post.type == .session {
                    SessionPostCard(post: post, context: refContext(ref))
                } else {
                    TinyPostCard(post: post, context: refContext(ref))
                }

                Divider().padding(.vertical, 4)

                PostInteractionsView(postRef: ref)
            }
            .padding()
        }
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            NewCommentsTracker.shared.markSeen(
                postKey: ref.stableKey,
                at: post.lastCommentAt ?? Date()
            )
        }

    }

    private func refContext(_ ref: PostContextRef) -> TinyPostCard.Context {
        switch ref {
        case .profile: return .profile
        case .group:   return .group
        }
    }
}

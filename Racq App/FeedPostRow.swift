//
//  FeedPostRow.swift
//  Racq App
//
//  Created by Deets on 2/2/26.
//

import SwiftUI

struct FeedPostRow: View {
    let post: AppPost
    let ref: PostContextRef
    let onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: onOpen) {
                Group {
                    if post.type == .session {
                        SessionPostCard(
                            post: post,
                            context: .group,
                            embeddedInContainer: true
                        )
                    } else {
                        TinyPostCard(
                            post: post,
                            context: .group,
                            variant: .feed,
                            embeddedInContainer: true
                        )
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            HStack {
                ReactionsBarView(postRef: ref)
                Spacer()
                CommentBubbleBadge(
                    count: post.commentCount,
                    isNew: NewCommentsTracker.shared.hasNewComments(
                        postKey: ref.stableKey,
                        lastCommentAt: post.lastCommentAt
                    )
                )
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

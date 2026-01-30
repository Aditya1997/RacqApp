//  UNUSED
//  GroupPostCardView.swift
//  Racq App
//
//  Created by Deets on 1/28/26.
//


import SwiftUI

struct GroupPostCardView: View {
    let groupId: String
    let post: GroupPost

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {

            HStack {
                Text("@\(post.authorName)")
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Text(relativeTime(post.createdAt))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            if let loc = post.locationText, !loc.isEmpty {
                Text(loc)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text(post.caption)
                .font(.body)

            // placeholder row for future emojis/comments
            HStack(spacing: 10) {
                Text("🔥")
                Text("👍")
                Text("🎾")
                Spacer()
                Image(systemName: "bubble.left")
                    .foregroundColor(.secondary)
            }
            .font(.caption)
            .padding(.top, 4)

        }
        .padding(12)
        .background(Color.white.opacity(0.06))
        .cornerRadius(14)
    }

    private func relativeTime(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }
}

//
//  CommentBubbleBadge.swift
//  Racq App
//
//  Created by Deets on 2/5/26.
//


import SwiftUI

struct CommentBubbleBadge: View {
    let count: Int
    let isNew: Bool

    var body: some View {
        if count > 0 {
            ZStack(alignment: .topTrailing) {
                Image(systemName: "text.bubble.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(isNew ? .red : .secondary)

                Text(count > 99 ? "99+" : "\(count)")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(
                        Capsule()
                            .fill(isNew ? Color.red : Color.secondary)
                    )
                    .offset(x: 8, y: -8)
            }
        }
    }
}

//
//  TinyPostCard.swift
//  Racq App
//
//  Created by Deets on 1/30/26.
//

import SwiftUI

struct TinyPostCard: View {
    enum Context {
        case profile
        case group
    }

    let post: AppPost
    let context: Context

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {

            header

            if let loc = post.locationText, !loc.isEmpty {
                Text(loc)
                    .font(context == .group ? .caption : .caption)
                    .foregroundColor(.secondary)
            }

            if !post.caption.isEmpty {
                Text(post.caption)
                    .font(context == .group ? .body : .body)
                    .foregroundColor(.primary)
                    .lineLimit(context == .group ? 4 : nil)   // example difference
            }

            if !post.imageURLs.isEmpty {
                imagesRow
            }

            if context == .profile {
                // Example: show extra session stats on profile only
                if post.type == .session {
                    sessionStatsRow
                }
            } else {
                // Example: group view shows a smaller footer or nothing
                EmptyView()
            }
        }
        .padding(12)
        .background(context == .group ? Color.white.opacity(0.05) : Color.white.opacity(0.06))
        .cornerRadius(12)
    }

    private var header: some View {
        HStack {
            Text("@\(post.authorName)")
                .font(context == .group ? .subheadline.weight(.semibold) : .headline.weight(.semibold))

            Spacer()

            Text(relativeTime(post.createdAt))
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }

    private var imagesRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(post.imageURLs, id: \.self) { urlString in
                    if let url = URL(string: urlString) {
                        AsyncImage(url: url) { img in
                            img.resizable().scaledToFill()
                        } placeholder: {
                            Color.white.opacity(0.08)
                        }
                        .frame(
                            width: context == .group ? 120 : 150,
                            height: context == .group ? 90 : 110
                        )
                        .clipped()
                        .cornerRadius(10)
                    }
                }
            }
        }
    }

    private var sessionStatsRow: some View {
        HStack(spacing: 12) {
            if let shots = post.shotCount { Text("Shots \(shots)") }
            if let dur = post.durationSec { Text("Dur \(formatDuration(dur))") }
            if let hr = post.heartRate, hr > 0 { Text("\(Int(hr)) BPM") }
            if let swing = post.fastestSwing, swing > 0 { Text("\(Int(swing)) mph") }
        }
        .font(.caption2)
        .foregroundColor(.secondary)
    }

    private func relativeTime(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }

    private func formatDuration(_ sec: Int) -> String {
        let m = sec / 60
        let s = sec % 60
        return String(format: "%02d:%02d", m, s)
    }
}

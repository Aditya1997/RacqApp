//
//  TinyPostCard.swift
//  Racq App
//
//  Created by Deets on 1/30/26.
//  Updated: add a profile grid-style tile version (3 per row)
//  Updated: add pin icon next to location + person icon + partner username on same row
//

import SwiftUI

struct TinyPostCard: View {
    enum Context {
        case profile
        case group
    }

    enum Variant {
        case feed
        case profileGrid
    }

    let post: AppPost
    let context: Context
    var variant: Variant = .feed
    var embeddedInContainer: Bool = false

    var body: some View {
        switch variant {
        case .feed:
            feedCard
        case .profileGrid:
            profileGridTile
        }
    }

    // MARK: - FEED CARD

    private var feedCard: some View {
        let content = VStack(alignment: .leading, spacing: 8) {
            header
            if shouldShowMetaRow {
                metaRow
            }
            if !post.caption.isEmpty {
                Text(post.caption)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(context == .group ? 4 : nil)
            }
            if !post.imageURLs.isEmpty {
                imagesRow
            }
            if context == .profile, post.type == .session {
                sessionStatsRow
            }
        }

        if embeddedInContainer {
            return AnyView(content)
        } else {
            return AnyView(
                content
                    .padding(12)
                    .background(context == .group ? Color.white.opacity(0.05) : Color.white.opacity(0.06))
                    .cornerRadius(12)
            )
        }
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

    private var shouldShowMetaRow: Bool {
        let hasLocation = (post.locationText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        let hasPartner = !(primaryTaggedUsername?.isEmpty ?? true)
        return hasLocation || hasPartner
    }

    private var primaryTaggedUsername: String? {
        post.taggedUsernames.first?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var metaRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            if let loc = post.locationText?.trimmingCharacters(in: .whitespacesAndNewlines),
               !loc.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(loc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            } else {
                Spacer(minLength: 0)
            }

            Spacer()

            if let partner = primaryTaggedUsername, !partner.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(partner.hasPrefix("@") ? partner : "@\(partner)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
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

    // MARK: - PROFILE GRID TILE

    private var profileGridTile: some View {
        ZStack(alignment: .bottomLeading) {
            gridImage
                .aspectRatio(1, contentMode: .fit)
                .clipped()
                .cornerRadius(10)

            LinearGradient(
                colors: [.clear, .black.opacity(0.55)],
                startPoint: .top,
                endPoint: .bottom
            )
            .cornerRadius(10)

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    if post.type == .session {
                        Image(systemName: "figure.tennis")
                            .font(.caption2)
                    } else {
                        Image(systemName: "text.bubble")
                            .font(.caption2)
                    }
                    Text(relativeTime(post.createdAt))
                        .font(.caption2)
                }
                .foregroundColor(.white.opacity(0.9))
                if post.type == .session, let shots = post.shotCount {
                    Text("Shots \(shots)")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            CommentBubbleBadge(
                count: post.commentCount,
                isNew: NewCommentsTracker.shared.hasNewComments(
                    postKey: post.id,
                    lastCommentAt: post.lastCommentAt
                )
            )
            .padding(6)
            .frame(
                maxWidth: .infinity,
                maxHeight: .infinity,
                alignment: .topTrailing
            )
            .padding(8)
        }
        .background(Color.white.opacity(0.06))
        .cornerRadius(10)
    }

    @ViewBuilder
    private var gridImage: some View {
        if let first = post.imageURLs.first, let url = URL(string: first) {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    Color.white.opacity(0.08)
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    gridPlaceholder
                @unknown default:
                    gridPlaceholder
                }
            }
        } else {
            gridPlaceholder
        }
    }

    private var gridPlaceholder: some View {
        ZStack {
            Color.white.opacity(0.08)
            Image(systemName: post.type == .session ? "figure.tennis" : "text.bubble")
                .font(.system(size: 26, weight: .semibold))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    // MARK: - Helpers

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

// MARK: - SessionPostCard (RecordView-style session card + feed metadata)

struct SessionPostCard: View {
    let post: AppPost
    let context: TinyPostCard.Context
    var embeddedInContainer: Bool = false

    @AppStorage("userHeightInInches") private var userHeightInInches: Double = 70
    @StateObject private var sessionStore = UserSessionStore()
    @State private var fetchedSession: UserSession?

    var body: some View {
        let content = VStack(alignment: .leading, spacing: 10) {
            header
            if shouldShowMetaRow {
                metaRow
            }
            if !post.caption.isEmpty {
                Text(post.caption)
                    .font(.body)
                    .foregroundColor(.primary)
                    .lineLimit(context == .group ? 4 : nil)
            }
            if !post.imageURLs.isEmpty {
                imagesRow
            }

            SessionCardView(
                title: "Session",
                durationSec: resolvedDurationSec,
                avgHR: resolvedHeartRate,
                shotCount: resolvedShotCount,
                forehandCount: resolvedForehandCount,
                backhandCount: resolvedBackhandCount,
                swings: [],
                userHeightInInches: userHeightInInches,
                fallbackFastestSwing: resolvedFastestSwing
            )
        }
        .task { await maybeFetchSession() }

        if embeddedInContainer {
            content
        } else {
            content
                .padding(12)
                .background(context == .group ? Color.white.opacity(0.05) : Color.white.opacity(0.06))
                .cornerRadius(12)
        }
    }

    // MARK: - Resolution logic (prefer AppPost snapshot, fallback to UserSession doc)

    private var resolvedShotCount: Int {
        post.shotCount ?? fetchedSession?.shotCount ?? 0
    }

    private var resolvedForehandCount: Int {
        post.forehandCount ?? fetchedSession?.forehandCount ?? 0
    }

    private var resolvedBackhandCount: Int {
        post.backhandCount ?? fetchedSession?.backhandCount ?? 0
    }

    private var resolvedDurationSec: Int {
        post.durationSec ?? fetchedSession?.durationSec ?? 0
    }

    private var resolvedHeartRate: Double {
        post.heartRate ?? fetchedSession?.heartRate ?? 0
    }

    private var resolvedFastestSwing: Double? {
        let v = post.fastestSwing ?? fetchedSession?.fastestSwing
        return (v ?? 0) > 0 ? v : nil
    }

    private var needsFetch: Bool {
        // If any key stat is missing on the post snapshot, try to fetch from session doc
        if post.sessionId == nil { return false }
        if post.shotCount == nil { return true }
        if post.forehandCount == nil { return true }
        if post.backhandCount == nil { return true }
        if post.durationSec == nil { return true }
        if post.heartRate == nil { return true }
        if post.fastestSwing == nil { return true }
        return false
    }

    private func maybeFetchSession() async {
        guard needsFetch else { return }
        guard let sessionId = post.sessionId else { return }

        // session docs are stored under the author's user doc
        let s = await sessionStore.fetchSession(participantId: post.authorId, sessionId: sessionId)
        self.fetchedSession = s
    }

    // MARK: - Header + Meta

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

    private var shouldShowMetaRow: Bool {
        let hasLocation = (post.locationText?.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false)
        let hasPartner = !(primaryTaggedUsername?.isEmpty ?? true)
        return hasLocation || hasPartner
    }

    private var primaryTaggedUsername: String? {
        post.taggedUsernames.first?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var metaRow: some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            if let loc = post.locationText?.trimmingCharacters(in: .whitespacesAndNewlines),
               !loc.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "mappin.and.ellipse")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(loc)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            } else {
                Spacer(minLength: 0)
            }

            Spacer()

            if let partner = primaryTaggedUsername, !partner.isEmpty {
                HStack(spacing: 6) {
                    Image(systemName: "person.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    Text(partner.hasPrefix("@") ? partner : "@\(partner)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
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

    private func relativeTime(_ date: Date) -> String {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f.localizedString(for: date, relativeTo: Date())
    }
}

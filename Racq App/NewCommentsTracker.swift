//
//  NewCommentsTracker.swift
//  Racq App
//
//  Created by Deets on 2/5/26.
//


import Foundation

final class NewCommentsTracker {
    static let shared = NewCommentsTracker()
    private init() {}

    private func key(_ postKey: String) -> String {
        "lastSeenCommentAt:\(postKey)"
    }

    func hasNewComments(postKey: String, lastCommentAt: Date?) -> Bool {
        guard let lastCommentAt else { return false }
        let seen = lastSeenAt(postKey: postKey) ?? .distantPast
        return lastCommentAt > seen
    }

    func markSeen(postKey: String, at date: Date = Date()) {
        UserDefaults.standard.set(
            date.timeIntervalSince1970,
            forKey: key(postKey)
        )
    }

    private func lastSeenAt(postKey: String) -> Date? {
        let t = UserDefaults.standard.double(forKey: key(postKey))
        return t == 0 ? nil : Date(timeIntervalSince1970: t)
    }
}

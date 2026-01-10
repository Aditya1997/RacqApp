//
//  UserIdentity.swift
//  Racq App
//
//  Created by Deets on 1/9/26.
//

import Foundation
import SwiftUI

enum UserIdentity {
    /// Stable per-device participant ID for multi-user testing without login.
    static func participantId() -> String {
        if let existing = UserDefaults.standard.string(forKey: "participantId"),
           !existing.isEmpty {
            return existing
        }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: "participantId")
        return new
    }

    static func displayName() -> String {
        UserDefaults.standard.string(forKey: "displayName") ?? "Anonymous"
    }

    static func setDisplayName(_ name: String) {
        UserDefaults.standard.set(name, forKey: "displayName")
    }
}

//
//  GroupMemberCount.swift
//  Racq App
//
//  Created by Deets on 1/28/26.
//


import Foundation

enum GroupMemberCount {
    static func count(from data: [String: Any]) -> Int {
        // Prefer counting "members.<id>" keys (true/1/etc)
        let memberKeyCount = data.keys.filter { $0.hasPrefix("members.") }.count
        if memberKeyCount > 0 { return memberKeyCount }

        // Fallback to "memberNames.<id>" keys
        let nameKeyCount = data.keys.filter { $0.hasPrefix("memberNames.") }.count
        if nameKeyCount > 0 { return nameKeyCount }

        // Last resort: try nested maps if they exist
        if let membersMap = data["members"] as? [String: Any], !membersMap.isEmpty {
            return membersMap.count
        }
        if let namesMap = data["memberNames"] as? [String: Any], !namesMap.isEmpty {
            return namesMap.count
        }

        return 0
    }
}
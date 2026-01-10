//
//  GroupMembership.swift
//  Racq App
//
//  Created by Deets on 1/9/26.
//

import Foundation

enum GroupMembership {
    static func getGroupIds() -> [String] {
        UserDefaults.standard.stringArray(forKey: "groupIds") ?? []
    }

    static func addGroupId(_ id: String) {
        var current = getGroupIds()
        if current.contains(id) { return }
        current.append(id)
        UserDefaults.standard.set(current, forKey: "groupIds")
    }

    static func removeGroupId(_ id: String) {
        var current = getGroupIds()
        current.removeAll { $0 == id }
        UserDefaults.standard.set(current, forKey: "groupIds")
    }
}

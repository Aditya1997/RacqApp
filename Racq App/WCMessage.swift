//
//  WCMessage.swift
//  Racq Shared
//

import Foundation

enum WCMessageType: String, Codable {
    case sessionStart        // ▶️ Watch starts recording (phone shows “Recording in Progress”)
    case sessionUpdate       // 🏁 Watch ends session and sends summary payload
    case settingsRequest     // ⚙️ Watch asks iPhone for latest settings
    case settingsUpdate      // ⚙️ Phone sends updated settings to Watch
}

struct WCMessage: Codable, Identifiable {
    let id: UUID
    let type: WCMessageType
    let payload: [String: String]

    init(id: UUID = UUID(), type: WCMessageType, payload: [String: String]) {
        self.id = id
        self.type = type
        self.payload = payload
    }
}

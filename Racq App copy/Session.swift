//
//  Session.swift
//  Racq App
//

import Foundation

struct Session: Identifiable, Codable {
    let id: UUID
    var date: Date
    var shots: Int
    var duration: TimeInterval
    var averageHR: Int?

    init(id: UUID = UUID(),
         date: Date = Date(),
         shots: Int = 0,
         duration: TimeInterval = 0,
         averageHR: Int? = nil) {
        self.id = id
        self.date = date
        self.shots = shots
        self.duration = duration
        self.averageHR = averageHR
    }

    var formattedDuration: String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

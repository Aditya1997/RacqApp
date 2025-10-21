//
//  SessionStore.swift
//  Racq App
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class SessionStore: ObservableObject {
    @Published var sessions: [Session] = []

    private let fileURL: URL = {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("sessions.json")
    }()

    func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        if let decoded = try? JSONDecoder().decode([Session].self, from: data) {
            sessions = decoded
        }
    }

    func save() {
        do {
            let data = try JSONEncoder().encode(sessions)
            try data.write(to: fileURL)
        } catch {
            print("Save error:", error)
        }
    }

    func add(_ session: Session) {
        sessions.insert(session, at: 0)
        save()
    }

    func delete(_ indexSet: IndexSet) {
        sessions.remove(atOffsets: indexSet)
        save()
    }
}

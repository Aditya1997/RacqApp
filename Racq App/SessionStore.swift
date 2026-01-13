//  UNUSED
//  SessionStore.swift
//  Racq App
//
//  Updated 10/29 to add new Firebase functionality

//import SwiftUI
//import Foundation
//import Combine
//import Firebase
//import FirebaseFirestore
//
//final class SessionStore: ObservableObject {
//    @Published var sessions: [Session] = []
//
//    private var cancellables = Set<AnyCancellable>()
//    private let fileURL: URL
//
//    init() {
//        let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
//        self.fileURL = documents.appendingPathComponent("sessions.json")
//        load()
//    }
//
//    // MARK: - Local Persistence
//
//    func load() {
//        if let data = try? Data(contentsOf: fileURL),
//           let decoded = try? JSONDecoder().decode([Session].self, from: data) {
//            sessions = decoded
//        }
//    }
//
//    func save() {
//        if let data = try? JSONEncoder().encode(sessions) {
//            try? data.write(to: fileURL)
//        }
//    }
//
//    func add(_ session: Session) {
//        sessions.append(session)
//        save()
//
//        // Firestore upload
//        Task {
//            do { try await uploadSession(session) }
//            catch { print("🔥 Firestore upload error: \(error)") }
//        }
//    }
//
//    func delete(at offsets: IndexSet) {
//        sessions.remove(atOffsets: offsets)
//        save()
//    }
//
//    // MARK: - Firestore Integration (manual encoding, no FirebaseFirestoreSwift)
//
//    /// Uploads a single session to Firestore
//    func uploadSession(_ session: Session) async throws {
//        let db = FirebaseManager.shared.db
//        let data: [String: Any] = [
//            "id": session.id.uuidString,
//            "date": session.date,
//            "shots": session.shots,
//            "duration": session.duration,
//            "averageHR": session.averageHR ?? 0
//        ]
//        try await db.collection("sessions")
//            .document(session.id.uuidString)
//            .setData(data)
//    }
//
//    /// Downloads all sessions from Firestore
//    func syncSessions() async throws {
//        let db = FirebaseManager.shared.db
//        let snapshot = try await db.collection("sessions").getDocuments()
//
//        let fetched: [Session] = snapshot.documents.compactMap { doc in
//            let data = doc.data()
//            guard
//                let id = UUID(uuidString: doc.documentID),
//                let timestamp = data["date"] as? Timestamp,
//                let shots = data["shots"] as? Int,
//                let duration = data["duration"] as? Double
//            else { return nil }
//            let averageHR = data["averageHR"] as? Int
//            return Session(
//                id: id,
//                date: timestamp.dateValue(),
//                shots: shots,
//                duration: duration,
//                averageHR: averageHR
//            )
//        }
//
//        DispatchQueue.main.async {
//            self.sessions = fetched
//            self.save()
//        }
//    }
//}

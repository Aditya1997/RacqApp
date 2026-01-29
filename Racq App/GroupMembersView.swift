//
//  GroupMembersView.swift
//  Racq App
//
//  Created by Deets on 1/28/26.
//


import SwiftUI
import Firebase
import FirebaseFirestore

struct GroupMembersView: View {
    let groupId: String
    @Environment(\.dismiss) private var dismiss

    @State private var names: [String] = []
    private var db: Firestore { FirebaseManager.shared.db }

    var body: some View {
        NavigationView {
            List {
                if names.isEmpty {
                    Text("No members yet.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(names, id: \.self) { n in
                        Text(n)
                    }
                }
            }
            .navigationTitle("Members")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await loadMembers()
            }
        }
    }

    private func loadMembers() async {
        guard FirebaseApp.app() != nil else { return }
        do {
            let snap = try await db.collection("groups").document(groupId).getDocument()
            let data = snap.data() ?? [:]

            // 1) Prefer nested map if it exists
            let nested = data["memberNames"] as? [String: Any] ?? [:]
            if !nested.isEmpty {
                names = nested.values.compactMap { $0 as? String }.sorted()
                return
            }

            // 2) Fallback: flattened keys memberNames.<id>
            let flattened = data.compactMap { (k, v) -> String? in
                guard k.hasPrefix("memberNames.") else { return nil }
                return v as? String
            }

            names = flattened.sorted()
        } catch {
            print("❌ loadMembers error:", error)
        }
    }
}

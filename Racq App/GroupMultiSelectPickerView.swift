//
//  GroupMultiSelectPickerView.swift
//  Racq App
//
//  Created by Deets on 1/30/26.
//

import SwiftUI
import Firebase
import FirebaseFirestore
import Combine

// MARK: - Shared Group Multi-Select Picker

struct GroupMultiSelectPickerView: View {
    let title: String
    let preselectedGroupIds: Set<String>
    let allowEmptySelection: Bool
    let onCancel: () -> Void
    let onConfirm: (Set<String>) -> Void

    @StateObject private var store = GroupPickerStore()
    @State private var selected: Set<String> = []

    private let columns: [GridItem] = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        NavigationView {
            Group {
                if store.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if store.groups.isEmpty {
                    VStack(spacing: 8) {
                        Text("No groups")
                            .font(.headline)
                        Text("Join a group to share posts there.")
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding()
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 18) {
                            ForEach(store.groups) { group in
                                GroupTile(group: group, isSelected: selected.contains(group.id))
                                    .onTapGesture { toggle(group.id) }
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { onCancel() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Post") { onConfirm(selected) }
                        .disabled(!allowEmptySelection && selected.isEmpty)
                }
            }
            .task {
                selected = preselectedGroupIds
                await store.loadJoinedGroups()
            }
        }
    }

    private func toggle(_ id: String) {
        if selected.contains(id) { selected.remove(id) }
        else { selected.insert(id) }
    }
}

// MARK: - Store + Models

struct GroupLite: Identifiable, Hashable {
    let id: String
    let name: String
    let icon: String
}

@MainActor
final class GroupPickerStore: ObservableObject {
    @Published var groups: [GroupLite] = []
    @Published var isLoading = false

    private var db: Firestore { FirebaseManager.shared.db }

    func loadJoinedGroups() async {
        guard FirebaseApp.app() != nil else { return }

        isLoading = true
        defer { isLoading = false }

        let ids = GroupMembership.getGroupIds()
        guard !ids.isEmpty else {
            groups = []
            return
        }

        do {
            // Firestore "in" query limit commonly 10
            let chunks = ids.chunked(into: 10)
            var loaded: [GroupLite] = []

            for chunk in chunks {
                let snap = try await db.collection("groups")
                    .whereField(FieldPath.documentID(), in: chunk)
                    .getDocuments()

                for doc in snap.documents {
                    let data = doc.data()
                    let name = data["name"] as? String ?? "Group"
                    let icon = data["icon"] as? String ?? ""
                    loaded.append(GroupLite(id: doc.documentID, name: name, icon: icon))
                }
            }

            groups = loaded.sorted {
                $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
            }
        } catch {
            print("❌ loadJoinedGroups error:", error)
            groups = []
        }
    }
}

// MARK: - UI Tile

struct GroupTile: View {
    let group: GroupLite
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            groupImage
                .frame(width: 70, height: 70)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(isSelected ? Color.accentColor : Color.white.opacity(0.20),
                                lineWidth: isSelected ? 3 : 1)
                )
                .overlay(alignment: .topTrailing) {
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .offset(x: 6, y: -6)
                    }
                }

            Text(group.name)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(maxWidth: 90)
        }
        .contentShape(Rectangle())
    }

    @ViewBuilder
    private var groupImage: some View {
        if let url = URL(string: group.icon), !group.icon.isEmpty {
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    Color.white.opacity(0.08)
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    placeholder
                @unknown default:
                    placeholder
                }
            }
        } else {
            placeholder
        }
    }

    private var placeholder: some View {
        ZStack {
            Color.white.opacity(0.08)
            Text(initials(from: group.name))
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white.opacity(0.85))
        }
    }

    private func initials(from name: String) -> String {
        let parts = name.split(separator: " ").map(String.init)
        let first = parts.first?.first.map(String.init) ?? "G"
        let second = parts.dropFirst().first?.first.map(String.init) ?? ""
        return (first + second).uppercased()
    }
}

// MARK: - Helpers

private extension Array {
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [self] }
        var result: [[Element]] = []
        var idx = 0
        while idx < count {
            let end = Swift.min(idx + size, count)
            result.append(Array(self[idx..<end]))
            idx = end
        }
        return result
    }
}

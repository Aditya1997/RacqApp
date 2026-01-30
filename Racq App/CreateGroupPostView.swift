//
//  CreateGroupPostView.swift
//  Racq App
//
//  Created by Deets on 1/28/26.
//

import SwiftUI
import Firebase

struct CreateGroupPostView: View {
    let groupId: String?

    @Environment(\.dismiss) private var dismiss
    @AppStorage("displayName") private var displayName: String = "Anonymous"
    private var participantId: String { UserIdentity.participantId() }

    @State private var caption: String = ""
    @State private var isSaving = false

    // Default to sharing
    @State private var shareToGroups: Bool = true

    // After tapping Post, show group picker
    @State private var showGroupPicker = false
    @State private var selectedGroupIds: Set<String> = []

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextEditor(text: $caption)
                    .frame(minHeight: 160)
                    .padding(10)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(12)
                    .padding(.horizontal)

                Toggle("Share", isOn: $shareToGroups)
                    .padding(.horizontal)

                Button {
                    let clean = caption.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard !clean.isEmpty, !isSaving else { return }

                    if shareToGroups {
                        showGroupPicker = true
                    } else {
                        Task { await createPost(shareToGroupIds: []) }
                    }
                } label: {
                    if isSaving {
                        ProgressView().frame(maxWidth: .infinity)
                    } else {
                        Text("Post").frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .disabled(caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)

                Spacer()
            }
            .padding(.top, 14)
            .navigationTitle("Create Text Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if let gid = groupId {
                    selectedGroupIds.insert(gid)
                }
            }
            .sheet(isPresented: $showGroupPicker) {
                GroupMultiSelectPickerView(
                    title: "Select Groups",
                    preselectedGroupIds: selectedGroupIds,
                    allowEmptySelection: true,
                    onCancel: { showGroupPicker = false },
                    onConfirm: { chosenIds in
                        showGroupPicker = false
                        selectedGroupIds = chosenIds
                        Task { await createPost(shareToGroupIds: Array(chosenIds)) }
                    }
                )
            }
        }
    }

    @MainActor
    private func createPost(shareToGroupIds: [String]) async {
        guard FirebaseApp.app() != nil else { return }
        let clean = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            try await PostService.shared.createTextPost(
                participantId: participantId,
                displayName: displayName,
                caption: clean,
                shareToGroupIds: shareToGroupIds
            )
            dismiss()
        } catch {
            print("❌ create text post error:", error)
        }
    }
}

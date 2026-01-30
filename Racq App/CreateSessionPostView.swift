//
//  CreateSessionPostView.swift
//  Racq App
//
//  Created by Deets on 1/30/26.
//  Updated: add group picker after tapping Post when sharing is enabled
//

import SwiftUI
import PhotosUI
import Firebase

struct CreateSessionPostView: View {
    let session: UserSession

    @Environment(\.dismiss) private var dismiss
    @AppStorage("displayName") private var displayName: String = "Anonymous"
    private var participantId: String { UserIdentity.participantId() }

    @State private var caption = ""
    @State private var locationText = ""
    @State private var taggedText = ""

    // ✅ default to share
    @State private var shareToJoinedGroups = true

    @State private var selectedItems: [PhotosPickerItem] = []
    @State private var selectedImageDatas: [Data] = []

    @State private var isSaving = false

    // ✅ Step 2: group picker after tapping Post
    @State private var showGroupPicker = false
    @State private var selectedGroupIds: Set<String> = []

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Caption")) {
                    TextField("Write something…", text: $caption, axis: .vertical)
                        .lineLimit(3...8)
                }

                Section(header: Text("Location (manual)")) {
                    TextField("West Coast Tennis Club", text: $locationText)
                }

                Section(header: Text("Tagged usernames")) {
                    TextField("marcus_serve, sarah_ace", text: $taggedText)
                    Text("Comma-separated")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                Section(header: Text("Images")) {
                    PhotosPicker(selection: $selectedItems, maxSelectionCount: 6, matching: .images) {
                        Text("Select up to 6 photos")
                    }
                    if !selectedImageDatas.isEmpty {
                        Text("\(selectedImageDatas.count) image(s) selected")
                            .foregroundColor(.secondary)
                    }
                }
                .onChange(of: selectedItems) { _ in
                    Task { await loadSelectedImages() }
                }

                Section {
                    Toggle("Share to my joined groups", isOn: $shareToJoinedGroups)
                }

                Section {
                    Button {
                        guard !isSaving else { return }
                        if shareToJoinedGroups {
                            showGroupPicker = true
                        } else {
                            Task { await submit(shareToGroupIds: []) }
                        }
                    } label: {
                        if isSaving { ProgressView() }
                        else { Text("Post Session") }
                    }
                    .disabled(isSaving)
                }
            }
            .navigationTitle("Post Session")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showGroupPicker) {
                GroupMultiSelectPickerView(
                    title: "Select Groups",
                    preselectedGroupIds: selectedGroupIds,
                    allowEmptySelection: true, // profile-only allowed
                    onCancel: { showGroupPicker = false },
                    onConfirm: { chosenIds in
                        showGroupPicker = false
                        selectedGroupIds = chosenIds
                        Task { await submit(shareToGroupIds: Array(chosenIds)) }
                    }
                )
            }
        }
    }

    private func loadSelectedImages() async {
        selectedImageDatas = []
        for item in selectedItems {
            if let data = try? await item.loadTransferable(type: Data.self) {
                selectedImageDatas.append(data)
            }
        }
    }

    private func submit(shareToGroupIds: [String]) async {
        guard FirebaseApp.app() != nil else { return }
        isSaving = true
        defer { isSaving = false }

        let cleanCaption = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        let cleanLocation = locationText.trimmingCharacters(in: .whitespacesAndNewlines)

        let tagged = taggedText
            .split(separator: ",")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        do {
            // Upload images (if any)
            let imageURLs: [String]
            if selectedImageDatas.isEmpty {
                imageURLs = []
            } else {
                imageURLs = try await StorageService.shared.uploadJPEGs(
                    datas: selectedImageDatas,
                    pathPrefix: "user_posts/\(participantId)"
                )
            }

            // Write post to profile + selected groups
            try await PostService.shared.createSessionPost(
                participantId: participantId,
                displayName: displayName,
                session: session,
                caption: cleanCaption,
                locationText: cleanLocation.isEmpty ? nil : cleanLocation,
                taggedUsernames: tagged,
                imageURLs: imageURLs,
                shareToGroupIds: shareToGroupIds
            )

            dismiss()
        } catch {
            print("❌ submit session post error:", error)
        }
    }
}

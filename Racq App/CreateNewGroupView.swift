//
//  CreateNewGroupView.swift
//  Racq App
//
//  Created by Deets on 2/4/26.
//
import SwiftUI
import PhotosUI

struct CreateNewGroupView: View {
    @Environment(\.dismiss) private var dismiss

    @State private var name: String = ""
    @State private var location: String = ""
    @State private var tagline: String = ""
    @State private var description: String = ""

    @State private var profilePickerItem: PhotosPickerItem?
    @State private var backgroundPickerItem: PhotosPickerItem?

    @State private var profilePreview: UIImage?
    @State private var backgroundPreview: UIImage?

    // Store image data so it can be uploaded later when Storage is enabled
    @State private var profileImageData: Data?
    @State private var backgroundImageData: Data?

    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            Form {
                Section("Group Info") {
                    TextField("Group name", text: $name)
                        .textInputAutocapitalization(.words)

                    TextField("Location", text: $location)
                        .textInputAutocapitalization(.words)

                    TextField("Tagline", text: $tagline)
                        .textInputAutocapitalization(.sentences)
                }

                Section("Detailed Description") {
                    TextEditor(text: $description)
                        .frame(minHeight: 130)
                }

                Section("Images") {
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Cover / background")
                            Spacer()
                            PhotosPicker(selection: $backgroundPickerItem, matching: .images) {
                                Text("Choose")
                            }
                        }

                        if let img = backgroundPreview {
                            Image(uiImage: img)
                                .resizable()
                                .scaledToFill()
                                .frame(height: 150)
                                .clipped()
                                .cornerRadius(12)
                        } else {
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(UIColor.secondarySystemBackground))
                                .frame(height: 150)
                                .overlay(
                                    Text("No cover selected")
                                        .foregroundColor(.secondary)
                                )
                        }
                    }
                    .padding(.vertical, 6)

                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("Profile picture")
                            Spacer()
                            PhotosPicker(selection: $profilePickerItem, matching: .images) {
                                Text("Choose")
                            }
                        }

                        HStack(spacing: 12) {
                            if let img = profilePreview {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 72, height: 72)
                                    .clipShape(Circle())
                            } else {
                                Circle()
                                    .fill(Color(UIColor.secondarySystemBackground))
                                    .frame(width: 72, height: 72)
                                    .overlay(
                                        Image(systemName: "person.2.circle")
                                            .font(.title2)
                                            .foregroundColor(.secondary)
                                    )
                            }

                            Text("Saved for later. Will upload when Storage is enabled.")
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 6)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                            .font(.footnote)
                    }
                }
            }
            .navigationTitle("Create Group")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .disabled(isSaving)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        Task { await createGroup() }
                    } label: {
                        if isSaving { ProgressView() } else { Text("Create") }
                    }
                    .disabled(isSaving || name.trimmed.isEmpty)
                }
            }
            .onChange(of: backgroundPickerItem) { _ in
                Task { await loadBackgroundPreview() }
            }
            .onChange(of: profilePickerItem) { _ in
                Task { await loadProfilePreview() }
            }
        }
    }

    private func createGroup() async {
        errorMessage = nil
        let trimmedName = name.trimmed
        guard !trimmedName.isEmpty else {
            errorMessage = "Group name is required."
            return
        }

        isSaving = true
        defer { isSaving = false }

        do {
            _ = try await GroupStore.shared.createGroup(
                name: trimmedName,
                location: location.trimmedOrNil,
                tagline: tagline.trimmedOrNil,
                description: description.trimmedOrNil,
                profileImageData: profileImageData,             // stored for later Storage upload
                backgroundImageData: backgroundImageData        // stored for later Storage upload
            )

            await GroupStore.shared.fetchGroups()
            dismiss()
        } catch {
            errorMessage = "Failed to create group: \(error.localizedDescription)"
        }
    }

    private func loadBackgroundPreview() async {
        guard let item = backgroundPickerItem else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                backgroundImageData = data
                backgroundPreview = img
            }
        } catch {
            errorMessage = "Couldn’t load cover image."
        }
    }

    private func loadProfilePreview() async {
        guard let item = profilePickerItem else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                profileImageData = data
                profilePreview = img
            }
        } catch {
            errorMessage = "Couldn’t load profile image."
        }
    }
}

private extension String {
    var trimmed: String { trimmingCharacters(in: .whitespacesAndNewlines) }
    var trimmedOrNil: String? {
        let t = trimmed
        return t.isEmpty ? nil : t
    }
}

//
//  CreateGroupPostView.swift
//  Racq App
//
//  Created by Deets on 1/28/26.
//


import SwiftUI
import Firebase
import FirebaseFirestore

struct CreateGroupPostView: View {
    let groupId: String

    @Environment(\.dismiss) private var dismiss
    @AppStorage("displayName") private var displayName: String = "Anonymous"
    private var participantId: String { UserIdentity.participantId() }

    @State private var caption: String = ""
    @State private var isSaving = false

    private var db: Firestore { FirebaseManager.shared.db }

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                TextEditor(text: $caption)
                    .frame(minHeight: 160)
                    .padding(10)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(12)
                    .padding(.horizontal)

                Button {
                    Task { await createPost() }
                } label: {
                    if isSaving {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Post")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal)
                .disabled(caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSaving)

                Spacer()
            }
            .padding(.top, 14)
            .navigationTitle("Create Post")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func createPost() async {
        guard FirebaseApp.app() != nil else { return }
        let clean = caption.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !clean.isEmpty else { return }

        isSaving = true
        defer { isSaving = false }

        do {
            let ref = db.collection("groups")
                .document(groupId)
                .collection("posts")
                .document()

            try await ref.setData([
                "authorId": participantId,
                "authorName": displayName,
                "caption": clean,
                "createdAt": Timestamp(date: Date()),
                "type": "text"
            ], merge: true)

            dismiss()
        } catch {
            print("❌ create post error:", error)
        }
    }
}
//
//  ProfileView.swift
//  Racq App
//  Created by Deets on 10/29/2025
//  12/9/2025 - Updated to fill out dummy view

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @ObservedObject var wc = PhoneWCManager.shared

    // MARK: - Persistent Profile Info
    @AppStorage("dateJoined") private var dateJoined = "Jan 2025"
    @AppStorage("sessionsCompleted") private var sessionsCompleted = 42
    @AppStorage("totalHits") private var totalHits = 1280
    @AppStorage("hardestHit") private var hardestHit = "87 mph"

    @AppStorage("racket") private var racket = "Wilson Blade 98"
    @AppStorage("shoes") private var shoes = "Nike Vapor Pro"
    @AppStorage("bag") private var bag = "Babolat Classic"

    // MARK: - Photo Picker
    @State private var selectedPhoto: PhotosPickerItem?
    @AppStorage("profileImageData") private var profileImageData: Data?
    @State private var profileImage: UIImage?

    // MARK: - Editing Sheet Control
    @State private var editingField: EditingField?
    @State private var tempText = ""

    enum EditingField: Identifiable {
        case racket, shoes, bag
        var id: Int { hashValue }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {

                // MARK: - Profile Icon (NOW PICKABLE)
                VStack(spacing: 12) {
                    PhotosPicker(selection: $selectedPhoto, matching: .images) {
                        Group {
                            if let data = profileImageData,
                               let img = UIImage(data: data) {
                                Image(uiImage: img)
                                    .resizable()
                                    .scaledToFill()
                            } else {
                                Image(systemName: "person.crop.circle.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .foregroundColor(.white.opacity(0.85))
                            }
                        }
                        .frame(width: 130, height: 130)
                        .clipShape(Circle())
                        .shadow(color: .white.opacity(0.25), radius: 10)
                    }
                    .onChange(of: selectedPhoto) { newItem in
                        loadImage(from: newItem)
                    }

                    Text("Player Profile")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                }
                .padding(.top, 16)

                // MARK: - Player Stats Card (UNCHANGED)
                VStack(alignment: .leading, spacing: 18) {

                    Text("Player Stats")
                        .font(.headline)
                        .foregroundColor(.white)

                    VStack(spacing: 24) {

                        // -------- ROW 1 --------
                        HStack(spacing: 20) {
                            statBox(title: "Date Joined",
                                    value: dateJoined,
                                    icon: "calendar")
                            statBox(title: "Sessions Completed",
                                    value: "\(sessionsCompleted)",
                                    icon: "figure.run")
                        }

                        // -------- ROW 2 --------
                        HStack(spacing: 20) {
                            statBox(title: "Total Hits",
                                    value: "\(totalHits)",
                                    icon: "bolt.circle")
                            statBox(title: "Hardest Hit",
                                    value: hardestHit,
                                    icon: "speedometer")
                        }
                    }
                    .padding()
                    .background(BlurBackground(style: .systemUltraThinMaterialDark))
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                }

                // MARK: - Equipment Card (NOW EDITABLE)
                VStack(alignment: .leading, spacing: 18) {

                    Text("Equipment")
                        .font(.headline)
                        .foregroundColor(.white)

                    VStack(spacing: 24) {

                        HStack(spacing: 20) {
                            editableEquipmentBox(label: "Racket", value: racket) {
                                beginEditing(.racket, current: racket)
                            }
                            editableEquipmentBox(label: "Shoes", value: shoes) {
                                beginEditing(.shoes, current: shoes)
                            }
                        }

                        HStack(spacing: 20) {
                            editableEquipmentBox(label: "Bag", value: bag) {
                                beginEditing(.bag, current: bag)
                            }
                            Spacer()
                        }

                    }
                    .padding()
                    .background(BlurBackground(style: .systemUltraThinMaterialDark))
                    .cornerRadius(18)
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                }

                Spacer(minLength: 20)
            }
            .padding(.horizontal)
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .navigationTitle("Profile")
        .sheet(item: $editingField) { field in
            editSheet(for: field)
        }
        .onAppear { loadStoredImage() }
    }

    // MARK: - Load Photo
    private func loadImage(from item: PhotosPickerItem?) {
        guard let item else { return }
        Task {
            if let data = try? await item.loadTransferable(type: Data.self),
               let img = UIImage(data: data) {
                profileImage = img
                profileImageData = data   // Persist
            }
        }
    }

    private func loadStoredImage() {
        if let data = profileImageData {
            profileImage = UIImage(data: data)
        }
    }

    // MARK: - Start Editing
    private func beginEditing(_ field: EditingField, current: String) {
        editingField = field
        tempText = current
    }

    // MARK: - Edit Sheet
    @ViewBuilder
    private func editSheet(for field: EditingField) -> some View {
        NavigationView {
            VStack(spacing: 20) {
                TextField("Enter new value", text: $tempText)
                    .textFieldStyle(.roundedBorder)
                    .padding()

                Button("Save") {
                    switch field {
                    case .racket: racket = tempText
                    case .shoes: shoes = tempText
                    case .bag: bag = tempText
                    }
                    editingField = nil
                }
                .buttonStyle(.borderedProminent)

                Spacer()
            }
            .navigationTitle("Edit \(fieldTitle(field))")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func fieldTitle(_ field: EditingField) -> String {
        switch field {
        case .racket: return "Racket"
        case .shoes: return "Shoes"
        case .bag: return "Bag"
        }
    }
}

// MARK: - Existing Stylish Stat Box (UNCHANGED)
private func statBox(title: String, value: String, icon: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {

        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Text(title.uppercased())
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }

        Text(value)
            .font(.headline)
            .foregroundColor(.white)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
}

// MARK: - Stylish Equipment Box (NOW TAPPABLE)
private func editableEquipmentBox(label: String, value: String, action: @escaping () -> Void) -> some View {
    Button(action: action) {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text(label.uppercased())
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))

                Text(value)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }

            Spacer()

            // ← CLEAR TAP INDICATOR
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.35))
                .font(.caption)
        }
        .padding(10)
        .background(Color.white.opacity(0.05)) // subtle highlight
        .cornerRadius(10)
    }
}

// MARK: - Blur Background (UNCHANGED)
struct BlurBackground: UIViewRepresentable {
    var style: UIBlurEffect.Style

    func makeUIView(context: Context) -> UIVisualEffectView {
        UIVisualEffectView(effect: UIBlurEffect(style: style))
    }

    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

#Preview {
    ProfileView()
}

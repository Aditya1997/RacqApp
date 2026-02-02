//
//  ProfileView.swift
//  Racq App
//  Created by Deets on 10/29/2025
//  12/9/2025 - Updated to fill out dummy view

import SwiftUI
import PhotosUI

struct ProfileView: View {
    @ObservedObject var wc = PhoneWCManager.shared

    // MARK: - Persistent Profile Info and Past Sessions
    @StateObject private var sessionStore = UserSessionStore()
    private var participantId: String { UserIdentity.participantId() }
    @StateObject private var profileStore = UserProfileStore()
    @AppStorage("displayName") private var displayName: String = "Anonymous"
    
    @AppStorage("racket") private var racket = "Wilson Blade 98"
    @AppStorage("shoes") private var shoes = "Nike Vapor Pro"
    @AppStorage("bag") private var bag = "Babolat Classic"

    // MARK: - User Posts
    @StateObject private var postStore = UserPostStore()
    @State private var showPostSession: UserSession?
    
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
        NavigationStack {
            ScrollView {
                VStack(spacing: 28) {
                    // MARK: - Profile Icon
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
                        Text(displayName)
                            .font(.title2.bold())
                            .foregroundColor(.white)
                    }
                    .padding(.top, 16)
                    
                    // MARK: - Player Stats Card
                    VStack(alignment: .leading, spacing: 18) {
                        Text("Player Stats")
                            .font(.headline)
                            .foregroundColor(.white)
                        let p = profileStore.profile
                        VStack(spacing: 24) {
                            // -------- ROW 1 --------
                            HStack(spacing: 20) {
                                statBox(
                                    title: "Date Joined",
                                    value: p == nil ? "--" : formattedDate(p!.dateJoined),
                                    icon: "calendar"
                                )
                                statBox(
                                    title: "Sessions Completed",
                                    value: "\(p?.sessionsCompleted ?? 0)",
                                    icon: "figure.run"
                                )
                            }
                            // -------- ROW 2 --------
                            HStack(spacing: 20) {
                                statBox(
                                    title: "Total Hits",
                                    value: "\(p?.totalHits ?? 0)",
                                    icon: "bolt.circle"
                                )
                                statBox(
                                    title: "Fastest Swing",
                                    value: {
                                        let swing = p?.fastestSwing ?? 0
                                        return swing > 0 ? "\(Int(swing)) mph" : "N/A"
                                    }(),
                                    icon: "speedometer"
                                )
                                statBox(
                                    title: "Total Duration",
                                    value: formatDuration(p?.totalDurationSec ?? 0),
                                    icon: "clock"
                                )
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
                    
                    // MARK: - Equipment Card
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
                    // MARK: - Posts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Posts")
                            .font(.headline)
                            .foregroundColor(.white)
                        if postStore.posts.isEmpty {
                            Text("No posts yet.")
                                .foregroundColor(.white.opacity(0.6))
                                .font(.subheadline)
                        } else {
                            let columns = [
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8),
                                GridItem(.flexible(), spacing: 8)
                            ]
                            LazyVGrid(columns: columns, spacing: 8) {
                                ForEach(postStore.posts) { p in
                                    NavigationLink {
                                        PostDetailView(
                                            post: p,
                                            ref: .profile(ownerId: participantId, postId: p.id)
                                        )
                                    } label: {
                                        TinyPostCard(post: p, context: .profile, variant: .profileGrid)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                    // MARK: - Past Sessions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Past Sessions")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        if sessionStore.sessions.isEmpty {
                            Text("No sessions saved yet.")
                                .foregroundColor(.white.opacity(0.6))
                                .font(.subheadline)
                        } else {
                            VStack(spacing: 10) {
                                ForEach(sessionStore.sessions.prefix(10)) { s in
                                    sessionRow(s) {
                                        showPostSession = s
                                    }
                                }
                            }
                        }
                    }
                    
                }
                .padding(.horizontal)
            }
        }
        .background(Color.black.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .navigationTitle("Profile")
        .sheet(item: $editingField) { field in
            editSheet(for: field)
        }
        .sheet(item: $showPostSession) { session in
            CreateSessionPostView(session: session)
        }
        .onAppear {
            loadStoredImage()
            Task {
                await profileStore.fetchProfile(participantId: participantId)
                await sessionStore.fetchSessions(participantId: participantId)
                await postStore.startListening(participantId: participantId)
            }
        }
        .onDisappear { postStore.stopListening() }
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

// MARK: - Session Helpers (outside of ProfileView)

private func sessionRow(_ s: UserSession, onPost: @escaping () -> Void) -> some View {
    VStack(alignment: .leading, spacing: 6) {
        HStack {
            Text(formattedDate(s.timestamp))
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white)
            Spacer()
            Button("Post") { onPost() }
                .font(.caption)
                .buttonStyle(.bordered)
        }
        HStack {
            Text("Shots \(s.shotCount)")
            Spacer()
            Text("FH \(s.forehandCount)")
            Spacer()
            Text("BH \(s.backhandCount)")
        }
        .font(.caption)
        .foregroundColor(.white.opacity(0.75))
        HStack {
            Text("Dur \(formatDuration(s.durationSec))")
            Spacer()
            Text(s.heartRate > 0 ? "\(Int(s.heartRate)) BPM" : "-- BPM")
            Spacer()
            Text(s.fastestSwing > 0 ? "\(Int(s.fastestSwing)) mph" : "-- mph")
        }
        .font(.caption2)
        .foregroundColor(.white.opacity(0.6))
    }
    .padding(12)
    .background(Color.white.opacity(0.06))
    .cornerRadius(12)
}

private func formattedDate(_ date: Date) -> String {
    let f = DateFormatter()
    f.dateStyle = .medium
    f.timeStyle = .short
    return f.string(from: date)
}

private func formatDuration(_ sec: Int) -> String {
    let m = sec / 60
    let s = sec % 60
    return String(format: "%02d:%02d", m, s)
}

// MARK: - Existing Stat Box
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

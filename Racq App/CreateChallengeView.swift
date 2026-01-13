//
//  CreateChallengeView.swift
//  Racq App
//
//  Created by Deets on 1/9/26.
//
//
//  CreateChallengeView.swift
//  Racq App
//
//  Created by Deets on 1/9/26.
//

import SwiftUI

struct CreateChallengeView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var store: ChallengeStore

    @State private var title: String = ""
    @State private var goalText: String = "100"
    @State private var trackedStat: ChallengeTrackedStat = .forehands
    @State private var minPerSessionText: String = "0"
    @State private var sponsor: String = ""

    // ✅ Use saved name, but do NOT edit it here
    @AppStorage("displayName") private var displayName: String = "Anonymous"

    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {

                Section(header: Text("Creator")) {
                    HStack {
                        Text(displayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Anonymous" : displayName)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("Challenge")) {
                    TextField("Title", text: $title)

                    TextField("Goal (number)", text: $goalText)
                        .keyboardType(.numberPad)

                    Picker("Tracks", selection: $trackedStat) {
                        ForEach(ChallengeTrackedStat.allCases) { stat in
                            Text(stat.displayName).tag(stat)
                        }
                    }

                    TextField("Min per session (optional)", text: $minPerSessionText)
                        .keyboardType(.numberPad)

                    TextField("Sponsor (optional)", text: $sponsor)
                }

                if let errorMessage {
                    Section { Text(errorMessage).foregroundColor(.red) }
                }
            }
            .navigationTitle("New Challenge")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Create") {
                        Task { await createChallenge() }
                    }
                    .disabled(isSaving || title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }

    private func createChallenge() async {
        errorMessage = nil

        let t = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { errorMessage = "Please enter a title."; return }

        guard let goal = Int(goalText), goal > 0 else {
            errorMessage = "Goal must be a positive number."
            return
        }

        let minTrim = minPerSessionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let minValue: Int? = minTrim.isEmpty ? nil : Int(minTrim)

        let sponsorTrim = sponsor.trimmingCharacters(in: .whitespacesAndNewlines)
        let sponsorValue: String? = sponsorTrim.isEmpty ? nil : sponsorTrim

        let pid = UserIdentity.participantId()

        // ✅ Use saved displayName, but do not edit it here
        let cleanName = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let creatorName = cleanName.isEmpty ? "Anonymous" : cleanName

        isSaving = true
        defer { isSaving = false }

        let new = Challenge(
            id: UUID().uuidString,
            title: t,
            goal: goal,
            progress: 0,
            participants: [pid: 0],              // creator auto-joined
            participantNames: [pid: creatorName],// store their name
            sponsor: sponsorValue,
            trackedStat: trackedStat,
            minPerSession: minValue,
            updatedAt: Date()
        )

        await store.addChallenge(new)
        await store.fetchChallenges()
        dismiss()
    }
}

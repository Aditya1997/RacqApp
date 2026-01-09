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
    @State private var yourName: String = "You"

    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        NavigationView {
            Form {
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

                Section(header: Text("You")) {
                    TextField("Your name (MVP)", text: $yourName)
                }

                if let errorMessage {
                    Section {
                        Text(errorMessage).foregroundColor(.red)
                    }
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

        let nameTrim = yourName.trimmingCharacters(in: .whitespacesAndNewlines)
        let participantName = nameTrim.isEmpty ? "You" : nameTrim

        let sponsorTrim = sponsor.trimmingCharacters(in: .whitespacesAndNewlines)
        let sponsorValue: String? = sponsorTrim.isEmpty ? nil : sponsorTrim

        let minTrim = minPerSessionText.trimmingCharacters(in: .whitespacesAndNewlines)
        let minValue: Int? = minTrim.isEmpty ? nil : Int(minTrim)

        isSaving = true
        defer { isSaving = false }

        let new = Challenge(
            id: UUID().uuidString,
            title: t,
            goal: goal,
            progress: 0,
            participants: [participantName: 0],   // creator auto-joined
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

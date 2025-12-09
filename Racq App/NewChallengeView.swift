//
//  NewChallengeView.swift
//  Racq App
//
//  Created by Deets on 12/9/25.
//
import SwiftUI

struct NewChallengeView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var store: ChallengeStore
    
    @State private var title = ""
    @State private var goal = ""
    @State private var sponsor = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Challenge Info")) {
                    TextField("Title", text: $title)
                    TextField("Goal (#)", text: $goal)
                        .keyboardType(.numberPad)
                    TextField("Sponsor (Optional)", text: $sponsor)
                }
            }
            .navigationTitle("New Challenge")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        Task {
                            let challenge = Challenge(
                                id: UUID().uuidString,
                                title: title,
                                goal: Int(goal) ?? 0,
                                progress: 0,
                                participants: [:],
                                sponsor: sponsor.isEmpty ? nil : sponsor,
                                updatedAt: Date()
                            )
                            await store.addChallenge(challenge)
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }
    
    func saveChallenge() {
        let challenge = Challenge(
            id: UUID().uuidString,
            title: title,
            goal: Int(goal) ?? 0,
            progress: 0,
            participants: [:],
            sponsor: sponsor.isEmpty ? nil : sponsor,
            updatedAt: Date()
        )
        
        Task {
            await store.addChallenge(challenge)
            dismiss()
        }
    }
}

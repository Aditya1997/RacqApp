//
//  NameSetupView.swift
//  Racq App
//
//  Created by Deets on 1/12/26.
//

import SwiftUI

struct NameSetupView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage("displayName") private var displayName: String = ""
    @State private var tempName: String = ""

    var body: some View {
        NavigationView {
            VStack(spacing: 16) {
                Text("What should we call you?")
                    .font(.title2.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("This will show on leaderboards and in group chat. You can change it later.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                TextField("Your name", text: $tempName)
                    .textInputAutocapitalization(.words)
                    .autocorrectionDisabled()
                    .textFieldStyle(.roundedBorder)

                Button {
                    let trimmed = tempName.trimmingCharacters(in: .whitespacesAndNewlines)
                    displayName = trimmed.isEmpty ? "Anonymous" : trimmed
                    dismiss()
                } label: {
                    Text("Continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(tempName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                Spacer()
            }
            .padding()
            .navigationTitle("Set Name")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onAppear {
            tempName = displayName
        }
    }
}

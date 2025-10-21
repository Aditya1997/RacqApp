//
//  SessionDetailView.swift
//  Racq App
//

import SwiftUI

struct SessionDetailView: View {
    let session: Session

    var body: some View {
        VStack(spacing: 20) {
            Text("🎾 Session Details")
                .font(.title2)
                .padding(.top)

            VStack(spacing: 10) {
                Text("Shots: \(session.shots)")
                    .font(.headline)
                Text("Duration: \(session.formattedDuration)")
                if let hr = session.averageHR {
                    Text("Average HR: \(hr) bpm")
                }
            }

            Spacer()
        }
        .padding()
        .navigationTitle(session.date.formatted(date: .abbreviated, time: .shortened))
    }
}

#Preview {
    SessionDetailView(session: Session(shots: 42, duration: 300))
}

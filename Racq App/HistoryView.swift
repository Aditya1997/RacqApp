//
//  HistoryView.swift
//  Racq App
//

import SwiftUI

struct HistoryView: View {
    @ObservedObject var store = SessionStoreSingleton.shared

    var body: some View {
        List {
            if store.sessions.isEmpty {
                VStack(spacing: 12) {
                    Text("📭 No Sessions Yet")
                        .font(.headline)
                        .padding(.top, 40)
                    Text("Start a session on your Apple Watch to begin tracking.")
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .center)
            } else {
                ForEach(store.sessions) { session in
                    NavigationLink(destination: SessionDetailView(session: session)) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Shots: \(session.shots)")
                                .font(.headline)
                            Text(session.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("Duration: \(session.formattedDuration)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete(perform: store.delete)
            }
        }
        .navigationTitle("History")
        .onAppear { store.load() }
    }
}

#Preview {
    NavigationStack {
        HistoryView()
    }
}

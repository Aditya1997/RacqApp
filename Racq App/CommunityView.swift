//
//  CommunityView.swift
//  Racq App
//
//  Created by Deets on 10/29/25.
//

import SwiftUI

struct CommunityView: View {
    @StateObject private var store = ChallengeStore()

    var body: some View {
        NavigationView {
            List(store.challenges) { challenge in
                VStack(alignment: .leading, spacing: 8) {
                    Text(challenge.title)
                        .font(.headline)
                    ProgressView(value: Double(challenge.progress),
                                 total: Double(challenge.goal))
                    HStack {
                        Text("\(challenge.progress)/\(challenge.goal)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        Spacer()
                        let pct = Int((Double(challenge.progress) / max(1.0, Double(challenge.goal))) * 100)
                        Text("\(pct)%")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.vertical, 8)
            }
            .navigationTitle("Community Challenges")
            .task { await store.fetchChallenges() }
        }
    }
}

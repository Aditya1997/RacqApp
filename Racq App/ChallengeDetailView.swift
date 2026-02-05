//
//  ChallengeDetailView.swift
//  Racq App
//
//  Created by Deets on 2/4/26.
//


import SwiftUI

struct ChallengeDetailView: View {
    let challenge: Challenge
    @ObservedObject var store: ChallengeStore

    @AppStorage("displayName") private var displayName: String = "Anonymous"
    private var participantId: String { UserIdentity.participantId() }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(challenge.title)
                        .font(.title3.bold())

                    if let sponsor = challenge.sponsor, !sponsor.isEmpty {
                        Text(sponsor)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    ProgressView(value: Double(challenge.progress), total: Double(challenge.goal))

                    HStack {
                        Text("\(challenge.progress)/\(challenge.goal)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)

                        Spacer()

                        Text("\(challengePercent(challenge))%")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                // ✅ Leaderboard now lives here
                ChallengeLeaderboardView(
                    participants: challenge.participants,
                    participantNames: challenge.participantNames,
                    maxRows: 50
                )
            }
            .padding()
        }
        .navigationTitle("Challenge")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func challengePercent(_ challenge: Challenge) -> Int {
        let goal = max(1, challenge.goal)
        let pct = Int((Double(challenge.progress) / Double(goal)) * 100.0)
        return pct
    }
}

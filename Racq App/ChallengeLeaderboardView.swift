//
//  ChallengeLeaderboardView.swift
//  Racq App
//
//  Created by Deets on 1/9/26.
//

import SwiftUI

struct ChallengeLeaderboardView: View {
    let participants: [String: Int]         // participantId -> progress
    let participantNames: [String: String]  // participantId -> displayName
    let maxRows: Int

    init(participants: [String: Int], participantNames: [String: String], maxRows: Int = 3) {
        self.participants = participants
        self.participantNames = participantNames
        self.maxRows = maxRows
    }

    var body: some View {
        let rows = leaderboardRows()

        if rows.isEmpty {
            Text("No participants yet.")
                .font(.caption2)
                .foregroundColor(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("Leaderboard")
                    .font(.caption)
                    .foregroundColor(.secondary)

                ForEach(Array(rows.prefix(maxRows).enumerated()), id: \.offset) { index, row in
                    HStack {
                        Text(rankLabel(index))
                            .font(.caption2)
                            .frame(width: 28, alignment: .leading)

                        Text(row.name)
                            .font(.caption)
                            .lineLimit(1)

                        Spacer()

                        Text("\(row.value)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.top, 6)
        }
    }

    private func leaderboardRows() -> [(name: String, value: Int)] {
        let sorted = participants
            .map { (pid: $0.key, value: $0.value) }
            .sorted { $0.value > $1.value }

        return sorted.map { item in
            let name = participantNames[item.pid] ?? "Unknown"
            return (name: name, value: item.value)
        }
    }

    private func rankLabel(_ index: Int) -> String {
        switch index {
        case 0: return "🥇"
        case 1: return "🥈"
        case 2: return "🥉"
        default: return "#\(index + 1)"
        }
    }
}

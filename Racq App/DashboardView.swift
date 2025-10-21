//
//  DashboardView.swift
//  Racq App
//

import SwiftUI
import Charts

struct DashboardView: View {
    @ObservedObject var store = SessionStoreSingleton.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                Text("📊 Session Dashboard")
                    .font(.title2.bold())
                    .padding(.top)

                if store.sessions.isEmpty {
                    VStack(spacing: 10) {
                        Text("No session data yet")
                            .font(.headline)
                        Text("Start a session on your Apple Watch to see your stats here.")
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 60)
                } else {
                    // MARK: - Summary Stats
                    summarySection

                    // MARK: - Chart Section
                    chartSection
                }

                Spacer()
            }
            .padding()
        }
        .onAppear {
            store.load()
        }
    }

    // MARK: - Summary Section
    private var summarySection: some View {
        let totalShots = store.sessions.reduce(0) { $0 + $1.shots }
        let avgShots = store.sessions.isEmpty ? 0 : totalShots / store.sessions.count
        let avgDuration = store.sessions.isEmpty ? 0 : Int(store.sessions.reduce(0) { $0 + $1.duration } / Double(store.sessions.count))

        return VStack(alignment: .leading, spacing: 8) {
            Text("Summary")
                .font(.headline)

            HStack {
                statCard(title: "Total Shots", value: "\(totalShots)")
                statCard(title: "Avg Shots", value: "\(avgShots)")
                statCard(title: "Avg Duration", value: "\(avgDuration)s")
            }
        }
    }

    // MARK: - Chart Section
    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Shots Over Time")
                .font(.headline)

            Chart(store.sessions) { session in
                BarMark(
                    x: .value("Date", session.date, unit: .day),
                    y: .value("Shots", session.shots)
                )
                .foregroundStyle(.blue.gradient)
            }
            .frame(height: 250)
        }
    }

    // MARK: - Helper UI
    private func statCard(title: String, value: String) -> some View {
        VStack(spacing: 6) {
            Text(value)
                .font(.title3.bold())
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.thinMaterial)
        .cornerRadius(12)
    }
}

#Preview {
    DashboardView()
}


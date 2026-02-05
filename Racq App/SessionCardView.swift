//
//  SessionCardView.swift
//  Racq App
//
//  Created by Deets on 1/30/26.
//

import SwiftUI

struct SessionCardView: View {
    let title: String
    let durationSec: Int
    let avgHR: Double
    let shotCount: Int
    let forehandCount: Int
    let backhandCount: Int

    // speeds come from swings + height
    let swings: [SwingSummaryCSV]
    let userHeightInInches: Double

    // ✅ optional fallback when swings are unavailable (typical for feed posts)
    let fallbackFastestSwing: Double?

    // color variables
    private let cardBG = Color(red: 0.20, green: 0.6, blue: 0.7).opacity(0.4)
    private let outerGradient = LinearGradient(
        colors: [
            Color(red: 0.22, green: 0.56, blue: 0.80).opacity(0.22),
            Color(red: 0.16, green: 0.48, blue: 0.72).opacity(0.30)
        ],
        startPoint: .top,
        endPoint: .bottom
    )

    init(
        title: String,
        durationSec: Int,
        avgHR: Double,
        shotCount: Int,
        forehandCount: Int,
        backhandCount: Int,
        swings: [SwingSummaryCSV],
        userHeightInInches: Double,
        fallbackFastestSwing: Double? = nil
    ) {
        self.title = title
        self.durationSec = durationSec
        self.avgHR = avgHR
        self.shotCount = shotCount
        self.forehandCount = forehandCount
        self.backhandCount = backhandCount
        self.swings = swings
        self.userHeightInInches = userHeightInInches
        self.fallbackFastestSwing = fallbackFastestSwing
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(title)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .center)
                .multilineTextAlignment(.center)
                .padding(.top, 2)

            Image("tennis_court")
                .resizable()
                .scaledToFill()
                .frame(height: 180)
                .overlay(
                    LinearGradient(
                        colors: [.black.opacity(0.05), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .clipShape(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                )

            // MARK: - Combined Speed Card
            CombinedSpeedCard(
                fhTitle: "Forehand Speed (\(forehandCount))",
                fhMaxValue: fhMaxText,
                fhAvgValue: fhAvgText,
                fhRatio: fhRatio,
                fhColor: .blue,
                fhIcon: AnyView(letterIcon("F")),

                bhTitle: "Backhand Speed (\(backhandCount))",
                bhMaxValue: bhMaxText,
                bhAvgValue: bhAvgText,
                bhRatio: bhRatio,
                bhColor: .red,
                bhIcon: AnyView(letterIcon("B"))
            )
            .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 3)

            // MARK: - Summary Blocks
            HStack(spacing: 16) {
                SummaryBlock(
                    title: "Duration",
                    value: format(durationSec),
                    icon: AnyView(Image(systemName: "clock.fill").foregroundColor(.white))
                )
                SummaryBlock(
                    title: "Shots",
                    value: "\(shotCount)",
                    icon: AnyView(Image(systemName: "tennisball.fill").foregroundColor(.white))
                )
                SummaryBlock(
                    title: "Avg HR",
                    value: avgHRText,
                    icon: AnyView(Image(systemName: "heart.fill").foregroundColor(.white))
                )
            }
        }
        .padding(.horizontal, 14)
        .padding(.top, 10)
        .padding(.bottom, 8)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(outerGradient)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
    }

    private var avgHRText: String {
        let bpm = Int(avgHR.rounded())
        return bpm > 0 ? "\(bpm) bpm" : "--"
    }

    private func format(_ sec: Int) -> String {
        let m = sec / 60
        let s = sec % 60
        return String(format: "%02d:%02d", m, s)
    }

    private func letterIcon(_ letter: String) -> some View {
        Text(letter)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(.white)
            .frame(width: 32, height: 32)
            .background(Color.white.opacity(0.25))
            .clipShape(Circle())
    }

    // MARK: - Speed presentation

    private var hasSwings: Bool { !swings.isEmpty }

    private var fallbackMph: Double {
        let v = fallbackFastestSwing ?? 0
        return v > 0 ? v : 0
    }

    private var fhMaxText: String {
        if hasSwings {
            return String(format: "%.0f mph", SwingMath.maxFHSpeed(swings: swings, height: userHeightInInches))
        }
        return fallbackMph > 0 ? String(format: "%.0f mph", fallbackMph) : "--"
    }

    private var bhMaxText: String {
        if hasSwings {
            return String(format: "%.0f mph", SwingMath.maxBHSpeed(swings: swings, height: userHeightInInches))
        }
        return fallbackMph > 0 ? String(format: "%.0f mph", fallbackMph) : "--"
    }

    private var fhAvgText: String {
        if hasSwings {
            return String(format: "%.0f", SwingMath.avgFHSpeed(swings: swings, height: userHeightInInches))
        }
        return "--"
    }

    private var bhAvgText: String {
        if hasSwings {
            return String(format: "%.0f", SwingMath.avgBHSpeed(swings: swings, height: userHeightInInches))
        }
        return "--"
    }

    private var fhRatio: CGFloat {
        if hasSwings {
            let avg = SwingMath.avgFHSpeed(swings: swings, height: userHeightInInches)
            let maxv = max(SwingMath.maxFHSpeed(swings: swings, height: userHeightInInches), 1)
            return CGFloat(avg / maxv)
        }
        return 0
    }

    private var bhRatio: CGFloat {
        if hasSwings {
            let avg = SwingMath.avgBHSpeed(swings: swings, height: userHeightInInches)
            let maxv = max(SwingMath.maxBHSpeed(swings: swings, height: userHeightInInches), 1)
            return CGFloat(avg / maxv)
        }
        return 0
    }
}

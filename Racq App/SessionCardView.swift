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
                fhMaxValue: String(
                    format: "%.0f mph",
                    SwingMath.maxFHSpeed(swings: swings, height: userHeightInInches)
                ),
                fhAvgValue: String(
                    format: "%.0f",
                    SwingMath.avgFHSpeed(swings: swings, height: userHeightInInches)
                ),
                fhRatio: CGFloat(
                    SwingMath.avgFHSpeed(swings: swings, height: userHeightInInches) /
                    max(SwingMath.maxFHSpeed(swings: swings, height: userHeightInInches), 1)
                ),
                fhColor: .blue,
                fhIcon: AnyView(letterIcon("F")),

                bhTitle: "Backhand Speed (\(backhandCount))",
                bhMaxValue: String(
                    format: "%.0f mph",
                    SwingMath.maxBHSpeed(swings: swings, height: userHeightInInches)
                ),
                bhAvgValue: String(
                    format: "%.0f",
                    SwingMath.avgBHSpeed(swings: swings, height: userHeightInInches)
                ),
                bhRatio: CGFloat(
                    SwingMath.avgBHSpeed(swings: swings, height: userHeightInInches) /
                    max(SwingMath.maxBHSpeed(swings: swings, height: userHeightInInches), 1)
                ),
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
}

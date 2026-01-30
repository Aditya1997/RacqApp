//
//  CardViews.swift
//  Racq App
//
//  Created by Deets on 12/11/25.
//

import SwiftUI

private let cardBG = Color(red: 0.20, green: 0.55, blue: 0.75).opacity(0.1)

// MARK: - SummaryBlock (single value)
struct SummaryBlock: View {
    var title: String
    var value: String
    var icon: AnyView? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                if let icon = icon {
                    icon
                        .frame(width: 30, height: 30)
                }
                Spacer()
                Text(value)
                    .foregroundColor(.white)
                    .font(.system(size: 24, weight: .bold))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
            }
            Text(title)
                .foregroundColor(.white.opacity(0.85))
                .font(.system(size: 14, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical,6)
        .padding(.horizontal,6)
        .frame(height: 85)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(cardBG)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.blue.opacity(0.85), lineWidth: 0.75)
        )
        .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 3)
    }
}

// MARK: - Combined Speed Card (max + avg + bar + both hands)

struct CombinedSpeedCard: View {
    var fhTitle: String
    var fhMaxValue: String
    var fhAvgValue: String
    var fhRatio: CGFloat
    var fhColor: Color
    var fhIcon: AnyView? = nil

    var bhTitle: String
    var bhMaxValue: String
    var bhAvgValue: String
    var bhRatio: CGFloat
    var bhColor: Color
    var bhIcon: AnyView? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // forehand row
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(fhTitle)
                            .foregroundColor(.white.opacity(0.75))
                            .font(.subheadline)
                        if let icon = fhIcon {
                            icon
                                .frame(width: 30, height: 30)
                        }
                    }
                    Spacer()
                    Text(fhMaxValue)
                        .foregroundColor(.white)
                        .font(.system(size: 24, weight: .bold))
                }
                // forehand bar
                ZStack(alignment: .leading) {
                    // Background bar (always visible)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 16)
                    GeometryReader { geo in
                        let clamped = max(min(fhRatio, 1), 0)
                        let barWidth = geo.size.width * clamped
                        // Foreground colored bar
                        RoundedRectangle(cornerRadius: 6)
                            .fill(fhColor)
                            .frame(width: barWidth, height: 16)
                    }
                }
                .overlay(
                    Text("\(fhAvgValue) avg")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.leading, 4)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7),
                )
                .frame(maxWidth: .infinity)
                .frame(height: 12)
            }
            //Divider()
            //    .background(Color.white.opacity(0.3))
            // backhand row
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(bhTitle)
                            .foregroundColor(.white.opacity(0.75))
                            .font(.subheadline)
                        if let icon = bhIcon {
                            icon
                                .frame(width: 30, height: 30)
                        }
                    }
                    Spacer()
                    Text(bhMaxValue)
                        .foregroundColor(.white)
                        .font(.system(size: 24, weight: .bold))
                }
                // backhand bar
                ZStack(alignment: .leading) {
                    // Background bar (always visible)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.12))
                        .frame(height: 16)
                    GeometryReader { geo in
                        let clamped = max(min(bhRatio, 1), 0)
                        let barWidth = geo.size.width * clamped
                        // Foreground colored bar
                        RoundedRectangle(cornerRadius: 6)
                            .fill(bhColor)
                            .frame(width: barWidth, height: 16)
                    }
                }
                .overlay(
                    Text("\(bhAvgValue) avg")
                        .font(.caption2)
                        .foregroundColor(.white)
                        .padding(.leading, 4)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7),
                )
                .frame(maxWidth: .infinity)
                .frame(height: 12)
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous).fill(cardBG)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(Color.blue.opacity(0.85), lineWidth: 0.75)
        )
        .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
    }
}

// MARK: - One Hand Speed (max + avg + bar)

struct OneHandSpeedCard: View {
    var title: String
    var maxValue: String
    var avgValue: String
    var avgRatio: CGFloat
    var barColor: Color = .blue
    var icon: AnyView? = nil
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Title + Max Value Row
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text(title)
                        .foregroundColor(.white.opacity(0.75))
                        .font(.subheadline)
                    if let icon = icon {
                        icon.frame(width: 30, height: 30)
                    }
                }
                Spacer()
                Text(maxValue)
                    .foregroundColor(.white)
                    .font(.system(size: 28, weight: .bold))
            }
            // Avg Bar
            VStack(alignment: .leading, spacing: 6) {
                // Background bar
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.12))
                    .frame(height: 8)
                    .overlay(
                        // Foreground bar
                        GeometryReader { geo in
                            let clamped = max(min(avgRatio, 1), 0)
                            RoundedRectangle(cornerRadius: 6)
                                .fill(barColor)
                                .frame(width: geo.size.width * clamped)
                        }
                    )
                Text("\(avgValue) avg")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)
    }
}




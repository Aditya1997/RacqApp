//
//  CardViews.swift
//  Racq App
//
//  Created by Deets on 12/11/25.
//

import SwiftUI

// MARK: - SummaryCard (single value)

struct SummaryCard: View {
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
        .padding(.horizontal,12)
        .frame(height: 85)
        .background(
            RoundedRectangle(cornerRadius: 15).fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15).stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.35), radius: 6, x: 0, y: 3)
    }
}


// MARK: - DualMetricCard (max + avg + bar)

struct DualMetricCard: View {
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

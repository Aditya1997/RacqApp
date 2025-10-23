//
//  DebugOverlayView.swift
//  RacqWatch Watch App
//

import SwiftUI

struct DebugOverlayView: View {
    @ObservedObject private var motionManager = MotionManager.shared
    @State private var showDetails = false

    var body: some View {
        VStack(spacing: 8) {
            Button {
                showDetails.toggle()
            } label: {
                Text(showDetails ? "Hide Debug" : "Show Debug")
                    .font(.caption)
                    .padding(6)
                    .background(Color.gray.opacity(0.2))
                    .cornerRadius(8)
            }

            if showDetails {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Debug Info")
                        .font(.headline)

                    Text("Shots: \(motionManager.shotCount)")
                    Text(String(format: "Magnitude: %.2f", motionManager.lastMagnitude))
                    Text("Sensitivity: \(motionManager.motionSensitivity, specifier: "%.2f")")
                    Text("Active: \(motionManager.isActive ? "Yes" : "No")")

                    Button("Reset Shots") {
                        motionManager.shotCount = 0
                    }
                    .buttonStyle(.bordered)
                    .tint(.red)
                }
                .padding(8)
                .background(Color.black.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(6)
    }
}

#Preview {
    DebugOverlayView()
}

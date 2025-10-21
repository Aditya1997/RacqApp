//
//  DebugOverlayView.swift
//  RacqWatch Watch App
//

import SwiftUI

struct DebugOverlayView: View {
    @ObservedObject private var motion = MotionManager.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("📊 Debug Overlay")
                .font(.system(size: 12, weight: .semibold))
            Text("Shots: \(motion.shotCount)")
                .font(.system(size: 11))
            Text(String(format: "Mag: %.2f", motion.lastMagnitude))
                .font(.system(size: 11))
            Text(String(format: "Sens: %.2f", motion.motionSensitivity))
                .font(.system(size: 11))
            Text(motion.isActive ? "Active ✅" : "Stopped ⛔️")
                .font(.system(size: 11))
                .foregroundColor(motion.isActive ? .green : .red)
        }
        .padding(6)
        .background(Color.black.opacity(0.3))
        .cornerRadius(8)
    }
}

#Preview {
    DebugOverlayView()
}

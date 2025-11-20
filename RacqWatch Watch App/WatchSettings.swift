//
//  WatchSettings.swift
//  RacqWatch Watch App
//
//  Created by Brian on 10/21/25.
//

import Foundation
import SwiftUI
import Combine

/// Centralized, persistent settings on Watch.
/// Values mirror iPhone Settings and are updated via WatchConnectivity.
@MainActor
final class WatchSettings: ObservableObject {
    static let shared = WatchSettings()

    @AppStorage("smoothedMagnitudeLimit") var smoothedMagnitudeLimit: Double = 1.9   // 0.1 ... 3.0
    @AppStorage("hapticsEnabled")    var hapticsEnabled: Bool   = true
    @AppStorage("hrEnabled")         var hrEnabled: Bool        = false

    /// Apply payload coming from iPhone Settings
    func apply(payload: [String: String]) {
        if let s = payload["smoothedMagnitudeLimit"], let v = Double(s) { smoothedMagnitudeLimit = v }
        if let s = payload["hapticsEnabled"], let v = Bool(s)      { hapticsEnabled = v }
        if let s = payload["hrEnabled"], let v = Bool(s)           { hrEnabled = v }
        objectWillChange.send()
        print("⚙️ Watch settings updated: sensitivity=\(smoothedMagnitudeLimit), haptics=\(hapticsEnabled), hr=\(hrEnabled)")
    }
}


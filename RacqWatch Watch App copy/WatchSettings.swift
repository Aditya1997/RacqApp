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

    @AppStorage("motionSensitivity") var motionSensitivity: Double = 0.5   // 0.1 ... 1.0
    @AppStorage("hapticsEnabled")    var hapticsEnabled: Bool   = true
    @AppStorage("hrEnabled")         var hrEnabled: Bool        = false

    /// Apply payload coming from iPhone Settings
    func apply(payload: [String: String]) {
        if let s = payload["motionSensitivity"], let v = Double(s) { motionSensitivity = v }
        if let s = payload["hapticsEnabled"], let v = Bool(s)      { hapticsEnabled = v }
        if let s = payload["hrEnabled"], let v = Bool(s)           { hrEnabled = v }
        objectWillChange.send()
        print("⚙️ Watch settings updated: sensitivity=\(motionSensitivity), haptics=\(hapticsEnabled), hr=\(hrEnabled)")
    }
}


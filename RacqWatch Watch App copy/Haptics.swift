//
//  Haptics.swift
//  RacqWatch Watch App
//
//  Created by Brian on 10/21/25.
//

import WatchKit

enum Haptics {
    static func hit()  { WKInterfaceDevice.current().play(.success) }
    static func tick() { WKInterfaceDevice.current().play(.click) }
}


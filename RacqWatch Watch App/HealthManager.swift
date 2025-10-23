//
//  HealthManager.swift
//  RacqWatch Watch App
//

import Foundation
import HealthKit
import Combine

@MainActor
final class HealthManager: ObservableObject {
    static let shared = HealthManager()

    private let healthStore = HKHealthStore()
    private var query: HKAnchoredObjectQuery?

    @Published var heartRate: Double = 0.0

    private init() {}   // ✅ removed 'override'

    // MARK: - Request authorization
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set = [HKQuantityType.quantityType(forIdentifier: .heartRate)!]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if !success {
                print("❌ HealthKit authorization failed: \(error?.localizedDescription ?? "unknown")")
            } else {
                print("✅ HealthKit authorization granted")
            }
        }
    }

    // MARK: - Start live heart rate updates
    func startHeartRateUpdates() {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)

        query = HKAnchoredObjectQuery(type: heartRateType,
                                      predicate: predicate,
                                      anchor: nil,
                                      limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, _, _ in
            self?.handleSamples(samples)
        }

        query?.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.handleSamples(samples)
        }

        if let q = query {
            healthStore.execute(q)
            print("❤️ Started live heart rate updates")
        }
    }

    // MARK: - Stop updates
    func stopHeartRateUpdates() {
        if let q = query {
            healthStore.stop(q)
            query = nil
            print("🛑 Stopped heart rate updates")
        }
    }

    // MARK: - Handle heart rate samples
    nonisolated private func handleSamples(_ samples: [HKSample]?) {  // ✅ added 'nonisolated'
        guard let hrSamples = samples as? [HKQuantitySample], !hrSamples.isEmpty else { return }

        let unit = HKUnit(from: "count/min")
        let latest = hrSamples.last!.quantity.doubleValue(for: unit)

        // hop back to main actor to update UI
        Task { @MainActor in
            self.heartRate = latest
        }
    }
}

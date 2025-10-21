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
    private var heartRateLog: [(time: Date, bpm: Double)] = []

    private init() {}

    // MARK: - Authorization
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("⚠️ Health data unavailable.")
            return
        }

        let typesToRead: Set = [HKQuantityType.quantityType(forIdentifier: .heartRate)!]
        let typesToShare: Set = [HKQuantityType.workoutType()]

        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { success, error in
            if success {
                print("✅ HealthKit authorized.")
            } else {
                print("❌ HealthKit error:", error?.localizedDescription ?? "unknown")
            }
        }
    }

    // MARK: - Heart Rate Monitoring
    func startHeartRateUpdates() {
        guard let type = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)

        query = HKAnchoredObjectQuery(
            type: type,
            predicate: predicate,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.process(samples)
            }
        }

        query?.updateHandler = { [weak self] _, samples, _, _, _ in
            guard let self = self else { return }
            Task { @MainActor in
                self.process(samples)
            }
        }

        if let query = query {
            healthStore.execute(query)
            print("❤️ Started heart rate updates.")
        }
    }

    func stopHeartRateUpdates() {
        if let query = query {
            healthStore.stop(query)
            print("🛑 Stopped heart rate updates.")
        }
        query = nil
    }

    // MARK: - Handle heart rate samples safely on main thread
    private func process(_ samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample], let sample = samples.last else { return }

        let bpm = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
        heartRate = bpm
        heartRateLog.append((time: Date(), bpm: bpm))
    }

    func clearLogs() {
        heartRateLog.removeAll()
    }
}

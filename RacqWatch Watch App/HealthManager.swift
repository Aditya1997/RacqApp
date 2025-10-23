//
//  HealthManager.swift
//  RacqWatch Watch App
//

import Foundation
import HealthKit
import Combine

@MainActor
final class HealthManager: NSObject, ObservableObject {
    static let shared = HealthManager()

    @Published var heartRate: Double = 0
    @Published var isWorkoutActive = false
    @Published var workoutStartDate: Date?

    private let healthStore = HKHealthStore()
    private var session: HKWorkoutSession?
    private var builder: HKLiveWorkoutBuilder?
    private var hrQuery: HKAnchoredObjectQuery?

    private override init() {
        super.init()
    }

    // MARK: - Authorization
    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        let typesToShare: Set = [HKObjectType.workoutType()]
        let typesToRead: Set = [HKQuantityType.quantityType(forIdentifier: .heartRate)!]

        do {
            try await healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead)
        } catch {
            print("❌ Health authorization error: \(error)")
        }
    }

    // MARK: - Start Workout
    func startWorkout() async {
        if isWorkoutActive { return }

        let config = HKWorkoutConfiguration()
        config.activityType = .tennis
        config.locationType = .outdoor

        do {
            session = try HKWorkoutSession(healthStore: healthStore, configuration: config)
            builder = session?.associatedWorkoutBuilder()
            session?.delegate = self
            builder?.delegate = self
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: config)

            workoutStartDate = Date()
            session?.startActivity(with: workoutStartDate!)
            builder?.beginCollection(withStart: workoutStartDate!) { _, _ in }

            startHeartRateStream()
            isWorkoutActive = true
            print("🏃‍♂️ Workout started")
        } catch {
            print("❌ Failed to start workout: \(error)")
        }
    }

    // MARK: - Stop Workout
    func stopWorkout() async {
        guard isWorkoutActive else { return }

        hrQuery.map { healthStore.stop($0) }
        hrQuery = nil
        builder?.endCollection(withEnd: Date()) { [weak self] _, _ in
            guard let self else { return }
            Task { @MainActor in
                self.builder?.finishWorkout { _, _ in }
            }
        }

        session?.end()
        isWorkoutActive = false
        print("🛑 Workout stopped")

        // Export and send CSV via SensorLogger (for consistent data)
        SensorLogger.shared.stopLoggingAndExport()
    }

    // MARK: - Heart Rate Stream
    private func startHeartRateStream() {
        let hrType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let predicate = HKQuery.predicateForSamples(withStart: Date(), end: nil, options: .strictStartDate)

        hrQuery = HKAnchoredObjectQuery(type: hrType, predicate: predicate, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] _, samples, _, _, _ in
            Task { @MainActor in self?.handleHeartRate(samples: samples) }
        }

        hrQuery?.updateHandler = { [weak self] _, samples, _, _, _ in
            Task { @MainActor in self?.handleHeartRate(samples: samples) }
        }

        if let q = hrQuery { healthStore.execute(q) }
    }

    private func handleHeartRate(samples: [HKSample]?) {
        guard let samples = samples as? [HKQuantitySample],
              let last = samples.last else { return }

        let bpm = last.quantity.doubleValue(for: .init(from: "count/min"))
        heartRate = bpm
        print("❤️ Heart Rate: \(Int(bpm)) BPM")
    }
}

// MARK: - Delegates
extension HealthManager: HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                    didChangeTo toState: HKWorkoutSessionState,
                                    from _: HKWorkoutSessionState,
                                    date: Date) {
        print("Workout state → \(toState.rawValue) at \(date)")
    }

    nonisolated func workoutSession(_ workoutSession: HKWorkoutSession,
                                    didFailWithError error: Error) {
        print("Workout error: \(error)")
    }

    nonisolated func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {}
    nonisolated func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder,
                                    didCollectDataOf collectedTypes: Set<HKSampleType>) {}
}

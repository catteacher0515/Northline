import Foundation
import SwiftUI

enum StressManagementPage: Equatable {
    case home
    case resetChecklist
    case resetResult
    case measurement
}

@MainActor
final class StressManagementViewModel: ObservableObject {
    @Published var page: StressManagementPage = .home
    @Published private(set) var resetAnswers: [Int: Bool] = [:]
    @Published private(set) var measurementScores: [Int: Int] = [:]
    @Published private(set) var currentResetRecord: StressResetRecord?
    @Published private(set) var latestMeasurementRecord: StressMeasurementRecord?

    private let store: StressManagementStore

    init(store: StressManagementStore = StressManagementStore()) {
        self.store = store
        refreshSnapshot()
    }

    var latestResetSummary: String {
        currentResetRecord?.matchedResetLevel?.title ?? "还没有即时重置记录"
    }

    var latestMeasurementSummary: String {
        guard let latestMeasurementRecord else {
            return "还没有压力测量记录"
        }

        return "\(latestMeasurementRecord.totalScore) 分 · \(latestMeasurementRecord.pressureLevel.title)"
    }

    var measurementHistory: [StressMeasurementRecord] {
        store.snapshot().measurementHistory
    }

    func startResetChecklist() {
        resetAnswers = Dictionary(
            uniqueKeysWithValues: StressResetQuestion.allCases.map { ($0.rawValue, false) }
        )
        page = .resetChecklist
    }

    func updateResetAnswer(for question: StressResetQuestion, value: Bool) {
        resetAnswers[question.rawValue] = value
    }

    func submitResetChecklist(now: Date = Date()) {
        let matchedLevel = StressManagementStore.matchedResetLevel(for: resetAnswers)
        let record = StressResetRecord(
            createdAt: now,
            answers: resetAnswers,
            matchedResetLevel: matchedLevel,
            completed: true
        )
        store.saveResetRecord(record)
        currentResetRecord = record
        page = .resetResult
    }

    func deleteCurrentResetRecord() {
        guard let currentResetRecord else {
            return
        }

        store.deleteResetRecord(id: currentResetRecord.id)
        refreshSnapshot()
        page = .home
    }

    func startMeasurement() {
        measurementScores = Dictionary(
            uniqueKeysWithValues: StressMeasurementQuestion.allCases.map { ($0.rawValue, 0) }
        )
        page = .measurement
    }

    func updateMeasurementScore(for question: StressMeasurementQuestion, value: Int) {
        measurementScores[question.rawValue] = min(4, max(0, value))
    }

    func submitMeasurement(now: Date = Date()) {
        let record = StressMeasurementRecord(
            id: UUID(),
            createdAt: now,
            scores: measurementScores
        )
        store.saveMeasurementRecord(record)
        latestMeasurementRecord = record
    }

    func goHome() {
        refreshSnapshot()
        page = .home
    }

    private func refreshSnapshot() {
        let snapshot = store.snapshot()
        currentResetRecord = snapshot.latestResetRecord
        latestMeasurementRecord = snapshot.latestMeasurementRecord
    }
}

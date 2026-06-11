import Foundation

struct StressManagementSnapshot: Equatable {
    let latestResetRecord: StressResetRecord?
    let latestMeasurementRecord: StressMeasurementRecord?
    let measurementHistory: [StressMeasurementRecord]
}

final class StressManagementStore {
    private static let resetFileName = "stress-reset-records.json"
    private static let measurementFileName = "stress-measurement-records.json"

    private var resetRecords: [StressResetRecord]
    private var measurementRecords: [StressMeasurementRecord]

    init() {
        resetRecords = LocalJSONStore.load([StressResetRecord].self, from: Self.resetFileName) ?? []
        measurementRecords = LocalJSONStore.load([StressMeasurementRecord].self, from: Self.measurementFileName) ?? []
    }

    func saveResetRecord(_ record: StressResetRecord) {
        resetRecords.append(record)
        persistResetRecords()
    }

    func deleteResetRecord(id: UUID) {
        resetRecords.removeAll { $0.id == id }
        persistResetRecords()
    }

    func saveMeasurementRecord(_ record: StressMeasurementRecord) {
        measurementRecords.append(record)
        persistMeasurementRecords()
    }

    func snapshot() -> StressManagementSnapshot {
        StressManagementSnapshot(
            latestResetRecord: resetRecords.sorted { $0.createdAt > $1.createdAt }.first,
            latestMeasurementRecord: measurementRecords.sorted { $0.createdAt > $1.createdAt }.first,
            measurementHistory: measurementRecords.sorted { $0.createdAt > $1.createdAt }
        )
    }

    static func matchedResetLevel(for answers: [Int: Bool]) -> StressResetLevel? {
        StressResetLevel.allCases.sorted { $0.priority < $1.priority }.first { level in
            StressResetQuestion.allCases
                .filter { $0.level == level }
                .contains { answers[$0.rawValue] == true }
        }
    }

    private func persistResetRecords() {
        LocalJSONStore.save(resetRecords, to: Self.resetFileName)
    }

    private func persistMeasurementRecords() {
        LocalJSONStore.save(measurementRecords, to: Self.measurementFileName)
    }
}

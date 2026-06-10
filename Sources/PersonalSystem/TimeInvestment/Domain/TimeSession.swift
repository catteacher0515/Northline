import Foundation

struct TimeSession: Codable, Equatable {
    var id: UUID
    var startAt: Date
    var endAt: Date
    var referenceDurationSeconds: Int
    var classificationRawValue: String
    var productionNote: String?
    var endedByUser: Bool

    init(
        id: UUID = UUID(),
        startAt: Date,
        endAt: Date,
        referenceDurationSeconds: Int,
        classification: SessionClassification,
        productionNote: String?,
        endedByUser: Bool
    ) {
        self.id = id
        self.startAt = startAt
        self.endAt = endAt
        self.referenceDurationSeconds = referenceDurationSeconds
        self.classificationRawValue = classification.rawValue
        self.productionNote = productionNote
        self.endedByUser = endedByUser
    }

    var classification: SessionClassification {
        get { SessionClassification(rawValue: classificationRawValue) ?? .consumption }
        set { classificationRawValue = newValue.rawValue }
    }

    var durationSeconds: Int {
        max(0, Int(endAt.timeIntervalSince(startAt)))
    }

    func normalizedForPersistence() -> TimeSession {
        let note = productionNote?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard classification == .production, note.isEmpty == false else {
            return TimeSession(
                id: id,
                startAt: startAt,
                endAt: endAt,
                referenceDurationSeconds: referenceDurationSeconds,
                classification: .consumption,
                productionNote: nil,
                endedByUser: endedByUser
            )
        }

        return TimeSession(
            id: id,
            startAt: startAt,
            endAt: endAt,
            referenceDurationSeconds: referenceDurationSeconds,
            classification: .production,
            productionNote: productionNote,
            endedByUser: endedByUser
        )
    }
}

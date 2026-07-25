import Foundation

struct TimeSession: Codable, Equatable {
    var id: UUID
    var startAt: Date
    var endAt: Date
    var referenceDurationSeconds: Int
    var roundedDurationSeconds: Int?
    var taskName: String?
    var categoryRawValue: String?
    var joyScore: Int?
    var meaningScore: Int?
    var note: String?
    var classificationRawValue: String
    var productionNote: String?
    var endedByUser: Bool

    init(
        id: UUID = UUID(),
        startAt: Date,
        endAt: Date,
        referenceDurationSeconds: Int,
        taskName: String,
        category: TimeSessionCategory,
        joyScore: Int?,
        meaningScore: Int?,
        note: String?,
        endedByUser: Bool
    ) {
        self.id = id
        self.startAt = startAt
        self.endAt = endAt
        self.referenceDurationSeconds = referenceDurationSeconds
        self.roundedDurationSeconds = Self.roundedQuarterHourSeconds(from: startAt, to: endAt)
        self.taskName = taskName
        self.categoryRawValue = category.rawValue
        self.joyScore = joyScore
        self.meaningScore = meaningScore
        self.note = note
        self.classificationRawValue = category.legacyClassification.rawValue
        self.productionNote = note
        self.endedByUser = endedByUser
    }

    init(
        id: UUID = UUID(),
        startAt: Date,
        endAt: Date,
        referenceDurationSeconds: Int,
        classification: SessionClassification,
        productionNote: String?,
        endedByUser: Bool
    ) {
        let legacyTaskName = productionNote ?? classification.rawValue
        let category: TimeSessionCategory = classification == .production ? .studyWork : .other
        self.init(
            id: id,
            startAt: startAt,
            endAt: endAt,
            referenceDurationSeconds: referenceDurationSeconds,
            taskName: legacyTaskName,
            category: category,
            joyScore: nil,
            meaningScore: nil,
            note: productionNote,
            endedByUser: endedByUser
        )
        self.classificationRawValue = classification.rawValue
    }

    var classification: SessionClassification {
        get {
            if let categoryRawValue,
               let category = TimeSessionCategory(rawValue: categoryRawValue) {
                return category.legacyClassification
            }

            return SessionClassification(rawValue: classificationRawValue) ?? .consumption
        }
        set { classificationRawValue = newValue.rawValue }
    }

    var category: TimeSessionCategory {
        get {
            guard let categoryRawValue else {
                return classification == .production ? .studyWork : .other
            }
            return TimeSessionCategory(rawValue: categoryRawValue) ?? .other
        }
        set {
            categoryRawValue = newValue.rawValue
            classificationRawValue = newValue.legacyClassification.rawValue
        }
    }

    var durationSeconds: Int {
        max(0, Int(endAt.timeIntervalSince(startAt)))
    }

    var roundedSeconds: Int {
        roundedDurationSeconds ?? Self.roundedQuarterHourSeconds(from: startAt, to: endAt)
    }

    func normalizedForPersistence() -> TimeSession {
        let trimmedTaskName = taskName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let trimmedNote = note?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? productionNote?.trimmingCharacters(in: .whitespacesAndNewlines)
            ?? ""
        let normalizedTaskName = trimmedTaskName.isEmpty ? "未命名" : trimmedTaskName
        let normalizedCategory = trimmedTaskName.isEmpty ? TimeSessionCategory.other : category
        let normalizedJoyScore = Self.clampedScore(joyScore)
        let normalizedMeaningScore = Self.clampedScore(meaningScore)
        let normalizedNote = trimmedNote.isEmpty ? nil : trimmedNote

        var normalized = TimeSession(
            id: id,
            startAt: startAt,
            endAt: endAt,
            referenceDurationSeconds: referenceDurationSeconds,
            taskName: normalizedTaskName,
            category: normalizedCategory,
            joyScore: normalizedJoyScore,
            meaningScore: normalizedMeaningScore,
            note: normalizedNote,
            endedByUser: endedByUser
        )
        normalized.roundedDurationSeconds = Self.roundedQuarterHourSeconds(from: startAt, to: endAt)
        normalized.productionNote = normalizedNote
        return normalized
    }

    static func roundedQuarterHourSeconds(from startAt: Date, to endAt: Date) -> Int {
        let duration = max(0, Int(endAt.timeIntervalSince(startAt)))
        let quarter = 15 * 60
        return Int((Double(duration) / Double(quarter)).rounded()) * quarter
    }

    private static func clampedScore(_ score: Int?) -> Int? {
        guard let score else {
            return nil
        }

        return min(10, max(1, score))
    }
}

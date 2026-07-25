import Foundation

struct SessionDraftResult: Equatable {
    let taskName: String
    let category: TimeSessionCategory?
    let joyScore: Int?
    let meaningScore: Int?
    let note: String?

    init(
        taskName: String,
        category: TimeSessionCategory? = nil,
        joyScore: Int? = nil,
        meaningScore: Int? = nil,
        note: String? = nil
    ) {
        self.taskName = taskName
        self.category = category
        self.joyScore = joyScore
        self.meaningScore = meaningScore
        self.note = note
    }

    static func production(note: String) -> SessionDraftResult {
        SessionDraftResult(
            taskName: note.isEmpty ? "生产" : note,
            category: .studyWork,
            note: note
        )
    }

    static var consumption: SessionDraftResult {
        SessionDraftResult(taskName: "消费", category: .other)
    }

    func makeSession(
        startAt: Date,
        endAt: Date,
        referenceDurationSeconds: Int
    ) -> TimeSession {
        let trimmedTaskName = taskName.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedCategory = category ?? TimeSessionCategory.classify(taskName: trimmedTaskName)
        return TimeSession(
            startAt: startAt,
            endAt: endAt,
            referenceDurationSeconds: referenceDurationSeconds,
            taskName: trimmedTaskName,
            category: resolvedCategory,
            joyScore: joyScore,
            meaningScore: meaningScore,
            note: note,
            endedByUser: true
        ).normalizedForPersistence()
    }
}

import Foundation

struct StressResetRecord: Codable, Equatable, Identifiable {
    var id: UUID
    var createdAt: Date
    var answers: [Int: Bool]
    var matchedResetLevelRawValue: String?
    var completed: Bool

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        answers: [Int: Bool],
        matchedResetLevel: StressResetLevel?,
        completed: Bool = true
    ) {
        self.id = id
        self.createdAt = createdAt
        self.answers = answers
        self.matchedResetLevelRawValue = matchedResetLevel?.rawValue
        self.completed = completed
    }

    var matchedResetLevel: StressResetLevel? {
        get {
            guard let matchedResetLevelRawValue else {
                return nil
            }

            return StressResetLevel(rawValue: matchedResetLevelRawValue)
        }
        set {
            matchedResetLevelRawValue = newValue?.rawValue
        }
    }
}

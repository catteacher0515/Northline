import Foundation

struct ReviewSummary: Equatable {
    let totalSeconds: Int
    let productionSeconds: Int
    let consumptionSeconds: Int

    var productionRatio: Double {
        guard totalSeconds > 0 else {
            return 0
        }

        return Double(productionSeconds) / Double(totalSeconds)
    }
}

struct ReviewDayRow: Equatable, Identifiable {
    let date: Date
    let productionSeconds: Int
    let consumptionSeconds: Int

    var id: Date { date }
    var totalSeconds: Int { productionSeconds + consumptionSeconds }
}

struct ReviewProductionNoteRow: Equatable, Identifiable {
    let sessionID: UUID
    let endAt: Date
    let durationSeconds: Int
    let note: String

    var id: UUID { sessionID }
}

struct ReviewSnapshot: Equatable {
    let range: ReviewRange
    let interval: DateInterval
    let summary: ReviewSummary
    let dailyRows: [ReviewDayRow]
    let recentProductionNotes: [ReviewProductionNoteRow]
}

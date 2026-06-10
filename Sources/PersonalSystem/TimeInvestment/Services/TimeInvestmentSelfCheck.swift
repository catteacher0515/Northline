import Darwin
import Foundation

enum TimeInvestmentSelfCheck {
    static func runAndExit() -> Never {
        do {
            try verifyDailyTotals()
            try verifyProductionNoteNormalization()
            print("TimeInvestment self-check passed")
            Darwin.exit(0)
        } catch {
            fputs("TimeInvestment self-check failed: \(error)\n", stderr)
            Darwin.exit(1)
        }
    }

    private static func verifyDailyTotals() throws {
        let calendar = Calendar(identifier: .gregorian)
        let startOfDay = calendar.startOfDay(for: Date(timeIntervalSince1970: 1_718_000_000))
        let production = TimeSession(
            startAt: startOfDay,
            endAt: startOfDay.addingTimeInterval(1_800),
            referenceDurationSeconds: 1_500,
            classification: .production,
            productionNote: "Wrote implementation notes",
            endedByUser: true
        )
        let consumption = TimeSession(
            startAt: startOfDay.addingTimeInterval(2_000),
            endAt: startOfDay.addingTimeInterval(3_200),
            referenceDurationSeconds: 1_500,
            classification: .consumption,
            productionNote: nil,
            endedByUser: true
        )

        let totals = TimeSessionStore.dailyTotals(
            sessions: [production, consumption],
            now: startOfDay.addingTimeInterval(4_000),
            calendar: calendar
        )

        try expect(totals.productionSeconds == 1_800, "production total should be 1800 seconds")
        try expect(totals.consumptionSeconds == 1_200, "consumption total should be 1200 seconds")
    }

    private static func verifyProductionNoteNormalization() throws {
        let session = TimeSession(
            startAt: Date(timeIntervalSince1970: 100),
            endAt: Date(timeIntervalSince1970: 400),
            referenceDurationSeconds: 1_500,
            classification: .production,
            productionNote: "  shipped dashboard copy  ",
            endedByUser: true
        )

        let normalized = session.normalizedForPersistence()

        try expect(normalized.classification == .production, "production note should preserve production classification")
        try expect(normalized.productionNote == "shipped dashboard copy", "production note should be trimmed")

        let emptyProduction = TimeSession(
            startAt: Date(timeIntervalSince1970: 100),
            endAt: Date(timeIntervalSince1970: 400),
            referenceDurationSeconds: 1_500,
            classification: .production,
            productionNote: "   ",
            endedByUser: true
        ).normalizedForPersistence()

        try expect(emptyProduction.classification == .consumption, "empty production note should downgrade to consumption")
        try expect(emptyProduction.productionNote == nil, "downgraded consumption session should clear production note")
    }

    private static func expect(_ condition: @autoclosure () -> Bool, _ message: String) throws {
        guard condition() else {
            throw SelfCheckError(message: message)
        }
    }
}

private struct SelfCheckError: LocalizedError {
    let message: String

    var errorDescription: String? {
        message
    }
}

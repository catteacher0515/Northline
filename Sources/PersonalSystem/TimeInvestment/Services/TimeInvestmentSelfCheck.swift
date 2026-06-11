import Darwin
import Foundation

enum TimeInvestmentSelfCheck {
    static func runAndExit() -> Never {
        do {
            try verifyDailyTotals()
            try verifyProductionNoteNormalization()
            try verifyReviewRangeBoundaries()
            try verifyReviewSnapshotAggregation()
            try verifyReviewViewModelState()
            try verifyStressManagementDomain()
            try verifyLocalPersistenceRoundTrip()
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

    private static func verifyReviewRangeBoundaries() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 1_718_020_000)

        let today = ReviewRange.today.dateInterval(now: now, calendar: calendar)
        try expect(calendar.isDate(today.start, inSameDayAs: now), "today range should start on the same local day")
        try expect(today.duration == 86_400, "today range should cover one full day")

        let customStart = Date(timeIntervalSince1970: 1_717_800_000)
        let customEnd = Date(timeIntervalSince1970: 1_717_972_800)
        let custom = ReviewRange.custom(start: customStart, end: customEnd).dateInterval(now: now, calendar: calendar)
        try expect(custom.start == customStart, "custom range should preserve explicit start")
        try expect(custom.end == customEnd, "custom range should preserve explicit end")
    }

    private static func verifyReviewSnapshotAggregation() throws {
        let calendar = Calendar(identifier: .gregorian)
        let now = Date(timeIntervalSince1970: 1_718_020_000)
        let dayOne = calendar.startOfDay(for: now)
        let dayTwo = calendar.date(byAdding: .day, value: 1, to: dayOne) ?? dayOne

        let sessions = [
            TimeSession(
                id: UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeee1") ?? UUID(),
                startAt: dayOne.addingTimeInterval(1_200),
                endAt: dayOne.addingTimeInterval(4_800),
                referenceDurationSeconds: 1_500,
                classification: .production,
                productionNote: "drafted article",
                endedByUser: true
            ),
            TimeSession(
                id: UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeee2") ?? UUID(),
                startAt: dayOne.addingTimeInterval(8_000),
                endAt: dayOne.addingTimeInterval(9_800),
                referenceDurationSeconds: 1_500,
                classification: .consumption,
                productionNote: nil,
                endedByUser: true
            ),
            TimeSession(
                id: UUID(uuidString: "aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeee3") ?? UUID(),
                startAt: dayTwo.addingTimeInterval(1_000),
                endAt: dayTwo.addingTimeInterval(3_400),
                referenceDurationSeconds: 1_500,
                classification: .production,
                productionNote: "recorded notes",
                endedByUser: true
            )
        ]

        let snapshot = TimeSessionStore.reviewSnapshot(
            sessions: sessions,
            range: .custom(start: dayOne, end: dayTwo.addingTimeInterval(86_400)),
            now: now,
            calendar: calendar
        )

        try expect(snapshot.summary.totalSeconds == 7_800, "summary should include total duration")
        try expect(snapshot.summary.productionSeconds == 6_000, "summary should include production duration")
        try expect(snapshot.summary.consumptionSeconds == 1_800, "summary should include consumption duration")
        try expect(snapshot.dailyRows.count == 2, "daily rows should include each day in the range")
        try expect(snapshot.recentProductionNotes.count == 2, "recent production notes should include production sessions only")
        try expect(snapshot.recentProductionNotes.first?.note == "recorded notes", "recent production notes should be reverse chronological")
    }

    private static func verifyReviewViewModelState() throws {
        try MainActor.assumeIsolated {
            let calendar = Calendar(identifier: .gregorian)
            let now = Date(timeIntervalSince1970: 1_718_020_000)
            let start = calendar.startOfDay(for: now)
            let session = TimeSession(
                startAt: start.addingTimeInterval(1_200),
                endAt: start.addingTimeInterval(4_800),
                referenceDurationSeconds: 1_500,
                classification: .production,
                productionNote: "wrote review logic",
                endedByUser: true
            )

            let store = InMemoryTimeSessionStore(seedSessions: [session])
            let viewModel = TimeInvestmentViewModel(
                store: store,
                timer: SessionTimer(),
                referenceDurationSeconds: 1_500
            )

            try expect(viewModel.selectedTab == .record, "default tab should be record")
            viewModel.selectedTab = .review
            viewModel.selectReviewRange(.today)

            let snapshot = viewModel.reviewSnapshot(now: now, calendar: calendar)
            try expect(viewModel.selectedTab == .review, "tab selection should persist")
            try expect(snapshot.summary.productionSeconds == 3_600, "review snapshot should come from the injected store")
            try expect(snapshot.range == .today, "review snapshot should preserve the selected range")
        }
    }

    private static func verifyStressManagementDomain() throws {
        try expect(StressResetQuestion.allCases.count == 10, "stress reset should expose 10 checklist questions")
        try expect(StressMeasurementQuestion.allCases.count == 5, "stress measurement should expose 5 monthly questions")
        try expect(StressResetLevel.first.priority < StressResetLevel.second.priority, "reset levels should preserve recovery order")
    }

    private static func verifyLocalPersistenceRoundTrip() throws {
        let directory = try LocalJSONStore.applicationSupportDirectory()
        let sessionsURL = directory.appendingPathComponent("sessions.json")
        let backupURL = directory.appendingPathComponent("sessions.self-check.backup.json")
        let fileManager = FileManager.default

        if fileManager.fileExists(atPath: backupURL.path) {
            try fileManager.removeItem(at: backupURL)
        }

        if fileManager.fileExists(atPath: sessionsURL.path) {
            try fileManager.copyItem(at: sessionsURL, to: backupURL)
            try fileManager.removeItem(at: sessionsURL)
        }

        defer {
            try? fileManager.removeItem(at: sessionsURL)
            if fileManager.fileExists(atPath: backupURL.path) {
                try? fileManager.moveItem(at: backupURL, to: sessionsURL)
            }
        }

        let session = TimeSession(
            id: UUID(uuidString: "11111111-2222-3333-4444-555555555555") ?? UUID(),
            startAt: Date(timeIntervalSince1970: 1_718_000_000),
            endAt: Date(timeIntervalSince1970: 1_718_001_200),
            referenceDurationSeconds: 1_500,
            classification: .production,
            productionNote: "self-check persistence",
            endedByUser: true
        ).normalizedForPersistence()

        let store = TimeSessionStore()
        store.append(session)

        let loaded = LocalJSONStore.load([TimeSession].self, from: "sessions.json")
        try expect(loaded?.count == 1, "persistence round-trip should reload one session")
        try expect(loaded?.first == session, "reloaded session should match saved session")
        try expect(fileManager.fileExists(atPath: sessionsURL.path), "sessions.json should exist on disk after append")
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

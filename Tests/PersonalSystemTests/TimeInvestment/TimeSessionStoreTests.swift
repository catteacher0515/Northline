import Foundation
import XCTest
@testable import PersonalSystem

final class TimeSessionStoreTests: XCTestCase {
    func testDailyTotalsSeparateProductionAndConsumption() {
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

        XCTAssertEqual(totals.productionSeconds, 1_800)
        XCTAssertEqual(totals.consumptionSeconds, 1_200)
    }

    func testEmptyProductionNoteDowngradesToConsumption() {
        let session = TimeSession(
            startAt: Date(timeIntervalSince1970: 100),
            endAt: Date(timeIntervalSince1970: 400),
            referenceDurationSeconds: 1_500,
            classification: .production,
            productionNote: "   ",
            endedByUser: true
        )

        let normalized = session.normalizedForPersistence()

        XCTAssertEqual(normalized.classification, .consumption)
        XCTAssertNil(normalized.productionNote)
    }
}

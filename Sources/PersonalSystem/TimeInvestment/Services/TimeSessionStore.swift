import Foundation

struct DailyTotals: Equatable {
    let productionSeconds: Int
    let consumptionSeconds: Int
}

struct TimeSessionStore {
    static func dailyTotals(
        sessions: [TimeSession],
        now: Date,
        calendar: Calendar = .current
    ) -> DailyTotals {
        let todaySessions = sessions.filter { DayBoundary.isSameLocalDay($0.startAt, now, calendar: calendar) }

        let productionSeconds = todaySessions
            .filter { $0.classification == .production }
            .reduce(0) { $0 + $1.durationSeconds }

        let consumptionSeconds = todaySessions
            .filter { $0.classification == .consumption }
            .reduce(0) { $0 + $1.durationSeconds }

        return DailyTotals(
            productionSeconds: productionSeconds,
            consumptionSeconds: consumptionSeconds
        )
    }
}

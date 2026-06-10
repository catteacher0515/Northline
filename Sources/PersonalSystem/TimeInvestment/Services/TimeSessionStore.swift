import Foundation

struct DailyTotals: Equatable {
    let productionSeconds: Int
    let consumptionSeconds: Int
}

final class TimeSessionStore {
    private static let sessionsFileName = "sessions.json"
    private var sessions: [TimeSession]

    init() {
        sessions = LocalJSONStore.load([TimeSession].self, from: Self.sessionsFileName) ?? []
    }

    func append(_ session: TimeSession) {
        sessions.append(session.normalizedForPersistence())
        LocalJSONStore.save(sessions, to: Self.sessionsFileName)
    }

    func allSessions() -> [TimeSession] {
        sessions
    }

    func dailyTotals(now: Date, calendar: Calendar = .current) -> DailyTotals {
        Self.dailyTotals(sessions: sessions, now: now, calendar: calendar)
    }

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

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

    func reviewSnapshot(
        range: ReviewRange,
        now: Date,
        calendar: Calendar = .current
    ) -> ReviewSnapshot {
        Self.reviewSnapshot(sessions: sessions, range: range, now: now, calendar: calendar)
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

    static func reviewSnapshot(
        sessions: [TimeSession],
        range: ReviewRange,
        now: Date,
        calendar: Calendar = .current
    ) -> ReviewSnapshot {
        let interval = range.dateInterval(now: now, calendar: calendar)
        let includedSessions = sessions
            .filter { $0.startAt >= interval.start && $0.startAt < interval.end }
            .sorted { $0.startAt < $1.startAt }

        let productionSeconds = includedSessions
            .filter { $0.classification == .production }
            .reduce(0) { $0 + $1.durationSeconds }

        let consumptionSeconds = includedSessions
            .filter { $0.classification == .consumption }
            .reduce(0) { $0 + $1.durationSeconds }

        let summary = ReviewSummary(
            totalSeconds: productionSeconds + consumptionSeconds,
            productionSeconds: productionSeconds,
            consumptionSeconds: consumptionSeconds
        )

        var dailyRows: [ReviewDayRow] = []
        var cursor = calendar.startOfDay(for: interval.start)

        while cursor < interval.end {
            let next = calendar.date(byAdding: .day, value: 1, to: cursor) ?? interval.end
            let daySessions = includedSessions.filter { $0.startAt >= cursor && $0.startAt < next }
            let dayProduction = daySessions
                .filter { $0.classification == .production }
                .reduce(0) { $0 + $1.durationSeconds }
            let dayConsumption = daySessions
                .filter { $0.classification == .consumption }
                .reduce(0) { $0 + $1.durationSeconds }

            dailyRows.append(
                ReviewDayRow(
                    date: cursor,
                    productionSeconds: dayProduction,
                    consumptionSeconds: dayConsumption
                )
            )

            cursor = next
        }

        let recentProductionNotes = includedSessions
            .filter { $0.classification == .production }
            .reversed()
            .compactMap { session -> ReviewProductionNoteRow? in
                guard let note = session.productionNote else {
                    return nil
                }

                return ReviewProductionNoteRow(
                    sessionID: session.id,
                    endAt: session.endAt,
                    durationSeconds: session.durationSeconds,
                    note: note
                )
            }

        return ReviewSnapshot(
            range: range,
            interval: interval,
            summary: summary,
            dailyRows: dailyRows,
            recentProductionNotes: Array(recentProductionNotes.prefix(10))
        )
    }
}

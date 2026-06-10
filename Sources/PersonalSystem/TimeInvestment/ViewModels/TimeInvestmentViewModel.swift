import Foundation
import SwiftUI

enum TimeInvestmentTab: String, CaseIterable, Identifiable {
    case record
    case review

    var id: String { rawValue }

    var title: String {
        switch self {
        case .record:
            return "记录"
        case .review:
            return "复盘"
        }
    }
}

protocol TimeSessionStoreProviding {
    func append(_ session: TimeSession)
    func dailyTotals(now: Date, calendar: Calendar) -> DailyTotals
    func reviewSnapshot(range: ReviewRange, now: Date, calendar: Calendar) -> ReviewSnapshot
}

extension TimeSessionStore: TimeSessionStoreProviding {}

final class InMemoryTimeSessionStore: TimeSessionStoreProviding {
    private var sessions: [TimeSession]

    init(seedSessions: [TimeSession]) {
        self.sessions = seedSessions
    }

    func append(_ session: TimeSession) {
        sessions.append(session)
    }

    func dailyTotals(now: Date, calendar: Calendar) -> DailyTotals {
        TimeSessionStore.dailyTotals(sessions: sessions, now: now, calendar: calendar)
    }

    func reviewSnapshot(range: ReviewRange, now: Date, calendar: Calendar) -> ReviewSnapshot {
        TimeSessionStore.reviewSnapshot(sessions: sessions, range: range, now: now, calendar: calendar)
    }
}

@MainActor
final class TimeInvestmentViewModel: ObservableObject {
    @Published private(set) var isSessionRunning = false
    @Published var isPresentingEndSessionSheet = false
    @Published var selectedTab: TimeInvestmentTab = .record
    @Published private(set) var selectedReviewRange: ReviewRange = .today

    private let store: TimeSessionStoreProviding
    private let timer: SessionTimer

    init(
        store: TimeSessionStoreProviding = TimeSessionStore(),
        timer: SessionTimer = SessionTimer(),
        referenceDurationSeconds: Int = 1_500
    ) {
        self.store = store
        self.timer = timer
        self.timer.updateDefaultReferenceDurationSeconds(referenceDurationSeconds)
        isSessionRunning = timer.isRunning
    }

    var todayTotals: DailyTotals {
        store.dailyTotals(now: Date(), calendar: .current)
    }

    var referenceDurationSeconds: Int {
        timer.defaultReferenceDurationSeconds
    }

    func updateReferenceDurationSeconds(_ seconds: Int) {
        timer.updateDefaultReferenceDurationSeconds(seconds)
        objectWillChange.send()
    }

    func startSession(now: Date = Date()) {
        guard timer.isRunning == false else {
            return
        }

        timer.start(at: now)
        isSessionRunning = timer.isRunning
    }

    func requestEndSession() {
        guard timer.isRunning else {
            return
        }

        isPresentingEndSessionSheet = true
    }

    func cancelEndSession() {
        isPresentingEndSessionSheet = false
    }

    func completeSession(using draft: SessionDraftResult, now: Date = Date()) {
        guard let snapshot = timer.stop(at: now) else {
            isPresentingEndSessionSheet = false
            return
        }

        let session = draft
            .makeSession(
                startAt: snapshot.startAt,
                endAt: snapshot.endAt,
                referenceDurationSeconds: snapshot.referenceDurationSeconds
            )
            .normalizedForPersistence()

        store.append(session)
        isPresentingEndSessionSheet = false
        isSessionRunning = timer.isRunning
        objectWillChange.send()
    }

    func selectReviewRange(_ range: ReviewRange) {
        selectedReviewRange = range
    }

    func reviewSnapshot(now: Date = Date(), calendar: Calendar = .current) -> ReviewSnapshot {
        store.reviewSnapshot(range: selectedReviewRange, now: now, calendar: calendar)
    }

    func elapsedSeconds(now: Date = Date()) -> Int {
        timer.elapsedSeconds(now: now)
    }
}

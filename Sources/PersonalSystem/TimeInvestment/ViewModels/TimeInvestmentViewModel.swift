import Foundation
import SwiftUI

@MainActor
final class TimeInvestmentViewModel: ObservableObject {
    @Published private(set) var isSessionRunning = false
    @Published var isPresentingEndSessionSheet = false

    private let store: TimeSessionStore
    private let timer: SessionTimer

    init(
        store: TimeSessionStore = TimeSessionStore(),
        timer: SessionTimer = SessionTimer(),
        referenceDurationSeconds: Int = 1_500
    ) {
        self.store = store
        self.timer = timer
        self.timer.updateDefaultReferenceDurationSeconds(referenceDurationSeconds)
        isSessionRunning = timer.isRunning
    }

    var todayTotals: DailyTotals {
        store.dailyTotals(now: Date())
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
    }

    func elapsedSeconds(now: Date = Date()) -> Int {
        timer.elapsedSeconds(now: now)
    }
}

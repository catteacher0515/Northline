import Foundation

struct ActiveSessionState: Codable, Equatable {
    let startAt: Date
    let referenceDurationSeconds: Int
}

struct SessionTimerSnapshot: Equatable {
    let startAt: Date
    let endAt: Date
    let referenceDurationSeconds: Int
}

final class SessionTimer {
    private(set) var activeStartAt: Date?
    private(set) var activeReferenceDurationSeconds: Int
    private(set) var defaultReferenceDurationSeconds: Int

    init(referenceDurationSeconds: Int = 1_500) {
        self.defaultReferenceDurationSeconds = referenceDurationSeconds
        self.activeReferenceDurationSeconds = referenceDurationSeconds
    }

    var isRunning: Bool {
        activeStartAt != nil
    }

    func updateDefaultReferenceDurationSeconds(_ seconds: Int) {
        defaultReferenceDurationSeconds = seconds
    }

    func start(at now: Date = Date()) {
        activeStartAt = now
        activeReferenceDurationSeconds = defaultReferenceDurationSeconds
    }

    func restore(from state: ActiveSessionState) {
        activeStartAt = state.startAt
        activeReferenceDurationSeconds = state.referenceDurationSeconds
    }

    func stop(at now: Date = Date()) -> SessionTimerSnapshot? {
        guard let startAt = activeStartAt else {
            return nil
        }

        activeStartAt = nil
        return SessionTimerSnapshot(
            startAt: startAt,
            endAt: now,
            referenceDurationSeconds: activeReferenceDurationSeconds
        )
    }

    var activeState: ActiveSessionState? {
        guard let activeStartAt else {
            return nil
        }

        return ActiveSessionState(
            startAt: activeStartAt,
            referenceDurationSeconds: activeReferenceDurationSeconds
        )
    }

    func elapsedSeconds(now: Date = Date()) -> Int {
        guard let startAt = activeStartAt else {
            return 0
        }

        return max(0, Int(now.timeIntervalSince(startAt)))
    }
}

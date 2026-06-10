import Foundation

struct SessionTimerSnapshot: Equatable {
    let startAt: Date
    let endAt: Date
    let referenceDurationSeconds: Int
}

final class SessionTimer {
    private(set) var activeStartAt: Date?
    let referenceDurationSeconds: Int

    init(referenceDurationSeconds: Int = 1_500) {
        self.referenceDurationSeconds = referenceDurationSeconds
    }

    var isRunning: Bool {
        activeStartAt != nil
    }

    func start(at now: Date = Date()) {
        activeStartAt = now
    }

    func stop(at now: Date = Date()) -> SessionTimerSnapshot? {
        guard let startAt = activeStartAt else {
            return nil
        }

        activeStartAt = nil
        return SessionTimerSnapshot(
            startAt: startAt,
            endAt: now,
            referenceDurationSeconds: referenceDurationSeconds
        )
    }

    func elapsedSeconds(now: Date = Date()) -> Int {
        guard let startAt = activeStartAt else {
            return 0
        }

        return max(0, Int(now.timeIntervalSince(startAt)))
    }
}

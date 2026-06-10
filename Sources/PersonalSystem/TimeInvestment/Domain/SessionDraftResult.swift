import Foundation

struct SessionDraftResult: Equatable {
    let classification: SessionClassification
    let productionNote: String?

    static func production(note: String) -> SessionDraftResult {
        SessionDraftResult(classification: .production, productionNote: note)
    }

    static var consumption: SessionDraftResult {
        SessionDraftResult(classification: .consumption, productionNote: nil)
    }

    func makeSession(
        startAt: Date,
        endAt: Date,
        referenceDurationSeconds: Int
    ) -> TimeSession {
        TimeSession(
            startAt: startAt,
            endAt: endAt,
            referenceDurationSeconds: referenceDurationSeconds,
            classification: classification,
            productionNote: productionNote,
            endedByUser: true
        )
    }
}

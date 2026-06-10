# Time Investment Review Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a `记录 / 复盘` split inside the Time Investment module, with a minimal review dashboard that supports shared time ranges, summary totals, daily production/consumption trends, and recent production notes.

**Architecture:** Keep the record flow intact and isolate review concerns into new range/snapshot types plus a dedicated review view. Reuse `TimeSessionStore` as the single source of truth, add range-based aggregation APIs there, and keep verification on the current Command Line Tools environment through `TimeInvestmentSelfCheck`.

**Tech Stack:** Swift 6, SwiftUI, Charts, Foundation, existing local JSON persistence, self-check verification via `swift run PersonalSystem --self-check`

---

## File Structure

### Domain

- Create: `Sources/PersonalSystem/TimeInvestment/Domain/ReviewRange.swift`
  - Defines the review range presets and custom date interval handling.
- Create: `Sources/PersonalSystem/TimeInvestment/Domain/ReviewSnapshot.swift`
  - Defines summary totals, daily trend rows, and recent production note rows.

### Store and View Model

- Modify: `Sources/PersonalSystem/TimeInvestment/Services/TimeSessionStore.swift`
  - Add range-based aggregation and recent production note queries.
- Modify: `Sources/PersonalSystem/TimeInvestment/ViewModels/TimeInvestmentViewModel.swift`
  - Add tab state and review range state, expose the current review snapshot.
- Modify: `Sources/PersonalSystem/TimeInvestment/Services/TimeInvestmentSelfCheck.swift`
  - Add review aggregation verification for the CLT-only environment.

### Views

- Create: `Sources/PersonalSystem/TimeInvestment/Views/TimeInvestmentModuleView.swift`
  - Provides the `记录 / 复盘` segmented shell.
- Create: `Sources/PersonalSystem/TimeInvestment/Views/TimeInvestmentRecordView.swift`
  - Holds the current record-first dashboard content extracted from the existing view.
- Create: `Sources/PersonalSystem/TimeInvestment/Views/TimeInvestmentReviewView.swift`
  - Composes range controls, summary cards, daily trend, and recent production notes.
- Create: `Sources/PersonalSystem/TimeInvestment/Views/ReviewRangePicker.swift`
  - Shared control for `今天 / 本周 / 本月 / 自定义`.
- Create: `Sources/PersonalSystem/TimeInvestment/Views/ReviewSummaryCards.swift`
  - Renders the four top-level metrics.
- Create: `Sources/PersonalSystem/TimeInvestment/Views/ReviewDailyTrendChart.swift`
  - Renders the daily production/consumption chart.
- Create: `Sources/PersonalSystem/TimeInvestment/Views/RecentProductionNotesView.swift`
  - Renders the recent note list in reverse chronological order.

### App Wiring

- Modify: `Sources/PersonalSystem/App/ContainerHomeView.swift`
  - Swap the time investment module entry from the current dashboard view to the new module shell.

---

## Task 1: Add Review Range and Snapshot Domain Types

**Files:**
- Create: `Sources/PersonalSystem/TimeInvestment/Domain/ReviewRange.swift`
- Create: `Sources/PersonalSystem/TimeInvestment/Domain/ReviewSnapshot.swift`
- Modify: `Sources/PersonalSystem/TimeInvestment/Services/TimeInvestmentSelfCheck.swift`

- [ ] **Step 1: Add a failing self-check for review ranges**

Append this code inside `TimeInvestmentSelfCheck.runAndExit()` and below the existing verification helpers:

```swift
try verifyReviewRangeBoundaries()
```

```swift
private static func verifyReviewRangeBoundaries() throws {
    let calendar = Calendar(identifier: .gregorian)
    let now = Date(timeIntervalSince1970: 1_718_020_000) // fixed date for deterministic checks

    let today = ReviewRange.today.dateInterval(now: now, calendar: calendar)
    try expect(calendar.isDate(today.start, inSameDayAs: now), "today range should start on the same local day")
    try expect(today.duration == 86_400, "today range should cover one full day")

    let customStart = Date(timeIntervalSince1970: 1_717_800_000)
    let customEnd = Date(timeIntervalSince1970: 1_717_972_800)
    let custom = ReviewRange.custom(start: customStart, end: customEnd).dateInterval(now: now, calendar: calendar)
    try expect(custom.start == customStart, "custom range should preserve explicit start")
    try expect(custom.end == customEnd, "custom range should preserve explicit end")
}
```

- [ ] **Step 2: Run the self-check to verify it fails**

Run:

```bash
swift run PersonalSystem --self-check
```

Expected: FAIL with errors that `ReviewRange` is not defined.

- [ ] **Step 3: Create the minimal range and snapshot types**

Write `Sources/PersonalSystem/TimeInvestment/Domain/ReviewRange.swift`:

```swift
import Foundation

enum ReviewRange: Equatable {
    case today
    case week
    case month
    case custom(start: Date, end: Date)

    func dateInterval(now: Date, calendar: Calendar = .current) -> DateInterval {
        switch self {
        case .today:
            let start = calendar.startOfDay(for: now)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? now
            return DateInterval(start: start, end: end)
        case .week:
            let interval = calendar.dateInterval(of: .weekOfYear, for: now) ?? DateInterval(start: now, end: now)
            return interval
        case .month:
            let interval = calendar.dateInterval(of: .month, for: now) ?? DateInterval(start: now, end: now)
            return interval
        case let .custom(start, end):
            return DateInterval(start: start, end: end)
        }
    }

    var title: String {
        switch self {
        case .today:
            return "今天"
        case .week:
            return "本周"
        case .month:
            return "本月"
        case .custom:
            return "自定义"
        }
    }
}
```

Write `Sources/PersonalSystem/TimeInvestment/Domain/ReviewSnapshot.swift`:

```swift
import Foundation

struct ReviewSummary: Equatable {
    let totalSeconds: Int
    let productionSeconds: Int
    let consumptionSeconds: Int

    var productionRatio: Double {
        guard totalSeconds > 0 else { return 0 }
        return Double(productionSeconds) / Double(totalSeconds)
    }
}

struct ReviewDayRow: Equatable, Identifiable {
    let date: Date
    let productionSeconds: Int
    let consumptionSeconds: Int

    var id: Date { date }
    var totalSeconds: Int { productionSeconds + consumptionSeconds }
}

struct ReviewProductionNoteRow: Equatable, Identifiable {
    let sessionID: UUID
    let endAt: Date
    let durationSeconds: Int
    let note: String

    var id: UUID { sessionID }
}

struct ReviewSnapshot: Equatable {
    let range: ReviewRange
    let interval: DateInterval
    let summary: ReviewSummary
    let dailyRows: [ReviewDayRow]
    let recentProductionNotes: [ReviewProductionNoteRow]
}
```

- [ ] **Step 4: Run the self-check to verify the new types pass the range assertions**

Run:

```bash
swift run PersonalSystem --self-check
```

Expected: PASS for the new range assertions and FAIL later because the review snapshot aggregation does not exist yet.

- [ ] **Step 5: Commit**

```bash
git add Sources/PersonalSystem/TimeInvestment/Domain/ReviewRange.swift Sources/PersonalSystem/TimeInvestment/Domain/ReviewSnapshot.swift Sources/PersonalSystem/TimeInvestment/Services/TimeInvestmentSelfCheck.swift
git commit -m "feat: add review dashboard domain types"
```

---

## Task 2: Add Review Aggregation to `TimeSessionStore`

**Files:**
- Modify: `Sources/PersonalSystem/TimeInvestment/Services/TimeSessionStore.swift`
- Modify: `Sources/PersonalSystem/TimeInvestment/Services/TimeInvestmentSelfCheck.swift`

- [ ] **Step 1: Add a failing self-check for review aggregation**

Append this call inside `runAndExit()` after `verifyReviewRangeBoundaries()`:

```swift
try verifyReviewSnapshotAggregation()
```

Append this helper below `verifyReviewRangeBoundaries()`:

```swift
private static func verifyReviewSnapshotAggregation() throws {
    let calendar = Calendar(identifier: .gregorian)
    let now = Date(timeIntervalSince1970: 1_718_020_000)
    let dayOne = calendar.startOfDay(for: now)
    let dayTwo = calendar.date(byAdding: .day, value: 1, to: dayOne) ?? dayOne

    let sessions = [
        TimeSession(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEE1") ?? UUID(),
            startAt: dayOne.addingTimeInterval(1_200),
            endAt: dayOne.addingTimeInterval(4_800),
            referenceDurationSeconds: 1_500,
            classification: .production,
            productionNote: "drafted article",
            endedByUser: true
        ),
        TimeSession(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEE2") ?? UUID(),
            startAt: dayOne.addingTimeInterval(8_000),
            endAt: dayOne.addingTimeInterval(9_800),
            referenceDurationSeconds: 1_500,
            classification: .consumption,
            productionNote: nil,
            endedByUser: true
        ),
        TimeSession(
            id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEE3") ?? UUID(),
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
```

- [ ] **Step 2: Run the self-check to verify it fails**

Run:

```bash
swift run PersonalSystem --self-check
```

Expected: FAIL with `TimeSessionStore.reviewSnapshot` not found.

- [ ] **Step 3: Implement review snapshot aggregation in the store**

Update `Sources/PersonalSystem/TimeInvestment/Services/TimeSessionStore.swift` to:

```swift
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
```

- [ ] **Step 4: Run build and self-check**

Run:

```bash
swift build
swift run PersonalSystem --self-check
```

Expected:

- `swift build` succeeds
- self-check prints `TimeInvestment self-check passed`

- [ ] **Step 5: Commit**

```bash
git add Sources/PersonalSystem/TimeInvestment/Services/TimeSessionStore.swift Sources/PersonalSystem/TimeInvestment/Services/TimeInvestmentSelfCheck.swift
git commit -m "feat: add review dashboard aggregations"
```

---

## Task 3: Add Review State to `TimeInvestmentViewModel`

**Files:**
- Modify: `Sources/PersonalSystem/TimeInvestment/ViewModels/TimeInvestmentViewModel.swift`
- Modify: `Sources/PersonalSystem/TimeInvestment/Services/TimeInvestmentSelfCheck.swift`

- [ ] **Step 1: Add a failing self-check for review state wiring**

Append this call inside `runAndExit()` after `verifyReviewSnapshotAggregation()`:

```swift
try verifyReviewViewModelState()
```

Append this helper below `verifyReviewSnapshotAggregation()`:

```swift
private static func verifyReviewViewModelState() throws {
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
}
```

- [ ] **Step 2: Run the self-check to verify it fails**

Run:

```bash
swift run PersonalSystem --self-check
```

Expected: FAIL because `selectedTab`, `selectReviewRange`, `reviewSnapshot`, and `InMemoryTimeSessionStore` do not exist.

- [ ] **Step 3: Implement minimal review state and store protocol support**

Replace `Sources/PersonalSystem/TimeInvestment/ViewModels/TimeInvestmentViewModel.swift` with:

```swift
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
```

- [ ] **Step 4: Run build and self-check**

Run:

```bash
swift build
swift run PersonalSystem --self-check
```

Expected:

- build succeeds
- self-check passes with the new review state assertions

- [ ] **Step 5: Commit**

```bash
git add Sources/PersonalSystem/TimeInvestment/ViewModels/TimeInvestmentViewModel.swift Sources/PersonalSystem/TimeInvestment/Services/TimeInvestmentSelfCheck.swift
git commit -m "feat: add review state to time investment view model"
```

---

## Task 4: Split the Module into `记录 / 复盘`

**Files:**
- Create: `Sources/PersonalSystem/TimeInvestment/Views/TimeInvestmentModuleView.swift`
- Create: `Sources/PersonalSystem/TimeInvestment/Views/TimeInvestmentRecordView.swift`
- Modify: `Sources/PersonalSystem/TimeInvestment/Views/TimeInvestmentDashboardView.swift`
- Modify: `Sources/PersonalSystem/App/ContainerHomeView.swift`

- [ ] **Step 1: Replace the old single-page dashboard with a module shell**

Write `Sources/PersonalSystem/TimeInvestment/Views/TimeInvestmentModuleView.swift`:

```swift
import SwiftUI

struct TimeInvestmentModuleView: View {
    @ObservedObject var viewModel: TimeInvestmentViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Picker("页面", selection: $viewModel.selectedTab) {
                ForEach(TimeInvestmentTab.allCases) { tab in
                    Text(tab.title).tag(tab)
                }
            }
            .pickerStyle(.segmented)

            switch viewModel.selectedTab {
            case .record:
                TimeInvestmentRecordView(viewModel: viewModel)
            case .review:
                TimeInvestmentReviewView(viewModel: viewModel)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .sheet(isPresented: $viewModel.isPresentingEndSessionSheet) {
            EndSessionSheet(
                onCancel: {
                    viewModel.cancelEndSession()
                },
                onConfirm: { draft in
                    viewModel.completeSession(using: draft)
                }
            )
        }
    }
}
```

Write `Sources/PersonalSystem/TimeInvestment/Views/TimeInvestmentRecordView.swift`:

```swift
import SwiftUI

struct TimeInvestmentRecordView: View {
    @ObservedObject var viewModel: TimeInvestmentViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            header
            totalsCard
            sessionCard
            Spacer(minLength: 0)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("时间投入")
                .font(.largeTitle.weight(.semibold))
            Text("开始时零阻力，结束时必须裁决。")
                .foregroundStyle(.secondary)
        }
    }

    private var totalsCard: some View {
        HStack(spacing: 12) {
            MetricPill(
                title: "今日生产",
                value: DurationFormatter.formatted(viewModel.todayTotals.productionSeconds)
            )
            MetricPill(
                title: "今日消费",
                value: DurationFormatter.formatted(viewModel.todayTotals.consumptionSeconds)
            )
            Spacer(minLength: 0)
        }
    }

    private var sessionCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(viewModel.isSessionRunning ? "进行中" : "未开始")
                .font(.headline)

            if viewModel.isSessionRunning {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("已投入 \(DurationFormatter.formatted(viewModel.elapsedSeconds(now: context.date)))")
                            .font(.title2.weight(.semibold))
                        Text("默认参考时长 \(DurationFormatter.formatted(viewModel.referenceDurationSeconds))")
                            .foregroundStyle(.secondary)
                    }
                }

                Button("结束") {
                    viewModel.requestEndSession()
                }
                .buttonStyle(.borderedProminent)
            } else {
                Text("点击开始即可进入静默计时。")
                    .foregroundStyle(.secondary)

                Button("开始") {
                    viewModel.startSession()
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}

private struct MetricPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}
```

- [ ] **Step 2: Make the old dashboard a thin compatibility wrapper and rewire the container**

Replace `Sources/PersonalSystem/TimeInvestment/Views/TimeInvestmentDashboardView.swift` with:

```swift
import SwiftUI

struct TimeInvestmentDashboardView: View {
    @ObservedObject var viewModel: TimeInvestmentViewModel

    var body: some View {
        TimeInvestmentModuleView(viewModel: viewModel)
    }
}
```

Update the `.timeInvestment` branch in `Sources/PersonalSystem/App/ContainerHomeView.swift` to:

```swift
case .timeInvestment:
    TimeInvestmentModuleView(viewModel: timeInvestmentViewModel)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
```

- [ ] **Step 3: Run build to verify the shell compiles before the review page exists**

Run:

```bash
swift build
```

Expected: FAIL because `TimeInvestmentReviewView` does not exist yet.

- [ ] **Step 4: Commit the shell extraction after Task 5 is complete**

Do not commit this task alone. Commit it together with Task 5 after the missing review view exists.

---

## Task 5: Build the Minimal Review Dashboard UI

**Files:**
- Create: `Sources/PersonalSystem/TimeInvestment/Views/ReviewRangePicker.swift`
- Create: `Sources/PersonalSystem/TimeInvestment/Views/ReviewSummaryCards.swift`
- Create: `Sources/PersonalSystem/TimeInvestment/Views/ReviewDailyTrendChart.swift`
- Create: `Sources/PersonalSystem/TimeInvestment/Views/RecentProductionNotesView.swift`
- Create: `Sources/PersonalSystem/TimeInvestment/Views/TimeInvestmentReviewView.swift`
- Modify: `Sources/PersonalSystem/TimeInvestment/Services/TimeInvestmentSelfCheck.swift`

- [ ] **Step 1: Create the review range picker**

Write `Sources/PersonalSystem/TimeInvestment/Views/ReviewRangePicker.swift`:

```swift
import SwiftUI

struct ReviewRangePicker: View {
    @Binding var selectedRange: ReviewRange

    var body: some View {
        HStack(spacing: 12) {
            Button("今天") { selectedRange = .today }
            Button("本周") { selectedRange = .week }
            Button("本月") { selectedRange = .month }
            Button("自定义") {
                let end = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: Date())) ?? Date()
                let start = Calendar.current.date(byAdding: .day, value: -6, to: end) ?? end
                selectedRange = .custom(start: start, end: end)
            }
        }
        .buttonStyle(.bordered)
    }
}
```

- [ ] **Step 2: Create the summary cards and recent notes list**

Write `Sources/PersonalSystem/TimeInvestment/Views/ReviewSummaryCards.swift`:

```swift
import SwiftUI

struct ReviewSummaryCards: View {
    let summary: ReviewSummary

    var body: some View {
        HStack(spacing: 12) {
            ReviewMetricCard(title: "总投入", value: DurationFormatter.formatted(summary.totalSeconds))
            ReviewMetricCard(title: "生产", value: DurationFormatter.formatted(summary.productionSeconds))
            ReviewMetricCard(title: "消费", value: DurationFormatter.formatted(summary.consumptionSeconds))
            ReviewMetricCard(title: "生产占比", value: "\(Int(summary.productionRatio * 100))%")
            Spacer(minLength: 0)
        }
    }
}

private struct ReviewMetricCard: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.weight(.semibold))
        }
        .padding(16)
        .frame(maxWidth: 180, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}
```

Write `Sources/PersonalSystem/TimeInvestment/Views/RecentProductionNotesView.swift`:

```swift
import SwiftUI

struct RecentProductionNotesView: View {
    let notes: [ReviewProductionNoteRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近生产备注")
                .font(.headline)

            if notes.isEmpty {
                Text("当前时间范围内还没有生产记录。")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(notes) { row in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(row.note)
                            .font(.body.weight(.medium))
                        Text("\(row.endAt.formatted(date: .abbreviated, time: .shortened)) · \(DurationFormatter.formatted(row.durationSeconds))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)
                    Divider()
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}
```

- [ ] **Step 3: Create the daily trend chart and compose the review view**

Write `Sources/PersonalSystem/TimeInvestment/Views/ReviewDailyTrendChart.swift`:

```swift
import Charts
import SwiftUI

struct ReviewDailyTrendChart: View {
    let rows: [ReviewDayRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("按天趋势")
                .font(.headline)

            Chart {
                ForEach(rows) { row in
                    BarMark(
                        x: .value("日期", row.date, unit: .day),
                        y: .value("生产", row.productionSeconds)
                    )
                    .foregroundStyle(.green)

                    BarMark(
                        x: .value("日期", row.date, unit: .day),
                        y: .value("消费", row.consumptionSeconds)
                    )
                    .foregroundStyle(.orange)
                }
            }
            .frame(height: 240)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}
```

Write `Sources/PersonalSystem/TimeInvestment/Views/TimeInvestmentReviewView.swift`:

```swift
import SwiftUI

struct TimeInvestmentReviewView: View {
    @ObservedObject var viewModel: TimeInvestmentViewModel

    var body: some View {
        let snapshot = viewModel.reviewSnapshot()

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("复盘")
                        .font(.largeTitle.weight(.semibold))
                    Text("看总账、看趋势、看最近做了什么。")
                        .foregroundStyle(.secondary)
                }

                ReviewRangePicker(
                    selectedRange: Binding(
                        get: { viewModel.selectedReviewRange },
                        set: { viewModel.selectReviewRange($0) }
                    )
                )

                ReviewSummaryCards(summary: snapshot.summary)
                ReviewDailyTrendChart(rows: snapshot.dailyRows)
                RecentProductionNotesView(notes: snapshot.recentProductionNotes)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
```

- [ ] **Step 4: Add a final self-check assertion for the default review range and run verification**

Append this line to `verifyReviewViewModelState()`:

```swift
try expect(viewModel.reviewSnapshot(now: now, calendar: calendar).range == .today, "review snapshot should preserve the selected range")
```

Run:

```bash
swift build
swift run PersonalSystem --self-check
```

Expected:

- build succeeds
- self-check prints `TimeInvestment self-check passed`

- [ ] **Step 5: Commit**

```bash
git add Sources/PersonalSystem/TimeInvestment/Views/TimeInvestmentModuleView.swift Sources/PersonalSystem/TimeInvestment/Views/TimeInvestmentRecordView.swift Sources/PersonalSystem/TimeInvestment/Views/ReviewRangePicker.swift Sources/PersonalSystem/TimeInvestment/Views/ReviewSummaryCards.swift Sources/PersonalSystem/TimeInvestment/Views/ReviewDailyTrendChart.swift Sources/PersonalSystem/TimeInvestment/Views/RecentProductionNotesView.swift Sources/PersonalSystem/TimeInvestment/Views/TimeInvestmentReviewView.swift Sources/PersonalSystem/TimeInvestment/Views/TimeInvestmentDashboardView.swift Sources/PersonalSystem/App/ContainerHomeView.swift Sources/PersonalSystem/TimeInvestment/Services/TimeInvestmentSelfCheck.swift
git commit -m "feat: add time investment review dashboard"
```

---

## Self-Review

### Spec Coverage

- `记录 / 复盘` 双标签：Task 3 and Task 4
- 时间范围 `今天 / 本周 / 本月 / 自定义`：Task 1 and Task 5
- 总账卡片：Task 2 and Task 5
- 按天趋势：Task 2 and Task 5
- 最近生产备注：Task 2 and Task 5
- 不污染记录页零阻力流程：Task 4 keeps record content in a dedicated view

No spec section is left without an implementation task.

### Placeholder Scan

- No `TODO`, `TBD`, or “implement later” markers are present.
- Every code step includes concrete file content or concrete code snippets.
- Every verification step includes an exact command and expected result.

### Type Consistency

- `ReviewRange`, `ReviewSnapshot`, `ReviewSummary`, `ReviewDayRow`, and `ReviewProductionNoteRow` are defined in Task 1 and reused consistently later.
- `TimeInvestmentTab` and `selectedReviewRange` are defined in Task 3 before they are used in Tasks 4 and 5.
- `TimeInvestmentModuleView`, `TimeInvestmentRecordView`, and `TimeInvestmentReviewView` have non-overlapping responsibilities.

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-06-10-time-investment-review-dashboard.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?

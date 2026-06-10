# Personal System Container V1 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native macOS personal system container app whose first module is a zero-friction time investment module with start, silent timing, end-of-session production/consumption classification, required production naming, and daily totals.

**Architecture:** Use a thin container with one strong module. Build a native menu bar macOS app in SwiftUI, with small AppKit bridges for status bar control and global hotkeys. Keep module boundaries explicit: app shell, time investment domain, persistence, and session end UI should be separate units with minimal shared state.

**Tech Stack:** Swift 6, SwiftUI, AppKit, SwiftData, XCTest

---

## File Structure

### App Shell

- Create: `PersonalSystem/PersonalSystemApp.swift`
- Create: `PersonalSystem/App/AppCoordinator.swift`
- Create: `PersonalSystem/App/AppState.swift`
- Create: `PersonalSystem/App/ContainerHomeView.swift`
- Create: `PersonalSystem/App/ModuleCardView.swift`
- Create: `PersonalSystem/App/SettingsView.swift`

### Time Investment Module

- Create: `PersonalSystem/TimeInvestment/Domain/TimeSession.swift`
- Create: `PersonalSystem/TimeInvestment/Domain/SessionClassification.swift`
- Create: `PersonalSystem/TimeInvestment/Domain/SessionDraftResult.swift`
- Create: `PersonalSystem/TimeInvestment/Services/TimeSessionStore.swift`
- Create: `PersonalSystem/TimeInvestment/Services/SessionTimer.swift`
- Create: `PersonalSystem/TimeInvestment/Services/HotkeyService.swift`
- Create: `PersonalSystem/TimeInvestment/Services/MenuBarService.swift`
- Create: `PersonalSystem/TimeInvestment/ViewModels/TimeInvestmentViewModel.swift`
- Create: `PersonalSystem/TimeInvestment/Views/TimeInvestmentDashboardView.swift`
- Create: `PersonalSystem/TimeInvestment/Views/EndSessionSheet.swift`
- Create: `PersonalSystem/TimeInvestment/Views/EndSessionProductionForm.swift`
- Create: `PersonalSystem/TimeInvestment/Views/StatusDotView.swift`

### Shared Utilities

- Create: `PersonalSystem/Shared/Date/DayBoundary.swift`
- Create: `PersonalSystem/Shared/Formatting/DurationFormatter.swift`

### Tests

- Create: `PersonalSystemTests/TimeInvestment/TimeSessionStoreTests.swift`
- Create: `PersonalSystemTests/TimeInvestment/SessionTimerTests.swift`
- Create: `PersonalSystemTests/TimeInvestment/TimeInvestmentViewModelTests.swift`
- Create: `PersonalSystemTests/App/ContainerHomeViewModelTests.swift`

## Implementation Notes

- The app starts as a menu bar app with a lightweight main window for the container home.
- The first module shown on the home screen is `Time Investment`.
- Future modules such as stress management are represented as disabled placeholder cards in the home view.
- Session classification is manual only. No automatic productivity inference exists anywhere in V1.
- Production notes are required only when the user selects `production`.
- If the user backs out, closes, or submits an empty production note, the session is stored as `consumption`.

## Task 1: Create the Xcode Project Skeleton

**Files:**
- Create: `PersonalSystem/PersonalSystemApp.swift`
- Create: `PersonalSystem/App/AppState.swift`
- Create: `PersonalSystem/App/AppCoordinator.swift`

- [ ] **Step 1: Create the Xcode macOS app target**

Use Xcode to create a new macOS App project named `PersonalSystem` with:

```text
Interface: SwiftUI
Language: Swift
Storage: SwiftData
Testing: XCTest
```

Expected project tree:

```text
PersonalSystem/
PersonalSystem.xcodeproj
PersonalSystem/
PersonalSystemTests/
```

- [ ] **Step 2: Replace the default app entry with a container-oriented shell**

Write `PersonalSystem/PersonalSystemApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct PersonalSystemApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup("Personal System") {
            AppCoordinator()
                .environment(appState)
        }
        .modelContainer(for: TimeSession.self)

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}
```

- [ ] **Step 3: Add global app state**

Write `PersonalSystem/App/AppState.swift`:

```swift
import Foundation

@Observable
final class AppState {
    var selectedModuleID: String = "time-investment"
    var launchAtLoginEnabled: Bool = false
    var menuBarShowsElapsedTime: Bool = false
    var defaultReferenceDurationSeconds: Int = 1_500
}
```

- [ ] **Step 4: Add an app coordinator placeholder**

Write `PersonalSystem/App/AppCoordinator.swift`:

```swift
import SwiftUI

struct AppCoordinator: View {
    var body: some View {
        ContainerHomeView()
    }
}
```

- [ ] **Step 5: Build the app**

Run:

```bash
xcodebuild -scheme PersonalSystem -destination 'platform=macOS' build
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 6: Commit**

```bash
git add PersonalSystem.xcodeproj PersonalSystem PersonalSystemTests
git commit -m "chore: initialize personal system macOS app shell"
```

## Task 2: Model a Time Session and Daily Totals

**Files:**
- Create: `PersonalSystem/TimeInvestment/Domain/SessionClassification.swift`
- Create: `PersonalSystem/TimeInvestment/Domain/TimeSession.swift`
- Create: `PersonalSystem/Shared/Date/DayBoundary.swift`
- Test: `PersonalSystemTests/TimeInvestment/TimeSessionStoreTests.swift`

- [ ] **Step 1: Write the failing tests for session rules**

Write `PersonalSystemTests/TimeInvestment/TimeSessionStoreTests.swift`:

```swift
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
```

- [ ] **Step 2: Run the tests to verify they fail**

Run:

```bash
xcodebuild test -scheme PersonalSystem -destination 'platform=macOS' -only-testing:PersonalSystemTests/TimeSessionStoreTests
```

Expected: FAIL with missing `TimeSession` / `TimeSessionStore`

- [ ] **Step 3: Add the classification enum**

Write `PersonalSystem/TimeInvestment/Domain/SessionClassification.swift`:

```swift
import Foundation

enum SessionClassification: String, Codable, CaseIterable, Identifiable {
    case production
    case consumption

    var id: String { rawValue }
}
```

- [ ] **Step 4: Add the session model**

Write `PersonalSystem/TimeInvestment/Domain/TimeSession.swift`:

```swift
import Foundation
import SwiftData

@Model
final class TimeSession {
    var id: UUID
    var startAt: Date
    var endAt: Date
    var referenceDurationSeconds: Int
    var classificationRawValue: String
    var productionNote: String?
    var endedByUser: Bool

    init(
        id: UUID = UUID(),
        startAt: Date,
        endAt: Date,
        referenceDurationSeconds: Int,
        classification: SessionClassification,
        productionNote: String?,
        endedByUser: Bool
    ) {
        self.id = id
        self.startAt = startAt
        self.endAt = endAt
        self.referenceDurationSeconds = referenceDurationSeconds
        self.classificationRawValue = classification.rawValue
        self.productionNote = productionNote
        self.endedByUser = endedByUser
    }

    var classification: SessionClassification {
        get { SessionClassification(rawValue: classificationRawValue) ?? .consumption }
        set { classificationRawValue = newValue.rawValue }
    }

    var durationSeconds: Int {
        max(0, Int(endAt.timeIntervalSince(startAt)))
    }

    func normalizedForPersistence() -> TimeSession {
        guard classification == .production else {
            return TimeSession(
                id: id,
                startAt: startAt,
                endAt: endAt,
                referenceDurationSeconds: referenceDurationSeconds,
                classification: .consumption,
                productionNote: nil,
                endedByUser: endedByUser
            )
        }

        let note = productionNote?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard note.isEmpty == false else {
            return TimeSession(
                id: id,
                startAt: startAt,
                endAt: endAt,
                referenceDurationSeconds: referenceDurationSeconds,
                classification: .consumption,
                productionNote: nil,
                endedByUser: endedByUser
            )
        }

        return TimeSession(
            id: id,
            startAt: startAt,
            endAt: endAt,
            referenceDurationSeconds: referenceDurationSeconds,
            classification: .production,
            productionNote: note,
            endedByUser: endedByUser
        )
    }
}
```

- [ ] **Step 5: Add day boundary helpers**

Write `PersonalSystem/Shared/Date/DayBoundary.swift`:

```swift
import Foundation

enum DayBoundary {
    static func isSameLocalDay(_ lhs: Date, _ rhs: Date, calendar: Calendar = .current) -> Bool {
        calendar.isDate(lhs, inSameDayAs: rhs)
    }
}
```

- [ ] **Step 6: Add a minimal store type with daily totals**

Create `PersonalSystem/TimeInvestment/Services/TimeSessionStore.swift`:

```swift
import Foundation
import SwiftData

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
        let filtered = sessions.filter { DayBoundary.isSameLocalDay($0.startAt, now, calendar: calendar) }
        let production = filtered
            .filter { $0.classification == .production }
            .reduce(0) { $0 + $1.durationSeconds }
        let consumption = filtered
            .filter { $0.classification == .consumption }
            .reduce(0) { $0 + $1.durationSeconds }

        return DailyTotals(productionSeconds: production, consumptionSeconds: consumption)
    }
}
```

- [ ] **Step 7: Run the tests to verify they pass**

Run:

```bash
xcodebuild test -scheme PersonalSystem -destination 'platform=macOS' -only-testing:PersonalSystemTests/TimeSessionStoreTests
```

Expected: PASS

- [ ] **Step 8: Commit**

```bash
git add PersonalSystem/TimeInvestment PersonalSystem/Shared PersonalSystemTests/TimeInvestment
git commit -m "feat: add time session model and daily totals"
```

## Task 3: Add the Session Timer

**Files:**
- Create: `PersonalSystem/TimeInvestment/Services/SessionTimer.swift`
- Test: `PersonalSystemTests/TimeInvestment/SessionTimerTests.swift`

- [ ] **Step 1: Write the failing timer tests**

Write `PersonalSystemTests/TimeInvestment/SessionTimerTests.swift`:

```swift
import XCTest
@testable import PersonalSystem

final class SessionTimerTests: XCTestCase {
    func testStartCreatesRunningSession() {
        let timer = SessionTimer(now: { Date(timeIntervalSince1970: 1_000) })

        timer.start(referenceDurationSeconds: 1_500)

        XCTAssertTrue(timer.isRunning)
        XCTAssertEqual(timer.currentSessionStartAt, Date(timeIntervalSince1970: 1_000))
        XCTAssertEqual(timer.referenceDurationSeconds, 1_500)
    }

    func testStopReturnsSessionWindow() {
        var now = Date(timeIntervalSince1970: 1_000)
        let timer = SessionTimer(now: { now })

        timer.start(referenceDurationSeconds: 1_500)
        now = Date(timeIntervalSince1970: 1_900)
        let window = timer.stop()

        XCTAssertEqual(window?.startAt, Date(timeIntervalSince1970: 1_000))
        XCTAssertEqual(window?.endAt, Date(timeIntervalSince1970: 1_900))
        XCTAssertFalse(timer.isRunning)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
xcodebuild test -scheme PersonalSystem -destination 'platform=macOS' -only-testing:PersonalSystemTests/SessionTimerTests
```

Expected: FAIL with missing `SessionTimer`

- [ ] **Step 3: Implement the timer**

Write `PersonalSystem/TimeInvestment/Services/SessionTimer.swift`:

```swift
import Foundation

struct SessionWindow: Equatable {
    let startAt: Date
    let endAt: Date
}

@Observable
final class SessionTimer {
    private let now: () -> Date
    private(set) var currentSessionStartAt: Date?
    private(set) var referenceDurationSeconds: Int = 1_500

    init(now: @escaping () -> Date = Date.init) {
        self.now = now
    }

    var isRunning: Bool {
        currentSessionStartAt != nil
    }

    func start(referenceDurationSeconds: Int) {
        guard isRunning == false else { return }
        currentSessionStartAt = now()
        self.referenceDurationSeconds = referenceDurationSeconds
    }

    func stop() -> SessionWindow? {
        guard let start = currentSessionStartAt else { return nil }
        let window = SessionWindow(startAt: start, endAt: now())
        currentSessionStartAt = nil
        return window
    }

    func elapsedSeconds() -> Int {
        guard let start = currentSessionStartAt else { return 0 }
        return max(0, Int(now().timeIntervalSince(start)))
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

Run:

```bash
xcodebuild test -scheme PersonalSystem -destination 'platform=macOS' -only-testing:PersonalSystemTests/SessionTimerTests
```

Expected: PASS

- [ ] **Step 5: Commit**

```bash
git add PersonalSystem/TimeInvestment/Services/SessionTimer.swift PersonalSystemTests/TimeInvestment/SessionTimerTests.swift
git commit -m "feat: add session timer service"
```

## Task 4: Build the Time Investment View Model

**Files:**
- Create: `PersonalSystem/TimeInvestment/Domain/SessionDraftResult.swift`
- Create: `PersonalSystem/TimeInvestment/ViewModels/TimeInvestmentViewModel.swift`
- Test: `PersonalSystemTests/TimeInvestment/TimeInvestmentViewModelTests.swift`

- [ ] **Step 1: Write failing view model tests**

Write `PersonalSystemTests/TimeInvestment/TimeInvestmentViewModelTests.swift`:

```swift
import XCTest
@testable import PersonalSystem

final class TimeInvestmentViewModelTests: XCTestCase {
    func testSelectingConsumptionCreatesStoredSessionWithoutNote() {
        let store = InMemoryTimeSessionStore()
        let timer = SessionTimer(now: { Date(timeIntervalSince1970: 1_000) })
        let viewModel = TimeInvestmentViewModel(
            timer: timer,
            store: store,
            defaultReferenceDurationSeconds: 1_500
        )

        viewModel.startSession()
        store.now = Date(timeIntervalSince1970: 1_600)
        viewModel.endSession()
        viewModel.completeSession(as: .consumption, productionNote: nil)

        XCTAssertEqual(store.savedSessions.count, 1)
        XCTAssertEqual(store.savedSessions[0].classification, .consumption)
        XCTAssertNil(store.savedSessions[0].productionNote)
    }

    func testEmptyProductionNoteDowngradesSessionToConsumption() {
        let store = InMemoryTimeSessionStore()
        let timer = SessionTimer(now: { Date(timeIntervalSince1970: 1_000) })
        let viewModel = TimeInvestmentViewModel(
            timer: timer,
            store: store,
            defaultReferenceDurationSeconds: 1_500
        )

        viewModel.startSession()
        store.now = Date(timeIntervalSince1970: 1_900)
        viewModel.endSession()
        viewModel.completeSession(as: .production, productionNote: "")

        XCTAssertEqual(store.savedSessions[0].classification, .consumption)
        XCTAssertNil(store.savedSessions[0].productionNote)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
xcodebuild test -scheme PersonalSystem -destination 'platform=macOS' -only-testing:PersonalSystemTests/TimeInvestmentViewModelTests
```

Expected: FAIL with missing `TimeInvestmentViewModel`

- [ ] **Step 3: Add a persistence protocol and in-memory fake**

Update `PersonalSystem/TimeInvestment/Services/TimeSessionStore.swift`:

```swift
import Foundation
import SwiftData

protocol TimeSessionPersisting {
    var now: Date { get set }
    func save(_ session: TimeSession)
    func fetchSessionsForToday() -> [TimeSession]
}

final class InMemoryTimeSessionStore: TimeSessionPersisting {
    var now: Date = Date()
    var savedSessions: [TimeSession] = []

    func save(_ session: TimeSession) {
        savedSessions.append(session.normalizedForPersistence())
    }

    func fetchSessionsForToday() -> [TimeSession] {
        savedSessions.filter { DayBoundary.isSameLocalDay($0.startAt, now) }
    }
}
```

- [ ] **Step 4: Add a draft result model**

Write `PersonalSystem/TimeInvestment/Domain/SessionDraftResult.swift`:

```swift
import Foundation

struct SessionDraftResult: Equatable {
    let startAt: Date
    let endAt: Date
    let referenceDurationSeconds: Int
}
```

- [ ] **Step 5: Implement the view model**

Write `PersonalSystem/TimeInvestment/ViewModels/TimeInvestmentViewModel.swift`:

```swift
import Foundation

@Observable
final class TimeInvestmentViewModel {
    private let timer: SessionTimer
    private let store: TimeSessionPersisting
    private let defaultReferenceDurationSeconds: Int

    private(set) var pendingSessionResult: SessionDraftResult?

    init(
        timer: SessionTimer,
        store: TimeSessionPersisting,
        defaultReferenceDurationSeconds: Int
    ) {
        self.timer = timer
        self.store = store
        self.defaultReferenceDurationSeconds = defaultReferenceDurationSeconds
    }

    var isRunning: Bool { timer.isRunning }

    var todayTotals: DailyTotals {
        TimeSessionStore.dailyTotals(sessions: store.fetchSessionsForToday(), now: store.now)
    }

    func startSession() {
        timer.start(referenceDurationSeconds: defaultReferenceDurationSeconds)
    }

    func endSession() {
        guard let window = timer.stop() else { return }
        pendingSessionResult = SessionDraftResult(
            startAt: window.startAt,
            endAt: window.endAt,
            referenceDurationSeconds: timer.referenceDurationSeconds
        )
    }

    func completeSession(as classification: SessionClassification, productionNote: String?) {
        guard let pendingSessionResult else { return }
        let session = TimeSession(
            startAt: pendingSessionResult.startAt,
            endAt: pendingSessionResult.endAt,
            referenceDurationSeconds: pendingSessionResult.referenceDurationSeconds,
            classification: classification,
            productionNote: productionNote,
            endedByUser: true
        )
        store.save(session)
        self.pendingSessionResult = nil
    }
}
```

- [ ] **Step 6: Run tests to verify they pass**

Run:

```bash
xcodebuild test -scheme PersonalSystem -destination 'platform=macOS' -only-testing:PersonalSystemTests/TimeInvestmentViewModelTests
```

Expected: PASS

- [ ] **Step 7: Commit**

```bash
git add PersonalSystem/TimeInvestment PersonalSystemTests/TimeInvestment
git commit -m "feat: add time investment view model"
```

## Task 5: Build the End Session Classification UI

**Files:**
- Create: `PersonalSystem/TimeInvestment/Views/EndSessionSheet.swift`
- Create: `PersonalSystem/TimeInvestment/Views/EndSessionProductionForm.swift`
- Create: `PersonalSystem/Shared/Formatting/DurationFormatter.swift`

- [ ] **Step 1: Implement a formatter for totals and elapsed time**

Write `PersonalSystem/Shared/Formatting/DurationFormatter.swift`:

```swift
import Foundation

enum DurationFormatter {
    static func short(_ seconds: Int) -> String {
        let hours = seconds / 3_600
        let minutes = (seconds % 3_600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        }
        return "\(minutes)m"
    }
}
```

- [ ] **Step 2: Build the production note form**

Write `PersonalSystem/TimeInvestment/Views/EndSessionProductionForm.swift`:

```swift
import SwiftUI

struct EndSessionProductionForm: View {
    @State var note: String = ""
    let onSubmit: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("这段时间产出了什么？")
                .font(.headline)

            TextField("例如：写完接口设计说明", text: $note)
                .textFieldStyle(.roundedBorder)

            HStack {
                Spacer()
                Button("记为消费") {
                    onSubmit("")
                }
                Button("保存生产") {
                    onSubmit(note)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}
```

- [ ] **Step 3: Build the end-of-session sheet**

Write `PersonalSystem/TimeInvestment/Views/EndSessionSheet.swift`:

```swift
import SwiftUI

struct EndSessionSheet: View {
    @State private var showProductionForm = false
    let onConsumption: () -> Void
    let onProduction: (String) -> Void

    var body: some View {
        if showProductionForm {
            EndSessionProductionForm { note in
                onProduction(note)
            }
        } else {
            VStack(spacing: 16) {
                Text("这段时间属于哪一类？")
                    .font(.headline)

                HStack(spacing: 12) {
                    Button("生产") {
                        showProductionForm = true
                    }
                    .keyboardShortcut(.defaultAction)

                    Button("消费") {
                        onConsumption()
                    }
                }
            }
            .padding(24)
            .frame(width: 320)
        }
    }
}
```

- [ ] **Step 4: Build to verify UI compiles**

Run:

```bash
xcodebuild -scheme PersonalSystem -destination 'platform=macOS' build
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 5: Commit**

```bash
git add PersonalSystem/TimeInvestment/Views PersonalSystem/Shared/Formatting
git commit -m "feat: add session classification sheet"
```

## Task 6: Add the Time Investment Dashboard

**Files:**
- Create: `PersonalSystem/TimeInvestment/Views/TimeInvestmentDashboardView.swift`
- Create: `PersonalSystem/TimeInvestment/Views/StatusDotView.swift`
- Modify: `PersonalSystem/App/AppCoordinator.swift`

- [ ] **Step 1: Create the status dot**

Write `PersonalSystem/TimeInvestment/Views/StatusDotView.swift`:

```swift
import SwiftUI

struct StatusDotView: View {
    let isRunning: Bool

    var body: some View {
        Circle()
            .fill(isRunning ? Color.green : Color.gray)
            .frame(width: 10, height: 10)
    }
}
```

- [ ] **Step 2: Create the module dashboard**

Write `PersonalSystem/TimeInvestment/Views/TimeInvestmentDashboardView.swift`:

```swift
import SwiftUI

struct TimeInvestmentDashboardView: View {
    @Bindable var viewModel: TimeInvestmentViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                StatusDotView(isRunning: viewModel.isRunning)
                Text("时间投入")
                    .font(.title2.bold())
                Spacer()
                Button(viewModel.isRunning ? "结束" : "开始") {
                    if viewModel.isRunning {
                        viewModel.endSession()
                    } else {
                        viewModel.startSession()
                    }
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("今日生产：\(DurationFormatter.short(viewModel.todayTotals.productionSeconds))")
                Text("今日消费：\(DurationFormatter.short(viewModel.todayTotals.consumptionSeconds))")
            }
            .font(.headline)
        }
        .padding(24)
        .sheet(isPresented: .constant(viewModel.pendingSessionResult != nil)) {
            EndSessionSheet(
                onConsumption: {
                    viewModel.completeSession(as: .consumption, productionNote: nil)
                },
                onProduction: { note in
                    viewModel.completeSession(as: .production, productionNote: note)
                }
            )
        }
    }
}
```

- [ ] **Step 3: Show the module dashboard in the coordinator**

Update `PersonalSystem/App/AppCoordinator.swift`:

```swift
import SwiftUI

struct AppCoordinator: View {
    @State private var store = InMemoryTimeSessionStore()
    @State private var timer = SessionTimer()

    var body: some View {
        TimeInvestmentDashboardView(
            viewModel: TimeInvestmentViewModel(
                timer: timer,
                store: store,
                defaultReferenceDurationSeconds: 1_500
            )
        )
    }
}
```

- [ ] **Step 4: Build and smoke test**

Run:

```bash
xcodebuild -scheme PersonalSystem -destination 'platform=macOS' build
```

Expected: `BUILD SUCCEEDED`

Manual check:

```text
Open the app
Click 开始
Wait 5 seconds
Click 结束
Choose 消费
Verify 今日消费 increases
```

- [ ] **Step 5: Commit**

```bash
git add PersonalSystem/App/AppCoordinator.swift PersonalSystem/TimeInvestment/Views
git commit -m "feat: add time investment dashboard"
```

## Task 7: Add the Thin Container Home

**Files:**
- Create: `PersonalSystem/App/ContainerHomeView.swift`
- Create: `PersonalSystem/App/ModuleCardView.swift`
- Modify: `PersonalSystem/App/AppCoordinator.swift`
- Test: `PersonalSystemTests/App/ContainerHomeViewModelTests.swift`

- [ ] **Step 1: Create the module card**

Write `PersonalSystem/App/ModuleCardView.swift`:

```swift
import SwiftUI

struct ModuleCardView: View {
    let title: String
    let subtitle: String
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .opacity(isEnabled ? 1 : 0.6)
        }
        .buttonStyle(.plain)
        .disabled(isEnabled == false)
    }
}
```

- [ ] **Step 2: Create the container home**

Write `PersonalSystem/App/ContainerHomeView.swift`:

```swift
import SwiftUI

struct ContainerHomeView: View {
    let todayProduction: String
    let todayConsumption: String
    let openTimeInvestment: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("个人系统")
                .font(.largeTitle.bold())

            ModuleCardView(
                title: "时间投入",
                subtitle: "今日生产 \(todayProduction) / 今日消费 \(todayConsumption)",
                isEnabled: true,
                action: openTimeInvestment
            )

            ModuleCardView(
                title: "压力管理",
                subtitle: "尚未启用",
                isEnabled: false,
                action: {}
            )

            ModuleCardView(
                title: "目标清晰化",
                subtitle: "尚未启用",
                isEnabled: false,
                action: {}
            )
        }
        .padding(24)
        .frame(minWidth: 520, minHeight: 360)
    }
}
```

- [ ] **Step 3: Switch coordinator to container home**

Update `PersonalSystem/App/AppCoordinator.swift`:

```swift
import SwiftUI

struct AppCoordinator: View {
    @State private var store = InMemoryTimeSessionStore()
    @State private var timer = SessionTimer()
    @State private var showTimeInvestment = false

    var body: some View {
        let viewModel = TimeInvestmentViewModel(
            timer: timer,
            store: store,
            defaultReferenceDurationSeconds: 1_500
        )

        ContainerHomeView(
            todayProduction: DurationFormatter.short(viewModel.todayTotals.productionSeconds),
            todayConsumption: DurationFormatter.short(viewModel.todayTotals.consumptionSeconds),
            openTimeInvestment: {
                showTimeInvestment = true
            }
        )
        .sheet(isPresented: $showTimeInvestment) {
            TimeInvestmentDashboardView(viewModel: viewModel)
        }
    }
}
```

- [ ] **Step 4: Build and manually test container navigation**

Run:

```bash
xcodebuild -scheme PersonalSystem -destination 'platform=macOS' build
```

Expected: `BUILD SUCCEEDED`

Manual check:

```text
Open app home
See three module cards
Click 时间投入
See module sheet open
```

- [ ] **Step 5: Commit**

```bash
git add PersonalSystem/App
git commit -m "feat: add thin container home"
```

## Task 8: Add Menu Bar and Global Hotkey Integration

**Files:**
- Create: `PersonalSystem/TimeInvestment/Services/HotkeyService.swift`
- Create: `PersonalSystem/TimeInvestment/Services/MenuBarService.swift`
- Modify: `PersonalSystem/App/AppCoordinator.swift`
- Modify: `PersonalSystem/PersonalSystemApp.swift`

- [ ] **Step 1: Add a simple hotkey service wrapper**

Write `PersonalSystem/TimeInvestment/Services/HotkeyService.swift`:

```swift
import AppKit

final class HotkeyService {
    private var monitor: Any?
    private let handler: () -> Void

    init(handler: @escaping () -> Void) {
        self.handler = handler
    }

    func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [handler] event in
            let isOptionCommandV = event.modifierFlags.contains([.option, .command]) && event.charactersIgnoringModifiers == "v"
            if isOptionCommandV {
                handler()
            }
        }
    }
}
```

- [ ] **Step 2: Add a menu bar service**

Write `PersonalSystem/TimeInvestment/Services/MenuBarService.swift`:

```swift
import AppKit
import SwiftUI

@MainActor
final class MenuBarService {
    private let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

    func update(isRunning: Bool, elapsedText: String?) {
        let symbol = isRunning ? "●" : "○"
        if let elapsedText, elapsedText.isEmpty == false {
            statusItem.button?.title = "\(symbol) \(elapsedText)"
        } else {
            statusItem.button?.title = symbol
        }
    }
}
```

- [ ] **Step 3: Wire the services into the coordinator**

Update `PersonalSystem/App/AppCoordinator.swift`:

```swift
import SwiftUI

struct AppCoordinator: View {
    @Environment(AppState.self) private var appState

    @State private var store = InMemoryTimeSessionStore()
    @State private var timer = SessionTimer()
    @State private var showTimeInvestment = false
    @State private var menuBarService = MenuBarService()

    var body: some View {
        let viewModel = TimeInvestmentViewModel(
            timer: timer,
            store: store,
            defaultReferenceDurationSeconds: appState.defaultReferenceDurationSeconds
        )

        ContainerHomeView(
            todayProduction: DurationFormatter.short(viewModel.todayTotals.productionSeconds),
            todayConsumption: DurationFormatter.short(viewModel.todayTotals.consumptionSeconds),
            openTimeInvestment: {
                showTimeInvestment = true
            }
        )
        .sheet(isPresented: $showTimeInvestment) {
            TimeInvestmentDashboardView(viewModel: viewModel)
        }
        .task {
            menuBarService.update(isRunning: viewModel.isRunning, elapsedText: nil)
        }
        .onChange(of: viewModel.isRunning) { _, isRunning in
            menuBarService.update(isRunning: isRunning, elapsedText: nil)
        }
    }
}
```

- [ ] **Step 4: Start the hotkey service from app launch**

Update `PersonalSystem/PersonalSystemApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct PersonalSystemApp: App {
    @State private var appState = AppState()
    private let hotkeyService = HotkeyService(handler: {})

    init() {
        hotkeyService.start()
    }

    var body: some Scene {
        WindowGroup("Personal System") {
            AppCoordinator()
                .environment(appState)
        }
        .modelContainer(for: TimeSession.self)

        Settings {
            SettingsView()
                .environment(appState)
        }
    }
}
```

- [ ] **Step 5: Build and manually verify**

Run:

```bash
xcodebuild -scheme PersonalSystem -destination 'platform=macOS' build
```

Expected: `BUILD SUCCEEDED`

Manual check:

```text
Launch app
Observe menu bar shows ○
Start a session from UI
Observe menu bar shows ●
Press the configured global hotkey
Confirm handler is reachable for future wiring
```

- [ ] **Step 6: Commit**

```bash
git add PersonalSystem/TimeInvestment/Services PersonalSystem/App/AppCoordinator.swift PersonalSystem/PersonalSystemApp.swift
git commit -m "feat: add menu bar and hotkey services"
```

## Task 9: Add Settings for the First Module

**Files:**
- Create: `PersonalSystem/App/SettingsView.swift`
- Modify: `PersonalSystem/App/AppState.swift`

- [ ] **Step 1: Build the settings screen**

Write `PersonalSystem/App/SettingsView.swift`:

```swift
import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var appState

    var body: some View {
        Form {
            Section("时间投入") {
                Stepper(
                    value: $appState.defaultReferenceDurationSeconds,
                    in: 300...7_200,
                    step: 300
                ) {
                    Text("默认参考时长：\(appState.defaultReferenceDurationSeconds / 60) 分钟")
                }

                Toggle("菜单栏显示经过时长", isOn: $appState.menuBarShowsElapsedTime)
            }
        }
        .padding(20)
        .frame(width: 420)
    }
}
```

- [ ] **Step 2: Build to verify settings compile**

Run:

```bash
xcodebuild -scheme PersonalSystem -destination 'platform=macOS' build
```

Expected: `BUILD SUCCEEDED`

- [ ] **Step 3: Commit**

```bash
git add PersonalSystem/App/SettingsView.swift PersonalSystem/App/AppState.swift
git commit -m "feat: add v1 settings"
```

## Task 10: Final Verification and Documentation

**Files:**
- Modify: `docs/superpowers/specs/2026-06-10-personal-system-container-design.md`
- Modify: `docs/superpowers/plans/2026-06-10-personal-system-container-v1.md`

- [ ] **Step 1: Run the full test suite**

Run:

```bash
xcodebuild test -scheme PersonalSystem -destination 'platform=macOS'
```

Expected: all tests PASS

- [ ] **Step 2: Run a manual end-to-end scenario**

Manual script:

```text
Open the app
See the thin container home
Open 时间投入
Start a session
Wait 10 seconds
End the session
Choose 生产
Enter "Drafted module boundary notes"
Verify 今日生产 increases
Start another session
Wait 5 seconds
End the session
Choose 生产
Submit empty text
Verify it is stored as 消费
Verify 今日消费 increases
```

- [ ] **Step 3: Add a short implementation note to the spec**

Append this note to `docs/superpowers/specs/2026-06-10-personal-system-container-design.md`:

```markdown
## V1 Implementation Notes

- Native macOS app using SwiftUI and AppKit bridges
- Menu bar state is the default ambient status surface
- First release intentionally avoids task management, notifications, and auto-classification
```

- [ ] **Step 4: Commit final verification**

```bash
git add docs/superpowers/specs/2026-06-10-personal-system-container-design.md docs/superpowers/plans/2026-06-10-personal-system-container-v1.md
git commit -m "docs: finalize v1 implementation plan and verification notes"
```

## Self-Review

### Spec coverage

- Thin container: covered by Tasks 1 and 7
- Single strong module: covered by Tasks 2 through 6
- Silent timer: covered by Task 3 and Task 6
- Manual production/consumption classification: covered by Tasks 4 and 5
- Required production note with downgrade: covered by Tasks 2, 4, 5, and 10
- Home screen with placeholders for future modules: covered by Task 7
- Global settings and reference duration: covered by Task 9
- Menu bar minimal status: covered by Task 8

### Placeholder scan

- No `TODO`, `TBD`, or deferred implementation placeholders remain in the task steps.
- Each code-writing step contains concrete file paths and code.
- Each verification step includes exact commands or manual checks.

### Type consistency

- `TimeSession`, `SessionClassification`, `TimeSessionStore`, `SessionTimer`, and `TimeInvestmentViewModel` names are used consistently across tasks.
- `productionNote` is the only V1 note field and is consistently nullable.


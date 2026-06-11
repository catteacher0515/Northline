# Stress Management Module Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the first version of the Stress Management module with a light module home, an immediate reset flow based on the 10-question checklist, and a stress measurement flow that saves monthly score history.

**Architecture:** Keep the module independent from Time Investment. Model the two flows separately in domain and persistence, add a dedicated store and view model for stress management, and render the module as a lightweight home page plus three focused flow screens. Use the existing local JSON persistence pattern and extend the CLT self-check path instead of assuming `swift test` is available.

**Tech Stack:** Swift 6, SwiftUI, Foundation, existing local JSON persistence, self-check verification via `swift run PersonalSystem --self-check`

---

## File Structure

### Domain

- Create: `Sources/PersonalSystem/StressManagement/Domain/StressResetLevel.swift`
  - Defines the five reset levels and their copy payload.
- Create: `Sources/PersonalSystem/StressManagement/Domain/StressResetQuestion.swift`
  - Defines the 10 reset questions and their level grouping.
- Create: `Sources/PersonalSystem/StressManagement/Domain/StressMeasurementQuestion.swift`
  - Defines the 5 monthly score questions and answer scale labels.
- Create: `Sources/PersonalSystem/StressManagement/Domain/StressResetRecord.swift`
  - Stores one completed reset checklist result.
- Create: `Sources/PersonalSystem/StressManagement/Domain/StressMeasurementRecord.swift`
  - Stores one completed pressure score record.

### Services

- Create: `Sources/PersonalSystem/StressManagement/Services/StressManagementStore.swift`
  - Loads, saves, deletes, and summarizes reset/measurement records.
- Modify: `Sources/PersonalSystem/TimeInvestment/Services/TimeInvestmentSelfCheck.swift`
  - Add stress management verification to the existing CLT self-check entry.

### View Model

- Create: `Sources/PersonalSystem/StressManagement/ViewModels/StressManagementViewModel.swift`
  - Owns module page state, reset answers, measurement answers, submission logic, and latest-history summaries.

### Views

- Create: `Sources/PersonalSystem/StressManagement/Views/StressManagementModuleView.swift`
  - Hosts the stress module navigation state.
- Create: `Sources/PersonalSystem/StressManagement/Views/StressManagementHomeView.swift`
  - Renders module intro, two entry cards, and latest summaries.
- Create: `Sources/PersonalSystem/StressManagement/Views/StressResetChecklistView.swift`
  - Renders the 10-question immediate reset form.
- Create: `Sources/PersonalSystem/StressManagement/Views/StressResetResultView.swift`
  - Renders the matched reset level, copy, action, full text, and delete action.
- Create: `Sources/PersonalSystem/StressManagement/Views/StressMeasurementView.swift`
  - Renders the 5-question monthly measurement form and recent history.

### App Wiring

- Modify: `Sources/PersonalSystem/App/AppState.swift`
  - Hold a `StressManagementViewModel`.
- Modify: `Sources/PersonalSystem/App/ContainerHomeView.swift`
  - Replace the placeholder stress module with the real module view.

---

## Task 1: Add Stress Management Domain Types

**Files:**
- Create: `Sources/PersonalSystem/StressManagement/Domain/StressResetLevel.swift`
- Create: `Sources/PersonalSystem/StressManagement/Domain/StressResetQuestion.swift`
- Create: `Sources/PersonalSystem/StressManagement/Domain/StressMeasurementQuestion.swift`
- Create: `Sources/PersonalSystem/StressManagement/Domain/StressResetRecord.swift`
- Create: `Sources/PersonalSystem/StressManagement/Domain/StressMeasurementRecord.swift`
- Modify: `Sources/PersonalSystem/TimeInvestment/Services/TimeInvestmentSelfCheck.swift`

- [ ] **Step 1: Add a failing self-check for stress reset level lookup**

Append this call inside `TimeInvestmentSelfCheck.runAndExit()` after the existing review checks:

```swift
try verifyStressManagementDomain()
```

Append this helper:

```swift
private static func verifyStressManagementDomain() throws {
    try expect(StressResetQuestion.allCases.count == 10, "stress reset should expose 10 checklist questions")
    try expect(StressMeasurementQuestion.allCases.count == 5, "stress measurement should expose 5 monthly questions")
    try expect(StressResetLevel.first.priority < StressResetLevel.second.priority, "reset levels should preserve recovery order")
}
```

- [ ] **Step 2: Run self-check to verify it fails**

Run:

```bash
swift run PersonalSystem --self-check
```

Expected: FAIL because the stress management domain types do not exist yet.

- [ ] **Step 3: Create the domain types**

Write `Sources/PersonalSystem/StressManagement/Domain/StressResetLevel.swift`:

```swift
import Foundation

enum StressResetLevel: String, Codable, CaseIterable, Equatable, Identifiable {
    case first
    case second
    case third
    case fourth
    case fifth

    var id: String { rawValue }

    var priority: Int {
        switch self {
        case .first: return 1
        case .second: return 2
        case .third: return 3
        case .fourth: return 4
        case .fifth: return 5
        }
    }

    var title: String {
        switch self {
        case .first: return "第一次重置：明确优先级"
        case .second: return "第二次重置：找到一丝宁静"
        case .third: return "第三次重置：身心合一"
        case .fourth: return "第四次重置：喘口气"
        case .fifth: return "第五次重置：展现最好的自己"
        }
    }

    var prompt: String {
        switch self {
        case .first: return "这周最重要的到底是什么？"
        case .second: return "我今天有没有停止给焦虑持续供电？"
        case .third: return "我的身体现在怎么样？"
        case .fourth: return "我今天有没有给自己留缓冲？"
        case .fifth: return "我现在是在调整自己，还是在逼自己证明价值？"
        }
    }

    var action: String {
        switch self {
        case .first: return "只保 2～3 件本周核心事项，并写下今天唯一最重要任务。"
        case .second: return "给自己留 20～30 分钟，做一件不为产出的停供电动作。"
        case .third: return "先检查身体信号，确认今天的睡眠、胸闷、胃和疲惫状态。"
        case .fourth: return "现在给自己留一个缓冲，并写下今天做到哪、明天第一步是什么。"
        case .fifth: return "暂停自责，提醒自己先做够用版，恢复也算进展。"
        }
    }

    var excerpt: [String] {
        switch self {
        case .first:
            return [
                "不是所有重要的事，都要同时推进",
                "一周只抓 2～3 件核心事项",
                "每天只定 1 个最重要任务"
            ]
        case .second:
            return [
                "停供电时间不是拿来顺便推进一下的",
                "休息不是换个地方继续想任务"
            ]
        case .third:
            return [
                "身体不舒服不是小题大做",
                "也要问我的身体今天扛得住吗"
            ]
        case .fourth:
            return [
                "做完一件事，停 10 分钟",
                "不要把所有空档都拿去补进度"
            ]
        case .fifth:
            return [
                "我不需要靠自责来驱动行动",
                "调整不是退步，是能力"
            ]
        }
    }

    var fullText: [String] {
        switch self {
        case .first:
            return [
                "不是所有重要的事，都要同时推进",
                "一周只抓 2～3 件核心事项",
                "每天只定 1 个最重要任务",
                "大任务一定拆开，不能只写准备实习这种总称"
            ]
        case .second:
            return [
                "停供电时间不是拿来顺便推进一下的",
                "休息不是换个地方继续想任务",
                "可以用 Pocket 3 录给自己、爬坡、听音乐、看脱口秀、不为了产出的表达"
            ]
        case .third:
            return [
                "身体不舒服不是小题大做",
                "睡眠乱、胸闷、头昏、胃不舒服，都是压力信号",
                "不要只问今天做了多少事，也要问身体今天扛得住吗"
            ]
        case .fourth:
            return [
                "做完一件事，停 10 分钟",
                "每天只设 1 个主任务块",
                "晚上做收口：写下今天做到哪，明天第一步是什么"
            ]
        case .fifth:
            return [
                "我不需要靠自责来驱动行动",
                "状态波动不等于我不行",
                "先做够用版，再慢慢变好",
                "恢复也算进展"
            ]
        }
    }
}
```

Write `Sources/PersonalSystem/StressManagement/Domain/StressResetQuestion.swift`:

```swift
import Foundation

enum StressResetQuestion: Int, CaseIterable, Identifiable {
    case q1 = 1
    case q2
    case q3
    case q4
    case q5
    case q6
    case q7
    case q8
    case q9
    case q10

    var id: Int { rawValue }

    var level: StressResetLevel {
        switch self {
        case .q1, .q2, .q3: return .first
        case .q4, .q5: return .second
        case .q6, .q7: return .third
        case .q8, .q9: return .fourth
        case .q10: return .fifth
        }
    }

    var prompt: String {
        switch self {
        case .q1: return "这周我是不是又想同时抓太多事情？"
        case .q2: return "如果只能保 2～3 件事，现在最重要的是哪几件？"
        case .q3: return "我今天最重要的那一件事，写清楚了吗？"
        case .q4: return "我今天有没有至少 20～30 分钟，不继续给焦虑供电？"
        case .q5: return "我休息的时候，是真的在休息，还是换个方式继续想任务？"
        case .q6: return "我最近的身体有没有在报警？"
        case .q7: return "我最近有没有明显的晚睡、疲惫、胸闷、胃不舒服、难专注？"
        case .q8: return "我今天做完一件事后，有没有给自己一点缓冲？"
        case .q9: return "我晚上有没有给今天做收口，还是直接带着悬挂感上床？"
        case .q10: return "我现在是在温和调整自己，还是又开始靠逼迫和自责驱动自己？"
        }
    }
}
```

Write `Sources/PersonalSystem/StressManagement/Domain/StressMeasurementQuestion.swift`:

```swift
import Foundation

enum StressMeasurementQuestion: Int, CaseIterable, Identifiable {
    case q1 = 1
    case q2
    case q3
    case q4
    case q5

    var id: Int { rawValue }

    var prompt: String {
        switch self {
        case .q1: return "过去的一个月，你内心的金丝雀向你发出预警的频率是？"
        case .q2: return "过去的一个月，压力让你不堪重负或心神不安的频率是？"
        case .q3: return "过去的一个月，压力让你感到筋疲力尽或精神不振的频率是？"
        case .q4: return "过去的一个月，因为压力巨大而睡眠中断的频率是？"
        case .q5: return "过去的一个月，压力影响到你日常生活的频率是？"
        }
    }

    static let scoreLabels: [Int: String] = [
        0: "从不",
        1: "几乎没有",
        2: "有时",
        3: "比较频繁",
        4: "非常频繁"
    ]
}
```

Write `Sources/PersonalSystem/StressManagement/Domain/StressResetRecord.swift`:

```swift
import Foundation

struct StressResetRecord: Codable, Equatable, Identifiable {
    var id: UUID
    var createdAt: Date
    var answers: [Int: Bool]
    var matchedResetLevelRawValue: String?
    var completed: Bool

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        answers: [Int: Bool],
        matchedResetLevel: StressResetLevel?,
        completed: Bool = true
    ) {
        self.id = id
        self.createdAt = createdAt
        self.answers = answers
        self.matchedResetLevelRawValue = matchedResetLevel?.rawValue
        self.completed = completed
    }

    var matchedResetLevel: StressResetLevel? {
        get {
            guard let matchedResetLevelRawValue else { return nil }
            return StressResetLevel(rawValue: matchedResetLevelRawValue)
        }
        set {
            matchedResetLevelRawValue = newValue?.rawValue
        }
    }
}
```

Write `Sources/PersonalSystem/StressManagement/Domain/StressMeasurementRecord.swift`:

```swift
import Foundation

enum StressPressureLevel: String, Codable, Equatable {
    case low
    case moderate
    case high

    static func from(totalScore: Int) -> StressPressureLevel {
        switch totalScore {
        case 0...6: return .low
        case 7...13: return .moderate
        default: return .high
        }
    }

    var title: String {
        switch self {
        case .low: return "低压"
        case .moderate: return "中压"
        case .high: return "高压"
        }
    }
}

struct StressMeasurementRecord: Codable, Equatable, Identifiable {
    var id: UUID
    var createdAt: Date
    var scores: [Int: Int]
    var totalScore: Int
    var pressureLevelRawValue: String

    init(
        id: UUID = UUID(),
        createdAt: Date = Date(),
        scores: [Int: Int]
    ) {
        self.id = id
        self.createdAt = createdAt
        self.scores = scores
        self.totalScore = scores.values.reduce(0, +)
        self.pressureLevelRawValue = StressPressureLevel.from(totalScore: totalScore).rawValue
    }

    var pressureLevel: StressPressureLevel {
        StressPressureLevel(rawValue: pressureLevelRawValue) ?? .moderate
    }
}
```

- [ ] **Step 4: Run self-check to verify the new domain passes**

Run:

```bash
swift run PersonalSystem --self-check
```

Expected: PASS for the new domain assertions and FAIL later because the stress store/view model do not exist yet.

- [ ] **Step 5: Commit**

```bash
git add Sources/PersonalSystem/StressManagement/Domain Sources/PersonalSystem/TimeInvestment/Services/TimeInvestmentSelfCheck.swift
git commit -m "feat: add stress management domain types"
```

---

## Task 2: Add Stress Management Persistence and Rules

**Files:**
- Create: `Sources/PersonalSystem/StressManagement/Services/StressManagementStore.swift`
- Modify: `Sources/PersonalSystem/TimeInvestment/Services/TimeInvestmentSelfCheck.swift`

- [ ] **Step 1: Add a failing self-check for reset matching and saved history**

Append this call:

```swift
try verifyStressManagementStore()
```

Append this helper:

```swift
private static func verifyStressManagementStore() throws {
    let resetAnswers = [
        1: true,
        2: false,
        3: false,
        4: true,
        5: true,
        6: false,
        7: false,
        8: false,
        9: false,
        10: false
    ]

    let firstMatch = StressManagementStore.matchedResetLevel(for: resetAnswers)
    try expect(firstMatch == .first, "store should return the earliest matched reset level")

    let noMatch = StressManagementStore.matchedResetLevel(for: Dictionary(uniqueKeysWithValues: (1...10).map { ($0, false) }))
    try expect(noMatch == nil, "store should return nil when no reset layer is hit")

    let measurement = StressMeasurementRecord(scores: [1: 4, 2: 3, 3: 3, 4: 2, 5: 4])
    try expect(measurement.totalScore == 16, "measurement should sum all item scores")
    try expect(measurement.pressureLevel == .high, "measurement should map total score to a pressure level")
}
```

- [ ] **Step 2: Run self-check to verify it fails**

Run:

```bash
swift run PersonalSystem --self-check
```

Expected: FAIL because `StressManagementStore` does not exist.

- [ ] **Step 3: Create the store**

Write `Sources/PersonalSystem/StressManagement/Services/StressManagementStore.swift`:

```swift
import Foundation

struct StressManagementSnapshot: Equatable {
    let latestResetRecord: StressResetRecord?
    let latestMeasurementRecord: StressMeasurementRecord?
    let measurementHistory: [StressMeasurementRecord]
}

final class StressManagementStore {
    private static let resetFileName = "stress-reset-records.json"
    private static let measurementFileName = "stress-measurement-records.json"

    private var resetRecords: [StressResetRecord]
    private var measurementRecords: [StressMeasurementRecord]

    init() {
        resetRecords = LocalJSONStore.load([StressResetRecord].self, from: Self.resetFileName) ?? []
        measurementRecords = LocalJSONStore.load([StressMeasurementRecord].self, from: Self.measurementFileName) ?? []
    }

    func saveResetRecord(_ record: StressResetRecord) {
        resetRecords.append(record)
        persistResetRecords()
    }

    func deleteResetRecord(id: UUID) {
        resetRecords.removeAll { $0.id == id }
        persistResetRecords()
    }

    func saveMeasurementRecord(_ record: StressMeasurementRecord) {
        measurementRecords.append(record)
        persistMeasurementRecords()
    }

    func snapshot() -> StressManagementSnapshot {
        StressManagementSnapshot(
            latestResetRecord: resetRecords.sorted { $0.createdAt > $1.createdAt }.first,
            latestMeasurementRecord: measurementRecords.sorted { $0.createdAt > $1.createdAt }.first,
            measurementHistory: measurementRecords.sorted { $0.createdAt > $1.createdAt }
        )
    }

    static func matchedResetLevel(for answers: [Int: Bool]) -> StressResetLevel? {
        StressResetLevel.allCases.sorted { $0.priority < $1.priority }.first { level in
            StressResetQuestion.allCases
                .filter { $0.level == level }
                .contains { answers[$0.rawValue] == true }
        }
    }

    private func persistResetRecords() {
        LocalJSONStore.save(resetRecords, to: Self.resetFileName)
    }

    private func persistMeasurementRecords() {
        LocalJSONStore.save(measurementRecords, to: Self.measurementFileName)
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
- self-check prints `TimeInvestment self-check passed`

- [ ] **Step 5: Commit**

```bash
git add Sources/PersonalSystem/StressManagement/Services/StressManagementStore.swift Sources/PersonalSystem/TimeInvestment/Services/TimeInvestmentSelfCheck.swift
git commit -m "feat: add stress management store"
```

---

## Task 3: Add Stress Management View Model

**Files:**
- Create: `Sources/PersonalSystem/StressManagement/ViewModels/StressManagementViewModel.swift`
- Modify: `Sources/PersonalSystem/TimeInvestment/Services/TimeInvestmentSelfCheck.swift`

- [ ] **Step 1: Add a failing self-check for view model flow state**

Append this call:

```swift
try verifyStressManagementViewModel()
```

Append this helper:

```swift
private static func verifyStressManagementViewModel() throws {
    let store = StressManagementStore()
    let viewModel = StressManagementViewModel(store: store)

    try expect(viewModel.page == .home, "stress module should default to home")

    viewModel.startResetChecklist()
    viewModel.updateResetAnswer(for: .q1, value: true)
    viewModel.submitResetChecklist(now: Date(timeIntervalSince1970: 1_718_100_000))

    try expect(viewModel.page == .resetResult, "submitting reset checklist should move to result page")
    try expect(viewModel.currentResetRecord?.matchedResetLevel == .first, "view model should keep the matched reset result")

    viewModel.startMeasurement()
    viewModel.updateMeasurementScore(for: .q1, value: 4)
    viewModel.updateMeasurementScore(for: .q2, value: 4)
    viewModel.updateMeasurementScore(for: .q3, value: 3)
    viewModel.updateMeasurementScore(for: .q4, value: 2)
    viewModel.updateMeasurementScore(for: .q5, value: 3)
    viewModel.submitMeasurement(now: Date(timeIntervalSince1970: 1_718_100_100))

    try expect(viewModel.latestMeasurementRecord?.totalScore == 16, "view model should persist measurement scores")
}
```

- [ ] **Step 2: Run self-check to verify it fails**

Run:

```bash
swift run PersonalSystem --self-check
```

Expected: FAIL because `StressManagementViewModel` does not exist.

- [ ] **Step 3: Create the view model**

Write `Sources/PersonalSystem/StressManagement/ViewModels/StressManagementViewModel.swift`:

```swift
import Foundation
import SwiftUI

enum StressManagementPage: Equatable {
    case home
    case resetChecklist
    case resetResult
    case measurement
}

@MainActor
final class StressManagementViewModel: ObservableObject {
    @Published var page: StressManagementPage = .home
    @Published private(set) var resetAnswers: [Int: Bool] = [:]
    @Published private(set) var measurementScores: [Int: Int] = [:]
    @Published private(set) var currentResetRecord: StressResetRecord?
    @Published private(set) var latestMeasurementRecord: StressMeasurementRecord?

    private let store: StressManagementStore

    init(store: StressManagementStore = StressManagementStore()) {
        self.store = store
        refreshSnapshot()
    }

    var latestResetSummary: String {
        currentResetRecord?.matchedResetLevel?.title ?? "还没有即时重置记录"
    }

    var latestMeasurementSummary: String {
        guard let latestMeasurementRecord else {
            return "还没有压力测量记录"
        }
        return "\(latestMeasurementRecord.totalScore) 分 · \(latestMeasurementRecord.pressureLevel.title)"
    }

    var measurementHistory: [StressMeasurementRecord] {
        store.snapshot().measurementHistory
    }

    func startResetChecklist() {
        resetAnswers = Dictionary(uniqueKeysWithValues: StressResetQuestion.allCases.map { ($0.rawValue, false) })
        page = .resetChecklist
    }

    func updateResetAnswer(for question: StressResetQuestion, value: Bool) {
        resetAnswers[question.rawValue] = value
    }

    func submitResetChecklist(now: Date = Date()) {
        let matchedLevel = StressManagementStore.matchedResetLevel(for: resetAnswers)
        let record = StressResetRecord(
            createdAt: now,
            answers: resetAnswers,
            matchedResetLevel: matchedLevel,
            completed: true
        )
        store.saveResetRecord(record)
        currentResetRecord = record
        page = .resetResult
    }

    func deleteCurrentResetRecord() {
        guard let currentResetRecord else { return }
        store.deleteResetRecord(id: currentResetRecord.id)
        refreshSnapshot()
        page = .home
    }

    func startMeasurement() {
        measurementScores = Dictionary(uniqueKeysWithValues: StressMeasurementQuestion.allCases.map { ($0.rawValue, 0) })
        page = .measurement
    }

    func updateMeasurementScore(for question: StressMeasurementQuestion, value: Int) {
        measurementScores[question.rawValue] = min(4, max(0, value))
    }

    func submitMeasurement(now: Date = Date()) {
        let record = StressMeasurementRecord(
            id: UUID(),
            createdAt: now,
            scores: measurementScores
        )
        store.saveMeasurementRecord(record)
        latestMeasurementRecord = record
    }

    func goHome() {
        refreshSnapshot()
        page = .home
    }

    private func refreshSnapshot() {
        let snapshot = store.snapshot()
        currentResetRecord = snapshot.latestResetRecord
        latestMeasurementRecord = snapshot.latestMeasurementRecord
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
- self-check passes with the new stress view model assertions

- [ ] **Step 5: Commit**

```bash
git add Sources/PersonalSystem/StressManagement/ViewModels/StressManagementViewModel.swift Sources/PersonalSystem/TimeInvestment/Services/TimeInvestmentSelfCheck.swift
git commit -m "feat: add stress management view model"
```

---

## Task 4: Add Stress Management Views

**Files:**
- Create: `Sources/PersonalSystem/StressManagement/Views/StressManagementModuleView.swift`
- Create: `Sources/PersonalSystem/StressManagement/Views/StressManagementHomeView.swift`
- Create: `Sources/PersonalSystem/StressManagement/Views/StressResetChecklistView.swift`
- Create: `Sources/PersonalSystem/StressManagement/Views/StressResetResultView.swift`
- Create: `Sources/PersonalSystem/StressManagement/Views/StressMeasurementView.swift`

- [ ] **Step 1: Create the module shell and module home**

Write `Sources/PersonalSystem/StressManagement/Views/StressManagementModuleView.swift`:

```swift
import SwiftUI

struct StressManagementModuleView: View {
    @ObservedObject var viewModel: StressManagementViewModel

    var body: some View {
        Group {
            switch viewModel.page {
            case .home:
                StressManagementHomeView(viewModel: viewModel)
            case .resetChecklist:
                StressResetChecklistView(viewModel: viewModel)
            case .resetResult:
                StressResetResultView(viewModel: viewModel)
            case .measurement:
                StressMeasurementView(viewModel: viewModel)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
    }
}
```

Write `Sources/PersonalSystem/StressManagement/Views/StressManagementHomeView.swift`:

```swift
import SwiftUI

struct StressManagementHomeView: View {
    @ObservedObject var viewModel: StressManagementViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            VStack(alignment: .leading, spacing: 8) {
                Text("压力管理")
                    .font(.largeTitle.weight(.semibold))
                Text("把自己重新拉回可运转状态。")
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 12) {
                moduleCard(
                    title: "即时重置",
                    subtitle: "状态乱掉时，先做 10 题自查",
                    action: viewModel.startResetChecklist
                )
                moduleCard(
                    title: "压力测量",
                    subtitle: "记录过去一个月的压力状态",
                    action: viewModel.startMeasurement
                )
            }

            VStack(alignment: .leading, spacing: 12) {
                Text("最近记录")
                    .font(.headline)
                Text("即时重置：\(viewModel.latestResetSummary)")
                Text("压力测量：\(viewModel.latestMeasurementSummary)")
            }

            Spacer(minLength: 0)
        }
    }

    private func moduleCard(title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(subtitle)
                    .foregroundStyle(.secondary)
                Spacer(minLength: 0)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 160, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(Color.secondary.opacity(0.08))
            )
        }
        .buttonStyle(.plain)
    }
}
```

- [ ] **Step 2: Create the checklist and result views**

Write `Sources/PersonalSystem/StressManagement/Views/StressResetChecklistView.swift`:

```swift
import SwiftUI

struct StressResetChecklistView: View {
    @ObservedObject var viewModel: StressManagementViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("即时重置")
                    .font(.largeTitle.weight(.semibold))

                ForEach(StressResetQuestion.allCases) { question in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(question.rawValue). \(question.prompt)")
                            .font(.headline)

                        Toggle("有问题", isOn: Binding(
                            get: { viewModel.resetAnswers[question.rawValue] ?? false },
                            set: { viewModel.updateResetAnswer(for: question, value: $0) }
                        ))
                        .toggleStyle(.switch)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.secondary.opacity(0.08))
                    )
                }

                HStack {
                    Button("返回首页") {
                        viewModel.goHome()
                    }
                    Spacer()
                    Button("提交") {
                        viewModel.submitResetChecklist()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}
```

Write `Sources/PersonalSystem/StressManagement/Views/StressResetResultView.swift`:

```swift
import SwiftUI

struct StressResetResultView: View {
    @ObservedObject var viewModel: StressManagementViewModel

    var body: some View {
        let matchedLevel = viewModel.currentResetRecord?.matchedResetLevel

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("即时重置结果")
                    .font(.largeTitle.weight(.semibold))

                if let matchedLevel {
                    Text(matchedLevel.title)
                        .font(.title2.weight(.semibold))
                    Text(matchedLevel.prompt)
                        .foregroundStyle(.secondary)
                    Text("现在就去做：\(matchedLevel.action)")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("原文全文")
                            .font(.headline)
                        ForEach(matchedLevel.fullText, id: \.self) { line in
                            Text("• \(line)")
                        }
                    }
                } else {
                    Text("当前未见明显失衡。")
                        .font(.title3.weight(.semibold))
                    Text("可以直接回首页，或按需要自行查看五次重置内容。")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Button("删除这次记录") {
                        viewModel.deleteCurrentResetRecord()
                    }
                    Spacer()
                    Button("返回首页") {
                        viewModel.goHome()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}
```

- [ ] **Step 3: Create the measurement view**

Write `Sources/PersonalSystem/StressManagement/Views/StressMeasurementView.swift`:

```swift
import SwiftUI

struct StressMeasurementView: View {
    @ObservedObject var viewModel: StressManagementViewModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("压力测量")
                    .font(.largeTitle.weight(.semibold))

                ForEach(StressMeasurementQuestion.allCases) { question in
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\(question.rawValue). \(question.prompt)")
                            .font(.headline)

                        Picker("分值", selection: Binding(
                            get: { viewModel.measurementScores[question.rawValue] ?? 0 },
                            set: { viewModel.updateMeasurementScore(for: question, value: $0) }
                        )) {
                            ForEach(0...4, id: \.self) { score in
                                Text("\(score) · \(StressMeasurementQuestion.scoreLabels[score] ?? "")").tag(score)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color.secondary.opacity(0.08))
                    )
                }

                if let latestMeasurementRecord = viewModel.latestMeasurementRecord {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("最近一次结果")
                            .font(.headline)
                        Text("总分：\(latestMeasurementRecord.totalScore)")
                        Text("区间：\(latestMeasurementRecord.pressureLevel.title)")
                    }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("历史记录")
                        .font(.headline)
                    ForEach(viewModel.measurementHistory.prefix(5)) { record in
                        Text("\(record.createdAt.formatted(date: .abbreviated, time: .shortened)) · \(record.totalScore) 分 · \(record.pressureLevel.title)")
                    }
                }

                HStack {
                    Button("返回首页") {
                        viewModel.goHome()
                    }
                    Spacer()
                    Button("保存测量") {
                        viewModel.submitMeasurement()
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
    }
}
```

- [ ] **Step 4: Run build**

Run:

```bash
swift build
```

Expected: PASS because all view dependencies now exist.

- [ ] **Step 5: Commit**

```bash
git add Sources/PersonalSystem/StressManagement/Views
git commit -m "feat: add stress management module views"
```

---

## Task 5: Wire Stress Management into the App Shell

**Files:**
- Modify: `Sources/PersonalSystem/App/AppState.swift`
- Modify: `Sources/PersonalSystem/App/ContainerHomeView.swift`

- [ ] **Step 1: Add the stress view model to app state**

Update `Sources/PersonalSystem/App/AppState.swift` to include:

```swift
let stressManagementViewModel: StressManagementViewModel
```

and initialize it in `init()`:

```swift
self.stressManagementViewModel = StressManagementViewModel()
```

- [ ] **Step 2: Replace the placeholder module view**

Update `Sources/PersonalSystem/App/ContainerHomeView.swift`:

1. Add:

```swift
@ObservedObject var stressManagementViewModel: StressManagementViewModel
```

2. Update the stress module subtitle:

```swift
(.stressManagement, "压力管理", "即时重置 / 压力测量")
```

3. Replace the `.stressManagement` branch with:

```swift
case .stressManagement:
    StressManagementModuleView(viewModel: stressManagementViewModel)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
```

4. Update `AppCoordinator` usage indirectly through the existing initializer call chain so it passes `appState.stressManagementViewModel`.

- [ ] **Step 3: Run build and self-check**

Run:

```bash
swift build
swift run PersonalSystem --self-check
```

Expected:

- build succeeds
- self-check still prints `TimeInvestment self-check passed`

- [ ] **Step 4: Commit**

```bash
git add Sources/PersonalSystem/App/AppState.swift Sources/PersonalSystem/App/ContainerHomeView.swift Sources/PersonalSystem/App/AppCoordinator.swift
git commit -m "feat: wire stress management module into app shell"
```

---

## Self-Review

### Spec Coverage

- 轻首页 + 双流程：Task 4 and Task 5
- 即时重置 10 题自查：Task 1 and Task 4
- 最早失衡层级判定：Task 2
- 压力测量 5 题记录化：Task 1, Task 2, Task 3, and Task 4
- 即时重置记录默认保存且可删除：Task 2, Task 3, and Task 4
- 压力测量历史回看：Task 2, Task 3, and Task 4

No spec requirement is left without an implementation task.

### Placeholder Scan

- No `TODO`, `TBD`, or “implement later” markers remain.
- Each step contains concrete code or concrete commands.
- Verification steps specify exact commands and expected outcomes.

### Type Consistency

- `StressResetLevel`, `StressResetQuestion`, `StressMeasurementQuestion`, `StressResetRecord`, and `StressMeasurementRecord` are defined before later tasks use them.
- `StressManagementStore` owns persistence and matching.
- `StressManagementViewModel` owns page state and submission logic.
- `StressManagementModuleView` and subviews consume view model state without duplicating rules.

## Execution Handoff

Plan complete and saved to `docs/superpowers/plans/2026-06-11-stress-management-module.md`. Two execution options:

**1. Subagent-Driven (recommended)** - I dispatch a fresh subagent per task, review between tasks, fast iteration

**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints

Which approach?

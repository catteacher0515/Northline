import AppKit
import SwiftUI

enum TimeMateViewMode {
    case record
    case review
}

struct TimeInvestmentMenuBarView: View {
    @ObservedObject var viewModel: TimeInvestmentViewModel
    @Binding var viewMode: TimeMateViewMode

    @State private var isEndingSession = false
    @State private var endedAt = Date()
    @State private var taskName = ""
    @State private var selectedCategory: TimeSessionCategory = .other
    @State private var joyScore = 6.0
    @State private var meaningScore = 6.0
    @State private var note = ""
    @State private var reviewScope: ReviewScope = .day
    @State private var selectedDay = Date()
    @State private var customStartDate = Calendar.current.date(byAdding: .day, value: -6, to: Date()) ?? Date()
    @State private var customEndDate = Date()
    @State private var exportStatusText = ""

    var body: some View {
        Group {
            switch viewMode {
            case .record:
                recordPage
                    .frame(width: 360)
            case .review:
                reviewPage
                    .frame(width: 700)
            }
        }
        .padding(16)
        .onChange(of: viewModel.isSessionRunning) { _, isRunning in
            if isRunning == false {
                resetDraft()
            }
        }
        .onChange(of: taskName) { _, newValue in
            selectedCategory = TimeSessionCategory.classify(taskName: newValue)
        }
    }

    private var recordPage: some View {
        VStack(alignment: .leading, spacing: 14) {
            header(showReviewButton: true)
            recordSummaryStrip

            if viewModel.isSessionRunning {
                if isEndingSession {
                    endSessionForm
                } else {
                    runningSessionSection
                }
            } else {
                idleSessionSection
            }

            todayTimeline
            recentConfirmation

            Text("快捷键可在 Time Mate 设置中调整。")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private var recordSummaryStrip: some View {
        HStack(spacing: 10) {
            MetricPill(title: "今日记录", value: DurationFormatter.formatted(recordedSecondsToday()))
            MetricPill(title: "覆盖率", value: "\(coveragePercentToday())%")
        }
    }

    private func header(showReviewButton: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Time Mate")
                    .font(.system(.headline, design: .rounded).weight(.bold))
                Spacer()
                if showReviewButton {
                    Button("回顾") {
                        viewMode = .review
                    }
                    .buttonStyle(.bordered)
                } else {
                    Text(Date().formatted(date: .abbreviated, time: .omitted))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }

            Text(viewModel.isSessionRunning ? "正在记录这段时间" : "点击开始，结束后再补任务")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var runningSessionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(DurationFormatter.formatted(viewModel.elapsedSeconds(now: context.date)))
                    .font(.system(size: 34, weight: .semibold, design: .rounded))
                    .monospacedDigit()
            }

            Button {
                endedAt = Date()
                isEndingSession = true
            } label: {
                Text("结束")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red.opacity(0.82))
        }
        .padding(14)
        .background(TimeGlassPanel(cornerRadius: 18))
    }

    private var idleSessionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("不需要先想分类，先把计时打开。")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button {
                viewModel.startSession()
            } label: {
                Text("开始")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green.opacity(0.76))
        }
        .padding(14)
        .background(TimeGlassPanel(cornerRadius: 18))
    }

    private var endSessionForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("补上这段时间")
                .font(.subheadline.weight(.semibold))

            TextField("任务名，例如：学习、吃饭、刷视频", text: $taskName)
                .textFieldStyle(.roundedBorder)

            Picker("分类", selection: $selectedCategory) {
                ForEach(TimeSessionCategory.allCases) { category in
                    Text(category.title).tag(category)
                }
            }
            .pickerStyle(.menu)

            scoreSlider(title: "快乐值", value: $joyScore)
            scoreSlider(title: "意义值", value: $meaningScore)

            TextField("备注，可选", text: $note)
                .textFieldStyle(.roundedBorder)

            HStack {
                Button("放弃") {
                    resetDraft()
                }

                Spacer()

                Button("保存") {
                    saveEndedSession()
                }
                .buttonStyle(.borderedProminent)
                .disabled(taskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(14)
        .background(TimeGlassPanel(cornerRadius: 18))
    }

    private func scoreSlider(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                Spacer()
                Text("\(Int(value.wrappedValue))")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            Slider(value: value, in: 1...10, step: 1)
        }
    }

    private var todayTimeline: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日色块")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(spacing: 1) {
                let slots = todaySlots()
                ForEach(slots.indices, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(slots[index].map(color(for:)) ?? Color.secondary.opacity(0.12))
                        .frame(height: 22)
                        .overlay(alignment: .top) {
                            Color.white.opacity(slots[index] == nil ? 0.02 : 0.12)
                                .frame(height: 1)
                        }
                }
            }
            .padding(7)
            .background(TimeRailBackground())
        }
        .padding(12)
        .background(TimeGlassPanel(cornerRadius: 18))
    }

    private var recentConfirmation: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("最近保存")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            let records = viewModel.recentSessions(limit: 3)
            if records.isEmpty {
                Text("还没有记录。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(records, id: \.id) { session in
                        RecordRow(session: session, color: color(for: session.category))
                    }
                }
            }
        }
        .padding(12)
        .background(TimeGlassPanel(cornerRadius: 18))
    }

    private var reviewPage: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("记录回顾")
                        .font(.system(.title2, design: .rounded).weight(.bold))
                    Text("按天或按时间范围看过去的色块。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Button(exportStatusText.isEmpty ? "导出" : exportStatusText) {
                    exportReviewFiles()
                }
                .buttonStyle(.borderedProminent)

                Button("返回记录") {
                    viewMode = .record
                }
                .buttonStyle(.bordered)
            }

            reviewControls
            reviewSummaryStrip
            reviewColorBlocks
            reviewRecordList
        }
    }

    private var reviewSummaryStrip: some View {
        let records = reviewRangeSessions()
        let roundedSeconds = records.reduce(0) { $0 + $1.roundedSeconds }
        let dayCount = max(1, reviewDays().count)
        let coverage = min(100, Int((Double(roundedSeconds) / Double(dayCount * 24 * 60 * 60) * 100).rounded()))

        return HStack(spacing: 10) {
            MetricPill(title: "范围记录", value: DurationFormatter.formatted(roundedSeconds))
            MetricPill(title: "覆盖率", value: "\(coverage)%")
            MetricPill(title: "记录数", value: "\(records.count)")
        }
    }

    private var reviewControls: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("范围", selection: $reviewScope) {
                ForEach(ReviewScope.allCases) { scope in
                    Text(scope.title).tag(scope)
                }
            }
            .pickerStyle(.segmented)

            switch reviewScope {
            case .day:
                DatePicker("选择日期", selection: $selectedDay, displayedComponents: .date)
                    .datePickerStyle(.compact)
            case .last7Days:
                Text("展示包含今天在内的最近 7 天。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .custom:
                HStack {
                    DatePicker("开始", selection: $customStartDate, displayedComponents: .date)
                    DatePicker("结束", selection: $customEndDate, displayedComponents: .date)
                }
                .datePickerStyle(.compact)
            }
        }
        .padding(12)
        .background(TimeGlassPanel(cornerRadius: 18))
    }

    private var reviewColorBlocks: some View {
        let rows = reviewDays()
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("色块")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("每格 15 min")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            if rows.isEmpty {
                Text("这个范围还没有记录。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(rows, id: \.self) { day in
                            DayBlockRow(
                                day: day,
                                slots: slots(for: day),
                                colorForCategory: color(for:)
                            )
                        }
                    }
                }
                .frame(height: colorBlockHeight(for: rows.count))
            }
        }
        .padding(12)
        .background(TimeGlassPanel(cornerRadius: 18))
    }

    private var reviewRecordList: some View {
        let records = reviewRangeSessions()
        return VStack(alignment: .leading, spacing: 8) {
            Text("记录明细")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            if records.isEmpty {
                Text("没有可展示的记录。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(records, id: \.id) { session in
                            RecordRow(session: session, color: color(for: session.category), showsDate: reviewScope != .day)
                        }
                    }
                }
                .frame(maxHeight: 210)
            }
        }
        .padding(12)
        .background(TimeGlassPanel(cornerRadius: 18))
    }

    private func saveEndedSession() {
        let draft = SessionDraftResult(
            taskName: taskName,
            category: selectedCategory,
            joyScore: Int(joyScore),
            meaningScore: Int(meaningScore),
            note: note
        )
        viewModel.completeSession(using: draft, now: endedAt)
    }

    private func resetDraft() {
        isEndingSession = false
        taskName = ""
        selectedCategory = .other
        joyScore = 6
        meaningScore = 6
        note = ""
        endedAt = Date()
    }

    private func todaySlots() -> [TimeSessionCategory?] {
        slots(for: Date())
    }

    private func recordedSecondsToday() -> Int {
        viewModel.todaySessions().reduce(0) { $0 + $1.roundedSeconds }
    }

    private func coveragePercentToday() -> Int {
        min(100, Int((Double(recordedSecondsToday()) / Double(24 * 60 * 60) * 100).rounded()))
    }

    private func slots(for day: Date) -> [TimeSessionCategory?] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: day)
        var slots = Array<TimeSessionCategory?>(repeating: nil, count: 96)

        for session in viewModel.sessions(on: day) {
            let startMinutes = max(0, Int(session.startAt.timeIntervalSince(startOfDay) / 60))
            let startIndex = min(95, max(0, startMinutes / 15))
            let slotCount = max(1, session.roundedSeconds / (15 * 60))
            let endIndex = min(96, startIndex + slotCount)

            guard startIndex < endIndex else {
                continue
            }

            for index in startIndex..<endIndex {
                slots[index] = session.category
            }
        }

        return slots
    }

    private func reviewRangeSessions() -> [TimeSession] {
        let interval = reviewDateBounds()
        return viewModel.sessions(from: interval.start, to: interval.end)
    }

    private func exportReviewFiles() {
        let interval = reviewDateBounds()
        let package = TimeSessionExportFormatter.package(
            sessions: viewModel.sessions(from: interval.start, to: interval.end),
            startDate: interval.start,
            endDate: interval.end
        )

        let panel = NSOpenPanel()
        panel.title = "选择导出位置"
        panel.prompt = "导出"
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true
        panel.allowsMultipleSelection = false

        guard panel.runModal() == .OK, let parentURL = panel.url else {
            return
        }

        let exportURL = parentURL.appendingPathComponent(package.folderName, isDirectory: true)

        do {
            try FileManager.default.createDirectory(at: exportURL, withIntermediateDirectories: true)

            for (fileName, content) in package.files {
                try content.write(
                    to: exportURL.appendingPathComponent(fileName),
                    atomically: true,
                    encoding: .utf8
                )
            }

            exportStatusText = "已导出"
        } catch {
            exportStatusText = "导出失败"
            NSLog("Time Mate export failed: %@", String(describing: error))
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
            exportStatusText = ""
        }
    }

    private func reviewDays() -> [Date] {
        let interval = reviewDateBounds()
        return viewModel.days(from: interval.start, to: interval.end)
    }

    private func colorBlockHeight(for dayCount: Int) -> CGFloat {
        min(260, max(34, CGFloat(dayCount) * 28))
    }

    private func reviewDateBounds() -> (start: Date, end: Date) {
        let calendar = Calendar.current

        switch reviewScope {
        case .day:
            return (selectedDay, selectedDay)
        case .last7Days:
            let today = calendar.startOfDay(for: Date())
            let start = calendar.date(byAdding: .day, value: -6, to: today) ?? today
            return (start, today)
        case .custom:
            return (customStartDate, customEndDate)
        }
    }

    private func color(for category: TimeSessionCategory) -> Color {
        switch category {
        case .sleep:
            return Color(red: 0.73, green: 0.75, blue: 0.78)
        case .foodExercise:
            return Color(red: 0.34, green: 0.62, blue: 0.43)
        case .studyWork:
            return Color(red: 0.31, green: 0.48, blue: 0.84)
        case .entertainment:
            return Color(red: 0.82, green: 0.34, blue: 0.32)
        case .other:
            return Color(red: 0.72, green: 0.66, blue: 0.56)
        }
    }
}

private struct TimeGlassPanel: View {
    var cornerRadius: CGFloat = 18

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0.105),
                        Color.white.opacity(0.055)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.18),
                                Color.white.opacity(0.055)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .shadow(color: Color.black.opacity(0.18), radius: 18, x: 0, y: 12)
    }
}

private struct TimeRailBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(Color.black.opacity(0.22))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.06), lineWidth: 1)
            }
    }
}

private struct MetricPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.caption.monospacedDigit().weight(.semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(TimeGlassPanel(cornerRadius: 14))
    }
}

private enum ReviewScope: String, CaseIterable, Identifiable {
    case day
    case last7Days
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .day:
            return "某一天"
        case .last7Days:
            return "最近 7 天"
        case .custom:
            return "自定义"
        }
    }
}

private struct DayBlockRow: View {
    let day: Date
    let slots: [TimeSessionCategory?]
    let colorForCategory: (TimeSessionCategory) -> Color

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            VStack(alignment: .leading, spacing: 2) {
                Text(day.formatted(.dateTime.month(.twoDigits).day(.twoDigits)))
                    .font(.caption2.monospacedDigit().weight(.semibold))
                Text(day.formatted(.dateTime.weekday(.abbreviated)))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(width: 48, alignment: .leading)

            HStack(spacing: 1) {
                ForEach(slots.indices, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 1.5, style: .continuous)
                        .fill(slots[index].map(colorForCategory) ?? Color.secondary.opacity(0.12))
                        .frame(height: 20)
                        .overlay(alignment: .top) {
                            Color.white.opacity(slots[index] == nil ? 0.02 : 0.10)
                                .frame(height: 1)
                        }
                }
            }
            .padding(6)
            .background(TimeRailBackground())
        }
    }
}

private struct RecordRow: View {
    let session: TimeSession
    let color: Color
    var showsDate = false

    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(session.taskName ?? "未命名")
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)

                    Spacer()

                    Text(showsDate ? "\(dateText) \(timeRange)" : timeRange)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(.secondary)
                }

                Text("\(session.category.title) · \(DurationFormatter.formatted(session.roundedSeconds)) · 快 \(session.joyScore ?? 6) · 义 \(session.meaningScore ?? 6)")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)

                if let note = session.note, note.isEmpty == false {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
    }

    private var timeRange: String {
        "\(session.startAt.formatted(date: .omitted, time: .shortened))-\(session.endAt.formatted(date: .omitted, time: .shortened))"
    }

    private var dateText: String {
        session.startAt.formatted(.dateTime.month(.twoDigits).day(.twoDigits))
    }
}

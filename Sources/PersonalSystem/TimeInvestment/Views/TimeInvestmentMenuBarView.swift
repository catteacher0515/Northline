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
                .foregroundStyle(ScrapbookPalette.mutedInk)
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
                HStack(spacing: 8) {
                    Text("Time Mate")
                        .font(.system(.title3, design: .rounded).weight(.black))
                        .foregroundStyle(ScrapbookPalette.ink)

                    if showReviewButton {
                        SunSticker()
                            .frame(width: 28, height: 28)
                    }
                }
                Spacer()
                if showReviewButton {
                    Button("回顾") {
                        viewMode = .review
                    }
                    .buttonStyle(.bordered)
                    .tint(ScrapbookPalette.purpleTape)
                } else {
                    Text(Date().formatted(date: .abbreviated, time: .omitted))
                        .font(.caption.weight(.medium))
                        .foregroundStyle(ScrapbookPalette.mutedInk)
                }
            }

            Text(viewModel.isSessionRunning ? "正在记录这段时间" : "今天先记下来，结束后再补任务")
                .font(.caption)
                .foregroundStyle(ScrapbookPalette.mutedInk)
        }
        .padding(.bottom, 2)
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
        .background(ScrapbookPanel(tint: ScrapbookPalette.whitePaper, rotation: -0.7))
    }

    private var idleSessionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("不用先想分类，先把计时打开。")
                .font(.subheadline)
                .foregroundStyle(ScrapbookPalette.mutedInk)

            Button {
                viewModel.startSession()
            } label: {
                Text("开始")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(ScrapbookPalette.greenTape)
        }
        .padding(14)
        .background(ScrapbookPanel(tint: ScrapbookPalette.yellowNote, rotation: -0.5))
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
        .background(ScrapbookPanel(tint: ScrapbookPalette.whitePaper, rotation: 0.4))
    }

    private func scoreSlider(title: String, value: Binding<Double>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ScrapbookPalette.ink)
                Spacer()
                Text("\(Int(value.wrappedValue))")
                    .font(.caption.monospacedDigit().weight(.semibold))
                    .foregroundStyle(ScrapbookPalette.mutedInk)
            }

            Slider(value: value, in: 1...10, step: 1)
        }
    }

    private var todayTimeline: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("今日色块")
                .font(.caption.weight(.semibold))
                .foregroundStyle(ScrapbookPalette.ink)

            HStack(spacing: 1) {
                let slots = todaySlots()
                ForEach(slots.indices, id: \.self) { index in
                    RoundedRectangle(cornerRadius: 2, style: .continuous)
                        .fill(slots[index].map(color(for:)) ?? ScrapbookPalette.blankSlot)
                        .frame(height: 22)
                        .overlay(alignment: .top) {
                            Color.white.opacity(slots[index] == nil ? 0.18 : 0.28)
                                .frame(height: 1)
                        }
                }
            }
            .padding(7)
            .background(TapeRailBackground())
        }
        .padding(12)
        .background(ScrapbookPanel(tint: ScrapbookPalette.whitePaper, rotation: 0.6))
    }

    private var recentConfirmation: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("最近保存")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ScrapbookPalette.ink)
            }

            let records = viewModel.recentSessions(limit: 3)
            if records.isEmpty {
                Text("还没有记录。")
                    .font(.caption)
                    .foregroundStyle(ScrapbookPalette.mutedInk)
            } else {
                LazyVStack(alignment: .leading, spacing: 8) {
                    ForEach(records, id: \.id) { session in
                        RecordRow(session: session, color: color(for: session.category))
                    }
                }
            }
        }
        .padding(12)
        .background(ScrapbookPanel(tint: ScrapbookPalette.yellowNote, rotation: -0.8))
    }

    private var reviewPage: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("记录回顾")
                        .font(.system(.title2, design: .rounded).weight(.black))
                        .foregroundStyle(ScrapbookPalette.ink)
                    Text("按天或按时间范围看过去的色块。")
                        .font(.caption)
                        .foregroundStyle(ScrapbookPalette.mutedInk)
                }

                Spacer()

                Button(exportStatusText.isEmpty ? "导出" : exportStatusText) {
                    exportReviewFiles()
                }
                .buttonStyle(.borderedProminent)
                .tint(ScrapbookPalette.blueTape)

                Button("返回记录") {
                    viewMode = .record
                }
                .buttonStyle(.bordered)
                .tint(ScrapbookPalette.purpleTape)
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
                ScrapbookDateStepper(title: "选择日期", date: $selectedDay)
            case .last7Days:
                Text("展示包含今天在内的最近 7 天。")
                    .font(.caption)
                    .foregroundStyle(ScrapbookPalette.mutedInk)
            case .custom:
                HStack {
                    ScrapbookDateStepper(title: "开始", date: $customStartDate)
                    ScrapbookDateStepper(title: "结束", date: $customEndDate)
                }
            }
        }
        .padding(12)
        .background(ScrapbookPanel(tint: ScrapbookPalette.purpleTape.opacity(0.74), rotation: -0.5))
    }

    private var reviewColorBlocks: some View {
        let rows = reviewDays()
        return VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("色块")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(ScrapbookPalette.ink)
                Spacer()
                Text("每格 15 min")
                    .font(.caption2)
                    .foregroundStyle(ScrapbookPalette.mutedInk)
            }

            if rows.isEmpty {
                Text("这个范围还没有记录。")
                    .font(.caption)
                    .foregroundStyle(ScrapbookPalette.mutedInk)
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
        .background(ScrapbookPanel(tint: ScrapbookPalette.whitePaper, rotation: 0.5))
    }

    private var reviewRecordList: some View {
        let records = reviewRangeSessions()
        return VStack(alignment: .leading, spacing: 8) {
            Text("记录明细")
                .font(.caption.weight(.semibold))
                .foregroundStyle(ScrapbookPalette.ink)

            if records.isEmpty {
                Text("没有可展示的记录。")
                    .font(.caption)
                    .foregroundStyle(ScrapbookPalette.mutedInk)
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
        .background(ScrapbookPanel(tint: ScrapbookPalette.yellowNote, rotation: -0.4))
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
            return Color(red: 0.73, green: 0.74, blue: 0.73)
        case .foodExercise:
            return Color(red: 0.48, green: 0.76, blue: 0.53)
        case .studyWork:
            return Color(red: 0.42, green: 0.62, blue: 0.94)
        case .entertainment:
            return Color(red: 0.93, green: 0.42, blue: 0.42)
        case .other:
            return Color(red: 0.76, green: 0.66, blue: 0.53)
        }
    }
}

private enum ScrapbookPalette {
    static let ink = Color(red: 0.095, green: 0.083, blue: 0.066)
    static let mutedInk = Color(red: 0.36, green: 0.32, blue: 0.27)
    static let whitePaper = Color(red: 0.985, green: 0.968, blue: 0.925)
    static let yellowNote = Color(red: 0.965, green: 0.835, blue: 0.285)
    static let purpleTape = Color(red: 0.775, green: 0.675, blue: 0.940)
    static let greenTape = Color(red: 0.455, green: 0.765, blue: 0.510)
    static let blueTape = Color(red: 0.420, green: 0.620, blue: 0.930)
    static let blankSlot = Color(red: 0.825, green: 0.810, blue: 0.765)
}

private struct ScrapbookPanel: View {
    var tint: Color
    var rotation: Double = 0
    var cornerRadius: CGFloat = 14

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
            .fill(tint)
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(ScrapbookPalette.ink.opacity(0.82), lineWidth: 1.8)
                    .offset(x: 1.2, y: 1.2)
            }
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.22), lineWidth: 1)
                    .padding(2)
            }
            .rotationEffect(.degrees(rotation))
            .shadow(color: Color.black.opacity(0.16), radius: 5, x: 3, y: 4)
    }
}

private struct TapeRailBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 9, style: .continuous)
            .fill(Color.white.opacity(0.48))
            .overlay {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .strokeBorder(ScrapbookPalette.ink.opacity(0.45), lineWidth: 1.3)
            }
            .shadow(color: Color.black.opacity(0.08), radius: 2, x: 1, y: 2)
    }
}

private struct MetricPill: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(title)
                .font(.caption2.weight(.medium))
                .foregroundStyle(ScrapbookPalette.mutedInk)
            Text(value)
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(ScrapbookPalette.ink)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(ScrapbookPanel(tint: ScrapbookPalette.whitePaper, rotation: 0.5, cornerRadius: 12))
    }
}

private struct SunSticker: View {
    var body: some View {
        ZStack {
            ForEach(0..<10, id: \.self) { index in
                Capsule()
                    .fill(Color(red: 0.95, green: 0.78, blue: 0.16))
                    .frame(width: 4, height: 9)
                    .offset(y: -13)
                    .rotationEffect(.degrees(Double(index) * 36))
            }

            Circle()
                .fill(Color(red: 0.98, green: 0.83, blue: 0.17))
                .overlay {
                    Circle()
                        .strokeBorder(Color.white.opacity(0.8), lineWidth: 2)
                }

            HStack(spacing: 5) {
                Circle().fill(ScrapbookPalette.ink).frame(width: 2.5, height: 2.5)
                Circle().fill(ScrapbookPalette.ink).frame(width: 2.5, height: 2.5)
            }
            .offset(y: -2)

            Path { path in
                path.move(to: CGPoint(x: 10, y: 16))
                path.addQuadCurve(to: CGPoint(x: 18, y: 16), control: CGPoint(x: 14, y: 20))
            }
            .stroke(ScrapbookPalette.ink, style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
        }
    }
}

private struct ScrapbookDateStepper: View {
    let title: String
    @Binding var date: Date

    var body: some View {
        HStack(spacing: 7) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(ScrapbookPalette.ink)

            Button {
                shiftDay(-1)
            } label: {
                Image(systemName: "chevron.left")
                    .font(.caption2.weight(.bold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(ScrapbookPalette.ink)

            Text(date.formatted(.dateTime.year().month(.twoDigits).day(.twoDigits)))
                .font(.caption.monospacedDigit().weight(.bold))
                .foregroundStyle(ScrapbookPalette.ink)
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(ScrapbookPalette.whitePaper.opacity(0.86))
                        .overlay {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(ScrapbookPalette.ink.opacity(0.38), lineWidth: 1.2)
                        }
                }

            Button {
                shiftDay(1)
            } label: {
                Image(systemName: "chevron.right")
                    .font(.caption2.weight(.bold))
            }
            .buttonStyle(.plain)
            .foregroundStyle(ScrapbookPalette.ink)
        }
    }

    private func shiftDay(_ value: Int) {
        date = Calendar.current.date(byAdding: .day, value: value, to: date) ?? date
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
                        .fill(slots[index].map(colorForCategory) ?? ScrapbookPalette.blankSlot)
                        .frame(height: 20)
                        .overlay(alignment: .top) {
                            Color.white.opacity(slots[index] == nil ? 0.18 : 0.28)
                                .frame(height: 1)
                        }
                }
            }
            .padding(6)
            .background(TapeRailBackground())
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
                .overlay {
                    Circle().strokeBorder(ScrapbookPalette.ink.opacity(0.28), lineWidth: 0.7)
                }
                .padding(.top, 5)

            VStack(alignment: .leading, spacing: 3) {
                HStack(alignment: .firstTextBaseline) {
                    Text(session.taskName ?? "未命名")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(ScrapbookPalette.ink)
                        .lineLimit(1)

                    Spacer()

                    Text(showsDate ? "\(dateText) \(timeRange)" : timeRange)
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(ScrapbookPalette.mutedInk)
                }

                Text("\(session.category.title) · \(DurationFormatter.formatted(session.roundedSeconds)) · 快 \(session.joyScore ?? 6) · 义 \(session.meaningScore ?? 6)")
                    .font(.caption2)
                    .foregroundStyle(ScrapbookPalette.mutedInk)
                    .lineLimit(1)

                if let note = session.note, note.isEmpty == false {
                    Text(note)
                        .font(.caption2)
                        .foregroundStyle(ScrapbookPalette.mutedInk)
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

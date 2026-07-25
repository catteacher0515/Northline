import SwiftUI

struct TimeInvestmentMenuBarView: View {
    @ObservedObject var viewModel: TimeInvestmentViewModel

    @State private var isEndingSession = false
    @State private var endedAt = Date()
    @State private var taskName = ""
    @State private var selectedCategory: TimeSessionCategory = .other
    @State private var joyScore = 6.0
    @State private var meaningScore = 6.0
    @State private var note = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            header

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
            recentRecords

            Text("快捷键可在 Time Mate 设置中调整。")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 360)
        .onChange(of: viewModel.isSessionRunning) { _, isRunning in
            if isRunning == false {
                resetDraft()
            }
        }
        .onChange(of: taskName) { _, newValue in
            selectedCategory = TimeSessionCategory.classify(taskName: newValue)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("Time Mate")
                    .font(.headline.weight(.semibold))
                Spacer()
                Text(Date().formatted(date: .abbreviated, time: .omitted))
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
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
        .background(MenuPanelBackground())
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
        .background(MenuPanelBackground())
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
        .background(MenuPanelBackground())
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
                        .frame(height: 18)
                }
            }
        }
        .padding(12)
        .background(MenuPanelBackground())
    }

    private var recentRecords: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("最近记录")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            let records = viewModel.recentSessions(limit: 3)
            if records.isEmpty {
                Text("还没有记录。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                ForEach(records, id: \.id) { session in
                    HStack(spacing: 8) {
                        Circle()
                            .fill(color(for: session.category))
                            .frame(width: 8, height: 8)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(session.taskName ?? "未命名")
                                .font(.caption.weight(.semibold))
                            Text("\(DurationFormatter.formatted(session.roundedSeconds)) · 快 \(session.joyScore ?? 6) · 义 \(session.meaningScore ?? 6)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()
                    }
                }
            }
        }
        .padding(12)
        .background(MenuPanelBackground())
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
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        var slots = Array<TimeSessionCategory?>(repeating: nil, count: 96)

        for session in viewModel.todaySessions() {
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

private struct MenuPanelBackground: View {
    var body: some View {
        RoundedRectangle(cornerRadius: 14, style: .continuous)
            .fill(Color.secondary.opacity(0.08))
    }
}

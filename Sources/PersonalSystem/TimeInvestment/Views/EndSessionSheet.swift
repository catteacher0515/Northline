import SwiftUI

struct EndSessionSheet: View {
    let onCancel: () -> Void
    let onConfirm: (SessionDraftResult) -> Void

    @State private var taskName = ""
    @State private var selectedCategory: TimeSessionCategory = .other
    @State private var joyScore = 6.0
    @State private var meaningScore = 6.0
    @State private var note = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            VStack(alignment: .leading, spacing: 6) {
                Text("结束记录")
                    .font(.title2.weight(.semibold))
                Text("补上任务名，系统会按 15 分钟对齐。")
                    .foregroundStyle(.secondary)
            }

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
                Button("取消", action: onCancel)
                Spacer()
                Button("记录") {
                    confirm()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(taskName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(24)
        .frame(minWidth: 420)
        .onChange(of: taskName) { _, newValue in
            selectedCategory = TimeSessionCategory.classify(taskName: newValue)
        }
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

    private func confirm() {
        onConfirm(
            SessionDraftResult(
                taskName: taskName,
                category: selectedCategory,
                joyScore: Int(joyScore),
                meaningScore: Int(meaningScore),
                note: note
            )
        )
    }
}

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

                        Toggle(
                            "有问题",
                            isOn: Binding(
                                get: { viewModel.resetAnswers[question.rawValue] ?? false },
                                set: { viewModel.updateResetAnswer(for: question, value: $0) }
                            )
                        )
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

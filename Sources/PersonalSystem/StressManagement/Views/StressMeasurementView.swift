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

                        Picker(
                            "分值",
                            selection: Binding(
                                get: { viewModel.measurementScores[question.rawValue] ?? 0 },
                                set: { viewModel.updateMeasurementScore(for: question, value: $0) }
                            )
                        ) {
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

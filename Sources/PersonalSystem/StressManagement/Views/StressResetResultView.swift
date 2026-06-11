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

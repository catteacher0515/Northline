import SwiftUI

struct ContainerHomeView: View {
    let selectedModule: AppModule
    let onSelectModule: (AppModule) -> Void
    @ObservedObject var timeInvestmentViewModel: TimeInvestmentViewModel

    private let modules: [(id: AppModule, title: String, subtitle: String)] = [
        (.timeInvestment, "时间投入", "今日生产 / 今日消费"),
        (.stressManagement, "压力管理", "尚未启用"),
        (.goalClarity, "目标清晰化", "尚未启用")
    ]

    var body: some View {
        HStack(alignment: .top, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("个人系统")
                        .font(.largeTitle.weight(.semibold))
                    Text("容器首页")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    ForEach(modules, id: \.id) { module in
                        Button {
                            onSelectModule(module.id)
                        } label: {
                            ModuleCard(
                                title: module.title,
                                subtitle: module.subtitle,
                                isSelected: module.id == selectedModule
                            )
                        }
                        .buttonStyle(.plain)
                    }
                }

                SettingsLink {
                    ModuleCard(
                        title: "设置",
                        subtitle: "快捷键 / 默认参考时长",
                        isSelected: false
                    )
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)
            }
            .frame(maxWidth: 320, alignment: .leading)

            Divider()

            selectedModuleView
        }
        .padding(24)
        .frame(minWidth: 980, minHeight: 560)
    }

    @ViewBuilder
    private var selectedModuleView: some View {
        switch selectedModule {
        case .timeInvestment:
            TimeInvestmentDashboardView(viewModel: timeInvestmentViewModel)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        case .stressManagement:
            PlaceholderModuleView(title: "压力管理", subtitle: "尚未启用")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        case .goalClarity:
            PlaceholderModuleView(title: "目标清晰化", subtitle: "尚未启用")
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        }
    }
}

private struct PlaceholderModuleView: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.largeTitle.weight(.semibold))
            Text(subtitle)
                .foregroundStyle(.secondary)
            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
    }
}
private struct ModuleCard: View {
    let title: String
    let subtitle: String
    let isSelected: Bool

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .font(.title3.weight(.semibold))
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)

            if isSelected {
                Text("当前")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(.thinMaterial, in: Capsule())
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(nsColor: .windowBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(isSelected ? Color.accentColor : Color.secondary.opacity(0.18), lineWidth: isSelected ? 1.5 : 1)
        )
    }
}

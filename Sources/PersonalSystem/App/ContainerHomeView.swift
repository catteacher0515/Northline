import SwiftUI

struct ContainerHomeView: View {
    let selectedModuleID: String

    private let modules: [(id: String, title: String, subtitle: String)] = [
        ("time-investment", "时间投入", "今日生产 / 今日消费"),
        ("stress-management", "压力管理", "尚未启用"),
        ("goal-clarity", "目标清晰化", "尚未启用")
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                Text("个人系统")
                    .font(.largeTitle.weight(.semibold))
                Text("容器首页")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }

            VStack(spacing: 12) {
                ForEach(modules, id: \.id) { module in
                    ModuleCard(
                        title: module.title,
                        subtitle: module.subtitle,
                        isSelected: module.id == selectedModuleID
                    )
                }
            }

            Spacer(minLength: 0)
        }
        .padding(24)
        .frame(minWidth: 680, minHeight: 480)
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

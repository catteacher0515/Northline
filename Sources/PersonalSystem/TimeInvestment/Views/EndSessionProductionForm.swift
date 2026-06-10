import SwiftUI

struct EndSessionProductionForm: View {
    @Binding var productionNote: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("产出描述")
                .font(.headline)

            TextEditor(text: $productionNote)
                .frame(minHeight: 120)
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .strokeBorder(Color.secondary.opacity(0.2))
                )

            Text("留空会自动记为消费。")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

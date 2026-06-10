import SwiftUI

struct EndSessionSheet: View {
    let onCancel: () -> Void
    let onConfirm: (SessionDraftResult) -> Void

    @State private var classification: SessionClassification = .consumption
    @State private var productionNote = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("结束 session")
                .font(.title2.weight(.semibold))

            Picker("裁决", selection: $classification) {
                Text("消费").tag(SessionClassification.consumption)
                Text("生产").tag(SessionClassification.production)
            }
            .pickerStyle(.segmented)

            if classification == .production {
                EndSessionProductionForm(productionNote: $productionNote)
            }

            HStack {
                Button("取消", action: onCancel)
                Spacer()
                Button("记录") {
                    confirm()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        .frame(minWidth: 360)
    }

    private func confirm() {
        switch classification {
        case .consumption:
            onConfirm(.consumption)
        case .production:
            onConfirm(.production(note: productionNote))
        }
    }
}

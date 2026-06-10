import SwiftUI

struct RecentProductionNotesView: View {
    let notes: [ReviewProductionNoteRow]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("最近生产备注")
                .font(.headline)

            if notes.isEmpty {
                Text("当前时间范围内还没有生产记录。")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(notes) { row in
                    VStack(alignment: .leading, spacing: 6) {
                        Text(row.note)
                            .font(.body.weight(.medium))
                        Text("\(row.endAt.formatted(date: .abbreviated, time: .shortened)) · \(DurationFormatter.formatted(row.durationSeconds))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 8)

                    if row.id != notes.last?.id {
                        Divider()
                    }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.secondary.opacity(0.08))
        )
    }
}

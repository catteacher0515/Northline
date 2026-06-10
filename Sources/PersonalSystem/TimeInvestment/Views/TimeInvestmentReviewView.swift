import SwiftUI

struct TimeInvestmentReviewView: View {
    @ObservedObject var viewModel: TimeInvestmentViewModel

    var body: some View {
        let snapshot = viewModel.reviewSnapshot()

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("复盘")
                        .font(.largeTitle.weight(.semibold))
                    Text("看总账、看趋势、看最近做了什么。")
                        .foregroundStyle(.secondary)
                }

                ReviewRangePicker(
                    selectedRange: Binding(
                        get: { viewModel.selectedReviewRange },
                        set: { viewModel.selectReviewRange($0) }
                    )
                )

                ReviewSummaryCards(summary: snapshot.summary)
                ReviewDailyTrendChart(rows: snapshot.dailyRows)
                RecentProductionNotesView(notes: snapshot.recentProductionNotes)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

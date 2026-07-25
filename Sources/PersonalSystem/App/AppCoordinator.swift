import AppKit
import SwiftUI

struct AppCoordinator: View {
    @EnvironmentObject private var appState: AppState
    @State private var viewMode: TimeMateViewMode = .record

    var body: some View {
        TimeRicherDesktopWidgetView(viewModel: appState.timeInvestmentViewModel, viewMode: $viewMode)
            .onAppear {
                resizeMainWindow()
            }
            .onChange(of: viewMode) { _, _ in
                resizeMainWindow()
            }
    }

    private func resizeMainWindow() {
        DispatchQueue.main.async {
            guard let window = NSApp.windows.first(where: { $0.title == "Time Mate" }) ?? NSApp.windows.first else {
                return
            }

            window.title = "Time Mate"
            window.setContentSize(contentSize)
            window.minSize = viewMode == .record
                ? NSSize(width: 360, height: 560)
                : NSSize(width: 680, height: 620)
            window.center()
            window.makeKeyAndOrderFront(nil)
        }
    }

    private var contentSize: NSSize {
        switch viewMode {
        case .record:
            return NSSize(width: 390, height: 650)
        case .review:
            return NSSize(width: 740, height: 720)
        }
    }
}

private struct TimeRicherDesktopWidgetView: View {
    @ObservedObject var viewModel: TimeInvestmentViewModel
    @Binding var viewMode: TimeMateViewMode

    var body: some View {
        VStack(spacing: 0) {
            TimeInvestmentMenuBarView(viewModel: viewModel, viewMode: $viewMode)
        }
        .padding(10)
        .frame(width: viewMode == .record ? 390 : 740, height: viewMode == .record ? 650 : 720)
        .background(
            LinearGradient(
                colors: [
                    Color(nsColor: .windowBackgroundColor),
                    Color(nsColor: .controlBackgroundColor)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
}

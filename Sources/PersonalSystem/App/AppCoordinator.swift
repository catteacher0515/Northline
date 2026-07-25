import AppKit
import SwiftUI

struct AppCoordinator: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TimeRicherDesktopWidgetView(viewModel: appState.timeInvestmentViewModel)
            .onAppear {
                resizeMainWindow()
            }
    }

    private func resizeMainWindow() {
        DispatchQueue.main.async {
            guard let window = NSApp.windows.first(where: { $0.title == "Time Mate" }) ?? NSApp.windows.first else {
                return
            }

            window.title = "Time Mate"
            window.setContentSize(NSSize(width: 390, height: 650))
            window.minSize = NSSize(width: 360, height: 560)
            window.center()
            window.makeKeyAndOrderFront(nil)
        }
    }
}

private struct TimeRicherDesktopWidgetView: View {
    @ObservedObject var viewModel: TimeInvestmentViewModel

    var body: some View {
        VStack(spacing: 0) {
            TimeInvestmentMenuBarView(viewModel: viewModel)
        }
        .padding(10)
        .frame(width: 390, height: 650)
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

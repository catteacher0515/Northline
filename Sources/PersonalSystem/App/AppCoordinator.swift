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
        .background(TimeSliceBackdrop())
    }
}

struct TimeSliceBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.075, green: 0.078, blue: 0.078),
                    Color(red: 0.115, green: 0.112, blue: 0.104)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            TimelineGrid()
                .opacity(0.18)

            Circle()
                .fill(Color(red: 0.22, green: 0.42, blue: 0.72).opacity(0.16))
                .blur(radius: 72)
                .frame(width: 260, height: 260)
                .offset(x: -150, y: -250)

            Circle()
                .fill(Color(red: 0.36, green: 0.56, blue: 0.38).opacity(0.11))
                .blur(radius: 88)
                .frame(width: 300, height: 300)
                .offset(x: 180, y: 240)
        }
    }
}

private struct TimelineGrid: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            let spacing: CGFloat = 18

            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += spacing
            }

            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }

            context.stroke(path, with: .color(.white.opacity(0.11)), lineWidth: 0.5)
        }
    }
}

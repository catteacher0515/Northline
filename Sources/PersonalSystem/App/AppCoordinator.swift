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
        .background(ScrapbookBackdrop())
    }
}

struct ScrapbookBackdrop: View {
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.965, green: 0.942, blue: 0.890),
                    Color(red: 0.925, green: 0.895, blue: 0.825)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            PaperTexture()
                .opacity(0.34)

            TornTapeBand(color: Color(red: 0.79, green: 0.68, blue: 0.94).opacity(0.52), rotation: -5)
                .frame(width: 250, height: 54)
                .offset(x: -125, y: -238)

            TornTapeBand(color: Color(red: 0.96, green: 0.78, blue: 0.25).opacity(0.38), rotation: 4)
                .frame(width: 300, height: 62)
                .offset(x: 145, y: 262)
        }
    }
}

private struct PaperTexture: View {
    var body: some View {
        Canvas { context, size in
            for index in 0..<420 {
                let x = CGFloat((index * 37) % 997) / 997 * size.width
                let y = CGFloat((index * 71) % 991) / 991 * size.height
                let radius = CGFloat((index % 4) + 1) * 0.34
                let rect = CGRect(x: x, y: y, width: radius, height: radius)
                context.fill(Path(ellipseIn: rect), with: .color(.black.opacity(0.06)))
            }
        }
    }
}

private struct TornTapeBand: View {
    let color: Color
    let rotation: Double

    var body: some View {
        UnevenRoundedRectangle(cornerRadii: .init(topLeading: 8, bottomLeading: 3, bottomTrailing: 9, topTrailing: 4), style: .continuous)
            .fill(color)
            .rotationEffect(.degrees(rotation))
            .overlay {
                PaperTexture()
                    .clipShape(UnevenRoundedRectangle(cornerRadii: .init(topLeading: 8, bottomLeading: 3, bottomTrailing: 9, topTrailing: 4), style: .continuous))
                    .opacity(0.18)
            }
        }
    }

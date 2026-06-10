import AppKit
import SwiftUI

struct ShortcutRecorderView: NSViewRepresentable {
    @Binding var isRecording: Bool
    let onShortcutRecorded: (KeyboardShortcut) -> Void

    func makeNSView(context: Context) -> RecordingKeyView {
        let view = RecordingKeyView()
        view.onShortcutRecorded = { shortcut in
            onShortcutRecorded(shortcut)
        }
        return view
    }

    func updateNSView(_ nsView: RecordingKeyView, context: Context) {
        nsView.onShortcutRecorded = { shortcut in
            onShortcutRecorded(shortcut)
        }
        nsView.isRecording = isRecording

        if isRecording, let window = nsView.window {
            window.makeFirstResponder(nsView)
        }
    }
}

final class RecordingKeyView: NSView {
    var isRecording = false
    var onShortcutRecorded: ((KeyboardShortcut) -> Void)?

    override var acceptsFirstResponder: Bool {
        true
    }

    override func keyDown(with event: NSEvent) {
        guard isRecording else {
            super.keyDown(with: event)
            return
        }

        guard let shortcut = KeyboardShortcut.from(event: event) else {
            return
        }

        onShortcutRecorded?(shortcut)
    }
}

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var appState: AppState
    @State private var isRecordingShortcut = false

    var body: some View {
        Form {
            Section("时间投入") {
                Stepper(
                    value: Binding(
                        get: { appState.settings.referenceDurationSeconds / 60 },
                        set: { appState.settings.referenceDurationSeconds = max(5, $0) * 60 }
                    ),
                    in: 5...240,
                    step: 5
                ) {
                    Text("默认参考时长：\(appState.settings.referenceDurationSeconds / 60) 分钟")
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("开始 / 结束快捷键")

                    HStack(spacing: 12) {
                        Text(appState.settings.startEndShortcut.displayString)
                            .font(.system(.body, design: .monospaced))
                            .frame(minWidth: 90, alignment: .leading)

                        Button(isRecordingShortcut ? "按下新快捷键…" : "录制快捷键") {
                            isRecordingShortcut.toggle()
                        }

                        if isRecordingShortcut {
                            Button("取消") {
                                isRecordingShortcut = false
                            }
                        }
                    }

                    ShortcutRecorderView(isRecording: $isRecordingShortcut) { shortcut in
                        appState.updateStartEndShortcut(shortcut)
                        isRecordingShortcut = false
                    }
                    .frame(width: 0, height: 0)

                    Text("默认值：⌃⌘P，同一个快捷键切换开始 / 结束。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(width: 460, height: 260)
    }
}

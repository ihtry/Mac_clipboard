//
//  SettingsView.swift
//  clipboard
//
//  Joker Created by Codex on 2026/5/12.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var preferences: AppPreferences

    var body: some View {
        Form {
            Section("启动") {
                Toggle("开机启动", isOn: $preferences.launchAtLogin)

                Text("当前状态：\(preferences.launchAtLoginStatusText)")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let launchAtLoginError = preferences.launchAtLoginError {
                    Text("设置失败：\(launchAtLoginError)")
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section("快捷键") {
                HotKeyRecorderView(hotKey: $preferences.hotKey)

                Text("设置后可在任何地方唤起主窗口。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("交互") {
                Toggle("暂停监听剪切板", isOn: $preferences.isMonitoringPaused)

                Text(preferences.isMonitoringPaused ? "暂停期间复制的新内容不会被记录。" : "当前会自动记录新的剪切板内容。")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker("点击历史项", selection: $preferences.historyItemActionRaw) {
                    ForEach(HistoryItemAction.allCases) { action in
                        Text(action.title).tag(action.rawValue)
                    }
                }

                Stepper("历史上限：\(preferences.historyLimit)", value: $preferences.historyLimit, in: 10...500, step: 10)
            }

            Section("文本清洗") {
                Toggle("去掉首尾空白", isOn: $preferences.trimWhitespace)
                Toggle("合并换行为空格", isOn: $preferences.collapseNewlines)
                Toggle("忽略空白内容", isOn: $preferences.skipBlankContent)
                Stepper("最大文本长度：\(preferences.maximumTextLength)", value: $preferences.maximumTextLength, in: 100...20000, step: 100)
            }

            Section("黑名单应用") {
                TextEditor(text: $preferences.blacklistedBundlesText)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 120)

                Text("每行一个 bundle id，例如 `com.apple.keychainaccess`。黑名单应用复制的内容不会被记录。")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .formStyle(.grouped)
        .padding(20)
        .frame(width: 520)
    }
}

private struct HotKeyRecorderView: View {
    @Binding var hotKey: HotKey?

    @State private var isRecording = false
    @State private var eventMonitor: Any?

    var body: some View {
        HStack {
            Button {
                toggleRecording()
            } label: {
                Text(isRecording ? "按下新的快捷键" : (hotKey?.displayString ?? "点击设置快捷键"))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)

            Button("清除") {
                hotKey = nil
                stopRecording()
            }
            .disabled(hotKey == nil && !isRecording)
        }
        .onDisappear {
            stopRecording()
        }
    }

    private func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    private func startRecording() {
        stopRecording()
        isRecording = true

        eventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            if event.keyCode == 53 {
                stopRecording()
                return nil
            }

            guard let recordedHotKey = HotKey.from(event: event) else {
                return nil
            }

            hotKey = recordedHotKey
            stopRecording()
            return nil
        }
    }

    private func stopRecording() {
        isRecording = false

        if let eventMonitor {
            NSEvent.removeMonitor(eventMonitor)
            self.eventMonitor = nil
        }
    }
}

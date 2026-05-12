//
//  SettingsView.swift
//  clipboard
//
//  Joker Created by Codex on 2026/5/12.
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var updateManager: UpdateManager

    private var strings: AppStrings {
        preferences.strings
    }

    private var historyLimitBinding: Binding<Int> {
        Binding(
            get: { preferences.historyLimit },
            set: { preferences.historyLimit = AppPreferences.clampedHistoryLimit($0) }
        )
    }

    private var maximumTextLengthBinding: Binding<Int> {
        Binding(
            get: { preferences.maximumTextLength },
            set: { preferences.maximumTextLength = AppPreferences.clampedMaximumTextLength($0) }
        )
    }

    var body: some View {
        Form {
            Section(strings.launchSection) {
                Toggle(strings.launchAtLogin, isOn: $preferences.launchAtLogin)

                Text(strings.launchAtLoginStatus(preferences.launchAtLoginStatusText))
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let launchAtLoginError = preferences.launchAtLoginError {
                    Text(strings.launchAtLoginError(launchAtLoginError))
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }

            Section(strings.hotKeySection) {
                HotKeyRecorderView(hotKey: $preferences.hotKey, strings: strings)

                Text(strings.hotKeyHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(strings.languageSection) {
                Picker(strings.appLanguage, selection: $preferences.languageRaw) {
                    ForEach(AppLanguage.allCases) { language in
                        Text(language.title).tag(language.rawValue)
                    }
                }

                Text(strings.languageHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(strings.updatesSection) {
                Button(strings.checkForUpdates) {
                    updateManager.checkForUpdates()
                }
                .disabled(!updateManager.isAvailable)

                Text(updateManager.isAvailable ? strings.updatesEnabledHint : strings.updatesDisabledHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(strings.interactionSection) {
                Toggle(strings.pauseClipboardMonitoring, isOn: $preferences.isMonitoringPaused)

                Text(preferences.isMonitoringPaused ? strings.pausedHint : strings.activeHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Picker(strings.historyItemClickAction, selection: $preferences.historyItemActionRaw) {
                    ForEach(HistoryItemAction.allCases) { action in
                        Text(action.title(for: strings)).tag(action.rawValue)
                    }
                }

                Stepper(strings.historyLimit(preferences.historyLimit), value: historyLimitBinding, in: 10...500, step: 10)
            }

            Section(strings.textCleaningSection) {
                Toggle(strings.trimWhitespace, isOn: $preferences.trimWhitespace)
                Toggle(strings.collapseNewlines, isOn: $preferences.collapseNewlines)
                Toggle(strings.skipBlankContent, isOn: $preferences.skipBlankContent)
                Toggle(strings.filterSensitiveText, isOn: $preferences.filterSensitiveText)
                Stepper(strings.maximumTextLength(preferences.maximumTextLength), value: maximumTextLengthBinding, in: 100...20000, step: 100)

                Text(strings.sensitiveFilterHint)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section(strings.blacklistedAppsSection) {
                TextEditor(text: $preferences.blacklistedBundlesText)
                    .font(.system(.body, design: .monospaced))
                    .frame(minHeight: 120)

                Text(strings.blacklistHint)
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
    let strings: AppStrings

    @State private var isRecording = false
    @State private var eventMonitor: Any?

    var body: some View {
        HStack {
            Button {
                toggleRecording()
            } label: {
                Text(isRecording ? strings.recordHotKey : (hotKey?.displayString ?? strings.setHotKey))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.bordered)

            Button(strings.clearHotKey) {
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

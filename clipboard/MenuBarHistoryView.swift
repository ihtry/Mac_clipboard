//
//  MenuBarHistoryView.swift
//  clipboard
//
//  Joker Created by Codex on 2026/5/12.
//

import SwiftData
import SwiftUI

struct MenuBarHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openWindow) private var openWindow
    @EnvironmentObject private var clipboardMonitor: ClipboardMonitor
    @EnvironmentObject private var preferences: AppPreferences
    @Query(sort: \Item.copiedAt, order: .reverse) private var items: [Item]

    @State private var searchText = ""
    @State private var feedbackMessage: String?
    @State private var selectedItemID: PersistentIdentifier?

    init() {}

    private var sortedItems: [Item] {
        items.sorted {
            if $0.isPinned != $1.isPinned {
                return $0.isPinned && !$1.isPinned
            }
            return $0.copiedAt > $1.copiedAt
        }
    }

    private var filteredItems: [Item] {
        let trimmedQuery = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedQuery.isEmpty else {
            return sortedItems
        }

        return sortedItems.filter {
            $0.searchableText.localizedCaseInsensitiveContains(trimmedQuery)
        }
    }

    private var pinnedItems: [Item] {
        Array(filteredItems.prefix(20)).filter(\.isPinned)
    }

    private var recentItems: [Item] {
        Array(filteredItems.prefix(20)).filter { !$0.isPinned }
    }

    private var strings: AppStrings {
        preferences.strings
    }

    var body: some View {
        VStack(spacing: 12) {
            if preferences.isMonitoringPaused {
                Label(strings.monitoringPaused, systemImage: "pause.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            TextField(strings.searchHistory, text: $searchText)
                .textFieldStyle(.roundedBorder)

            if items.isEmpty {
                emptyState
            } else if filteredItems.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selectedItemID) {
                    if !pinnedItems.isEmpty {
                        Section(strings.pinnedSection) {
                            menuRows(for: pinnedItems)
                        }
                    }

                    if !recentItems.isEmpty {
                        Section(pinnedItems.isEmpty ? strings.historySection : strings.recentSection) {
                            menuRows(for: recentItems)
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }

            if let feedbackMessage {
                Text(feedbackMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            Divider()

            HStack {
                Button(strings.openMainWindow) {
                    openWindow(id: AppWindowID.main)
                }

                Spacer()

                SettingsLink {
                    Label(strings.settings, systemImage: "gearshape")
                }

                Button(preferences.isMonitoringPaused ? strings.resumeMonitoring : strings.pauseMonitoring) {
                    preferences.isMonitoringPaused.toggle()
                }

                Button(strings.clearHistory, role: .destructive) {
                    clearHistory()
                }
                .disabled(items.isEmpty)
            }
        }
        .padding(14)
        .focusable(false)
        .onChange(of: searchText) { _, _ in
            feedbackMessage = nil
            selectedItemID = filteredItems.first?.persistentModelID
        }
        .onAppear {
            selectedItemID = filteredItems.first?.persistentModelID
        }
        .onMoveCommand { direction in
            moveSelection(direction)
        }
        .onDeleteCommand {
            if let item = filteredItems.first(where: { $0.persistentModelID == selectedItemID }) {
                delete(item)
            }
        }
        .onExitCommand {
            dismiss()
        }
    }

    private var emptyState: some View {
        VStack {
            Spacer()

            ContentUnavailableView(
                strings.emptyHistoryTitle,
                systemImage: "clipboard",
                description: Text(strings.emptyHistoryDescription)
            )

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.clear, lineWidth: 0)
        )
    }

    private func delete(_ item: Item) {
        modelContext.delete(item)
        try? modelContext.save()
    }

    private func clearHistory() {
        for item in items {
            modelContext.delete(item)
        }

        try? modelContext.save()
    }

    private func performPrimaryAction(for item: Item) {
        feedbackMessage = nil

        switch preferences.historyItemAction {
        case .directPaste:
            let result = clipboardMonitor.directPaste(item, using: modelContext)
            switch result {
            case .pasted:
                dismiss()
            case let .copiedNeedsManualPaste(reason):
                feedbackMessage = strings.copiedNeedsManualPaste(reason: reason)
            }
        case .copyOnly:
            clipboardMonitor.copy(item, using: modelContext)
            feedbackMessage = strings.copied
        }
    }

    private func togglePin(_ item: Item) {
        item.isPinned.toggle()
        try? modelContext.save()
    }

    private func moveSelection(_ direction: MoveCommandDirection) {
        guard !filteredItems.isEmpty else {
            return
        }

        let currentIndex = filteredItems.firstIndex { $0.persistentModelID == selectedItemID } ?? 0
        let nextIndex: Int

        switch direction {
        case .down:
            nextIndex = min(currentIndex + 1, filteredItems.count - 1)
        case .up:
            nextIndex = max(currentIndex - 1, 0)
        default:
            return
        }

        selectedItemID = filteredItems[nextIndex].persistentModelID
    }

    @ViewBuilder
    private func menuRows(for historyItems: [Item]) -> some View {
        ForEach(historyItems) { item in
            Button {
                performPrimaryAction(for: item)
            } label: {
                HStack(alignment: .top, spacing: 10) {
                    Image(systemName: item.isPinned ? "pin.fill" : item.systemImageName)
                        .frame(width: 18)
                        .foregroundStyle(item.isPinned ? .orange : .secondary)

                    VStack(alignment: .leading, spacing: 6) {
                        Text(item.previewText)
                            .font(.headline)
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.leading)
                            .lineLimit(2)

                        Text(item.copiedAt, format: Date.FormatStyle(date: .omitted, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 10))
            }
            .buttonStyle(.plain)
            .tag(item.persistentModelID)
            .listRowBackground(Color.clear)
            .listRowSeparator(.hidden)
            .contextMenu {
                Button(preferences.historyItemAction == .directPaste ? strings.directPaste : strings.copyOnly) {
                    performPrimaryAction(for: item)
                }

                Button(strings.copy) {
                    clipboardMonitor.copy(item, using: modelContext)
                }

                Button(item.isPinned ? strings.unpin : strings.pin) {
                    togglePin(item)
                }

                Button(strings.delete, role: .destructive) {
                    delete(item)
                }
            }
        }
    }
}

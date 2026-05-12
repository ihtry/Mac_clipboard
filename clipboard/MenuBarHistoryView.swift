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

    var body: some View {
        VStack(spacing: 12) {
            if preferences.isMonitoringPaused {
                Label("剪切板监听已暂停", systemImage: "pause.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            TextField("搜索历史内容", text: $searchText)
                .textFieldStyle(.roundedBorder)

            if items.isEmpty {
                emptyState
            } else if filteredItems.isEmpty {
                ContentUnavailableView.search(text: searchText)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                List(selection: $selectedItemID) {
                    if !pinnedItems.isEmpty {
                        Section("固定") {
                            menuRows(for: pinnedItems)
                        }
                    }

                    if !recentItems.isEmpty {
                        Section(pinnedItems.isEmpty ? "历史记录" : "最近") {
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
                Button("打开主窗口") {
                    openWindow(id: AppWindowID.main)
                }

                Spacer()

                SettingsLink {
                    Label("设置", systemImage: "gearshape")
                }

                Button(preferences.isMonitoringPaused ? "继续监听" : "暂停监听") {
                    preferences.isMonitoringPaused.toggle()
                }

                Button("清空历史", role: .destructive) {
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
                "暂无历史",
                systemImage: "clipboard",
                description: Text("复制文本后会自动出现在这里。")
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
                feedbackMessage = "已复制，按 Command+V 粘贴。原因：\(reason)"
            }
        case .copyOnly:
            clipboardMonitor.copy(item, using: modelContext)
            feedbackMessage = "已复制"
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
                Button(preferences.historyItemAction == .directPaste ? "直接粘贴" : "仅复制") {
                    performPrimaryAction(for: item)
                }

                Button("复制") {
                    clipboardMonitor.copy(item, using: modelContext)
                }

                Button(item.isPinned ? "取消固定" : "固定") {
                    togglePin(item)
                }

                Button("删除", role: .destructive) {
                    delete(item)
                }
            }
        }
    }
}

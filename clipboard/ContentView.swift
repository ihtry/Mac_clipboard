//
//  ContentView.swift
//  clipboard
//
//  Created by joker on 2026/5/12.
//

import SwiftData
import SwiftUI
import AppKit

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var clipboardMonitor: ClipboardMonitor
    @EnvironmentObject private var preferences: AppPreferences
    @EnvironmentObject private var updateManager: UpdateManager
    @Query(sort: \Item.copiedAt, order: .reverse) private var items: [Item]

    @State private var selectedItemID: PersistentIdentifier?
    @State private var searchText = ""
    @State private var feedbackMessage: String?

    private let githubURL = URL(string: "https://github.com/ihtry/Mac_clipboard")!

    init() {}

    private var strings: AppStrings {
        preferences.strings
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

    private var sortedItems: [Item] {
        items.sorted {
            if $0.isPinned != $1.isPinned {
                return $0.isPinned && !$1.isPinned
            }
            return $0.copiedAt > $1.copiedAt
        }
    }

    private var selectedItem: Item? {
        filteredItems.first { $0.persistentModelID == selectedItemID }
            ?? items.first { $0.persistentModelID == selectedItemID }
    }

    private var pinnedItems: [Item] {
        filteredItems.filter(\.isPinned)
    }

    private var recentItems: [Item] {
        filteredItems.filter { !$0.isPinned }
    }

    var body: some View {
        NavigationSplitView {
            VStack(spacing: 14) {
                searchField

                Group {
                    if items.isEmpty {
                        ContentUnavailableView(
                            strings.emptyClipboardHistoryTitle,
                            systemImage: "clipboard",
                            description: Text(strings.emptyClipboardHistoryDescription)
                        )
                    } else if filteredItems.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    } else {
                        List {
                            if !pinnedItems.isEmpty {
                                Section(strings.pinnedSection) {
                                    historyRows(for: pinnedItems)
                                }
                            }

                            if !recentItems.isEmpty {
                                Section(pinnedItems.isEmpty ? strings.historySection : strings.recentSection) {
                                    historyRows(for: recentItems)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollContentBackground(.hidden)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.top, 12)
            .padding(.bottom, 10)
            .navigationTitle(strings.clipboardTitle)
            .navigationSplitViewColumnWidth(min: 320, ideal: 420, max: 520)
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Button {
                        if let item = selectedItem {
                            performPrimaryAction(for: item)
                        }
                    } label: {
                        Label(primaryActionTitle, systemImage: primaryActionSystemImage)
                    }
                    .disabled(selectedItem == nil)

                    Button {
                        if let item = selectedItem {
                            delete(item)
                        }
                    } label: {
                        Label(strings.delete, systemImage: "trash")
                    }
                    .disabled(selectedItem == nil)

                    Button(role: .destructive, action: clearHistory) {
                        Label(strings.clear, systemImage: "trash.slash")
                    }
                    .disabled(items.isEmpty)

                    if let item = selectedItem {
                        Button {
                            togglePin(item)
                        } label: {
                            Label(item.isPinned ? strings.unpin : strings.pin, systemImage: item.isPinned ? "pin.slash" : "pin")
                        }
                    }
                }
            }
        } detail: {
            Group {
                if let item = selectedItem {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            VStack(alignment: .leading, spacing: 16) {
                                HStack(alignment: .center, spacing: 12) {
                                    Image(systemName: item.systemImageName)
                                        .font(.title3)
                                        .foregroundStyle(.secondary)

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(item.previewText)
                                            .font(.title3.weight(.semibold))
                                            .lineLimit(2)

                                        Text(item.detailSummary(for: strings.language))
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Text(item.copiedAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                if let feedbackMessage {
                                    Label(feedbackMessage, systemImage: "info.circle")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Divider()

                                ClipboardDetailContent(item: item, strings: strings)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(.background, in: RoundedRectangle(cornerRadius: 18))
                            .overlay(
                                RoundedRectangle(cornerRadius: 18)
                                    .stroke(.quaternary, lineWidth: 1)
                            )
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                    }
                    .navigationTitle(strings.contentDetail)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                performPrimaryAction(for: item)
                            } label: {
                                Label(primaryActionTitle, systemImage: primaryActionSystemImage)
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        strings.selectRecordTitle,
                        systemImage: "text.viewfinder",
                        description: Text(strings.selectRecordDescription)
                    )
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    updateManager.checkForUpdates()
                } label: {
                    Label(strings.checkForUpdates, systemImage: "arrow.triangle.2.circlepath")
                }
                .disabled(!updateManager.isAvailable)
                .help(strings.checkForUpdates)
            }

            ToolbarItem(placement: .primaryAction) {
                Link(destination: githubURL) {
                    Image("GitHubMark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .accessibilityLabel("GitHub")
                }
                    .buttonStyle(.plain)
                    .help(strings.githubHelp)
            }
        }
        .task {
            if selectedItemID == nil {
                selectedItemID = filteredItems.first?.persistentModelID ?? items.first?.persistentModelID
            }
        }
        .onChange(of: items.count) { _, _ in
            if let selectedItemID, filteredItems.contains(where: { $0.persistentModelID == selectedItemID }) {
                return
            }

            self.selectedItemID = filteredItems.first?.persistentModelID ?? items.first?.persistentModelID
        }
        .onChange(of: searchText) { _, _ in
            if let selectedItemID, filteredItems.contains(where: { $0.persistentModelID == selectedItemID }) {
                return
            }

            self.selectedItemID = filteredItems.first?.persistentModelID
            feedbackMessage = nil
        }
        .onDeleteCommand {
            if let item = selectedItem {
                delete(item)
            }
        }
        .onSubmit {
            if let item = selectedItem {
                performPrimaryAction(for: item)
            }
        }
    }

    private var primaryActionTitle: String {
        preferences.historyItemAction == .directPaste ? strings.paste : strings.copy
    }

    private var primaryActionSystemImage: String {
        preferences.historyItemAction == .directPaste ? "arrow.turn.down.left" : "doc.on.doc"
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField(strings.searchHistory, text: $searchText)
                .textFieldStyle(.plain)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(nsColor: .textBackgroundColor))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
    }

    private func copy(_ item: Item) {
        clipboardMonitor.copy(item, using: modelContext)
        selectedItemID = item.persistentModelID
        feedbackMessage = strings.copied
    }

    private func performPrimaryAction(for item: Item) {
        selectedItemID = item.persistentModelID
        feedbackMessage = nil

        switch preferences.historyItemAction {
        case .directPaste:
            let result = clipboardMonitor.directPaste(item, using: modelContext)
            switch result {
            case .pasted:
                feedbackMessage = strings.pastedToPreviousApp
            case let .copiedNeedsManualPaste(reason):
                feedbackMessage = strings.copiedNeedsManualPaste(reason: reason)
            }
        case .copyOnly:
            copy(item)
        }
    }

    private func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(filteredItems[index])
            }

            try? modelContext.save()
        }
    }

    private func delete(_ item: Item) {
        withAnimation {
            modelContext.delete(item)
            try? modelContext.save()
        }
    }

    private func clearHistory() {
        withAnimation {
            for item in items {
                modelContext.delete(item)
            }

            try? modelContext.save()
            selectedItemID = nil
        }
    }

    private func togglePin(_ item: Item) {
        withAnimation {
            item.isPinned.toggle()
            try? modelContext.save()
        }
    }

    @ViewBuilder
    private func historyRows(for historyItems: [Item]) -> some View {
        ForEach(historyItems) { item in
            Button {
                selectedItemID = item.persistentModelID
            } label: {
                ClipboardHistoryRow(
                    item: item,
                    isSelected: selectedItem?.persistentModelID == item.persistentModelID,
                    strings: strings
                )
            }
            .buttonStyle(.plain)
            .listRowInsets(EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 8))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(role: .destructive) {
                    delete(item)
                } label: {
                    Label(strings.delete, systemImage: "trash")
                }
            }
            .contextMenu {
                Button(primaryActionTitle) {
                    performPrimaryAction(for: item)
                }

                Button(strings.copy) {
                    copy(item)
                }

                Button(item.isPinned ? strings.unpin : strings.pin) {
                    togglePin(item)
                }

                Button(strings.delete, role: .destructive) {
                    delete(item)
                }
            }
        }
        .onDelete(perform: deleteItems)
    }
}

private struct ClipboardHistoryRow: View {
    let item: Item
    let isSelected: Bool
    let strings: AppStrings

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(.quaternary.opacity(0.45))
                    .frame(width: 32, height: 32)

                Image(systemName: item.systemImageName)
                    .font(.callout.weight(.medium))
                    .foregroundStyle(.secondary)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text(item.previewText)
                    .font(.headline)
                    .lineLimit(1)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    Text(item.kindLabel(for: strings.language))
                        .font(.caption2.weight(.medium))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 3)
                        .background(.quaternary.opacity(0.5), in: Capsule())

                    Text(item.copiedAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer(minLength: 0)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(rowBackground, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(borderColor, lineWidth: 1)
        )
        .contentShape(RoundedRectangle(cornerRadius: 16))
    }

    private var rowBackground: Color {
        isSelected
            ? Color.primary.opacity(0.08)
            : Color(nsColor: .textBackgroundColor)
    }

    private var borderColor: Color {
        isSelected
            ? Color.primary.opacity(0.16)
            : Color.primary.opacity(0.08)
    }
}

private struct ClipboardDetailContent: View {
    let item: Item
    let strings: AppStrings

    var body: some View {
        switch item.kind {
        case .text:
            Text(item.content)
                .textSelection(.enabled)
                .font(.body)
                .frame(maxWidth: .infinity, alignment: .leading)
        case .image:
            if let imageData = item.imageData, let nsImage = NSImage(data: imageData) {
                Image(nsImage: nsImage)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 520, alignment: .leading)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                Text(strings.imageDataUnavailable)
                    .foregroundStyle(.secondary)
            }
        case .file:
            VStack(alignment: .leading, spacing: 10) {
                ForEach(item.filePaths, id: \.self) { path in
                    Text(path)
                        .font(.body)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: Item.self, inMemory: true)
}

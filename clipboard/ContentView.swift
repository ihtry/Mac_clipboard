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
    @Query(sort: \Item.copiedAt, order: .reverse) private var items: [Item]

    @State private var selectedItemID: PersistentIdentifier?
    @State private var searchText = ""

    private let githubURL = URL(string: "https://github.com/ihtry/Mac_clipboard")!

    init() {}

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
                            "暂无剪切板历史",
                            systemImage: "clipboard",
                            description: Text("复制任意文本后，这里会自动记录。")
                        )
                    } else if filteredItems.isEmpty {
                        ContentUnavailableView.search(text: searchText)
                    } else {
                        List {
                            if !pinnedItems.isEmpty {
                                Section("固定") {
                                    historyRows(for: pinnedItems)
                                }
                            }

                            if !recentItems.isEmpty {
                                Section(pinnedItems.isEmpty ? "历史记录" : "最近") {
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
            .navigationTitle("剪切板")
            .navigationSplitViewColumnWidth(min: 320, ideal: 420, max: 520)
            .toolbar {
                ToolbarItemGroup(placement: .automatic) {
                    Button {
                        if let item = selectedItem {
                            copy(item)
                        }
                    } label: {
                        Label("复制", systemImage: "doc.on.doc")
                    }
                    .disabled(selectedItem == nil)

                    Button {
                        if let item = selectedItem {
                            delete(item)
                        }
                    } label: {
                        Label("删除", systemImage: "trash")
                    }
                    .disabled(selectedItem == nil)

                    Button(role: .destructive, action: clearHistory) {
                        Label("清空", systemImage: "trash.slash")
                    }
                    .disabled(items.isEmpty)

                    if let item = selectedItem {
                        Button {
                            togglePin(item)
                        } label: {
                            Label(item.isPinned ? "取消固定" : "固定", systemImage: item.isPinned ? "pin.slash" : "pin")
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

                                        Text(item.detailSummary)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }

                                    Spacer()

                                    Text(item.copiedAt, format: Date.FormatStyle(date: .abbreviated, time: .shortened))
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }

                                Divider()

                                ClipboardDetailContent(item: item)
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
                    .navigationTitle("内容详情")
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button {
                                copy(item)
                            } label: {
                                Label("复制到系统剪切板", systemImage: "document.on.document")
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(
                        "选择一条记录",
                        systemImage: "text.viewfinder",
                        description: Text("右侧会显示完整内容，并可再次复制。")
                    )
                }
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Link(destination: githubURL) {
                    Image("GitHubMark")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 18, height: 18)
                        .accessibilityLabel("GitHub")
                }
                    .buttonStyle(.plain)
                    .help("打开 GitHub 项目地址")
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
        }
    }

    private var searchField: some View {
        HStack(spacing: 10) {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.secondary)

            TextField("搜索历史内容", text: $searchText)
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
                    isSelected: selectedItem?.persistentModelID == item.persistentModelID
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
                    Label("删除", systemImage: "trash")
                }
            }
            .contextMenu {
                Button("复制") {
                    copy(item)
                }

                Button(item.isPinned ? "取消固定" : "固定") {
                    togglePin(item)
                }

                Button("删除", role: .destructive) {
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
                    Text(item.kindLabel)
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
                Text("图片数据不可用")
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

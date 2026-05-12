//
//  Item.swift
//  clipboard
//
//  Created by joker on 2026/5/12.
//

import Foundation
import SwiftData

enum ClipboardItemKind: String, Codable {
    case text
    case image
    case file
}

@Model
final class Item {
    var kindRaw: String
    var content: String
    var copiedAt: Date
    var imageData: Data?
    var fileList: String?
    var recognizedText: String?
    var signature: String
    var isPinned: Bool

    init(
        kind: ClipboardItemKind = .text,
        content: String,
        copiedAt: Date = .now,
        imageData: Data? = nil,
        fileList: String? = nil,
        recognizedText: String? = nil,
        signature: String,
        isPinned: Bool = false
    ) {
        self.kindRaw = kind.rawValue
        self.content = content
        self.copiedAt = copiedAt
        self.imageData = imageData
        self.fileList = fileList
        self.recognizedText = recognizedText
        self.signature = signature
        self.isPinned = isPinned
    }

    var kind: ClipboardItemKind {
        get { ClipboardItemKind(rawValue: kindRaw) ?? .text }
        set { kindRaw = newValue.rawValue }
    }

    var filePaths: [String] {
        guard let fileList, !fileList.isEmpty else {
            return []
        }

        return fileList.components(separatedBy: "\n")
    }

    var previewText: String {
        switch kind {
        case .text:
            Self.makePreview(from: content)
        case .image, .file:
            content
        }
    }

    var systemImageName: String {
        switch kind {
        case .text:
            return "doc.text"
        case .image:
            return "photo"
        case .file:
            return "folder"
        }
    }

    var kindLabel: String {
        switch kind {
        case .text:
            return "文本"
        case .image:
            return "图片"
        case .file:
            return "文件"
        }
    }

    var detailSummary: String {
        switch kind {
        case .text:
            return "\(content.count) 个字符"
        case .image:
            if let recognizedText, !recognizedText.isEmpty {
                return "图片已识别文本"
            }
            return content
        case .file:
            return "\(filePaths.count) 个文件"
        }
    }

    var searchableText: String {
        [content, recognizedText]
            .compactMap { $0 }
            .joined(separator: "\n")
    }

    static func makePreview(from content: String, limit: Int = 80) -> String {
        let normalized = content
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !normalized.isEmpty else {
            return "空白内容"
        }

        guard normalized.count > limit else {
            return normalized
        }

        return String(normalized.prefix(limit)) + "…"
    }

    static func makeFileSummary(from paths: [String]) -> String {
        let names = paths.map { URL(fileURLWithPath: $0).lastPathComponent }

        guard let firstName = names.first else {
            return "文件"
        }

        if names.count == 1 {
            return firstName
        }

        return "\(firstName) 等 \(names.count) 个文件"
    }
}

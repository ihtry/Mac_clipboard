//
//  clipboardTests.swift
//  clipboardTests
//
//  Created by joker on 2026/5/12.
//

import Testing
@testable import clipboard

struct clipboardTests {

    @Test func previewReplacesLineBreaksAndTrimsWhitespace() async throws {
        let preview = Item.makePreview(from: "  first line\nsecond line  ")
        #expect(preview == "first line second line")
    }

    @Test func previewTruncatesLongContent() async throws {
        let preview = Item.makePreview(from: String(repeating: "a", count: 100), limit: 10)
        #expect(preview == "aaaaaaaaaa…")
    }

    @Test func previewUsesPlaceholderForBlankContent() async throws {
        let preview = Item.makePreview(from: "\n  \n")
        #expect(preview == "空白内容")
    }
}

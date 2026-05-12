//
//  ClipboardMonitor.swift
//  clipboard
//
//  Joker Created by Codex on 2026/5/12.
//

import AppKit
import ApplicationServices
import Combine
import CryptoKit
import Foundation
import SwiftData
import Vision

@MainActor
final class ClipboardMonitor: NSObject, ObservableObject {
    enum PasteResult {
        case pasted
        case copiedNeedsManualPaste(reason: String)
    }

    private let pollInterval: TimeInterval = 0.8

    private let preferences: AppPreferences
    private var timer: Timer?
    private var modelContext: ModelContext?
    private var lastChangeCount = NSPasteboard.general.changeCount
    private var workspaceObserver: NSObjectProtocol?
    private var lastTargetApplication: NSRunningApplication?
    private var lastFocusedElement: AXUIElement?
    private var lastFocusedElementProcessIdentifier: pid_t?
    private var ignoredChangeCount: Int?

    init(preferences: AppPreferences) {
        self.preferences = preferences
    }

    func start(using modelContext: ModelContext) {
        self.modelContext = modelContext

        guard timer == nil else {
            return
        }

        lastChangeCount = NSPasteboard.general.changeCount
        captureCurrentClipboard()

        timer = Timer.scheduledTimer(
            timeInterval: pollInterval,
            target: self,
            selector: #selector(handleTimerFired),
            userInfo: nil,
            repeats: true
        )

        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }

        startTrackingTargetApplication()
    }

    func stop() {
        timer?.invalidate()
        timer = nil

        if let workspaceObserver {
            NSWorkspace.shared.notificationCenter.removeObserver(workspaceObserver)
            self.workspaceObserver = nil
        }
    }

    @objc private func handleTimerFired() {
        Task { @MainActor in
            self.pollPasteboard()
        }
    }

    private func pollPasteboard() {
        let pasteboard = NSPasteboard.general
        guard pasteboard.changeCount != lastChangeCount else {
            return
        }

        if preferences.isMonitoringPaused {
            lastChangeCount = pasteboard.changeCount
            ignoredChangeCount = nil
            return
        }

        if let ignoredChangeCount, pasteboard.changeCount == ignoredChangeCount {
            lastChangeCount = pasteboard.changeCount
            self.ignoredChangeCount = nil
            return
        }

        lastChangeCount = pasteboard.changeCount

        if let application = NSWorkspace.shared.frontmostApplication {
            track(application: application)

            if preferences.blacklistedBundleIDs.contains(application.bundleIdentifier ?? "") {
                return
            }
        }

        captureCurrentClipboard()
    }

    private func captureCurrentClipboard() {
        guard let modelContext else {
            return
        }

        guard !preferences.isMonitoringPaused else {
            return
        }

        let pasteboard = NSPasteboard.general

        if let text = cleanedText(from: pasteboard.string(forType: .string)) {
            let signature = makeSignature(kind: .text, data: Data(text.utf8))
            storeClipboardItem(
                kind: .text,
                content: text,
                signature: signature,
                using: modelContext
            )
            return
        }

        if let imageData = pasteboard.data(forType: .png), let image = NSImage(data: imageData) {
            let summary = makeImageSummary(from: image)
            let signature = makeSignature(kind: .image, data: imageData)
            let recognizedText = recognizeText(in: image)
            storeClipboardItem(
                kind: .image,
                content: summary,
                imageData: imageData,
                recognizedText: recognizedText,
                signature: signature,
                using: modelContext
            )
            return
        }

        let filePaths = (pasteboard.pasteboardItems ?? []).compactMap { item -> String? in
            guard let fileURLString = item.string(forType: .fileURL),
                  let fileURL = URL(string: fileURLString) else {
                return nil
            }

            return fileURL.path
        }
        guard !filePaths.isEmpty else {
            return
        }

        let fileSummary = Item.makeFileSummary(from: filePaths)
        let fileList = filePaths.joined(separator: "\n")
        let signature = makeSignature(kind: .file, data: Data(fileList.utf8))

        storeClipboardItem(
            kind: .file,
            content: fileSummary,
            fileList: fileList,
            signature: signature,
            using: modelContext
        )
    }

    private func storeClipboardItem(
        kind: ClipboardItemKind,
        content: String,
        imageData: Data? = nil,
        fileList: String? = nil,
        recognizedText: String? = nil,
        signature: String,
        using modelContext: ModelContext
    ) {
        let currentSignature = signature
        let duplicateDescriptor = FetchDescriptor<Item>(
            predicate: #Predicate<Item> { item in
                item.signature == currentSignature
            },
            sortBy: [SortDescriptor(\Item.copiedAt, order: .reverse)]
        )

        if let duplicates = try? modelContext.fetch(duplicateDescriptor), let firstMatch = duplicates.first {
            firstMatch.kind = kind
            firstMatch.content = content
            firstMatch.imageData = imageData
            firstMatch.fileList = fileList
            firstMatch.recognizedText = recognizedText
            firstMatch.copiedAt = .now

            for item in duplicates.dropFirst() {
                modelContext.delete(item)
            }
        } else {
            modelContext.insert(
                Item(
                    kind: kind,
                    content: content,
                    imageData: imageData,
                    fileList: fileList,
                    recognizedText: recognizedText,
                    signature: signature
                )
            )
        }

        let allItemsDescriptor = FetchDescriptor<Item>(
            sortBy: [SortDescriptor(\Item.copiedAt, order: .reverse)]
        )

        let historyLimit = preferences.historyLimit
        if let allItems = try? modelContext.fetch(allItemsDescriptor), allItems.count > historyLimit {
            for item in allItems.dropFirst(historyLimit) {
                modelContext.delete(item)
            }
        }

        try? modelContext.save()
    }

    func copy(_ item: Item, using modelContext: ModelContext) {
        item.copiedAt = .now
        try? modelContext.save()

        switch item.kind {
        case .text:
            writeTextToPasteboard(item.content)
        case .image:
            if let imageData = item.imageData {
                writeImageToPasteboard(imageData)
            }
        case .file:
            writeFilesToPasteboard(item.filePaths)
        }
    }

    func directPaste(_ item: Item, using modelContext: ModelContext) -> PasteResult {
        copy(item, using: modelContext)

        if preferences.historyItemAction == .copyOnly {
            return .copiedNeedsManualPaste(reason: "当前设置为仅复制")
        }

        guard let targetApplication = currentPasteTargetApplication() else {
            return .copiedNeedsManualPaste(reason: "未找到当前窗口")
        }

        guard ensureAccessibilityPermission(prompt: true) else {
            return .copiedNeedsManualPaste(reason: "没有辅助功能权限")
        }

        targetApplication.activate()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            self.restoreFocusAndPaste(item, to: targetApplication.processIdentifier)
        }

        return .pasted
    }

    private func writeTextToPasteboard(_ content: String) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setString(content, forType: .string)
        lastChangeCount = pasteboard.changeCount
        ignoredChangeCount = pasteboard.changeCount
    }

    private func writeImageToPasteboard(_ imageData: Data) {
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.setData(imageData, forType: .png)
        lastChangeCount = pasteboard.changeCount
        ignoredChangeCount = pasteboard.changeCount
    }

    private func writeFilesToPasteboard(_ filePaths: [String]) {
        let urls = filePaths.map { URL(fileURLWithPath: $0) }
        let pasteboard = NSPasteboard.general
        pasteboard.clearContents()
        pasteboard.writeObjects(urls as [NSURL])
        lastChangeCount = pasteboard.changeCount
        ignoredChangeCount = pasteboard.changeCount
    }

    private func makeImageSummary(from image: NSImage) -> String {
        let width = Int(image.size.width)
        let height = Int(image.size.height)
        return "图片 \(width)×\(height)"
    }

    private func makeSignature(kind: ClipboardItemKind, data: Data) -> String {
        let digest = SHA256.hash(data: data)
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        return "\(kind.rawValue):\(hex)"
    }

    private func startTrackingTargetApplication() {
        guard workspaceObserver == nil else {
            return
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleActivatedApplicationNotification),
            name: NSWorkspace.didActivateApplicationNotification,
            object: NSWorkspace.shared
        )
        workspaceObserver = self

        if let current = NSWorkspace.shared.frontmostApplication {
            track(application: current)
        }
    }

    @objc private func handleActivatedApplicationNotification() {
        Task { @MainActor in
            guard let application = NSWorkspace.shared.frontmostApplication else {
                return
            }

            self.track(application: application)
        }
    }

    private func track(application: NSRunningApplication) {
        guard shouldTrack(application: application) else {
            return
        }

        lastTargetApplication = application

        guard ensureAccessibilityPermission(prompt: false) else {
            lastFocusedElement = nil
            lastFocusedElementProcessIdentifier = nil
            return
        }

        captureFocusedElement(for: application.processIdentifier)
    }

    private func shouldTrack(application: NSRunningApplication) -> Bool {
        let ownBundleID = Bundle.main.bundleIdentifier
        guard application.bundleIdentifier != ownBundleID else {
            return false
        }

        guard application.activationPolicy == .regular else {
            return false
        }

        return true
    }

    private func currentPasteTargetApplication() -> NSRunningApplication? {
        if let frontmostApplication = NSWorkspace.shared.frontmostApplication,
           shouldTrack(application: frontmostApplication) {
            return frontmostApplication
        }

        return lastTargetApplication
    }

    private func ensureAccessibilityPermission(prompt: Bool) -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    private func cleanedText(from original: String?) -> String? {
        guard var text = original else {
            return nil
        }

        if preferences.trimWhitespace {
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        }

        if preferences.collapseNewlines {
            text = text
                .replacingOccurrences(of: "\r\n", with: "\n")
                .replacingOccurrences(of: "\n", with: " ")
        }

        if preferences.skipBlankContent && text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return nil
        }

        if text.count > preferences.maximumTextLength {
            return nil
        }

        return text
    }

    private func recognizeText(in image: NSImage) -> String? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            return nil
        }

        let text = request.results?
            .compactMap { $0.topCandidates(1).first?.string }
            .joined(separator: "\n")

        guard let text, !text.isEmpty else {
            return nil
        }

        return text
    }

    private func captureFocusedElement(for processIdentifier: pid_t) {
        let applicationElement = AXUIElementCreateApplication(processIdentifier)
        var focusedElement: CFTypeRef?

        let result = AXUIElementCopyAttributeValue(
            applicationElement,
            kAXFocusedUIElementAttribute as CFString,
            &focusedElement
        )

        guard result == .success, let focusedElement else {
            lastFocusedElement = nil
            lastFocusedElementProcessIdentifier = nil
            return
        }

        lastFocusedElement = (focusedElement as! AXUIElement)
        lastFocusedElementProcessIdentifier = processIdentifier
    }

    private func restoreFocusAndPaste(_ item: Item, to processIdentifier: pid_t) {
        if processIdentifier == lastFocusedElementProcessIdentifier, let lastFocusedElement {
            _ = restoreFocus(to: lastFocusedElement)

            if item.kind == .text, insertText(item.content, into: lastFocusedElement) {
                return
            }
        }

        sendPasteShortcut(to: processIdentifier)
    }

    private func restoreFocus(to element: AXUIElement) -> Bool {
        AXUIElementSetAttributeValue(
            element,
            kAXFocusedAttribute as CFString,
            kCFBooleanTrue
        ) == .success
    }

    private func insertText(_ text: String, into element: AXUIElement) -> Bool {
        var isSettable = DarwinBoolean(false)
        if AXUIElementIsAttributeSettable(
            element,
            kAXSelectedTextAttribute as CFString,
            &isSettable
        ) == .success, isSettable.boolValue {
            if AXUIElementSetAttributeValue(
                element,
                kAXSelectedTextAttribute as CFString,
                text as CFTypeRef
            ) == .success {
                return true
            }
        }

        guard let currentValue = stringAttribute(kAXValueAttribute as CFString, on: element),
              let selectedRange = selectedTextRange(on: element),
              isAttributeSettable(kAXValueAttribute as CFString, on: element) else {
            return false
        }

        let lowerBound = max(0, min(selectedRange.location, currentValue.count))
        let upperBound = max(lowerBound, min(selectedRange.location + selectedRange.length, currentValue.count))
        let startIndex = currentValue.index(currentValue.startIndex, offsetBy: lowerBound)
        let endIndex = currentValue.index(currentValue.startIndex, offsetBy: upperBound)
        let updatedValue = currentValue[..<startIndex] + text + currentValue[endIndex...]

        let setValueResult = AXUIElementSetAttributeValue(
            element,
            kAXValueAttribute as CFString,
            String(updatedValue) as CFTypeRef
        )

        guard setValueResult == .success else {
            return false
        }

        let insertionLocation = lowerBound + text.count
        var collapsedRange = CFRange(location: insertionLocation, length: 0)
        if let rangeValue = AXValueCreate(.cfRange, &collapsedRange) {
            _ = AXUIElementSetAttributeValue(
                element,
                kAXSelectedTextRangeAttribute as CFString,
                rangeValue
            )
        }

        return true
    }

    private func stringAttribute(_ attribute: CFString, on element: AXUIElement) -> String? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(element, attribute, &value)
        guard result == .success else {
            return nil
        }

        return value as? String
    }

    private func selectedTextRange(on element: AXUIElement) -> CFRange? {
        var value: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(
            element,
            kAXSelectedTextRangeAttribute as CFString,
            &value
        )

        guard result == .success,
              let axValue = value,
              CFGetTypeID(axValue) == AXValueGetTypeID() else {
            return nil
        }

        let castValue = axValue as! AXValue
        guard AXValueGetType(castValue) == .cfRange else {
            return nil
        }

        var range = CFRange()
        guard AXValueGetValue(castValue, .cfRange, &range) else {
            return nil
        }

        return range
    }

    private func isAttributeSettable(_ attribute: CFString, on element: AXUIElement) -> Bool {
        var isSettable = DarwinBoolean(false)
        let result = AXUIElementIsAttributeSettable(element, attribute, &isSettable)
        return result == .success && isSettable.boolValue
    }

    private func sendPasteShortcut(to processIdentifier: pid_t) {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            return
        }

        let keyCode: CGKeyCode = 9
        let flags: CGEventFlags = .maskCommand

        let keyDown = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: true)
        keyDown?.flags = flags
        keyDown?.postToPid(processIdentifier)

        let keyUp = CGEvent(keyboardEventSource: source, virtualKey: keyCode, keyDown: false)
        keyUp?.flags = flags
        keyUp?.postToPid(processIdentifier)
    }
}

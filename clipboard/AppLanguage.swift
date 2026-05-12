//
//  AppLanguage.swift
//  clipboard
//
//  Joker Created by Codex on 2026/5/12.
//

import Foundation

enum AppLanguage: String, CaseIterable, Identifiable {
    case simplifiedChinese
    case english

    var id: String { rawValue }

    var title: String {
        switch self {
        case .simplifiedChinese:
            return "简体中文"
        case .english:
            return "English"
        }
    }
}

struct AppStrings {
    let language: AppLanguage

    var clipboardTitle: String { text("T clipboard", "T clipboard") }
    var emptyClipboardHistoryTitle: String { text("暂无剪切板历史", "No Clipboard History") }
    var emptyClipboardHistoryDescription: String { text("复制任意文本后，这里会自动记录。", "Copy any text and it will appear here automatically.") }
    var pinnedSection: String { text("固定", "Pinned") }
    var historySection: String { text("历史记录", "History") }
    var recentSection: String { text("最近", "Recent") }
    var delete: String { text("删除", "Delete") }
    var clear: String { text("清空", "Clear") }
    var clearHistory: String { text("清空历史", "Clear History") }
    var pin: String { text("固定", "Pin") }
    var unpin: String { text("取消固定", "Unpin") }
    var contentDetail: String { text("内容详情", "Content Detail") }
    var selectRecordTitle: String { text("选择一条记录", "Select an Item") }
    var selectRecordDescription: String { text("右侧会显示完整内容，并可再次复制。", "The full content appears on the right and can be copied again.") }
    var githubHelp: String { text("打开 GitHub 项目地址", "Open GitHub repository") }
    var paste: String { text("粘贴", "Paste") }
    var copy: String { text("复制", "Copy") }
    var searchHistory: String { text("搜索历史内容", "Search history") }
    var copied: String { text("已复制", "Copied") }
    var pastedToPreviousApp: String { text("已粘贴到上一个应用", "Pasted to the previous app") }
    var imageDataUnavailable: String { text("图片数据不可用", "Image data is unavailable") }
    var monitoringPaused: String { text("剪切板监听已暂停", "Clipboard monitoring is paused") }
    var openMainWindow: String { text("打开主窗口", "Open Main Window") }
    var settings: String { text("设置", "Settings") }
    var resumeMonitoring: String { text("继续监听", "Resume") }
    var pauseMonitoring: String { text("暂停监听", "Pause") }
    var emptyHistoryTitle: String { text("暂无历史", "No History") }
    var emptyHistoryDescription: String { text("复制文本后会自动出现在这里。", "Copied text will appear here automatically.") }
    var directPaste: String { text("直接粘贴", "Direct Paste") }
    var copyOnly: String { text("仅复制", "Copy Only") }
    var currentSettingIsCopyOnly: String { text("当前设置为仅复制", "Current setting is copy only") }
    var noCurrentWindow: String { text("未找到当前窗口", "No current window found") }
    var missingAccessibilityPermission: String { text("没有辅助功能权限", "Missing Accessibility permission") }

    var launchSection: String { text("启动", "Launch") }
    var launchAtLogin: String { text("开机启动", "Launch at Login") }
    var currentStatusPrefix: String { text("当前状态", "Current status") }
    var settingFailedPrefix: String { text("设置失败", "Setting failed") }
    var hotKeySection: String { text("快捷键", "Hotkey") }
    var hotKeyHint: String { text("设置后可在任何地方唤起主窗口。", "Use it anywhere to open the main window.") }
    var languageSection: String { text("语言", "Language") }
    var appLanguage: String { text("应用语言", "App Language") }
    var languageHint: String { text("切换后立即应用到主要界面。", "Applies immediately to the main interface.") }
    var updatesSection: String { text("更新", "Updates") }
    var checkForUpdates: String { text("检查更新", "Check for Updates") }
    var updatesEnabledHint: String { text("将通过 Sparkle 检查 GitHub Release 更新。", "Checks GitHub Release updates through Sparkle.") }
    var updatesDisabledHint: String { text("自动更新尚未配置公钥和更新源。生成 Sparkle 密钥后在构建设置中填入。", "Automatic updates need a Sparkle public key and feed URL. Generate a Sparkle key and fill them in build settings.") }
    var interactionSection: String { text("交互", "Interaction") }
    var pauseClipboardMonitoring: String { text("暂停监听剪切板", "Pause Clipboard Monitoring") }
    var pausedHint: String { text("暂停期间复制的新内容不会被记录。", "New copies are not recorded while monitoring is paused.") }
    var activeHint: String { text("当前会自动记录新的剪切板内容。", "New clipboard content is recorded automatically.") }
    var historyItemClickAction: String { text("点击历史项", "Click History Item") }
    var textCleaningSection: String { text("文本清洗", "Text Cleanup") }
    var trimWhitespace: String { text("去掉首尾空白", "Trim leading and trailing whitespace") }
    var collapseNewlines: String { text("合并换行为空格", "Collapse newlines into spaces") }
    var skipBlankContent: String { text("忽略空白内容", "Ignore blank content") }
    var filterSensitiveText: String { text("过滤敏感文本", "Filter sensitive text") }
    var sensitiveFilterHint: String { text("默认跳过常见验证码、token、API Key、私钥和 password/secret 字段。", "Skips common verification codes, tokens, API keys, private keys, and password/secret fields by default.") }
    var blacklistedAppsSection: String { text("黑名单应用", "Blacklisted Apps") }
    var blacklistHint: String { text("每行一个 bundle id，例如 `com.apple.keychainaccess`。黑名单应用复制的内容不会被记录。", "One bundle id per line, for example `com.apple.keychainaccess`. Copies from blacklisted apps are not recorded.") }
    var recordHotKey: String { text("按下新的快捷键", "Press a new hotkey") }
    var setHotKey: String { text("点击设置快捷键", "Click to set hotkey") }
    var clearHotKey: String { text("清除", "Clear") }

    func copiedNeedsManualPaste(reason: String) -> String {
        text("已复制，按 Command+V 粘贴。原因：\(reason)", "Copied. Press Command+V to paste. Reason: \(reason)")
    }

    func historyLimit(_ value: Int) -> String {
        text("历史上限：\(value)", "History limit: \(value)")
    }

    func maximumTextLength(_ value: Int) -> String {
        text("最大文本长度：\(value)", "Maximum text length: \(value)")
    }

    func launchAtLoginStatus(_ status: String) -> String {
        text("当前状态：\(status)", "Current status: \(status)")
    }

    func launchAtLoginError(_ error: String) -> String {
        text("设置失败：\(error)", "Setting failed: \(error)")
    }

    func text(_ zhCN: String, _ en: String) -> String {
        switch language {
        case .simplifiedChinese:
            return zhCN
        case .english:
            return en
        }
    }
}

extension HistoryItemAction {
    func title(for strings: AppStrings) -> String {
        switch self {
        case .directPaste:
            return strings.directPaste
        case .copyOnly:
            return strings.copyOnly
        }
    }
}

//
//  AppPreferences.swift
//  clipboard
//
//  Joker Created by Codex on 2026/5/12.
//

import Combine
import Foundation
import ServiceManagement

enum HistoryItemAction: String, CaseIterable, Identifiable {
    case directPaste
    case copyOnly

    var id: String { rawValue }

    var title: String {
        switch self {
        case .directPaste:
            return "直接粘贴"
        case .copyOnly:
            return "仅复制"
        }
    }
}

@MainActor
final class AppPreferences: ObservableObject {
    @Published var launchAtLogin: Bool {
        didSet {
            guard !isBootstrapping else {
                return
            }

            persistLaunchAtLogin()
            updateLaunchAtLoginRegistration()
        }
    }

    @Published var hotKey: HotKey? {
        didSet {
            guard !isBootstrapping else {
                return
            }

            persistHotKey()
        }
    }

    @Published var historyItemActionRaw: String {
        didSet {
            guard !isBootstrapping else {
                return
            }

            defaults.set(historyItemActionRaw, forKey: Self.historyItemActionKey)
        }
    }

    @Published var isMonitoringPaused: Bool {
        didSet {
            guard !isBootstrapping else {
                return
            }

            defaults.set(isMonitoringPaused, forKey: Self.isMonitoringPausedKey)
        }
    }

    @Published var historyLimit: Int {
        didSet {
            guard !isBootstrapping else {
                return
            }

            historyLimit = max(10, min(historyLimit, 500))
            defaults.set(historyLimit, forKey: Self.historyLimitKey)
        }
    }

    @Published var trimWhitespace: Bool {
        didSet {
            guard !isBootstrapping else {
                return
            }

            defaults.set(trimWhitespace, forKey: Self.trimWhitespaceKey)
        }
    }

    @Published var collapseNewlines: Bool {
        didSet {
            guard !isBootstrapping else {
                return
            }

            defaults.set(collapseNewlines, forKey: Self.collapseNewlinesKey)
        }
    }

    @Published var skipBlankContent: Bool {
        didSet {
            guard !isBootstrapping else {
                return
            }

            defaults.set(skipBlankContent, forKey: Self.skipBlankContentKey)
        }
    }

    @Published var maximumTextLength: Int {
        didSet {
            guard !isBootstrapping else {
                return
            }

            maximumTextLength = max(100, min(maximumTextLength, 20000))
            defaults.set(maximumTextLength, forKey: Self.maximumTextLengthKey)
        }
    }

    @Published var blacklistedBundlesText: String {
        didSet {
            guard !isBootstrapping else {
                return
            }

            defaults.set(blacklistedBundlesText, forKey: Self.blacklistedBundlesKey)
        }
    }

    @Published var launchAtLoginError: String?

    private let defaults: UserDefaults
    private var isBootstrapping = true

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.launchAtLogin = defaults.object(forKey: Self.launchAtLoginKey) as? Bool ?? false
        self.hotKey = Self.loadHotKey(from: defaults)
        self.historyItemActionRaw = defaults.string(forKey: Self.historyItemActionKey) ?? HistoryItemAction.directPaste.rawValue
        self.isMonitoringPaused = defaults.object(forKey: Self.isMonitoringPausedKey) as? Bool ?? false
        self.historyLimit = defaults.object(forKey: Self.historyLimitKey) as? Int ?? 50
        self.trimWhitespace = defaults.object(forKey: Self.trimWhitespaceKey) as? Bool ?? true
        self.collapseNewlines = defaults.object(forKey: Self.collapseNewlinesKey) as? Bool ?? false
        self.skipBlankContent = defaults.object(forKey: Self.skipBlankContentKey) as? Bool ?? true
        self.maximumTextLength = defaults.object(forKey: Self.maximumTextLengthKey) as? Int ?? 5000
        self.blacklistedBundlesText = defaults.string(forKey: Self.blacklistedBundlesKey) ?? ""
        self.isBootstrapping = false
    }

    var historyItemAction: HistoryItemAction {
        get { HistoryItemAction(rawValue: historyItemActionRaw) ?? .directPaste }
        set { historyItemActionRaw = newValue.rawValue }
    }

    var blacklistedBundleIDs: Set<String> {
        Set(
            blacklistedBundlesText
                .split(whereSeparator: \.isNewline)
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { !$0.isEmpty }
        )
    }

    var launchAtLoginStatusText: String {
        switch SMAppService.mainApp.status {
        case .enabled:
            return "已启用"
        case .notRegistered:
            return "未启用"
        case .requiresApproval:
            return "需要在系统设置中批准"
        case .notFound:
            return "当前构建暂不可注册"
        @unknown default:
            return "未知状态"
        }
    }

    func synchronizeLaunchAtLoginState() {
        let registered = SMAppService.mainApp.status == .enabled

        if launchAtLogin != registered {
            isBootstrapping = true
            launchAtLogin = registered
            isBootstrapping = false
            persistLaunchAtLogin()
        }
    }

    private func updateLaunchAtLoginRegistration() {
        do {
            if launchAtLogin {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }

            launchAtLoginError = nil
            synchronizeLaunchAtLoginState()
        } catch {
            launchAtLoginError = error.localizedDescription
            synchronizeLaunchAtLoginState()
        }
    }

    private func persistLaunchAtLogin() {
        defaults.set(launchAtLogin, forKey: Self.launchAtLoginKey)
    }

    private func persistHotKey() {
        if let hotKey {
            defaults.set(Int(hotKey.keyCode), forKey: Self.hotKeyCodeKey)
            defaults.set(Int(hotKey.modifiers), forKey: Self.hotKeyModifiersKey)
        } else {
            defaults.removeObject(forKey: Self.hotKeyCodeKey)
            defaults.removeObject(forKey: Self.hotKeyModifiersKey)
        }
    }

    private static func loadHotKey(from defaults: UserDefaults) -> HotKey? {
        guard defaults.object(forKey: hotKeyCodeKey) != nil,
              defaults.object(forKey: hotKeyModifiersKey) != nil else {
            return nil
        }

        let keyCode = UInt32(defaults.integer(forKey: hotKeyCodeKey))
        let modifiers = UInt32(defaults.integer(forKey: hotKeyModifiersKey))
        return HotKey(keyCode: keyCode, modifiers: modifiers)
    }

    private static let launchAtLoginKey = "launchAtLogin"
    private static let hotKeyCodeKey = "hotKeyCode"
    private static let hotKeyModifiersKey = "hotKeyModifiers"
    private static let historyItemActionKey = "historyItemAction"
    private static let isMonitoringPausedKey = "isMonitoringPaused"
    private static let historyLimitKey = "historyLimit"
    private static let trimWhitespaceKey = "trimWhitespace"
    private static let collapseNewlinesKey = "collapseNewlines"
    private static let skipBlankContentKey = "skipBlankContent"
    private static let maximumTextLengthKey = "maximumTextLength"
    private static let blacklistedBundlesKey = "blacklistedBundles"
}

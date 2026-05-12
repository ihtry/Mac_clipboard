//
//  UpdateManager.swift
//  clipboard
//
//  Joker Created by Codex on 2026/5/12.
//

import Combine
import Foundation
import Sparkle

@MainActor
final class UpdateManager: NSObject, ObservableObject {
    @Published private(set) var isAvailable: Bool
    @Published private(set) var statusMessage: String?

    private let updaterController: SPUStandardUpdaterController?

    override init() {
        let configuration = SparkleConfiguration.current
        isAvailable = configuration.isEnabled
        statusMessage = configuration.validationMessage

        if configuration.isEnabled {
            updaterController = SPUStandardUpdaterController(
                startingUpdater: true,
                updaterDelegate: nil,
                userDriverDelegate: nil
            )
        } else {
            updaterController = nil
        }

        super.init()
    }

    func checkForUpdates() {
        updaterController?.checkForUpdates(nil)
    }
}

struct SparkleConfiguration {
    let feedURL: String
    let publicKey: String

    var isEnabled: Bool {
        validationMessage == nil
    }

    var validationMessage: String? {
        if feedURL.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "缺少更新源地址"
        }

        if publicKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return "缺少 Sparkle 公钥"
        }

        guard let url = URL(string: feedURL), let scheme = url.scheme?.lowercased(), scheme == "https" else {
            return "更新源地址必须是有效的 HTTPS URL"
        }

        return nil
    }

    static var current: SparkleConfiguration {
        let infoDictionary = Bundle.main.infoDictionary ?? [:]
        return SparkleConfiguration(
            feedURL: infoDictionary["SUFeedURL"] as? String ?? "",
            publicKey: infoDictionary["SUPublicEDKey"] as? String ?? ""
        )
    }
}

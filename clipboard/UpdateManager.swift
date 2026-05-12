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

    private let updaterController: SPUStandardUpdaterController?

    override init() {
        let configuration = SparkleConfiguration.current
        isAvailable = configuration.isEnabled

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
        !feedURL.isEmpty && !publicKey.isEmpty
    }

    static var current: SparkleConfiguration {
        let infoDictionary = Bundle.main.infoDictionary ?? [:]
        return SparkleConfiguration(
            feedURL: infoDictionary["SUFeedURL"] as? String ?? "",
            publicKey: infoDictionary["SUPublicEDKey"] as? String ?? ""
        )
    }
}

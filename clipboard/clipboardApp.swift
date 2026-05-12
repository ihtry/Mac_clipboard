//
//  clipboardApp.swift
//  clipboard
//
//  Created by joker on 2026/5/12.
//

import Foundation
import SwiftData
import SwiftUI

enum AppWindowID {
    static let main = "main-window"
}

@MainActor
@main
struct clipboardApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    private let sharedModelContainer: ModelContainer
    private let clipboardMonitor: ClipboardMonitor
    private let preferences: AppPreferences
    private let hotKeyManager: HotKeyManager
    private let updateManager: UpdateManager

    init() {
        let schema = Schema([
            Item.self,
        ])
        let storeURL = Self.storeURL()
        let modelConfiguration = ModelConfiguration(schema: schema, url: storeURL)
        sharedModelContainer = Self.makeModelContainer(
            schema: schema,
            configuration: modelConfiguration,
            storeURL: storeURL
        )

        preferences = AppPreferences()
        clipboardMonitor = ClipboardMonitor(preferences: preferences)
        clipboardMonitor.start(using: sharedModelContainer.mainContext)
        hotKeyManager = HotKeyManager(preferences: preferences)
        updateManager = UpdateManager()
    }

    var body: some Scene {
        WindowGroup("T clipboard", id: AppWindowID.main) {
            ContentView()
                .frame(minWidth: 900, minHeight: 560)
                .environmentObject(clipboardMonitor)
                .environmentObject(preferences)
                .environmentObject(updateManager)
                .background(
                    WindowCommandBridge(appDelegate: appDelegate, hotKeyManager: hotKeyManager)
                )
                .background(WindowIdentitySetter())
        }
        .modelContainer(sharedModelContainer)

        MenuBarExtra(preferences.strings.clipboardTitle, systemImage: "clipboard") {
            MenuBarHistoryView()
                .frame(width: 380, height: 480)
                .environmentObject(clipboardMonitor)
                .environmentObject(preferences)
                .environmentObject(updateManager)
        }
        .menuBarExtraStyle(.window)
        .modelContainer(sharedModelContainer)

        Settings {
            SettingsView()
                .environmentObject(preferences)
                .environmentObject(updateManager)
        }
    }

    private static func makeModelContainer(
        schema: Schema,
        configuration: ModelConfiguration,
        storeURL: URL
    ) -> ModelContainer {
        do {
            return try ModelContainer(for: schema, configurations: [configuration])
        } catch {
            clearStore(at: storeURL)

            do {
                return try ModelContainer(for: schema, configurations: [configuration])
            } catch {
                fatalError("Could not create ModelContainer: \(error)")
            }
        }
    }

    private static func storeURL() -> URL {
        let baseDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let appDirectory = baseDirectory.appendingPathComponent("clipboard", isDirectory: true)

        try? FileManager.default.createDirectory(at: appDirectory, withIntermediateDirectories: true)

        return appDirectory.appendingPathComponent("clipboard.store")
    }

    private static func clearStore(at storeURL: URL) {
        let fileManager = FileManager.default
        let cleanupURLs = [
            storeURL,
            storeURL.appendingPathExtension("shm"),
            storeURL.appendingPathExtension("wal")
        ]

        for url in cleanupURLs where fileManager.fileExists(atPath: url.path) {
            try? fileManager.removeItem(at: url)
        }
    }
}

private struct WindowCommandBridge: View {
    let appDelegate: AppDelegate
    let hotKeyManager: HotKeyManager

    @Environment(\.openWindow) private var openWindow

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .task {
                appDelegate.openMainWindow = {
                    openWindow(id: AppWindowID.main)
                }

                hotKeyManager.onTrigger = {
                    appDelegate.showMainWindow(nil)
                }
            }
    }
}

private struct WindowIdentitySetter: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        let view = NSView()

        DispatchQueue.main.async {
            view.window?.identifier = NSUserInterfaceItemIdentifier(AppWindowID.main)
        }

        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            nsView.window?.identifier = NSUserInterfaceItemIdentifier(AppWindowID.main)
        }
    }
}

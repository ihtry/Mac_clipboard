//
//  AppDelegate.swift
//  clipboard
//
//  Joker Created by Codex on 2026/5/12.
//

import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var openMainWindow: (() -> Void)?

    @objc func showMainWindow(_ sender: Any?) {
        NSApp.activate(ignoringOtherApps: true)
        openMainWindow?()
        bringMainWindowToFront()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showMainWindow(nil)
        }

        return true
    }

    private func bringMainWindowToFront() {
        guard let window = NSApp.windows.first(where: { $0.identifier?.rawValue == AppWindowID.main }) ?? NSApp.windows.first else {
            return
        }

        if window.isMiniaturized {
            window.deminiaturize(nil)
        }

        window.orderFrontRegardless()
        window.makeKeyAndOrderFront(nil)
    }
}

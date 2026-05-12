# T clipboard

[![Release](https://img.shields.io/github/v/release/ihtry/Mac_clipboard?display_name=tag)](https://github.com/ihtry/Mac_clipboard/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
![Swift](https://img.shields.io/badge/Swift-5-orange.svg)
![Xcode](https://img.shields.io/badge/Xcode-17-blue.svg)

[中文](README.zh-CN.md) | English

T clipboard is a lightweight macOS clipboard history app built with SwiftUI and SwiftData. It records clipboard content locally and lets you quickly search, pin, and copy previous items again.

**Tags:** `macOS` `SwiftUI` `SwiftData` `Clipboard Manager` `Menu Bar App` `Hotkey`

## Highlights

- Text, image, and file-path clipboard history
- Fast keyword search
- Pin important clipboard items
- Directly paste a history item into the previous app, or copy only
- Menu bar access
- Global hotkey support, defaulting to `⌘⇧V`
- In-app Simplified Chinese and English switching
- Pause monitoring for privacy-sensitive moments
- Optional sensitive text filtering
- Local-first storage with SwiftData

## Download

Download the latest `T-clipboard.dmg` from [GitHub Releases](https://github.com/ihtry/Mac_clipboard/releases).

Open the DMG, then drag `T clipboard.app` into `Applications`.

## Build From Source

Requirements:

- macOS
- Xcode
- Xcode Command Line Tools

Build a Release app:

```sh
xcodebuild -project clipboard.xcodeproj -scheme clipboard -configuration Release build
```

## Package A DMG

Create a standard drag-to-install DMG:

```sh
scripts/package-dmg.sh
```

The generated DMG contains:

- `T clipboard.app`
- `Applications` shortcut

## Notarization

For public distribution outside the App Store, sign with a Developer ID certificate and notarize the DMG.

Create a notarytool keychain profile:

```sh
xcrun notarytool store-credentials "t-clipboard-notary"
```

Submit and staple a packaged DMG:

```sh
NOTARYTOOL_PROFILE=t-clipboard-notary scripts/notarize-dmg.sh dist/T-clipboard.dmg
```

## Repository Policy

The repository stores source code only. Build artifacts such as DMG files are ignored by Git and should be distributed through GitHub Releases.

## License

[MIT](LICENSE)

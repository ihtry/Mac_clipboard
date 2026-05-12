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
- Copy any history item back to the system clipboard
- Menu bar access
- Global hotkey support
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

After a Release build, create a standard drag-to-install DMG:

```sh
rm -rf dist/dmg-root dist/T-clipboard.dmg
mkdir -p dist/dmg-root
cp -R ~/Library/Developer/Xcode/DerivedData/clipboard-*/Build/Products/Release/clipboard.app "dist/dmg-root/T clipboard.app"
ln -s /Applications dist/dmg-root/Applications
hdiutil create -volname "T clipboard" -srcfolder dist/dmg-root -ov -format UDZO dist/T-clipboard.dmg
```

The generated DMG contains:

- `T clipboard.app`
- `Applications` shortcut

## Repository Policy

The repository stores source code only. Build artifacts such as DMG files are ignored by Git and should be distributed through GitHub Releases.

## License

[MIT](LICENSE)

# T clipboard

T clipboard is a macOS clipboard history app built with SwiftUI and SwiftData.

中文文档: [README.zh-CN.md](README.zh-CN.md)

## Features

- Automatically records copied text, images, and file paths.
- Search clipboard history.
- Pin important clipboard items.
- Copy previous items back to the system clipboard.
- Menu bar access and global hotkey support.
- Local-first storage.

## Installation

This repository only stores source code. Build the app locally with Xcode, or create a DMG from the Release build.

## Build

Requirements:

- macOS with Xcode installed
- Xcode command line tools

Build from the repository root:

```sh
xcodebuild -project clipboard.xcodeproj -scheme clipboard -configuration Release build
```

## Package DMG

After building Release, create a drag-to-install DMG:

```sh
rm -rf dist/dmg-root dist/T-clipboard.dmg
mkdir -p dist/dmg-root
cp -R ~/Library/Developer/Xcode/DerivedData/clipboard-*/Build/Products/Release/clipboard.app "dist/dmg-root/T clipboard.app"
ln -s /Applications dist/dmg-root/Applications
hdiutil create -volname "T clipboard" -srcfolder dist/dmg-root -ov -format UDZO dist/T-clipboard.dmg
```

The generated DMG contains `T clipboard.app` and an `Applications` shortcut, so users can install it by dragging the app into `Applications`.

## License

MIT

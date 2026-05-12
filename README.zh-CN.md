# T clipboard

[![Release](https://img.shields.io/github/v/release/ihtry/Mac_clipboard?display_name=tag)](https://github.com/ihtry/Mac_clipboard/releases)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
![Platform](https://img.shields.io/badge/platform-macOS-lightgrey.svg)
![Swift](https://img.shields.io/badge/Swift-5-orange.svg)
![Xcode](https://img.shields.io/badge/Xcode-17-blue.svg)

中文 | [English](README.md)

T clipboard 是一个轻量级 macOS 剪切板历史应用，使用 SwiftUI 和 SwiftData 构建。它会在本地记录剪切板内容，并支持快速搜索、固定和再次复制历史记录。

**标签：** `macOS` `SwiftUI` `SwiftData` `剪切板管理器` `菜单栏应用` `全局快捷键`

## 功能亮点

- 记录文本、图片和文件路径
- 快速搜索剪切板历史
- 固定重要记录
- 将任意历史记录重新复制到系统剪切板
- 菜单栏入口
- 全局快捷键支持
- 基于 SwiftData 的本地优先存储

## 下载

从 [GitHub Releases](https://github.com/ihtry/Mac_clipboard/releases) 下载最新的 `T-clipboard.dmg`。

打开 DMG 后，将 `T clipboard.app` 拖入 `Applications` 即可安装。

## 从源码构建

环境要求：

- macOS
- Xcode
- Xcode Command Line Tools

构建 Release 版本：

```sh
xcodebuild -project clipboard.xcodeproj -scheme clipboard -configuration Release build
```

## 打包 DMG

Release 构建完成后，可以创建标准拖拽安装 DMG：

```sh
rm -rf dist/dmg-root dist/T-clipboard.dmg
mkdir -p dist/dmg-root
cp -R ~/Library/Developer/Xcode/DerivedData/clipboard-*/Build/Products/Release/clipboard.app "dist/dmg-root/T clipboard.app"
ln -s /Applications dist/dmg-root/Applications
hdiutil create -volname "T clipboard" -srcfolder dist/dmg-root -ov -format UDZO dist/T-clipboard.dmg
```

生成的 DMG 包含：

- `T clipboard.app`
- `Applications` 快捷方式

## 仓库说明

本仓库只保存源代码。DMG 等构建产物已被 Git 忽略，应通过 GitHub Releases 分发。

## 开源协议

[MIT](LICENSE)

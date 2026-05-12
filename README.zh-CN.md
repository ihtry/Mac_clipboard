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
- 将历史记录直接粘贴到上一个应用，或仅复制到系统剪切板
- 菜单栏入口
- 全局快捷键支持，默认 `⌘⇧V`
- 应用内简体中文 / English 切换
- 基于 Sparkle 的更新检查
- 支持隐私场景下暂停监听
- 可选敏感文本过滤
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

创建标准拖拽安装 DMG：

```sh
scripts/package-dmg.sh
```

如需在 Release 构建中启用 Sparkle 更新检查，传入 appcast 地址和 EdDSA 公钥：

```sh
SPARKLE_FEED_URL="https://raw.githubusercontent.com/ihtry/Mac_clipboard/main/appcast.xml" \
SPARKLE_PUBLIC_ED_KEY="your_sparkle_public_key" \
scripts/package-dmg.sh
```

生成的 DMG 包含：

- `T clipboard.app`
- `Applications` 快捷方式

## 公证

如果要在 App Store 之外公开分发，建议使用 Developer ID 证书签名，并对 DMG 进行 Apple notarization。

创建 notarytool 钥匙串配置：

```sh
xcrun notarytool store-credentials "t-clipboard-notary"
```

提交并装订 DMG：

```sh
NOTARYTOOL_PROFILE=t-clipboard-notary scripts/notarize-dmg.sh dist/T-clipboard.dmg
```

## 自动更新

T clipboard 已集成 Sparkle 更新检查。生成 Sparkle 签名密钥、发布 `appcast.xml` 后，使用 `SPARKLE_FEED_URL` 和 `SPARKLE_PUBLIC_ED_KEY` 构建 Release。

如果没有配置这两个值，应用会自动禁用“检查更新”按钮。

仓库 raw appcast 地址：

```text
https://raw.githubusercontent.com/ihtry/Mac_clipboard/main/appcast.xml
```

GitHub 仓库需要配置：

- 开启 GitHub Pages，并将来源设置为 **GitHub Actions**。
- 添加 Actions Secret：`SPARKLE_PRIVATE_KEY`。

使用 Sparkle 的 `generate_keys` 工具生成密钥，将私钥保存到 `SPARKLE_PRIVATE_KEY`，打包时使用公钥：

```sh
SPARKLE_FEED_URL="https://raw.githubusercontent.com/ihtry/Mac_clipboard/main/appcast.xml" \
SPARKLE_PUBLIC_ED_KEY="your_sparkle_public_key" \
scripts/package-dmg.sh
```

打包签名后的 Release 后，生成 appcast：

```sh
SPARKLE_GENERATE_APPCAST="/path/to/generate_appcast" scripts/generate-appcast.sh dist
```

仓库已包含 `.github/workflows/publish-appcast.yml`。发布 GitHub Release 后，它会下载 `T-clipboard.dmg`，生成 `appcast.xml`，并直接提交回仓库根目录。

## 仓库说明

本仓库只保存源代码。DMG 等构建产物已被 Git 忽略，应通过 GitHub Releases 分发。

## 开源协议

[MIT](LICENSE)

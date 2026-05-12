# T clipboard

T clipboard 是一个使用 SwiftUI 和 SwiftData 构建的 macOS 剪切板历史应用。

English documentation: [README.md](README.md)

## 功能

- 自动记录复制的文本、图片和文件路径。
- 搜索剪切板历史。
- 固定重要的剪切板记录。
- 将历史记录重新复制到系统剪切板。
- 支持菜单栏入口和全局快捷键。
- 数据优先保存在本地。

## 安装

本仓库只保存源代码。你可以使用 Xcode 本地构建应用，或从 Release 构建结果生成 DMG 安装包。

## 构建

环境要求：

- 已安装 Xcode 的 macOS
- Xcode Command Line Tools

在仓库根目录执行：

```sh
xcodebuild -project clipboard.xcodeproj -scheme clipboard -configuration Release build
```

## 打包 DMG

Release 构建完成后，可以创建拖拽安装 DMG：

```sh
rm -rf dist/dmg-root dist/T-clipboard.dmg
mkdir -p dist/dmg-root
cp -R ~/Library/Developer/Xcode/DerivedData/clipboard-*/Build/Products/Release/clipboard.app "dist/dmg-root/T clipboard.app"
ln -s /Applications dist/dmg-root/Applications
hdiutil create -volname "T clipboard" -srcfolder dist/dmg-root -ov -format UDZO dist/T-clipboard.dmg
```

生成的 DMG 内包含 `T clipboard.app` 和 `Applications` 快捷方式，用户打开后拖动应用到 `Applications` 即可安装。

## 开源协议

MIT

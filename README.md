# Magpie Mobile

Magpie 的非官方 Android / iOS 界面原型，使用 Flutter 构建。不是上游项目发布的客户端，也没有接入其 Go 核心。 / An unofficial Flutter prototype inspired by [Magpie](https://github.com/yetone/magpie), not an official client.

## 当前范围

- 设置中可切换简体中文和 English，偏好会保留。部分演示文案尚未完全翻译。
- 供应商、Agent、网关和资源库使用本地演示数据，不会连接实际服务。
- Skills 和 MCP 支持演示管理与导出预览；不写入导出文件，不启动本地 stdio 进程，不访问其他 App 的私有目录。

## 本地运行

使用 Flutter 3.38.9（Dart 3.10.8）。Android 建议使用 JDK 17、Android SDK Platform 36；iOS 需要 macOS 和 Xcode，尚未完成真机验证。

```sh
flutter pub get
flutter run
flutter analyze
flutter test
```

首次 Android 构建时 Flutter 会补齐本地 Gradle Wrapper 文件。此仓库不包含签名材料或本机 SDK 配置。

## 图标来源

桌面和应用内图标由 [上游 Magpie SVG](https://github.com/yetone/magpie/blob/95e6a4180866afde186e0f1a25369388c7fd7e7f/build/icon/magpie.svg) 适配生成。参见 [图标说明](assets/brand/README.md) 和 [上游 MIT 许可及版权声明](THIRD_PARTY_NOTICES.md)。名称与标志仅用于说明项目来源，不代表上游认可或官方发布。

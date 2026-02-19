# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- 应用启动后延迟 2 秒自动检查 GitHub Releases 最新版本
- 完整更新对话框：版本对比、Markdown 格式 Release Notes、跳过/稍后/立即更新三按钮
- "跳过此版本"持久化存储，跳过后自动检查不再提示同版本
- Android APK 下载进度 BottomSheet（下载中/安装中/失败三状态）
- Android 原生 APK 安装（FileProvider + MethodChannel）
- 镜像下载链接优先，失败自动回退原始链接
- 非 Android 平台通过浏览器打开 Release 页面

### Changed
- 设置页"检查更新"逻辑统一收拢到 UpdateService
- 更新对话框 Release Notes 从纯文本改为 Markdown 渲染
- 更新对话框最大高度从 200 调整为 300

### Dependencies
- 新增 `dio: ^5.4.1`（APK 下载，支持进度回调）
- 新增 `flutter_markdown: ^0.7.7+1`（Markdown 渲染）

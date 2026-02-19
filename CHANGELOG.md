# Changelog

All notable changes to this project will be documented in this file.

## [Unreleased]

### Added
- 首页新增网格视图模式，支持列表/网格切换（AppBar 切换按钮）
- 网格卡片：彩色标题栏（事件名+还有/已经）、大号天数数字、底部日期行
- 视图模式持久化（SharedPreferences），重启后保持上次选择
- 应用启动后延迟 2 秒自动检查 GitHub Releases 最新版本
- 完整更新对话框：版本对比、Markdown 格式 Release Notes、跳过/稍后/立即更新三按钮
- "跳过此版本"持久化存储，跳过后自动检查不再提示同版本
- Android APK 下载进度 BottomSheet（下载中/安装中/失败三状态）
- Android 原生 APK 安装（FileProvider + MethodChannel）
- 镜像下载链接优先，失败自动回退原始链接
- 非 Android 平台通过浏览器打开 Release 页面

### Removed
- 移除聚焦功能（isFocus 字段、focusEventProvider、setFocus 等）
- 首页不再显示聚焦卡片区域

### Changed
- EventCard 的 isFocusCard 参数重命名为 isGridCard，用于网格视图
- 首页 _buildEventList 拆分为 _buildListView 和 _buildGridView
- 设置页"检查更新"逻辑统一收拢到 UpdateService
- 更新对话框 Release Notes 从纯文本改为 Markdown 渲染
- 更新对话框最大高度从 200 调整为 300

### Dependencies
- 新增 `dio: ^5.4.1`（APK 下载，支持进度回调）
- 新增 `flutter_markdown: ^0.7.7+1`（Markdown 渲染）

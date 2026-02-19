# DaysMater - 倒数日应用

一款基于 Flutter 的本地倒数日应用，支持公历和农历日期，帮助你管理和追踪重要日期。

## 功能特性

- **公历 & 农历**：支持公历和农历日期创建倒数日，农历自动转换公历计算
- **实时倒计时**：全屏横屏沉浸式倒计时，秒级实时刷新，归零庆祝动效
- **卡片风格**：7 种预设卡片风格（简约/渐变/玻璃/阴影/深邃/手绘/节日），支持自定义背景、颜色、字体
- **分类管理**：预设 5 种分类（生日/纪念日/节日/工作/考试），支持自定义分类和颜色
- **提醒通知**：本地通知提醒，支持提前天数和时间设置
- **数据导入导出**：JSON 格式导入导出，支持重复检测
- **应用内更新**：自动检查 GitHub Releases，Android 支持 APK 下载安装
- **Material 3**：遵循 Material Design 3 规范，支持壁纸取色（Android 12+）

## 技术栈

| 技术 | 用途 |
|------|------|
| Flutter | 跨平台框架 |
| Riverpod | 状态管理 |
| SQLite (sqflite) | 本地数据库 |
| Material Design 3 | UI 设计规范 |
| GoRouter | 路由管理 |
| dio | APK 下载 |
| flutter_markdown | Release Notes 渲染 |

## 开发

```bash
# 安装依赖
flutter pub get

# 运行分析
flutter analyze

# 运行测试
flutter test

# 构建 APK
flutter build apk --release
```

## 项目结构

```
lib/
├── main.dart              # 应用入口
├── app.dart               # MaterialApp 配置
├── router.dart            # 路由配置
├── models/                # 数据模型
├── providers/             # Riverpod 状态管理
├── services/              # 业务逻辑
├── repositories/          # 数据访问层
├── screens/               # 页面
├── widgets/               # 可复用组件
└── themes/                # M3 主题配置
```

## License

MIT

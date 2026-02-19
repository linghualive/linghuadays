# DaysMater 开发规划文档

> 采用 TDD 模式迭代开发，每个 Sprint 聚焦一个功能模块。
> 每个任务遵循：编写测试 → 实现功能 → 重构 → 更新文档。

---

## Sprint 1：项目基础设施

> 搭建项目骨架、核心依赖和 Material 3 主题体系。

- [x] **1.1 初始化 Flutter 项目**
  - 创建 Flutter 项目，配置最低 SDK 版本（iOS 13+, Android API 24+）
  - 配置 `pubspec.yaml`，引入核心依赖：
    - `sqflite` / `sqflite_common_ffi`（本地数据库）
    - `flutter_riverpod`（状态管理）
    - `path_provider`（文件路径）
    - `flutter_local_notifications`（本地通知）
    - `lunar`（农历转换）
    - `google_fonts`（自定义字体）
    - `intl`（国际化/日期格式化）
  - 配置 `analysis_options.yaml`，启用严格 lint 规则
  - 测试：验证项目可正常编译运行

- [x] **1.2 Material 3 主题系统**
  - 创建 `ThemeConfig`，基于 `ColorScheme.fromSeed()` 生成浅色/深色主题
  - 定义 Typography token（displayLarge 用于倒数数字，titleMedium 用于事件名称等）
  - 实现主题模式切换（浅色 / 深色 / 跟随系统）
  - 持久化用户主题偏好
  - 测试：主题切换正确性、ColorScheme 生成准确性

- [x] **1.3 数据库基础设施**
  - 设计数据库 Schema（events 表、categories 表、styles 表）
  - 实现 `DatabaseHelper`：初始化、版本迁移、CRUD 基础方法
  - 测试：数据库创建、表结构验证、CRUD 操作

- [x] **1.4 项目目录结构**
  - 按 `CLAUDE.md` 中定义的结构创建目录和占位文件
  - 配置路由方案（GoRouter 或 Navigator 2.0）
  - 测试：路由跳转正确性

---

## Sprint 2：数据模型与日期计算引擎

> 实现核心数据模型和日期计算逻辑，这是所有功能的基础。

- [x] **2.1 Event 数据模型**
  - 定义 `Event` 模型类，包含字段：
    - id, name, targetDate, calendarType(solar/lunar),
    - lunarYear, lunarMonth, lunarDay, isLeapMonth,
    - categoryId, note, isRepeating, isPinned, isFocus,
    - styleId, createdAt, updatedAt
  - 实现 `toMap()` / `fromMap()` 序列化
  - 实现 `toJson()` / `fromJson()` 用于导入导出
  - 测试：序列化/反序列化正确性、字段校验

- [x] **2.2 Category 数据模型**
  - 定义 `Category` 模型类：id, name, colorValue, isPreset
  - 预设分类数据：生日、纪念日、节日、工作、考试
  - 实现序列化方法
  - 测试：预设分类完整性、序列化正确性

- [x] **2.3 CardStyle 数据模型**
  - 定义 `CardStyle` 模型类：
    - id, styleName, styleType(enum: simple/gradient/glass/shadow/neon/handdrawn/festival)
    - backgroundColor, gradientColors, backgroundImagePath
    - imageBlur, overlayOpacity
    - textColor, numberColor
    - fontFamily, cardBorderRadius
    - isPreset
  - 预设7种内置风格的默认参数
  - 测试：所有预设风格参数完整性、序列化

- [x] **2.4 公历日期计算服务**
  - 实现 `DateCalculationService`：
    - `daysUntil(targetDate)`：计算距目标日期的天数（正数=未来，负数=过去，0=今天）
    - `nextOccurrence(targetDate)`：计算每年重复事件的下一次日期
    - `timeUntil(targetDate)`：计算剩余的天/时/分/秒（用于实时倒计时）
  - 测试：跨年计算、闰年、当天、边界日期

- [x] **2.5 农历转换服务**
  - 实现 `LunarService`：
    - `lunarToSolar(year, month, day, isLeapMonth)`：农历转公历
    - `solarToLunar(date)`：公历转农历
    - `getLunarDateString(year, month, day)`：格式化农历日期文本（如"甲辰年腊月廿三"）
    - `nextLunarOccurrence(lunarMonth, lunarDay, isLeapMonth)`：计算农历重复事件的下一次公历日期
  - 测试：闰月转换、边界年份（1900/2100）、常见节日日期验证

---

## Sprint 3：数据访问层与状态管理

> 实现 Repository 层和 Riverpod 状态管理。

- [x] **3.1 EventRepository**
  - 实现事件的 CRUD 操作
  - 实现排序查询（按剩余天数 / 创建时间 / 名称）
  - 实现分类筛选查询
  - 实现搜索（按名称模糊匹配）
  - 实现置顶排序逻辑
  - 测试：所有查询场景、边界条件

- [x] **3.2 CategoryRepository**
  - 实现分类的 CRUD 操作
  - 删除分类时将关联事件的 categoryId 置为 null
  - 首次启动时初始化预设分类
  - 测试：级联更新、预设分类保护

- [x] **3.3 StyleRepository**
  - 实现卡片风格的 CRUD 操作
  - 首次启动时初始化预设风格
  - 测试：预设风格不可删除、自定义风格 CRUD

- [x] **3.4 Riverpod Providers**
  - `eventsProvider`：事件列表状态（支持排序/筛选/搜索参数）
  - `categoriesProvider`：分类列表状态
  - `stylesProvider`：风格列表状态
  - `themeProvider`：主题模式状态
  - `focusEventProvider`：焦点事件状态
  - 测试：状态变更、数据联动

---

## Sprint 4：首页与事件列表 UI

> 实现主界面，包括焦点事件区域和列表展示。

- [x] **4.1 首页框架**
  - 实现 `HomeScreen`，M3 Scaffold 结构
  - 顶部焦点事件卡片区域（应用事件自定义风格）
  - 底部事件列表区域
  - FAB 按钮用于创建新事件
  - 测试：页面渲染、焦点事件展示

- [x] **4.2 事件卡片组件**
  - 实现 `EventCard` Widget，根据事件绑定的 `CardStyle` 渲染不同视觉风格
  - 卡片显示：事件名称、分类色标、剩余/已过天数、目标日期
  - 农历事件同时显示农历和公历日期
  - 应用自定义字体到数字和标题
  - 测试：7种预设风格渲染正确性、农历/公历显示、字体应用

- [x] **4.3 列表排序与筛选**
  - 排序切换 UI（M3 SegmentedButton 或 DropdownMenu）
  - 分类筛选 UI（M3 FilterChip）
  - 列表下拉刷新
  - 测试：排序结果正确性、筛选联动

- [x] **4.4 搜索功能**
  - M3 SearchBar 组件
  - 实时搜索，输入防抖
  - 搜索结果高亮
  - 测试：搜索匹配、空结果处理

- [x] **4.5 列表批量操作**
  - 长按进入多选模式
  - 多选状态下的操作栏：批量删除
  - 测试：多选状态切换、批量删除确认

---

## Sprint 5：创建与编辑事件

> 实现事件的创建和编辑表单，包含日历选择和风格选择。

- [x] **5.1 创建/编辑表单页面**
  - 底部弹出的 BottomSheet 表单
  - 表单字段：事件名称、日历类型切换、目标日期、分类、备注、是否重复
  - M3 表单组件：TextField、Switch、ChoiceChip
  - 表单校验逻辑
  - 测试：字段校验、必填项验证

- [x] **5.2 公历日期选择器**
  - M3 DatePicker 或自定义滚轮选择器
  - 日期范围限制 1900-2100
  - 测试：日期选择、边界值

- [x] **5.3 农历日期选择器**
  - 自定义三列滚轮选择器（年/月/日）
  - 年份显示天干地支（如"甲辰年"）
  - 月份显示农历月名（正月~十二月），存在闰月时额外显示
  - 日期显示农历日名（初一~三十）
  - 月份和日期联动（不同月份天数不同）
  - 选中后显示对应公历日期
  - 测试：闰月显示、月日联动、转换结果

- [x] **5.4 风格选择器**
  - 风格选择区域，展示所有可用风格的预览缩略图
  - 点击选择后实时预览卡片效果（使用当前填写的事件名称和日期）
  - 支持进入自定义编辑：背景色/渐变/图片、文字颜色、字体、圆角
  - 图片选择支持从相册选取，可调节模糊度和遮罩透明度
  - 测试：风格切换预览、自定义参数持久化

- [x] **5.5 分类选择与管理**
  - 表单中的分类选择器（M3 ChoiceChip 列表）
  - 内联"添加分类"入口，弹窗创建新分类（名称+颜色）
  - 测试：分类选择、新建分类

---

## Sprint 6：事件详情与实时倒计时

> 实现事件详情页和全屏实时倒计时。

- [x] **6.1 事件详情页**
  - 已过期事件点击进入详情页
  - 显示完整事件信息：名称、日期、分类、备注、已过天数
  - 编辑和删除操作入口
  - 测试：详情展示完整性

- [x] **6.2 实时倒计时页面**
  - 强制横屏全屏沉浸模式
  - 大号数字显示：XX天 XX时 XX分 XX秒，秒级实时刷新
  - 根据剩余时间自动隐藏高位单位
  - 使用事件绑定的自定义字体渲染数字
  - 深色背景，分类颜色作为点缀色
  - 测试：倒计时计算精度、单位自动隐藏逻辑

- [x] **6.3 倒计时页面交互**
  - 点击切换顶部信息栏显隐
  - 返回按钮和右滑手势退出
  - 屏幕常亮（WakeLock）
  - 测试：手势响应、屏幕锁逻辑

- [x] **6.4 倒计时归零动效**
  - 归零时触发庆祝动画（撒花/烟花粒子效果）
  - 文案切换为"时刻已到"
  - 测试：归零触发准确性

---

## Sprint 7：提醒通知系统

> 实现本地通知提醒功能。

- [x] **7.1 通知权限与初始化**
  - iOS / Android 通知权限请求
  - 初始化 `flutter_local_notifications`
  - 测试：权限请求流程

- [x] **7.2 提醒设置 UI**
  - 创建/编辑表单中增加提醒设置区域
  - 提前天数选择：当天、1天、3天、7天、14天、30天
  - 提醒时间选择：TimePicker
  - 测试：设置持久化、UI 交互

- [x] **7.3 通知调度**
  - 根据提醒设置计算通知触发时间
  - 使用 `zonedSchedule` 调度本地通知
  - 每年重复事件：每年重新调度下一次通知
  - 编辑/删除事件时同步取消或更新通知
  - 测试：触发时间计算、重复调度逻辑

---

## Sprint 8：分类管理与数据导入导出

> 完善分类管理页面和数据导入导出功能。

- [x] **8.1 分类管理页面**
  - 独立的分类管理页面（设置入口）
  - 分类列表：显示名称、颜色、关联事件数
  - 新建/编辑分类：名称 + 颜色选择器
  - 删除分类：二次确认，关联事件变为"未分类"
  - 预设分类不可删除，仅可编辑颜色
  - 测试：CRUD 操作、级联逻辑

- [x] **8.2 数据导出**
  - 设置页中"导出数据"入口
  - 将所有事件、分类、自定义风格序列化为 JSON
  - 调用系统分享/保存接口导出文件
  - 测试：JSON 结构完整性、特殊字符处理

- [ ] **8.3 数据导入**
  - 设置页中"导入数据"入口
  - 从文件选择器选取 JSON 文件
  - 解析并校验 JSON 格式
  - 检测重复事件（按名称+日期匹配），提示覆盖或跳过
  - 测试：格式校验、重复检测、异常文件处理

---

## Sprint 9：设置页面与收尾优化

> 实现设置页面，完成全局打磨。

- [x] **9.1 设置页面**
  - 主题模式切换（浅色/深色/跟随系统）
  - 数据管理入口（导入/导出）
  - 分类管理入口
  - 关于页面（版本号、开源许可）
  - 测试：设置项持久化

- [x] **9.2 长按快捷菜单**
  - 列表项长按弹出 M3 ModalBottomSheet 菜单
  - 菜单项：编辑、删除、置顶/取消置顶、设为焦点
  - 测试：菜单操作联动

- [x] **9.3 空状态与引导**
  - 列表为空时显示引导插画和"创建第一个倒数日"按钮
  - 搜索无结果时的空状态提示
  - 测试：空状态展示条件

- [ ] **9.4 性能与体验优化**
  - 列表 `ListView.builder` 懒加载
  - 数据库查询优化（索引）
  - 首屏加载骨架屏
  - 页面转场动画（M3 motion 规范）
  - 测试：1000 条数据下的列表滚动流畅性

- [ ] **9.5 国际化基础**
  - 配置 `flutter_localizations`
  - 提取所有硬编码字符串到 ARB 文件
  - 首期仅提供中文（简体），预留英文扩展
  - 测试：中文显示完整性

---

## 迭代进度追踪

| Sprint | 模块 | 状态 | 备注 |
|--------|------|------|------|
| 1 | 项目基础设施 | 已完成 | Flutter 3.35.4, M3 主题, SQLite, GoRouter, 65 tests passed |
| 2 | 数据模型与日期引擎 | 已完成 | Event/Category/CardStyle 模型, 公历计算, 农历转换 |
| 3 | 数据访问与状态管理 | 已完成 | 3 Repository + 5 Providers, 全部测试通过 |
| 4 | 首页与事件列表 UI | 已完成 | 首页、7种卡片风格、排序筛选搜索、批量操作 |
| 5 | 创建与编辑事件 | 已完成 | 公历/农历选择器、风格选择器、分类内联创建 |
| 6 | 事件详情与实时倒计时 | 已完成 | 横屏全屏倒计时、秒级刷新、归零提示、屏幕常亮 |
| 7 | 提醒通知系统 | 已完成 | NotificationService, 提醒UI, zonedSchedule调度, 12 tests |
| 8 | 分类管理与数据导入导出 | 进行中 | 分类管理和导出已完成，导入待实现 |
| 9 | 设置页面与收尾优化 | 进行中 | 设置页、快捷菜单、空状态已完成 |

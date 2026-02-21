import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/card_style.dart';
import '../models/event.dart';
import '../providers/category_provider.dart';
import '../providers/event_provider.dart';
import '../providers/style_provider.dart';
import '../providers/database_provider.dart';
import '../services/date_calculation_service.dart';
import '../services/lunar_service.dart';
import '../services/widget_service.dart';
import 'package:home_widget/home_widget.dart';

// ---- 字体预设 ----

class FontPreset {
  final String name;
  final String key;
  final TextStyle Function(TextStyle) apply;

  const FontPreset({
    required this.name,
    required this.key,
    required this.apply,
  });
}

final List<FontPreset> fontPresets = [
  FontPreset(name: '默认', key: 'default', apply: (s) => s),
  FontPreset(name: '手写', key: 'Caveat', apply: (s) => GoogleFonts.caveat(textStyle: s)),
  FontPreset(name: '花体', key: 'DancingScript', apply: (s) => GoogleFonts.dancingScript(textStyle: s)),
  FontPreset(name: '圆趣', key: 'ZCOOLQingKeHuangYou', apply: (s) => GoogleFonts.zcoolQingKeHuangYou(textStyle: s)),
  FontPreset(name: '快乐', key: 'ZCOOLKuaiLe', apply: (s) => GoogleFonts.zcoolKuaiLe(textStyle: s)),
  FontPreset(name: '书法', key: 'MaShanZheng', apply: (s) => GoogleFonts.maShanZheng(textStyle: s)),
  FontPreset(name: '行草', key: 'LiuJianMaoCao', apply: (s) => GoogleFonts.liuJianMaoCao(textStyle: s)),
  FontPreset(name: '龙藏', key: 'LongCang', apply: (s) => GoogleFonts.longCang(textStyle: s)),
  FontPreset(name: '复古', key: 'PlayfairDisplay', apply: (s) => GoogleFonts.playfairDisplay(textStyle: s.copyWith(fontStyle: FontStyle.italic))),
  FontPreset(name: '像素', key: 'PressStart2P', apply: (s) => GoogleFonts.pressStart2p(textStyle: s.copyWith(fontSize: (s.fontSize ?? 96) * 0.5))),
];

// ---- 详情页主体 ----

class EventDetailScreen extends ConsumerStatefulWidget {
  final Event event;

  const EventDetailScreen({super.key, required this.event});

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  final _cardKey = GlobalKey();
  int? _selectedStyleId;
  int _selectedFontIndex = 0;
  int _displayMode = 0; // 0=天, 1=年月天, 2=月天, 3=周天
  late Event _event;

  @override
  void initState() {
    super.initState();
    _event = widget.event;
    _selectedStyleId = _event.styleId;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final styles = ref.watch(stylesProvider).valueOrNull ?? [];
    final category = _event.categoryId != null
        ? categories.where((c) => c.id == _event.categoryId).firstOrNull
        : null;

    final calcService = DateCalculationService();
    final effectiveDate = _getEffectiveDate(_event, calcService);
    final days = calcService.daysUntil(effectiveDate);

    final font = fontPresets[_selectedFontIndex];

    // 查找当前事件的样式，找不到则用第一个预设
    final style = _findCurrentStyle(styles);

    // 用分类色覆盖默认 header 色（仅在无自定义样式时）
    final headerColor = (_selectedStyleId == null && category != null)
        ? category.color
        : Color(style.headerColor);

    // 页面背景：取样式 headerColor 的极淡色调
    final pageBg = _pageBackgroundColor(style);

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        backgroundColor: pageBg,
        title: const Text('玲华倒数'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              await context.pushNamed('editEvent', extra: _event);
              if (!mounted) return;
              final repo = ref.read(eventRepositoryProvider);
              final updated = await repo.getById(_event.id!);
              if (updated != null && mounted) {
                setState(() {
                  _event = updated;
                  _selectedStyleId = updated.styleId;
                });
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: RepaintBoundary(
                  key: _cardKey,
                  child: _buildCard(
                    theme, style, font, headerColor, days, effectiveDate,
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.palette_outlined,
                    label: '样式',
                    onPressed: () => _showStylePicker(context, styles),
                  ),
                  _ActionButton(
                    icon: Icons.text_fields,
                    label: '字体',
                    onPressed: () => _showFontPicker(context),
                  ),
                  _ActionButton(
                    icon: Icons.save_alt,
                    label: '存图',
                    onPressed: () => _exportAsImage(context, styles),
                  ),
                  if (days > 0)
                    _ActionButton(
                      icon: Icons.timer_outlined,
                      label: '倒计时',
                      onPressed: () =>
                          context.pushNamed('countdown', extra: _event),
                    ),
                  if (Platform.isAndroid)
                    _ActionButton(
                      icon: Icons.widgets_outlined,
                      label: '桌面',
                      onPressed: () => _addToWidget(),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  CardStyle _findCurrentStyle(List<CardStyle> styles) {
    if (_selectedStyleId != null) {
      final match = styles.where((s) => s.id == _selectedStyleId).firstOrNull;
      if (match != null) return match;
    }
    // 默认用第一个预设
    if (styles.isNotEmpty) {
      return styles.firstWhere((s) => s.isPreset, orElse: () => styles.first);
    }
    return CardStyle.presets.first;
  }

  Widget _buildCard(
    ThemeData theme,
    CardStyle style,
    FontPreset font,
    Color headerColor,
    int days,
    DateTime effectiveDate,
  ) {
    final hasGradient = style.gradientColors != null &&
        style.gradientColors!.length >= 2;
    final hasImage = style.backgroundImagePath != null &&
        style.backgroundImagePath!.isNotEmpty;
    final bgDecoration = BoxDecoration(
      color: hasGradient ? null : Color(style.backgroundColor),
      gradient: hasGradient
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: style.gradientColors!.map((c) => Color(c)).toList(),
            )
          : null,
      borderRadius: BorderRadius.circular(style.cardBorderRadius),
    );

    final numberStyle = font.apply(
      TextStyle(
        fontSize: 96,
        fontWeight: FontWeight.bold,
        height: 1,
        color: Color(style.numberColor),
      ),
    );

    final dateColor = Color(style.textColor).withValues(alpha: 0.7);

    return Container(
      decoration: bgDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 彩色标题栏（不受图片背景影响）
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: headerColor,
            child: Text(
              days == 0
                  ? '${_event.name}就是今天'
                  : days > 0
                      ? '距离${_event.name}还有'
                      : '${_event.name}已经',
              style: theme.textTheme.titleMedium?.copyWith(
                color: _contrastTextColor(headerColor),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // 内容区域（图片背景只覆盖这里）
          Stack(
            children: [
              if (hasImage)
                Positioned.fill(
                  child: _buildImageBackground(style),
                ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 大号天数（点击切换显示模式）
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _displayMode = (_displayMode + 1) % 4;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 36),
                      child: _buildDaysDisplay(
                        days, effectiveDate, numberStyle, font, style,
                      ),
                    ),
                  ),
                  // 虚线分隔
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: CustomPaint(
                      size: const Size(double.infinity, 1),
                      painter: _DashedLinePainter(
                        color: dateColor.withValues(alpha: 0.4),
                      ),
                    ),
                  ),
                  // 目标/起始日期
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Text(
                      '${_event.isRepeating ? "目标日" : "起始日"}: ${_formatTargetDate(effectiveDate)}',
                      style: theme.textTheme.bodyMedium?.copyWith(color: dateColor),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDaysDisplay(
    int days,
    DateTime effectiveDate,
    TextStyle numberStyle,
    FontPreset font,
    CardStyle style,
  ) {
    final calcService = DateCalculationService();
    final today = DateTime.now();
    final unitStyle = font.apply(
      TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: Color(style.numberColor).withAlpha(180),
      ),
    );
    final multiNumberStyle = font.apply(
      TextStyle(
        fontSize: 56,
        fontWeight: FontWeight.bold,
        height: 1,
        color: Color(style.numberColor),
      ),
    );

    switch (_displayMode) {
      case 0:
        // 默认：天数
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('${days.abs()}', style: numberStyle),
            const SizedBox(width: 4),
            Text('天', style: unitStyle.copyWith(fontSize: 32)),
          ],
        );
      case 1:
        // 年月天
        final result = calcService.yearsMonthsDaysBetween(today, effectiveDate);
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('${result.years}', style: multiNumberStyle),
            Text('年', style: unitStyle),
            const SizedBox(width: 8),
            Text('${result.months}', style: multiNumberStyle),
            Text('月', style: unitStyle),
            const SizedBox(width: 8),
            Text('${result.days}', style: multiNumberStyle),
            Text('天', style: unitStyle),
          ],
        );
      case 2:
        // 月天
        final result = calcService.monthsDaysBetween(today, effectiveDate);
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('${result.months}', style: multiNumberStyle),
            Text('月', style: unitStyle),
            const SizedBox(width: 12),
            Text('${result.days}', style: multiNumberStyle),
            Text('天', style: unitStyle),
          ],
        );
      case 3:
        // 周天
        final result = calcService.weeksDaysBetween(days);
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text('${result.weeks}', style: multiNumberStyle),
            Text('周', style: unitStyle),
            const SizedBox(width: 12),
            Text('${result.days}', style: multiNumberStyle),
            Text('天', style: unitStyle),
          ],
        );
      default:
        return Text('${days.abs()}', style: numberStyle);
    }
  }

  Widget _buildImageBackground(CardStyle style) {
    final file = File(style.backgroundImagePath!);
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
        Container(
          color: Colors.black.withValues(
            alpha: style.overlayOpacity,
          ),
        ),
      ],
    );
  }

  /// 根据背景色亮度选择对比文字色
  Color _contrastTextColor(Color bg) {
    return bg.computeLuminance() > 0.5
        ? const Color(0xFF212121)
        : const Color(0xFFFFFFFF);
  }

  // ---- 桌面小组件 ----

  Future<void> _addToWidget() async {
    await WidgetService().updateWidget(_event);
    try {
      await HomeWidget.requestPinWidget(
        androidName: 'CountdownWidgetProvider',
        qualifiedAndroidName: 'com.daysmater.daysmater.CountdownWidgetProvider',
      );
    } catch (_) {
      // 部分设备不支持 requestPinWidget
    }
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加桌面小组件'),
        content: Text(
          '已将「${_event.name}」设为小组件展示内容。\n\n'
          '如果桌面未自动弹出确认，请手动添加：\n'
          '长按桌面空白处 → 小组件 → 找到「玲华倒数」拖到桌面',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('知道了'),
          ),
        ],
      ),
    );
  }

  // ---- 样式选择 ----

  void _showStylePicker(BuildContext context, List<CardStyle> styles) {
    final presets = styles.where((s) => s.isPreset).toList();
    final currentStyle = _findCurrentStyle(styles);
    final hasImageStyle = currentStyle.backgroundImagePath != null;

    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('选择样式', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: presets.length + 1,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    // 最后一个是「图片」按钮
                    if (i == presets.length) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.pop(ctx);
                          if (hasImageStyle) {
                            _showImageStyleMenu(currentStyle);
                          } else {
                            _pickImageStyle();
                          }
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: hasImageStyle
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.outlineVariant,
                                  width: hasImageStyle ? 3 : 1,
                                ),
                                image: hasImageStyle
                                    ? DecorationImage(
                                        image: FileImage(
                                          File(currentStyle.backgroundImagePath!),
                                        ),
                                        fit: BoxFit.cover,
                                      )
                                    : null,
                              ),
                              child: hasImageStyle
                                  ? null
                                  : Icon(
                                      Icons.add_photo_alternate_outlined,
                                      size: 22,
                                      color: Theme.of(context).colorScheme.outline,
                                    ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '图片',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: hasImageStyle
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                                fontWeight: hasImageStyle ? FontWeight.bold : null,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final s = presets[i];
                    final selected = s.id == currentStyle.id;
                    final hasGradient = s.gradientColors != null &&
                        s.gradientColors!.length >= 2;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _updateEventStyle(s.id!);
                        Navigator.pop(ctx);
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: hasGradient
                                  ? LinearGradient(
                                      colors: s.gradientColors!
                                          .map((c) => Color(c))
                                          .toList())
                                  : null,
                              color: hasGradient
                                  ? null
                                  : Color(s.backgroundColor),
                              shape: BoxShape.circle,
                              border: selected
                                  ? Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary,
                                      width: 3)
                                  : Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                      width: 1),
                            ),
                            child: Center(
                              child: Container(
                                width: 20,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Color(s.headerColor),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.styleName,
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: selected
                                  ? Theme.of(context).colorScheme.primary
                                  : null,
                              fontWeight:
                                  selected ? FontWeight.bold : null,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- 图片背景 ----

  void _showImageStyleMenu(CardStyle currentStyle) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('更换图片'),
              onTap: () {
                Navigator.pop(ctx);
                _pickImageStyle();
              },
            ),
            ListTile(
              leading: Icon(
                Icons.delete_outline,
                color: Theme.of(context).colorScheme.error,
              ),
              title: Text(
                '移除图片背景',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _removeImageStyle(currentStyle);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeImageStyle(CardStyle imageStyle) async {
    // 切换到第一个预设样式
    final styles = ref.read(stylesProvider).valueOrNull ?? [];
    final firstPreset = styles.firstWhere(
      (s) => s.isPreset,
      orElse: () => styles.first,
    );
    _updateEventStyle(firstPreset.id!);

    // 删除自定义图片样式及对应文件
    if (imageStyle.id != null) {
      await ref.read(stylesProvider.notifier).deleteStyle(imageStyle.id!);
    }
    if (imageStyle.backgroundImagePath != null) {
      final file = File(imageStyle.backgroundImagePath!);
      if (file.existsSync()) file.deleteSync();
    }
  }

  Future<void> _pickImageStyle() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) return;

    // 复制到应用目录持久化
    final appDir = await getApplicationDocumentsDirectory();
    final bgDir = Directory('${appDir.path}/style_backgrounds');
    if (!bgDir.existsSync()) bgDir.createSync(recursive: true);
    final ext = p.extension(picked.path);
    final savedPath =
        '${bgDir.path}/bg_${_event.id}_${DateTime.now().millisecondsSinceEpoch}$ext';
    await File(picked.path).copy(savedPath);

    // 沿用当前样式的标题颜色
    final styles = ref.read(stylesProvider).valueOrNull ?? [];
    final currentStyle = _findCurrentStyle(styles);

    final customStyle = CardStyle(
      styleName: '自定义图片',
      styleType: StyleType.custom,
      backgroundColor: 0xFF1A1A1A,
      textColor: 0xFFFFFFFF,
      numberColor: 0xFFFFFFFF,
      headerColor: currentStyle.headerColor,
      backgroundImagePath: savedPath,
      overlayOpacity: 0.3,
    );

    final styleRepo = ref.read(stylesProvider.notifier);
    final styleId = await styleRepo.addStyle(customStyle);
    ref.invalidate(stylesProvider);
    _updateEventStyle(styleId);
  }

  void _updateEventStyle(int styleId) {
    final updated = _event.copyWith(
      styleId: () => styleId,
      updatedAt: DateTime.now(),
    );
    setState(() {
      _selectedStyleId = styleId;
      _event = updated;
    });
    ref.read(eventsProvider.notifier).updateEvent(updated);
  }

  // ---- 字体选择 ----

  void _showFontPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('选择字体', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(fontPresets.length, (i) {
                  final f = fontPresets[i];
                  final selected = i == _selectedFontIndex;
                  return ChoiceChip(
                    label: Text(f.name),
                    selected: selected,
                    onSelected: (_) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedFontIndex = i);
                      Navigator.pop(ctx);
                    },
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---- 导出为图片 ----

  Future<void> _exportAsImage(BuildContext context, List<CardStyle> styles) async {
    final style = _findCurrentStyle(styles);
    final font = fontPresets[_selectedFontIndex];
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final category = _event.categoryId != null
        ? categories.where((c) => c.id == _event.categoryId).firstOrNull
        : null;
    final calcService = DateCalculationService();
    final effectiveDate = _getEffectiveDate(_event, calcService);
    final days = calcService.daysUntil(effectiveDate);
    final headerColor = (_selectedStyleId == null && category != null)
        ? category.color
        : Color(style.headerColor);

    final exportKey = GlobalKey();
    final bgColor = _exportBackgroundColor(style);

    final exportWidget = MediaQuery(
      data: MediaQuery.of(context),
      child: Theme(
        data: Theme.of(context),
        child: RepaintBoundary(
          key: exportKey,
          child: Container(
            width: 400,
            color: bgColor,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 48),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '玲华倒数',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _isLightBackground(bgColor)
                        ? const Color(0xFF757575)
                        : const Color(0xFFBDBDBD),
                  ),
                ),
                const SizedBox(height: 24),
                _buildCard(
                  Theme.of(context), style, font, headerColor,
                  days, effectiveDate,
                ),
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: _isLightBackground(bgColor)
                          ? headerColor.withValues(alpha: 0.7)
                          : headerColor.withValues(alpha: 0.8),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '玲华倒数 · LingHua Days',
                      style: TextStyle(
                        fontSize: 12,
                        color: _isLightBackground(bgColor)
                            ? headerColor.withValues(alpha: 0.7)
                            : headerColor.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        left: -1000,
        top: -1000,
        child: exportWidget,
      ),
    );
    overlay.insert(entry);

    try {
      await Future.delayed(const Duration(milliseconds: 200));

      final boundary = exportKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;
      if (boundary == null) {
        entry.remove();
        return;
      }

      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      entry.remove();
      if (byteData == null) return;

      final dir = await getTemporaryDirectory();
      final file = File(
        '${dir.path}/linghua_countdown_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await file.writeAsBytes(byteData.buffer.asUint8List());

      if (!context.mounted) return;

      await Share.shareXFiles([XFile(file.path)]);
    } catch (e) {
      entry.remove();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('导出失败，请重试')),
        );
      }
    }
  }

  /// 详情页背景：取样式 headerColor 的极淡色调，营造氛围感
  Color _pageBackgroundColor(CardStyle style) {
    // 图片背景样式 → 使用主题默认背景色
    if (style.backgroundImagePath != null &&
        style.backgroundImagePath!.isNotEmpty) {
      return Theme.of(context).colorScheme.surface;
    }

    final hsl = HSLColor.fromColor(Color(style.headerColor));
    if (_isLightBackground(Color(style.backgroundColor))) {
      // 浅色卡片 → 柔和但可辨识的 headerColor 色调
      return hsl.withSaturation((hsl.saturation * 0.5).clamp(0.0, 1.0))
          .withLightness(0.90)
          .toColor();
    }
    // 深色卡片 → 深色背景
    return hsl.withSaturation((hsl.saturation * 0.3).clamp(0.0, 1.0))
        .withLightness(0.15)
        .toColor();
  }

  Color _exportBackgroundColor(CardStyle style) {
    final base = Color(style.backgroundColor);
    if (_isLightBackground(base)) {
      return const Color(0xFFF5F5F5);
    }
    return HSLColor.fromColor(base).withLightness(0.08).toColor();
  }

  bool _isLightBackground(Color color) {
    return color.computeLuminance() > 0.4;
  }

  // ---- 日期格式化 ----

  String _formatTargetDate(DateTime displayDate) {
    if (_event.calendarType == 'lunar' &&
        _event.lunarYear != null &&
        _event.lunarMonth != null &&
        _event.lunarDay != null) {
      final lunarStr = LunarService().getLunarDateString(
        _event.lunarYear!,
        _event.lunarMonth!,
        _event.lunarDay!,
        isLeapMonth: _event.isLeapMonth,
      );
      final solarStr = DateFormat('yyyy-MM-dd').format(displayDate);
      return '$lunarStr ($solarStr)';
    }
    return DateFormat('yyyy-MM-dd').format(displayDate);
  }

  static DateTime _getEffectiveDate(
    Event event,
    DateCalculationService calcService,
  ) {
    if (!event.isRepeating) return event.targetDate;
    if (event.calendarType == 'lunar' &&
        event.lunarMonth != null &&
        event.lunarDay != null) {
      return LunarService().nextLunarOccurrence(
        event.lunarMonth!,
        event.lunarDay!,
        isLeapMonth: event.isLeapMonth,
      );
    }
    return calcService.nextOccurrence(event.targetDate);
  }
}

// ---- 操作按钮 ----

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}

// ---- 虚线绘制 ----

class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    var startX = 0.0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

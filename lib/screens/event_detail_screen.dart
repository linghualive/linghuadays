import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../models/event.dart';
import '../providers/category_provider.dart';
import '../services/date_calculation_service.dart';
import '../services/lunar_service.dart';

// ---- 详情页卡片样式预设 ----

class DetailCardStyle {
  final String name;
  final List<Color> backgroundColors; // 1=纯色, 2+=渐变
  final Color headerColor;
  final Color numberColor;
  final Color textColor;
  final Color dateColor;

  const DetailCardStyle({
    required this.name,
    required this.backgroundColors,
    required this.headerColor,
    required this.numberColor,
    required this.textColor,
    required this.dateColor,
  });

  static const List<DetailCardStyle> presets = [
    DetailCardStyle(
      name: '经典蓝',
      backgroundColors: [Color(0xFFFFFFFF)],
      headerColor: Color(0xFF4A7FBF),
      numberColor: Color(0xFF212121),
      textColor: Color(0xFFFFFFFF),
      dateColor: Color(0xFF757575),
    ),
    DetailCardStyle(
      name: '薄暮粉',
      backgroundColors: [Color(0xFFFFF0F5)],
      headerColor: Color(0xFFE91E63),
      numberColor: Color(0xFFC2185B),
      textColor: Color(0xFFFFFFFF),
      dateColor: Color(0xFF880E4F),
    ),
    DetailCardStyle(
      name: '森林绿',
      backgroundColors: [Color(0xFFF1F8E9)],
      headerColor: Color(0xFF388E3C),
      numberColor: Color(0xFF2E7D32),
      textColor: Color(0xFFFFFFFF),
      dateColor: Color(0xFF558B2F),
    ),
    DetailCardStyle(
      name: '暖阳橘',
      backgroundColors: [Color(0xFFFFF3E0)],
      headerColor: Color(0xFFE65100),
      numberColor: Color(0xFFBF360C),
      textColor: Color(0xFFFFFFFF),
      dateColor: Color(0xFF8D6E63),
    ),
    DetailCardStyle(
      name: '深邃紫',
      backgroundColors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
      headerColor: Color(0xFF7C4DFF),
      numberColor: Color(0xFFB388FF),
      textColor: Color(0xFFEDE7F6),
      dateColor: Color(0xFF9E9E9E),
    ),
    DetailCardStyle(
      name: '星空黑',
      backgroundColors: [Color(0xFF0D0D0D)],
      headerColor: Color(0xFF212121),
      numberColor: Color(0xFF00E5FF),
      textColor: Color(0xFFE0E0E0),
      dateColor: Color(0xFF757575),
    ),
    DetailCardStyle(
      name: '落日渐变',
      backgroundColors: [Color(0xFFFF6F61), Color(0xFFFFB74D)],
      headerColor: Color(0xCCBF360C),
      numberColor: Color(0xFFFFFFFF),
      textColor: Color(0xFFFFFFFF),
      dateColor: Color(0xFFFFF8E1),
    ),
    DetailCardStyle(
      name: '海洋渐变',
      backgroundColors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
      headerColor: Color(0xCC01579B),
      numberColor: Color(0xFFFFFFFF),
      textColor: Color(0xFFFFFFFF),
      dateColor: Color(0xFFE0F7FA),
    ),
    DetailCardStyle(
      name: '薰衣草',
      backgroundColors: [Color(0xFFE8DEF8), Color(0xFFD0BCFF)],
      headerColor: Color(0xFF6750A4),
      numberColor: Color(0xFF4A148C),
      textColor: Color(0xFFFFFFFF),
      dateColor: Color(0xFF4A148C),
    ),
    DetailCardStyle(
      name: '中国红',
      backgroundColors: [Color(0xFFB71C1C), Color(0xFFD32F2F)],
      headerColor: Color(0xCC7F0000),
      numberColor: Color(0xFFFFD54F),
      textColor: Color(0xFFFFD54F),
      dateColor: Color(0xFFFFCDD2),
    ),
    DetailCardStyle(
      name: '抹茶',
      backgroundColors: [Color(0xFFF9FBE7)],
      headerColor: Color(0xFF689F38),
      numberColor: Color(0xFF33691E),
      textColor: Color(0xFFFFFFFF),
      dateColor: Color(0xFF827717),
    ),
    DetailCardStyle(
      name: '莫兰迪灰',
      backgroundColors: [Color(0xFFECEFF1)],
      headerColor: Color(0xFF78909C),
      numberColor: Color(0xFF37474F),
      textColor: Color(0xFFFFFFFF),
      dateColor: Color(0xFF546E7A),
    ),
    DetailCardStyle(
      name: '手绘暖黄',
      backgroundColors: [Color(0xFFFFF8E1)],
      headerColor: Color(0xFF8D6E63),
      numberColor: Color(0xFF3E2723),
      textColor: Color(0xFFFFF8E1),
      dateColor: Color(0xFF5D4037),
    ),
    DetailCardStyle(
      name: '极光',
      backgroundColors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
      headerColor: Color(0xCC0F2027),
      numberColor: Color(0xFF80CBC4),
      textColor: Color(0xFFB2DFDB),
      dateColor: Color(0xFF80CBC4),
    ),
  ];
}

// ---- 字体预设 ----

class FontPreset {
  final String name;
  final String key; // 存储标识
  final TextStyle Function(TextStyle) apply;

  const FontPreset({
    required this.name,
    required this.key,
    required this.apply,
  });
}

final List<FontPreset> fontPresets = [
  FontPreset(name: '默认', key: 'default', apply: (s) => s),
  FontPreset(name: '等宽', key: 'RobotoMono', apply: (s) => GoogleFonts.robotoMono(textStyle: s)),
  FontPreset(name: '圆体', key: 'ZenMaruGothic', apply: (s) => GoogleFonts.zenMaruGothic(textStyle: s)),
  FontPreset(name: '书法', key: 'MaShanZheng', apply: (s) => GoogleFonts.maShanZheng(textStyle: s)),
  FontPreset(name: '宋体', key: 'NotoSerifSC', apply: (s) => GoogleFonts.notoSerifSc(textStyle: s)),
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
  int _selectedStyleIndex = 0;
  int _selectedFontIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final category = widget.event.categoryId != null
        ? categories.where((c) => c.id == widget.event.categoryId).firstOrNull
        : null;

    final calcService = DateCalculationService();
    final effectiveDate = _getEffectiveDate(widget.event, calcService);
    final days = calcService.daysUntil(effectiveDate);

    final style = DetailCardStyle.presets[_selectedStyleIndex];
    final font = fontPresets[_selectedFontIndex];

    // 用分类色覆盖默认 header 色（仅在第一个样式时）
    final headerColor = (_selectedStyleIndex == 0 && category != null)
        ? category.color
        : style.headerColor;

    return Scaffold(
      appBar: AppBar(
        title: const Text('玲华倒数'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => context.pushNamed('editEvent', extra: widget.event),
          ),
        ],
      ),
      body: Column(
        children: [
          // 卡片区域（居中展示）
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
          // 底部操作栏
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionButton(
                    icon: Icons.palette_outlined,
                    label: '样式',
                    onPressed: () => _showStylePicker(context),
                  ),
                  _ActionButton(
                    icon: Icons.text_fields,
                    label: '字体',
                    onPressed: () => _showFontPicker(context),
                  ),
                  _ActionButton(
                    icon: Icons.save_alt,
                    label: '存图',
                    onPressed: () => _exportAsImage(context),
                  ),
                  if (days > 0)
                    _ActionButton(
                      icon: Icons.timer_outlined,
                      label: '倒计时',
                      onPressed: () =>
                          context.pushNamed('countdown', extra: widget.event),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(
    ThemeData theme,
    DetailCardStyle style,
    FontPreset font,
    Color headerColor,
    int days,
    DateTime effectiveDate,
  ) {
    final hasGradient = style.backgroundColors.length > 1;
    final bgDecoration = BoxDecoration(
      color: hasGradient ? null : style.backgroundColors.first,
      gradient: hasGradient
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: style.backgroundColors,
            )
          : null,
      borderRadius: BorderRadius.circular(16),
    );

    final numberStyle = font.apply(
      TextStyle(
        fontSize: 96,
        fontWeight: FontWeight.bold,
        height: 1,
        color: style.numberColor,
      ),
    );

    return Container(
      decoration: bgDecoration,
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 彩色标题栏
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            color: headerColor,
            child: Text(
              '${widget.event.name}${days >= 0 ? "还有" : "已过"}',
              style: theme.textTheme.titleMedium?.copyWith(
                color: style.textColor,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // 大号天数
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Text('${days.abs()}', style: numberStyle),
          ),
          // 虚线分隔
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: CustomPaint(
              size: const Size(double.infinity, 1),
              painter: _DashedLinePainter(
                color: style.dateColor.withValues(alpha: 0.4),
              ),
            ),
          ),
          // 目标日期
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Text(
              '目标日: ${_formatTargetDate(effectiveDate)}',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: style.dateColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---- 样式选择 ----

  void _showStylePicker(BuildContext context) {
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
                  itemCount: DetailCardStyle.presets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (_, i) {
                    final s = DetailCardStyle.presets[i];
                    final selected = i == _selectedStyleIndex;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedStyleIndex = i);
                        Navigator.pop(ctx);
                      },
                      child: Column(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: s.backgroundColors.length > 1
                                  ? LinearGradient(
                                      colors: s.backgroundColors)
                                  : null,
                              color: s.backgroundColors.length == 1
                                  ? s.backgroundColors.first
                                  : null,
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
                                  color: s.headerColor,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            s.name,
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

  Future<void> _exportAsImage(BuildContext context) async {
    final style = DetailCardStyle.presets[_selectedStyleIndex];
    final font = fontPresets[_selectedFontIndex];
    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final category = widget.event.categoryId != null
        ? categories.where((c) => c.id == widget.event.categoryId).firstOrNull
        : null;
    final calcService = DateCalculationService();
    final effectiveDate = _getEffectiveDate(widget.event, calcService);
    final days = calcService.daysUntil(effectiveDate);
    final headerColor = (_selectedStyleIndex == 0 && category != null)
        ? category.color
        : style.headerColor;

    final exportKey = GlobalKey();

    // 确定导出背景色（比卡片背景更深一层）
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
                // 顶部应用名
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
                // 卡片
                _buildCard(
                  Theme.of(context), style, font, headerColor,
                  days, effectiveDate,
                ),
                const SizedBox(height: 32),
                // 底部品牌水印
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

    // 用 Overlay 离屏渲染
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

  /// 根据卡片样式计算导出图片的背景色
  Color _exportBackgroundColor(DetailCardStyle style) {
    final base = style.backgroundColors.first;
    // 浅色卡片用更浅的灰做背景，深色卡片用更深的色做背景
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
    if (widget.event.calendarType == 'lunar' &&
        widget.event.lunarYear != null &&
        widget.event.lunarMonth != null &&
        widget.event.lunarDay != null) {
      final lunarStr = LunarService().getLunarDateString(
        widget.event.lunarYear!,
        widget.event.lunarMonth!,
        widget.event.lunarDay!,
        isLeapMonth: widget.event.isLeapMonth,
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

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/card_style.dart';
import '../models/category.dart';
import '../models/event.dart';
import '../services/date_calculation_service.dart';
import '../services/lunar_service.dart';

class EventCard extends StatelessWidget {
  final Event event;
  final CardStyle? style;
  final EventCategory? category;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool isSelected;
  final bool isGridCard;

  const EventCard({
    super.key,
    required this.event,
    this.style,
    this.category,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isGridCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calcService = DateCalculationService();
    final effectiveDate = _getEffectiveDate(event, calcService);
    final days = calcService.daysUntil(effectiveDate);

    final effectiveStyle = style ?? CardStyle.presets.first;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: _buildDecoration(effectiveStyle, theme),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (effectiveStyle.backgroundImagePath != null)
              _buildBackgroundImage(effectiveStyle),
            Padding(
              padding: EdgeInsets.all(isGridCard ? 0.0 : 16.0),
              child: isGridCard
                  ? _buildGridLayout(days, effectiveStyle, theme)
                  : _buildListLayout(days, effectiveStyle, theme),
            ),
            if (isSelected)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.check_circle,
                  color: theme.colorScheme.primary,
                ),
              ),
            if (event.isPinned && !isGridCard)
              Positioned(
                top: 8,
                right: 8,
                child: Icon(
                  Icons.push_pin,
                  size: 16,
                  color: Color(effectiveStyle.textColor).withAlpha(150),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridLayout(
    int days,
    CardStyle cardStyle,
    ThemeData theme,
  ) {
    final headerColor = Color(cardStyle.headerColor);
    // 判断标题栏文字颜色：根据背景色亮度自动选择
    final headerTextColor =
        headerColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white;
    final headerText = '${event.name} ${_formatDaysLabel2(days)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 彩色标题栏
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: headerColor,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              topRight: Radius.circular(16),
            ),
          ),
          child: Text(
            headerText,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: headerTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        // 大号天数
        Expanded(
          child: Center(
            child: Text(
              _formatDaysNumber(days),
              style: _getNumberTextStyle(cardStyle, 40),
            ),
          ),
        ),
        // 底部日期行
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          child: Text(
            _formatDateLine(),
            style: TextStyle(
              fontSize: 11,
              color: Color(cardStyle.textColor).withAlpha(150),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  String _formatDaysLabel2(int days) {
    if (days == 0) return '就是今天';
    if (days > 0) return '还有';
    return '已经';
  }

  Widget _buildListLayout(
    int days,
    CardStyle cardStyle,
    ThemeData theme,
  ) {
    return Row(
      children: [
        // 色条（使用样式的 headerColor）
        Container(
          width: 4,
          height: 48,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Color(cardStyle.headerColor),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // 事件信息
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                event.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Color(cardStyle.textColor),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _formatDateLine(),
                style: TextStyle(
                  fontSize: 12,
                  color: Color(cardStyle.textColor).withAlpha(150),
                ),
              ),
            ],
          ),
        ),
        // 天数
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatDaysNumber(days),
              style: _getNumberTextStyle(cardStyle, 32),
            ),
            Text(
              _formatDaysLabel(days),
              style: TextStyle(
                fontSize: 12,
                color: Color(cardStyle.textColor).withAlpha(150),
              ),
            ),
          ],
        ),
      ],
    );
  }

  BoxDecoration _buildDecoration(CardStyle cardStyle, ThemeData theme) {
    final borderRadius = BorderRadius.circular(cardStyle.cardBorderRadius);
    final hasGradient = cardStyle.gradientColors != null &&
        cardStyle.gradientColors!.length >= 2;

    return BoxDecoration(
      borderRadius: borderRadius,
      gradient: hasGradient
          ? LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: cardStyle.gradientColors!
                  .map((c) => Color(c))
                  .toList(),
            )
          : null,
      color: hasGradient ? null : Color(cardStyle.backgroundColor),
    );
  }

  Widget _buildBackgroundImage(CardStyle cardStyle) {
    final path = cardStyle.backgroundImagePath!;
    final isFile = path.startsWith('/');

    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(cardStyle.cardBorderRadius),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ImageFiltered(
              imageFilter: ImageFilter.blur(
                sigmaX: cardStyle.imageBlur,
                sigmaY: cardStyle.imageBlur,
              ),
              child: isFile
                  ? Image.file(
                      File(path),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    )
                  : Image.asset(
                      path,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
            ),
            Container(
              color: Colors.black
                  .withAlpha((cardStyle.overlayOpacity * 255).toInt()),
            ),
          ],
        ),
      ),
    );
  }

  TextStyle _getNumberTextStyle(CardStyle cardStyle, double fontSize) {
    TextStyle baseStyle = TextStyle(
      fontSize: fontSize,
      fontWeight: FontWeight.w700,
      color: Color(cardStyle.numberColor),
    );

    if (cardStyle.fontFamily != 'default') {
      try {
        switch (cardStyle.fontFamily) {
          case 'Caveat':
            baseStyle = GoogleFonts.caveat(textStyle: baseStyle);
          case 'DancingScript':
            baseStyle = GoogleFonts.dancingScript(textStyle: baseStyle);
          case 'ZCOOLQingKeHuangYou':
            baseStyle = GoogleFonts.zcoolQingKeHuangYou(textStyle: baseStyle);
          case 'ZCOOLKuaiLe':
            baseStyle = GoogleFonts.zcoolKuaiLe(textStyle: baseStyle);
          case 'MaShanZheng':
            baseStyle = GoogleFonts.maShanZheng(textStyle: baseStyle);
          case 'LiuJianMaoCao':
            baseStyle = GoogleFonts.liuJianMaoCao(textStyle: baseStyle);
          case 'LongCang':
            baseStyle = GoogleFonts.longCang(textStyle: baseStyle);
          case 'PlayfairDisplay':
            baseStyle = GoogleFonts.playfairDisplay(
              textStyle: baseStyle.copyWith(fontStyle: FontStyle.italic),
            );
          case 'PressStart2P':
            baseStyle = GoogleFonts.pressStart2p(
              textStyle: baseStyle.copyWith(fontSize: fontSize * 0.6),
            );
        }
      } catch (_) {
        // 字体加载失败，使用默认字体
      }
    }

    return baseStyle;
  }

  String _formatDaysNumber(int days) {
    if (days == 0) return '0';
    return days.abs().toString();
  }

  String _formatDaysLabel(int days) {
    if (days == 0) return '就是今天';
    if (days > 0) return '天后';
    return '天前';
  }

  static DateTime _getEffectiveDate(Event event, DateCalculationService calcService) {
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

  String _formatDateLine() {
    final calcService = DateCalculationService();
    final displayDate = _getEffectiveDate(event, calcService);
    final dateStr =
        '${displayDate.year}.${displayDate.month.toString().padLeft(2, '0')}.${displayDate.day.toString().padLeft(2, '0')}';

    if (event.calendarType == 'lunar' &&
        event.lunarYear != null &&
        event.lunarMonth != null &&
        event.lunarDay != null) {
      final lunarService = LunarService();
      final lunarStr = lunarService.getLunarDateString(
        event.lunarYear!,
        event.lunarMonth!,
        event.lunarDay!,
        isLeapMonth: event.isLeapMonth,
      );
      return '$lunarStr ($dateStr)';
    }

    return dateStr;
  }
}

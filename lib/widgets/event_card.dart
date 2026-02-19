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
  final bool isFocusCard;

  const EventCard({
    super.key,
    required this.event,
    this.style,
    this.category,
    this.onTap,
    this.onLongPress,
    this.isSelected = false,
    this.isFocusCard = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final calcService = DateCalculationService();
    final days = calcService.daysUntil(event.targetDate);

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
              padding: EdgeInsets.all(isFocusCard ? 24.0 : 16.0),
              child: isFocusCard
                  ? _buildFocusLayout(days, effectiveStyle, theme)
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
            if (event.isPinned && !isFocusCard)
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

  Widget _buildFocusLayout(
    int days,
    CardStyle cardStyle,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // 分类标签
        if (category != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: category!.color.withAlpha(40),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              category!.name,
              style: TextStyle(
                fontSize: 12,
                color: Color(cardStyle.textColor),
              ),
            ),
          ),
        if (category != null) const SizedBox(height: 8),
        // 事件名称
        Text(
          event.name,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(cardStyle.textColor),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        // 天数
        Text(
          _formatDays(days),
          style: _getNumberTextStyle(cardStyle, 48),
        ),
        const SizedBox(height: 4),
        // 日期
        Text(
          _formatDateLine(),
          style: TextStyle(
            fontSize: 14,
            color: Color(cardStyle.textColor).withAlpha(180),
          ),
        ),
      ],
    );
  }

  Widget _buildListLayout(
    int days,
    CardStyle cardStyle,
    ThemeData theme,
  ) {
    return Row(
      children: [
        // 分类色条
        if (category != null)
          Container(
            width: 4,
            height: 48,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: category!.color,
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

    switch (cardStyle.styleType) {
      case StyleType.gradient:
        return BoxDecoration(
          borderRadius: borderRadius,
          gradient: cardStyle.gradientColors != null &&
                  cardStyle.gradientColors!.length >= 2
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: cardStyle.gradientColors!
                      .map((c) => Color(c))
                      .toList(),
                )
              : null,
          color: cardStyle.gradientColors == null
              ? Color(cardStyle.backgroundColor)
              : null,
        );

      case StyleType.glass:
        return BoxDecoration(
          borderRadius: borderRadius,
          color: Color(cardStyle.backgroundColor),
          border: Border.all(
            color: Colors.white.withAlpha(50),
          ),
        );

      case StyleType.shadow:
        return BoxDecoration(
          borderRadius: borderRadius,
          color: Color(cardStyle.backgroundColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        );

      case StyleType.neon:
        return BoxDecoration(
          borderRadius: borderRadius,
          color: Color(cardStyle.backgroundColor),
          border: Border.all(
            color: Color(cardStyle.numberColor).withAlpha(80),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(cardStyle.numberColor).withAlpha(30),
              blurRadius: 16,
              spreadRadius: 2,
            ),
          ],
        );

      case StyleType.handdrawn:
        return BoxDecoration(
          borderRadius: borderRadius,
          color: Color(cardStyle.backgroundColor),
          border: Border.all(
            color: Color(cardStyle.textColor).withAlpha(80),
            width: 2,
          ),
        );

      case StyleType.festival:
        return BoxDecoration(
          borderRadius: borderRadius,
          gradient: cardStyle.gradientColors != null &&
                  cardStyle.gradientColors!.length >= 2
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: cardStyle.gradientColors!
                      .map((c) => Color(c))
                      .toList(),
                )
              : null,
          color: cardStyle.gradientColors == null
              ? Color(cardStyle.backgroundColor)
              : null,
        );

      case StyleType.simple:
      case StyleType.custom:
        return BoxDecoration(
          borderRadius: borderRadius,
          color: Color(cardStyle.backgroundColor),
        );
    }
  }

  Widget _buildBackgroundImage(CardStyle cardStyle) {
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
              child: Image.asset(
                cardStyle.backgroundImagePath!,
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
          case 'RobotoMono':
            baseStyle = GoogleFonts.robotoMono(textStyle: baseStyle);
          case 'ZenMaruGothic':
            baseStyle = GoogleFonts.zenMaruGothic(textStyle: baseStyle);
          case 'MaShanZheng':
            baseStyle = GoogleFonts.maShanZheng(textStyle: baseStyle);
          case 'NotoSerifSC':
            baseStyle = GoogleFonts.notoSerifSc(textStyle: baseStyle);
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

  String _formatDays(int days) {
    if (days == 0) return '就是今天';
    if (days > 0) return '还有 $days 天';
    return '已过 ${days.abs()} 天';
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

  String _formatDateLine() {
    final date = event.targetDate;
    final dateStr =
        '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';

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

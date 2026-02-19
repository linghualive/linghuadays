import 'dart:io';

import 'package:flutter/material.dart';

import '../models/card_style.dart';
import '../models/event.dart';
import 'event_card.dart';

class StyleSelector extends StatelessWidget {
  final List<CardStyle> styles;
  final int? selectedStyleId;
  final Event previewEvent;
  final ValueChanged<CardStyle> onSelected;
  final ValueChanged<CardStyle>? onDeleted;

  const StyleSelector({
    super.key,
    required this.styles,
    this.selectedStyleId,
    required this.previewEvent,
    required this.onSelected,
    this.onDeleted,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '选择样式',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: styles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final style = styles[index];
              final isSelected = style.id == selectedStyleId;
              final hasImage = style.backgroundImagePath != null &&
                  style.backgroundImagePath!.isNotEmpty;
              final hasGradient = style.gradientColors != null &&
                  style.gradientColors!.length >= 2;

              return GestureDetector(
                onTap: () => onSelected(style),
                onLongPress: !style.isPreset && onDeleted != null
                    ? () => _confirmDelete(context, style)
                    : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 80,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(
                            color: theme.colorScheme.primary,
                            width: 2.5,
                          )
                        : Border.all(
                            color: theme.colorScheme.outline.withAlpha(50),
                          ),
                    color: hasImage ? null : Color(style.backgroundColor),
                    gradient: !hasImage && hasGradient
                        ? LinearGradient(
                            colors: style.gradientColors!
                                .map((c) => Color(c))
                                .toList(),
                          )
                        : null,
                    image: hasImage
                        ? DecorationImage(
                            image: FileImage(File(style.backgroundImagePath!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: Stack(
                    children: [
                      // 图片遮罩
                      if (hasImage)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Colors.black.withAlpha(60),
                            ),
                          ),
                        ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '42',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Color(style.numberColor),
                              ),
                            ),
                            Text(
                              hasImage ? '图片' : style.styleName,
                              style: TextStyle(
                                fontSize: 10,
                                color: Color(style.textColor),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (styles.any((s) => !s.isPreset))
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '长按自定义样式可删除',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ),
        const SizedBox(height: 16),
        // 实时预览
        if (selectedStyleId != null)
          EventCard(
            event: previewEvent,
            style: styles
                .where((s) => s.id == selectedStyleId)
                .firstOrNull,
          ),
      ],
    );
  }

  void _confirmDelete(BuildContext context, CardStyle style) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('删除样式'),
        content: Text('确定要删除「${style.backgroundImagePath != null ? "图片" : style.styleName}」样式吗？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDeleted?.call(style);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

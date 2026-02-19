import 'package:flutter/material.dart';

import '../models/card_style.dart';
import '../models/event.dart';
import 'event_card.dart';

class StyleSelector extends StatelessWidget {
  final List<CardStyle> styles;
  final int? selectedStyleId;
  final Event previewEvent;
  final ValueChanged<CardStyle> onSelected;

  const StyleSelector({
    super.key,
    required this.styles,
    this.selectedStyleId,
    required this.previewEvent,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '选择风格',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 12),
        // 风格缩略图网格
        SizedBox(
          height: 80,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: styles.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final style = styles[index];
              final isSelected = style.id == selectedStyleId;

              return GestureDetector(
                onTap: () => onSelected(style),
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
                    color: Color(style.backgroundColor),
                    gradient: style.gradientColors != null &&
                            style.gradientColors!.length >= 2
                        ? LinearGradient(
                            colors: style.gradientColors!
                                .map((c) => Color(c))
                                .toList(),
                          )
                        : null,
                  ),
                  child: Center(
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
                          style.styleName,
                          style: TextStyle(
                            fontSize: 10,
                            color: Color(style.textColor),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
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
}

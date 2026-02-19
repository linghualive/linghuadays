import 'package:flutter/material.dart';

class SkeletonLoader extends StatefulWidget {
  const SkeletonLoader({super.key});

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.3, end: 0.7).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, _) {
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Skeleton for focus card
            _buildFocusCardSkeleton(theme),
            const SizedBox(height: 16),
            // Skeleton for list items
            _buildListItemSkeleton(theme),
            const SizedBox(height: 8),
            _buildListItemSkeleton(theme),
            const SizedBox(height: 8),
            _buildListItemSkeleton(theme),
            const SizedBox(height: 8),
            _buildListItemSkeleton(theme),
          ],
        );
      },
    );
  }

  Widget _buildFocusCardSkeleton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: theme.colorScheme.surfaceContainerHighest
            .withAlpha((_animation.value * 255).toInt()),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _skeletonBox(theme, width: 60, height: 14),
          const SizedBox(height: 10),
          _skeletonBox(theme, width: 180, height: 18),
          const SizedBox(height: 14),
          _skeletonBox(theme, width: 120, height: 36),
          const SizedBox(height: 6),
          _skeletonBox(theme, width: 100, height: 12),
        ],
      ),
    );
  }

  Widget _buildListItemSkeleton(ThemeData theme) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainerHighest
            .withAlpha((_animation.value * 255).toInt()),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _skeletonBox(theme, width: 4, height: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _skeletonBox(theme, width: 140, height: 16),
                const SizedBox(height: 8),
                _skeletonBox(theme, width: 100, height: 12),
              ],
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _skeletonBox(theme, width: 50, height: 28),
              const SizedBox(height: 4),
              _skeletonBox(theme, width: 30, height: 12),
            ],
          ),
        ],
      ),
    );
  }

  Widget _skeletonBox(
    ThemeData theme, {
    required double width,
    required double height,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: theme.colorScheme.onSurface
            .withAlpha((_animation.value * 40).toInt()),
      ),
    );
  }
}

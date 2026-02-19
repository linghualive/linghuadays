import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/category.dart';
import '../providers/category_provider.dart';

class CategoryManagementScreen extends ConsumerWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('分类管理'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showAddDialog(context, ref, theme),
          ),
        ],
      ),
      body: categoriesAsync.when(
        data: (categories) => ListView.builder(
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: cat.color,
                radius: 16,
              ),
              title: Text(cat.name),
              subtitle: cat.isPreset ? const Text('预设分类') : null,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: () =>
                        _showEditDialog(context, ref, theme, cat),
                  ),
                  if (!cat.isPreset)
                    IconButton(
                      icon: Icon(
                        Icons.delete_outline,
                        size: 20,
                        color: theme.colorScheme.error,
                      ),
                      onPressed: () =>
                          _confirmDelete(context, ref, cat),
                    ),
                ],
              ),
            );
          },
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  void _showAddDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
  ) {
    _showCategoryDialog(
      context: context,
      theme: theme,
      title: '新建分类',
      onSave: (name, color) {
        ref.read(categoriesProvider.notifier).addCategory(
              EventCategory(name: name, colorValue: color),
            );
      },
    );
  }

  void _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    ThemeData theme,
    EventCategory category,
  ) {
    _showCategoryDialog(
      context: context,
      theme: theme,
      title: '编辑分类',
      initialName: category.name,
      initialColor: category.colorValue,
      nameEditable: !category.isPreset,
      onSave: (name, color) {
        ref.read(categoriesProvider.notifier).updateCategory(
              category.copyWith(
                name: category.isPreset ? category.name : name,
                colorValue: color,
              ),
            );
      },
    );
  }

  void _showCategoryDialog({
    required BuildContext context,
    required ThemeData theme,
    required String title,
    String? initialName,
    int initialColor = 0xFFE91E63,
    bool nameEditable = true,
    required void Function(String name, int color) onSave,
  }) {
    final nameController = TextEditingController(text: initialName);
    var selectedColor = initialColor;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                enabled: nameEditable,
                decoration: const InputDecoration(labelText: '分类名称'),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  0xFFE91E63,
                  0xFF9C27B0,
                  0xFF673AB7,
                  0xFF3F51B5,
                  0xFF2196F3,
                  0xFF00BCD4,
                  0xFF4CAF50,
                  0xFF8BC34A,
                  0xFFFF9800,
                  0xFFFF5722,
                  0xFF795548,
                  0xFF607D8B,
                ].map((color) {
                  return GestureDetector(
                    onTap: () =>
                        setDialogState(() => selectedColor = color),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Color(color),
                        shape: BoxShape.circle,
                        border: selectedColor == color
                            ? Border.all(
                                color: theme.colorScheme.onSurface,
                                width: 3,
                              )
                            : null,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('取消'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                if (name.isNotEmpty || !nameEditable) {
                  onSave(name, selectedColor);
                  Navigator.pop(context);
                }
              },
              child: const Text('保存'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    EventCategory category,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除'),
        content: Text('删除「${category.name}」分类后，该分类下的事件将变为"未分类"'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              ref
                  .read(categoriesProvider.notifier)
                  .deleteCategory(category.id!);
            },
            child: const Text('删除'),
          ),
        ],
      ),
    );
  }
}

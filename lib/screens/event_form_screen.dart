import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/card_style.dart';
import '../models/category.dart';
import '../models/event.dart';
import '../providers/category_provider.dart';
import '../providers/event_provider.dart';
import '../providers/style_provider.dart';
import '../services/notification_service.dart';
import '../widgets/lunar_date_picker.dart';
import '../widgets/style_selector.dart';

class EventFormScreen extends ConsumerStatefulWidget {
  final Event? event; // null 表示创建模式

  const EventFormScreen({super.key, this.event});

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _noteController = TextEditingController();

  String _calendarType = 'solar';
  DateTime? _solarDate;
  int? _lunarYear;
  int? _lunarMonth;
  int? _lunarDay;
  bool _isLeapMonth = false;
  int? _categoryId;
  bool _isRepeating = false;
  int? _styleId;
  bool _enableReminder = false;
  int _reminderDaysBefore = 1;
  int _reminderHour = 9;
  int _reminderMinute = 0;

  bool get _isEditMode => widget.event != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final e = widget.event!;
      _nameController.text = e.name;
      _noteController.text = e.note ?? '';
      _calendarType = e.calendarType;
      _solarDate = e.targetDate;
      _lunarYear = e.lunarYear;
      _lunarMonth = e.lunarMonth;
      _lunarDay = e.lunarDay;
      _isLeapMonth = e.isLeapMonth;
      _categoryId = e.categoryId;
      _isRepeating = e.isRepeating;
      _styleId = e.styleId;
      if (e.reminderDaysBefore != null) {
        _enableReminder = true;
        _reminderDaysBefore = e.reminderDaysBefore!;
        _reminderHour = e.reminderHour ?? 9;
        _reminderMinute = e.reminderMinute ?? 0;
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final categoriesAsync = ref.watch(categoriesProvider);
    final stylesAsync = ref.watch(stylesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditMode ? '编辑倒数日' : '创建倒数日'),
        actions: [
          TextButton(
            onPressed: _onSave,
            child: const Text('保存'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // 事件名称
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: '事件名称',
                hintText: '如：妈妈生日',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return '请输入事件名称';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // 日历类型切换
            Text('日历类型', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(
                  value: 'solar',
                  label: Text('公历'),
                  icon: Icon(Icons.calendar_today),
                ),
                ButtonSegment(
                  value: 'lunar',
                  label: Text('农历'),
                  icon: Icon(Icons.auto_awesome),
                ),
              ],
              selected: {_calendarType},
              onSelectionChanged: (selected) {
                setState(() {
                  _calendarType = selected.first;
                  // 切换日历类型时清空日期
                  if (!_isEditMode) {
                    _solarDate = null;
                    _lunarYear = null;
                    _lunarMonth = null;
                    _lunarDay = null;
                    _isLeapMonth = false;
                  }
                });
              },
            ),
            const SizedBox(height: 16),

            // 日期选择
            if (_calendarType == 'solar') _buildSolarDatePicker(theme),
            if (_calendarType == 'lunar') _buildLunarDatePicker(theme),
            const SizedBox(height: 24),

            // 分类选择
            Text('分类', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            categoriesAsync.when(
              data: (categories) =>
                  _buildCategorySelector(categories, theme),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('加载分类失败'),
            ),
            const SizedBox(height: 24),

            // 每年重复
            SwitchListTile(
              title: const Text('每年重复'),
              subtitle: const Text('开启后每年自动计算下一次倒计时'),
              value: _isRepeating,
              onChanged: (value) => setState(() => _isRepeating = value),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 16),

            // 提醒设置
            _buildReminderSection(theme),
            const SizedBox(height: 16),

            // 备注
            TextFormField(
              controller: _noteController,
              decoration: const InputDecoration(
                labelText: '备注（可选）',
                hintText: '添加备注信息',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),

            // 样式选择
            stylesAsync.when(
              data: (styles) => _buildStyleSelector(styles),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('加载样式失败'),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSolarDatePicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('选择日期', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        InkWell(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _solarDate ?? DateTime.now(),
              firstDate: DateTime(1900),
              lastDate: DateTime(2100, 12, 31),
            );
            if (date != null) {
              setState(() => _solarDate = date);
            }
          },
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.outline.withAlpha(80),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.calendar_month,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  _solarDate != null
                      ? '${_solarDate!.year}年${_solarDate!.month}月${_solarDate!.day}日'
                      : '点击选择日期',
                  style: TextStyle(
                    fontSize: 16,
                    color: _solarDate != null
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.outline,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLunarDatePicker(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('选择农历日期', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        LunarDatePicker(
          initialYear: _lunarYear,
          initialMonth: _lunarMonth,
          initialDay: _lunarDay,
          initialIsLeapMonth: _isLeapMonth,
          onChanged: (result) {
            setState(() {
              _lunarYear = result.year;
              _lunarMonth = result.month;
              _lunarDay = result.day;
              _isLeapMonth = result.isLeapMonth;
              _solarDate = result.solarDate;
            });
          },
        ),
      ],
    );
  }

  Widget _buildCategorySelector(
    List<EventCategory> categories,
    ThemeData theme,
  ) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        ...categories.map(
          (cat) => ChoiceChip(
            label: Text(cat.name),
            selected: _categoryId == cat.id,
            avatar: CircleAvatar(
              backgroundColor: cat.color,
              radius: 6,
            ),
            onSelected: (selected) {
              setState(() {
                _categoryId = selected ? cat.id : null;
              });
            },
          ),
        ),
        ActionChip(
          label: const Text('+ 新分类'),
          onPressed: () => _showAddCategoryDialog(theme),
        ),
      ],
    );
  }

  Widget _buildReminderSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile(
          title: const Text('事件提醒'),
          subtitle: const Text('在事件到来前发送通知提醒'),
          value: _enableReminder,
          onChanged: (value) async {
            if (value) {
              final granted =
                  await NotificationService().requestPermission();
              if (!granted) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('需要通知权限才能设置提醒')),
                  );
                }
                return;
              }
            }
            setState(() => _enableReminder = value);
          },
          contentPadding: EdgeInsets.zero,
        ),
        if (_enableReminder) ...[
          const SizedBox(height: 8),
          Text('提前提醒', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _reminderDaysChip('当天', 0),
              _reminderDaysChip('1天前', 1),
              _reminderDaysChip('3天前', 3),
              _reminderDaysChip('7天前', 7),
              _reminderDaysChip('14天前', 14),
              _reminderDaysChip('30天前', 30),
            ],
          ),
          const SizedBox(height: 16),
          Text('提醒时间', style: theme.textTheme.bodyMedium),
          const SizedBox(height: 8),
          InkWell(
            onTap: () async {
              final time = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: _reminderHour,
                  minute: _reminderMinute,
                ),
              );
              if (time != null) {
                setState(() {
                  _reminderHour = time.hour;
                  _reminderMinute = time.minute;
                });
              }
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: theme.colorScheme.outline.withAlpha(80),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.access_time,
                    color: theme.colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_reminderHour.toString().padLeft(2, '0')}:${_reminderMinute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _reminderDaysChip(String label, int days) {
    return ChoiceChip(
      label: Text(label),
      selected: _reminderDaysBefore == days,
      onSelected: (selected) {
        if (selected) {
          setState(() => _reminderDaysBefore = days);
        }
      },
    );
  }

  Widget _buildStyleSelector(List<CardStyle> styles) {
    final now = DateTime.now();
    final previewEvent = Event(
      name: _nameController.text.isEmpty ? '预览事件' : _nameController.text,
      targetDate: _solarDate ?? DateTime.now().add(const Duration(days: 30)),
      calendarType: _calendarType,
      lunarYear: _lunarYear,
      lunarMonth: _lunarMonth,
      lunarDay: _lunarDay,
      isLeapMonth: _isLeapMonth,
      createdAt: now,
      updatedAt: now,
    );

    return StyleSelector(
      styles: styles,
      selectedStyleId: _styleId,
      previewEvent: previewEvent,
      onSelected: (style) {
        setState(() => _styleId = style.id);
      },
      onDeleted: (style) async {
        // 如果删除的是当前选中的样式，切到第一个预设
        if (_styleId == style.id) {
          final firstPreset = styles.firstWhere(
            (s) => s.isPreset,
            orElse: () => styles.first,
          );
          setState(() => _styleId = firstPreset.id);
        }
        // 删除样式和图片文件
        if (style.id != null) {
          await ref.read(stylesProvider.notifier).deleteStyle(style.id!);
        }
        if (style.backgroundImagePath != null) {
          final file = File(style.backgroundImagePath!);
          if (file.existsSync()) file.deleteSync();
        }
      },
    );
  }

  void _showAddCategoryDialog(ThemeData theme) {
    final nameController = TextEditingController();
    var selectedColor = 0xFFE91E63;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('新建分类'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '分类名称',
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  0xFFE91E63,
                  0xFF9C27B0,
                  0xFF673AB7,
                  0xFF2196F3,
                  0xFF4CAF50,
                  0xFFFF9800,
                  0xFFFF5722,
                  0xFF795548,
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
                if (nameController.text.trim().isNotEmpty) {
                  ref
                      .read(categoriesProvider.notifier)
                      .addCategory(EventCategory(
                        name: nameController.text.trim(),
                        colorValue: selectedColor,
                      ));
                  Navigator.pop(context);
                }
              },
              child: const Text('创建'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    if (_solarDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请选择日期')),
      );
      return;
    }

    // 如果没有选择样式，自动分配第一个预设样式
    final effectiveStyleId = _styleId ?? _getDefaultStyleId();

    final now = DateTime.now();

    final int? reminderDays = _enableReminder ? _reminderDaysBefore : null;
    final int? reminderH = _enableReminder ? _reminderHour : null;
    final int? reminderM = _enableReminder ? _reminderMinute : null;

    if (_isEditMode) {
      final updated = widget.event!.copyWith(
        name: _nameController.text.trim(),
        targetDate: _solarDate!,
        calendarType: _calendarType,
        lunarYear: () => _lunarYear,
        lunarMonth: () => _lunarMonth,
        lunarDay: () => _lunarDay,
        isLeapMonth: _isLeapMonth,
        categoryId: () => _categoryId,
        note: () =>
            _noteController.text.trim().isEmpty
                ? null
                : _noteController.text.trim(),
        isRepeating: _isRepeating,
        styleId: () => effectiveStyleId,
        updatedAt: now,
        reminderDaysBefore: () => reminderDays,
        reminderHour: () => reminderH,
        reminderMinute: () => reminderM,
      );
      await ref.read(eventsProvider.notifier).updateEvent(updated);
    } else {
      final event = Event(
        name: _nameController.text.trim(),
        targetDate: _solarDate!,
        calendarType: _calendarType,
        lunarYear: _lunarYear,
        lunarMonth: _lunarMonth,
        lunarDay: _lunarDay,
        isLeapMonth: _isLeapMonth,
        categoryId: _categoryId,
        note: _noteController.text.trim().isEmpty
            ? null
            : _noteController.text.trim(),
        isRepeating: _isRepeating,
        styleId: effectiveStyleId,
        createdAt: now,
        updatedAt: now,
        reminderDaysBefore: reminderDays,
        reminderHour: reminderH,
        reminderMinute: reminderM,
      );
      await ref.read(eventsProvider.notifier).addEvent(event);
    }

    if (mounted) Navigator.pop(context);
  }

  int? _getDefaultStyleId() {
    final styles = ref.read(stylesProvider).valueOrNull;
    if (styles == null || styles.isEmpty) return null;
    final firstPreset = styles.where((s) => s.isPreset).firstOrNull;
    return firstPreset?.id ?? styles.first.id;
  }
}

import 'package:flutter/material.dart';

import '../services/lunar_service.dart';

class LunarDatePickerResult {
  final int year;
  final int month;
  final int day;
  final bool isLeapMonth;
  final DateTime solarDate;

  const LunarDatePickerResult({
    required this.year,
    required this.month,
    required this.day,
    required this.isLeapMonth,
    required this.solarDate,
  });
}

class LunarDatePicker extends StatefulWidget {
  final int? initialYear;
  final int? initialMonth;
  final int? initialDay;
  final bool initialIsLeapMonth;
  final ValueChanged<LunarDatePickerResult> onChanged;

  const LunarDatePicker({
    super.key,
    this.initialYear,
    this.initialMonth,
    this.initialDay,
    this.initialIsLeapMonth = false,
    required this.onChanged,
  });

  @override
  State<LunarDatePicker> createState() => _LunarDatePickerState();
}

class _LunarDatePickerState extends State<LunarDatePicker> {
  final _lunarService = LunarService();
  late int _selectedYear;
  late int _selectedMonth;
  late int _selectedDay;
  late bool _isLeapMonth;

  late FixedExtentScrollController _yearController;
  late FixedExtentScrollController _monthController;
  late FixedExtentScrollController _dayController;

  static const int _startYear = 1900;
  static const int _endYear = 2100;

  // 天干地支
  static const List<String> _tianGan = [
    '甲',
    '乙',
    '丙',
    '丁',
    '戊',
    '己',
    '庚',
    '辛',
    '壬',
    '癸',
  ];
  static const List<String> _diZhi = [
    '子',
    '丑',
    '寅',
    '卯',
    '辰',
    '巳',
    '午',
    '未',
    '申',
    '酉',
    '戌',
    '亥',
  ];

  static const List<String> _monthNames = [
    '正月',
    '二月',
    '三月',
    '四月',
    '五月',
    '六月',
    '七月',
    '八月',
    '九月',
    '十月',
    '冬月',
    '腊月',
  ];

  static const List<String> _dayNames = [
    '初一',
    '初二',
    '初三',
    '初四',
    '初五',
    '初六',
    '初七',
    '初八',
    '初九',
    '初十',
    '十一',
    '十二',
    '十三',
    '十四',
    '十五',
    '十六',
    '十七',
    '十八',
    '十九',
    '二十',
    '廿一',
    '廿二',
    '廿三',
    '廿四',
    '廿五',
    '廿六',
    '廿七',
    '廿八',
    '廿九',
    '三十',
  ];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final currentLunar = _lunarService.solarToLunar(now);

    _selectedYear = widget.initialYear ?? currentLunar.year;
    _selectedMonth = widget.initialMonth ?? currentLunar.month;
    _selectedDay = widget.initialDay ?? currentLunar.day;
    _isLeapMonth = widget.initialIsLeapMonth;

    _yearController = FixedExtentScrollController(
      initialItem: _selectedYear - _startYear,
    );
    _monthController = FixedExtentScrollController(
      initialItem: _getMonthIndex(),
    );
    _dayController = FixedExtentScrollController(
      initialItem: _selectedDay - 1,
    );
  }

  @override
  void dispose() {
    _yearController.dispose();
    _monthController.dispose();
    _dayController.dispose();
    super.dispose();
  }

  int _getMonthIndex() {
    final leapMonth = _lunarService.getLeapMonth(_selectedYear);
    if (_isLeapMonth && _selectedMonth == leapMonth) {
      return _selectedMonth; // 闰月在对应月之后
    }
    if (leapMonth > 0 && _selectedMonth > leapMonth) {
      return _selectedMonth; // 闰月之后的月份 index + 1
    }
    return _selectedMonth - 1;
  }

  List<String> _getMonthList() {
    final leapMonth = _lunarService.getLeapMonth(_selectedYear);
    final months = <String>[];
    for (var i = 1; i <= 12; i++) {
      months.add(_monthNames[i - 1]);
      if (i == leapMonth) {
        months.add('闰${_monthNames[i - 1]}');
      }
    }
    return months;
  }

  int _getDaysInMonth() {
    try {
      return _lunarService.getDaysInLunarMonth(
        _selectedYear,
        _selectedMonth,
        isLeapMonth: _isLeapMonth,
      );
    } catch (_) {
      return 30;
    }
  }

  String _getGanZhi(int year) {
    final ganIndex = (year - 4) % 10;
    final zhiIndex = (year - 4) % 12;
    return '${_tianGan[ganIndex]}${_diZhi[zhiIndex]}';
  }

  void _onYearChanged(int index) {
    setState(() {
      _selectedYear = _startYear + index;
      _adjustMonthAndDay();
    });
    _notifyChanged();
  }

  void _onMonthChanged(int index) {
    setState(() {
      final leapMonth = _lunarService.getLeapMonth(_selectedYear);
      if (leapMonth > 0) {
        if (index < leapMonth) {
          _selectedMonth = index + 1;
          _isLeapMonth = false;
        } else if (index == leapMonth) {
          _selectedMonth = leapMonth;
          _isLeapMonth = true;
        } else {
          _selectedMonth = index;
          _isLeapMonth = false;
        }
      } else {
        _selectedMonth = index + 1;
        _isLeapMonth = false;
      }
      _adjustDay();
    });
    _notifyChanged();
  }

  void _onDayChanged(int index) {
    setState(() {
      _selectedDay = index + 1;
    });
    _notifyChanged();
  }

  void _adjustMonthAndDay() {
    final months = _getMonthList();
    final currentMonthIndex = _getMonthIndex();
    if (currentMonthIndex >= months.length) {
      _selectedMonth = 12;
      _isLeapMonth = false;
    }
    _adjustDay();
  }

  void _adjustDay() {
    final maxDays = _getDaysInMonth();
    if (_selectedDay > maxDays) {
      _selectedDay = maxDays;
    }
  }

  void _notifyChanged() {
    try {
      final solarDate = _lunarService.lunarToSolar(
        _selectedYear,
        _selectedMonth,
        _selectedDay,
        isLeapMonth: _isLeapMonth,
      );
      widget.onChanged(LunarDatePickerResult(
        year: _selectedYear,
        month: _selectedMonth,
        day: _selectedDay,
        isLeapMonth: _isLeapMonth,
        solarDate: solarDate,
      ));
    } catch (_) {
      // 日期转换异常，忽略
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final months = _getMonthList();
    final daysInMonth = _getDaysInMonth();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 对应公历日期提示
        _buildSolarDateHint(theme),
        const SizedBox(height: 8),
        // 三列滚轮选择器
        SizedBox(
          height: 200,
          child: Row(
            children: [
              // 年份
              Expanded(
                flex: 3,
                child: ListWheelScrollView.useDelegate(
                  controller: _yearController,
                  itemExtent: 40,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: _onYearChanged,
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      final year = _startYear + index;
                      final isSelected = year == _selectedYear;
                      return Center(
                        child: Text(
                          '${_getGanZhi(year)}年 ($year)',
                          style: TextStyle(
                            fontSize: isSelected ? 16 : 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface
                                    .withAlpha(150),
                          ),
                        ),
                      );
                    },
                    childCount: _endYear - _startYear + 1,
                  ),
                ),
              ),
              // 月份
              Expanded(
                flex: 2,
                child: ListWheelScrollView.useDelegate(
                  controller: _monthController,
                  itemExtent: 40,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: _onMonthChanged,
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      if (index >= months.length) return null;
                      final isSelected = index == _getMonthIndex();
                      return Center(
                        child: Text(
                          months[index],
                          style: TextStyle(
                            fontSize: isSelected ? 16 : 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface
                                    .withAlpha(150),
                          ),
                        ),
                      );
                    },
                    childCount: months.length,
                  ),
                ),
              ),
              // 日
              Expanded(
                flex: 2,
                child: ListWheelScrollView.useDelegate(
                  controller: _dayController,
                  itemExtent: 40,
                  physics: const FixedExtentScrollPhysics(),
                  onSelectedItemChanged: _onDayChanged,
                  childDelegate: ListWheelChildBuilderDelegate(
                    builder: (context, index) {
                      if (index >= daysInMonth) return null;
                      final isSelected = index == _selectedDay - 1;
                      return Center(
                        child: Text(
                          _dayNames[index],
                          style: TextStyle(
                            fontSize: isSelected ? 16 : 14,
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface
                                    .withAlpha(150),
                          ),
                        ),
                      );
                    },
                    childCount: daysInMonth,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSolarDateHint(ThemeData theme) {
    try {
      final solarDate = _lunarService.lunarToSolar(
        _selectedYear,
        _selectedMonth,
        _selectedDay,
        isLeapMonth: _isLeapMonth,
      );
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: theme.colorScheme.primaryContainer.withAlpha(80),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          '对应公历: ${solarDate.year}年${solarDate.month}月${solarDate.day}日',
          style: TextStyle(
            fontSize: 14,
            color: theme.colorScheme.onPrimaryContainer,
          ),
        ),
      );
    } catch (_) {
      return const SizedBox.shrink();
    }
  }
}

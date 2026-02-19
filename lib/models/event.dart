class Event {
  final int? id;
  final String name;
  final DateTime targetDate;
  final String calendarType; // 'solar' or 'lunar'
  final int? lunarYear;
  final int? lunarMonth;
  final int? lunarDay;
  final bool isLeapMonth;
  final int? categoryId;
  final String? note;
  final bool isRepeating;
  final bool isPinned;
  final int? styleId;
  final DateTime createdAt;
  final DateTime updatedAt;

  // 提醒设置
  final int? reminderDaysBefore;
  final int? reminderHour;
  final int? reminderMinute;

  const Event({
    this.id,
    required this.name,
    required this.targetDate,
    required this.calendarType,
    this.lunarYear,
    this.lunarMonth,
    this.lunarDay,
    this.isLeapMonth = false,
    this.categoryId,
    this.note,
    this.isRepeating = false,
    this.isPinned = false,
    this.styleId,
    required this.createdAt,
    required this.updatedAt,
    this.reminderDaysBefore,
    this.reminderHour,
    this.reminderMinute,
  });

  Event copyWith({
    int? id,
    String? name,
    DateTime? targetDate,
    String? calendarType,
    int? Function()? lunarYear,
    int? Function()? lunarMonth,
    int? Function()? lunarDay,
    bool? isLeapMonth,
    int? Function()? categoryId,
    String? Function()? note,
    bool? isRepeating,
    bool? isPinned,
    int? Function()? styleId,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? Function()? reminderDaysBefore,
    int? Function()? reminderHour,
    int? Function()? reminderMinute,
  }) {
    return Event(
      id: id ?? this.id,
      name: name ?? this.name,
      targetDate: targetDate ?? this.targetDate,
      calendarType: calendarType ?? this.calendarType,
      lunarYear: lunarYear != null ? lunarYear() : this.lunarYear,
      lunarMonth: lunarMonth != null ? lunarMonth() : this.lunarMonth,
      lunarDay: lunarDay != null ? lunarDay() : this.lunarDay,
      isLeapMonth: isLeapMonth ?? this.isLeapMonth,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      note: note != null ? note() : this.note,
      isRepeating: isRepeating ?? this.isRepeating,
      isPinned: isPinned ?? this.isPinned,
      styleId: styleId != null ? styleId() : this.styleId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reminderDaysBefore: reminderDaysBefore != null
          ? reminderDaysBefore()
          : this.reminderDaysBefore,
      reminderHour:
          reminderHour != null ? reminderHour() : this.reminderHour,
      reminderMinute:
          reminderMinute != null ? reminderMinute() : this.reminderMinute,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'target_date': targetDate.toIso8601String(),
      'calendar_type': calendarType,
      'lunar_year': lunarYear,
      'lunar_month': lunarMonth,
      'lunar_day': lunarDay,
      'is_leap_month': isLeapMonth ? 1 : 0,
      'category_id': categoryId,
      'note': note,
      'is_repeating': isRepeating ? 1 : 0,
      'is_pinned': isPinned ? 1 : 0,
      'style_id': styleId,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'reminder_days_before': reminderDaysBefore,
      'reminder_hour': reminderHour,
      'reminder_minute': reminderMinute,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'] as int?,
      name: map['name'] as String,
      targetDate: DateTime.parse(map['target_date'] as String),
      calendarType: map['calendar_type'] as String,
      lunarYear: map['lunar_year'] as int?,
      lunarMonth: map['lunar_month'] as int?,
      lunarDay: map['lunar_day'] as int?,
      isLeapMonth: (map['is_leap_month'] as int?) == 1,
      categoryId: map['category_id'] as int?,
      note: map['note'] as String?,
      isRepeating: (map['is_repeating'] as int?) == 1,
      isPinned: (map['is_pinned'] as int?) == 1,
      styleId: map['style_id'] as int?,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
      reminderDaysBefore: map['reminder_days_before'] as int?,
      reminderHour: map['reminder_hour'] as int?,
      reminderMinute: map['reminder_minute'] as int?,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory Event.fromJson(Map<String, dynamic> json) => Event.fromMap(json);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Event && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

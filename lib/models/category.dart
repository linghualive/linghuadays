import 'package:flutter/material.dart';

class EventCategory {
  final int? id;
  final String name;
  final int colorValue;
  final bool isPreset;

  const EventCategory({
    this.id,
    required this.name,
    required this.colorValue,
    this.isPreset = false,
  });

  Color get color => Color(colorValue);

  EventCategory copyWith({
    int? id,
    String? name,
    int? colorValue,
    bool? isPreset,
  }) {
    return EventCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      isPreset: isPreset ?? this.isPreset,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color_value': colorValue,
      'is_preset': isPreset ? 1 : 0,
    };
  }

  factory EventCategory.fromMap(Map<String, dynamic> map) {
    return EventCategory(
      id: map['id'] as int?,
      name: map['name'] as String,
      colorValue: map['color_value'] as int,
      isPreset: (map['is_preset'] as int?) == 1,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory EventCategory.fromJson(Map<String, dynamic> json) =>
      EventCategory.fromMap(json);

  static List<EventCategory> get presets => const [
        EventCategory(
          name: '生日',
          colorValue: 0xFFE91E63,
          isPreset: true,
        ),
        EventCategory(
          name: '纪念日',
          colorValue: 0xFF9C27B0,
          isPreset: true,
        ),
        EventCategory(
          name: '节日',
          colorValue: 0xFFFF5722,
          isPreset: true,
        ),
        EventCategory(
          name: '工作',
          colorValue: 0xFF2196F3,
          isPreset: true,
        ),
        EventCategory(
          name: '考试',
          colorValue: 0xFF4CAF50,
          isPreset: true,
        ),
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EventCategory &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

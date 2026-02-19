enum StyleType {
  simple,
  gradient,
  glass,
  shadow,
  neon,
  handdrawn,
  festival,
  custom,
}

class CardStyle {
  final int? id;
  final String styleName;
  final StyleType styleType;
  final int backgroundColor;
  final List<int>? gradientColors;
  final String? backgroundImagePath;
  final double imageBlur;
  final double overlayOpacity;
  final int textColor;
  final int numberColor;
  final int headerColor;
  final String fontFamily;
  final double cardBorderRadius;
  final bool isPreset;

  const CardStyle({
    this.id,
    required this.styleName,
    required this.styleType,
    required this.backgroundColor,
    this.gradientColors,
    this.backgroundImagePath,
    this.imageBlur = 0.0,
    this.overlayOpacity = 0.0,
    required this.textColor,
    required this.numberColor,
    this.headerColor = 0xFF78909C,
    this.fontFamily = 'default',
    this.cardBorderRadius = 16.0,
    this.isPreset = false,
  });

  CardStyle copyWith({
    int? id,
    String? styleName,
    StyleType? styleType,
    int? backgroundColor,
    List<int>? Function()? gradientColors,
    String? Function()? backgroundImagePath,
    double? imageBlur,
    double? overlayOpacity,
    int? textColor,
    int? numberColor,
    int? headerColor,
    String? fontFamily,
    double? cardBorderRadius,
    bool? isPreset,
  }) {
    return CardStyle(
      id: id ?? this.id,
      styleName: styleName ?? this.styleName,
      styleType: styleType ?? this.styleType,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      gradientColors:
          gradientColors != null ? gradientColors() : this.gradientColors,
      backgroundImagePath: backgroundImagePath != null
          ? backgroundImagePath()
          : this.backgroundImagePath,
      imageBlur: imageBlur ?? this.imageBlur,
      overlayOpacity: overlayOpacity ?? this.overlayOpacity,
      textColor: textColor ?? this.textColor,
      numberColor: numberColor ?? this.numberColor,
      headerColor: headerColor ?? this.headerColor,
      fontFamily: fontFamily ?? this.fontFamily,
      cardBorderRadius: cardBorderRadius ?? this.cardBorderRadius,
      isPreset: isPreset ?? this.isPreset,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'style_name': styleName,
      'style_type': styleType.name,
      'background_color': backgroundColor,
      'gradient_colors': gradientColors?.join(','),
      'background_image_path': backgroundImagePath,
      'image_blur': imageBlur,
      'overlay_opacity': overlayOpacity,
      'text_color': textColor,
      'number_color': numberColor,
      'header_color': headerColor,
      'font_family': fontFamily,
      'card_border_radius': cardBorderRadius,
      'is_preset': isPreset ? 1 : 0,
    };
  }

  factory CardStyle.fromMap(Map<String, dynamic> map) {
    final gradientStr = map['gradient_colors'] as String?;
    return CardStyle(
      id: map['id'] as int?,
      styleName: map['style_name'] as String,
      styleType: StyleType.values.byName(map['style_type'] as String),
      backgroundColor: map['background_color'] as int,
      gradientColors: gradientStr?.isNotEmpty == true
          ? gradientStr!.split(',').map(int.parse).toList()
          : null,
      backgroundImagePath: map['background_image_path'] as String?,
      imageBlur: (map['image_blur'] as num?)?.toDouble() ?? 0.0,
      overlayOpacity: (map['overlay_opacity'] as num?)?.toDouble() ?? 0.0,
      textColor: map['text_color'] as int,
      numberColor: map['number_color'] as int,
      headerColor: (map['header_color'] as int?) ?? 0xFF78909C,
      fontFamily: (map['font_family'] as String?) ?? 'default',
      cardBorderRadius:
          (map['card_border_radius'] as num?)?.toDouble() ?? 16.0,
      isPreset: (map['is_preset'] as int?) == 1,
    );
  }

  Map<String, dynamic> toJson() => toMap();

  factory CardStyle.fromJson(Map<String, dynamic> json) =>
      CardStyle.fromMap(json);

  static List<CardStyle> get presets => const [
        CardStyle(
          styleName: '浅粉',
          styleType: StyleType.simple,
          backgroundColor: 0xFFFFF0F3,
          textColor: 0xFF5D4350,
          numberColor: 0xFFB85C7A,
          headerColor: 0xFFD4869C,
          isPreset: true,
        ),
        CardStyle(
          styleName: '淡紫',
          styleType: StyleType.simple,
          backgroundColor: 0xFFF3EEFA,
          textColor: 0xFF4A4458,
          numberColor: 0xFF7B6FA0,
          headerColor: 0xFF9B8EC4,
          isPreset: true,
        ),
        CardStyle(
          styleName: '墨绿',
          styleType: StyleType.simple,
          backgroundColor: 0xFFEFF5F0,
          textColor: 0xFF3B4F3F,
          numberColor: 0xFF4A7058,
          headerColor: 0xFF6B8F7B,
          isPreset: true,
        ),
        CardStyle(
          styleName: '雾蓝',
          styleType: StyleType.simple,
          backgroundColor: 0xFFEEF3F8,
          textColor: 0xFF3D4F5F,
          numberColor: 0xFF5A809E,
          headerColor: 0xFF7B9CB8,
          isPreset: true,
        ),
        CardStyle(
          styleName: '奶油',
          styleType: StyleType.simple,
          backgroundColor: 0xFFFFF8F0,
          textColor: 0xFF5D4E3C,
          numberColor: 0xFFA88B6A,
          headerColor: 0xFFC4A882,
          isPreset: true,
        ),
        CardStyle(
          styleName: '蜜桃',
          styleType: StyleType.simple,
          backgroundColor: 0xFFFFF0E8,
          textColor: 0xFF5C4033,
          numberColor: 0xFFBF7A62,
          headerColor: 0xFFD4937A,
          isPreset: true,
        ),
        CardStyle(
          styleName: '抹茶',
          styleType: StyleType.simple,
          backgroundColor: 0xFFF2F5E9,
          textColor: 0xFF4A5240,
          numberColor: 0xFF6B8055,
          headerColor: 0xFF8FA67A,
          isPreset: true,
        ),
        CardStyle(
          styleName: '莫兰迪',
          styleType: StyleType.simple,
          backgroundColor: 0xFFECECE4,
          textColor: 0xFF4A4A42,
          numberColor: 0xFF6E6E62,
          headerColor: 0xFF9A9A8C,
          isPreset: true,
        ),
        CardStyle(
          styleName: '烟粉',
          styleType: StyleType.gradient,
          backgroundColor: 0xFFF5E6EA,
          gradientColors: [0xFFF5E6EA, 0xFFECD8DF],
          textColor: 0xFF5C4350,
          numberColor: 0xFF9E6B80,
          headerColor: 0xFFB8849A,
          isPreset: true,
        ),
        CardStyle(
          styleName: '薰衣草',
          styleType: StyleType.gradient,
          backgroundColor: 0xFFE8DEF8,
          gradientColors: [0xFFE8DEF8, 0xFFD0BCFF],
          textColor: 0xFF4A4458,
          numberColor: 0xFF6B5B95,
          headerColor: 0xFF8B79AD,
          isPreset: true,
        ),
        CardStyle(
          styleName: '玫瑰金',
          styleType: StyleType.gradient,
          backgroundColor: 0xFFF5E0D8,
          gradientColors: [0xFFF5E0D8, 0xFFE8C8C0],
          textColor: 0xFF5C4540,
          numberColor: 0xFFA87068,
          headerColor: 0xFFC09080,
          isPreset: true,
        ),
        CardStyle(
          styleName: '暮色',
          styleType: StyleType.gradient,
          backgroundColor: 0xFF2A2438,
          gradientColors: [0xFF2A2438, 0xFF352F44],
          textColor: 0xFFD8D0E4,
          numberColor: 0xFFB8A8D0,
          headerColor: 0xFF7B6E92,
          isPreset: true,
        ),
      ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CardStyle &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

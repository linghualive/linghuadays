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
          styleName: '简约',
          styleType: StyleType.simple,
          backgroundColor: 0xFFF5F5F5,
          textColor: 0xFF212121,
          numberColor: 0xFF1565C0,
          fontFamily: 'default',
          cardBorderRadius: 16.0,
          isPreset: true,
        ),
        CardStyle(
          styleName: '渐变',
          styleType: StyleType.gradient,
          backgroundColor: 0xFF6A1B9A,
          gradientColors: [0xFF6A1B9A, 0xFFE91E63],
          textColor: 0xFFFFFFFF,
          numberColor: 0xFFFFFFFF,
          fontFamily: 'default',
          cardBorderRadius: 20.0,
          isPreset: true,
        ),
        CardStyle(
          styleName: '玻璃拟态',
          styleType: StyleType.glass,
          backgroundColor: 0x80FFFFFF,
          textColor: 0xFF212121,
          numberColor: 0xFF1565C0,
          fontFamily: 'default',
          cardBorderRadius: 24.0,
          isPreset: true,
        ),
        CardStyle(
          styleName: '卡片阴影',
          styleType: StyleType.shadow,
          backgroundColor: 0xFFFFFFFF,
          textColor: 0xFF424242,
          numberColor: 0xFF37474F,
          fontFamily: 'default',
          cardBorderRadius: 12.0,
          isPreset: true,
        ),
        CardStyle(
          styleName: '深邃',
          styleType: StyleType.neon,
          backgroundColor: 0xFF0D0D0D,
          textColor: 0xFFE0E0E0,
          numberColor: 0xFF00E5FF,
          fontFamily: 'default',
          cardBorderRadius: 16.0,
          isPreset: true,
        ),
        CardStyle(
          styleName: '手绘',
          styleType: StyleType.handdrawn,
          backgroundColor: 0xFFFFF8E1,
          textColor: 0xFF5D4037,
          numberColor: 0xFF3E2723,
          fontFamily: 'default',
          cardBorderRadius: 8.0,
          isPreset: true,
        ),
        CardStyle(
          styleName: '节日',
          styleType: StyleType.festival,
          backgroundColor: 0xFFB71C1C,
          gradientColors: [0xFFB71C1C, 0xFFD32F2F],
          textColor: 0xFFFFD54F,
          numberColor: 0xFFFFD54F,
          fontFamily: 'default',
          cardBorderRadius: 16.0,
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

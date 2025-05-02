import "dart:ui";

import "package:flutter/material.dart";
import "package:zo/src/base/types/types.dart";

/// 扩展 BuildContext, 用于更方便的获取 style
extension ZoStyleContext on BuildContext {
  ZoStyle get zoStyle => Theme.of(this).extension<ZoStyle>()!;
  ThemeData get zoTheme => Theme.of(this);
  TextTheme get zoTextTheme => Theme.of(this).textTheme;
}

/// Zo 基础样式配置
///
/// 除了 textTheme 外的大部分 material3 样式都做了覆盖, 通过 context.zoStyle 使用, 对于未覆盖的样式仍可通过 context.zoTheme 或 context.zoTextTheme 原样访问
///
/// 约定:
/// - *Variant 后缀: 特定样式的变体, 可能用于改样式某种状态下的样式
class ZoStyle extends ThemeExtension<ZoStyle> {
  ZoStyle({
    required this.brightness,
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.cyan,
    this.tertiaryColor = Colors.red,

    this.alpha = 160,
    Color? barrierColor,
    Color? primaryTextColor,
    Color? hintTextColor,
    Color? surfaceColor,
    Color? surfaceContainerColor,
    Color? surfaceGrayColor,
    Color? surfaceGrayColorVariant,
    this.infoColor = Colors.blue,
    this.successColor = Colors.green,
    this.warningColor = Colors.orange,
    this.errorColor = Colors.red,
    Color? focusColor,
    Color? hoverColor,
    Color? highlightColor,
    Color? disabledColor,
    Color? outlineColor,
    Color? outlineColorVariant,
    Color? shadowColor,
    Color? shadowColorVariant,

    this.elevation = 4,
    this.elevationDrawer = 8,
    this.elevationModal = 12,
    this.elevationMessage = 16,

    this.space1 = 4,
    this.space2 = 8,
    this.space3 = 12,
    this.space4 = 16,
    this.space5 = 20,
    this.space6 = 24,
    this.space7 = 28,
    this.space8 = 32,
    this.space9 = 36,
    this.space10 = 40,

    this.smallSize = 28,
    this.mediumSize = 34,
    this.largeSize = 40,
    this.borderRadius = 8,

    this.breakPointSM = 576,
    this.breakPointMD = 768,
    this.breakPointLG = 992,
    this.breakPointXL = 1200,
    this.breakPointXXL = 1600,
  }) {
    var darkMode = brightness == Brightness.dark;

    this.barrierColor =
        barrierColor ??
        (darkMode ? Colors.black.withAlpha(200) : Colors.white.withAlpha(200));
    this.surfaceColor =
        surfaceColor ?? (darkMode ? Colors.grey[850]! : Colors.white);
    this.surfaceContainerColor =
        surfaceContainerColor ?? (darkMode ? Colors.grey[900]! : Colors.white);
    this.surfaceGrayColor =
        surfaceGrayColor ??
        (darkMode ? Colors.white.withAlpha(20) : Colors.black.withAlpha(10));
    this.surfaceGrayColorVariant =
        surfaceGrayColorVariant ??
        (darkMode ? Colors.white.withAlpha(40) : Colors.black.withAlpha(20));

    this.primaryTextColor =
        primaryTextColor ??
        (darkMode ? Colors.white.withAlpha(200) : Colors.black.withAlpha(180));

    this.hintTextColor =
        hintTextColor ??
        (darkMode ? Colors.white.withAlpha(110) : Colors.black.withAlpha(90));

    this.outlineColor =
        outlineColor ??
        (darkMode ? Colors.white.withAlpha(40) : Colors.black.withAlpha(30));
    this.outlineColorVariant =
        outlineColorVariant ??
        (darkMode ? Colors.white.withAlpha(76) : Colors.black.withAlpha(66));
    this.shadowColor =
        shadowColor ?? (darkMode ? Colors.black : Colors.black.withAlpha(138));
    this.shadowColorVariant =
        shadowColorVariant ??
        (darkMode ? Colors.black : Colors.black.withAlpha(168));
    this.focusColor =
        focusColor ??
        (darkMode ? Colors.white.withAlpha(25) : Colors.black.withAlpha(20));
    this.hoverColor =
        hoverColor ??
        (darkMode ? Colors.white.withAlpha(30) : Colors.black.withAlpha(15));
    this.highlightColor =
        highlightColor ??
        (darkMode ? Colors.white.withAlpha(35) : Colors.black.withAlpha(25));
    this.disabledColor =
        disabledColor ??
        (darkMode ? Colors.white.withAlpha(25) : Colors.black.withAlpha(20));
  }

  /// 控制是否为暗黑模式
  Brightness brightness;

  // # # # # # # # widget # # # # # # #
  // emptyNode, errorNode, loadingNode,

  // # # # # # # # 颜色 # # # # # # #

  /// 通用透明度
  final int alpha;

  /// 主色
  final Color primaryColor;

  /// 次要色
  final Color secondaryColor;

  /// 第三色
  final Color tertiaryColor;

  /// 遮罩颜色
  late final Color barrierColor;

  /// 界面中使用最多的主要文本色
  late final Color primaryTextColor;

  /// 提示文本色
  late final Color hintTextColor;

  /// 大范围容器表面色
  late final Color surfaceColor;

  /// 组件表面色 (大部分组件可能不需要表面色, 与背景一致即可)
  late final Color surfaceContainerColor;

  /// 用于部分组件的浅灰色背景
  late final Color surfaceGrayColor;

  /// 用于部分组件的浅灰色背景
  late final Color surfaceGrayColorVariant;

  /// 表示强调的信息色
  final Color infoColor;

  /// 表示成功的信息色
  final Color successColor;

  /// 表示警告的信息色
  final Color warningColor;

  /// 表示错误的信息色
  final Color errorColor;

  /// 聚焦色
  late final Color focusColor;

  /// 悬停色
  late final Color hoverColor;

  /// 高亮色
  late final Color highlightColor;

  /// 禁用色
  late final Color disabledColor;

  /// 边框
  late final Color outlineColor;
  late final Color outlineColorVariant;

  /// 阴影
  late final Color shadowColor;
  late final Color shadowColorVariant;

  // # # # # # # # 层级 # # # # # # #
  /// 用于高于常规层的普通装饰
  final double elevation;

  /// 用于 drawer / sheet / popover 类组件的层级
  final double elevationDrawer;

  /// 用于模态类组件的层级
  final double elevationModal;

  /// 用于消息类的层级
  final double elevationMessage;

  // # # # # # # # 尺寸 & 距离 # # # # # # #

  final double space1;
  final double space2;
  final double space3;
  final double space4;
  final double space5;
  final double space6;
  final double space7;
  final double space8;
  final double space9;
  final double space10;

  /// 对应 [ZoSize] small 的尺寸
  final double smallSize;

  /// 对应 [ZoSize] medium 的尺寸
  final double mediumSize;

  /// 对应 [ZoSize] large 的尺寸
  final double largeSize;

  /// 圆角
  final double borderRadius;

  // # # # # # # # 媒体查询断点: # # # # # # #

  /// 媒体查询断点: 小屏
  final double breakPointSM;

  /// 媒体查询断点: 中屏
  final double breakPointMD;

  /// 媒体查询断点: 大屏
  final double breakPointLG;

  /// 媒体查询断点: 超大屏
  final double breakPointXL;

  /// 媒体查询断点: 超大屏+
  final double breakPointXXL;

  /// 根据当前配置获取 ThemeData, 若传入 theme, 会复制此 theme 后覆盖生成
  ThemeData toThemeData({ThemeData? theme}) {
    theme = theme ?? ThemeData();

    return theme.copyWith(
      scaffoldBackgroundColor: surfaceColor,
      colorScheme: ColorScheme.fromSeed(
        brightness: brightness,
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        tertiary: tertiaryColor,
        surface: surfaceColor,
        surfaceContainer: surfaceContainerColor,
        shadow: shadowColor,
        outline: outlineColor,
        outlineVariant: outlineColorVariant,
      ),
      dividerTheme: DividerThemeData(color: outlineColor),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: primaryTextColor),
        bodyMedium: TextStyle(color: primaryTextColor),
        bodySmall: TextStyle(color: primaryTextColor),
      ),
      hintColor: hintTextColor,
      dividerColor: outlineColor,
      shadowColor: shadowColor,
      focusColor: focusColor,
      hoverColor: hoverColor,
      highlightColor: highlightColor,
      disabledColor: disabledColor,
      extensions: [this],
    );
  }

  @override
  ZoStyle copyWith({
    Brightness? brightness,
    Color? primaryColor,
    Color? secondaryColor,
    Color? tertiaryColor,
    int? alpha,
    Color? barrierColor,
    Color? primaryTextColor,
    Color? hintTextColor,
    Color? surfaceColor,
    Color? surfaceContainerColor,
    Color? surfaceGrayColor,
    Color? infoColor,
    Color? successColor,
    Color? warningColor,
    Color? errorColor,
    Color? focusColor,
    Color? hoverColor,
    Color? highlightColor,
    Color? disabledColor,
    Color? outlineColor,
    Color? outlineColorVariant,
    Color? shadowColor,
    Color? shadowColorVariant,
    double? elevation,
    double? elevationDrawer,
    double? elevationModal,
    double? elevationMessage,
    double? space1,
    double? space2,
    double? space3,
    double? space4,
    double? space5,
    double? space6,
    double? space7,
    double? space8,
    double? space9,
    double? space10,
    double? smallSize,
    double? mediumSize,
    double? largeSize,
    double? borderRadius,
    double? breakPointSM,
    double? breakPointMD,
    double? breakPointLG,
    double? breakPointXL,
    double? breakPointXXL,
  }) {
    return ZoStyle(
      brightness: brightness ?? this.brightness,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      tertiaryColor: tertiaryColor ?? this.tertiaryColor,
      alpha: alpha ?? this.alpha,
      barrierColor: barrierColor ?? this.barrierColor,
      primaryTextColor: primaryTextColor ?? this.primaryTextColor,
      hintTextColor: hintTextColor ?? this.hintTextColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      surfaceContainerColor:
          surfaceContainerColor ?? this.surfaceContainerColor,
      surfaceGrayColor: surfaceGrayColor ?? this.surfaceGrayColor,
      infoColor: infoColor ?? this.infoColor,
      successColor: successColor ?? this.successColor,
      warningColor: warningColor ?? this.warningColor,
      errorColor: errorColor ?? this.errorColor,
      focusColor: focusColor ?? this.focusColor,
      hoverColor: hoverColor ?? this.hoverColor,
      highlightColor: highlightColor ?? this.highlightColor,
      disabledColor: disabledColor ?? this.disabledColor,
      outlineColor: outlineColor ?? this.outlineColor,
      outlineColorVariant: outlineColorVariant ?? this.outlineColorVariant,
      shadowColor: shadowColor ?? this.shadowColor,
      shadowColorVariant: shadowColorVariant ?? this.shadowColorVariant,
      elevation: elevation ?? this.elevation,
      elevationDrawer: elevationDrawer ?? this.elevationDrawer,
      elevationModal: elevationModal ?? this.elevationModal,
      elevationMessage: elevationMessage ?? this.elevationMessage,
      space1: space1 ?? this.space1,
      space2: space2 ?? this.space2,
      space3: space3 ?? this.space3,
      space4: space4 ?? this.space4,
      space5: space5 ?? this.space5,
      space6: space6 ?? this.space6,
      space7: space7 ?? this.space7,
      space8: space8 ?? this.space8,
      space9: space9 ?? this.space9,
      space10: space10 ?? this.space10,
      smallSize: smallSize ?? this.smallSize,
      mediumSize: mediumSize ?? this.mediumSize,
      largeSize: largeSize ?? this.largeSize,
      borderRadius: borderRadius ?? this.borderRadius,
      breakPointSM: breakPointSM ?? this.breakPointSM,
      breakPointMD: breakPointMD ?? this.breakPointMD,
      breakPointLG: breakPointLG ?? this.breakPointLG,
      breakPointXL: breakPointXL ?? this.breakPointXL,
      breakPointXXL: breakPointXXL ?? this.breakPointXXL,
    );
  }

  @override
  ZoStyle lerp(ThemeExtension<ZoStyle>? other, double t) {
    if (other is! ZoStyle) return this;
    return ZoStyle(
      brightness: other.brightness,
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      secondaryColor: Color.lerp(secondaryColor, other.secondaryColor, t)!,
      tertiaryColor: Color.lerp(tertiaryColor, other.tertiaryColor, t)!,
      alpha: other.alpha,
      barrierColor: Color.lerp(barrierColor, other.barrierColor, t),
      primaryTextColor: Color.lerp(primaryTextColor, other.primaryTextColor, t),
      hintTextColor: Color.lerp(hintTextColor, other.hintTextColor, t),
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t),
      surfaceContainerColor: Color.lerp(
        surfaceContainerColor,
        other.surfaceContainerColor,
        t,
      ),
      surfaceGrayColor: Color.lerp(surfaceGrayColor, other.surfaceGrayColor, t),
      infoColor: Color.lerp(infoColor, other.infoColor, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
      errorColor: Color.lerp(errorColor, other.errorColor, t)!,
      focusColor: Color.lerp(focusColor, other.focusColor, t),
      hoverColor: Color.lerp(hoverColor, other.hoverColor, t),
      highlightColor: Color.lerp(highlightColor, other.highlightColor, t),
      disabledColor: Color.lerp(disabledColor, other.disabledColor, t),
      outlineColor: Color.lerp(outlineColor, other.outlineColor, t),
      outlineColorVariant: Color.lerp(
        outlineColorVariant,
        other.outlineColorVariant,
        t,
      ),
      shadowColor: Color.lerp(shadowColor, other.shadowColor, t),
      shadowColorVariant:
          Color.lerp(shadowColorVariant, other.shadowColorVariant, t)!,
      elevation: lerpDouble(elevation, other.elevation, t)!,
      elevationDrawer: lerpDouble(elevationDrawer, other.elevationDrawer, t)!,
      elevationModal: lerpDouble(elevationModal, other.elevationModal, t)!,
      elevationMessage:
          lerpDouble(elevationMessage, other.elevationMessage, t)!,
      space1: lerpDouble(space1, other.space1, t)!,
      space2: lerpDouble(space2, other.space2, t)!,
      space3: lerpDouble(space3, other.space3, t)!,
      space4: lerpDouble(space4, other.space4, t)!,
      space5: lerpDouble(space5, other.space5, t)!,
      space6: lerpDouble(space6, other.space6, t)!,
      space7: lerpDouble(space7, other.space7, t)!,
      space8: lerpDouble(space8, other.space8, t)!,
      space9: lerpDouble(space9, other.space9, t)!,
      space10: lerpDouble(space10, other.space10, t)!,
      smallSize: lerpDouble(smallSize, other.smallSize, t)!,
      mediumSize: lerpDouble(mediumSize, other.mediumSize, t)!,
      largeSize: lerpDouble(largeSize, other.largeSize, t)!,
      borderRadius: lerpDouble(borderRadius, other.borderRadius, t)!,
      breakPointSM: other.breakPointSM,
      breakPointMD: other.breakPointMD,
      breakPointLG: other.breakPointLG,
      breakPointXL: other.breakPointXL,
      breakPointXXL: other.breakPointXXL,
    );
  }
}

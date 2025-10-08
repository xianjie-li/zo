import "package:flutter/material.dart";
import "package:zo/src/base/types/types.dart";

/// 扩展 BuildContext, 用于更方便的获取 style
extension ZoStyleContext on BuildContext {
  ZoStyle get zoStyle => Theme.of(this).extension<ZoStyle>()!;
}

/// Zo 基础样式配置
///
/// 有两种使用方式:
/// - 通过 [toThemeData] 转换为 ThemeData 直接使用, 它会将相关样式覆盖为 ZoStyle 提供的样式,
/// 并将 ZoStyle 设置为 extensions
/// - 直接将 ZoStyle 作为 ThemeData 的 extensions 来使用
///
/// 约定:
/// - *Variant 后缀: 特定样式的变体, 可能用于改样式某种状态下的样式
class ZoStyle extends ThemeExtension<ZoStyle> {
  ZoStyle({
    required this.brightness,
    this.alpha = 160,
    this.primaryColor = Colors.blue,
    this.secondaryColor = Colors.cyan,
    this.tertiaryColor = Colors.red,
    Color? barrierColor,
    Color? surfaceColor,
    Color? surfaceContainerColor,
    Color? surfaceGrayColor,
    Color? surfaceGrayColorVariant,
    Color? titleTextColor,
    Color? textColor,
    Color? hintTextColor,
    Color? disabledTextColor,
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
    BoxShadow? shadow,
    BoxShadow? shadowVariant,
    BoxShadow? overlayShadow,
    BoxShadow? overlayShadowVariant,
    BoxShadow? modalShadow,
    BoxShadow? modalShadowVariant,

    this.fontSizeSM = 12,
    this.fontSize = 14,
    this.fontSizeMD = 16,
    this.fontSizeLG = 20,
    this.fontSizeXL = 24,

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

    this.sizeSM = 28,
    this.sizeMD = 34,
    this.sizeLG = 40,
    this.borderRadius = 10,
    this.borderRadiusLG = 18,

    this.breakPointSM = 576,
    this.breakPointMD = 768,
    this.breakPointLG = 992,
    this.breakPointXL = 1200,
    this.breakPointXXL = 1600,
  }) {
    final darkMode = brightness == Brightness.dark;

    this.barrierColor =
        barrierColor ??
        (darkMode
            ? Colors.grey[900]!.withAlpha(200)
            : Colors.white.withAlpha(200));

    this.surfaceColor =
        surfaceColor ?? (darkMode ? Colors.grey[850]! : Colors.white);
    this.surfaceContainerColor =
        surfaceContainerColor ?? (darkMode ? Colors.grey[900]! : Colors.white);
    this.surfaceGrayColor =
        surfaceGrayColor ?? (darkMode ? Colors.grey[900]! : Colors.grey[50]!);
    this.surfaceGrayColorVariant =
        surfaceGrayColorVariant ??
        (darkMode ? Colors.blueGrey[900]! : Colors.blueGrey[50]!);
    this.titleTextColor =
        titleTextColor ??
        (darkMode ? Colors.white.withAlpha(220) : Colors.black.withAlpha(200));
    this.textColor =
        textColor ??
        (darkMode ? Colors.white.withAlpha(200) : Colors.black.withAlpha(160));
    this.hintTextColor =
        hintTextColor ??
        (darkMode ? Colors.white.withAlpha(110) : Colors.black.withAlpha(90));
    this.disabledTextColor =
        disabledTextColor ??
        (darkMode ? Colors.white.withAlpha(70) : Colors.black.withAlpha(50));
    this.outlineColor =
        outlineColor ??
        (darkMode ? const Color(0xFF464646) : const Color(0xFFE5E5E5));
    this.outlineColorVariant =
        outlineColorVariant ??
        (darkMode ? Colors.grey[700]! : const Color(0xFFC6C6C6));
    this.shadowColor =
        shadowColor ?? (darkMode ? Colors.black : Colors.black.withAlpha(36));
    this.shadowColorVariant =
        shadowColorVariant ??
        (darkMode ? Colors.black : Colors.black.withAlpha(56));

    this.shadow = BoxShadow(
      color: this.shadowColor,
      blurRadius: 8,
      offset: const Offset(1, 1),
    );
    this.shadowVariant = BoxShadow(
      color: this.shadowColorVariant,
      blurRadius: 8,
      offset: const Offset(1, 1),
    );
    this.overlayShadow = BoxShadow(
      color: this.shadowColor,
      blurRadius: 16,
      offset: const Offset(2, 2),
    );
    this.overlayShadowVariant = BoxShadow(
      color: this.shadowColorVariant,
      blurRadius: 16,
      offset: const Offset(2, 2),
    );
    this.modalShadow = BoxShadow(
      color: this.shadowColor,
      blurRadius: 24,
      offset: const Offset(3, 3),
    );
    this.modalShadowVariant = BoxShadow(
      color: this.shadowColorVariant,
      blurRadius: 24,
      offset: const Offset(3, 3),
    );

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

  /// 与当前style的brightness相反的样式, 在亮色主题下, 它对应暗色主题
  /// 使用者需要在初始化style实例后调用 [connectReverse] 方法来连接两者, 如果没有进行连接,
  /// 会返回默认的反向样式
  ZoStyle get reverseStyle {
    _reverseStyle ??= ZoStyle(
      brightness: brightness == Brightness.dark
          ? Brightness.light
          : Brightness.dark,
    );
    return _reverseStyle!;
  }

  ZoStyle? _reverseStyle;

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

  /// 大范围容器表面色
  late final Color surfaceColor;

  /// 组件表面色 (大部分组件可能不需要表面色, 与背景一致即可)
  late final Color surfaceContainerColor;

  /// 用于部分组件的浅色背景
  late final Color surfaceGrayColor;

  /// 用于部分组件的浅色背景
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

  /// 用于高于常规层的阴影
  late final BoxShadow shadow;
  late final BoxShadow shadowVariant;

  /// 用于 drawer / sheet / popover 类组件的阴影
  late final BoxShadow overlayShadow;
  late final BoxShadow overlayShadowVariant;

  /// 用于模态框类组件的阴影
  late final BoxShadow modalShadow;
  late final BoxShadow modalShadowVariant;

  // # # # # # # # 文字 # # # # # # #

  /// 标题文本色
  late final Color titleTextColor;

  /// 界面中最常见的主要文本色
  late final Color textColor;

  /// 提示文本色
  late final Color hintTextColor;

  /// 禁用文本色
  late final Color disabledTextColor;

  /// 小号文本
  final double fontSizeSM;

  /// 常规文本
  final double fontSize;

  /// 中号文本
  final double fontSizeMD;

  /// 大号文本
  final double fontSizeLG;

  /// 超大号文本
  final double fontSizeXL;

  TextStyle get titleStyle => TextStyle(
    color: titleTextColor,
    fontSize: fontSizeMD,
  );

  TextStyle get textStyle => TextStyle(
    color: textColor,
    fontSize: fontSize,
  );

  TextStyle get hintTextStyle => TextStyle(
    color: hintTextColor,
    fontSize: fontSize,
  );

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
  final double sizeSM;

  /// 对应 [ZoSize] medium 的尺寸
  final double sizeMD;

  /// 对应 [ZoSize] large 的尺寸
  final double sizeLG;

  /// 圆角
  final double borderRadius;

  /// 更大的圆角
  final double borderRadiusLG;

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

  /// 如果应用实现了亮/暗两种style, 需要在两者创建完成后调用一次 connectReverse 方法来进行连接
  void connectReverse(ZoStyle reverseStyle) {
    reverseStyle._reverseStyle = this;
    _reverseStyle = reverseStyle;
  }

  /// 主动获取指定的明暗主题
  ZoStyle getSpecifiedTheme(Brightness brightness) {
    return this.brightness == brightness ? this : reverseStyle;
  }

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
        // shadow: shadowColor, 不改写预置组件阴影色
        outline: outlineColor,
        outlineVariant: outlineColorVariant,
      ),
      iconTheme: IconThemeData(color: textColor),
      dividerTheme: DividerThemeData(color: outlineColor),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textColor, fontSize: fontSizeMD),
        bodyMedium: TextStyle(color: textColor, fontSize: fontSize),
        bodySmall: TextStyle(color: textColor, fontSize: fontSizeSM),
        titleLarge: TextStyle(color: titleTextColor, fontSize: fontSizeMD),
        titleMedium: TextStyle(color: titleTextColor, fontSize: fontSizeMD),
        titleSmall: TextStyle(color: titleTextColor, fontSize: fontSizeMD),
      ),
      switchTheme: brightness == Brightness.dark
          ? null
          // 默认边框色会导致亮色下 Switch 默认状态 thumb 不可见, 需要覆盖颜色
          : SwitchThemeData(
              thumbColor: WidgetStateProperty.fromMap({
                WidgetState.selected: surfaceContainerColor,
                WidgetState.hovered: hoverColor,
                WidgetState.focused: focusColor,
                WidgetState.disabled: disabledColor,
                WidgetState.any: surfaceColor,
              }),
            ),
      hintColor: hintTextColor,
      dividerColor: outlineColor,
      // shadowColor: shadowColor, 不改写预置组件阴影色
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
    Color? titleTextColor,
    Color? textColor,
    Color? hintTextColor,
    Color? disabledTextColor,
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
    BoxShadow? shadow,
    BoxShadow? shadowVariant,
    BoxShadow? overlayShadow,
    BoxShadow? overlayShadowVariant,
    BoxShadow? modalShadow,
    BoxShadow? modalShadowVariant,
    double? fontSizeSM,
    double? fontSize,
    double? fontSizeMD,
    double? fontSizeLG,
    double? fontSizeXL,
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
    double? sizeSM,
    double? sizeMD,
    double? sizeLG,
    double? borderRadius,
    double? borderRadiusLG,
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
      titleTextColor: titleTextColor ?? this.titleTextColor,
      textColor: textColor ?? this.textColor,
      hintTextColor: hintTextColor ?? this.hintTextColor,
      disabledTextColor: disabledTextColor ?? this.disabledTextColor,
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
      shadow: shadow ?? this.shadow,
      shadowVariant: shadowVariant ?? this.shadowVariant,
      overlayShadow: overlayShadow ?? this.overlayShadow,
      overlayShadowVariant: overlayShadowVariant ?? this.overlayShadowVariant,
      modalShadow: modalShadow ?? this.modalShadow,
      modalShadowVariant: modalShadowVariant ?? this.modalShadowVariant,
      fontSizeSM: fontSizeSM ?? this.fontSizeSM,
      fontSize: fontSize ?? this.fontSize,
      fontSizeMD: fontSizeMD ?? this.fontSizeMD,
      fontSizeLG: fontSizeLG ?? this.fontSizeLG,
      fontSizeXL: fontSizeXL ?? this.fontSizeXL,
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
      sizeSM: sizeSM ?? this.sizeSM,
      sizeMD: sizeMD ?? this.sizeMD,
      sizeLG: sizeLG ?? this.sizeLG,
      borderRadius: borderRadius ?? this.borderRadius,
      borderRadiusLG: borderRadiusLG ?? this.borderRadiusLG,
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

    // 通常只有颜色类的需要添加线性插值, 其他内容在切换主题时是不需要动画的
    return ZoStyle(
      brightness: other.brightness,
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t)!,
      secondaryColor: Color.lerp(secondaryColor, other.secondaryColor, t)!,
      tertiaryColor: Color.lerp(tertiaryColor, other.tertiaryColor, t)!,
      alpha: other.alpha,
      barrierColor: Color.lerp(barrierColor, other.barrierColor, t),
      titleTextColor: Color.lerp(titleTextColor, other.titleTextColor, t),
      textColor: Color.lerp(textColor, other.textColor, t),
      hintTextColor: Color.lerp(hintTextColor, other.hintTextColor, t),
      disabledTextColor: Color.lerp(
        disabledTextColor,
        other.disabledTextColor,
        t,
      ),
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
      shadowColor: other.shadowColor,
      shadowColorVariant: other.shadowColorVariant,
      shadow: other.shadow,
      shadowVariant: other.shadowVariant,
      overlayShadow: other.overlayShadow,
      overlayShadowVariant: other.overlayShadowVariant,
      modalShadow: other.modalShadow,
      modalShadowVariant: other.modalShadowVariant,
      fontSizeSM: other.fontSizeSM,
      fontSize: other.fontSize,
      fontSizeMD: other.fontSizeMD,
      fontSizeLG: other.fontSizeLG,
      fontSizeXL: other.fontSizeXL,
      space1: other.space1,
      space2: other.space2,
      space3: other.space3,
      space4: other.space4,
      space5: other.space5,
      space6: other.space6,
      space7: other.space7,
      space8: other.space8,
      space9: other.space9,
      space10: other.space10,
      sizeSM: other.sizeSM,
      sizeMD: other.sizeMD,
      sizeLG: other.sizeLG,
      borderRadius: other.borderRadius,
      borderRadiusLG: other.borderRadiusLG,
      breakPointSM: other.breakPointSM,
      breakPointMD: other.breakPointMD,
      breakPointLG: other.breakPointLG,
      breakPointXL: other.breakPointXL,
      breakPointXXL: other.breakPointXXL,
    );
  }
}

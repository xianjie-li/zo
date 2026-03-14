import "package:flutter/material.dart";
import "package:zo/zo.dart";

/// 标签的视觉类型。
///
/// 用于控制标签的前景色、背景色和边框表现方式。
enum ZoTagType {
  /// 实心标签。
  ///
  /// 使用纯色背景强调标签轮廓，文本以白色显示在高对比度前景色上。
  solid,

  /// 描边标签。
  ///
  /// 使用边框强调标签轮廓，文本颜色与边框颜色保持一致。
  outline,

  /// 浅底标签。
  ///
  /// 文本使用前景色，背景使用该颜色的浅色透明版本来形成轻量强调。
  plain,
}

/// 轻量级标签组件。
///
/// 常用于展示状态、分类、属性等简短信息，支持：
/// - 通过 [type] 切换不同视觉风格
/// - 通过 [size] 适配不同密度场景
/// - 通过 [color] 自定义主题色
/// - 通过 [backgroundAlpha] 和 [borderRadius] 微调外观
class ZoTag extends StatelessWidget {
  const ZoTag({
    super.key,
    required this.child,
    this.type = ZoTagType.plain,
    this.color,
    this.size,
    this.height,
    this.textStyle,
    this.backgroundAlpha,
    this.borderRadius,
  });

  /// 标签内容。
  ///
  /// 可以是文本，也可以是图标和文本的组合。
  final Widget child;

  /// 标签类型。
  final ZoTagType type;

  /// 标签主色。
  ///
  /// - `solid` 模式下通常作为背景色
  /// - `outline` / `plain` 模式下通常作为前景色来源
  /// - 未传时会退回到组件默认语义颜色
  final Color? color;

  /// 标签尺寸。
  ///
  /// 未传时使用当前 `ZoStyle.widgetSize`。
  final ZoSize? size;

  /// 标签高度。
  ///
  /// 传入后会直接使用该高度；未传时按 [size] 从 `ZoStyle` 推导默认高度。
  final double? height;

  /// 标签内容的文本样式。
  ///
  /// 会在组件默认文字样式基础上进行合并。
  final TextStyle? textStyle;

  /// 自定义浅色背景的不透明度。
  ///
  /// 仅对 `outline` 和 `plain` 类型的浅色背景生效：
  /// - 当 [color] 不为空时，默认值为 `40`
  /// - 当 [color] 为空时，默认值为 `16`
  final int? backgroundAlpha;

  /// 自定义标签圆角。
  ///
  /// 未传时使用 `ZoStyle.borderRadiusSM`。
  final double? borderRadius;

  @override
  Widget build(BuildContext context) {
    final style = context.zoStyle;

    final padding = style.getSizedSpace(size);

    final currentHeight = height ?? style.getSizedSmallExtent(size) + 2;

    Color? borderColor;
    Color? backgroundColor;
    Color? textColor;

    final curAlpha = backgroundAlpha ?? (color == null ? 16 : 40);

    if (type == ZoTagType.solid) {
      backgroundColor = color ?? style.primaryColor;
      textColor = style.darkStyle.titleTextColor;
    } else if (type == ZoTagType.outline) {
      borderColor = color ?? style.outlineColor;
      textColor = color ?? style.textColor;

      backgroundColor = color != null
          ? textColor.withAlpha(curAlpha)
          : style.surfaceColor;
    } else {
      textColor = color ?? style.textColor;

      backgroundColor = textColor.withAlpha(curAlpha);
    }

    final fontSize = style.getSizedFontSize(size);

    return DefaultTextStyle(
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
      ).merge(textStyle),
      child: IconTheme(
        data: IconThemeData(color: textColor, size: fontSize),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: padding),
          height: currentHeight,
          decoration: BoxDecoration(
            color: backgroundColor,
            border: borderColor != null ? Border.all(color: borderColor) : null,
            borderRadius: BorderRadius.circular(
              borderRadius ?? style.borderRadiusSM,
            ),
          ),
          child: Center(widthFactor: 1, child: child),
        ),
      ),
    );
  }
}

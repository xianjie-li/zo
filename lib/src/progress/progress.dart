import "package:flutter/material.dart";
import "package:zo/zo.dart";

enum ZoProgressType {
  /// 圆形指示器
  circle,

  /// 线性进度条
  linear,
}

/// 进度或加载状态显示
class ZoProgress extends StatelessWidget {
  const ZoProgress({
    super.key,
    this.open = true,
    this.value,
    this.text,
    this.inline = false,
    this.size = ZoSize.medium,
    this.child,
    this.alignment = Alignment.center,
    this.type = ZoProgressType.circle,
  });

  /// 是否显示
  final bool open;

  /// 进度, 不传时使用非确定进度
  final double? value;

  /// 提示文本, 仅 circle 指示器有效
  final Widget? text;

  /// 将text和加载指示器内联对齐
  final bool inline;

  /// 尺寸
  final ZoSize size;

  /// 使用此组件包裹指定节点, 作为其容器覆盖child, 实现遮挡展示加载状态
  final Widget? child;

  /// 配置了child时的对齐方式
  final AlignmentGeometry alignment;

  /// 显示类型
  final ZoProgressType type;

  Widget buildCircle(ZoStyle style) {
    BoxConstraints? constraints;
    double strokeWidth = 8;

    if (size == ZoSize.small) {
      constraints = BoxConstraints(
        minWidth: 24,
        minHeight: 24,
        maxWidth: 24,
        maxHeight: 24,
      );
      strokeWidth = 5;
    } else if (size == ZoSize.large) {
      constraints = BoxConstraints(
        minWidth: 60,
        minHeight: 60,
        maxWidth: 60,
        maxHeight: 60,
      );
      strokeWidth = 12;
    }

    return CircularProgressIndicator(
      value: value,
      backgroundColor: style.surfaceGrayColorVariant,
      trackGap: 0,
      strokeWidth: strokeWidth,
      constraints: constraints,
      year2023: false,
    );
  }

  Widget buildLinear(ZoStyle style) {
    double minHeight = switch (size) {
      ZoSize.small => 4,
      ZoSize.medium => 8,
      ZoSize.large => 12,
    };

    return LinearProgressIndicator(
      value: value,
      trackGap: 0,
      backgroundColor: style.surfaceGrayColorVariant,
      stopIndicatorColor: Colors.transparent,
      minHeight: minHeight,
      borderRadius: BorderRadius.circular(12),
      year2023: false,
    );
  }

  Widget withText(ZoStyle style, TextTheme textTheme, Widget child) {
    if (text == null || type != ZoProgressType.circle) return child;

    double? fontSize = switch (size) {
      ZoSize.small => textTheme.bodySmall!.fontSize!,
      ZoSize.medium => null,
      ZoSize.large => textTheme.bodyLarge!.fontSize!,
    };

    var styledText = DefaultTextStyle(
      style: TextStyle(color: style.hintTextColor, fontSize: fontSize),
      child: text!,
    );

    if (inline) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        spacing: style.space1,
        children: [child, styledText],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: style.space1,
      children: [child, styledText],
    );
  }

  Widget withContainer(ZoStyle style, Widget child) {
    if (this.child == null) return child;

    return Stack(
      children: [
        this.child!,
        if (open)
          Positioned.fill(
            child: Container(
              padding:
                  type == ZoProgressType.linear
                      ? EdgeInsets.all(style.space2)
                      : null,
              alignment: alignment,
              color: style.barrierColor,
              child: child,
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!open) return child ?? const SizedBox();

    var style = context.zoStyle;
    var textTheme = context.zoTextTheme;

    var node = switch (type) {
      ZoProgressType.circle => buildCircle(style),
      ZoProgressType.linear => buildLinear(style),
    };

    node = withText(style, textTheme, node);
    node = withContainer(style, node);

    return node;
  }
}

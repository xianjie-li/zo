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
    this.barrier = true,
    this.alignment = Alignment.center,
    this.type = ZoProgressType.circle,
    this.borderRadius,
    this.indicator,
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

  /// 使用 child 实现覆盖加载时, 是否显示遮罩, 不显示时, 内容仍能正常交互
  final bool barrier;

  /// 配置了child时的对齐方式
  final AlignmentGeometry alignment;

  /// 显示类型
  final ZoProgressType type;

  /// 设置了 child 作为容器时, 如果子级包含圆角裁剪, 可通过此项指定容器的圆角
  final BorderRadiusGeometry? borderRadius;

  /// 传入后会忽略 type, 并将其作为加载指示器显示
  final Widget? indicator;

  Widget buildCircle(ZoStyle style) {
    BoxConstraints? constraints;
    double strokeWidth = 8;

    if (size == ZoSize.small) {
      final size = style.sizeSM - style.space3;

      constraints = BoxConstraints(
        minWidth: size,
        minHeight: size,
        maxWidth: size,
        maxHeight: size,
      );
      strokeWidth = 4;
    } else if (size == ZoSize.large) {
      constraints = const BoxConstraints(
        minWidth: 60,
        minHeight: 60,
        maxWidth: 60,
        maxHeight: 60,
      );
      strokeWidth = 12;
    }

    return CircularProgressIndicator(
      value: value,
      backgroundColor: style.surfaceContainerColor,
      trackGap: 0,
      strokeCap: StrokeCap.round,
      strokeWidth: strokeWidth,
      constraints: constraints,
    );
  }

  Widget buildLinear(ZoStyle style) {
    final double minHeight = switch (size) {
      ZoSize.small => 4,
      ZoSize.medium => 8,
      ZoSize.large => 12,
    };

    return LinearProgressIndicator(
      value: value,
      trackGap: 0,
      backgroundColor: style.surfaceContainerColor,
      stopIndicatorColor: Colors.transparent,
      minHeight: minHeight,
      borderRadius: BorderRadius.circular(12),
    );
  }

  Widget withText(ZoStyle style, Widget child) {
    if (text == null || type != ZoProgressType.circle) return child;

    final double? fontSize = switch (size) {
      ZoSize.small => style.fontSizeSM,
      ZoSize.medium => null,
      ZoSize.large => style.fontSizeMD,
    };

    final styledText = DefaultTextStyle.merge(
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
            child: IgnorePointer(
              ignoring: !barrier,
              child: Container(
                padding: type == ZoProgressType.linear
                    ? EdgeInsets.all(style.space2)
                    : null,
                alignment: alignment,
                decoration: barrier
                    ? BoxDecoration(
                        borderRadius: borderRadius,
                        color: style.barrierColor,
                      )
                    : null,
                child: child,
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = context.zoStyle;

    var node =
        indicator ??
        switch (type) {
          ZoProgressType.circle => buildCircle(style),
          ZoProgressType.linear => buildLinear(style),
        };

    node = withText(style, node);
    node = withContainer(style, node);

    return node;
  }
}

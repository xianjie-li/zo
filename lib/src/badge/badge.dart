import "package:flutter/material.dart";
import "package:zo/src/base/base.dart";

/// 徽标组件。
///
/// 支持两种使用方式：
/// - 组件模式：不传 [child]，仅渲染徽标本体
/// - 右上角模式：传入 [child]，在其右上角叠加徽标
///
/// 内容优先级如下：
/// - 传入 [count] 时显示计数徽标
/// - 否则传入 [content] 时显示自定义内容徽标
/// - 两者都未传时显示红点徽标
class ZoBadge extends StatelessWidget {
  const ZoBadge({
    super.key,
    this.child,
    this.count,
    this.maxCount,
    this.content,
    this.color,
    this.size,
    this.offset,
  }) : assert(maxCount == null || maxCount > 0);

  /// 传入子级时, 徽标会显示在组件右上角
  final Widget? child;

  /// 徽标计数，传入时显示数值；小于等于 `0` 时不显示。
  final double? count;

  /// 徽标计数最大值。
  ///
  /// 仅在传入 [count] 时生效。
  /// 当 `count > maxCount` 时，会显示为 `maxCount+`。
  final double? maxCount;

  /// 自定义徽标内容
  final Widget? content;

  /// 徽标颜色，默认使用 `ZoStyle.errorColor`。
  final Color? color;

  /// 徽标尺寸，默认跟随 `ZoStyle.widgetSize`。
  final ZoSize? size;

  /// 在右上角模式下对徽标做额外偏移。
  ///
  /// 会在组件内置定位结果基础上叠加该偏移。
  final Offset? offset;

  @override
  Widget build(BuildContext context) {
    final badge = _ZoBadgeCore(
      count: count,
      maxCount: maxCount,
      content: content,
      color: color,
      size: size,
    );

    if (child == null) {
      return badge;
    }

    final isDotMode = count == null && content == null;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.topRight,
      children: [
        child!,
        FractionalTranslation(
          translation: isDotMode
              ? const Offset(0.3, -0.3)
              : const Offset(0.5, -0.5),
          child: Transform.translate(
            offset: offset ?? Offset.zero,
            child: badge,
          ),
        ),
      ],
    );
  }
}

class _ZoBadgeCore extends StatelessWidget {
  const _ZoBadgeCore({
    required this.count,
    required this.maxCount,
    required this.content,
    required this.color,
    required this.size,
  });

  /// 徽标计数值。
  final double? count;

  /// 计数最大值，用于生成 `max+` 展示文案。
  final double? maxCount;

  /// 自定义内容模式下的内容节点。
  final Widget? content;

  /// 徽标背景色。
  final Color? color;

  /// 徽标尺寸。
  final ZoSize? size;

  @override
  Widget build(BuildContext context) {
    if (count != null && count! <= 0) {
      return const SizedBox.shrink();
    }

    final style = context.zoStyle;
    final currentSize = size ?? style.widgetSize;
    final currentColor = color ?? style.errorColor;
    final dotSize = _getDotSize(currentSize);
    final height = _getBadgeHeight(currentSize);
    final minWidth = _getBadgeMinWidth(currentSize);
    final fontSize = _getFontSize(currentSize, style);
    final horizontalPadding = _getHorizontalPadding(currentSize, style);

    Widget currentChild;
    late String childKey;

    if (count != null) {
      final text = _getCountText(count!, maxCount);
      childKey = "count:$text";

      currentChild = Text(
        text,
        style: TextStyle(
          color: style.darkStyle.titleTextColor,
          fontSize: fontSize,
        ),
      );
    } else if (content != null) {
      childKey = "content:${content.runtimeType}";

      currentChild = DefaultTextStyle(
        style: TextStyle(
          color: style.darkStyle.titleTextColor,
          fontSize: fontSize,
          height: 1,
        ),
        child: IconTheme(
          data: IconThemeData(
            color: style.darkStyle.titleTextColor,
            size: fontSize + 2,
          ),
          child: content!,
        ),
      );
    } else {
      return Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(
          color: currentColor,
          shape: BoxShape.circle,
        ),
      );
    }

    return Container(
      constraints: BoxConstraints(minWidth: minWidth),
      height: height,
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      decoration: BoxDecoration(
        color: currentColor,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        child: Center(
          widthFactor: 1,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            transitionBuilder: (child, animation) {
              final offsetAnimation = Tween<Offset>(
                begin: const Offset(0, 0.5),
                end: Offset.zero,
              ).animate(animation);

              return FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: offsetAnimation,
                  child: child,
                ),
              );
            },
            child: KeyedSubtree(
              key: ValueKey(childKey),
              child: currentChild,
            ),
          ),
        ),
      ),
    );
  }

  /// 根据最大值规则返回最终计数字符串。
  String _getCountText(double value, double? maxValue) {
    if (maxValue != null && value > maxValue) {
      return "${_formatCount(maxValue)}+";
    }

    return _formatCount(value);
  }

  /// 格式化数值文本：整数去小数，小数保留原值字符串。
  String _formatCount(double value) {
    final intValue = value.round();

    if ((value - intValue).abs() < 0.000001) {
      return "$intValue";
    }

    return value.toString();
  }

  /// 获取红点模式下的圆点直径。
  double _getDotSize(ZoSize size) {
    return switch (size) {
      ZoSize.small => 6,
      ZoSize.medium => 8,
      ZoSize.large => 10,
    };
  }

  /// 获取徽标高度。
  double _getBadgeHeight(ZoSize size) {
    return switch (size) {
      ZoSize.small => 16,
      ZoSize.medium => 18,
      ZoSize.large => 22,
    };
  }

  /// 获取徽标最小宽度。
  double _getBadgeMinWidth(ZoSize size) {
    return switch (size) {
      ZoSize.small => 16,
      ZoSize.medium => 18,
      ZoSize.large => 22,
    };
  }

  /// 获取徽标文本字号。
  double _getFontSize(ZoSize size, ZoStyle style) {
    return switch (size) {
      // 防止文本大于可用体积导致显示偏下
      ZoSize.small => style.fontSizeSM - 2,
      ZoSize.medium => style.fontSizeSM,
      ZoSize.large => style.fontSize,
    };
  }

  /// 获取徽标左右内边距。
  double _getHorizontalPadding(ZoSize size, ZoStyle style) {
    return switch (size) {
      ZoSize.small => style.space1,
      ZoSize.medium => style.space1,
      ZoSize.large => style.space2,
    };
  }
}

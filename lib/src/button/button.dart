import "dart:async";

import "package:flutter/material.dart";
import "package:zo/zo.dart";

/// 交互按钮, 集成了多种不同类型的按钮
class ZoButton extends StatefulWidget {
  const ZoButton({
    super.key,
    this.child,
    this.icon,
    this.loading = false,
    this.primary = false,
    this.square = false,
    this.text = false,
    this.size = ZoSize.medium,
    this.color,
    this.onPressed,
    this.onLongPress,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// 按钮内容
  final Widget? child;

  /// 图标, 若未传入 child 将显示图标按钮, 不支持 text 按钮
  final Widget? icon;

  /// 是否显示加载状态
  final bool loading;

  /// 是否是主要按钮, 将使用主题色作为背景色, icon / text 按钮此项不可用
  final bool primary;

  /// 图标按钮显示为方型
  final bool square;

  /// 设置为文本按钮
  final bool text;

  /// 尺寸
  final ZoSize size;

  /// 自定义颜色, 对 text 按钮无效
  final Color? color;

  /// 点击, 若返回一个 future, 可使按钮进入loading状态
  final dynamic Function()? onPressed;

  /// 长按, 若返回一个 future, 可使按钮进入loading状态
  final dynamic Function()? onLongPress;

  /// 通过md3 style自定义样式
  final ButtonStyle? style;

  /// 焦点控制
  final FocusNode? focusNode;

  /// 自动聚焦
  final bool autofocus;

  @override
  State<ZoButton> createState() => _ZoButtonState();
}

class _ZoButtonState extends State<ZoButton> {
  bool localLoading = false;

  bool get isIconButton {
    return widget.icon != null && widget.child == null;
  }

  bool get isIconTextButton {
    return widget.icon != null && widget.child != null;
  }

  bool get isLoading {
    return widget.loading || localLoading;
  }

  bool get isDisabled {
    return widget.onPressed == null && widget.onLongPress == null;
  }

  void onPressed() {
    if (widget.onPressed == null) return;

    final ret = widget.onPressed!();

    if (ret is Future) {
      setState(() {
        localLoading = true;
      });

      ret.whenComplete(() {
        setState(() {
          localLoading = false;
        });
      }).ignore();
    }
  }

  void onLongPress() {
    if (widget.onLongPress == null) return;

    final ret = widget.onLongPress!();

    if (ret is Future) {
      setState(() {
        localLoading = true;
      });

      ret.whenComplete(() {
        setState(() {
          localLoading = false;
        });
      }).ignore();
    }
  }

  /// 获取定制按钮样式
  ButtonStyle getStyle(bool lighterText) {
    final zoStyle = context.zoStyle;
    final theme = context.zoTheme;
    final style = widget.style ?? ButtonStyle();

    EdgeInsets padding;
    WidgetStateProperty<double?>? iconSize;
    WidgetStateProperty<OutlinedBorder?>? shape;
    TextStyle? textStyle;
    WidgetStateProperty<Color?>? backgroundColor;
    WidgetStateProperty<Color?>? iconColor;

    final double space = switch (widget.size) {
      ZoSize.small => zoStyle.space2,
      ZoSize.medium => zoStyle.space3,
      ZoSize.large => zoStyle.space4,
    };

    // Padding 调整
    if (isIconButton) {
      padding = EdgeInsets.zero;
    } else if (widget.text) {
      padding = EdgeInsets.symmetric(horizontal: space, vertical: 0);
    } else {
      padding = EdgeInsets.symmetric(horizontal: space, vertical: 0);
    }

    // 图标尺寸 调整
    if (isIconButton) {
      final double iconSizeNum = switch (widget.size) {
        ZoSize.small => zoStyle.sizeSM,
        ZoSize.medium => zoStyle.sizeMD,
        ZoSize.large => zoStyle.sizeLG,
      };

      iconSize = WidgetStateProperty.fromMap({
        // 控制 small icon 最小尺寸
        WidgetState.any: iconSizeNum - (widget.size == ZoSize.small ? 10 : 12),
      });
    }

    // 圆角调整
    if (!isIconButton || widget.square) {
      shape = WidgetStateProperty.fromMap({
        WidgetState.any: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(zoStyle.borderRadius),
        ),
      });
    }

    if (widget.size == ZoSize.large) {
      textStyle = TextStyle(
        fontSize: zoStyle.fontSizeMD,
      );
    }

    if (widget.color != null && !(isIconButton || widget.text)) {
      backgroundColor = WidgetStateProperty.fromMap({
        WidgetState.disabled: zoStyle.disabledColor,
        WidgetState.any: widget.color,
      });
    }

    // 特定场景下强制按钮为白色
    if (lighterText) {
      iconColor = WidgetStateProperty.fromMap({
        WidgetState.any: theme.brightness == Brightness.light
            ? Colors.white
            : zoStyle.textColor,
      });
    }

    return style.copyWith(
      // 允许完全定制尺寸
      minimumSize: WidgetStateProperty.fromMap({WidgetState.any: Size(0, 0)}),
      iconSize: iconSize,
      padding: WidgetStateProperty.fromMap({WidgetState.any: padding}),
      shape: shape,
      textStyle: textStyle == null
          ? null
          : WidgetStateProperty.fromMap({WidgetState.any: textStyle}),
      backgroundColor: backgroundColor,
      iconColor: iconColor,
    );
  }

  /// 选择要使用的内部组件
  Widget buildButton(bool lighterText) {
    assert(widget.icon != null || widget.child != null);

    final zoStyle = context.zoStyle;
    final buttonStyle = getStyle(lighterText);
    final theme = context.zoTheme;
    var child = widget.child;

    VoidCallback? onPressed = this.onPressed;
    VoidCallback? onLongPress = this.onLongPress;

    if (isLoading || widget.onPressed == null) {
      onPressed = null;
    }

    if (isLoading || widget.onLongPress == null) {
      onLongPress = null;
    }

    // 特定场景下强制文本使用白色
    if (lighterText && child != null) {
      child = DefaultTextStyle(
        style: TextStyle(
          fontSize: widget.size == ZoSize.large ? zoStyle.fontSizeMD : null,
          color: theme.brightness == Brightness.light
              ? Colors.white
              : zoStyle.textColor,
        ),
        child: child,
      );
    }

    // icon + 文本 按钮
    if (isIconTextButton) {
      if (widget.primary) {
        return FilledButton.icon(
          icon: widget.icon!,
          label: child!,
          onPressed: onPressed,
          onLongPress: onLongPress,
          style: buttonStyle,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
        );
      } else {
        return FilledButton.tonalIcon(
          icon: widget.icon!,
          label: child!,
          onPressed: onPressed,
          onLongPress: onLongPress,
          style: buttonStyle,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
        );
      }
    }

    // 纯 icon 按钮
    if (isIconButton) {
      return IconButton(
        icon: widget.icon!,
        onPressed: onPressed,
        onLongPress: onLongPress,
        style: buttonStyle,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        color: widget.color,
      );
    }

    // 文本按钮
    if (widget.text) {
      return TextButton(
        onPressed: onPressed,
        onLongPress: onLongPress,
        style: buttonStyle,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        child: child!,
      );
    }

    // 主色按钮
    if (widget.primary) {
      return FilledButton(
        onPressed: onPressed,
        onLongPress: onLongPress,
        style: buttonStyle,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        child: child!,
      );
    }

    // 默认按钮
    return FilledButton.tonal(
      onPressed: onPressed,
      onLongPress: onLongPress,
      style: buttonStyle,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      child: child!,
    );
  }

  /// 控制尺寸
  Widget withConstrained(Widget node) {
    final zoStyle = context.zoStyle;

    final standardSize = switch (widget.size) {
      ZoSize.small => zoStyle.sizeSM,
      ZoSize.medium => zoStyle.sizeMD,
      ZoSize.large => zoStyle.sizeLG,
    };

    double? width;
    double? height;

    if (isIconButton) {
      // 小型按钮尺寸适当再缩小
      final diff = (widget.size == ZoSize.small ? 4 : 0);
      width = standardSize - diff;
      height = standardSize - diff;
    } else if (widget.text) {
      height = standardSize;
      width = 0;
    } else {
      height = standardSize;

      // 常规按钮限制最小宽度
      width = standardSize * 2 + 4;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minWidth: width, minHeight: height),
      child: node,
    );
  }

  /// 添加Loading状态
  Widget withLoading(Widget node) {
    if (!isLoading) return node;
    final zoStyle = context.zoStyle;

    var progressType = ZoProgressType.circle;

    if (widget.size == ZoSize.small || isIconButton) {
      progressType = ZoProgressType.linear;
    }

    return ZoProgress(
      size: ZoSize.small,
      type: progressType,
      borderRadius: BorderRadius.circular(zoStyle.borderRadius),
      child: node,
    );
  }

  /// 对特定场景的按钮和文本强制应用白色文字
  bool useLighterText() {
    // 文本按钮 禁用 无child 均跳过
    if (widget.child == null || widget.text || isDisabled) return false;
    // 配置了颜色或为primary按钮
    if (!widget.primary && widget.color == null) return false;

    final curColor = widget.color ?? context.zoStyle.primaryColor;
    final lum = curColor.computeLuminance();

    return lum > 0.2;
  }

  @override
  Widget build(BuildContext context) {
    final lighterText = useLighterText();
    return withLoading(withConstrained(buildButton(lighterText)));
  }
}

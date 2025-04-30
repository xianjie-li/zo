import "package:flutter/material.dart";
import "package:zo/zo.dart";

/// 一个通用容器, 它创建一个矩形区域, 并在 focus / hover / 点击时触发特定的交互样式, 它在内部
/// 包装了 Container 和 InkWell, 支持它们的大部分属性
///
/// 包含背景色 / 边框 / 水波三种交互效果, 默认使用背景色交互, 可以同事启用多种效果
class ZoInteractiveBox extends StatefulWidget {
  const ZoInteractiveBox({
    super.key,
    this.child,
    this.colorEffect = true,
    this.borderEffect = false,
    this.splashEffect = false,
    this.borderRadius,
    this.border,
    this.activeBorder,
    this.alignment,
    this.padding,
    this.width,
    this.height,
    this.constraints,
    this.decoration,
    this.foregroundDecoration,
    this.onTap,
    this.onTapDown,
    this.onTapUp,
    this.onTapCancel,
    this.onSecondaryTap,
    this.onSecondaryTapUp,
    this.onSecondaryTapDown,
    this.onSecondaryTapCancel,
    this.onDoubleTap,
    this.onLongPress,
    this.onHighlightChanged,
    this.onHover,
    this.focusColor,
    this.hoverColor,
    this.highlightColor,
    this.splashColor,
    this.enableFeedback = true,
    this.focusNode,
    this.canRequestFocus = true,
    this.onFocusChange,
    this.autofocus = false,
  });

  // # # # # # # # 定制属性 # # # # # # #

  /// 子级
  final Widget? child;

  /// 是否显示背景色效果
  final bool colorEffect;

  /// 是否显示边框效果, 可通过 [border] 和 [activeBorder] 定制边框样式
  final bool borderEffect;

  /// 是否显示点击水波效果
  final bool splashEffect;

  /// 圆角
  final BorderRadius? borderRadius;

  /// 边框
  final BoxBorder? border;

  /// 高亮边框, 会在聚焦 / hover 时显示
  final BoxBorder? activeBorder;

  // # # # # # # # Container 属性 # # # # # # #

  /// 控制子级对齐
  final AlignmentGeometry? alignment;

  /// 边距
  final EdgeInsetsGeometry? padding;

  /// 宽度
  final double? width;

  /// 高度
  final double? height;

  /// 盒子约束
  final BoxConstraints? constraints;

  /// 应用盒子装饰
  final BoxDecoration? decoration;

  /// 应用盒子前景装饰
  final BoxDecoration? foregroundDecoration;

  // # # # # # # # InkWell 属性 # # # # # # #

  /// 点击
  final void Function()? onTap;
  final void Function(TapDownDetails)? onTapDown;
  final void Function(TapUpDetails)? onTapUp;
  final void Function()? onTapCancel;
  final void Function()? onSecondaryTap;
  final void Function(TapUpDetails)? onSecondaryTapUp;
  final void Function(TapDownDetails)? onSecondaryTapDown;
  final void Function()? onSecondaryTapCancel;

  /// 双击
  final void Function()? onDoubleTap;

  /// 长按
  final void Function()? onLongPress;

  /// 高亮状态变更
  final void Function(bool)? onHighlightChanged;

  /// hover状态变更
  final void Function(bool)? onHover;

  /// 颜色配置
  final Color? focusColor;
  final Color? hoverColor;
  final Color? highlightColor;
  final Color? splashColor;

  /// 应用交互反馈
  final bool enableFeedback;

  /// 焦点控制
  final FocusNode? focusNode;

  /// 可聚焦
  final bool canRequestFocus;

  /// 聚焦状态变更
  final void Function(bool)? onFocusChange;

  /// 自动聚焦
  final bool autofocus;

  @override
  State<ZoInteractiveBox> createState() => _ZoInteractiveBoxState();
}

class _ZoInteractiveBoxState extends State<ZoInteractiveBox> {
  bool highlight = false;
  bool hover = false;
  bool focus = false;

  void onHighlightChanged(bool val) {
    widget.onHighlightChanged?.call(val);
    setState(() {
      highlight = val;
    });
  }

  void onHover(bool val) {
    widget.onHover?.call(val);
    setState(() {
      hover = val;
    });
  }

  void onFocusChange(bool val) {
    widget.onFocusChange?.call(val);

    setState(() {
      focus = val;
    });
  }

  // 根据状态获取当前 border
  BoxBorder? getBorder() {
    var border = widget.border;
    var activeBorder = widget.activeBorder;

    if (!widget.borderEffect) {
      return widget.border;
    }

    if (border == null || activeBorder == null) {
      var style = context.zoStyle;
      var zBorder = style.outlineColor;
      var zBorderVariant = style.outlineColorVariant;

      border = border ?? Border.all(color: zBorder);
      activeBorder = activeBorder ?? Border.all(color: zBorderVariant);
    }

    if (highlight || hover || focus) {
      return activeBorder;
    }

    return border;
  }

  @override
  Widget build(BuildContext context) {
    var decoration = widget.decoration ?? BoxDecoration();

    return InkWell(
      borderRadius: widget.borderRadius,
      onTap: widget.onTap,
      onTapDown: widget.onTapDown,
      onTapUp: widget.onTapUp,
      onTapCancel: widget.onTapCancel,
      onSecondaryTap: widget.onSecondaryTap,
      onSecondaryTapUp: widget.onSecondaryTapUp,
      onSecondaryTapDown: widget.onSecondaryTapDown,
      onSecondaryTapCancel: widget.onSecondaryTapCancel,
      onDoubleTap: widget.onDoubleTap,
      onLongPress: widget.onLongPress,
      onHighlightChanged: onHighlightChanged,
      onHover: onHover,
      onFocusChange: onFocusChange,
      focusColor: widget.colorEffect ? widget.focusColor : Colors.transparent,
      hoverColor: widget.colorEffect ? widget.hoverColor : Colors.transparent,
      highlightColor:
          widget.colorEffect ? widget.highlightColor : Colors.transparent,
      splashColor:
          widget.splashEffect ? widget.splashColor : Colors.transparent,
      enableFeedback: widget.enableFeedback,
      focusNode: widget.focusNode,
      canRequestFocus: widget.canRequestFocus,
      autofocus: widget.autofocus,
      child: Container(
        decoration: decoration.copyWith(
          borderRadius: widget.borderRadius,
          border: getBorder(),
        ),
        alignment: widget.alignment,
        padding: widget.padding,
        width: widget.width,
        height: widget.height,
        constraints: widget.constraints,
        foregroundDecoration: widget.foregroundDecoration,
        child: widget.child,
      ),
    );
  }
}

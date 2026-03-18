import "package:flutter/material.dart";
import "package:zo/zo.dart";

/// 基础交互按钮
class ZoButton extends StatelessWidget {
  const ZoButton({
    super.key,
    this.child,
    this.icon,
    this.loading = false,
    this.enabled = true,
    this.primary = false,
    this.plain = false,
    this.size = ZoSize.medium,
    this.constraints,
    this.padding,
    this.color,
    this.onTap,
    this.onContextAction,
    this.focusNode,
    this.autofocus = false,
    this.canRequestFocus = true,
    this.focusOnTap = false,
    this.adjustSize,
    this.mainAxisAlignment = MainAxisAlignment.center,
    this.builder,
  });

  /// 按钮主要内容
  final Widget? child;

  /// 是否是主要按钮, 将使用主题色作为颜色
  final bool primary;

  /// 图标, 传入后，如果同时传入了 [child] 会显示图文并排图标，否则会将按钮渲染为图标按钮
  final Widget? icon;

  /// 不通过边框 / 背景色等来强调按钮轮廓
  final bool plain;

  /// 是否显示加载状态
  final bool loading;

  /// 是否启用
  final bool enabled;

  /// 预置尺寸
  final ZoSize size;

  /// 自定义尺寸
  final BoxConstraints? constraints;

  /// 间距
  final EdgeInsets? padding;

  /// 自定义颜色
  final Color? color;

  /// 点击, 可返回一个 future 使按钮进入 loading 状态
  final dynamic Function()? onTap;

  /// 触发上下文操作, 在鼠标操作中表示右键点击, 在触摸操作中表示长按
  final void Function(ZoTriggerEvent event)? onContextAction;

  /// 焦点控制
  final FocusNode? focusNode;

  /// 自动聚焦
  final bool autofocus;

  /// 是否可获取焦点
  final bool canRequestFocus;

  /// 是否可通过点击获得焦点, 需要同时启用点击相关的事件才能生效
  final bool focusOnTap;

  /// 手动调整按钮的最终尺寸, 当需要把按钮放置在类似按钮一样使用了标准 [ZoStyle.sizeMD] 等属性的容器中时，
  /// 为了避免按钮和容器重叠，可以通过此项微调按钮尺寸
  final double? adjustSize;

  /// 主轴对齐方式, 仅在同时存在 [icon] 和 [child] 时生效
  final MainAxisAlignment mainAxisAlignment;

  /// 通过构造器自定义子级, 可通过此方式覆盖默认的 flex 布局结构, 并且可以接受 [ZoInteractiveBoxBuildArgs.active],
  /// [ZoInteractiveBoxBuildArgs.focus] 等状态来定制渲染
  final Widget Function(ZoButton widget, ZoInteractiveBoxBuildArgs args)?
  builder;

  dynamic _onTapHandle(ZoTriggerEvent event) {
    return onTap?.call();
  }

  Color? _getColor(ZoStyle style) {
    if (primary) return style.primaryColor;

    if (plain) return color;

    return color ?? style.surfaceContainerColor;
  }

  Widget _buildChild(ZoInteractiveBoxBuildArgs args) {
    return builder!(this, args);
  }

  @override
  Widget build(BuildContext context) {
    final style = context.zoStyle;

    final isIconButton = icon != null && child == null;

    // 按钮尺寸
    final btnSize = style.getSizedExtent(size);

    // 文本尺寸
    final textSize = style.getSizedFontSize(size);

    // 图标尺寸, 图标按钮使用偏大一点的尺寸
    final iconSize = style.getSizedIconSize(size, !isIconButton);

    // 横向间距
    var padding = switch (size) {
      ZoSize.small => style.space2,
      ZoSize.medium => style.space2,
      ZoSize.large => style.space3,
    };

    // 设置最小尺寸, 防止按钮过小
    var minWidth = btnSize * 2;
    var minHeight = btnSize;

    // 图标按钮宽度和间距调整
    if (isIconButton) {
      // 按钮图标比常规图标稍微小一些, 使其能在 input 等场景中更好的放置
      minHeight = btnSize - 4;
      minWidth = minHeight;
      padding = 0;
    }

    if (adjustSize != null) {
      minWidth += adjustSize!;
      minHeight += adjustSize!;
    }

    // 是否显示边框
    final showBorder = !primary && color == null && !plain;

    Widget? childNode;

    if (builder != null) {
      childNode = null;
    } else if (icon != null && child != null) {
      childNode = Row(
        spacing: style.space1,
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: mainAxisAlignment,
        children: [
          icon!,
          child!,
        ],
      );
    } else if (icon != null || child != null) {
      childNode = Center(
        widthFactor: 1,
        child: icon ?? child!,
      );
    } else {
      return const SizedBox.shrink();
    }

    return Semantics(
      button: true,
      enabled: enabled,
      child: ZoInteractiveBox(
        canRequestFocus: canRequestFocus,
        iconTheme: IconThemeData(size: iconSize),
        textStyle: TextStyle(fontSize: textSize),
        loading: loading,
        enabled: enabled,
        style: showBorder
            ? ZoInteractiveBoxStyle.border
            : ZoInteractiveBoxStyle.normal,
        plain: plain,
        onTap: _onTapHandle,
        onContextAction: onContextAction,
        focusNode: focusNode,
        autofocus: autofocus,
        color: _getColor(style),
        padding: this.padding ?? EdgeInsets.symmetric(horizontal: padding),
        constraints: BoxConstraints(
          minWidth: constraints?.minWidth ?? minWidth,
          minHeight: constraints?.minHeight ?? minHeight,
          maxWidth: constraints?.maxWidth ?? double.infinity,
          maxHeight: constraints?.maxHeight ?? double.infinity,
        ),
        focusOnTap: focusOnTap,
        builder: builder != null ? _buildChild : null,
        child: childNode,
      ),
    );
  }
}

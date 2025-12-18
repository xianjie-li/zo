import "package:flutter/material.dart";
import "package:zo/zo.dart";

/// 通用交互按钮, 覆盖了几乎所有常见的按钮交互场景
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
    this.focusOnTap = true,
    this.adjustSize,
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

  dynamic _onTapHandle(ZoTriggerEvent event) {
    return onTap?.call();
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

    return Semantics(
      button: true,
      enabled: enabled,
      child: ZoInteractiveBox(
        canRequestFocus: canRequestFocus,
        iconTheme: IconThemeData(size: iconSize),
        textStyle: TextStyle(fontSize: textSize),
        loading: loading,
        enabled: enabled,
        plain: plain,
        onTap: _onTapHandle,
        onContextAction: onContextAction,
        focusNode: focusNode,
        autofocus: autofocus,
        color: primary ? style.primaryColor : color,
        border: showBorder ? Border.all(color: style.outlineColor) : null,
        activeBorder: showBorder
            ? Border.all(color: style.outlineColorVariant)
            : null,
        padding: this.padding ?? EdgeInsets.symmetric(horizontal: padding),
        constraints:
            constraints ??
            BoxConstraints(
              minWidth: minWidth,
              minHeight: minHeight,
            ),
        focusOnTap: focusOnTap,
        child: Row(
          spacing: style.space1,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            ?icon,
            ?child,
          ],
        ),
      ),
    );
  }
}

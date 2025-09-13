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
    this.color,
    this.onTap,
    this.onContextAction,
    this.focusNode,
    this.autofocus = false,
  });

  /// 按钮主要内容
  final Widget? child;

  /// 是否是主要按钮, 将使用主题色作为颜色
  final bool primary;

  /// 图标, 若未传入 [child] 将显示图标按钮
  final Widget? icon;

  /// 不通过边框 / 背景色等来强调按钮轮廓
  final bool plain;

  /// 是否显示加载状态
  final bool loading;

  /// 是否启用
  final bool enabled;

  /// 尺寸
  final ZoSize size;

  /// 自定义颜色
  final Color? color;

  /// 点击, 若返回一个 future, 可使按钮进入loading状态
  final dynamic Function()? onTap;

  /// 触发上下文操作, 在鼠标操作中表示右键点击, 在触摸操作中表示长按
  final void Function(ZoTriggerEvent event)? onContextAction;

  /// 焦点控制
  final FocusNode? focusNode;

  /// 自动聚焦
  final bool autofocus;

  dynamic _onTapHandle(ZoTriggerEvent event) {
    return onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final style = context.zoStyle;

    final isIconButton = icon != null && child == null;

    // 按钮尺寸
    final btnSize = switch (size) {
      ZoSize.small => style.sizeSM,
      ZoSize.medium => style.sizeMD,
      ZoSize.large => style.sizeLG,
    };

    // 文本尺寸
    final textSize = switch (size) {
      ZoSize.small => style.fontSizeSM,
      ZoSize.medium => style.fontSize,
      ZoSize.large => style.fontSizeMD,
    };

    // 图标尺寸, 图标按钮使用偏大一点的尺寸
    final iconSize = isIconButton ? btnSize - 12 : textSize + 4;

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

    // 是否显示边框
    final showBorder = !primary && color == null && !plain;

    return Semantics(
      button: true,
      enabled: enabled,
      child: ZoInteractiveBox(
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
        padding: EdgeInsets.symmetric(horizontal: padding),
        constraints: BoxConstraints(
          minWidth: minWidth,
          minHeight: minHeight,
        ),
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

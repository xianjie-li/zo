import "package:flutter/material.dart";
import "package:zo/zo.dart";

/// Tile 显示样式
enum ZoTileStyle {
  /// 默认风格
  normal,

  /// 边框风格
  border,

  /// 填充背景色
  filled,
}

/// 一个基础布局组件, 包含 header, content, footer, leading, trailing 几个内容区域, 可用于
/// 列表 / 表单 / 卡片 等各种布局场景, 它也在内部使用 [ZoInteractiveBox] 提供交互反馈和简单的事件
/// 绑定
class ZoTile extends StatelessWidget {
  const ZoTile({
    super.key,
    this.header,
    this.content,
    this.footer,
    this.leading,
    this.trailing,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.style = ZoTileStyle.normal,
    this.arrow = false,
    this.active = false,
    this.highlight = false,
    this.enable = true,
    this.horizontal = false,
    this.innerFoot = false,
    this.status,
    this.padding,
    this.verticalSpacing,
    this.horizontalSpacing,
    this.footerSpacing,
    this.onTap,
    this.onDoubleTap,
    this.onLongPress,
    this.focusNode,
    this.canRequestFocus = true,
    this.onFocusChange,
    this.autofocus = false,
  });

  /// 顶部内容
  final Widget? header;

  /// 主要内容区
  final Widget? content;

  /// 底部内容
  final Widget? footer;

  /// 前置内容区
  final Widget? leading;

  /// 后置的内容区
  final Widget? trailing;

  /// 显示右侧箭头
  final bool arrow;

  /// 显示风格
  final ZoTileStyle style;

  // # # # # # # # 内容区布局调整 # # # # # # #

  /// 控制交叉轴的对齐方式, 主要用于对齐 leader 和 trailing
  final CrossAxisAlignment crossAxisAlignment;

  /// 将 content 与 header 水平排列, 如果 [footer] 为 [innerFoot], 会移动到
  /// content 下方显示
  final bool horizontal;

  /// 将 footer 放置到 header / content 所在容器, 这会导致其位置被 leading / trailing
  /// 占用
  final bool innerFoot;

  /// 间距
  final EdgeInsetsGeometry? padding;

  /// 纵向内容间的间距
  final double? verticalSpacing;

  /// 横向内容间的间距
  final double? horizontalSpacing;

  /// footerSpacing 底部距离内容的间距, 若设置了 innerFoot, 该间距改为由 [verticalSpacing] 控制
  final double? footerSpacing;

  // # # # # # # # 各种状态 # # # # # # #

  /// 标记为active, 可表示选中等状态
  final bool active;

  /// 高亮并突出当前项
  final bool highlight;

  /// 是否启用
  final bool enable;

  /// 状态
  final ZoStatus? status;

  /// onTap, onDoubleTap, onLongPress, focusNode, canRequestFocus, onFocusChange, autofocus
  ///

  // # # # # # # # 事件和焦点 # # # # # # #

  /// 点击
  final void Function()? onTap;

  /// 双击
  final void Function()? onDoubleTap;

  /// 长按
  final void Function()? onLongPress;

  /// 焦点控制
  final FocusNode? focusNode;

  /// 可聚焦
  final bool canRequestFocus;

  /// 聚焦状态变更
  final void Function(bool)? onFocusChange;

  /// 自动聚焦
  final bool autofocus;

  /// 处理 rowContent 和 innerFoot 下的渲染content和footer渲染
  Widget? _buildRowContentAndFooter(ZoStyle style) {
    if (footer == null && content == null) return null;

    // 任意一项无值
    if (!innerFoot || content == null || footer == null) {
      return Expanded(child: (content ?? footer)!);
    }

    return Expanded(
      child: Column(
        spacing: verticalSpacing ?? style.space2,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [content!, footer!],
      ),
    );
  }

  /// 构造纵轴内容区域
  List<Widget> _buildCrossContent(ZoStyle style) {
    List<Widget> list = [];

    if (horizontal && header != null && content != null) {
      var contentAndFooter = _buildRowContentAndFooter(style);

      list.add(
        Row(
          spacing: horizontalSpacing ?? style.space3,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: crossAxisAlignment,
          children: [
            if (header != null) header!,
            if (contentAndFooter != null) contentAndFooter,
          ],
        ),
      );
    } else {
      if (header != null) list.add(header!);
      if (content != null) list.add(content!);
      if (footer != null && innerFoot) {
        list.add(footer!);
      }
    }

    return list;
  }

  List<Widget> _buildMainContent(ZoStyle style, Color? statusColor) {
    List<Widget> list = [];

    var curLeading = _getLeading(statusColor);

    if (curLeading != null) list.add(curLeading);

    list.add(
      Expanded(
        child: Column(
          spacing: verticalSpacing ?? style.space2,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildCrossContent(style),
        ),
      ),
    );

    var arrowNode =
        arrow
            ? Icon(
              Icons.arrow_forward_ios_rounded,
              color: style.hintTextColor,
              size: 16,
            )
            : null;

    if (trailing != null && arrowNode != null) {
      list.add(
        Row(
          spacing: horizontalSpacing ?? style.space3,
          children: [trailing!, arrowNode],
        ),
      );
    } else if (trailing != null || arrowNode != null) {
      list.add(trailing ?? arrowNode!);
    }

    return list;
  }

  /// 根据 innerFoot 构造外部 footer 或原样返回
  Widget _withOuterFooter(ZoStyle style, Widget child) {
    if (innerFoot) return child;

    return Column(
      spacing: footerSpacing ?? style.space4,
      children: [child, if (footer != null) footer!],
    );
  }

  /// 返回当前应显示的状态色, 仅 active 和 status 会返回对应状态色
  Color? _getStatusColor(ZoStyle zoStyle) {
    if (active) {
      return zoStyle.primaryColor;
    }

    return switch (status) {
      ZoStatus.success => zoStyle.successColor,
      ZoStatus.error => zoStyle.errorColor,
      ZoStatus.warning => zoStyle.warningColor,
      ZoStatus.info => zoStyle.infoColor,
      _ => null,
    };
  }

  /// 返回当前应显示的背景色
  Color? _getBgColor(ZoStyle zoStyle) {
    if (active) {
      return zoStyle.primaryColor.withAlpha(50);
    }

    if (highlight) {
      return zoStyle.highlightColor;
    }

    var statusColor = _getStatusColor(zoStyle);

    Color? color;

    if (statusColor != null) {
      var alpha = style == ZoTileStyle.border ? 16 : 32;
      color = statusColor.withAlpha(alpha);
    }

    if (color == null && style == ZoTileStyle.filled) {
      return zoStyle.surfaceGrayColor;
    }

    return color;
  }

  /// 返回当前应该使用的 leading 节点, 如果设置的 status, 会返回对应的状态图标, 否则原样返回 leading
  Widget? _getLeading(Color? color) {
    if (status == null) return leading;

    return switch (status) {
      ZoStatus.success => Icon(Icons.check_circle_rounded, color: color),
      ZoStatus.error => Icon(Icons.cancel_rounded, color: color),
      ZoStatus.warning => Icon(Icons.warning_rounded, color: color),
      ZoStatus.info => Icon(Icons.info, color: color),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    assert(header != null || content != null);

    var style = context.zoStyle;
    var statusColor = _getStatusColor(style);
    var curColor = _getBgColor(style);

    var mainContent = Row(
      spacing: horizontalSpacing ?? style.space3,
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: crossAxisAlignment,
      children: _buildMainContent(style, statusColor),
    );

    var curBorder =
        this.style == ZoTileStyle.border && statusColor != null
            ? Border.all(color: statusColor)
            : null;

    var mainNode = ZoInteractiveBox(
      onTap: enable ? onTap : null,
      onDoubleTap: enable ? onDoubleTap : null,
      onLongPress: enable ? onLongPress : null,
      focusNode: focusNode,
      canRequestFocus: enable && canRequestFocus,
      onFocusChange: onFocusChange,
      autofocus: autofocus,
      borderEffect: this.style == ZoTileStyle.border,
      border: curBorder,
      activeBorder: curBorder,
      decoration: curColor != null ? BoxDecoration(color: curColor) : null,
      padding:
          padding ??
          EdgeInsets.symmetric(
            horizontal: style.space3,
            vertical: style.space3,
          ),
      borderRadius: BorderRadius.circular(style.borderRadius),
      child: _withOuterFooter(style, mainContent),
    );

    if (!enable) {
      return Opacity(opacity: style.alpha / 255, child: mainNode);
    }

    return mainNode;
  }
}

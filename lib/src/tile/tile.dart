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
/// 列表 / 表单 / 卡片 等各种布局场景, 它还在内部使用 [ZoInteractiveBox] 提供交互反馈和简单的事件
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
    this.enabled = true,
    this.horizontal = false,
    this.innerFoot = false,
    this.status,
    this.loading = false,
    this.interactive = true,
    this.padding,
    this.decorationPadding,
    this.backgroundWidget,
    this.foregroundWidget,
    this.verticalSpacing,
    this.horizontalSpacing,
    this.footerSpacing,
    this.onTap,
    this.onActiveChanged,
    this.onFocusChanged,
    this.onContextAction,
    this.data,
    this.focusNode,
    this.autofocus = false,
    this.canRequestFocus = true,
    this.focusOnTap = true,
    this.focusBorder = true,
    this.disabledColor,
    this.activeColor,
    this.highlightColor,
    this.iconTheme,
    this.textStyle,
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

  /// 控制交叉轴的对齐方式, 主要用于对齐 leader 和 trailing
  final CrossAxisAlignment crossAxisAlignment;

  /// 将 content 与 header 水平排列, 如果 [footer] 为 [innerFoot], 会移动到
  /// content 下方显示
  final bool horizontal;

  /// 将 footer 放置到 header / content 所在容器, 这会导致其位置被 leading / trailing
  /// 占用
  final bool innerFoot;

  /// 间距
  final EdgeInsets? padding;

  /// 仅用于装饰的边距，不影响实际布局空间，用于多个相同组件并列时，添加间距，但是不影响事件触发的边距
  final EdgeInsets? decorationPadding;

  /// 额外挂载内容到与内容所在的 stack 后方
  final Widget? backgroundWidget;

  /// 额外挂载内容到与内容所在的 stack 前方
  final Widget? foregroundWidget;

  /// 纵向内容间的间距
  final double? verticalSpacing;

  /// 横向内容间的间距
  final double? horizontalSpacing;

  /// footerSpacing 底部距离内容的间距, 若设置了 innerFoot, 该间距改为由 [verticalSpacing] 控制
  final double? footerSpacing;

  /// 标记为active, 可表示选中等状态
  final bool active;

  /// 高亮并突出当前项
  final bool highlight;

  /// 是否启用
  final bool enabled;

  /// 状态
  final ZoStatus? status;

  /// 是否显示加载状态
  final bool loading;

  /// 是否可进行交互, 与 enabled = false 不同的是它不设置禁用样式, 只是阻止交互行为
  final bool interactive;

  /// 点击, 若返回一个 future, 可进入loading状态
  final dynamic Function(ZoTriggerEvent event)? onTap;

  /// 是否活动状态
  /// - 鼠标: 表示位于组件上方
  /// - 触摸设备: 按下触发, 松开或移动时关闭
  final ZoTriggerListener<ZoTriggerToggleEvent>? onActiveChanged;

  /// 焦点变更
  final ZoTriggerListener<ZoTriggerToggleEvent>? onFocusChanged;

  /// 触发上下文操作, 在鼠标操作中表示右键点击, 在触摸操作中表示长按
  final void Function(ZoTriggerEvent event)? onContextAction;

  /// 传递到事件对象的额外信息, 可在事件回调中通过 event.data 访问
  final dynamic data;

  /// 焦点控制
  final FocusNode? focusNode;

  /// 自动聚焦
  final bool autofocus;

  /// 是否可获取焦点
  final bool canRequestFocus;

  /// 是否可通过点击获得焦点, 需要同事启用点击相关的事件才能生效
  final bool focusOnTap;

  /// 获取焦点时，是否为组件设置边框样式
  final bool focusBorder;

  /// 禁用状态的背景色
  final Color? disabledColor;

  /// active 状态的背景色
  final Color? activeColor;

  /// highlight 状态的背景色
  final Color? highlightColor;

  /// 调整图标样式
  final IconThemeData? iconTheme;

  /// 文本样式
  final TextStyle? textStyle;

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
        mainAxisSize: MainAxisSize.min,
        children: [content!, footer!],
      ),
    );
  }

  /// 构造纵轴内容区域
  List<Widget> _buildCrossContent(ZoStyle style) {
    final List<Widget> list = [];

    if (horizontal && header != null && content != null) {
      final contentAndFooter = _buildRowContentAndFooter(style);

      list.add(
        Row(
          key: const ValueKey("__cross_content__"),
          spacing: horizontalSpacing ?? style.space3,
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: crossAxisAlignment,
          mainAxisSize: MainAxisSize.min,
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
    final List<Widget> list = [];

    final curLeading = _getLeading(statusColor);

    if (curLeading != null) list.add(curLeading);

    list.add(
      Expanded(
        key: const ValueKey("__main_content__"),
        child: Column(
          spacing: verticalSpacing ?? style.space2,
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: _buildCrossContent(style),
        ),
      ),
    );

    final arrowNode = arrow
        ? Icon(
            key: const ValueKey("__arrow__"),
            Icons.arrow_forward_ios_rounded,
            size: (iconTheme?.size ?? style.getSizedIconSize()) - 4,
          )
        : null;

    if (trailing != null && arrowNode != null) {
      list.add(
        Row(
          key: const ValueKey("__trailing__"),
          spacing: horizontalSpacing ?? style.space3,
          mainAxisSize: MainAxisSize.min,
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
      mainAxisAlignment: MainAxisAlignment.center,
      children: [child, if (footer != null) footer!],
    );
  }

  /// 返回当前应显示的状态色, 仅 active 和 status 会返回对应状态色
  Color? _getStatusColor(ZoStyle zoStyle) {
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
      return activeColor ?? zoStyle.primaryColor;
    }

    if (highlight) {
      return highlightColor ?? zoStyle.highlightColor;
    }

    final statusColor = _getStatusColor(zoStyle);

    Color? color;

    if (statusColor != null) {
      final alpha = style == ZoTileStyle.border ? 32 : 48;
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

  (Border? border, Border? activeBorder) _getBorder(
    ZoStyle style,
    Color? statusColor,
  ) {
    if (this.style != ZoTileStyle.border) return (null, null);

    if (statusColor != null) {
      final border = Border.all(color: statusColor);
      return (border, border);
    }

    return (
      Border.all(color: style.outlineColor),
      Border.all(color: style.outlineColorVariant),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(header != null || content != null);

    final style = context.zoStyle;
    final statusColor = _getStatusColor(style);
    final curColor = _getBgColor(style);

    Widget mainContent = Row(
      key: const ValueKey("__main_container__"),
      spacing: horizontalSpacing ?? style.space3,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: crossAxisAlignment,
      children: _buildMainContent(style, statusColor),
    );

    mainContent = _withOuterFooter(style, mainContent);

    final (border, activeBorder) = _getBorder(style, statusColor);

    final mainNode = ZoInteractiveBox(
      enabled: enabled,
      loading: loading,
      interactive: interactive,
      onTap: onTap,
      onContextAction: onContextAction,
      onActiveChanged: onActiveChanged,
      onFocusChanged: onFocusChanged,
      focusNode: focusNode,
      autofocus: autofocus,
      canRequestFocus: canRequestFocus,
      focusOnTap: focusOnTap,
      border: border,
      activeBorder: activeBorder,
      color: curColor,
      // 激活时文字使用反色
      textColorAdjust: active,
      disabledColor: disabledColor,
      iconTheme: iconTheme,
      textStyle: textStyle,
      padding: padding ?? EdgeInsets.all(style.space3),
      decorationPadding: decorationPadding,
      backgroundWidget: backgroundWidget,
      foregroundWidget: foregroundWidget,
      radius: BorderRadius.circular(style.borderRadius),
      data: data,
      child: mainContent,
    );

    return mainNode;
  }
}

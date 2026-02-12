import "package:flutter/material.dart";
import "package:zo/zo.dart";

/// 一个基础布局组件, 包含 header, content, footer, leading, trailing 几个内容区域, 可用于
/// 列表、 表单、 卡片 等各种布局场景
class ZoTile extends StatelessWidget {
  const ZoTile({
    super.key,
    this.header,
    this.content,
    this.footer,
    this.leading,
    this.trailing,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.arrow = false,
    this.horizontal = false,
    this.innerFoot = false,
    this.verticalSpacing,
    this.horizontalSpacing,
    this.footerSpacing,
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

  /// 控制交叉轴的对齐方式, 主要用于对齐 leader 和 trailing
  final CrossAxisAlignment crossAxisAlignment;

  /// 显示右侧箭头
  final bool arrow;

  /// 将 content 与 header 水平排列, 如果 [footer] 为 [innerFoot], 会移动到
  /// content 下方显示
  final bool horizontal;

  /// 将 footer 放置到 header / content 所在容器, 这会导致其位置被 leading / trailing
  /// 占用
  final bool innerFoot;

  /// 纵向内容间的间距
  final double? verticalSpacing;

  /// 横向内容间的间距
  final double? horizontalSpacing;

  /// 底部距离内容的间距, 若设置了 innerFoot, 该间距改为由 [verticalSpacing] 控制
  final double? footerSpacing;

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

  List<Widget> _buildMainContent(ZoStyle style) {
    final List<Widget> list = [];

    if (leading != null) list.add(leading!);

    list.add(
      Expanded(
        key: const ValueKey("__main_content__"),
        child: Column(
          spacing: verticalSpacing ?? style.space2,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _buildCrossContent(style),
        ),
      ),
    );

    final arrowNode = arrow
        ? Icon(
            key: const ValueKey("__arrow__"),
            Icons.arrow_forward_ios_rounded,
            size: style.getSizedIconSize() - 4,
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
      key: const ValueKey("__outer_footer_container__"),
      spacing: footerSpacing ?? style.space4,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [child, if (footer != null) footer!],
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(header != null || content != null);

    final style = context.zoStyle;

    final Widget mainContent = Row(
      key: const ValueKey("__main_container__"),
      spacing: horizontalSpacing ?? style.space3,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: crossAxisAlignment,
      children: _buildMainContent(style),
    );

    return _withOuterFooter(style, mainContent);
  }
}

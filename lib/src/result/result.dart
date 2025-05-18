import "package:flutter/material.dart";
import "package:zo/zo.dart";

/// 结果展示
class ZoResult extends StatelessWidget {
  const ZoResult({
    super.key,
    this.size = ZoSize.medium,
    this.icon,
    this.title,
    this.desc,
    this.actions,
    this.extra,
    this.simpleResult = false,
  });

  /// 尺寸
  final ZoSize size;

  /// 图标
  final Widget? icon;

  /// 标题
  final Widget? title;

  /// 描述
  final Widget? desc;

  /// 操作区
  final List<Widget>? actions;

  /// 额外内容
  final Widget? extra;

  /// 在单行紧凑的展示结果, extra 配置会被忽略
  final bool simpleResult;

  Widget buildSimpleResult(BuildContext context) {
    final style = context.zoStyle;

    return Row(
      spacing: style.space1,
      children: [
        if (icon != null) icon!,
        if (title != null) title!,
        if (title != null && desc != null) const Text(": "),
        if (desc != null)
          DefaultTextStyle(
            style: TextStyle(color: style.hintTextColor),
            child: desc!,
          ),
        if (actions != null) ...actions!,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (simpleResult) return buildSimpleResult(context);

    final style = context.zoStyle;
    final textTheme = context.zoTextTheme;

    var space = style.space2;
    var actionButtonSpace = style.space4;
    var extraPadding = style.space4;
    var iconSize = 60.0;
    var titleStyle = textTheme.bodyLarge!;
    var descFontSize = textTheme.bodyMedium!.fontSize!;

    if (size == ZoSize.small) {
      space = style.space1;
      actionButtonSpace = style.space3;
      extraPadding = style.space3;
      iconSize = 40;
      titleStyle = textTheme.bodyMedium!;
      descFontSize = textTheme.bodySmall!.fontSize!;
    } else if (size == ZoSize.large) {
      space = style.space3;
      actionButtonSpace = style.space5;
      extraPadding = style.space3;
      iconSize = 80;
      titleStyle = textTheme.titleLarge!;
      descFontSize = textTheme.bodyMedium!.fontSize!;
    }

    final List<Widget> list = [];

    if (icon != null) {
      list.add(
        IconTheme(
          data: IconThemeData(size: iconSize, color: style.hintTextColor),
          child: icon!,
        ),
      );
    }

    if (title != null) {
      list.add(DefaultTextStyle(style: titleStyle, child: title!));
    }

    if (desc != null) {
      list.add(
        DefaultTextStyle(
          style: TextStyle(color: style.hintTextColor, fontSize: descFontSize),
          child: desc!,
        ),
      );
    }

    if (actions != null && actions!.isNotEmpty) {
      list.addAll([
        // 上方额外填充一些距离
        if (list.isNotEmpty) SizedBox(height: style.space1),
        Row(
          spacing: actionButtonSpace,
          mainAxisAlignment: MainAxisAlignment.center,
          children: actions!,
        ),
      ]);
    }

    if (extra != null) {
      list.addAll([
        // 上方额外填充一些距离
        if (list.isNotEmpty) SizedBox(height: style.space1),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(extraPadding),
          decoration: BoxDecoration(
            color: style.surfaceGrayColor,
            borderRadius: BorderRadius.circular(style.borderRadius),
          ),
          child: extra!,
        ),
      ]);
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: style.breakPointSM),
      child: Column(spacing: space, children: list),
    );
  }
}

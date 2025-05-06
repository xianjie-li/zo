import "dart:math" as math;

import "package:flutter/widgets.dart";

/// 使用栅格系统进行布局, 栅格宽度为 12
///
/// 组件必须在一个有限的空间内, 其子项是若干个 [ZoCell] 组件, 其通过 [ZoCell.span] 指定
/// 栅格宽度, 当单行不足以容纳所有子项时, 会换行显示
class ZoCells extends StatelessWidget {
  const ZoCells({
    super.key,
    required this.children,
    this.spacing = 0,
    this.runSpacing = 0,
    this.alignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.runAlignment = WrapAlignment.start,
  });

  static const double spanMax = 12;

  /// 子项在主轴上的间距
  final double spacing;

  /// 子项在交叉轴上的间距
  final double runSpacing;

  /// 主轴对齐方式
  final WrapAlignment alignment;

  /// 子项在单行中交叉轴对齐方式
  final WrapCrossAlignment crossAxisAlignment;

  /// 子项整体在交叉轴对齐方式
  final WrapAlignment runAlignment;

  /// 子项, 通常是一组 [ZoCell] 组件
  final List<Widget> children;

  List<Widget> arrange(BuildContext context, BoxConstraints constraints) {
    final width = constraints.maxWidth;
    // spacing 会占用的最大空间
    final totalSpacingWidth = (ZoCells.spanMax - 1) * spacing;
    // 去掉总 spacing 占用后的单列宽度
    final unitWidth = (width - totalSpacingWidth) / ZoCells.spanMax;

    assert(width.isFinite, "ZoCells's width must be finite");

    // 将子项根据 span 分为不同的列
    List<List<ZoCell>> rows = [[]];

    // 每一列的总 span
    List<double> rowSpanCount = [];

    List<Widget> arranged = [];

    // 当前行的span总数
    var spanCount = 0.0;

    // 根据 children 获取 rowSpanCount / rows
    for (var i = 0; i < children.length; i++) {
      final child = children[i] as ZoCell;
      final span = child.span;

      assert(children[i] is ZoCell, "ZoCells's children must be ZoCell");

      assert(
        span >= 0 && span <= ZoCells.spanMax,
        "ZoCell's span must be between 0 and ${ZoCells.spanMax}",
      );

      spanCount += span;

      // 如果当前行的span总数大于12, 则换行
      if (spanCount > ZoCells.spanMax) {
        rows.add([child]);
        rowSpanCount.add(spanCount - span);
        spanCount = span;
      } else {
        rows.last.add(child);
      }

      if (i == children.length - 1) {
        rowSpanCount.add(spanCount);
      }
    }

    // 根据 rowSpanCount 和 rows 计算出每一列的宽度并生成 arranged, 主要需要处理配置了 spacing 的情况
    for (var i = 0; i < rows.length; i++) {
      final rowList = rows[i];

      for (var j = 0; j < rowList.length; j++) {
        final child = rowList[j];

        // 当前列的 width 加上其 span 数总共占用的 spacing 数量
        // 列如: 一个表示为 [4, 1, 7] 的栅格, 4这一列占用3个spacing位, 1这一列占用0个, 7这一列占用6个spacing,
        // 总共就还剩余两个spacing位置, 刚好能分隔3个项
        // 循环结束后, 未被扣减掉的 totalSpacingWidth 就是剩余的 spacing 占用的空间, 这些空间
        // 交由 Wrap 组件提供间距
        // 之前的实现是计算spacing占用行的总宽度, 然后平均扣减到每一个列上, 这样实现正常, 但是在不同行中,
        // 同样span的项宽度可能不一致, 对齐会比较怪异, 新的方式能保证不管多少 spacing, 同样 span 在不同
        // 行的占用一致, 缺点是span为1的项会被其他项更小, 因为其不占用任何gutter空间
        var width = unitWidth * child.span + spacing * (child.span - 1);

        arranged.add(SizedBox(width: math.max(width, 0), child: child));
      }
    }

    return arranged;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Wrap(
          spacing: spacing,
          runSpacing: runSpacing,
          alignment: alignment,
          crossAxisAlignment: crossAxisAlignment,
          runAlignment: runAlignment,
          children: arrange(context, constraints),
        );
      },
    );
  }
}

/// 作为 [ZoCells] 的子项使用, 用于占用制定的栅格宽度
class ZoCell extends StatelessWidget {
  const ZoCell({super.key, required this.span, this.child});

  /// 子项占用的栅格宽度, 值范围为 1 ~ 12, 可以通过指定小数来实现更复杂的列, 比5个2.4可组成5列栅格
  final double span;

  /// 子项
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return child ?? SizedBox.shrink();
  }
}

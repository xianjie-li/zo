import "package:flutter/material.dart";
import "package:zo/zo.dart";

enum ZoAdaptiveLayoutPointType { xs, sm, md, lg, xl, xxl }

/// 包含断点信息的类, 用于帮助进行断点布局
class ZoAdaptiveLayoutMeta<Val> extends BoxConstraints {
  const ZoAdaptiveLayoutMeta({
    required this.value,
    required this.point,
    required this.isSmall,
    required this.isMedium,
    required this.isLarge,
    super.maxHeight,
    super.maxWidth,
    super.minHeight,
    super.minWidth,
  });

  /// 当前命中的断点
  final ZoAdaptiveLayoutPointType point;

  /// 当前断点命中的值
  final Val value;

  /// 当前尺寸是 xs或sm
  final bool isSmall;

  /// 当前尺寸是 md或lg
  final bool isMedium;

  /// 当前尺寸在 lg 或其之上
  final bool isLarge;

  @override
  String toString() {
    return "AdaptiveLayoutMeta{value: $value, point: $point, isSmall: $isSmall, isMedium: $isMedium, isLarge: $isLarge, maxWidth: $maxWidth, minWidth: $minWidth, maxHeight: $maxHeight, minHeight: $minHeight}";
  }
}

/// 响应式布局工具, 用于简化响应式布局的实现, 其核心是通过 [ZoAdaptiveLayoutMeta] 提供各种有助于
/// 简化响应式布局的属性和检测方法
///
/// [ZoAdaptiveLayout] 会通过 builder 提供 [ZoAdaptiveLayoutMeta] 对象, 有两种方式来使用它:
/// - 通过 [ZoAdaptiveLayoutMeta.point] / [ZoAdaptiveLayoutMeta.isSmall] 等属性判断并显示不同的 UI
/// - 提供 [ZoAdaptiveLayout.values] 配置, 根据当前断点会自动从中挑选合适的作为 [ZoAdaptiveLayoutMeta.value],
/// 在 UI 中直接它进行 UI 显示控制, value 的类型与泛型 [Val] 匹配
///
/// 通过 [ZoAdaptiveLayout.values] 使用时, 不需要为所有断点都提供对应的值, 更大的断点会自动继承更小
/// 断点的值配置, xs 是必须配置的, 其后所有断点的值都是可选的
class ZoAdaptiveLayout<Val> extends StatelessWidget {
  const ZoAdaptiveLayout({
    super.key,
    this.customPoints = const {},
    this.values,
    this.child,
    required this.builder,
  });

  final Map<ZoAdaptiveLayoutPointType, Val>? values;

  /// 自定义断点值, 包含以下注意事项
  ///
  /// - xs 断点不可定制, 固定为0
  /// - 后方断点的值必须大于前方断点
  final Map<ZoAdaptiveLayoutPointType, double> customPoints;

  /// 构造子级, 会传入当前的断点信息
  final Function(
    BuildContext context,
    ZoAdaptiveLayoutMeta<Val> meta,
    Widget? child,
  )
  builder;

  /// 如果 builder 子树中包含不需要依赖 meta 变更的子级, 可以通过 child 传递到 builder 中
  /// 进行挂载, 避免不必要的构建
  final Widget? child;

  ZoAdaptiveLayoutMeta<Val> getMeta(
    BuildContext context,
    BoxConstraints constraints,
  ) {
    if (values != null) {
      assert(values![ZoAdaptiveLayoutPointType.xs] != null);
    }

    var style = context.zoStyle;

    var points = [
      (ZoAdaptiveLayoutPointType.xs, 0.0),
      (
        ZoAdaptiveLayoutPointType.sm,
        customPoints[ZoAdaptiveLayoutPointType.sm] ?? style.breakPointSM,
      ),
      (
        ZoAdaptiveLayoutPointType.md,
        customPoints[ZoAdaptiveLayoutPointType.md] ?? style.breakPointMD,
      ),
      (
        ZoAdaptiveLayoutPointType.lg,
        customPoints[ZoAdaptiveLayoutPointType.lg] ?? style.breakPointLG,
      ),
      (
        ZoAdaptiveLayoutPointType.xl,
        customPoints[ZoAdaptiveLayoutPointType.xl] ?? style.breakPointXL,
      ),
      (
        ZoAdaptiveLayoutPointType.xxl,
        customPoints[ZoAdaptiveLayoutPointType.xxl] ?? style.breakPointXXL,
      ),
    ];

    (ZoAdaptiveLayoutPointType, double)? curPoint;
    dynamic curVal;

    for (var i = points.length - 1; i >= 0; i--) {
      var (type, pointVal) = points[i];
      if (curPoint == null && constraints.maxWidth >= pointVal) {
        curPoint = points[i];

        // 未配置 values 时, 不用在进行后续循环
        if (values == null) break;
      }

      if (curPoint != null) {
        var valConf = values![type];

        if (valConf != null) {
          curVal = valConf;
          // 如果已经挑选到合适值, 跳出循环, 否则从前方断点的配置中获取
          break;
        }
      }
    }

    // 如果断点不符合规范并且未找到匹配, 默认以首个断点作为默认值
    if (curPoint == null) {
      curPoint = points.first;
      curVal = values![curPoint.$1];
    }

    var point = curPoint.$1;

    var isSmall =
        point == ZoAdaptiveLayoutPointType.xs ||
        point == ZoAdaptiveLayoutPointType.sm;

    var isMedium =
        point == ZoAdaptiveLayoutPointType.md ||
        point == ZoAdaptiveLayoutPointType.lg;

    return ZoAdaptiveLayoutMeta<Val>(
      point: point,
      value: curVal,
      isSmall: isSmall,
      isMedium: isMedium,
      isLarge: !isSmall && !isMedium,
      maxHeight: constraints.maxHeight,
      minHeight: constraints.minHeight,
      maxWidth: constraints.maxWidth,
      minWidth: constraints.minWidth,
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return builder(context, getMeta(context, constraints), child);
      },
    );
  }
}

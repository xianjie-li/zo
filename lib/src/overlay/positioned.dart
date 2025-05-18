part of "overlay.dart";

/// 为 Overlay 提供布局功能的核心组件, 它负责将子级通过 entry 给定的
///  offset / rect / alignment 之一在父级中进行定位,
/// 同时传入多个时, 按 offset > rect > alignment 的优先级进行定位
///
/// Positioned 还根据 preventOverflow direction 启用 popper 定位功能, 并通过 preventOverflow
/// 配置调整自身的位置
///
/// 依赖的 entry 属性有: offset / rect / alignment / direction / preventOverflow
///
/// 定位目标 / 层 / 容器:
/// - 定位目标由 rect / offset / alignment 等定位属性确定
/// - 层指的是 renderObject.child 子对象, 其表示我们要绘制的层内容
/// - 容器是当前 RenderObject, 其所在空间位有效布局区域
///
/// 定位属性会由 globalPosition 转换为 localPosition 后再容器内进行定位
///
/// 超出容器的内容会视为 overflow
class ZoOverlayPositioned extends SingleChildRenderObjectWidget {
  const ZoOverlayPositioned({super.key, super.child, required this.entry});

  /// 用于定位的层
  final ZoOverlayEntry entry;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return OverlayPositionedRenderObject(entry: entry);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    OverlayPositionedRenderObject renderObject,
  ) {
    if (renderObject.entry != entry ||
        renderObject.changeId != entry.changeId) {
      renderObject.entry = entry;
      renderObject.changeId = entry.changeId;
      renderObject.markNeedsLayout();
    }
  }
}

class OverlayPositionedRenderObject extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  OverlayPositionedRenderObject({required this.entry});

  /// 与 entry 的变更id同步, 减少不必要更新
  double changeId = 0;

  /// 用于定位的层
  ZoOverlayEntry entry;

  /// 获取子节点的尺寸或 Size.zero
  Size get _childSize =>
      (child == null || !child!.hasSize) ? Size.zero : child!.size;

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    if (child == null) return false;

    final BoxParentData childParentData = child!.parentData as BoxParentData;

    // 对于超出容器的层, 不用进行处理, 因为不会走到命中测试
    return result.addWithPaintOffset(
      offset: childParentData.offset,
      position: position,
      hitTest: (BoxHitTestResult result, Offset transformed) {
        assert(transformed == position - childParentData.offset);
        return child!.hitTest(result, position: transformed);
      },
    );
  }

  @override
  void performLayout() {
    if (child == null) return;

    child!.layout(constraints.loosen(), parentUsesSize: true);

    size = constraints.biggest;
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;
    // 执行常规布局还是方向布局
    final Offset layoutOffset =
        entry.direction == null
            ? _regularLayout()
            : _directionLayout(context, offset);

    final BoxParentData childParentData = child!.parentData as BoxParentData;

    childParentData.offset = layoutOffset;

    /// 如果不可见则不进行渲染
    final containerRect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      size.width,
      size.height,
    );
    final childRect = Rect.fromLTWH(
      layoutOffset.dx + offset.dx,
      layoutOffset.dy + offset.dy,
      _childSize.width,
      _childSize.height,
    );

    if (!containerRect.overlaps(childRect)) return;

    // 裁剪不可见部分
    context.clipRectAndPaint(containerRect, Clip.hardEdge, containerRect, () {
      // 绘制
      context.paintChild(child!, offset + layoutOffset);
    });
  }

  /// 常规布局
  Offset _regularLayout() {
    if (entry.offset != null) {
      return globalToLocal(entry.offset!);
    }

    if (entry.rect != null) {
      return globalToLocal(entry.rect!.topLeft);
    }

    if (child == null) return Offset.zero;

    return entry.alignment!.alongOffset((size - _childSize) as Offset);
  }

  /// 根据方向布局获取层定位位置, 按以下步骤进行:
  ///
  /// - 获取 target
  /// - 获取不同方向的摆放位置, 位置需要加上 distance, 并包含 hasOverflow 信息
  /// - 如果未设置 preventOverflow 或无遮挡, 直接根据方向返回位置
  /// - flip: 主轴方向被遮挡时, 若相反方向可用则移动到相反方向, flip 只会在相对方向切换,
  /// 不会变更轴向
  /// - 进行 flip 后, 如果交叉轴存在被遮挡部分, 尝试调整交叉轴偏移, 使元素保持在视口中,
  /// - 当前使用位置/交叉轴偏移调整等需要向上通知, 方便使用者对 popper arrow 等进行位置调整
  Offset _directionLayout(PaintingContext context, Offset offset) {
    assert(entry.direction != null);

    /// 获取定位目标, 它是子项进行布局的参照物
    /// - 通过 rect 布局时, 与 rect 相同
    /// - 通过 offset 布局时, 为左上角与 offset 相同的 0 尺寸矩形
    /// - 通过 alignment 布局时, 为 alignment 比例在容器尺寸上对应的点位置
    Rect target;

    if (entry.offset != null) {
      target = _getTargetWithOffset();
    } else if (entry.rect != null) {
      target = _getTargetWithRect();
    } else {
      target = _getTargetWithAlign();
    }

    final directionMetaMap = _calcDirectionMetaMap(target);

    final curDirectionMeta = _pickDirection(directionMetaMap);

    // _debugTargetPosition(context, offset, target);
    // _debugDirectionPosition(context, offset, target, directionMetaMap);

    var x = curDirectionMeta.position.dx;
    var y = curDirectionMeta.position.dy;

    // 交叉轴存在遮挡时, 修正其位置
    if (curDirectionMeta.crossOverflow && entry.preventOverflow) {
      final isVertical = _isVerticalDirection(curDirectionMeta.direction);
      final isHorizontal = !isVertical;

      if (isVertical) {
        x = x + curDirectionMeta.crossOverflowDistance;
      } else if (isHorizontal) {
        y = y + curDirectionMeta.crossOverflowDistance;
      }
    }

    return Offset(x, y);
  }

  /// 根据 offset 获取 target
  Rect _getTargetWithOffset() {
    final local = globalToLocal(entry.offset!);
    return Rect.fromLTWH(local.dx, local.dy, 0, 0);
  }

  /// 根据 rect 获取 target
  Rect _getTargetWithRect() {
    final local = globalToLocal(entry.rect!.topLeft);
    return Rect.fromLTWH(
      local.dx,
      local.dy,
      entry.rect!.width,
      entry.rect!.height,
    );
  }

  /// 根据 alignment 获取 target
  Rect _getTargetWithAlign() {
    final pos = entry.alignment!.alongOffset(Offset(size.width, size.height));

    return Rect.fromCenter(center: Offset(pos.dx, pos.dy), width: 0, height: 0);
  }

  /// 获取指定模板不同方向的放置位置和遮挡状态
  HashMap<ZoPopperDirection, _DirectionMeta> _calcDirectionMetaMap(
    Rect targetRect,
  ) {
    final childSize = _childSize;
    final meta = HashMap<ZoPopperDirection, _DirectionMeta>();

    final halfChildWidth = childSize.width / 2;
    final halfChildHeight = childSize.height / 2;

    /// 纵轴不同位置的偏移
    final verticalCenter = targetRect.center.dx - halfChildWidth;
    final verticalLeft = targetRect.left;
    final verticalRight = targetRect.right - childSize.width;

    /// 横轴不同位置的偏移
    final horizontalCenter = targetRect.center.dy - halfChildHeight;
    final horizontalTop = targetRect.top;
    final horizontalBottom = targetRect.bottom - childSize.height;

    /// 不同方向的位置
    final topPosition = Offset(
      verticalCenter,
      targetRect.top - childSize.height,
    );

    final topLeftPosition = Offset(verticalLeft, topPosition.dy);

    final topRightPosition = Offset(verticalRight, topPosition.dy);

    final bottomPosition = Offset(verticalCenter, targetRect.bottom);

    final bottomLeftPosition = Offset(verticalLeft, bottomPosition.dy);

    final bottomRightPosition = Offset(verticalRight, bottomPosition.dy);

    final leftPosition = Offset(
      targetRect.left - childSize.width,
      horizontalCenter,
    );

    final leftTopPosition = Offset(leftPosition.dx, horizontalTop);

    final leftBottomPosition = Offset(leftPosition.dx, horizontalBottom);

    final rightPosition = Offset(targetRect.right, horizontalCenter);

    final rightTopPosition = Offset(rightPosition.dx, horizontalTop);

    final rightBottomPosition = Offset(rightPosition.dx, horizontalBottom);

    /// 主轴遮挡计算
    final topOverflow = topPosition.dy < 0;

    final bottomOverflow = bottomPosition.dy + childSize.height > size.height;

    final leftOverflow = leftPosition.dx < 0;

    final rightOverflow = rightPosition.dx + childSize.width > size.width;

    /// 交叉轴遮挡计算
    var verticalLeftCrossOverflowDistance = 0.0;
    var verticalRightCrossOverflowDistance = 0.0;
    var verticalCenterCrossOverflowDistance = 0.0;

    // 层超出有效区域时, 根据超出位置进行修正
    if (verticalLeft < 0) {
      verticalLeftCrossOverflowDistance = -verticalLeft;
    } else if (verticalLeft + childSize.width > size.width) {
      verticalLeftCrossOverflowDistance =
          size.width - (verticalLeft + childSize.width);
    }

    if (verticalRight < 0) {
      verticalRightCrossOverflowDistance = -verticalRight;
    } else if (verticalRight + childSize.width > size.width) {
      verticalRightCrossOverflowDistance =
          size.width - (verticalRight + childSize.width);
    }

    if (verticalCenter < 0) {
      verticalCenterCrossOverflowDistance = -verticalCenter;
    } else if (verticalCenter + childSize.width > size.width) {
      verticalCenterCrossOverflowDistance =
          size.width - (verticalCenter + childSize.width);
    }

    var horizontalTopCrossOverflowDistance = 0.0;
    var horizontalBottomCrossOverflowDistance = 0.0;
    var horizontalCenterCrossOverflowDistance = 0.0;

    if (horizontalTop < 0) {
      horizontalTopCrossOverflowDistance = -horizontalTop;
    } else if (horizontalTop + childSize.height > size.height) {
      horizontalTopCrossOverflowDistance =
          size.height - (horizontalTop + childSize.height);
    }

    if (horizontalBottom < 0) {
      horizontalBottomCrossOverflowDistance = -horizontalBottom;
    } else if (horizontalBottom + childSize.height > size.height) {
      horizontalBottomCrossOverflowDistance =
          size.height - (horizontalBottom + childSize.height);
    }

    if (horizontalCenter < 0) {
      horizontalCenterCrossOverflowDistance = -horizontalCenter;
    } else if (horizontalCenter + childSize.height > size.height) {
      horizontalCenterCrossOverflowDistance =
          size.height - (horizontalCenter + childSize.height);
    }

    // target完全不可见时, 需要将层固定target到对应方向的末端
    if (targetRect.right < 0) {
      verticalCenterCrossOverflowDistance += targetRect.right;
      verticalRightCrossOverflowDistance += targetRect.right;
      verticalLeftCrossOverflowDistance += targetRect.right;
    } else if (targetRect.left > size.width) {
      verticalCenterCrossOverflowDistance += targetRect.left - size.width;
      verticalRightCrossOverflowDistance += targetRect.left - size.width;
      verticalLeftCrossOverflowDistance += targetRect.left - size.width;
    }

    if (targetRect.top < 0) {
      horizontalCenterCrossOverflowDistance += targetRect.bottom;
      horizontalBottomCrossOverflowDistance += targetRect.bottom;
      horizontalTopCrossOverflowDistance += targetRect.bottom;
    } else if (targetRect.top > size.height) {
      horizontalCenterCrossOverflowDistance += targetRect.top - size.height;
      horizontalBottomCrossOverflowDistance += targetRect.top - size.height;
      horizontalTopCrossOverflowDistance += targetRect.top - size.height;
    }

    meta[ZoPopperDirection.top] = _DirectionMeta(
      direction: ZoPopperDirection.top,
      position: topPosition,
      mainOverflow: topOverflow,
      crossOverflow: verticalCenterCrossOverflowDistance != 0.0,
      crossOverflowDistance: verticalCenterCrossOverflowDistance,
    );

    meta[ZoPopperDirection.topLeft] = _DirectionMeta(
      direction: ZoPopperDirection.topLeft,
      position: topLeftPosition,
      mainOverflow: topOverflow,
      crossOverflow: verticalLeftCrossOverflowDistance != 0.0,
      crossOverflowDistance: verticalLeftCrossOverflowDistance,
    );

    meta[ZoPopperDirection.topRight] = _DirectionMeta(
      direction: ZoPopperDirection.topRight,
      position: topRightPosition,
      mainOverflow: topOverflow,
      crossOverflow: verticalRightCrossOverflowDistance != 0.0,
      crossOverflowDistance: verticalRightCrossOverflowDistance,
    );

    meta[ZoPopperDirection.bottom] = _DirectionMeta(
      direction: ZoPopperDirection.bottom,
      position: bottomPosition,
      mainOverflow: bottomOverflow,
      crossOverflow: verticalCenterCrossOverflowDistance != 0.0,
      crossOverflowDistance: verticalCenterCrossOverflowDistance,
    );

    meta[ZoPopperDirection.bottomLeft] = _DirectionMeta(
      direction: ZoPopperDirection.bottomLeft,
      position: bottomLeftPosition,
      mainOverflow: bottomOverflow,
      crossOverflow: verticalLeftCrossOverflowDistance != 0.0,
      crossOverflowDistance: verticalLeftCrossOverflowDistance,
    );

    meta[ZoPopperDirection.bottomRight] = _DirectionMeta(
      direction: ZoPopperDirection.bottomRight,
      position: bottomRightPosition,
      mainOverflow: bottomOverflow,
      crossOverflow: verticalRightCrossOverflowDistance != 0.0,
      crossOverflowDistance: verticalRightCrossOverflowDistance,
    );

    meta[ZoPopperDirection.left] = _DirectionMeta(
      direction: ZoPopperDirection.left,
      position: leftPosition,
      mainOverflow: leftOverflow,
      crossOverflow: horizontalCenterCrossOverflowDistance != 0.0,
      crossOverflowDistance: horizontalCenterCrossOverflowDistance,
    );

    meta[ZoPopperDirection.leftTop] = _DirectionMeta(
      direction: ZoPopperDirection.leftTop,
      position: leftTopPosition,
      mainOverflow: leftOverflow,
      crossOverflow: horizontalTopCrossOverflowDistance != 0.0,
      crossOverflowDistance: horizontalTopCrossOverflowDistance,
    );

    meta[ZoPopperDirection.leftBottom] = _DirectionMeta(
      direction: ZoPopperDirection.leftBottom,
      position: leftBottomPosition,
      mainOverflow: leftOverflow,
      crossOverflow: horizontalBottomCrossOverflowDistance != 0.0,
      crossOverflowDistance: horizontalBottomCrossOverflowDistance,
    );

    meta[ZoPopperDirection.right] = _DirectionMeta(
      direction: ZoPopperDirection.right,
      position: rightPosition,
      mainOverflow: rightOverflow,
      crossOverflow: horizontalCenterCrossOverflowDistance != 0.0,
      crossOverflowDistance: horizontalCenterCrossOverflowDistance,
    );

    meta[ZoPopperDirection.rightTop] = _DirectionMeta(
      direction: ZoPopperDirection.rightTop,
      position: rightTopPosition,
      mainOverflow: rightOverflow,
      crossOverflow: horizontalTopCrossOverflowDistance != 0.0,
      crossOverflowDistance: horizontalTopCrossOverflowDistance,
    );

    meta[ZoPopperDirection.rightBottom] = _DirectionMeta(
      direction: ZoPopperDirection.rightBottom,
      position: rightBottomPosition,
      mainOverflow: rightOverflow,
      crossOverflow: horizontalBottomCrossOverflowDistance != 0.0,
      crossOverflowDistance: horizontalBottomCrossOverflowDistance,
    );

    return meta;
  }

  /// 根据方向 map 挑选当前合适的显示方向, 主要是执行 flip 操作
  _DirectionMeta _pickDirection(Map<ZoPopperDirection, _DirectionMeta> meta) {
    var curMeta = meta[entry.direction]!;

    if (curMeta.mainOverflow && entry.preventOverflow) {
      final revMeta = meta[_getReverseDirection(entry.direction!)]!;

      if (!revMeta.mainOverflow) {
        curMeta = revMeta;
      }
    }

    return curMeta;
  }

  /// 获取指定方向的相反方向
  ZoPopperDirection _getReverseDirection(ZoPopperDirection direction) {
    return switch (direction) {
      ZoPopperDirection.top => ZoPopperDirection.bottom,
      ZoPopperDirection.bottom => ZoPopperDirection.top,
      ZoPopperDirection.left => ZoPopperDirection.right,
      ZoPopperDirection.right => ZoPopperDirection.left,
      ZoPopperDirection.topLeft => ZoPopperDirection.bottomLeft,
      ZoPopperDirection.topRight => ZoPopperDirection.bottomRight,
      ZoPopperDirection.bottomLeft => ZoPopperDirection.topLeft,
      ZoPopperDirection.bottomRight => ZoPopperDirection.topRight,
      ZoPopperDirection.leftTop => ZoPopperDirection.rightTop,
      ZoPopperDirection.leftBottom => ZoPopperDirection.rightBottom,
      ZoPopperDirection.rightTop => ZoPopperDirection.leftTop,
      ZoPopperDirection.rightBottom => ZoPopperDirection.leftBottom,
    };
  }

  /// 检测方向是否是垂直方向
  bool _isVerticalDirection(ZoPopperDirection direction) {
    return direction == ZoPopperDirection.topLeft ||
        direction == ZoPopperDirection.topRight ||
        direction == ZoPopperDirection.top ||
        direction == ZoPopperDirection.bottomLeft ||
        direction == ZoPopperDirection.bottomRight ||
        direction == ZoPopperDirection.bottom;
  }

  /// 绘制 target 调试框
  /// ignore: unused_element
  void _debugTargetPosition(
    PaintingContext context,
    Offset offset,
    Rect target,
  ) {
    final t = target.shift(offset);
    context.canvas.drawRect(
      t.isEmpty ? t.inflate(2) : t,
      Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke,
    );
  }

  /// 绘制方向布局的调试框
  /// ignore: unused_element
  void _debugDirectionPosition(
    PaintingContext context,
    Offset offset,
    HashMap<ZoPopperDirection, _DirectionMeta> directionMetaMap,
  ) {
    for (var element in directionMetaMap.entries) {
      var x = element.value.position.dx + offset.dx;
      var y = element.value.position.dy + offset.dy;

      final isVertical = element.key.name.startsWith(RegExp(r"^(top|bottom)"));
      final isHorizontal = !isVertical;

      if (isVertical && element.value.crossOverflow) {
        x = x + element.value.crossOverflowDistance;
      }

      if (isHorizontal && element.value.crossOverflow) {
        y = y + element.value.crossOverflowDistance;
      }

      context.canvas.drawRect(
        Rect.fromLTWH(x, y, _childSize.width, _childSize.height),
        Paint()
          ..color = element.value.crossOverflow ? Colors.red : Colors.blue
          ..style = PaintingStyle.stroke,
      );
    }
  }
}

/// 方向定位中, 包含对应方向的位置和遮挡状态等信息
class _DirectionMeta {
  const _DirectionMeta({
    required this.direction,
    required this.position,
    required this.mainOverflow,
    required this.crossOverflow,
    required this.crossOverflowDistance,
  });

  /// 对应的方向
  final ZoPopperDirection direction;

  /// 位置
  final Offset position;

  /// 在该方向的主轴是否超出
  final bool mainOverflow;

  /// 在该方向的交叉轴是否超出
  final bool crossOverflow;

  /// 交叉轴溢出的距离, 为正数表示从开始方向溢出, 为负数表示从结束方向溢出, position
  /// 加上此值就可以得到修正后的位置
  final double crossOverflowDistance;
}

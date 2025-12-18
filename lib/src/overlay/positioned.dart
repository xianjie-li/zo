part of "package:zo/src/overlay/overlay.dart";

/// 为 Overlay 提供布局功能的核心组件, 它负责将子级通过 entry 给定的
///  offset / rect / alignment 之一在父级中进行定位,
/// 同时传入多个时, 按 offset > rect > alignment 的优先级进行定位
///
/// Positioned 还根据 preventOverflow direction 启用 popper 定位功能, 并通过 preventOverflow
/// 配置调整自身的位置
///
/// 依赖的 entry 属性有: offset / rect / alignment / direction / preventOverflow / constrainsToView
///
/// 定位目标 / 层 / 容器:
/// - 定位目标由 rect / offset / alignment 等定位属性确定
/// - 层指的是 renderObject.child 子对象, 其表示我们要绘制的层内容
/// - 容器是当前 RenderObject, 其所在空间为有效布局区域
///
/// 定位属性会由 globalPosition 转换为 localPosition 后再容器内进行定位
///
/// 超出容器的内容会视为 overflow
class ZoOverlayPositioned extends SingleChildRenderObjectWidget {
  const ZoOverlayPositioned({
    super.key,
    super.child,
    required this.entry,
    this.renderObjectRef,
  });

  /// 用于定位的层
  final ZoOverlayEntry entry;

  /// 通过此项访问底层的布局对象
  final ValueChanged<OverlayPositionedRenderObject?>? renderObjectRef;

  @override
  RenderObject createRenderObject(BuildContext context) {
    final obj = OverlayPositionedRenderObject(
      entry: entry,
      style: context.zoStyle,
    );
    renderObjectRef?.call(obj);
    return obj;
  }

  @override
  void updateRenderObject(
    BuildContext context,
    OverlayPositionedRenderObject renderObject,
  ) {
    if (renderObject.entry != entry ||
        renderObject.changeId != entry.changeId ||
        renderObject.style != context.zoStyle) {
      renderObject.entry = entry;
      renderObject.changeId = entry.changeId;
      renderObject.style = context.zoStyle;
      renderObject.markNeedsLayout();
    }
  }

  @override
  void didUnmountRenderObject(OverlayPositionedRenderObject renderObject) {
    renderObjectRef?.call(null);
    super.didUnmountRenderObject(renderObject);
  }
}

class OverlayPositionedRenderObject extends RenderBox
    with RenderObjectWithChildMixin<RenderBox> {
  OverlayPositionedRenderObject({required this.entry, required this.style});

  /// 与 entry 的变更id同步, 减少不必要更新
  double changeId = 0;

  /// 用于定位的层
  ZoOverlayEntry entry;

  /// 当前样式对象
  ZoStyle style;

  /// 获取层(子节点)的尺寸或 Size.zero
  Size get overlaySize =>
      (child == null || !child!.hasSize) ? Size.zero : child!.size;

  /// 最后一次绘制时的容器尺寸
  Rect? containerRect;

  /// 最后一次绘制时的层尺寸
  Rect? overlayRect;

  /// 最后一次方向布局中使用的方向
  ZoPopperDirection? direction;

  /// 手动指定布局位置, 设置后, 后续布局会优先使用此位置进行布局
  ///
  /// - 在 entry 中传入的位置变更后失效
  /// - 方向布局时无效
  Offset? get manualPosition => _manualPosition;
  Offset? _manualPosition;
  set manualPosition(Offset? value) {
    _manualPosition = value;
    markNeedsPaint();
  }

  /// 内部额外施加的布局约束，用于 [ZoOverlayEntry.constrainsToView] 将内容尺寸限制
  /// 到可用区域
  BoxConstraints? internalConstraints;

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

    // 清理残留的内部限制
    if (!entry.constrainsToView || entry.direction == null) {
      internalConstraints = null;
    }

    if (internalConstraints != null) {
      child!.layout(
        internalConstraints!.enforce(constraints.loosen()),
        parentUsesSize: true,
      );
    } else {
      child!.layout(constraints.loosen(), parentUsesSize: true);
    }

    // 该尺寸为 Positioned 的最大可用尺寸
    size = constraints.biggest;
  }

  Offset? lastOffset;

  Rect? lastRect;

  Alignment? lastAlignment;

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) return;

    /// entry 的位置发生变更时, 清理手动设置的位置
    if (lastOffset != entry.offset ||
        lastRect != entry.rect ||
        lastAlignment != entry.alignment ||
        entry.direction != null) {
      _manualPosition = null;
    }

    lastOffset = entry.offset;
    lastRect = entry.rect;
    lastAlignment = entry.alignment;

    // 执行常规布局还是方向布局
    Offset layoutOffset;
    ZoDirectionLayoutData? directionLayoutData;

    // 由于 _regularLayout 等方法使用了 globalToLocal, 所以只能在绘制阶段进行响应,
    // 因为布局阶段对象位置还未确定
    if (manualPosition != null) {
      layoutOffset = manualPosition!;
    } else if (entry.direction == null) {
      layoutOffset = _regularLayout();
    } else {
      (layoutOffset, directionLayoutData) = _directionLayout(context, offset);
      direction = directionLayoutData.direction;
    }

    _updateAvailableSpace(directionLayoutData);

    final BoxParentData childParentData = child!.parentData as BoxParentData;

    childParentData.offset = layoutOffset;

    containerRect = Rect.fromLTWH(
      offset.dx,
      offset.dy,
      size.width,
      size.height,
    );

    overlayRect = Rect.fromLTWH(
      layoutOffset.dx + offset.dx,
      layoutOffset.dy + offset.dy,
      overlaySize.width,
      overlaySize.height,
    );

    /// 如果不可见则不进行渲染
    if (!containerRect!.overlaps(overlayRect!)) return;

    // 裁剪不可见部分
    context.clipRectAndPaint(containerRect!, Clip.hardEdge, containerRect!, () {
      final pOffset = offset + layoutOffset;

      // 绘制
      context.paintChild(child!, pOffset);

      // 层自定义绘制
      entry.customPaint(
        this,
        context,
        ZoOverlayCustomPaintData(
          offset: pOffset,
          directionLayoutData: directionLayoutData,
        ),
      );
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

    return entry.alignment!.alongOffset((size - overlaySize) as Offset);
  }

  /// 根据方向布局获取层定位位置, 按以下步骤进行:
  ///
  /// - 获取 target
  /// - 获取不同方向的摆放位置, 位置需要加上 distance, 并包含 hasOverflow 信息
  /// - 如果未设置 preventOverflow 或无遮挡, 直接根据方向返回位置
  /// - flip: 挑选合适方向进行放置，并对交叉轴使用偏移，使其保持在视口中
  /// - 当前使用位置/交叉轴偏移调整等需要向上通知, 方便使用者对 popper arrow 等进行位置调整
  (Offset, ZoDirectionLayoutData) _directionLayout(
    PaintingContext context,
    Offset offset,
  ) {
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

    final directionDataMap = _calcDirectionDataMap(target);

    final curDirectionData = _pickDirection(directionDataMap);

    // _debugTargetPosition(context, offset, target);
    // _debugDirectionPosition(context, offset, directionDataMap);

    var x = curDirectionData.position.dx;
    var y = curDirectionData.position.dy;

    // 交叉轴存在遮挡时, 修正其位置
    if (curDirectionData.crossOverflow && entry.preventOverflow) {
      final isVertical = isVerticalDirection(curDirectionData.direction);
      final isHorizontal = !isVertical;

      if (isVertical) {
        x = x + curDirectionData.crossOverflowDistance;
      } else if (isHorizontal) {
        y = y + curDirectionData.crossOverflowDistance;
      }
    }

    return (Offset(x, y), curDirectionData);
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

  /// 一个复杂的方法 :) 它获取指定目標不同方向的放置位置和遮挡状态
  HashMap<ZoPopperDirection, ZoDirectionLayoutData> _calcDirectionDataMap(
    Rect targetRect,
  ) {
    final oSize = overlaySize;
    final data = HashMap<ZoPopperDirection, ZoDirectionLayoutData>();

    final halfChildWidth = oSize.width / 2;
    final halfChildHeight = oSize.height / 2;

    /// 纵轴不同位置的偏移
    final verticalCenter = targetRect.center.dx - halfChildWidth;
    final verticalLeft = targetRect.left;
    final verticalRight = targetRect.right - oSize.width;

    /// 横轴不同位置的偏移
    final horizontalCenter = targetRect.center.dy - halfChildHeight;
    final horizontalTop = targetRect.top;
    final horizontalBottom = targetRect.bottom - oSize.height;

    /// 不同方向的位置
    final topPosition = Offset(
      verticalCenter,
      targetRect.top - oSize.height - entry.distance,
    );

    final topLeftPosition = Offset(verticalLeft, topPosition.dy);

    final topRightPosition = Offset(verticalRight, topPosition.dy);

    final bottomPosition = Offset(
      verticalCenter,
      targetRect.bottom + entry.distance,
    );

    final bottomLeftPosition = Offset(verticalLeft, bottomPosition.dy);

    final bottomRightPosition = Offset(verticalRight, bottomPosition.dy);

    final leftPosition = Offset(
      targetRect.left - oSize.width - entry.distance,
      horizontalCenter,
    );

    final leftTopPosition = Offset(leftPosition.dx, horizontalTop);

    final leftBottomPosition = Offset(leftPosition.dx, horizontalBottom);

    final rightPosition = Offset(
      targetRect.right + entry.distance,
      horizontalCenter,
    );

    final rightTopPosition = Offset(rightPosition.dx, horizontalTop);

    final rightBottomPosition = Offset(rightPosition.dx, horizontalBottom);

    /// 主轴遮挡计算
    final topOverflow = topPosition.dy < 0;

    final bottomOverflow = bottomPosition.dy + oSize.height > size.height;

    final leftOverflow = leftPosition.dx < 0;

    final rightOverflow = rightPosition.dx + oSize.width > size.width;

    /// 交叉轴遮挡计算
    var verticalLeftCrossOverflowDistance = 0.0;
    var verticalRightCrossOverflowDistance = 0.0;
    var verticalCenterCrossOverflowDistance = 0.0;

    // 层超出有效区域时, 根据超出位置进行修正
    if (verticalLeft < 0) {
      verticalLeftCrossOverflowDistance = -verticalLeft;
    } else if (verticalLeft + oSize.width > size.width) {
      verticalLeftCrossOverflowDistance =
          size.width - (verticalLeft + oSize.width);
    }

    if (verticalRight < 0) {
      verticalRightCrossOverflowDistance = -verticalRight;
    } else if (verticalRight + oSize.width > size.width) {
      verticalRightCrossOverflowDistance =
          size.width - (verticalRight + oSize.width);
    }

    if (verticalCenter < 0) {
      verticalCenterCrossOverflowDistance = -verticalCenter;
    } else if (verticalCenter + oSize.width > size.width) {
      verticalCenterCrossOverflowDistance =
          size.width - (verticalCenter + oSize.width);
    }

    var horizontalTopCrossOverflowDistance = 0.0;
    var horizontalBottomCrossOverflowDistance = 0.0;
    var horizontalCenterCrossOverflowDistance = 0.0;

    if (horizontalTop < 0) {
      horizontalTopCrossOverflowDistance = -horizontalTop;
    } else if (horizontalTop + oSize.height > size.height) {
      horizontalTopCrossOverflowDistance =
          size.height - (horizontalTop + oSize.height);
    }

    if (horizontalBottom < 0) {
      horizontalBottomCrossOverflowDistance = -horizontalBottom;
    } else if (horizontalBottom + oSize.height > size.height) {
      horizontalBottomCrossOverflowDistance =
          size.height - (horizontalBottom + oSize.height);
    }

    if (horizontalCenter < 0) {
      horizontalCenterCrossOverflowDistance = -horizontalCenter;
    } else if (horizontalCenter + oSize.height > size.height) {
      horizontalCenterCrossOverflowDistance =
          size.height - (horizontalCenter + oSize.height);
    }

    // target 超出视口时, 层需要固定在 target 末端的最小距离, 可以在视觉上防止气泡框的箭头不与 target 对齐
    // 如果模板尺寸小于值, 则使用模板尺寸(完全对其对应方向的开始一侧)
    final xFollowDistance = math.min(26.0, targetRect.width);
    final yFollowDistance = math.min(26.0, targetRect.height);

    // target完全不可见时, 需要将层固定target到对应方向的末端
    if (targetRect.right < xFollowDistance) {
      final fixPos = targetRect.right - xFollowDistance;

      verticalCenterCrossOverflowDistance += fixPos;
      verticalRightCrossOverflowDistance += fixPos;
      verticalLeftCrossOverflowDistance += fixPos;
    } else if (targetRect.left > size.width - xFollowDistance) {
      final fixPos = targetRect.left - size.width + xFollowDistance;

      verticalCenterCrossOverflowDistance += fixPos;
      verticalRightCrossOverflowDistance += fixPos;
      verticalLeftCrossOverflowDistance += fixPos;
    }

    if (targetRect.bottom < yFollowDistance) {
      final fixPos = targetRect.bottom - yFollowDistance;

      horizontalCenterCrossOverflowDistance += fixPos;
      horizontalBottomCrossOverflowDistance += fixPos;
      horizontalTopCrossOverflowDistance += fixPos;
    } else if (targetRect.top > size.height - yFollowDistance) {
      final fixPos = targetRect.top - size.height + yFollowDistance;

      horizontalCenterCrossOverflowDistance += fixPos;
      horizontalBottomCrossOverflowDistance += fixPos;
      horizontalTopCrossOverflowDistance += fixPos;
    }

    final topAvailableSpace = Size(
      size.width,
      targetRect.top,
    );

    final bottomAvailableSpace = Size(
      size.width,
      size.height - targetRect.bottom,
    );

    final leftAvailableSpace = Size(
      targetRect.left,
      size.height,
    );

    final rightAvailableSpace = Size(
      size.width - targetRect.right,
      size.height,
    );

    data[ZoPopperDirection.top] = ZoDirectionLayoutData(
      direction: ZoPopperDirection.top,
      position: topPosition,
      mainOverflow: topOverflow,
      crossOverflow: verticalCenterCrossOverflowDistance != 0.0,
      crossOverflowDistance: verticalCenterCrossOverflowDistance,
      availableSpace: topAvailableSpace,
    );

    data[ZoPopperDirection.topLeft] = ZoDirectionLayoutData(
      direction: ZoPopperDirection.topLeft,
      position: topLeftPosition,
      mainOverflow: topOverflow,
      crossOverflow: verticalLeftCrossOverflowDistance != 0.0,
      crossOverflowDistance: verticalLeftCrossOverflowDistance,
      availableSpace: topAvailableSpace,
    );

    data[ZoPopperDirection.topRight] = ZoDirectionLayoutData(
      direction: ZoPopperDirection.topRight,
      position: topRightPosition,
      mainOverflow: topOverflow,
      crossOverflow: verticalRightCrossOverflowDistance != 0.0,
      crossOverflowDistance: verticalRightCrossOverflowDistance,
      availableSpace: topAvailableSpace,
    );

    data[ZoPopperDirection.bottom] = ZoDirectionLayoutData(
      direction: ZoPopperDirection.bottom,
      position: bottomPosition,
      mainOverflow: bottomOverflow,
      crossOverflow: verticalCenterCrossOverflowDistance != 0.0,
      crossOverflowDistance: verticalCenterCrossOverflowDistance,
      availableSpace: bottomAvailableSpace,
    );

    data[ZoPopperDirection.bottomLeft] = ZoDirectionLayoutData(
      direction: ZoPopperDirection.bottomLeft,
      position: bottomLeftPosition,
      mainOverflow: bottomOverflow,
      crossOverflow: verticalLeftCrossOverflowDistance != 0.0,
      crossOverflowDistance: verticalLeftCrossOverflowDistance,
      availableSpace: bottomAvailableSpace,
    );

    data[ZoPopperDirection.bottomRight] = ZoDirectionLayoutData(
      direction: ZoPopperDirection.bottomRight,
      position: bottomRightPosition,
      mainOverflow: bottomOverflow,
      crossOverflow: verticalRightCrossOverflowDistance != 0.0,
      crossOverflowDistance: verticalRightCrossOverflowDistance,
      availableSpace: bottomAvailableSpace,
    );

    data[ZoPopperDirection.left] = ZoDirectionLayoutData(
      direction: ZoPopperDirection.left,
      position: leftPosition,
      mainOverflow: leftOverflow,
      crossOverflow: horizontalCenterCrossOverflowDistance != 0.0,
      crossOverflowDistance: horizontalCenterCrossOverflowDistance,
      availableSpace: leftAvailableSpace,
    );

    data[ZoPopperDirection.leftTop] = ZoDirectionLayoutData(
      direction: ZoPopperDirection.leftTop,
      position: leftTopPosition,
      mainOverflow: leftOverflow,
      crossOverflow: horizontalTopCrossOverflowDistance != 0.0,
      crossOverflowDistance: horizontalTopCrossOverflowDistance,
      availableSpace: leftAvailableSpace,
    );

    data[ZoPopperDirection.leftBottom] = ZoDirectionLayoutData(
      direction: ZoPopperDirection.leftBottom,
      position: leftBottomPosition,
      mainOverflow: leftOverflow,
      crossOverflow: horizontalBottomCrossOverflowDistance != 0.0,
      crossOverflowDistance: horizontalBottomCrossOverflowDistance,
      availableSpace: leftAvailableSpace,
    );

    data[ZoPopperDirection.right] = ZoDirectionLayoutData(
      direction: ZoPopperDirection.right,
      position: rightPosition,
      mainOverflow: rightOverflow,
      crossOverflow: horizontalCenterCrossOverflowDistance != 0.0,
      crossOverflowDistance: horizontalCenterCrossOverflowDistance,
      availableSpace: rightAvailableSpace,
    );

    data[ZoPopperDirection.rightTop] = ZoDirectionLayoutData(
      direction: ZoPopperDirection.rightTop,
      position: rightTopPosition,
      mainOverflow: rightOverflow,
      crossOverflow: horizontalTopCrossOverflowDistance != 0.0,
      crossOverflowDistance: horizontalTopCrossOverflowDistance,
      availableSpace: rightAvailableSpace,
    );

    data[ZoPopperDirection.rightBottom] = ZoDirectionLayoutData(
      direction: ZoPopperDirection.rightBottom,
      position: rightBottomPosition,
      mainOverflow: rightOverflow,
      crossOverflow: horizontalBottomCrossOverflowDistance != 0.0,
      crossOverflowDistance: horizontalBottomCrossOverflowDistance,
      availableSpace: rightAvailableSpace,
    );

    return data;
  }

  /// 根据方向 map 挑选当前合适的显示方向, 简要流程见 [_directionLayout] 文档
  ZoDirectionLayoutData _pickDirection(
    Map<ZoPopperDirection, ZoDirectionLayoutData> data,
  ) {
    final curData = data[entry.direction]!;

    // 如果未开启防遮挡，直接返回原始数据
    if (!entry.preventOverflow) return curData;

    // 指定方向可用
    if (_isDirectionCapable(curData)) {
      return curData;
    }

    // 相反方向可用
    final revData = data[_getReverseDirection(entry.direction!)]!;
    if (_isDirectionCapable(revData)) {
      return revData;
    }

    // 寻找最佳的其他方向，代码走到这里，说明上下(或左右)都彻底放不下了，需要在剩余方向中寻找一个
    // - 首选：能完全容纳的
    // - 次选：如果都不能完全容纳，选可视面积最大的

    ZoDirectionLayoutData? bestCandidate;
    double maxVisibleArea = -1.0;

    // 用来标记是否找到了完美适配的方向，如果找到了，就不再考虑那些会被裁剪的方向了
    bool foundCapable = false;

    for (final candidate in data.values) {
      if (candidate == curData || candidate == revData) continue;

      final bool isCapable = _isDirectionCapable(candidate);

      // 如果我们已经找到了完美适配的方向，就忽略那些不能适配的
      if (foundCapable && !isCapable) continue;

      // 如果当前是完美适配，但之前没找到过，通过 foundCapable 标记提升优先级
      if (isCapable && !foundCapable) {
        foundCapable = true;
        maxVisibleArea = -1.0; // 重置最大面积，因为之前的面积是基于"会被裁剪"的那些计算的
      }

      // 计算可视面积
      // 如果 isCapable 为 true，这里的 area 其实就是完整面积
      // 如果 isCapable 为 false，这里计算的是裁剪后的面积
      final double visibleWidth = candidate.availableSpace.width.clamp(
        0.0,
        overlaySize.width,
      );
      final double visibleHeight = candidate.availableSpace.height.clamp(
        0.0,
        overlaySize.height,
      );
      final double area = visibleWidth * visibleHeight;

      if (area > maxVisibleArea) {
        maxVisibleArea = area;
        bestCandidate = candidate;
      }
    }

    return bestCandidate ?? curData;
  }

  /// 判断方向是否有能力完全展示弹层
  /// - 主轴必须不溢出
  /// - 交叉轴虽然可能溢出，但总空间必须足够容纳弹层，可通过位置偏移修复
  bool _isDirectionCapable(ZoDirectionLayoutData data) {
    // 主轴溢出，无法通过偏移修复
    if (data.mainOverflow) return false;

    // 交叉轴没有溢出
    if (!data.crossOverflow) return true;

    // 如果交叉轴溢出了，检查是否有足够的空间通过偏移来修复
    // 获取当前方向对应的交叉轴尺寸限制
    final double availableCrossSize = isVerticalDirection(data.direction)
        ? data.availableSpace.width
        : data.availableSpace.height;

    // 获取弹层在该交叉轴上的实际尺寸
    final double overlayCrossSize = isVerticalDirection(data.direction)
        ? overlaySize.width
        : overlaySize.height;

    // 只要总空间够大，我们认为可以通过偏移修复，所以视为可用
    // 允许 1 像素的误差容忍
    return availableCrossSize >= (overlayCrossSize - 1.0);
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

  /// 传入方向布局的 directionLayoutData，更新 [internalConstraints] 并按需触发绘制
  void _updateAvailableSpace(
    ZoDirectionLayoutData? directionLayoutData,
  ) {
    if (directionLayoutData == null ||
        !entry.constrainsToView ||
        entry.direction == null) {
      internalConstraints = null;
      return;
    }

    final availableSpace = directionLayoutData.availableSpace;

    final newConstraints = BoxConstraints(
      maxWidth: availableSpace.width,
      maxHeight: availableSpace.height,
    ).normalize();

    final changed = newConstraints != internalConstraints;

    final hasOverflow =
        overlaySize.width > availableSpace.width ||
        overlaySize.height > availableSpace.height;

    if (changed && hasOverflow) {
      internalConstraints = newConstraints;

      WidgetsBinding.instance.addPostFrameCallback((d) {
        if (attached) {
          markNeedsLayout();
        }
      });
    }
  }
}

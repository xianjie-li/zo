part of "dnd.dart";

mixin _ZoDNDAutoScrollMixin {
  /// 存储滚动父级信息，在每次拖动开始时获取，并在该次拖动中复用
  final HashMap<ScrollableState, Rect> _scrollStates = HashMap();

  /// 应该被视为自动滚动边缘的尺寸比例
  final double _autoScrollEdgeRatio = 0.14;

  // 定义最大滚动速度
  final double _maxAutoScrollSpeed = 20.0; // 每 tick 20 像素

  /// 自动滚动计时器
  Timer? _scrollTimer;

  /// 自动滚动速度
  Offset _currentScrollSpeed = Offset.zero;

  /// 当前活动的滚动位置控制器
  ScrollPosition? _activeScrollPosition; // <-- 跟踪当前正在滚动的 Position

  /// 处理拖动到滚动容器边缘时的自动滚动
  void _autoDragScrollHandle({
    required ZoTriggerDragEvent event,
    required List<_ZoDNDNode> groupNodes,
  }) {
    // 开始拖动时，获取所有滚动节点信息
    if (event.first) {
      _scrollStates.clear();

      for (final node in groupNodes) {
        final parentData = node.getScrollParent();

        if (parentData != null) {
          _scrollStates[parentData.$1] = parentData.$2;
        }
      }
      return;
    }

    // 结束拖动时进行清理
    if (event.last || event.canceled) {
      _scrollStates.clear();
      _stopAutoScroll();
      return;
    }

    if (_scrollStates.isEmpty) return;

    // 获取在当前拖动区域的容器，并尽量获取到widget层级中最深的
    MapEntry<ScrollableState, Rect>? activeEntry;

    for (final entries in _scrollStates.entries) {
      final rect = entries.value;

      if (entries.value.contains(event.position)) {
        if (activeEntry == null) {
          activeEntry = entries;
        } else if (_someAxisLessThen(activeEntry.value, rect)) {
          // 如果当前rect任意一个轴尺寸小于前一个容器，我们就理想的认为它在widget树的更深层级中，这在大多数场景中是可靠的
          activeEntry = entries;
        }
      }
    }

    if (activeEntry == null) return;

    // 当前拖动的位置
    final dragPosition = event.position;

    // 滚动状态对象
    final scrollState = activeEntry.key;

    // scrollState 所在容器的尺寸和位置
    final scrollRect = activeEntry.value;

    // 滚动控制
    final scrollPosition = scrollState.position;

    // 如果内容根本无法滚动，则直接返回
    if (scrollPosition.maxScrollExtent <= scrollPosition.minScrollExtent) {
      _stopAutoScroll();
      return;
    }

    // 定义热区尺寸
    final double verticalHotZoneHeight =
        scrollRect.height * _autoScrollEdgeRatio;
    final double horizontalHotZoneWidth =
        scrollRect.width * _autoScrollEdgeRatio;

    // 定义四个热区的全局 Rect
    final Rect topHotZone = Rect.fromLTRB(
      scrollRect.left,
      scrollRect.top,
      scrollRect.right,
      scrollRect.top + verticalHotZoneHeight,
    );
    final Rect bottomHotZone = Rect.fromLTRB(
      scrollRect.left,
      scrollRect.bottom - verticalHotZoneHeight,
      scrollRect.right,
      scrollRect.bottom,
    );
    final Rect leftHotZone = Rect.fromLTRB(
      scrollRect.left,
      scrollRect.top,
      scrollRect.left + horizontalHotZoneWidth,
      scrollRect.bottom,
    );
    final Rect rightHotZone = Rect.fromLTRB(
      scrollRect.right - horizontalHotZoneWidth,
      scrollRect.top,
      scrollRect.right,
      scrollRect.bottom,
    );

    // 计算期望的滚动速度 (dx, dy)
    double dy = 0.0;
    double dx = 0.0;

    // 检查垂直方向
    if (topHotZone.contains(dragPosition)) {
      final double distance = topHotZone.bottom - dragPosition.dy;
      final double normalizedSpeed = (distance / verticalHotZoneHeight).clamp(
        0.0,
        1.0,
      );
      dy = -_maxAutoScrollSpeed * normalizedSpeed;
    } else if (bottomHotZone.contains(dragPosition)) {
      final double distance = dragPosition.dy - bottomHotZone.top;
      final double normalizedSpeed = (distance / verticalHotZoneHeight).clamp(
        0.0,
        1.0,
      );
      dy = _maxAutoScrollSpeed * normalizedSpeed;
    }

    // 检查水平方向
    if (leftHotZone.contains(dragPosition)) {
      final double distance = leftHotZone.right - dragPosition.dx;
      final double normalizedSpeed = (distance / horizontalHotZoneWidth).clamp(
        0.0,
        1.0,
      );
      dx = -_maxAutoScrollSpeed * normalizedSpeed;
    } else if (rightHotZone.contains(dragPosition)) {
      final double distance = dragPosition.dx - rightHotZone.left;
      final double normalizedSpeed = (distance / horizontalHotZoneWidth).clamp(
        0.0,
        1.0,
      );
      dx = _maxAutoScrollSpeed * normalizedSpeed;
    }

    final Offset desiredSpeed = Offset(dx, dy);

    // 启动或停止定时器
    // 如果拖动位置不在滚动容器内，或者计算出的速度为0，则停止
    if (desiredSpeed == Offset.zero || !scrollRect.contains(dragPosition)) {
      _stopAutoScroll();
    } else {
      // 否则，启动或维持滚动
      _startAutoScroll(scrollPosition, desiredSpeed);
    }
  }

  /// 启动或维持自动滚动
  void _startAutoScroll(ScrollPosition scrollPosition, Offset speed) {
    // 更新当前期望的速度
    _currentScrollSpeed = speed;
    // 记录我们正在驱动哪个 ScrollPosition
    _activeScrollPosition = scrollPosition;

    // 如果定时器已在运行，它会在下一个 tick 自动使用新的 _currentScrollSpeed
    if (_scrollTimer != null) {
      return;
    }

    _scrollTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_activeScrollPosition == null) {
        _stopAutoScroll();
        return;
      }

      final pos = _activeScrollPosition!;
      double scrollSpeed = 0.0;

      // 检查滚动轴，并只应用该轴的速度
      if (pos.axis == Axis.vertical) {
        scrollSpeed = _currentScrollSpeed.dy;
      } else if (pos.axis == Axis.horizontal) {
        scrollSpeed = _currentScrollSpeed.dx;
      }

      if (scrollSpeed == 0.0) {
        // 如果计算出的速度为0 (例如，一个垂直列表但只在水平热区)，则停止
        _stopAutoScroll();
        return;
      }

      // 检查是否还能朝那个方向滚动
      final bool canScroll =
          (scrollSpeed < 0 && pos.pixels > pos.minScrollExtent) ||
          (scrollSpeed > 0 && pos.pixels < pos.maxScrollExtent);

      if (canScroll) {
        final newOffset = (pos.pixels + scrollSpeed).clamp(
          pos.minScrollExtent,
          pos.maxScrollExtent,
        );
        pos.jumpTo(newOffset);
      } else {
        _stopAutoScroll();
      }
    });
  }

  /// 停止自动滚动
  void _stopAutoScroll() {
    _scrollTimer?.cancel();
    _scrollTimer = null;
    _currentScrollSpeed = Offset.zero;
    _activeScrollPosition = null;
  }

  /// 检测 rect2 是否有任意一个轴小于 rect1
  bool _someAxisLessThen(Rect rect1, Rect rect2) {
    if (rect2.left > rect1.left && rect2.right < rect1.right) {
      return true;
    }

    if (rect2.top > rect1.top && rect2.bottom < rect1.bottom) {
      return true;
    }

    return false;
  }
}

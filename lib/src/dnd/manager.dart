part of "dnd.dart";

/// 管理所有 dnd 节点并处理命中等逻辑
class _ZoDNDManager with _ZoDNDAutoScrollMixin {
  static final _ZoDNDManager instance = _ZoDNDManager._internal();

  static _ZoDNDManager _internal() {
    // 减小可见性反馈间隔
    VisibilityDetectorController.instance.updateInterval = Durations.short2;
    return _ZoDNDManager();
  }

  /// 视为边缘位置的尺寸比例
  final _edgeRatio = 0.24;

  /// 以id 为 key 存储的 dnd 节点信息，对于已经卸载的 dnd 应该将其移除，防止 map 过于庞大
  final HashMap<String, _ZoDNDNode> _dndNodes = HashMap();

  /// 当前视图id，设置后，getGroup 等api会将结果限制到匹配的视口, 防止不同视口的dnd互相干扰
  /// 通常需要在节点开始拖动时，将拖动节点的viewId设置为当前视图id，防止错误的匹配到其他窗口
  int? currentViewId;

  /// 正在拖动的节点
  _ZoDNDNode? dragNode;

  /// 当前存在激活位置的节点
  _ZoDNDNode? activeNode;

  /// 当前 activeNode 的激活位置
  var activePosition = const ZoDNDPosition();

  /// 移除指定DND
  void remove(String id) {
    _dndNodes.remove(id);
  }

  /// 获取指定DND
  _ZoDNDNode? get(String id) {
    return _dndNodes[id];
  }

  /// 添加DND, 如果对应的 node.id 已存在则替换
  void add(_ZoDNDNode node) {
    _dndNodes[node.id] = node;
  }

  /// 检测node的关键信息是否都有效，这通常意味着节点时可见的
  bool isValidNode(_ZoDNDNode node) {
    return node.visibleRect != null &&
        node.viewId != null &&
        node.renderBox != null;
  }

  /// 获取指定组的所有有效DND, 若已设置 [currentViewId] 会将结果限制到该 viewId 下
  List<_ZoDNDNode> getGroup(Object? groupId) {
    final List<_ZoDNDNode> list = [];

    for (final entry in _dndNodes.entries) {
      final node = entry.value;
      if (node.dnd.groupId == groupId && isValidNode(node)) {
        if (currentViewId == null || node.viewId == currentViewId) {
          list.add(node);
        }
      }
    }

    return list;
  }

  /// 获取指定位置命中的dnd以及该组所有dnd节点
  (_ZoDNDNode?, List<_ZoDNDNode>) findHitDNDs(
    Offset position, {
    Object? groupId,
    bool Function(_ZoDNDNode node)? filter,
  }) {
    assert(currentViewId != null);

    final list = getGroup(groupId);

    final HashSet<_ZoDNDNode> matchList = HashSet();

    for (final node in list) {
      if (node.visibleRect != null && node.visibleRect!.contains(position)) {
        if (filter != null) {
          if (filter(node)) {
            matchList.add(node);
          }
        } else {
          matchList.add(node);
        }
      }
    }

    if (matchList.length <= 1) {
      return (matchList.firstOrNull, list);
    }

    // 有多个时，按命中顺序确定谁在上方
    final HitTestResult result = HitTestResult();

    WidgetsBinding.instance.hitTestInView(
      result,
      position,
      currentViewId!,
    );

    final renderBoxMap = HashMap<RenderBox, _ZoDNDNode>();

    for (final node in matchList) {
      renderBoxMap[node.renderBox!] = node;
    }

    // 获取第一个匹配项
    for (final entry in result.path) {
      final match = renderBoxMap[entry.target];

      if (match != null) {
        return (match, list);
      }
    }

    return (null, list);
  }

  /// 判定当前命中的位置, 调用者需要确保节点处于可见状态
  ZoDNDPosition detectHitPosition({
    required _ZoDNDNode node,
    required Offset position,
  }) {
    final droppablePosition = node.droppablePosition;
    final rect = node.rect;

    if (!droppablePosition.any || rect == null) {
      return const ZoDNDPosition();
    }

    if (droppablePosition.left) {
      final start = rect.left;
      final end = rect.left + rect.width * _edgeRatio;

      if (position.dx >= start && position.dx < end) {
        return const ZoDNDPosition(left: true);
      }
    }

    if (droppablePosition.right) {
      final start = rect.right - rect.width * _edgeRatio;
      final end = rect.right;

      if (position.dx >= start && position.dx < end) {
        return const ZoDNDPosition(right: true);
      }
    }

    if (droppablePosition.top) {
      final start = rect.top;
      final end = rect.top + rect.height * _edgeRatio;

      if (position.dy >= start && position.dy < end) {
        return const ZoDNDPosition(top: true);
      }
    }

    if (droppablePosition.bottom) {
      final start = rect.bottom - rect.height * _edgeRatio;
      final end = rect.bottom;

      if (position.dy >= start && position.dy < end) {
        return const ZoDNDPosition(bottom: true);
      }
    }

    return droppablePosition.center
        ? const ZoDNDPosition(center: true)
        : const ZoDNDPosition();
  }

  /// 通知给定node的widget更新
  void _updateNodes(List<_ZoDNDNode?> nodes) {
    for (final node in nodes) {
      node?.updateWidget();
    }
  }

  /// 显示 feedback 的层
  ZoOverlayEntry? _feedbackEntry;

  /// feedback偏移
  Offset? _feedbackOffset;

  /// feedback的创建显示等处理
  void _feedbackHandle({
    required ZoTriggerDragEvent event,
    required _ZoDNDNode dragNode,
    required BuildContext context,
  }) {
    if (event.first) {
      // 创建 overlay 实例显示 feedback
      final size = dragNode.rect?.size ?? const Size(80, 20);

      final dnd = dragNode.dnd;

      final textStyle = DefaultTextStyle.of(context);

      // 记录偏移位置
      _feedbackOffset = dnd.feedbackOffset ?? event.offset;

      // 反馈节点
      Widget child;

      // 如果是自定义反馈，不需要设置尺寸、默认文本样式、透明度等
      var isCustomFeedback = false;

      // 使用自定义反馈节点或根据widget配置构造
      if (dnd.feedback != null) {
        child = dnd.feedback!;
        isCustomFeedback = true;

        // 如果是自定义 feedback, 不使用开始拖动的位置作为偏移, 默认使其右移一些防止被光标遮挡
        _feedbackOffset = dragNode.dnd.feedbackOffset ?? const Offset(-12, 6);
      } else if (dnd.builder != null) {
        child = dnd.builder!(
          context,
          // 一个模拟的空 dnd context，用于还原节点
          ZoDNDBuildContext(
            dragging: false,
            droppablePosition: const ZoDNDPosition(),
            activePosition: const ZoDNDPosition(),
          ),
        );
      } else {
        child = dnd.child!;
      }

      _feedbackEntry = ZoOverlayEntry(
        offset: event.position - _feedbackOffset!,
        tapAwayClosable: false,
        escapeClosable: false,
        requestFocus: false,
        preventOverflow: false,
        duration: Duration.zero,
        // 需要直接在层的根级添加 IgnorePointer，否则会导致 findHitDNDs 处理重叠节点时使用命中测试命中 feedback 节点
        customWrap: (context, child) {
          return IgnorePointer(
            child: child,
          );
        },
        builder: (context) {
          if (isCustomFeedback) return child;

          final wrappedChild = dragNode.dnd.feedbackWrap == null
              ? child
              : dragNode.dnd.feedbackWrap!(context, child);

          return SizedBox.fromSize(
            size: size,
            child: Opacity(
              opacity: dragNode.dnd.feedbackOpacity,
              child: textStyle.wrap(
                context,
                wrappedChild,
              ),
            ),
          );
        },
      );

      zoOverlay.open(_feedbackEntry!);
    } else if (event.last) {
      // 销毁
      if (_feedbackEntry != null) {
        _feedbackEntry!.disposeSelf();
        _feedbackEntry = null;
        _feedbackOffset = null;
      }
    } else {
      // 更新位置
      if (_feedbackEntry != null) {
        _feedbackEntry!.offset =
            event.position - (_feedbackOffset ?? Offset.zero);
      }
    }
  }

  /// 显示 directionIndicator 的层
  ZoOverlayEntry? _directionIndicatorEntry;

  /// 方向指示器处理
  void _directionIndicatorHandle({
    required ZoTriggerDragEvent event,
    required _ZoDNDNode dragNode,
    required BuildContext context,
    required ZoDNDPosition activePosition,
  }) {
    if (event.last ||
        event.canceled ||
        (event.first && _directionIndicatorEntry != null)) {
      if (_directionIndicatorEntry != null) {
        _directionIndicatorEntry!.disposeSelf();
        _directionIndicatorEntry = null;
      }

      return;
    }

    final showIndicator = activeNode?.dnd.directionIndicator ?? false;

    final shouldShow =
        showIndicator &&
        (activePosition.top ||
            activePosition.right ||
            activePosition.bottom ||
            activePosition.left);

    final nodeRect = activeNode?.rect;

    // 没有要显示的东西
    if (!shouldShow || activeNode == null || nodeRect == null) {
      // 清空显示
      if (_directionIndicatorEntry != null) {
        _directionIndicatorEntry!.offset = Offset.zero;
        _directionIndicatorEntry!.builder = (context) {
          return const SizedBox.shrink();
        };
      }

      return;
    }

    // 显示在哪个方向
    ZoPopperDirection direction = ZoPopperDirection.bottom;

    // Indicator 的宽或高
    var size = 0.0;

    // 参照位置
    final rect = nodeRect.inflate(dragNode.dnd.directionIndicatorOffset ?? 0);

    var isVertical = false;

    if (activePosition.left) {
      direction = ZoPopperDirection.left;
      size = nodeRect.height;
    } else if (activePosition.right) {
      direction = ZoPopperDirection.right;
      size = nodeRect.height;
    } else if (activePosition.top) {
      direction = ZoPopperDirection.top;
      size = nodeRect.width;
      isVertical = true;
    } else if (activePosition.bottom) {
      direction = ZoPopperDirection.bottom;
      size = nodeRect.width;
      isVertical = true;
    }

    Widget builder(BuildContext context) {
      return _DirectionIndicator(
        width: isVertical ? size : 2,
        height: isVertical ? 2 : size,
        isVertical: isVertical,
      );
    }

    // 确保层已创建
    if (_directionIndicatorEntry == null) {
      _directionIndicatorEntry = ZoOverlayEntry(
        builder: builder,
        rect: rect,
        direction: direction,
        tapAwayClosable: false,
        escapeClosable: false,
        requestFocus: false,
        preventOverflow: false,
        duration: Duration.zero,
      );

      zoOverlay.open(_directionIndicatorEntry!);
    }

    _directionIndicatorEntry!.actions(() {
      _directionIndicatorEntry!.builder = builder;
      _directionIndicatorEntry!.rect = rect;
      _directionIndicatorEntry!.direction = direction;
    });
  }

  /// 最后一次传入 _escapeHandle 的拖动事件
  ZoTriggerDragEvent? _lastEscapeHandleEvent;

  /// 处理拖动过程的按键
  bool _draggingKeyHandle(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.escape) {
        if (_lastEscapeHandleEvent != null) {
          _lastEscapeHandleEvent!.cancel();
          return true;
        }
      }
    }
    // 6. 对于所有其他按键，返回 false
    return false;
  }

  /// 监听 escape 并取消当前拖动
  void _escapeHandle({
    required ZoTriggerDragEvent event,
    required BuildContext context,
  }) {
    _lastEscapeHandleEvent = event;

    if (event.first) {
      HardwareKeyboard.instance.addHandler(_draggingKeyHandle);
      return;
    }

    if (event.last) {
      HardwareKeyboard.instance.removeHandler(_draggingKeyHandle);
      _lastEscapeHandleEvent = null;
      return;
    }
  }

  /// 悬停展开计时器
  Timer? _dragExpandTimer;

  /// 处理拖动到中心悬停后的展开操作
  void _dragExpandHandle({
    required ZoTriggerDragEvent event,
    required ZoDNDPosition activePosition,
    required _ZoDNDNode dragNode,
    required BuildContext context,
  }) {
    // 拖到中间：添加计时器 任意拖动会清理计时器

    // 每次拖动都重置计时器
    if (_dragExpandTimer != null) {
      _dragExpandTimer!.cancel();
      _dragExpandTimer = null;
    }

    // 当前在中间位置时，添加计时器
    if (activePosition.center) {
      _dragExpandTimer = Timer(Durations.long4, () {
        if (activeNode == null || !context.mounted) return;

        final expandEvent = ZoDNDDropEvent(
          type: ZoDNDEventType.expand,
          dragDND: dragNode.dnd,
          activeDND: activeNode!.dnd,
          activePosition: activePosition,
        );

        activeNode!.dnd.onExpand?.call(expandEvent);

        ZoDNDEventNotification(expandEvent).dispatch(context);

        _dragExpandTimer = null;
      });
    }
  }

  /// 处理 dnd 节点的拖动行为, 需要在合适的时机进行事件通知以及更新对应的widget
  ///
  /// dnd组件更新时机：
  /// - 开始拖动/结束拖动：所有
  /// - dnd active 或 inactive
  /// - activePosition变更：active dnd
  void _dragHandle({
    required String id,
    required ZoTriggerDragEvent event,
    required BuildContext context,
  }) {
    dragNode = _dndNodes[id]!;

    currentViewId = dragNode!.viewId;

    final (hitNode, groupNodes) = findHitDNDs(
      event.position,
      groupId: dragNode!.dnd.groupId,
      filter: (node) => node.id != dragNode!.id,
    );

    currentViewId = null;

    final prevActiveNode = activeNode;
    final prevActivePosition = activePosition;

    _feedbackHandle(
      event: event,
      dragNode: dragNode!,
      context: context,
    );

    _escapeHandle(
      event: event,
      context: context,
    );

    _autoDragScrollHandle(
      event: event,
      groupNodes: groupNodes,
    );

    // 中途取消
    if (!dragNode!.draggable || event.canceled) {
      event.cancel();

      const nilPosition = ZoDNDPosition();

      // 清理
      _directionIndicatorHandle(
        event: event,
        dragNode: dragNode!,
        context: context,
        activePosition: nilPosition,
      );

      // 清理
      _dragExpandHandle(
        event: event,
        dragNode: dragNode!,
        context: context,
        activePosition: nilPosition,
      );

      dragNode!.updateWidget();

      dragNode = null;
      activeNode = null;

      if (prevActiveNode != activeNode ||
          prevActivePosition != activePosition) {
        _updateNodes([prevActiveNode]);
      }

      return;
    }

    activePosition = const ZoDNDPosition();

    // 检测命中节点
    if (hitNode != null) {
      activePosition = detectHitPosition(
        node: hitNode,
        position: event.position,
      );

      activeNode = hitNode;
    } else {
      activeNode = null;
    }

    if (event.first) {
      final startEvent = ZoDNDEvent(
        type: ZoDNDEventType.start,
        dragDND: dragNode!.dnd,
        activeDND: activeNode?.dnd,
        activePosition: activePosition,
      );

      for (final node in groupNodes) {
        node.dnd.onDragStart?.call(startEvent);
        node.updateWidget();
      }

      ZoDNDEventNotification(startEvent).dispatch(context);
    } else if (event.last) {
      final dragEnd = ZoDNDEvent(
        type: ZoDNDEventType.end,
        dragDND: dragNode!.dnd,
        activeDND: activeNode?.dnd,
        activePosition: activePosition,
      );

      for (final node in groupNodes) {
        node.dnd.onDragEnd?.call(dragEnd);
        node.updateWidget();
      }

      dragNode?.updateWidget();

      ZoDNDEventNotification(dragEnd).dispatch(context);
    } else {
      // 拖动过程处理
      final dragMove = ZoDNDEvent(
        type: ZoDNDEventType.move,
        dragDND: dragNode!.dnd,
        activeDND: activeNode?.dnd,
        activePosition: activePosition,
      );

      for (final node in groupNodes) {
        node.dnd.onDragMove?.call(dragMove);
      }

      ZoDNDEventNotification(dragMove).dispatch(context);
    }

    _directionIndicatorHandle(
      event: event,
      dragNode: dragNode!,
      context: context,
      activePosition: activePosition,
    );

    _dragExpandHandle(
      event: event,
      dragNode: dragNode!,
      context: context,
      activePosition: activePosition,
    );

    // 结束拖动是，根据需要清理和触发事件
    if (event.last) {
      if (activeNode != null && activePosition.any) {
        final acceptEvent = ZoDNDDropEvent(
          type: ZoDNDEventType.accept,
          dragDND: dragNode!.dnd,
          activeDND: activeNode!.dnd,
          activePosition: activePosition,
        );

        activeNode!.dnd.onAccept?.call(acceptEvent);

        ZoDNDAcceptNotification(acceptEvent).dispatch(context);
      }

      dragNode = null;
      activeNode = null;
      activePosition = const ZoDNDPosition();
    }

    final activeChanged =
        (prevActiveNode != activeNode || prevActivePosition != activePosition);

    // 更新 active 的 dnd，first和last时会更新全部，所以无需单独更新
    if (!event.first && !event.last && activeChanged) {
      _updateNodes([prevActiveNode, activeNode]);
    }
  }
}

/// 由 [_ZoDNDManager] 管理的 dnd 节点信息
class _ZoDNDNode {
  _ZoDNDNode({
    required this.id,
    required this.dnd,
    this.rect,
    this.visibleRect,
    this.viewId,
    this.renderBox,
    required this.draggable,
    required this.droppablePosition,
    required this.updateWidget,
    required this.getScrollParent,
  });

  /// dnd实例id
  final String id;

  /// dnd节点信息
  ZoDND dnd;

  /// 节点位置
  Rect? rect;

  /// 节点可见区域的位置, 为null时表示不可见
  Rect? visibleRect;

  /// 所属视图的id，用于父子级命中查询
  int? viewId;

  /// dnd 节点的 renderBox，用于尺寸测量和定位
  RenderBox? renderBox;

  /// 是否可拖动
  bool draggable;

  /// 当前dnd节点的可放置位置信息
  ZoDNDPosition droppablePosition;

  /// 主动更新 dnd 组件
  VoidCallback updateWidget;

  /// 获取节点的滚动父级信息
  (ScrollableState, Rect)? Function() getScrollParent;

  dispose() {
    renderBox = null;
    rect = null;
  }
}

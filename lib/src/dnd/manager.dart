import "dart:collection";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:visibility_detector/visibility_detector.dart";
import "package:zo/src/dnd/base.dart";
import "package:zo/src/dnd/dnd.dart";
import "package:zo/zo.dart";

/// 管理所有 dnd 节点并处理命中等逻辑
class ZoDNDManager {
  static final ZoDNDManager instance = ZoDNDManager._internal();

  static ZoDNDManager _internal() {
    // 减小可见性反馈间隔
    VisibilityDetectorController.instance.updateInterval = Durations.short2;
    return ZoDNDManager();
  }

  /// 视为边缘位置的尺寸比例
  final _edgeRatio = 0.24;

  /// 以id 为 key 存储的 dnd 节点信息，对于已经卸载的 dnd 应该将其移除，防止 map 过于庞大
  final HashMap<String, ZoDNDNode> _dndNodes = HashMap();

  /// 当前视图id，设置后，getGroup 等api会将结果限制到匹配的视口, 防止不同视口的dnd互相干扰
  /// 通常需要在节点开始拖动时，将拖动节点的viewId设置为当前视图id，防止错误的匹配到其他窗口
  int? currentViewId;

  /// 用于显示 feedback 的 overlay
  ZoOverlayEntry? feedbackEntry;

  /// 正在拖动的节点
  ZoDNDNode? dragNode;

  /// 当前存在激活位置的节点, 应通过_updateActiveNode更新
  ZoDNDNode? activeNode;

  /// 当前 activeNode 的激活位置
  var activePosition = const ZoDNDPosition();

  /// 移除指定DND
  void remove(String id) {
    _dndNodes.remove(id);
  }

  /// 获取指定DND
  ZoDNDNode? get(String id) {
    return _dndNodes[id];
  }

  /// 添加DND, 如果对应的 node.id 已存在则替换
  void add(ZoDNDNode node) {
    _dndNodes[node.id] = node;
  }

  /// 检测node的关键信息是否都有效，这通常意味着节点时可见的
  bool isValidNode(ZoDNDNode node) {
    return node.visibleRect != null &&
        node.viewId != null &&
        node.renderBox != null;
  }

  /// 获取指定组的所有有效DND, 若已设置 [currentViewId] 会将结果限制到该 viewId 下
  List<ZoDNDNode> getGroup(Object? groupId) {
    final List<ZoDNDNode> list = [];

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
  (ZoDNDNode?, List<ZoDNDNode>) findHitDNDs(
    Offset position, {
    Object? groupId,
    bool Function(ZoDNDNode node)? filter,
  }) {
    assert(currentViewId != null);

    final list = getGroup(groupId);

    final HashSet<ZoDNDNode> matchList = HashSet();

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

    final renderBoxMap = HashMap<RenderBox, ZoDNDNode>();

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
  ZoDNDPosition detachHitPosition({
    required ZoDNDNode node,
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
  void _updateNodes(List<ZoDNDNode?> nodes) {
    for (final node in nodes) {
      node?.updateWidget();
    }
  }

  ZoOverlayEntry? _feedbackEntry;

  Offset? _feedbackOffset;

  /// 处理feedback的创建显示等
  void _feedbackHandle({
    required ZoTriggerDragEvent event,
    required ZoDNDNode dragNode,
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
          return isCustomFeedback
              ? child
              : SizedBox.fromSize(
                  size: size,
                  child: Opacity(
                    opacity: dragNode.dnd.feedbackOpacity,
                    child: textStyle.wrap(
                      context,
                      child,
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

  /// 处理 dnd 节点的拖动行为, 需要在合适的时机进行事件通知以及更新对应的widget
  ///
  /// dnd组件更新时机：
  /// - 开始拖动/结束拖动：所有
  /// - dnd active 或 inactive
  /// - activePosition变更：active dnd
  @internal
  void dragHandle({
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

    if (!dragNode!.draggable) {
      event.cancel();

      dragNode = null;
      activeNode = null;

      if (prevActiveNode != activeNode ||
          prevActivePosition != activePosition) {
        _updateNodes([prevActiveNode, activeNode]);
      }

      return;
    }

    activePosition = const ZoDNDPosition();

    if (hitNode != null) {
      activePosition = detachHitPosition(
        node: hitNode,
        position: event.position,
      );

      activeNode = hitNode;
    } else {
      activeNode = null;
    }

    if (event.first) {
      final startEvent = ZoDNDEvent(
        type: ZoDNDEventType.dragStart,
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
        type: ZoDNDEventType.dragEnd,
        dragDND: dragNode!.dnd,
        activeDND: activeNode?.dnd,
        activePosition: activePosition,
      );

      for (final node in groupNodes) {
        node.dnd.onDragEnd?.call(dragEnd);
        node.updateWidget();
      }

      ZoDNDEventNotification(dragEnd).dispatch(context);
    } else {
      final dragMove = ZoDNDEvent(
        type: ZoDNDEventType.dragMove,
        dragDND: dragNode!.dnd,
        activeDND: activeNode?.dnd,
        activePosition: activePosition,
      );

      for (final node in groupNodes) {
        node.dnd.onDragMove?.call(dragMove);
      }

      ZoDNDEventNotification(dragMove).dispatch(context);
    }

    if (event.last && activeNode != null) {
      final acceptEvent = ZoDNDDropEvent(
        type: ZoDNDEventType.accept,
        dragDND: dragNode!.dnd,
        activeDND: activeNode?.dnd,
        activePosition: activePosition,
      );

      activeNode!.dnd.onAccept?.call(acceptEvent);

      ZoDNDAcceptNotification(acceptEvent).dispatch(context);
    }

    if (event.last) {
      dragNode = null;
    }

    final activeChanged =
        (prevActiveNode != activeNode || prevActivePosition != activePosition);

    // 更新 active 的 dnd，first和last时会更新全部，所以无需单独更新
    if (!event.first && !event.last && activeChanged) {
      _updateNodes([prevActiveNode, activeNode]);
    }
  }
}

/// 由 [ZoDNDManager] 管理的 dnd 节点信息
class ZoDNDNode {
  ZoDNDNode({
    required this.id,
    required this.dnd,
    this.rect,
    this.visibleRect,
    this.viewId,
    this.renderBox,
    required this.draggable,
    required this.droppablePosition,
    required this.updateWidget,
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

  dispose() {
    renderBox = null;
    rect = null;
  }
}

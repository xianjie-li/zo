import "package:flutter/material.dart";
import "package:visibility_detector/visibility_detector.dart";
import "package:zo/src/dnd/manager.dart";
import "package:zo/zo.dart";

import "base.dart";

/// 实现拖动放置行为，与常见的dnd库不同的是，一个dnd节点即可以是拖动节点，也可以是放置节点，
/// 并且支持区分放置位置，比如放置目标的上方、下方、中间等，这在一些需要拖动排序的场景下会很有用
///
/// 自定义拖动位置：通过 [ZoDND.customHandler] 和 [ZoDNDHandler] 可以自定义拖动位置。
///
/// 放置反馈：通过 [ZoDND.builder] 根据状态渲染放置的位置反馈等，也可以使用 [ZoDNDFeedback] 便捷实现反馈
///
/// 拖动事件：每个 dnd 组件均支持 拖动和放置事件，也可以通过 [ZoDNDEventNotification] 和 [ZoDNDAcceptNotification]
/// 在组件树上层统一接收事件通知
class ZoDND extends StatefulWidget {
  const ZoDND({
    super.key,
    this.child,
    this.builder,
    this.groupId,
    this.data,
    this.draggable = false,
    this.draggableDetector,
    this.droppablePosition,
    this.droppablePositionDetector,
    this.customHandler = false,
    this.feedback,
    this.feedbackOpacity = 0.4,
    this.feedbackOffset,
    this.cursor,
    this.onDragStart,
    this.onDragMove,
    this.onDragEnd,
    this.onAccept,
  }) : assert(child != null || builder != null);

  /// 要显示的子级，如果需要根据拖动状态动态构造内容，请使用 [builder]
  final Widget? child;

  final Widget Function(BuildContext context, ZoDNDBuildContext dndContext)?
  builder;

  /// 分组id，只有相同组的dnd才能互相拖放，未设置分组的dnd会被放置到一个默认组
  final Object? groupId;

  /// 用于在拖放间共享的数据
  final Object? data;

  /// 是否可拖动
  final bool draggable;

  /// 动态检测是否可拖动, 会传入当前节点，此项会覆盖 [draggable] 配置
  final bool Function(ZoDND? currentDND)? draggableDetector;

  /// 可位置配置
  final ZoDNDPosition? droppablePosition;

  /// 动态检测是否可放置位置, 会传入当前正在拖动的dnd和当前dnd，此项会覆盖 [droppablePosition] 配置
  final ZoDNDPosition Function(ZoDND currentDND, ZoDND? dragDND)?
  droppablePositionDetector;

  /// 自定义可拖动位置，默认为整个dnd节点，可以设置为true禁用默认行为，然后在内部放置 DNDHandler 组件绑定可拖动位置
  final bool customHandler;

  /// 自定义反馈节点，默认会以当前子级作为反馈节点
  final Widget? feedback;

  /// 默认反馈节点的透明度
  final double feedbackOpacity;

  /// 默认 [feedback] 会使用开始拖动时指针相对位置作为偏移，可使用此项覆盖偏移位置
  final Offset? feedbackOffset;

  /// 鼠标在组件上方时显示的光标类型
  final MouseCursor? cursor;

  /// 任意节点开始拖动触发
  final void Function(ZoDNDEvent event)? onDragStart;

  /// 任意节点节点拖动中触发
  final void Function(ZoDNDEvent event)? onDragMove;

  /// 任意节点拖动结束时触发
  final void Function(ZoDNDEvent event)? onDragEnd;

  /// 某个节点在当前节点区域成功放置时触发
  final void Function(ZoDNDEvent event)? onAccept;

  @override
  State<ZoDND> createState() => _ZoDNDState();
}

class _ZoDNDState extends State<ZoDND> {
  /// 标识 dnd 节点的唯一id
  final id = createTempId();

  late ZoDNDNode node;

  /// 根据参数获取可拖动状态
  bool getDraggable() {
    if (widget.draggableDetector != null) {
      return widget.draggableDetector!(widget);
    }

    return widget.draggable;
  }

  /// 根据参数获取可放置状态
  ZoDNDPosition getDroppablePosition() {
    if (widget.droppablePositionDetector != null) {
      return widget.droppablePositionDetector!(
        widget,
        ZoDNDManager.instance.dragNode?.dnd,
      );
    }

    return widget.droppablePosition ?? const ZoDNDPosition();
  }

  @override
  void initState() {
    super.initState();

    node = ZoDNDNode(
      id: id,
      dnd: widget,
      draggable: getDraggable(),
      droppablePosition: getDroppablePosition(),
      updateWidget: () {
        setState(() {});
      },
    );

    ZoDNDManager.instance.add(node);
  }

  @override
  void didUpdateWidget(covariant ZoDND oldWidget) {
    super.didUpdateWidget(oldWidget);

    node.draggable = getDraggable();
    node.droppablePosition = getDroppablePosition();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    node.viewId = View.of(context).viewId;
  }

  @override
  void dispose() {
    super.dispose();
    ZoDNDManager.instance.remove(node.id);
    node.dispose();
    updateRectThrottler.cancel();
    visibilityInfo = null;
  }

  /// 最后一次上报的可见信息
  VisibilityInfo? visibilityInfo;

  Throttler updateRectThrottler = Throttler(delay: Durations.short1);

  void onPaint(RenderBox box) {
    node.renderBox = box;

    // 更新位置信息，理想状态下在 onVisibilityChanged 中更新是更合适的，
    // 但实际场景中会存在快速滚动导致记录位置和最终上报位置不一致
    updateRectThrottler.run(updateRect);
  }

  void onVisibilityChanged(VisibilityInfo visibilityInfo) {
    this.visibilityInfo = visibilityInfo;

    updateRectThrottler.run(updateRect);
  }

  /// 根据 [visibilityInfo] 更新位置信息
  void updateRect() {
    if (node.renderBox != null) {
      node.rect =
          node.renderBox!.localToGlobal(Offset.zero) & node.renderBox!.size;
    }

    if (visibilityInfo == null) {
      node.visibleRect = null;
      return;
    }

    // TODO: 节点在滚动容器中部分可见，并且滚动出视口时，会存在尺寸为负数的情况，这里手动处理一下避免断言错误
    final hasValidSize =
        visibilityInfo!.visibleBounds.height >= 0 &&
        visibilityInfo!.visibleBounds.width >= 0;

    if (!hasValidSize ||
        visibilityInfo!.visibleFraction == 0 ||
        node.renderBox == null) {
      node.visibleRect = null;
      return;
    }

    final visibleRect = visibilityInfo!.visibleBounds;

    final globalRect =
        node.renderBox!.localToGlobal(visibleRect.topLeft) & visibleRect.size;

    node.visibleRect = globalRect;
  }

  void onDrag(ZoTriggerDragEvent event) {
    ZoDNDManager.instance.dragHandle(id: id, event: event, context: context);
  }

  Widget buildChild(BuildContext context) {
    if (widget.child != null) return widget.child!;

    final manager = ZoDNDManager.instance;
    final dragDND = manager.dragNode?.dnd;

    final selfActive = manager.activeNode == node;

    final dndContext = ZoDNDBuildContext(
      dragging: manager.dragNode == node,
      dragDND: dragDND,
      draggable: node.draggable,
      droppablePosition: node.droppablePosition,
      // 如果当前节点时 active 节点，需要写入命中位置信息
      activePosition: selfActive
          ? manager.activePosition
          : const ZoDNDPosition(),
    );

    return widget.builder!(context, dndContext);
  }

  @override
  Widget build(BuildContext context) {
    return RenderTrigger(
      onPaintImmediately: onPaint,
      child: VisibilityDetector(
        key: Key(id),
        onVisibilityChanged: onVisibilityChanged,
        child: ZoTrigger(
          defaultCursor: widget.cursor,
          enabled: node.draggable,
          onDrag: onDrag,
          child: buildChild(context),
        ),
      ),
    );
  }
}

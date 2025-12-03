import "dart:async";
import "dart:collection";

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:visibility_detector/visibility_detector.dart";
import "package:zo/zo.dart";

part "base.dart";
part "auto_scroll.dart";
part "manager.dart";

/// 实现拖动与放置，与常见的dnd库不同的是，一个dnd节点即可以是拖动节点，也可以是放置节点，
/// 并且支持区分放置位置，比如放置目标的上方、下方、中间等，这在一些需要拖动排序的场景下会很有用
///
/// 自定义拖动位置：通过设置 [ZoDND.customHandler] 为 true 并在子级放置 [ZoDNDHandler] 组件自定义拖动位置。
///
/// 放置反馈：
/// - 内置：可通过 [ZoDND.dropIndicator] 显示不同方向的可放置反馈，
/// [ZoDND.disabledOpacity] 可以控制被拖动时显示半透明禁用效果
/// - 自定义：通过 [ZoDND.builder] 根据状态渲染拖动或可放置反馈反馈
///
/// 拖动事件：每个 dnd 组件均支持 拖动和放置事件，也可以通过 [ZoDNDEventNotification] 和 [ZoDNDAcceptNotification]
/// 在组件树上层统一接收事件通知
///
/// 分组：使用 [groupId] 将dnd简单分组，不同组之间的dnd互不干扰。
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
    this.feedbackWrap,
    this.dropIndicator = true,
    this.dropIndicatorPadding,
    this.dropIndicatorRadius = 6,
    this.disabledOpacity,
    this.longPressDragOnTouch = true,
    this.onDragStart,
    this.onDragMove,
    this.onDragEnd,
    this.onAccept,
    this.onExpand,
  }) : assert(child != null || builder != null);

  /// 子级，如果需要根据拖动状态动态构造内容，请使用 [builder]
  final Widget? child;

  /// 构造子级，可以通过 dndContext 来动态构造子级，比如显示拖动中、可放置等反馈样式
  final Widget Function(BuildContext context, ZoDNDBuildContext dndContext)?
  builder;

  /// 分组id，只有相同组的dnd才能互相拖放，未设置分组的dnd会被放置到一个默认组
  final Object? groupId;

  /// 用于在拖放间共享的数据
  final Object? data;

  /// 是否可拖动
  final bool draggable;

  /// 动态检测是否可拖动, 会传入当前组件，此项会覆盖 [draggable] 配置
  final bool Function(ZoDND dnd)? draggableDetector;

  /// 可位置配置
  final ZoDNDPosition? droppablePosition;

  /// 动态检测是否可放置位置, 会传入当前正在拖动的dnd和当前dnd，此项会覆盖 [droppablePosition] 配置
  final ZoDNDPosition Function(ZoDND currentDND, ZoDND? dragDND)?
  droppablePositionDetector;

  /// 自定义可拖动位置，默认为整个dnd节点，可以设置为true禁用默认行为，然后在内部放置 [ZoDNDHandler] 组件绑定可拖动位置
  final bool customHandler;

  /// 自定义反馈节点，默认会以当前子级作为反馈节点
  final Widget? feedback;

  /// 默认反馈节点的透明度
  final double feedbackOpacity;

  /// 默认 [feedback] 会使用开始拖动时指针相对位置作为偏移，可使用此项覆盖偏移位置
  final Offset? feedbackOffset;

  /// 为 feedback 节点自定义包装组件，默认会将 [child] / [builder] 的构造内容单独渲染一份在 overlay 下，
  /// 可能存在上下文状态丢失(比如主题、文本样式等)，可以通过此方法手动添加
  final WidgetChildBuilder? feedbackWrap;

  /// 当一个节点被拖动到可放置组件上位置时，显示放置指示器
  final bool dropIndicator;

  /// 在 [dropIndicator] 不同方向的填充距离，距离可以为负数，例如，在树节点拖动时可能想要根据缩进调整左间距;
  /// 在列表项间存在间距时，需要调整上下间距来使两个项之间的指示器位置一直
  final EdgeInsets? dropIndicatorPadding;

  /// 控制 [dropIndicator] 防止到中间时，矩形框的圆角
  final double dropIndicatorRadius;

  /// 节点不可用时添加的透明度，在拖动节点、不可放置节点添加
  final double? disabledOpacity;

  /// 在触控类操作中使用 longPress 触发拖动事件, 防止干扰后方的滚动组件
  final bool longPressDragOnTouch;

  /// 任意节点开始拖动触发
  final void Function(ZoDNDEvent event)? onDragStart;

  /// 任意节点节点拖动中触发
  final void Function(ZoDNDEvent event)? onDragMove;

  /// 任意节点拖动结束时触发
  final void Function(ZoDNDEvent event)? onDragEnd;

  /// 某个节点在当前节点区域成功放置时触发
  final void Function(ZoDNDEvent event)? onAccept;

  /// 当前节点启用 [ZoDNDPosition.center] 位置的放置时，如果将一个节点拖动带当前节点对应位置一段时间后，
  /// 会触发C此事件，用来对树形结构等进行展开
  final void Function(ZoDNDEvent event)? onExpand;

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
      updateWidget: ([immediate = false]) {
        if (!mounted) return;

        if (immediate) {
          setState(() {});
        } else {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {});
          });
        }
      },
      updateRect: ([immediate = false]) {
        if (immediate) {
          updateRect();
        } else {
          updateRectThrottler.run(updateRect);
        }
      },
      getScrollParent: getScrollParent,
    );

    ZoDNDManager.instance._add(node);
  }

  @override
  void didUpdateWidget(covariant ZoDND oldWidget) {
    super.didUpdateWidget(oldWidget);

    node.dnd = widget;
    node.draggable = getDraggable();
    updateDroppablePosition();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    node.viewId = View.of(context).viewId;
    updateDroppablePosition();
  }

  @override
  void dispose() {
    super.dispose();
    node.dispose();

    updateRectThrottler.cancel();
    ZoDNDManager.instance._remove(node.id);
    visibilityInfo = null;
  }

  /// 最后一次上报的可见信息
  VisibilityInfo? visibilityInfo;

  /// 限制 updateRect 触发频率
  Throttler updateRectThrottler = Throttler(delay: Durations.short1);

  bool lastVisible = false;

  void onPaint(RenderBox box) {
    node.renderBox = box;
  }

  void onVisibilityChanged(VisibilityInfo visibilityInfo) {
    this.visibilityInfo = visibilityInfo;

    final isVisible = visibilityInfo.visibleFraction > 0;

    // 由不可见转为可见时，更新组件
    // 针对的场景：开始拖动时，如果组件在sliver的缓冲区，也就是挂载状态，此时开始拖动并自动滚动到该组件显示时，
    // 组件因为还是使用的旧的build状态，UI会呈过时状态，需要在显示时手动更新一下组件
    if (isVisible && !lastVisible) {
      node.updateWidget();
    }

    lastVisible = isVisible;
  }

  /// 更新可放置位置
  void updateDroppablePosition() {
    node.droppablePosition = getDroppablePosition();
  }

  /// 根据当前状态更新位置信息
  void updateRect() {
    if (node.renderBox != null) {
      if (node.renderBox!.attached) {
        node.rect =
            node.renderBox!.localToGlobal(Offset.zero) & node.renderBox!.size;
      } else {
        node.rect = null;
        node.visibleRect = null;
        node.renderBox = null;
        return;
      }
    }

    if (visibilityInfo == null) {
      node.visibleRect = null;
      return;
    }

    // 节点在滚动容器中部分可见，并且滚动出视口时，会存在尺寸为负数的情况，这里手动处理一下避免断言错误
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

    // 实际可见的rect
    final globalRect =
        node.renderBox!.localToGlobal(visibleRect.topLeft) & visibleRect.size;

    node.visibleRect = globalRect;
  }

  /// 获取滚动父级的信息
  (ScrollableState, Rect)? getScrollParent() {
    final scrollState = Scrollable.maybeOf(context);

    if (scrollState == null || !mounted) return null;

    final obj = scrollState.context.findRenderObject() as RenderBox?;

    if (obj == null || !obj.attached) return null;

    final Rect globalRect = obj.localToGlobal(Offset.zero) & obj.size;

    return (scrollState, globalRect);
  }

  void onDrag(ZoTriggerDragEvent event) {
    ZoDNDManager.instance._dragHandle(id: id, event: event, context: context);
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

  Widget buildTrigger(BuildContext context) {
    if (widget.customHandler) {
      return buildChild(context);
    }

    return ZoTrigger(
      enabled: node.draggable,
      onDrag: onDrag,
      longPressDragOnTouch: widget.longPressDragOnTouch,
      child: buildChild(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    updateDroppablePosition();

    final dragNode = ZoDNDManager.instance.dragNode;

    // 拖动中为拖动中和不可放置节点添加透明度
    final showOpacity =
        dragNode != null &&
        (ZoDNDManager.instance.dragNode == node || !node.droppablePosition.any);

    return RenderTrigger(
      onPaintImmediately: onPaint,
      child: _DNDNodeProvider(
        node: node,
        child: Opacity(
          opacity: showOpacity
              ? (widget.disabledOpacity ?? context.zoStyle.disableOpacity)
              : 1,
          child: VisibilityDetector(
            key: Key(id),
            onVisibilityChanged: onVisibilityChanged,
            child: buildTrigger(context),
          ),
        ),
      ),
    );
  }
}

/// 自定义拖动位置，将 [ZoDND.customHandler] 设置为true，并在其子级放置此节点实现自定义拖动位置
class ZoDNDHandler extends StatelessWidget {
  const ZoDNDHandler({
    super.key,
    required this.child,
  });

  /// 渲染子级
  final Widget child;

  void onDrag(ZoTriggerDragEvent event) {
    final (ZoDNDNode node, BuildContext context) = event.data;

    ZoDNDManager.instance._dragHandle(
      id: node.id,
      event: event,
      context: context,
    );
  }

  @override
  Widget build(BuildContext context) {
    final nodeProvider = _DNDNodeProvider.maybeOf(context);

    // 节点被复制为 feedback 时，会丢失上下文，直接原样渲染组件
    if (nodeProvider == null) return child;

    final node = nodeProvider.node;

    return ZoTrigger(
      data: (node, context),
      enabled: node.draggable,
      onDrag: onDrag,
      child: child,
    );
  }
}

/// 由dnd内部向下分发 node 信息, 并在 DNDHandler 等组件中获取使用
class _DNDNodeProvider extends InheritedWidget {
  const _DNDNodeProvider({
    super.key,
    required this.node,
    required super.child,
  });

  final ZoDNDNode node;

  static _DNDNodeProvider? maybeOf(BuildContext context) {
    final _DNDNodeProvider? result = context
        .dependOnInheritedWidgetOfExactType<_DNDNodeProvider>();
    return result;
  }

  @override
  bool updateShouldNotify(_DNDNodeProvider oldWidget) {
    return oldWidget.node != node;
  }
}

/// 位置指示器
class _DirectionIndicator extends StatelessWidget {
  const _DirectionIndicator({
    super.key,
    required this.width,
    required this.height,
    required this.thickness,
    required this.activePosition,
    required this.indicatorRadius,
  });

  /// 控制线条宽度
  final double width;

  /// 控制线条高度
  final double height;

  /// 指示线或边框厚度
  final double thickness;

  /// 当前活动方向
  final ZoDNDPosition activePosition;

  /// 放置到中间时，矩形框的圆角
  final double indicatorRadius;

  static double circularSize = 8;

  @override
  Widget build(BuildContext context) {
    final style = context.zoStyle;

    final circularMainOffset = -(circularSize - thickness);

    final circularCrossOffset = circularMainOffset / 2;

    final isVertical = activePosition.top || activePosition.bottom;

    final isCenter = activePosition.center;

    final contourColor = style.surfaceContainerColor;

    // 为指示线添加轮廓，防止模板颜色与指示线一直时的低可见性
    final contour = [
      BoxShadow(
        color: contourColor,
        spreadRadius: 1,
      ),
    ];

    final mainIndicator = isCenter
        ? Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              border: Border.all(
                color: style.primaryColor,
                width: thickness,
              ),
              borderRadius: BorderRadius.circular(indicatorRadius),
            ),
            // 额外添加一层内边框作为轮廓线，防止指示器与目标背景颜色相同
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: contourColor,
                ),
                borderRadius: BorderRadius.circular(indicatorRadius),
              ),
            ),
          )
        : Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: style.primaryColor,
              borderRadius: BorderRadius.circular(4),
              boxShadow: contour,
            ),
          );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        mainIndicator,
        if (!isCenter)
          Positioned(
            left: isVertical ? circularMainOffset : circularCrossOffset,
            top: isVertical ? circularCrossOffset : circularMainOffset,
            width: circularSize,
            height: circularSize,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: style.primaryColor,
                  width: thickness,
                ),
                boxShadow: contour,
              ),
            ),
          ),
      ],
    );
  }
}

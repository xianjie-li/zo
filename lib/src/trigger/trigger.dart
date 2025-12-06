import "dart:async";
import "dart:ui";

import "package:flutter/foundation.dart";
import "package:flutter/gestures.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

typedef ZoTriggerListener<T> = void Function(T event);

/// 支持的事件类型
enum ZoTriggerType {
  tap,
  tapDown,
  active,
  focus,
  contextAction,
  drag,
  move,
}

/// 通用事件, 包含事件类型, 触发位置等信息
class ZoTriggerEvent extends Notification {
  ZoTriggerEvent({
    required this.type,
    required this.time,
    required this.trigger,
    this.position = Offset.zero,
    this.offset = Offset.zero,
    this.data,
    this.deviceKind,
    this.keyEventDeviceType,
  });

  /// 触发的事件类型
  final ZoTriggerType type;

  /// 触发的时间
  final DateTime time;

  /// 对应的 trigger 配置
  final ZoTrigger trigger;

  /// 全局位置
  final Offset position;

  /// 距离目标左上角的位置
  final Offset offset;

  /// 绑定到组件的额外信息
  final dynamic data;

  /// 触发事件的设备类型, 仅部分事件包含
  final PointerDeviceKind? deviceKind;

  /// 触发事件的按键设备类型, 仅部分事件包含
  final KeyEventDeviceType? keyEventDeviceType;

  @override
  String toString() {
    return "ZoTriggerEvent(type: $type, time: $time, trigger: $trigger, position: $position, offset: $offset)";
  }
}

/// 具有开关状态的 [ZoTriggerEvent]
class ZoTriggerToggleEvent extends ZoTriggerEvent {
  ZoTriggerToggleEvent({
    required super.type,
    required super.time,
    required super.trigger,
    this.toggle = false,
    super.position,
    super.offset,
    super.data,
    super.deviceKind,
  });

  /// 当前开关状态
  final bool toggle;

  @override
  String toString() {
    return "ZoTriggerToggleEvent(type: $type, toggle: $toggle, time: $time, trigger: $trigger, position: $position, offset: $offset)";
  }
}

/// 鼠标 move 事件
class ZoTriggerMoveEvent extends ZoTriggerEvent {
  ZoTriggerMoveEvent({
    required super.type,
    required super.time,
    required super.trigger,
    this.first = false,
    this.last = false,
    super.position,
    super.offset,
    super.data,
    super.deviceKind,
  });

  /// 是否是拖动开始
  final bool first;

  /// 是否是拖动结束
  final bool last;

  @override
  String toString() {
    return "ZoTriggerMoveEvent(type: $type, first: $first, last: $last, time: $time, trigger: $trigger, position: $position, offset: $offset)";
  }
}

/// drag 事件
class ZoTriggerDragEvent extends ZoTriggerEvent {
  ZoTriggerDragEvent({
    required super.type,
    required super.time,
    required super.trigger,
    required this.cancel,
    this.first = false,
    this.last = false,
    this.delta = Offset.zero,
    this.canceled = false,
    this.velocity = Velocity.zero,
    super.position,
    super.offset,
    super.data,
    super.deviceKind,
  });

  /// 是否是拖动开始
  final bool first;

  /// 是否是拖动结束
  final bool last;

  /// 相对上一次拖动位置的位移
  final Offset delta;

  /// 拖动结束时的速度
  final Velocity velocity;

  /// 取消事件
  final VoidCallback cancel;

  /// 如果事件被取消, 此项为 true, 通常与 last 同时设置
  final bool canceled;

  @override
  String toString() {
    return "ZoTriggerDragEvent(type: $type, first: $first, last: $last, delta: $delta, time: $time, trigger: $trigger, position: $position, offset: $offset)";
  }
}

/// [ZoTrigger] 内部的 focusNode 变更时触发，当渲染大量 trigger 时，可通过此事件获取 focusNode，
/// 避免大量的重复创建
///
/// 会在创建、更新、销毁时触发
class ZoTriggerFocusNodeChangedNotification extends Notification {
  /// 焦点节点
  final FocusNode focusNode;

  /// 是否激活
  ///
  /// 为什么不使用直接将 FocusNode 设置为 null，而是提供 active?
  /// - 在某些场景下，比如 Sliver 滚动中，同一个位置的组件可能很快速的卸载并挂载，组件会创建两个不同的 focusNode, 这可以避免由于挂载和卸载顺序的不对称导致的错误通知，即：可能存在新组件挂载后，前一个组件才卸载完成
  final bool active;

  /// 传递给 [ZoTrigger] 的 event.data
  final dynamic data;

  /// 构造函数
  ZoTriggerFocusNodeChangedNotification({
    required this.focusNode,
    this.data,
    required this.active,
  });
}

/// 一个通用的事件触发器, 它集成了几种最常用的事件类型, 可用于基础组件实现 popper / button 等组件的事件绑定
class ZoTrigger extends StatefulWidget {
  const ZoTrigger({
    super.key,
    required this.child,
    this.onTap,
    this.onTapDown,
    this.onTapCancel,
    this.onActiveChanged,
    this.onFocusChanged,
    this.onContextAction,
    this.onDrag,
    this.onMove,
    this.onKeyEvent,
    this.data,
    this.enabled = true,
    this.dragAxis,
    this.focusNode,
    this.autofocus = false,
    this.canRequestFocus = true,
    this.focusOnTap = true,
    this.defaultCursor,
    this.changeCursor = false,
    this.longPressDragOnTouch = true,
    this.notification = false,
    this.behavior,
  });

  /// 子项
  final Widget child;

  /// 是否启用
  final bool enabled;

  /// 点击
  final ZoTriggerListener<ZoTriggerEvent>? onTap;

  /// 按下
  final ZoTriggerListener<ZoTriggerEvent>? onTapDown;

  /// 取消点击
  final ZoTriggerListener<ZoTriggerEvent>? onTapCancel;

  /// 是否活动状态
  /// - 鼠标: 表示位于组件上方
  /// - 触摸设备: 按下触发, 松开或移动时关闭
  final ZoTriggerListener<ZoTriggerToggleEvent>? onActiveChanged;

  /// 焦点变更, 传入此项后会自动启用 focus 功能
  final ZoTriggerListener<ZoTriggerToggleEvent>? onFocusChanged;

  /// 触发上下文操作
  /// - 鼠标: 右键点击
  /// - 触摸设备: 长按
  final ZoTriggerListener<ZoTriggerEvent>? onContextAction;

  /// 拖拽目标
  final ZoTriggerListener<ZoTriggerDragEvent>? onDrag;

  /// 在目标上方移动
  /// - 鼠标: 悬浮移动
  /// - 触摸设备: 按下并移动
  final ZoTriggerListener<ZoTriggerMoveEvent>? onMove;

  /// 聚焦状态按下按键时触发
  final KeyEventResult Function(KeyEvent)? onKeyEvent;

  /// 传递到事件对象的额外信息, 可在事件回调中通过 event.data 访问
  final dynamic data;

  /// 设置后, 将只能派发指定方向的拖动
  final Axis? dragAxis;

  /// 焦点控制
  final FocusNode? focusNode;

  /// 自动聚焦
  final bool autofocus;

  /// 是否可获得焦点, 当子级是 button 等可聚焦节点时, 可设置为 false, 使其只能监听子级的聚焦状态
  ///
  /// 传入 [onFocusChanged] 此项才会生效
  final bool canRequestFocus;

  /// 是否可通过点击获得焦点, 需要同事启用点击相关的事件才能生效
  final bool focusOnTap;

  /// 默认显示的光标
  final MouseCursor? defaultCursor;

  /// 是否显示适合当前事件的光标类型
  final bool changeCursor;

  /// 在触控类操作中使用 longPress 触发拖动事件, 防止干扰后方的滚动组件
  final bool longPressDragOnTouch;

  /// 是否将事件向上冒泡通知, 不影响 [ZoTriggerFocusNodeChangedNotification]
  final bool notification;

  /// 命中测试行为
  final HitTestBehavior? behavior;

  /// 应该被视为 touch 处理的事件
  static Set<PointerDeviceKind> touchLike = {
    PointerDeviceKind.touch,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
  };

  /// 是否应视为触控设备
  static bool isTouchLike(PointerDeviceKind? kind) {
    return kind != null && touchLike.contains(kind);
  }

  @override
  State<ZoTrigger> createState() => _ZoTriggerState();
}

class _ZoTriggerState extends State<ZoTrigger> {
  /// 临时禁用浏览器默认上下文菜单
  Timer? tempDisableContextActionTimer;

  /// 最后一次触发的拖动事件
  ZoTriggerDragEvent? lastDragEvent;

  /// 最后一次触发的移动事件
  ZoTriggerMoveEvent? lastMoveEvent;

  /// 最后一次触发的 active 启用事件
  ZoTriggerToggleEvent? lastActiveEvent;

  /// 区分 active 的触发类型, 决定何时应该关闭
  bool isTapActive = false;

  /// 控制显示的光标
  SystemMouseCursor? currentCursor;

  /// 是否存在未结束的 tap 事件
  bool tapPending = false;

  /// 焦点控制
  late FocusNode focusNode;

  @override
  void initState() {
    super.initState();

    focusNode = widget.focusNode ?? FocusNode();

    ZoTriggerFocusNodeChangedNotification(
      focusNode: focusNode,
      data: widget.data,
      active: true,
    ).dispatch(context);
  }

  @override
  void didUpdateWidget(covariant ZoTrigger oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.enabled != widget.enabled && !widget.enabled) {
      WidgetsBinding.instance.addPostFrameCallback((t) {
        clearPendingEvent();
      });
    }

    if (oldWidget.focusNode != widget.focusNode) {
      if (oldWidget.focusNode == null) {
        // 前一个节点时组件内部创建的
        focusNode.dispose();
      }
      focusNode = widget.focusNode ?? FocusNode();

      ZoTriggerFocusNodeChangedNotification(
        focusNode: focusNode,
        data: widget.data,
        active: true,
      ).dispatch(context);
    }
  }

  @override
  void dispose() {
    ZoTriggerFocusNodeChangedNotification(
      focusNode: focusNode,
      data: widget.data,
      active: false,
    ).dispatch(context);

    if (widget.focusNode != focusNode) {
      focusNode.dispose();
    }

    clearPendingEvent();

    super.dispose();
  }

  /// 在 enable 从 true 切换到 false 时, 需要强制结束未完成的事件
  void clearPendingEvent() {
    if (tapPending) {
      onTapCancel();
    }

    if (lastMoveEvent != null || lastActiveEvent != null) {
      onMouseExit(null);
    }

    if (lastDragEvent != null) {
      onPanCancel();
    }

    // focus 无需处理, 因为禁用事件后 Focus 组件会自动触发
  }

  TapDownDetails? lastTapDownDetails;

  void onTapUp(TapUpDetails details) {
    lastTapDownDetails = null;

    tapPending = false;

    clearTouchContextMenuTimer();

    // 在外部事件触发之前获取焦点，避免在外部handle中需要控制焦点时发生冲突
    if (widget.canRequestFocus && widget.focusOnTap) {
      focusNode.requestFocus();
    }

    if (widget.onTap != null) {
      final tapEvent = getTapEvent(details, kind: details.kind);
      widget.onTap?.call(tapEvent);
      if (widget.notification) tapEvent.dispatch(context);
    }

    setDragCursor(false);

    /// 关闭 active 事件
    if (lastActiveEvent != null && isTapActive) {
      final inactiveEvent = getInactiveEvent();
      widget.onActiveChanged!(inactiveEvent);
      if (widget.notification) inactiveEvent.dispatch(context);
    }
  }

  void onTapDown(TapDownDetails details) {
    lastTapDownDetails = details;

    tapPending = true;

    startTouchContextMenuTimer(details);

    if (widget.onTapDown != null) {
      final downEvent = getTapEvent(details, kind: details.kind);
      widget.onTapDown?.call(downEvent);
      if (widget.notification) downEvent.dispatch(context);
    }

    // 如果拖动事件启用，按下时立即更新光标
    setDragCursor(true);

    if (ZoTrigger.isTouchLike(details.kind)) {
      /// 当前没有已开始的 active 事件时触发
      if (widget.onActiveChanged != null && lastActiveEvent == null) {
        tempDisableContextAction();
        final event = ZoTriggerToggleEvent(
          type: ZoTriggerType.active,
          time: DateTime.now(),
          trigger: widget,
          position: details.globalPosition,
          offset: details.localPosition,
          toggle: true,
          data: widget.data,
          deviceKind: details.kind,
        );
        lastActiveEvent = event;
        isTapActive = true;
        widget.onActiveChanged!(event);
        if (widget.notification) event.dispatch(context);
      }
    }
  }

  void onTapCancel() {
    tapPending = false;

    clearTouchContextMenuTimer();

    if (widget.onTapCancel != null) {
      final downEvent = ZoTriggerEvent(
        type: ZoTriggerType.tap,
        time: DateTime.now(),
        trigger: widget,
        position: Offset.zero,
        offset: Offset.zero,
        data: widget.data,
        deviceKind: lastTapDownDetails?.kind,
      );
      widget.onTapCancel?.call(downEvent);
      if (widget.notification) downEvent.dispatch(context);
    }

    lastTapDownDetails = null;

    setDragCursor(false);

    /// 关闭 active 事件
    if (lastActiveEvent != null && isTapActive) {
      final event = getInactiveEvent();
      widget.onActiveChanged!(event);
      if (widget.notification) event.dispatch(context);
    }
  }

  void onSecondaryTapDown(TapDownDetails details) {
    tempDisableContextAction();

    if (widget.onContextAction != null) {
      final event = ZoTriggerEvent(
        type: ZoTriggerType.contextAction,
        time: DateTime.now(),
        trigger: widget,
        position: details.globalPosition,
        offset: details.localPosition,
        data: widget.data,
        deviceKind: details.kind,
      );
      widget.onContextAction!(event);
      if (widget.notification) event.dispatch(context);
    }
  }

  /// 为通过鼠标触发的 active 添加短暂延迟, 减少快速划过时产生的active触发
  Timer? _mouseActiveTimer;

  void onMouseEnter(PointerEnterEvent event) {
    mouseEnterMoveHandle(event.position, event.localPosition, event.kind);
  }

  void onMouseExit(PointerExitEvent? event) {
    if (widget.onMove != null) {
      var position = Offset.zero;
      var offset = Offset.zero;

      if (event != null) {
        position = event.position;
        offset = event.localPosition;
      } else if (lastMoveEvent != null) {
        position = lastMoveEvent!.position;
        offset = lastMoveEvent!.offset;
      }

      final e = ZoTriggerMoveEvent(
        type: ZoTriggerType.move,
        time: DateTime.now(),
        trigger: widget,
        position: position,
        offset: offset,
        last: true,
        data: widget.data,
        deviceKind: event?.kind ?? PointerDeviceKind.mouse,
      );

      lastMoveEvent = null;

      widget.onMove!(e);
      if (widget.notification) e.dispatch(context);
    }

    if (_mouseActiveTimer != null) {
      _mouseActiveTimer!.cancel();
      _mouseActiveTimer = null;
    }

    /// 关闭 active 事件
    if (lastActiveEvent != null && !isTapActive) {
      final inactiveEvent = getInactiveEvent();
      widget.onActiveChanged!(inactiveEvent);
      if (widget.notification) inactiveEvent.dispatch(context);
    }
  }

  void onMouseHover(PointerHoverEvent event) {
    mouseEnterMoveHandle(event.position, event.localPosition, event.kind);
  }

  /// 鼠标进入和移动时的通用逻辑
  void mouseEnterMoveHandle(
    Offset position,
    Offset offset,
    PointerDeviceKind kind,
  ) {
    if (widget.onMove != null) {
      final e = ZoTriggerMoveEvent(
        type: ZoTriggerType.move,
        time: DateTime.now(),
        trigger: widget,
        position: position,
        offset: offset,
        first: lastMoveEvent == null,
        data: widget.data,
        deviceKind: kind,
      );

      lastMoveEvent = e;

      widget.onMove!(e);
      if (widget.notification) e.dispatch(context);
    }

    /// 当前没有已开始的 active 事件时触发
    if (widget.onActiveChanged != null &&
        lastActiveEvent == null &&
        !isTapActive &&
        _mouseActiveTimer == null) {
      _mouseActiveTimer = Timer(const Duration(milliseconds: 20), () {
        final e = ZoTriggerToggleEvent(
          type: ZoTriggerType.active,
          time: DateTime.now(),
          trigger: widget,
          toggle: true,
          data: widget.data,
          deviceKind: kind,
        );
        lastActiveEvent = e;
        isTapActive = false;
        widget.onActiveChanged!(e);
        if (widget.notification) e.dispatch(context);

        _mouseActiveTimer = null;
      });
    }
  }

  KeyEventResult onKeyEvent(FocusNode node, KeyEvent event) {
    if (!widget.enabled) return KeyEventResult.ignored;

    final typeMatch = event is KeyRepeatEvent || event is KeyDownEvent;
    final hasHandle = widget.onTap != null || widget.onTapDown != null;

    if (typeMatch && hasHandle) {
      if (event.logicalKey == LogicalKeyboardKey.enter ||
          event.logicalKey == LogicalKeyboardKey.space) {
        final tapDownEvent = getTapEvent(
          event,
          type: ZoTriggerType.tapDown,
          keyEventDeviceType: event.deviceType,
        );

        final tapEvent = getTapEvent(
          event,
          keyEventDeviceType: event.deviceType,
        );

        widget.onTapDown?.call(tapDownEvent);

        widget.onTap?.call(tapEvent);
        if (widget.notification) tapEvent.dispatch(context);

        return KeyEventResult.handled;
      }
    }

    if (widget.onKeyEvent != null) {
      return widget.onKeyEvent!(event);
    }

    return KeyEventResult.ignored;
  }

  void onFocusChanged(bool value) {
    if (widget.onFocusChanged != null) {
      final e = ZoTriggerToggleEvent(
        type: ZoTriggerType.focus,
        time: DateTime.now(),
        trigger: widget,
        toggle: value,
        data: widget.data,
      );

      widget.onFocusChanged!(e);

      if (widget.notification) e.dispatch(context);
    }
  }

  LongPressDownDetails? lastLongPressDownDetails;

  Offset? lastLongPressOffset;

  bool _cancelDragRunning = false;

  void dragStart({
    required Offset globalPosition,
    required Offset localPosition,
    PointerDeviceKind? kind,
  }) {
    _cancelDragRunning = false;

    if (widget.onDrag == null || lastDragEvent != null) {
      return;
    }

    setDragCursor(true);

    final e = ZoTriggerDragEvent(
      type: ZoTriggerType.drag,
      time: DateTime.now(),
      trigger: widget,
      position: clampAxis(globalPosition),
      offset: localPosition,
      first: true,
      cancel: cancelDrag,
      data: widget.data,
      deviceKind: kind,
    );

    lastDragEvent = e;

    widget.onDrag!(e);
    if (widget.notification) e.dispatch(context);
  }

  void dragEnd({
    required Offset globalPosition,
    required Offset localPosition,
    required Velocity velocity,
  }) {
    if (lastDragEvent == null || _cancelDragRunning) return;

    setDragCursor(false);

    final e = ZoTriggerDragEvent(
      type: ZoTriggerType.drag,
      time: DateTime.now(),
      trigger: widget,
      position: clampAxis(globalPosition),
      offset: localPosition,
      last: true,
      cancel: cancelDrag,
      velocity: velocity,
      data: widget.data,
      deviceKind: lastDragEvent?.deviceKind,
    );

    lastDragEvent = null;

    widget.onDrag?.call(e);
    if (widget.notification) e.dispatch(context);
  }

  void dragMove({
    required Offset delta,
    required Offset globalPosition,
    required Offset localPosition,
  }) {
    if (lastDragEvent == null || _cancelDragRunning) return;

    final clampDelta = clampAxis(delta);

    final e = ZoTriggerDragEvent(
      type: ZoTriggerType.drag,
      time: DateTime.now(),
      trigger: widget,
      position: clampAxis(globalPosition),
      offset: clampAxis(localPosition),
      delta: clampDelta,
      cancel: cancelDrag,
      data: widget.data,
      deviceKind: lastDragEvent?.deviceKind,
    );

    lastDragEvent = e;

    widget.onDrag?.call(e);
    if (widget.notification) e.dispatch(context);
  }

  void dragCancel() {
    if (lastDragEvent == null) return;

    _cancelDragRunning = false;

    setDragCursor(false);

    final e = ZoTriggerDragEvent(
      type: ZoTriggerType.drag,
      time: DateTime.now(),
      trigger: widget,
      position: lastDragEvent!.position,
      offset: lastDragEvent!.offset,
      last: true,
      canceled: true,
      cancel: cancelDrag,
      data: widget.data,
      deviceKind: lastDragEvent?.deviceKind,
    );

    lastDragEvent = null;

    widget.onDrag?.call(e);
    if (widget.notification) e.dispatch(context);
  }

  void onPanStart(DragStartDetails details) {
    dragStart(
      globalPosition: details.globalPosition,
      localPosition: details.localPosition,
      kind: details.kind,
    );
  }

  void onPanEnd(DragEndDetails details) {
    dragEnd(
      globalPosition: details.globalPosition,
      localPosition: details.localPosition,
      velocity: details.velocity,
    );
  }

  void onPanUpdate(DragUpdateDetails details) {
    dragMove(
      delta: details.delta,
      globalPosition: details.globalPosition,
      localPosition: details.localPosition,
    );
  }

  void onPanCancel() {
    dragCancel();
  }

  void onLongPressDown(LongPressDownDetails details) {
    lastLongPressDownDetails = details;

    tempDisableContextAction();
  }

  void onLongPressStart(LongPressStartDetails details) {
    final kind = lastLongPressDownDetails?.kind;

    if (widget.onDrag != null) {
      lastLongPressOffset = details.globalPosition;

      dragStart(
        globalPosition: details.globalPosition,
        localPosition: details.localPosition,
        kind: kind,
      );
    }

    if (widget.onContextAction != null) {
      final event = ZoTriggerEvent(
        type: ZoTriggerType.contextAction,
        time: DateTime.now(),
        trigger: widget,
        position: details.globalPosition,
        offset: details.localPosition,
        data: widget.data,
        deviceKind: kind,
      );
      widget.onContextAction!(event);
      if (widget.notification) event.dispatch(context);
    }
  }

  void onLongPressEnd(LongPressEndDetails details) {
    lastLongPressDownDetails = null;
    lastLongPressOffset = null;

    dragEnd(
      globalPosition: details.globalPosition,
      localPosition: details.localPosition,
      velocity: details.velocity,
    );
  }

  void onLongPressCancel() {
    lastLongPressDownDetails = null;
    lastLongPressOffset = null;

    dragCancel();
  }

  void onLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    final delta = lastLongPressOffset == null
        ? Offset.zero
        : details.globalPosition - lastLongPressOffset!;

    lastLongPressOffset = details.globalPosition;

    dragMove(
      delta: delta,
      globalPosition: details.globalPosition,
      localPosition: details.localPosition,
    );
  }

  /// 取消正在进行的 drag 事件
  void cancelDrag() {
    if (_cancelDragRunning || lastDragEvent == null) return;

    // 因为 cancelDrag 是在事件 handle 内部调用的，需要确保取消事件在其之后
    // 在此期间阻止其他后续时间执行
    _cancelDragRunning = true;

    Timer.run(dragCancel);
  }

  /// 触发移动端长按上下文菜单的timer
  Timer? touchContextMenuTimer;

  /// 开始触控触发的上下文菜单长按计时
  void startTouchContextMenuTimer(TapDownDetails details) {
    clearTouchContextMenuTimer();

    // 仅启用且触控方式触发时使用
    if (widget.onContextAction == null ||
        !ZoTrigger.isTouchLike(details.kind)) {
      return;
    }

    touchContextMenuTimer = Timer(Durations.medium2, () {
      tempDisableContextAction();

      if (widget.onContextAction != null) {
        final event = ZoTriggerEvent(
          type: ZoTriggerType.contextAction,
          time: DateTime.now(),
          trigger: widget,
          position: details.globalPosition,
          offset: details.localPosition,
          data: widget.data,
          deviceKind: details.kind,
        );
        widget.onContextAction!(event);
        if (widget.notification) event.dispatch(context);
      }
    });
  }

  /// 结束触控触发的上下文菜单长按计时
  void clearTouchContextMenuTimer() {
    if (touchContextMenuTimer != null) {
      touchContextMenuTimer!.cancel();
      touchContextMenuTimer = null;
    }
  }

  /// 短暂的禁用右键菜单, 如果已经处于禁用状态则什么都不会发生
  void tempDisableContextAction() {
    if (kIsWeb && BrowserContextMenu.enabled) {
      if (tempDisableContextActionTimer != null) {
        tempDisableContextActionTimer!.cancel();
      }
      BrowserContextMenu.disableContextMenu();

      tempDisableContextActionTimer = Timer(
        const Duration(seconds: 1),
        () {
          BrowserContextMenu.enableContextMenu();
          tempDisableContextActionTimer = null;
        },
      );
    }
  }

  /// 根据 TapDownDetails / TapUpDetails / KeyEvent 之一获取 tap 事件
  ZoTriggerEvent getTapEvent(
    dynamic details, {
    ZoTriggerType type = ZoTriggerType.tap,
    PointerDeviceKind? kind,
    KeyEventDeviceType? keyEventDeviceType,
  }) {
    assert(
      details is TapDownDetails ||
          details is TapUpDetails ||
          details is KeyEvent,
    );

    var position = Offset.zero;
    var offset = Offset.zero;

    if (details is TapDownDetails || details is TapUpDetails) {
      position = details.globalPosition;
      offset = details.localPosition;
    }

    return ZoTriggerEvent(
      type: type,
      time: DateTime.now(),
      trigger: widget,
      position: position,
      offset: offset,
      data: widget.data,
      deviceKind: kind,
      keyEventDeviceType: keyEventDeviceType,
    );
  }

  /// 获取失活事件, 必须在当前处于活动状态时调用, 获取后会清理 activeOpenEvent 等状态
  ZoTriggerToggleEvent getInactiveEvent() {
    assert(lastActiveEvent != null);

    final e = ZoTriggerToggleEvent(
      type: ZoTriggerType.active,
      time: DateTime.now(),
      trigger: widget,
      position: lastActiveEvent!.position,
      offset: lastActiveEvent!.offset,
      toggle: false,
      data: widget.data,
      deviceKind: lastActiveEvent!.deviceKind,
    );

    lastActiveEvent = null;
    isTapActive = false;

    return e;
  }

  /// 限制可拖动的轴
  Offset clampAxis(Offset offset) {
    return switch (widget.dragAxis) {
      Axis.horizontal => Offset(offset.dx, 0),
      Axis.vertical => Offset(0, offset.dy),
      _ => offset,
    };
  }

  /// 设置拖动光标
  void setDragCursor(bool dragging) {
    if (widget.onDrag != null && widget.changeCursor) {
      if (dragging && currentCursor != SystemMouseCursors.grabbing) {
        setState(() {
          currentCursor = SystemMouseCursors.grabbing;
        });
      }

      if (!dragging && currentCursor != SystemMouseCursors.grab) {
        setState(() {
          currentCursor = SystemMouseCursors.grab;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var child = widget.child;

    final enable = widget.enabled;

    final contextActionEnable = widget.onContextAction != null;

    final enableTap =
        widget.onTap != null ||
        widget.onTapDown != null ||
        // pan 启用时，同时启用 tap 来防止按下立即触发拖动
        widget.onDrag != null;

    final enableTouchLikeTap =
        widget.onTap != null ||
        widget.onTapDown != null ||
        /// 触控类操作需要使用tap来模拟active
        widget.onActiveChanged != null;

    final enableDrag = widget.onDrag != null;

    final enableMouse =
        // tap / drag 事件需要定制光标, 所以需要启用 MouseRegion
        enableTap ||
        enableDrag ||
        widget.onActiveChanged != null ||
        widget.onMove != null;

    final enableFocus = widget.onFocusChanged != null;

    /// 各事件的实现方式:
    /// tap: tapUp + onKeyEvent
    /// tapDown: tapDown + onKeyEvent
    /// active: 鼠标: onEnter + onExit  触控: onTapDown + onTapUp + onTapCancel
    /// focus: Focus
    /// contextAction: 鼠标: onSecondaryTapDown 触控: tap + timer
    /// drag:
    /// - 非触控设备，onPan 系列事件，会同时启用 tap 事件来防止按下马上触发拖动，但这会导致后方组件的tap被覆盖，
    /// 另外还会在tap事件中更新光标，而不是等到实际开始拖动时
    /// - 移动端使用 longPress 实现，防止干扰滚动操作
    /// move: onEnter + onExit + onHover

    /// 根据 longPressDragOnTouch 调整触发事件类型，未启用时使用单个 GestureDetector 处理所有事件
    ///
    /// 这里额外排除了 trackpad 事件，因为它会导致 pan 等事件通过双指也能触发，这不符合预期，需要主动过滤掉，详情见:
    /// https://github.com/flutter/flutter/issues/107005
    final supportedDevices = widget.longPressDragOnTouch
        ? const <PointerDeviceKind>{
            PointerDeviceKind.mouse,
            PointerDeviceKind.unknown,
          }
        : const <PointerDeviceKind>{
            PointerDeviceKind.mouse,
            PointerDeviceKind.unknown,
            PointerDeviceKind.touch,
            PointerDeviceKind.stylus,
            PointerDeviceKind.invertedStylus,
          };

    if (enable && (enableTap || contextActionEnable || enableDrag)) {
      child = GestureDetector(
        onTapUp: enable && enableTap ? onTapUp : null,
        onTapDown: enable && enableTap ? onTapDown : null,
        onTapCancel: enable && enableTap ? onTapCancel : null,
        onSecondaryTapDown: enable && contextActionEnable
            ? onSecondaryTapDown
            : null,
        onPanStart: (enable && enableDrag) ? onPanStart : null,
        onPanEnd: enable && enableDrag ? onPanEnd : null,
        onPanUpdate: enable && enableDrag ? onPanUpdate : null,
        onPanCancel: enable && enableDrag ? onPanCancel : null,
        supportedDevices: supportedDevices,
        behavior: widget.behavior,
        child: child,
      );
    }

    /// 为触摸类事件使用单独的 GestureDetector，
    if (widget.longPressDragOnTouch &&
        enable &&
        (enableTouchLikeTap || enableDrag)) {
      child = GestureDetector(
        onTapUp: enable && enableTouchLikeTap ? onTapUp : null,
        onTapDown: enable && enableTouchLikeTap ? onTapDown : null,
        onTapCancel: enable && enableTouchLikeTap ? onTapCancel : null,
        onLongPressDown: enable && enableDrag ? onLongPressDown : null,
        onLongPressStart: enable && enableDrag ? onLongPressStart : null,
        onLongPressEnd: enable && enableDrag ? onLongPressEnd : null,
        onLongPressMoveUpdate: enable && enableDrag
            ? onLongPressMoveUpdate
            : null,
        onLongPressCancel: enable && enableDrag ? onLongPressCancel : null,
        supportedDevices: ZoTrigger.touchLike,
        behavior: widget.behavior,
        child: child,
      );
    }

    // 聚焦状态
    if (enableFocus) {
      child = Focus(
        canRequestFocus: widget.enabled && widget.canRequestFocus,
        autofocus: widget.autofocus,
        focusNode: focusNode,
        onFocusChange: onFocusChanged,
        onKeyEvent: onKeyEvent,
        child: child,
      );
    }

    // 鼠标监听
    if (enableMouse) {
      final enterExitEnable =
          enable && (widget.onActiveChanged != null || widget.onMove != null);

      MouseCursor cursor = widget.defaultCursor ?? MouseCursor.defer;

      if (widget.changeCursor) {
        if (currentCursor != null) {
          cursor = currentCursor!;
        } else if (!widget.enabled) {
          cursor = SystemMouseCursors.forbidden;
        } else if (enableDrag) {
          cursor = SystemMouseCursors.grab;
        } else if (enableTap) {
          cursor = SystemMouseCursors.click;
        }
      }

      child = MouseRegion(
        cursor: cursor,
        onEnter: enterExitEnable ? onMouseEnter : null,
        onExit: enterExitEnable ? onMouseExit : null,
        onHover: enable && widget.onMove != null ? onMouseHover : null,
        child: child,
      );
    }

    return child;
  }
}

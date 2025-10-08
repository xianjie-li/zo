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

  /// 屏幕坐标
  final Offset position;

  /// 距离目标左上角的位置
  final Offset offset;

  /// 绑定到组件的额外信息
  final dynamic data;

  /// 触发事件的设备类型, 仅部分事件包含
  final PointerDeviceKind? deviceKind;

  /// 除非事件的按键设备类型, 仅部分事件包含
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
  /// 焦点节点,
  final FocusNode? focusNode;

  /// 传递给 [ZoTrigger] 的 data
  final dynamic data;

  /// 构造函数
  ZoTriggerFocusNodeChangedNotification({
    this.focusNode,
    this.data,
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
    this.changeCursor = false,
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

  /// 是否变更显示的光标
  final bool changeCursor;

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
      ).dispatch(context);
    }
  }

  @override
  void dispose() {
    super.dispose();
    ZoTriggerFocusNodeChangedNotification(
      focusNode: null,
      data: widget.data,
    ).dispatch(context);

    if (widget.focusNode != focusNode) {
      focusNode.dispose();
    }
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

    // 在外部事件触发之前获取焦点，避免在外部handle中需要控制焦点时发生冲突
    if (widget.canRequestFocus && widget.focusOnTap) {
      focusNode.requestFocus();
    }

    final tapEvent = getTapEvent(details, kind: details.kind);
    widget.onTap?.call(tapEvent);
    tapEvent.dispatch(context);

    setDragCursor(false);

    /// 关闭 active 事件
    if (lastActiveEvent != null && isTapActive) {
      final inactiveEvent = getInactiveEvent();
      widget.onActiveChanged!(inactiveEvent);
      inactiveEvent.dispatch(context);
    }
  }

  void onTapDown(TapDownDetails details) {
    lastTapDownDetails = details;

    tapPending = true;

    final downEvent = getTapEvent(details, kind: details.kind);
    widget.onTapDown?.call(downEvent);

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
        event.dispatch(context);
      }
    }
  }

  void onTapCancel() {
    tapPending = false;

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

    lastTapDownDetails = null;

    setDragCursor(false);

    /// 关闭 active 事件
    if (lastActiveEvent != null && isTapActive) {
      final event = getInactiveEvent();
      widget.onActiveChanged!(event);
      event.dispatch(context);
    }
  }

  LongPressDownDetails? lastLongPressDownDetails;

  void onLongPressDown(LongPressDownDetails details) {
    lastLongPressDownDetails = details;

    tempDisableContextAction();
  }

  void onLongPressStart(LongPressStartDetails details) {
    final kind = lastLongPressDownDetails?.kind;
    lastLongPressDownDetails = null;

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
      event.dispatch(context);
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
      event.dispatch(context);
    }
  }

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
      e.dispatch(context);
    }

    /// 关闭 active 事件
    if (lastActiveEvent != null && !isTapActive) {
      final inactiveEvent = getInactiveEvent();
      widget.onActiveChanged!(inactiveEvent);
      inactiveEvent.dispatch(context);
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
      e.dispatch(context);
    }

    /// 当前没有已开始的 active 事件时触发
    if (widget.onActiveChanged != null &&
        lastActiveEvent == null &&
        !isTapActive) {
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
      e.dispatch(context);
    }
  }

  KeyEventResult onKeyEvent(FocusNode node, KeyEvent event) {
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
        tapEvent.dispatch(context);

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

      e.dispatch(context);
    }
  }

  void onPanStart(DragStartDetails details) {
    if (widget.onDrag == null || lastDragEvent != null) {
      return;
    }

    setDragCursor(true);

    final e = ZoTriggerDragEvent(
      type: ZoTriggerType.drag,
      time: DateTime.now(),
      trigger: widget,
      position: clampAxis(details.globalPosition),
      offset: details.localPosition,
      first: true,
      cancel: cancelDrag,
      data: widget.data,
      deviceKind: details.kind,
    );

    lastDragEvent = e;

    widget.onDrag!(e);
    e.dispatch(context);
  }

  void onPanEnd(DragEndDetails details) {
    if (lastDragEvent == null) return;

    setDragCursor(false);

    final e = ZoTriggerDragEvent(
      type: ZoTriggerType.drag,
      time: DateTime.now(),
      trigger: widget,
      position: clampAxis(details.globalPosition),
      offset: details.localPosition,
      last: true,
      cancel: cancelDrag,
      velocity: details.velocity,
      data: widget.data,
      deviceKind: lastDragEvent?.deviceKind,
    );

    lastDragEvent = null;

    widget.onDrag?.call(e);
    e.dispatch(context);
  }

  void onPanCancel() {
    if (lastDragEvent == null) return;

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
    e.dispatch(context);
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (lastDragEvent == null) return;

    final delta = clampAxis(details.delta);

    final e = ZoTriggerDragEvent(
      type: ZoTriggerType.drag,
      time: DateTime.now(),
      trigger: widget,
      position: clampAxis(details.globalPosition),
      offset: details.localPosition,
      delta: delta,
      cancel: cancelDrag,
      data: widget.data,
      deviceKind: lastDragEvent?.deviceKind,
    );

    lastDragEvent = e;

    widget.onDrag?.call(e);
    e.dispatch(context);
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

  /// 取消正在进行的 drag 事件
  void cancelDrag() {
    if (lastDragEvent != null) {
      onPanCancel();
    }
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

    child = GestureDetector(
      child: child,
    );

    final enable = widget.enabled;

    final contextActionEnable = widget.onContextAction != null;

    final enableTap = widget.onTap != null || widget.onTapDown != null;

    final enableActive = widget.onActiveChanged != null;

    /// 是否需要强制绑定 tap 事件, drag 等事件会受 tap 的绑定状态影响, 它还会会影响父级的 tab 命中,
    /// 所以在必要时才绑定, 比如在包含 tab 事件时, drag 会延迟到第一次拖动才触发 start, 而不是在按下时
    final needForceBindTap = enableTap || enableActive;

    final dragEnable = widget.onDrag != null;

    final enableMouse =
        // tap / drag 事件需要定制光标, 所以需要启用 MouseRegion
        enableTap ||
        dragEnable ||
        widget.onActiveChanged != null ||
        widget.onMove != null;

    final enableFocus = widget.onFocusChanged != null;

    /// 各事件的实现方式:
    /// tap: tapUp + onKeyEvent
    /// tapDown: tapDown + onKeyEvent
    /// active: 鼠标: onEnter + onExit  触控: onTapDown + onTapUp + onTapCancel
    /// focus: Focus
    /// contextAction: 鼠标: onSecondaryTapDown 触控: onLongPressStart + onLongPressDown (按需绑定, 否则会影响 tap 事件)
    /// drag: onPan 系列事件, 在绑定了 tap 时, 会改为在 tap 中改变光标
    /// move: onEnter + onExit + onHover

    child = GestureDetector(
      onTapUp: enable && enableTap ? onTapUp : null,
      onTapDown: enable && enableTap ? onTapDown : null,
      onTapCancel: enable && enableTap ? onTapCancel : null,
      onSecondaryTapDown: enable && contextActionEnable
          ? onSecondaryTapDown
          : null,
      onPanStart: enable ? onPanStart : null,
      onPanEnd: enable ? onPanEnd : null,
      onPanCancel: enable ? onPanCancel : null,
      onPanUpdate: enable ? onPanUpdate : null,
      behavior: widget.behavior,
      child: child,
    );

    // 部分仅在 touch 设备绑定, 防止影响 tap 的触发
    if (contextActionEnable || needForceBindTap) {
      child = GestureDetector(
        onLongPressStart: enable && contextActionEnable
            ? onLongPressStart
            : null,
        onLongPressDown: enable && contextActionEnable ? onLongPressDown : null,
        onTapUp: enable && needForceBindTap ? onTapUp : null,
        onTapDown: enable && needForceBindTap ? onTapDown : null,
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

      MouseCursor cursor = MouseCursor.defer;

      if (widget.changeCursor) {
        if (currentCursor != null) {
          cursor = currentCursor!;
        } else if (!widget.enabled) {
          cursor = SystemMouseCursors.forbidden;
        } else if (dragEnable) {
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

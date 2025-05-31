import "package:flutter/material.dart";

/// 由 [ZoDragTrigger] 派发的事件
class ZoDragTriggerEvent extends Notification {
  ZoDragTriggerEvent({
    required this.offset,
    required this.context,
    this.delta = Offset.zero,
    this.first = false,
    this.last = false,
    this.canceled = false,
    this.velocity = Velocity.zero,
    required this.cancel,
  });

  /// 触发的上下文
  final BuildContext context;

  /// 当前位置
  final Offset offset;

  /// 本次拖动的偏移量
  final Offset delta;

  /// 是否是拖动开始
  final bool first;

  /// 是否是拖动结束
  final bool last;

  /// 如果事件被取消, 此项为 true, 通常与 last 同时设置
  final bool canceled;

  /// 拖动结束时的速度
  final Velocity velocity;

  /// 取消事件
  final VoidCallback cancel;
}

/// 为子级添加拖动事件派发, 除了 onDrag 外, 它还会向上派发 Notification 事件, 可以树的上方接收通知
class ZoDragTrigger extends StatefulWidget {
  const ZoDragTrigger({
    super.key,
    this.enabled = true,
    this.axis,
    this.changeCursor = false,
    this.onDrag,
    required this.child,
  });

  /// 是否启用
  final bool enabled;

  /// 设置后, 将只能派发指定方向的拖动
  final Axis? axis;

  /// 是否变更显示的光标
  final bool changeCursor;

  /// 拖动事件
  final void Function(ZoDragTriggerEvent event)? onDrag;

  /// 子级
  final Widget child;

  @override
  State<ZoDragTrigger> createState() => _ZoDragTriggerState();
}

class _ZoDragTriggerState extends State<ZoDragTrigger> {
  ZoDragTriggerEvent? last;

  MouseCursor? cursor;

  @override
  void initState() {
    super.initState();
    if (widget.changeCursor) {
      cursor = SystemMouseCursors.grab;
    }
  }

  void onPanUpdate(DragUpdateDetails details) {
    if (last == null) return;

    final e = ZoDragTriggerEvent(
      offset: clampAxis(details.globalPosition),
      delta: clampAxis(details.delta),
      context: context,
      cancel: cancel,
    );

    last = e;

    e.dispatch(context);
    widget.onDrag?.call(e);
  }

  void onPanStart(DragStartDetails details) {
    if (!widget.enabled || last != null) return;

    if (widget.changeCursor) {
      setState(() {
        cursor = SystemMouseCursors.grabbing;
      });
    }

    final e = ZoDragTriggerEvent(
      offset: clampAxis(details.globalPosition),
      first: true,
      context: context,
      cancel: cancel,
    );

    last = e;

    e.dispatch(context);
    widget.onDrag?.call(e);
  }

  void onPanEnd(DragEndDetails details) {
    if (last == null) return;

    if (widget.changeCursor) {
      setState(() {
        cursor = SystemMouseCursors.grab;
      });
    } else if (cursor != null) {
      setState(() {
        cursor = null;
      });
    }

    final e = ZoDragTriggerEvent(
      offset: clampAxis(details.globalPosition),
      last: true,
      velocity: details.velocity,
      context: context,
      cancel: cancel,
    );

    last = null;

    e.dispatch(context);
    widget.onDrag?.call(e);
  }

  void onPanCancel() {
    if (last == null) return;

    if (widget.changeCursor) {
      setState(() {
        cursor = SystemMouseCursors.grab;
      });
    } else if (cursor != null) {
      setState(() {
        cursor = null;
      });
    }

    final e = ZoDragTriggerEvent(
      offset: last!.offset,
      last: true,
      canceled: true,
      context: context,
      cancel: cancel,
    );

    last = null;

    e.dispatch(context);
    widget.onDrag?.call(e);
  }

  void cancel() {
    if (last != null) {
      onPanCancel();
    }
  }

  Offset clampAxis(Offset offset) {
    return switch (widget.axis) {
      Axis.horizontal => Offset(offset.dx, 0),
      Axis.vertical => Offset(0, offset.dy),
      _ => offset,
    };
  }

  @override
  Widget build(BuildContext context) {
    Widget child = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: onPanStart,
      onPanEnd: onPanEnd,
      onPanCancel: onPanCancel,
      onPanUpdate: onPanUpdate,
      child: widget.child,
    );

    if (widget.changeCursor && cursor != null) {
      child = MouseRegion(
        cursor: cursor!,
        child: child,
      );
    }

    return child;
  }
}

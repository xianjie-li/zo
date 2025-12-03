import "package:flutter/gestures.dart";
import "package:flutter/material.dart";

/// 自适应拖动检测器
/// - 鼠标/触控板：按下立即触发拖动 (Pan)
/// - 触摸屏：短按 (150ms) 后触发拖动 (LongPress)，以防误触滚动
class AdaptiveDragDetector extends StatefulWidget {
  final Widget child;
  final void Function(Offset globalPosition)? onDragStart;
  final void Function(Offset globalPosition, Offset delta)? onDragUpdate;
  final void Function()? onDragEnd;
  final void Function()? onDragCancel;

  const AdaptiveDragDetector({
    super.key,
    required this.child,
    this.onDragStart,
    this.onDragUpdate,
    this.onDragEnd,
    this.onDragCancel,
  });

  @override
  State<AdaptiveDragDetector> createState() => _AdaptiveDragDetectorState();
}

class _AdaptiveDragDetectorState extends State<AdaptiveDragDetector> {
  // 用于计算 LongPress 模式下的 delta
  Offset? _lastPosition;

  @override
  Widget build(BuildContext context) {
    return RawGestureDetector(
      gestures: {
        // 1. 针对鼠标/触控板：使用修改版的 Pan 识别器
        _MousePanGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<_MousePanGestureRecognizer>(
              () => _MousePanGestureRecognizer(debugOwner: this),
              (_MousePanGestureRecognizer instance) {
                instance.onStart = (details) {
                  widget.onDragStart?.call(details.globalPosition);
                };
                instance.onUpdate = (details) {
                  widget.onDragUpdate?.call(
                    details.globalPosition,
                    details.delta,
                  );
                };
                instance.onEnd = (details) => widget.onDragEnd?.call();
                instance.onCancel = () => widget.onDragCancel?.call();
              },
            ),

        // 2. 针对触摸屏：使用短按 (150ms) 触发的长按识别器
        _TouchShortPressGestureRecognizer:
            GestureRecognizerFactoryWithHandlers<
              _TouchShortPressGestureRecognizer
            >(
              () => _TouchShortPressGestureRecognizer(debugOwner: this),
              (_TouchShortPressGestureRecognizer instance) {
                instance.onLongPressStart = (details) {
                  _lastPosition = details.globalPosition;
                  widget.onDragStart?.call(details.globalPosition);
                };
                instance.onLongPressMoveUpdate = (details) {
                  final currentPos = details.globalPosition;
                  // 手动计算 delta
                  final delta = currentPos - (_lastPosition ?? currentPos);
                  _lastPosition = currentPos;

                  widget.onDragUpdate?.call(currentPos, delta);
                };
                instance.onLongPressEnd = (details) {
                  _lastPosition = null;
                  widget.onDragEnd?.call();
                };
                instance.onLongPressCancel = () {
                  _lastPosition = null;
                  widget.onDragCancel?.call();
                };
              },
            ),
      },
      child: widget.child,
    );
  }
}

// --- 自定义识别器 ---

/// 仅响应鼠标的 Pan 识别器
class _MousePanGestureRecognizer extends PanGestureRecognizer {
  _MousePanGestureRecognizer({super.debugOwner});

  @override
  bool isPointerAllowed(PointerEvent event) {
    // 关键：只允许鼠标或触控板
    return event.kind == PointerDeviceKind.mouse ||
        event.kind == PointerDeviceKind.trackpad;
  }
}

/// 仅响应触摸的"短按"识别器
class _TouchShortPressGestureRecognizer extends LongPressGestureRecognizer {
  _TouchShortPressGestureRecognizer({
    super.debugOwner,
  }) : super(
         // 关键：设置一个很短的延迟 (例如 150ms)
         // 这个时间足够区分"点击"和"滚动"，又不会让拖动感觉太慢
         duration: const Duration(milliseconds: 150),
         // 允许稍微移动一点点手指而不打断判定 (默认是 18.0)
         postAcceptSlopTolerance: 18.0,
       );

  @override
  bool isPointerAllowed(PointerEvent event) {
    // 关键：只允许触摸
    return event.kind == PointerDeviceKind.touch ||
        event.kind == PointerDeviceKind.stylus ||
        event.kind == PointerDeviceKind.unknown; // 某些模拟器
  }
}

import "package:flutter/gestures.dart";

/// 立即触发拖动操作的 [PanGestureRecognizer], 主要针对的场景是触控操作并且在滚动容器内进行的拖动，
/// 这些滚动滚动事件优先级最高，使用此 Recognizer 可先于滚动视图占用事件，但也会覆盖掉 tap 等事件
class ImmediatePanGestureRecognizer extends PanGestureRecognizer {
  ImmediatePanGestureRecognizer({
    super.debugOwner,
    super.allowedButtonsFilter,
    super.supportedDevices,
  });

  @override
  void addAllowedPointer(PointerDownEvent event) {
    super.addAllowedPointer(event);
    resolve(GestureDisposition.accepted);
  }

  @override
  String get debugDescription => "immediate pan";
}

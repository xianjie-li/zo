part of "package:zo/src/overlay/overlay.dart";

/// popper 可用的定位方向
enum ZoPopperDirection {
  topLeft,
  top,
  topRight,
  rightTop,
  right,
  rightBottom,
  bottomRight,
  bottom,
  bottomLeft,
  leftBottom,
  left,
  leftTop,
}

/// 控制层在通过 dismiss 或 tapAway / escape / Navigator.pop 等行为触发关闭时, 应该销毁还是仅关闭层
enum ZoOverlayDismissMode {
  close, // 仅关闭弹层，保留资源
  dispose, // 销毁弹层，释放资源
}

/// 方向定位中, 包含对应方向的位置, 遮挡状态等信息
class ZoDirectionLayoutData {
  const ZoDirectionLayoutData({
    required this.direction,
    required this.position,
    required this.mainOverflow,
    required this.crossOverflow,
    required this.crossOverflowDistance,
  });

  /// 对应的方向
  final ZoPopperDirection direction;

  /// 位置
  final Offset position;

  /// 在该方向的主轴是否超出
  final bool mainOverflow;

  /// 在该方向的交叉轴是否超出
  final bool crossOverflow;

  /// 交叉轴溢出的距离, 为正数表示从开始方向溢出, 为负数表示从结束方向溢出, position
  /// 加上此值就可以得到修正后的位置
  final double crossOverflowDistance;
}

/// 层布局和绘制阶段向外暴露的信息, 用于对层位置或绘制进行自定义
class ZoOverlayCustomPaintData {
  ZoOverlayCustomPaintData({required this.offset, this.directionLayoutData});

  /// 当前已确定的层位置
  final Offset offset;

  /// 如果是带方向的布局, 此项为方向信息, 方向可能已经过 [ZoOverlayEntry.preventOverflow] 调整
  final ZoDirectionLayoutData? directionLayoutData;
}

/// 拖动结束时传入的信息
class ZoOverlayDragEndData {
  ZoOverlayDragEndData({
    required this.event,
    required this.position,
    required this.overlayRect,
    required this.overlayStartRect,
    required this.containerRect,
  });

  /// 事件对象本身
  final ZoTriggerDragEvent event;

  /// 位置
  final Offset position;

  /// 层位置信息
  final Rect overlayRect;

  /// 层开始移动时的位置
  final Rect overlayStartRect;

  /// 容器位置信息
  final Rect containerRect;
}

/// 检测箭头轴方向
bool isVerticalDirection(ZoPopperDirection direction) {
  return direction == ZoPopperDirection.topLeft ||
      direction == ZoPopperDirection.topRight ||
      direction == ZoPopperDirection.top ||
      direction == ZoPopperDirection.bottomLeft ||
      direction == ZoPopperDirection.bottomRight ||
      direction == ZoPopperDirection.bottom;
}

/// 根据 ZoPopperDirection 获取 AxisDirection
AxisDirection axisDirectionToPopperDirection(ZoPopperDirection direction) {
  return switch (direction) {
    ZoPopperDirection.top ||
    ZoPopperDirection.topLeft ||
    ZoPopperDirection.topRight => AxisDirection.up,
    ZoPopperDirection.bottom ||
    ZoPopperDirection.bottomLeft ||
    ZoPopperDirection.bottomRight => AxisDirection.down,
    ZoPopperDirection.right ||
    ZoPopperDirection.rightTop ||
    ZoPopperDirection.rightBottom => AxisDirection.right,
    ZoPopperDirection.left ||
    ZoPopperDirection.leftTop ||
    ZoPopperDirection.leftBottom => AxisDirection.left,
  };
}

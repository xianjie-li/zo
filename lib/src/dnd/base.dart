import "package:flutter/material.dart";
import "dnd.dart";

/// 可用的放置位置
class ZoDNDPosition {
  const ZoDNDPosition({
    this.top = false,
    this.right = false,
    this.bottom = false,
    this.left = false,
    this.center = false,
  });

  /// 默认启用所有，也可以单独指定某个位置的值
  const ZoDNDPosition.all({
    bool? top,
    bool? right,
    bool? bottom,
    bool? left,
    bool? center,
  }) : top = top ?? true,
       right = right ?? true,
       bottom = bottom ?? true,
       left = left ?? true,
       center = center ?? true;

  /// 包含任意一个有效位置
  bool get any => top || right || bottom || left || center;

  /// 所有位置均有效
  bool get all => top && right && bottom && left && center;

  final bool top;

  final bool right;

  final bool bottom;

  final bool left;

  /// 中间位置，会包含周围未启用的位置, 例：left 未启用，其占用区域也会视作 center
  final bool center;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ZoDNDPosition &&
        other.top == top &&
        other.right == right &&
        other.bottom == bottom &&
        other.left == left &&
        other.center == center;
  }

  @override
  int get hashCode {
    return Object.hash(
      top,
      right,
      bottom,
      left,
      center,
    );
  }

  @override
  String toString() {
    return "ZoDNDPosition(top: $top, right: $right, bottom: $bottom, left: $left, center: $center)";
  }
}

/// 当前的拖动状态信息
class ZoDNDBuildContext {
  ZoDNDBuildContext({
    this.dragging = false,
    this.dragDND,
    this.draggable = false,
    required this.droppablePosition,
    required this.activePosition,
  });

  /// 当前节点是否正在被拖动
  bool dragging;

  /// 当前处于拖动状态的dnd
  ZoDND? dragDND;

  /// 该节点是否可拖动
  bool draggable;

  /// 当前dnd节点的可放置位置信息
  ZoDNDPosition droppablePosition;

  /// 当前被激活的放置位置
  ZoDNDPosition activePosition;
}

/// dnd事件类型, 详细说明见 [ZoDND] 组件对应事件
enum ZoDNDEventType {
  dragStart,
  dragMove,
  dragEnd,
  accept,
}

/// 拖动时持续触发的事件
class ZoDNDEvent {
  const ZoDNDEvent({
    required this.type,
    required this.dragDND,
    required this.activePosition,
    this.activeDND,
  });

  /// 类型
  final ZoDNDEventType type;

  /// 拖动的节点
  final ZoDND dragDND;

  /// 上方存在正在拖动节点的 dnd
  final ZoDND? activeDND;

  /// 当前被激活的放置位置
  final ZoDNDPosition activePosition;
}

/// 放置事件
class ZoDNDDropEvent extends ZoDNDEvent {
  const ZoDNDDropEvent({
    required super.type,
    required super.dragDND,
    required super.activeDND,
    required super.activePosition,
  });

  /// 放置的节点
  ZoDND get dropDND => super.activeDND!;
}

/// 通过widget树向上通知的 [ZoDNDEvent]
class ZoDNDEventNotification extends Notification {
  ZoDNDEventNotification(this.dndEvent);

  ZoDNDEvent dndEvent;
}

/// 仅接受 accept 事件的 [ZoDNDEventNotification]
class ZoDNDAcceptNotification extends ZoDNDEventNotification {
  ZoDNDAcceptNotification(super.dndEvent);
}

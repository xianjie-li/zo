import "dart:async";
import "dart:math" as math;

import "package:flutter/material.dart";
import "package:zo/src/result/status_icon.dart";
import "package:zo/zo.dart";

part "entry.dart";

/// 所有 [ZoPopper] 组件通过 [ZoPopperManager] 复用的单个实例，
/// 可通过改实例访问当前气泡或进行命令式控制
ZoPopperManager? zoPopperPublicManager;

/// 实现气泡提示, 用于在目标的指定方向进行轻量和快速的内容展示
class ZoPopper extends StatefulWidget {
  const ZoPopper({
    super.key,
    required this.child,
    this.type = ZoTriggerType.tap,
    this.direction = ZoPopperDirection.top,
    this.content,
    this.icon,
    this.status,
    this.title,
    this.onConfirm,
    this.confirmText,
    this.cancelText,
    this.maxWidth,
    this.arrow = true,
    this.padding,
    this.tapAwayClosable = true,
    this.escapeClosable = true,
    this.requestFocus = true,
    this.requestTargetFocus = false,
    this.preventOverflow = true,
    this.onOpenChanged,
    this.waitDuration,
  });

  /// 在为 popper 添加开启延迟时，可使用该值
  static const Duration defaultWaitDuration = Durations.long2;

  /// 子级, 会作为气泡的触发目标
  final Widget child;

  /// 触发方式, 支持除 [ZoTriggerType.drag] 外的事件
  ///
  /// focus 触发的注意事项:
  /// - 使用 [ZoTriggerType.focus] 事件时, 需要将 [requestFocus] 设置为 false, 因为在层打开后,
  /// 当前目标会失去焦点从而触发关闭, 而层关闭后焦点会返回到前一个节点也就是目标节点, 造成递归的聚焦和失焦
  /// - 子级是按钮等本身就可聚焦的节点时, 通常也需要将 [requestFocus] 设置为 false 来使用子级的聚焦状态
  final ZoTriggerType type;

  /// 气泡显示的方向
  final ZoPopperDirection? direction;

  /// 显示的主要内容
  final Widget? content;

  /// 自定义图标, 通常用于表示状态
  final Widget? icon;

  /// 指定状态, 会在内容之前显示不同的状态图标
  final ZoStatus? status;

  /// 显示标题
  final Widget? title;

  /// 传入时, 显示底部确认栏, 并在确认后回调
  final VoidCallback? onConfirm;

  /// 确认按钮文本
  final String? confirmText;

  /// 取消按钮文本, 传入时显示取消按钮, 需要同时传入 [onConfirm] 才会生效
  final String? cancelText;

  /// 设置最大宽度, 默认会包含一个 180 的最大宽度, 防止 tooltip 等快捷提示占用太大宽度而显得突兀
  final double? maxWidth;

  /// 是否显示箭头
  final bool arrow;

  /// 外间距
  final EdgeInsets? padding;

  /// 点击内容区域外时, 是否关闭层
  final bool tapAwayClosable;

  /// 点击 esc 键是否关闭层
  final bool escapeClosable;

  /// 层是否需要获取焦点
  final bool requestFocus;

  /// 目标是否需要获取焦点, 当子级本身就是可聚焦节点时, 通常会禁用此项
  final bool requestTargetFocus;

  /// 启用防遮挡功能, 详情见 [ZoOverlayEntry.preventOverflow]
  final bool preventOverflow;

  /// 打开或关闭时触发
  final void Function(bool open)? onOpenChanged;

  /// 设置此值时，通过光标悬浮触发时，层会延迟该时间后才出现
  final Duration? waitDuration;

  @override
  State<ZoPopper> createState() => _ZoPopperState();
}

class _ZoPopperState extends State<ZoPopper> {
  ZoPopperManager get manager {
    // 初始化
    zoPopperPublicManager ??= ZoPopperManager(
      entry: createOrUpdateEntry(),
    );

    return zoPopperPublicManager!;
  }

  ZoPopperEntry get entry => manager.entry;

  @override
  @protected
  void dispose() {
    if (manager.target == this) {
      manager.delayClose();
      manager.target = null;
    }
    super.dispose();
  }

  void overlayHoverChanged(bool hovered) {
    if (hovered) {
      manager._clearCloseTimer();
    } else {
      manager.delayClose();
    }
  }

  ZoPopperEntry createOrUpdateEntry() {
    if (zoPopperPublicManager == null) {
      return ZoPopperEntry(
        alignment: Alignment.center,
        direction: widget.direction,
        content: widget.content,
        icon: widget.icon,
        status: widget.status,
        title: widget.title,
        onConfirm: widget.onConfirm,
        confirmText: widget.confirmText,
        cancelText: widget.cancelText,
        maxWidth: widget.maxWidth,
        arrow: widget.arrow,
        padding: widget.padding,
        tapAwayClosable: widget.tapAwayClosable,
        escapeClosable: widget.escapeClosable,
        requestFocus: widget.requestFocus,
        preventOverflow: widget.preventOverflow,
        onOpenChanged: widget.onOpenChanged,
        dismissMode: ZoOverlayDismissMode.close,
      );
    }

    final entry = zoPopperPublicManager!.entry;

    entry.actions(() {
      entry.direction = widget.direction;
      entry.content = widget.content;
      entry.icon = widget.icon;
      entry.status = widget.status;
      entry.title = widget.title;
      entry.onConfirm = widget.onConfirm;
      entry.confirmText = widget.confirmText;
      entry.cancelText = widget.cancelText;
      entry.maxWidth = widget.maxWidth;
      entry.arrow = widget.arrow;
      entry.padding = widget.padding;
      entry.tapAwayClosable = widget.tapAwayClosable;
      entry.escapeClosable = widget.escapeClosable;
      entry.requestFocus = widget.requestFocus;
      entry.preventOverflow = widget.preventOverflow;
      entry.onOpenChanged = widget.onOpenChanged;
    }, false);

    return entry;
  }

  // 最后绘制的位置信息
  Rect? lastRect;

  Rect _getRectByContext(BuildContext context) {
    final obj = context.findRenderObject() as RenderBox;
    return obj.localToGlobal(Offset.zero) & obj.size;
  }

  void onPaint(RenderBox box) {
    // 这些事件由事件对象决定位置, 不需要目标位置
    if (widget.type == ZoTriggerType.contextAction ||
        widget.type == ZoTriggerType.move) {
      return;
    }

    lastRect = box.localToGlobal(Offset.zero) & box.size;

    if (entry.rect != null &&
        entry.rect != lastRect &&
        manager.target == this) {
      entry.actions(() {
        entry.rect = lastRect;
      }, entry.currentOpen);
    }
  }

  void onTap(ZoTriggerEvent event) {
    createOrUpdateEntry();

    entry.actions(() {
      entry.offset = null;
      entry.rect = _getRectByContext(event.context);
    });

    manager.open(target: this);
  }

  void onToggleChanged(ZoTriggerToggleEvent event) {
    if (event.toggle) {
      createOrUpdateEntry();

      entry.actions(() {
        entry.offset = null;
        entry.rect = _getRectByContext(event.context);
      });

      if (ZoTrigger.isTouchLike(event.deviceKind)) {
        // 触摸类设备本身就带了延迟，不需要再添加
        manager.open(target: this);
      } else {
        manager.open(
          waitDuration: widget.waitDuration,
          target: this,
          beforeOpen: () {
            entry.rect = _getRectByContext(event.context);
          },
        );
      }
    } else {
      manager.delayClose();
    }
  }

  void onContextMenu(ZoTriggerEvent event) {
    createOrUpdateEntry();

    entry.actions(() {
      entry.rect = null;
      entry.offset = event.position;
    });

    manager.open(target: this);
  }

  void onMove(ZoTriggerMoveEvent event) {
    // !entry.currentOpen 可避免快速移动到层上导致关闭
    if (event.first || !entry.currentOpen) {
      createOrUpdateEntry();

      manager.open(target: this);
    } else if (event.last) {
      manager.close();
    } else {
      entry.actions(() {
        entry.rect = null;
        entry.offset = event.position;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return RenderTrigger(
      onPaint: onPaint,
      child: ZoTrigger(
        canRequestFocus: widget.requestTargetFocus,
        onTap: widget.type == ZoTriggerType.tap ? onTap : null,
        onActiveChanged: widget.type == ZoTriggerType.active
            ? onToggleChanged
            : null,
        onFocusChanged: widget.type == ZoTriggerType.focus
            ? onToggleChanged
            : null,
        onContextAction: widget.type == ZoTriggerType.contextAction
            ? onContextMenu
            : null,
        onMove: widget.type == ZoTriggerType.move ? onMove : null,
        child: TapRegion(groupId: entry.groupId, child: widget.child),
      ),
    );
  }
}

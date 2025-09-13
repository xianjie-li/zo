import "dart:async";
import "dart:math" as math;

import "package:flutter/material.dart";
import "package:zo/src/result/status_icon.dart";
import "package:zo/zo.dart";

part "entry.dart";

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
    this.popperEntry,
  });

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

  /// 直接传入已有 [ZoPopperEntry] 来显示气泡类型, 在以下常见中, 这会很有用:
  /// - 需要使用 [ZoPopperEntry] 提供但 [ZoPopper] 未向外暴露的高级功能更
  /// - 需要在多个 [ZoPopper] 复用一个气泡实例, 避免性能浪费
  final ZoPopperEntry? popperEntry;

  /// 打开或关闭时触发
  final void Function(bool open)? onOpenChanged;

  @override
  State<ZoPopper> createState() => _ZoPopperState();
}

class _ZoPopperState extends State<ZoPopper> {
  ZoPopperEntry? _popperEntry;

  ZoPopperEntry? get popperEntry => _popperEntry;

  set popperEntry(ZoPopperEntry? entry) {
    if (entry != _popperEntry) {
      if (_popperEntry != null) {
        _popperEntry!.hoverEvent.off(overlayHoverChanged);
      }
      entry!.hoverEvent.on(overlayHoverChanged);
    }

    _popperEntry = entry;
  }

  ZoPopperEntry get entry => popperEntry!;

  @override
  void initState() {
    super.initState();

    if (widget.popperEntry != null) {
      popperEntry = widget.popperEntry!;
    } else {
      createOrUpdateEntry();
    }
  }

  @override
  void didUpdateWidget(covariant ZoPopper oldWidget) {
    super.didUpdateWidget(oldWidget);

    createOrUpdateEntry();
  }

  @override
  void dispose() {
    // 非传入的 popperEntry 需要释放
    if (popperEntry != widget.popperEntry) {
      popperEntry!.dispose();
    }

    entry.hoverEvent.off(overlayHoverChanged);

    super.dispose();
  }

  void overlayHoverChanged(bool hovered) {
    if (hovered) {
      clearTriggerDelayTimer();
    } else {
      triggerDelayClose();
    }
  }

  void createOrUpdateEntry() {
    // 不对传入的 popperEntry 进行修改
    if (widget.popperEntry != null) return;

    if (popperEntry == null) {
      popperEntry = ZoPopperEntry(
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
      return;
    }

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
  }

  // 最后绘制的位置信息
  Rect? lastRect;

  void onPaint(RenderBox box) {
    // 这些事件由事件对象决定位置, 不需要目标位置
    if (widget.type == ZoTriggerType.contextAction ||
        widget.type == ZoTriggerType.move) {
      return;
    }

    lastRect = box.localToGlobal(Offset.zero) & box.size;

    entry.actions(() {
      entry.rect = lastRect;
    }, entry.currentOpen);
  }

  void onTap(ZoTriggerEvent event) {
    entry.actions(() {
      entry.offset = null;
      entry.rect = lastRect;
    });
    zoOverlay.open(entry);
  }

  void onToggleChanged(ZoTriggerToggleEvent event) {
    if (event.toggle) {
      clearTriggerDelayTimer();
      zoOverlay.open(entry);
    } else {
      // zoOverlay.close(entry);
      triggerDelayClose();
    }
  }

  void onContextMenu(ZoTriggerEvent event) {
    entry.actions(() {
      entry.rect = null;
      entry.offset = event.position;
    });
    zoOverlay.open(entry);
  }

  void onMove(ZoTriggerMoveEvent event) {
    // !entry.currentOpen 可避免快速移动到层上导致关闭
    if (event.first || !entry.currentOpen) {
      zoOverlay.open(entry);
    } else if (event.last) {
      zoOverlay.close(entry);
    } else {
      entry.actions(() {
        entry.rect = null;
        entry.offset = event.position;
      });
    }
  }

  Timer? delayCloseTimer;

  /// 延迟一段时间后关闭层, 如果延迟后层处于 hover 状态, 则取消关闭,
  /// 用于 active 场景下, 从目标移动到层上方时, 防止层关闭
  void triggerDelayClose() {
    clearTriggerDelayTimer();

    delayCloseTimer = Timer(const Duration(milliseconds: 100), () {
      if (entry.currentOpen && entry.hover) {
        return;
      }
      zoOverlay.close(entry);
      delayCloseTimer = null;
    });
  }

  void clearTriggerDelayTimer() {
    if (delayCloseTimer != null) {
      delayCloseTimer!.cancel();
      delayCloseTimer = null;
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

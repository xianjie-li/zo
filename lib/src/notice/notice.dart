import "dart:collection";

import "package:collection/collection.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:zo/src/result/status_icon.dart";
import "package:zo/zo.dart";

/// 消息显示位置
enum ZoNoticePosition {
  top,
  center,
  bottom,
  topLeft,
  topRight,
  bottomLeft,
  bottomRight,
}

/// 表示单条消息的配置项
class ZoNoticeEntry {
  const ZoNoticeEntry({
    this.title,
    this.content,
    this.actions,
    this.status,
    this.position = ZoNoticePosition.top,
    this.duration = const Duration(milliseconds: 1500),
    this.closeButton = false,
    this.barrier = false,
    this.interactive = true,
    this.maxWidth = 240,
    this.requestFocus = false,
    this.builder,
  });

  /// 消息的标题
  final Widget? title;

  /// 消息的主体内容
  final Widget? content;

  /// 右侧操作区内容
  final Widget? actions;

  /// 消息状态类型
  final ZoStatus? status;

  /// 显示位置
  final ZoNoticePosition position;

  /// 显示时间
  final Duration duration;

  /// 显示关闭按钮
  final bool closeButton;

  /// 是否显示遮罩
  final bool barrier;

  /// - 在用户按住或鼠标悬浮在消息上方时, 阻止自动关闭
  /// - 快速滑动时关闭消息
  final bool interactive;

  /// 最大宽度
  final double maxWidth;

  /// 是否需要请求焦点
  final bool requestFocus;

  /// 完成自定义消息样式
  final Widget Function(BuildContext context)? builder;
}

/// 进行应用内消息提醒, 支持指定各种消息位置, 样式和个性化配置
final zoNotice = ZoNotice();

var _instanceCount = 0;

/// 进行应用内消息提醒, 支持指定各种消息位置, 样式和个性化配置
///
/// 这是一个单例类, 应始终使用提供的 [zoNotice] 对象进行调用
class ZoNotice extends ChangeNotifier {
  ZoNotice() {
    assert(
      _instanceCount == 0,
      "Cannot create instances for ZoNotice, it should always be singleton, please use global zoNotice",
    );
    _instanceCount++;
  }

  /// 当前活动中的所有消息
  final List<ZoNoticeEntry> entries = [];

  /// 用于标记应该被删除的 entry, view 中通过此项确定是否要执行离场动画并删除项
  final HashSet<ZoNoticeEntry> _entryToRemove = HashSet();

  /// 将 entries 按位置分类后返回
  HashMap<ZoNoticePosition, List<ZoNoticeEntry>> get positionedEntries {
    final HashMap<ZoNoticePosition, List<ZoNoticeEntry>> map = HashMap();
    for (final entry in entries) {
      map[entry.position] ??= [];
      map[entry.position]!.add(entry);
    }
    return map;
  }

  /// 基础 api, 直接指定 [ZoNoticeEntry] 来发起消息提醒, 它拥有比上层 api 更高的可定制性
  ///
  /// 若传入的 entry 当前已在队列中, 则什么都不会发生
  ZoNoticeEntry notice(ZoNoticeEntry entry) {
    _ensureOverlaySetup();
    if (entries.contains(entry)) return entry;

    entries.add(entry);

    notifyListeners();

    return entry;
  }

  /// 关闭指定消息, immediate 为 true 时会跳过动画直接关闭
  void close(ZoNoticeEntry entry, [bool? immediate = false]) {
    _ensureOverlaySetup();
    if (!entries.contains(entry)) return;

    if (immediate!) {
      entries.remove(entry);
      _entryToRemove.remove(entry);
    } else {
      _entryToRemove.add(entry);
    }

    notifyListeners();
  }

  /// 立即清理所有消息
  void disposeAll() {
    entries.clear();
    _entryToRemove.clear();
    notifyListeners();
  }

  /// 便捷 api, 它是 [notice] 的简单包装
  ZoNoticeEntry tip(
    String message, {
    String? title,
    ZoStatus? status,
    ZoNoticePosition position = ZoNoticePosition.top,
  }) {
    final entry = ZoNoticeEntry(
      content: Text(message),
      title: title != null ? Text(title) : null,
      status: status,
      position: position,
    );

    return notice(entry);
  }

  /// 全局加载状态
  ZoNoticeEntry loading({
    String? message,
    bool barrier = true,
  }) {
    return notice(
      ZoNoticeEntry(
        duration: const Duration(days: 365),
        barrier: barrier,
        interactive: false,
        position: ZoNoticePosition.center,
        builder: (context) =>
            ZoProgress(text: message == null ? null : Text(message)),
      ),
    );
  }

  /// 确保 overlay 已插入并处于最上层
  void _ensureOverlaySetup() {
    if (_noticeOverlay.overlay == null || !_noticeOverlay.currentOpen) {
      zoOverlay.open(_noticeOverlay);
    }

    if (zoOverlay.overlays.last != _noticeOverlay) {
      zoOverlay.moveToTop(_noticeOverlay);
    }
  }

  @override
  // ignore: must_call_super
  void dispose() {
    // 防止销毁
    // super.dispose();
  }
}

/// 渲染消息使用的固定层
final _noticeOverlay = ZoOverlayEntry(
  alignment: Alignment.center,
  builder: (context) => const _NoticeView(),
  // tapAwayClosable: false,
  // escapeClosable: false,
  // requestFocus: false,
  alwaysOnTop: true,
  persistentInBatch: true,
  dismissMode: ZoOverlayDismissMode.close,
  duration: Duration.zero,
);

/// 消息显示的主体, 它负责在 [ZoOverlay] 中显示当前消息
class _NoticeView extends StatefulWidget {
  const _NoticeView({super.key});

  @override
  State<_NoticeView> createState() => _NoticeViewState();
}

class _NoticeViewState extends State<_NoticeView> {
  /// 用于消息组件之间对同方向的消息自动关闭动画的暂停和启用进行通知
  final countDownEvent =
      EventTrigger<({ZoNoticePosition position, bool toggle})>();

  @override
  void initState() {
    super.initState();
    zoNotice.addListener(noticeUpdate);
  }

  @override
  void dispose() {
    zoNotice.addListener(noticeUpdate);
    super.dispose();
  }

  bool barrier = false;

  void noticeUpdate() {
    setState(() {});
  }

  /// 构造指定方向的消息
  Widget? buildPosition(Alignment alignment, List<ZoNoticeEntry>? entries) {
    if (entries == null || entries.isEmpty) return null;

    final crossAxisAlignment = switch (alignment) {
      Alignment.bottomLeft || Alignment.topLeft => CrossAxisAlignment.start,
      Alignment.bottomRight || Alignment.topRight => CrossAxisAlignment.end,
      _ => CrossAxisAlignment.center,
    };

    return Align(
      key: ValueKey(alignment),
      alignment: alignment,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: crossAxisAlignment,
        children: entries.map((entry) {
          return ZoNoticeCard(
            key: ValueKey(entry),
            open: !zoNotice._entryToRemove.contains(entry),
            entry: entry,
            countDownEvent: countDownEvent,
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = context.zoStyle;
    final positionedEntries = zoNotice.positionedEntries;

    final hasBarrier =
        zoNotice.entries.firstWhereOrNull((z) {
          return z.barrier;
        }) !=
        null;

    return Stack(
      children: [
        ZoTransition(
          open: hasBarrier,
          type: ZoTransitionType.fade,
          appear: true,
          unmountOnExit: false,
          curve: _noticeOverlay.curve,
          duration: _noticeOverlay.duration,
          child: Container(
            color: context.zoStyle.barrierColor,
          ),
        ),
        Padding(
          padding: EdgeInsetsGeometry.all(style.space6),
          child: Stack(
            children: [
              ?buildPosition(
                Alignment.topLeft,
                positionedEntries[ZoNoticePosition.topLeft],
              ),
              ?buildPosition(
                Alignment.topCenter,
                positionedEntries[ZoNoticePosition.top],
              ),
              ?buildPosition(
                Alignment.topRight,
                positionedEntries[ZoNoticePosition.topRight],
              ),
              ?buildPosition(
                Alignment.bottomLeft,
                positionedEntries[ZoNoticePosition.bottomLeft],
              ),
              ?buildPosition(
                Alignment.bottomCenter,
                positionedEntries[ZoNoticePosition.bottom],
              ),
              ?buildPosition(
                Alignment.bottomRight,
                positionedEntries[ZoNoticePosition.bottomRight],
              ),
              ?buildPosition(
                Alignment.center,
                positionedEntries[ZoNoticePosition.center],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// 绘制单条卡片的 UI, 它接收 entry 并根据其配置绘制消息卡片, 并在需要进行关闭时进行通知
class ZoNoticeCard extends StatefulWidget {
  const ZoNoticeCard({
    super.key,
    required this.entry,
    this.open = true,
    required this.countDownEvent,
  });

  final bool open;

  /// 对应的 entry 配置
  final ZoNoticeEntry entry;

  /// 用于消息组件之间对同方向的消息自动关闭动画的暂停和启用进行通知
  final EventTrigger<({ZoNoticePosition position, bool toggle})> countDownEvent;

  @override
  State<ZoNoticeCard> createState() => _ZoNoticeCardState();
}

class _ZoNoticeCardState extends State<ZoNoticeCard> {
  /// 关闭进度动画控制
  AnimationController? controller;

  /// 关闭计时是否处于启用状态
  bool countDown = true;

  bool hover = false;

  @override
  initState() {
    super.initState();

    widget.countDownEvent.on(onCountDownTrigger);
  }

  @override
  dispose() {
    widget.countDownEvent.off(onCountDownTrigger);

    super.dispose();
  }

  Widget? buildCloseButton(ZoStyle style) {
    if (!widget.entry.closeButton) return null;
    return ZoButton(
      plain: true,
      size: ZoSize.small,
      icon: const Icon(
        Icons.close,
      ),
      onTap: onClose,
    );
  }

  void onClose([bool immediate = false]) {
    zoNotice.close(widget.entry, immediate);
  }

  /// 接收其他同方向组件的关闭计时开关事件并同步
  void onCountDownTrigger(({ZoNoticePosition position, bool toggle}) args) {
    if (args.position != widget.entry.position) return;
    args.toggle ? onStartCountDown(false) : onStopCountDown(false);
  }

  void onStartCountDown([bool emit = true]) {
    if (!widget.entry.interactive) return;
    if (controller == null || controller!.isAnimating || countDown) return;

    countDown = true;

    controller!.forward();

    if (emit) {
      widget.countDownEvent.emit((
        position: widget.entry.position,
        toggle: true,
      ));
    }
  }

  void onStopCountDown([bool emit = true]) {
    if (!widget.entry.interactive) return;
    if (controller == null || controller!.isCompleted || !countDown) return;

    countDown = false;

    controller!.stop();

    if (emit) {
      widget.countDownEvent.emit((
        position: widget.entry.position,
        toggle: false,
      ));
    }
  }

  void onPanEnd(DragEndDetails details) {
    if (!widget.entry.interactive) return;
    final xSpeed = details.velocity.pixelsPerSecond.dx.abs();
    final ySpeed = details.velocity.pixelsPerSecond.dy.abs();
    if (xSpeed > 1000 || ySpeed > 1000) {
      onClose();
    }
  }

  void onTapDown(TapDownDetails details) {
    if (hover || !countDown) return;
    onStopCountDown();
  }

  void onTapUp(TapUpDetails details) {
    if (hover || countDown) return;
    onStartCountDown();
  }

  void onTapCancel() {
    if (hover || countDown) return;
    onStartCountDown();
  }

  void onEnter(PointerEnterEvent event) {
    if (!countDown) return;
    hover = true;
    onStopCountDown();
  }

  void onExit(PointerExitEvent event) {
    if (countDown) return;
    hover = false;
    onStartCountDown();
  }

  void onStatusChange(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && !widget.open) {
      onClose(true);
    }
  }

  Widget buildProgressBar(ZoStyle style) {
    return ZoTransitionBase<double>(
      curve: Curves.linear,
      duration: widget.entry.duration,
      autoAlpha: false,
      onStatusChange: (status) {
        if (status == AnimationStatus.completed) {
          onClose();
        }
      },
      controllerRef: (value) => controller = value,
      animationBuilder: (animate) {
        return FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: animate.animation.value,
          child: animate.child,
        );
      },
      child: Container(
        height: 2,
        decoration: BoxDecoration(
          color: style.primaryColor.withAlpha(50),
          borderRadius: BorderRadius.circular(24),
        ),
      ),
    );
  }

  Widget defaultBuilder(ZoStyle style) {
    final iconNode = widget.entry.status == null
        ? null
        : ZoStatusIcon(status: widget.entry.status);

    var padding = EdgeInsets.all(style.space3);

    Widget? titleNode;

    var content = widget.entry.content;

    if (widget.entry.title != null) {
      titleNode = DefaultTextStyle.merge(
        style: TextStyle(
          color: style.titleTextColor,
          fontSize: style.fontSizeMD,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: style.space1,
          children: [
            ?iconNode,
            Expanded(child: widget.entry.title!),
            ?buildCloseButton(style),
          ],
        ),
      );
    }

    if (widget.entry.title == null &&
        (widget.entry.status != null || widget.entry.closeButton)) {
      // 调整纵向 padding, 防止按钮和 icon 把卡片撑得过大导致视觉上不舒适
      padding = EdgeInsets.symmetric(
        vertical: style.space2 + 2,
        horizontal: style.space2,
      );

      content = Row(
        mainAxisSize: MainAxisSize.min,
        spacing: style.space1,
        children: [
          ?iconNode,
          ?content,
          ?buildCloseButton(style),
        ],
      );
    }

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: style.outlineColor),
            color: style.surfaceContainerColor,
            borderRadius: BorderRadius.circular(style.borderRadius),
            boxShadow: style.brightness == Brightness.dark
                ? null
                : [style.shadow],
          ),
          constraints: BoxConstraints(maxWidth: widget.entry.maxWidth),
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: style.space2,
            children: [
              ?titleNode,
              ?content,
              ?widget.entry.actions,
            ],
          ),
        ),
        Positioned(
          bottom: 2,
          left: 10,
          right: 10,
          child: buildProgressBar(style),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = context.zoStyle;

    return MouseRegion(
      onEnter: onEnter,
      onExit: onExit,
      child: GestureDetector(
        onTapDown: onTapDown,
        onTapUp: onTapUp,
        onTapCancel: onTapCancel,
        onPanEnd: onPanEnd,
        child: ZoTransitionBase<double>(
          curve: Curves.easeOutBack,
          open: widget.open,
          appear: true,
          unmountOnExit: true,
          onStatusChange: onStatusChange,
          builder: (animate) {
            return SizeTransition(
              sizeFactor: animate.animation,
              fixedCrossAxisSizeFactor: 1,
              child: animate.child,
            );
          },
          child: Padding(
            // 纵向用于分割消息, 横向用于防止阴影被裁剪
            padding: EdgeInsetsGeometry.all(style.space2),
            child: widget.entry.builder == null
                ? defaultBuilder(style)
                : Stack(
                    children: [
                      widget.entry.builder!(context),

                      /// 仍然渲染一个一个隐藏的 ProgressBar, 因为我们的关闭依赖其完成
                      Positioned(
                        left: 0,
                        top: 0,
                        child: SizedBox(
                          width: 0,
                          height: 0,
                          child: buildProgressBar(style),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

import "dart:async";
import "dart:collection";
import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:collection/collection.dart";
import "package:zo/zo.dart";

part "overlay_entry.dart";
part "overlay_route.dart";
part "positioned.dart";
part "drag_handle.dart";

/// 动画包装器
typedef ZoOverlayAnimationWrap =
    Widget Function(Widget child, ZoOverlayEntry entry);

/// 控制层在通过内部 tapAway / escape / Navigator.pop 等行为触发关闭时, 应该销毁还是仅关闭层
enum ZoOverlayDismissMode {
  close, // 仅关闭弹层，保留资源
  dispose, // 销毁弹层，释放资源
}

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

/// ZoOverlayView 组件件发送的通知类型
enum _ViewTriggerType {
  /// 包含 barrier 的层显示或隐藏, 其他层应作为响应显示或隐藏自身的 barrier
  barrierChanged,
}

/// _ViewTriggerType 通知参数
typedef _ViewTriggerArgs =
    ({_ViewTriggerType type, _ZoOverlayViewState state, dynamic args});

/// 管理若干个 [ZoOverlayEntry], 它们是悬浮在常规 UI 之上的特殊层, 可用于实现 Modal, Drawer,
/// Popper 等弹层类组件, 它提供了实现着弹层类组件需要的绝大多数功能, 比如:
///
/// - 层管理
/// - 定位
/// - popper 定位, 防遮挡等
/// - 路由层, 可搭配原始路由 api 使用
/// - 遮罩
/// - 外部点击关闭和 esc 健关闭
/// - 可拖动
/// - 动画
/// - 弹出阻止
///
/// 连接到 Navigator: 使用前必须通过 connect 方法与 NavigatorState建立连接,
/// 所有层会在路由的 overlay 之上渲染
///
/// 层管理: [ZoOverlay] 主要职责是管理 [ZoOverlayEntry] 的添加, 删除, 销毁等,
/// 如果需要更改 [ZoOverlayEntry] 的状态, 通常是直接变更其提供的属性
///
/// 状态控制: 相比原始 [Overlay], [ZoOverlay] 能更细粒度的控制何时开启 / 关闭 / 销毁层,
/// 你可以在某个层暂时关闭, 并在稍后重新开启它而不会丢失状态, 这甚至能作用于路由层
final zoOverlay = ZoOverlay();

/// 管理若干个 [ZoOverlayEntry], 它们是悬浮在常规 UI 之上的特殊层, 比如 Modal, Drawer,
/// Popper 等
///
/// 很少需要自行创建实例, 而是使用通用全局实例 [zoOverlay]
class ZoOverlay {
  /// 当前所有层
  final List<ZoOverlayEntry> overlays = [];

  /// 当前 Overlay 要连接的 navigator, 所有层会在其 overlay 中显示, 并使用该导航实现
  /// routeOverlay
  GlobalKey<NavigatorState>? _navigatorKey;

  /// 原始 OverlayEntry, 与 overlays 一一对应
  final HashMap<ZoOverlayEntry, OverlayEntry> _originalOverlays = HashMap();

  /// 以 entry 为 key 存放延迟销毁计时器
  final HashMap<ZoOverlayEntry, Timer> _disposeTimers = HashMap();

  /// 以 entry 为 key 存放延迟关闭计时器
  final HashMap<ZoOverlayEntry, Timer> _closeTimers = HashMap();

  /// 一个空的 entry, 用于更准确的在 navigator.overlay 中排列我们自定义的层,
  /// 因为我们的层需要始终显示在默认层的上方, 但框架没有提供一中机制来遍历/对比它们,
  /// 所以需要一个参照层, 在通过 rearrange 同步前, 将参照层添加到最上方, 然后再插入我们自定义的层
  final OverlayEntry _emptyEntry = OverlayEntry(
    builder: (context) => const SizedBox.shrink(),
  );

  /// 用于 [ZoOverlayView] 组件之间发送特定的通知
  final _viewTrigger = EventTrigger<_ViewTriggerArgs>();

  /// 便捷获取当前 navigatorState
  NavigatorState get navigator {
    _assertConnected();
    return _navigatorKey!.currentState!;
  }

  /// 便捷获取路由 Overlay
  OverlayState get _navigatorOverlay => navigator.overlay!;

  /// 一个开关状态, 可控制 dispose 是否忽略关闭动画延迟立即完成
  bool _disposeImmediately = false;

  /// 强制 _mayDismissCheck 返回 true
  bool _forceDismiss = false;

  /// 若传入 entry 已在当前 entries 中, 则返回对应的 OverlayEntry, 否则创建一个新 OverlayEntry,
  /// 并将他插入到最顶部
  ({OverlayEntry entry, bool isNew}) _obtainOverlay(ZoOverlayEntry entry) {
    if (overlays.contains(entry)) {
      return (entry: _originalOverlays[entry]!, isNew: false);
    }

    assert(
      entry.overlay == null || entry.overlay == this,
      "OverlayEntry.overlay must be null or the same as this overlay",
    );

    final overlayEntry = OverlayEntry(
      // 我们会自行管理层什么时候绘制, 什么时候销毁
      maintainState: true,
      builder: (context) {
        return ZoOverlayView(entry: entry, overlay: this);
      },
    );

    overlays.add(entry);
    _originalOverlays[entry] = overlayEntry;
    entry.overlay = this;

    return (entry: overlayEntry, isNew: true);
  }

  /// 将当前 entries 与 navigator.overlay 同步
  void _syncOverlays() {
    _navigatorOverlay.insert(_emptyEntry);

    final list = overlays.map((i) {
      return _originalOverlays[i]!;
    });

    _navigatorOverlay.rearrange([_emptyEntry, ...list], below: _emptyEntry);

    _emptyEntry.remove();
  }

  /// 停止并销毁指定 entry 的延迟关闭计时器
  void _clearEntryTimers(ZoOverlayEntry entry) {
    _disposeTimers[entry]?.cancel();
    _disposeTimers.remove(entry);
    _closeTimers[entry]?.cancel();
    _closeTimers.remove(entry);
  }

  /// 检测指定 entry 是否有正在进行的延迟销毁操作
  bool isDelayDisposing(ZoOverlayEntry entry) {
    return _disposeTimers[entry]?.isActive ?? false;
  }

  /// 检测指定 entry 是否有正在进行的延迟关闭操作
  bool isDelayClosing(ZoOverlayEntry entry) {
    return _closeTimers[entry]?.isActive ?? false;
  }

  /// 防止层在不同的 overlay 中使用
  void _preventReuseEntry(ZoOverlayEntry entry) {
    assert(entry.overlay == null || entry.overlay == this);
  }

  /// 连接断言
  void _assertConnected() {
    assert(
      _navigatorKey != null,
      "NavigatorKey must not be null, please use connect() to connect to a Navigator",
    );
  }

  /// 检测指定 entry 的 mayDismiss / onDismiss, 返回是否应关闭
  bool _mayDismissCheck(ZoOverlayEntry entry) {
    final didDismiss = _forceDismiss ? _forceDismiss : entry._mayDismiss();

    entry._onDismiss(didDismiss, null);

    return didDismiss;
  }

  /// 将 NavigatorState 连接到当前 overlay 实例, 必须在执行其他 api 前先进行连接,
  /// 此方法可多次调用
  void connect(GlobalKey<NavigatorState> navigatorKey) {
    _navigatorKey ??= navigatorKey;

    if (_navigatorKey != null && _navigatorKey != navigatorKey) {
      _disposeImmediately = true;
      disposeAll();
      _disposeImmediately = false;
      _navigatorKey = navigatorKey;
    }
  }

  /// 关闭层, 层关闭后, 其状态仍会保留, 可以在稍后重新开启它
  void close(ZoOverlayEntry entry) {
    _assertConnected();

    if (isDelayDisposing(entry) || isDelayClosing(entry)) return;
    if (!entry._open) return;

    _preventReuseEntry(entry);

    if (!_mayDismissCheck(entry)) return;

    entry._open = false;

    final entryData = _obtainOverlay(entry);

    if (entryData.isNew) {
      _syncOverlays();
    }

    _onClose(entry);

    if (entry.exitAnimationDuration == null ||
        entry.exitAnimationDuration == Duration.zero) {
      return;
    }
    _closeTimers[entry] = Timer(entry.exitAnimationDuration!, () {
      _closeTimers.remove(entry);
    });
  }

  /// 开启层并将其其移动到顶部
  void open(ZoOverlayEntry entry) {
    _assertConnected();
    if (entry._open) return;
    _clearEntryTimers(entry);
    _preventReuseEntry(entry);

    entry._open = true;

    final entryData = _obtainOverlay(entry);

    if (overlays.last != entry) {
      moveToTop(entry);
    } else if (entryData.isNew) {
      _syncOverlays();
    }

    _onOpen(entry);
  }

  /// 完全移除指定的层
  void dispose(ZoOverlayEntry entry) {
    _assertConnected();
    if (!overlays.contains(entry)) return;
    if (isDelayDisposing(entry) && !_disposeImmediately) return;

    if (!_mayDismissCheck(entry)) return;

    // 移除 closeTimers
    _clearEntryTimers(entry);

    void doDispose() {
      if (!overlays.contains(entry)) return;

      overlays.remove(entry);

      final rmEntry = _originalOverlays.remove(entry);

      if (rmEntry != null) rmEntry.remove();

      entry.overlay = null;

      _clearEntryTimers(entry);
      _syncOverlays();

      _onDispose(entry);
    }

    if (entry.exitAnimationDuration == null ||
        entry.exitAnimationDuration == Duration.zero ||
        _disposeImmediately) {
      entry._open = false;
      doDispose();
      return;
    }

    entry._open = false;

    _disposeTimers[entry] = Timer(entry.exitAnimationDuration!, doDispose);
  }

  /// 将层移动到顶部
  ///
  /// 注: 只会改变其视觉位置, 路由栈顺序不会改变, 所以在执行返回等路由操作时, 仍然会以其打开的顺序进行关闭
  void moveToTop(ZoOverlayEntry entry) {
    _assertConnected();
    if (!overlays.contains(entry)) return;
    overlays.remove(entry);
    overlays.add(entry);
    _syncOverlays();
  }

  /// 将层移动到底部
  ///
  /// 注: 只会改变其视觉位置, 路由栈顺序不会改变, 所以在执行返回等路由操作时, 仍然会以其打开的顺序进行关闭
  void moveToBottom(ZoOverlayEntry entry) {
    _assertConnected();
    if (!overlays.contains(entry)) return;
    overlays.remove(entry);
    overlays.insert(0, entry);
    _syncOverlays();
  }

  /// 关闭所有层
  void closeAll() {
    _assertConnected();

    for (final element in overlays.reversed) {
      if (!_mayDismissCheck(element)) continue;
      close(element);
      _onClose(element);
    }
  }

  /// 开启所有层
  void openAll() {
    _assertConnected();

    for (final element in overlays) {
      // 对于正在关闭的层, openAll 不应该将它重新打开, 这基本上不符合预期
      if (isDelayDisposing(element) || element._open) continue;
      element._open = true;
      _onOpen(element);
    }
  }

  /// 移除所有层
  void disposeAll() {
    _assertConnected();

    for (final element in overlays.reversed) {
      if (!_mayDismissCheck(element)) continue;
      dispose(element);
    }
  }

  /// 临时跳过 mayDismiss 检测
  void skipDismissCheck(VoidCallback callback) {
    _forceDismiss = true;
    callback();
    _forceDismiss = false;
  }

  /// 每个层 open 时调用
  void _onOpen(ZoOverlayEntry entry) {
    _routeOpen(entry);
    entry.onStatusChanged?.call(ZoOverlayEntryStatus.open);
  }

  /// 每个层 close 时调用
  void _onClose(ZoOverlayEntry entry) {
    _routeClose(entry);
    entry.onStatusChanged?.call(ZoOverlayEntryStatus.close);
  }

  /// 每个层 dispose 时调用
  void _onDispose(ZoOverlayEntry entry) {
    _routeClose(entry);
    entry.onStatusChanged?.call(ZoOverlayEntryStatus.dispose);
  }

  /// 处理路由组件的 open
  void _routeOpen(ZoOverlayEntry entry) {
    if (!entry.route) return;

    final route = ZoOverlayRoute(
      onDispose: () {
        skipDismissCheck(() {
          if (entry.dismissMode == ZoOverlayDismissMode.close) {
            close(entry);
          } else {
            dispose(entry);
          }
        });
      },
      onPop: entry._onDismiss,
      mayPop: entry._mayDismiss,
    );

    entry._attachRoute = route;

    navigator.push(route);
  }

  /// 处理路由组件的 close
  void _routeClose(ZoOverlayEntry entry) {
    if (!entry.route || entry._attachRoute == null) return;

    final route = entry._attachRoute!;

    // 如果是当前路由, 使用 pop 关闭, 如果不是, 直接移除路由
    if (route.isCurrent) {
      navigator.pop();
    } else if (route.isActive) {
      navigator.removeRoute(route);
    }

    entry._attachRoute = null;
  }
}

/// ZoOverlay 视图层, 它在 navigator.overlay 中渲染 [ZoOverlayEntry], 并管理他们的更新,
/// 布局, 定位等
class ZoOverlayView extends StatefulWidget {
  const ZoOverlayView({super.key, required this.entry, required this.overlay});

  final ZoOverlayEntry entry;

  final ZoOverlay overlay;

  @override
  State<ZoOverlayView> createState() => _ZoOverlayViewState();
}

class _ZoOverlayViewState extends State<ZoOverlayView> {
  ZoOverlayEntry get entry => widget.entry;

  ZoOverlay get overlay => widget.overlay;

  FocusScopeNode focusScopeNode = FocusScopeNode();

  /// 最后一次的 open 状态
  bool? lastOpen;

  /// 设置为 true, 可在该次build临时禁用 barrier
  bool tempDisableBarrierAnimation = false;

  @override
  void initState() {
    super.initState();

    widget.entry.addListener(update);
    widget.overlay._viewTrigger.on(onViewTrigger);

    lastOpen = entry._open;

    focus();
  }

  @override
  void didUpdateWidget(ZoOverlayView oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.entry != widget.entry) {
      oldWidget.entry.removeListener(update);
      widget.entry.addListener(update);

      widget.overlay._viewTrigger.off(onViewTrigger);
      widget.overlay._viewTrigger.on(onViewTrigger);
    }
  }

  @override
  void dispose() {
    widget.entry.removeListener(update);
    widget.overlay._viewTrigger.off(onViewTrigger);

    super.dispose();
  }

  /// 在 entry 变更后更新组件
  void update() {
    if (lastOpen != entry._open) {
      lastOpen = entry._open;
      onOpenChanged();
    }
    setState(() {});
  }

  /// 默认动画实现
  Widget defaultAnimationWrap(Widget child, ZoOverlayEntry entry) {
    return ZoTransition(
      open: entry._open,
      type: entry.transitionType ?? ZoTransitionType.fade,

      /// 交由 overlay 管理
      unmountOnExit: false,
      child: child,
    );
  }

  /// 请求获取焦点
  void focus() {
    if (!entry.requestFocus || !entry._open) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      focusScopeNode.requestFocus();
    });
  }

  /// 接收来自其他 OverlayView 组件的通知
  void onViewTrigger(_ViewTriggerArgs args) {
    if (args.state == this) return;

    // 存在 barrier 变更, 更新状态, buildBarrier 会自动决定是否要显示 barrier
    if (args.type == _ViewTriggerType.barrierChanged &&
        entry.barrier &&
        entry._open) {
      tempDisableBarrierAnimation = true;
      setState(() {});
    }
  }

  /// open状态变更
  void onOpenChanged() {
    focus();

    // 通知其他包含 barrier 更新 barrier 状态
    if (!entry._open && entry.barrier) {
      overlay._viewTrigger.emit((
        type: _ViewTriggerType.barrierChanged,
        state: this,
        args: null,
        // ignore: require_trailing_commas
      ));
    }
  }

  /// 点击区域外关闭
  void onTapOutside(PointerDownEvent event) {
    if (!entry.tapAwayClosable || !entry._open) return;
    if (entry.lastOpenTime != null) {
      // 防止快速点击导致误关闭
      if (DateTime.now().difference(entry.lastOpenTime!).inMilliseconds < 150) {
        return;
      }
    }

    // 只在当前项是最上方的项时触发
    final lastClosable = overlay.overlays.lastWhereOrNull(
      (i) => i._open && i.tapAwayClosable,
    );

    if (lastClosable != entry) return;

    if (entry.dismissMode == ZoOverlayDismissMode.dispose) {
      overlay.dispose(entry);
    } else {
      overlay.close(entry);
    }
  }

  /// 按键按下
  KeyEventResult onKeyEvent(FocusNode node, KeyEvent event) {
    if (!entry._open || !entry.escapeClosable) return KeyEventResult.ignored;

    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      if (entry.dismissMode == ZoOverlayDismissMode.dispose) {
        overlay.dispose(entry);
      } else {
        overlay.close(entry);
      }

      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// 构造 barrier
  Widget? buildBarrier() {
    if (!entry.barrier) return null;

    // 最后一个启用 barrier 的层
    final lastBarrierOverlay = overlay.overlays.lastWhereOrNull(
      (i) => i._open && i.barrier,
    );

    if (lastBarrierOverlay != entry) return null;

    final disableAnimation = tempDisableBarrierAnimation;
    tempDisableBarrierAnimation = false;

    return ZoTransition(
      open: entry._open,
      type: ZoTransitionType.fade,
      appear: !disableAnimation,
      unmountOnExit: false,
      child: ModalBarrier(
        // 仅用于ui, 点击关闭通过上面的 TapRegion 统一添加
        dismissible: false,
        color: context.zoStyle.barrierColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (entry.animationWrap == null) {
      child = defaultAnimationWrap(widget.entry.builder(context), entry);
    } else {
      child = entry.animationWrap!(widget.entry.builder(context), entry);
    }

    /// 添加外部点击关闭
    if (entry.tapAwayClosable) {
      child = TapRegion(
        enabled: entry._open,
        onTapOutside: onTapOutside,
        child: child,
      );
    }

    child = FocusScope(
      node: focusScopeNode,
      canRequestFocus: entry.requestFocus && entry._open,
      onKeyEvent: onKeyEvent,
      descendantsAreFocusable: true,
      descendantsAreTraversable: true,
      child: child,
    );

    final barrier = buildBarrier();

    return Visibility(
      visible:
          entry._open ||
          overlay.isDelayClosing(entry) ||
          overlay.isDelayDisposing(entry),
      maintainState: true,
      maintainAnimation: true,
      child: Stack(
        children: [
          if (barrier != null) barrier,
          ZoOverlayPositioned(entry: widget.entry, child: child),
        ],
      ),
    );
  }
}

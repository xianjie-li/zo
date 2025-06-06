import "dart:async";
import "dart:collection";
import "dart:math" as math;

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:collection/collection.dart";
import "package:zo/zo.dart";

part "package:zo/src/overlay/common.dart";
part "package:zo/src/overlay/overlay_entry.dart";
part "package:zo/src/overlay/overlay_route.dart";
part "package:zo/src/overlay/positioned.dart";

/// 管理若干个 [ZoOverlayEntry], 它们是悬浮在常规 UI 之上的特殊层, 可用于实现 Modal, Drawer,
/// Popper 等弹层类组件, 它提供了实现弹层类组件需要的绝大多数功能, 比如:
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
/// 使用前必须将 ZoOverlayProvider 挂载到 widget 树尽量上方的位置, 并为其传入 navigatorKey
///
/// 层管理: [ZoOverlay] 主要职责是管理 [ZoOverlayEntry] 的添加, 删除, 销毁等,
/// 如果需要更改 [ZoOverlayEntry] 的状态, 通常是直接变更其提供的属性
///
/// 状态控制: 相比原始 [Overlay], [ZoOverlay] 能更细粒度的控制何时开启 / 关闭 / 销毁层,
/// 你可以在某个层暂时关闭, 并在稍后重新开启它而不会丢失状态, 这甚至能作用于路由层
final zoOverlay = ZoOverlay();

/// 动画包装器
typedef ZoOverlayAnimationWrap =
    Widget Function(Widget child, ZoOverlayEntry entry);

/// ZoOverlayView 组件件发送的通知类型
enum _ViewTriggerType {
  /// 包含 barrier 的层显示或隐藏, 其他层应作为响应显示或隐藏自身的 barrier
  barrierChanged,
}

/// _ViewTriggerType 通知参数
typedef _ViewTriggerArgs = ({
  _ViewTriggerType type,
  _ZoOverlayViewState state,
  dynamic args,
});

var _instanceCount = 0;

/// 管理若干个 [ZoOverlayEntry], 它们是悬浮在常规 UI 之上的特殊层, 比如 Modal, Drawer,
/// Popper 等
///
/// 不需要自行创建实例, 而是始终使用全局实例 [zoOverlay]
class ZoOverlay {
  ZoOverlay() {
    assert(
      _instanceCount == 0,
      "Cannot create instances for ZoOverlay, it should always be singleton, please use global zoOverlay",
    );
    _instanceCount++;
  }

  /// 当前所有层
  final List<ZoOverlayEntry> overlays = [];

  /// 当前用于处理路由层的 navigatorState
  NavigatorState get navigator {
    _assertConnected();
    return _navigatorKey!.currentState!;
  }

  /// 用于绘制内容的原始 [Overlay] 对象
  OverlayState get overlay {
    _assertConnected();
    return _overlayKey!.currentState!;
  }

  /// 原始 OverlayEntry, 与 overlays 一一对应
  final HashMap<ZoOverlayEntry, OverlayEntry> _originalOverlays = HashMap();

  /// 用于路由层进行导航, 由 connect 设置
  GlobalKey<NavigatorState>? _navigatorKey;

  /// 当前显示内容的 Overlay 对象
  GlobalKey<OverlayState>? _overlayKey;

  /// 以 entry 为 key 存放延迟销毁计时器
  final HashMap<ZoOverlayEntry, Timer> _disposeTimers = HashMap();

  /// 以 entry 为 key 存放延迟关闭计时器
  final HashMap<ZoOverlayEntry, Timer> _closeTimers = HashMap();

  /// 一个空的 entry, 用于更准确的在 overlay 中排列我们自定义的层,
  /// 因为我们的层需要始终显示在默认层的上方, 但框架没有提供一中机制来遍历/对比它们,
  /// 所以需要一个参照层, 在通过 rearrange 同步前, 将参照层添加到最上方, 然后再插入我们自定义的层
  final OverlayEntry _emptyEntry = OverlayEntry(
    builder: (context) => const SizedBox.shrink(),
  );

  /// 用于 [ZoOverlayView] 组件之间发送特定的通知
  final _viewTrigger = EventTrigger<_ViewTriggerArgs>();

  /// 禁用所有层的 tapAwayClosable, 在某些场景很有用, 比如当前层通过 onDismiss 弹出关闭了确认 Modal,
  /// 可以临时通过此项禁用范围外点击关闭来避免错误触发
  bool disableAllTapAwayClosable = false;

  /// 禁用所有层的 escapeClosable
  bool disableAllEscapeClosable = false;

  /// 记录最后触发 tapAway 的时间, 用于防止单词点击一次性关闭所有层
  DateTime? _lastTapAwayTime;

  /// 一个开关状态, 可控制 dispose 是否忽略关闭动画延迟立即完成
  bool _disposeImmediately = false;

  /// 强制 _mayDismissCheck 返回 true
  bool _forceDismiss = false;

  /// 检测指定 entry 是否有正在进行的延迟销毁操作
  bool isDelayDisposing(ZoOverlayEntry entry) {
    return _disposeTimers[entry]?.isActive ?? false;
  }

  /// 检测指定 entry 是否有正在进行的延迟关闭操作
  bool isDelayClosing(ZoOverlayEntry entry) {
    return _closeTimers[entry]?.isActive ?? false;
  }

  /// 判断指定层是否是 open , 并且未处于 `关闭中` 状态
  bool isActive(ZoOverlayEntry entry) {
    return entry.currentOpen &&
        !isDelayClosing(entry) &&
        !isDelayDisposing(entry);
  }

  /// 连接 navigatorKey / overlayKey, 必须在执行其他 api 前先进行连接,
  /// 此方法可多次调用
  void connect(
    GlobalKey<NavigatorState> navigatorKey,
    GlobalKey<OverlayState> overlayKey,
  ) {
    _navigatorKey ??= navigatorKey;
    _overlayKey ??= overlayKey;

    final navigatorChanged = _navigatorKey != navigatorKey;

    final overlayChanged = _overlayKey != overlayKey;

    if (navigatorChanged || overlayChanged) {
      _disposeImmediately = true;
      disposeAll();
      _disposeImmediately = false;
      _navigatorKey = navigatorKey;
      _overlayKey = overlayKey;
    }
  }

  /// 开启层并将其其移动到顶部
  void open(ZoOverlayEntry entry) {
    _assertConnected();
    if (entry.currentOpen) return;
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

  /// 关闭层, 层关闭后, 其状态仍会保留, 可以在稍后重新开启它
  void close(ZoOverlayEntry entry) {
    _assertConnected();

    if (!isActive(entry)) return;

    // 移除 closeTimers
    _clearEntryTimers(entry);

    _preventReuseEntry(entry);

    if (!_mayDismissCheck(entry)) return;

    entry._open = false;

    final entryData = _obtainOverlay(entry);

    if (entryData.isNew) {
      _syncOverlays();
    }

    _onClose(entry);

    if (entry.duration == Duration.zero) {
      return;
    }
    _closeTimers[entry] = Timer(entry.duration, () {
      _closeTimers.remove(entry);
      entry.delayClosed();
    });
  }

  /// 完全移除指定的层, 被销毁的层不能被再次使用
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

      _clearEntryTimers(entry);
      _syncOverlays();

      entry.delayClosed();
      _onDispose(entry);
    }

    if (entry.duration == Duration.zero || _disposeImmediately) {
      entry._open = false;
      entry.openChanged(false);
      doDispose();
      return;
    }

    entry._open = false;
    entry.openChanged(false);

    _disposeTimers[entry] = Timer(entry.duration, doDispose);
  }

  /// 将层移动到顶部
  ///
  /// 注: 对于路由层, 只会改变其视觉位置, 路由栈顺序不会改变, 所以在执行返回等路由操作时, 仍然会以其打开的顺序进行关闭
  void moveToTop(ZoOverlayEntry entry) {
    _assertConnected();
    if (!overlays.contains(entry) || overlays.lastOrNull == entry) return;

    overlays.remove(entry);

    if (entry.alwaysOnTop) {
      overlays.add(entry);
    } else {
      overlays.insert(_getEndIndex(), entry);
    }

    _syncOverlays();
  }

  /// 将层移动到底部
  ///
  /// 注: 对于路由层, 只会改变其视觉位置, 路由栈顺序不会改变, 所以在执行返回等路由操作时, 仍然会以其打开的顺序进行关闭
  void moveToBottom(ZoOverlayEntry entry) {
    _assertConnected();
    if (!overlays.contains(entry) || overlays.firstOrNull == entry) return;
    if (entry.alwaysOnTop) return;
    overlays.remove(entry);
    overlays.insert(0, entry);
    _syncOverlays();
  }

  /// 关闭所有层
  void closeAll() {
    _assertConnected();

    // 转为list是为了反正遍历时变更导致报错
    for (final element in overlays.reversed.toList()) {
      if (!_mayDismissCheck(element) || element.persistentInBatch) continue;
      close(element);
      _onClose(element);
    }
  }

  /// 开启所有层
  void openAll() {
    _assertConnected();

    for (final element in overlays) {
      // 对于正在关闭的层, openAll 不应该将它重新打开, 这不符合预期
      if (isDelayDisposing(element) || element.currentOpen) continue;
      element._open = true;
      _onOpen(element);
    }
  }

  /// 移除所有层
  void disposeAll() {
    _assertConnected();

    // 转为list是为了反正遍历时变更导致报错
    for (final element in overlays.reversed.toList()) {
      if (!_mayDismissCheck(element) || element.persistentInBatch) continue;
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
    entry.openChanged(true);
  }

  /// 每个层 close 时调用
  void _onClose(ZoOverlayEntry entry) {
    _routeClose(entry, false);
    entry.openChanged(false);
  }

  /// 每个层 dispose 时调用
  void _onDispose(ZoOverlayEntry entry) {
    if (entry.route) {
      _routeClose(entry, true);
    } else {
      entry._disposeByParent = true;
      entry.dispose();
      entry._disposeByParent = false;
    }
  }

  /// 处理路由组件的 open
  void _routeOpen(ZoOverlayEntry entry) {
    if (!entry.route) return;

    final route = ZoOverlayRoute(
      onDispose: () {
        skipDismissCheck(() {
          if (!entry.currentOpen) return;
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
  void _routeClose(ZoOverlayEntry entry, bool isDispose) {
    if (!entry.route || entry._attachRoute == null) return;

    final route = entry._attachRoute!;

    // 如果是当前路由, 使用 pop 关闭, 如果不是, 直接移除路由
    if (route.isCurrent) {
      navigator.pop();
    } else if (route.isActive) {
      navigator.removeRoute(route);
    }

    if (isDispose) {
      entry._disposeByParent = true;
      entry.dispose();
      entry._disposeByParent = false;
    } else {
      entry._attachRoute = null;
    }
  }

  /// 防止层在不同的 overlay 中使用
  void _preventReuseEntry(ZoOverlayEntry entry) {
    assert(entry.overlay == null || entry.overlay == this);
  }

  /// 连接断言
  void _assertConnected() {
    assert(
      _navigatorKey != null,
      "navigatorKey & overlayKey must not be null, please make sure ZoOverlayProvider has mounted in widget tree",
    );
  }

  /// 检测指定 entry 的 mayDismiss / onDismiss, 返回是否应关闭
  bool _mayDismissCheck(ZoOverlayEntry entry) {
    final didDismiss = _forceDismiss ? _forceDismiss : entry._mayDismiss();

    entry._onDismiss(didDismiss, null);

    return didDismiss;
  }

  /// 若传入 entry 已在当前 entries 中, 则返回对应的 OverlayEntry, 否则创建一个新 OverlayEntry,
  /// 并将他插入到最顶部
  ({OverlayEntry entry, bool isNew}) _obtainOverlay(ZoOverlayEntry entry) {
    if (overlays.contains(entry)) {
      return (entry: _originalOverlays[entry]!, isNew: false);
    }
    // _navigatorOverlay.context

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

    if (entry.alwaysOnTop) {
      overlays.add(entry);
    } else {
      overlays.insert(_getEndIndex(), entry);
    }

    _originalOverlays[entry] = overlayEntry;
    entry.overlay = this;

    return (entry: overlayEntry, isNew: true);
  }

  /// 获取 overlays 末端用于插入的索引, 该索引排除了 alwaysOnTop 的项
  int _getEndIndex() {
    var onTopCount = 0;
    for (final o in overlays.reversed) {
      if (o.alwaysOnTop) {
        onTopCount++;
      } else {
        break;
      }
    }
    return overlays.length - onTopCount;
  }

  /// 将当前 entries 与 navigator.overlay 同步
  void _syncOverlays() {
    overlay.insert(_emptyEntry);

    final list = overlays.map((i) {
      return _originalOverlays[i]!;
    });

    overlay.rearrange([_emptyEntry, ...list], below: _emptyEntry);

    _emptyEntry.remove();
  }

  /// 停止并销毁指定 entry 的延迟关闭计时器
  void _clearEntryTimers(ZoOverlayEntry entry) {
    _disposeTimers[entry]?.cancel();
    _disposeTimers.remove(entry);
    _closeTimers[entry]?.cancel();
    _closeTimers.remove(entry);
  }
}

/// 提供 [ZoOverlay] 需要的必要配置, 用户需提供 navigatorKey, 内部会将其用于实现路由层
///
/// 放置的理想位置是 [MaterialApp] / [WidgetsApp] 的 builder 内尽量外层的位置
class ZoOverlayProvider extends StatefulWidget {
  const ZoOverlayProvider({
    super.key,
    required this.navigatorKey,
    required this.child,
  });

  final GlobalKey<NavigatorState> navigatorKey;

  final Widget child;

  @override
  State<ZoOverlayProvider> createState() => _ZoOverlayProviderState();
}

class _ZoOverlayProviderState extends State<ZoOverlayProvider> {
  final GlobalKey<OverlayState> overlayKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    zoOverlay.connect(widget.navigatorKey, overlayKey);
  }

  @override
  void didUpdateWidget(covariant ZoOverlayProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    zoOverlay.connect(widget.navigatorKey, overlayKey);
  }

  @override
  Widget build(BuildContext context) {
    return Overlay(
      key: overlayKey,
      initialEntries: [
        OverlayEntry(
          builder: (context) => widget.child,
        ),
      ],
    );
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

  OverlayPositionedRenderObject? positionedRenderObject;

  /// 记录前一个 barrier 状态, 用于防止在某些场景下 barrier 在没有动画的情况下直接关闭
  late bool lastBarrier;

  /// 记录手动拖拽移动的距离
  Offset? manualPosition;

  /// 拖动时用于计算边界阻尼的距离
  final rubberDistance = 50.0;

  /// 在拖动结束后标记是否需要延迟到关闭动画结束后重置拖动位置
  var _needResetDragDistance = false;

  /// 记录拖拽开始时的层位置
  Rect? _overlayDragStartRect;

  /// 未拖拽到关闭位置时, 还原动画的取消函数
  VoidCallback? _dragEndResetClear;

  @override
  void initState() {
    super.initState();

    widget.entry.addListener(update);
    widget.overlay._viewTrigger.on(onViewTrigger);
    entry.openChangedEvent.on(onOpenChanged);
    entry.delayClosedEvent.on(onDelayClosed);

    lastBarrier = entry.barrier;

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

      entry.openChangedEvent.off(onOpenChanged);
      entry.openChangedEvent.on(onOpenChanged);

      entry.delayClosedEvent.off(onDelayClosed);
      entry.delayClosedEvent.on(onDelayClosed);
    }

    lastBarrier = oldWidget.entry.barrier;
  }

  @override
  void dispose() {
    widget.entry.removeListener(update);
    widget.overlay._viewTrigger.off(onViewTrigger);
    entry.openChangedEvent.off(onOpenChanged);
    entry.delayClosedEvent.off(onDelayClosed);

    super.dispose();
  }

  /// 默认动画实现
  Widget defaultAnimationWrap(Widget child, ZoOverlayEntry entry) {
    if (entry.duration == Duration.zero) return child;

    return ZoTransition(
      open: entry.currentOpen,
      type: entry.transitionType ?? ZoTransitionType.fade,
      duration: entry.duration,
      curve: entry.curve,

      /// 交由 overlay 管理
      unmountOnExit: false,
      child: child,
    );
  }

  /// 请求获取焦点
  void focus() {
    if (!entry.requestFocus || !entry.currentOpen) return;
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
        entry.currentOpen) {
      setState(() {});
    }
  }

  /// 在 entry 变更后更新组件
  void update() {
    setState(() {});
  }

  /// open状态变更
  void onOpenChanged(bool open) {
    focus();

    if (_dragEndResetClear != null) {
      _dragEndResetClear!();
      _dragEndResetClear = null;
    }

    emitBarrierChanged();
  }

  /// 延迟关闭完成后也需要更新组件
  void onDelayClosed() {
    emitBarrierChanged();

    if (_needResetDragDistance && positionedRenderObject != null) {
      positionedRenderObject!._manualPosition = null;
    }
  }

  /// 在当前 barrier 状态变更时, 通知其他包含 barrier 更新 barrier 状态
  void emitBarrierChanged() {
    if (!entry.currentOpen && entry.barrier) {
      overlay._viewTrigger.emit((
        type: _ViewTriggerType.barrierChanged,
        state: this,
        args: null,
      ));
    }
  }

  /// 点击区域外关闭
  void onTapOutside(PointerDownEvent event) {
    if (!entry.tapAwayClosable ||
        !overlay.isActive(entry) ||
        overlay.disableAllTapAwayClosable) {
      return;
    }

    final now = DateTime.now();

    if (entry.lastOpenTime != null) {
      // 防止快速点击导致误关闭
      if (now.difference(entry.lastOpenTime!).inMilliseconds < 150) {
        return;
      }
    }

    // 只在当前项是最上方的项时触发
    final lastClosable = overlay.overlays.lastWhereOrNull(
      (i) => overlay.isActive(i) && i.tapAwayClosable,
    );

    if (lastClosable != entry) return;

    /// 如果触发了 tapAway 需要在短暂延迟内阻止其他 tapAway
    /// 上面的 lastClosable 依然要保留, 因为 onTapOutside 的触发顺序可能和我们的层顺序不一致
    if (overlay._lastTapAwayTime != null &&
        now.difference(overlay._lastTapAwayTime!).inMilliseconds < 80) {
      return;
    }

    overlay._lastTapAwayTime = now;

    if (entry.dismissMode == ZoOverlayDismissMode.dispose) {
      overlay.dispose(entry);
    } else {
      overlay.close(entry);
    }
  }

  /// 按键按下
  KeyEventResult onKeyEvent(FocusNode node, KeyEvent event) {
    if (!entry.currentOpen ||
        !entry.escapeClosable ||
        overlay.disableAllEscapeClosable) {
      return KeyEventResult.ignored;
    }

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

  /// 拖动实现
  bool onDrag(ZoDragTriggerEvent event) {
    final obj = positionedRenderObject;

    // 为初始化或方向布局
    if (obj == null || entry.direction != null) return false;

    final overlayRect = obj.overlayRect;
    final containerRect = obj.containerRect;

    // 未完成过绘制
    if (overlayRect == null || containerRect == null) return false;

    if (!event.first && manualPosition == null) {
      event.cancel();
      manualPosition = null;
      _overlayDragStartRect = null;
      return true;
    }

    if (event.first) {
      // 交互位置相对于层左上角的位置
      final relative = event.offset - overlayRect.topLeft;
      manualPosition = event.offset - relative;
      _overlayDragStartRect = overlayRect;
      _needResetDragDistance = false;

      obj.manualPosition = manualPosition;

      return true;
    }

    final next = manualPosition! + event.delta;

    final nextRect = Rect.fromLTWH(
      next.dx,
      next.dy,
      overlayRect.width,
      overlayRect.height,
    );

    var xRubber = 1.0;
    var yRubber = 1.0;

    final boundData = entry.getDragBound(containerRect, overlayRect);

    if (boundData != null) {
      if (boundData.rubber) {
        if (next.dx < boundData.bound.left) {
          xRubber = getRubber(-next.dx);
        } else if (nextRect.right > boundData.bound.right) {
          xRubber = getRubber(nextRect.right - boundData.bound.right);
        }

        if (next.dy < boundData.bound.top) {
          yRubber = getRubber(-next.dy);
        } else if (nextRect.bottom > boundData.bound.bottom) {
          yRubber = getRubber(nextRect.bottom - boundData.bound.bottom);
        }
      }

      final hasRubber = boundData.rubber && (xRubber != 0 || yRubber != 0);

      if (hasRubber) {
        manualPosition = Offset(
          manualPosition!.dx + xRubber * event.delta.dx,
          manualPosition!.dy + yRubber * event.delta.dy,
        );
      } else {
        manualPosition = next;
      }

      // 非 rubber 或结束时, 将层限制到 bound 内
      if ((event.last && hasRubber) || !hasRubber) {
        final x = manualPosition!.dx.clamp(
          boundData.bound.left,
          boundData.bound.right - overlayRect.width,
        );

        final y = manualPosition!.dy.clamp(
          boundData.bound.top,
          boundData.bound.bottom - overlayRect.height,
        );

        manualPosition = Offset(x, y);
      }
    } else {
      manualPosition = next;
    }

    final tempManualPosition = manualPosition;

    zoAnimationKit.tickerCaller(this, () {
      if (!mounted) return;
      obj.manualPosition = tempManualPosition;
    });

    if (event.last) {
      final endData = entry.onDragEnd(
        ZoOverlayDragEndData(
          containerRect: containerRect,
          overlayRect: overlayRect,
          overlayStartRect: _overlayDragStartRect!,
          event: event,
          position: manualPosition!,
        ),
      );

      if (endData != null) {
        if (endData) {
          animationToPosition(manualPosition!, _overlayDragStartRect!.topLeft);
        } else {
          _needResetDragDistance = true;
        }
      }

      manualPosition = null;
      _overlayDragStartRect = null;
    }

    return true;
  }

  /// 将层通过动画移动的指定位置
  void animationToPosition(Offset startOffset, Offset endOffset) {
    _dragEndResetClear = zoAnimationKit.animation(
      tween: Tween(begin: startOffset, end: endOffset),
      onAnimation: (value) {
        if (!mounted || positionedRenderObject == null) return;
        positionedRenderObject!.manualPosition = value.value;
      },
    );
  }

  /// 将根据指定的超出距离 overDistance 和 rubberDistance 配置, 获取阻尼值
  double getRubber(double overDistance) {
    // 保持 0.1 的最小阻力值, 能使拖动不那么生硬
    return (1 - overDistance / rubberDistance).clamp(0.1, 1);
  }

  /// 构造 barrier
  Widget? buildBarrier(bool visible) {
    if (!entry.barrier) return null;

    /// 所有显示正在显示 barrier 的层
    final List<ZoOverlayEntry> barrierList = [];

    // 最后一个启用 barrier 的层
    for (final i in overlay.overlays) {
      final barrierShow = i.barrier && i.currentOpen;

      if (barrierShow) {
        barrierList.add(i);
      }
    }

    // barrier 数大于1时, 仅最后一个层显示遮罩
    if (barrierList.length > 1 && barrierList.lastOrNull != entry) return null;

    return Positioned.fill(
      child: ZoTransition(
        open: entry.currentOpen,
        type: ZoTransitionType.fade,
        appear: true,
        unmountOnExit: true,
        curve: entry.curve,
        duration: entry.duration,
        child: Container(
          color: context.zoStyle.barrierColor,
        ),
      ),
    );
  }

  void renderObjectRef(OverlayPositionedRenderObject? obj) {
    positionedRenderObject = obj;
  }

  @override
  Widget build(BuildContext context) {
    Widget child;

    if (entry.animationWrap == null) {
      child = defaultAnimationWrap(widget.entry.overlayBuilder(context), entry);
    } else {
      child = entry.animationWrap!(widget.entry.overlayBuilder(context), entry);
    }

    final isActive = overlay.isActive(entry);

    /// 添加外部点击关闭
    child = TapRegion(
      enabled: isActive && entry.tapAwayClosable,
      onTapOutside: onTapOutside,
      child: child,
    );

    child = FocusScope(
      node: focusScopeNode,
      canRequestFocus: isActive && entry.requestFocus,
      onKeyEvent: onKeyEvent,
      descendantsAreFocusable: true,
      descendantsAreTraversable: true,
      child: child,
    );

    child = DefaultTextStyle(
      style: Theme.of(context).textTheme.bodyMedium!,
      child: child,
    );

    // 监听自己派发的拖动事件, 实现拖动行为
    child = NotificationListener<ZoDragTriggerEvent>(
      onNotification: onDrag,
      child: child,
    );

    final visible =
        entry.currentOpen ||
        overlay.isDelayClosing(entry) ||
        overlay.isDelayDisposing(entry);

    final barrier = buildBarrier(visible);

    return Visibility(
      visible: visible,
      maintainState: true,
      maintainAnimation: true,
      child: Stack(
        children: [
          if (barrier != null) barrier,
          ZoOverlayPositioned(
            entry: widget.entry,
            renderObjectRef: renderObjectRef,
            child: child,
          ),
        ],
      ),
    );
  }
}

/// 添加 PositionController 并向外暴露, 通过他获取容器尺寸, 层位置, 设置当前位置
/// 新增 DragHandle 负责为子级派发拖动事件
/// view 监听冒泡事件, 通过 PositionController 实施拖动
/// 禁用drag的场景: popper / drawer
/// 拖动关闭支持: 各实现自行添加drag并处理拖动关闭逻辑

part of "package:zo/src/overlay/overlay.dart";

/// 表示界面中显示的单个 overlay 层, 每个 entry 只能被插入到一个 [ZoOverlay],
/// 在插入到 [ZoOverlay] 后, 通过 [offset] / [rect] / [alignment] 等等属性可以直接调整 entry
///
/// 定位目标: 定位目标表现为一个矩形区域或一个点, 由 offset / rect / alignment 之一指定,
/// 同时传入多个时, 按  offset > rect > alignment 的优先级获取
///
/// 路由层: 通过 [route] 启用, 它会在 open 时向路由栈 push 一个新的路由, 用户可通过 Navigator.pop()
/// 等路由 api 来关闭路由层
///
/// ZoOverlayEntry 本身是一个 [Listenable] 对象, 会在其大部分关键属性变更时进行通知
class ZoOverlayEntry extends ChangeNotifier {
  ZoOverlayEntry({
    WidgetBuilder? builder,
    Offset? offset,
    Rect? rect,
    Alignment? alignment,
    this.route = false,
    bool barrier = false,
    bool tapAwayClosable = true,
    bool escapeClosable = true,
    ZoOverlayDismissMode dismissMode = ZoOverlayDismissMode.dispose,
    bool requestFocus = true,
    this.alwaysOnTop = false,
    this.persistentInBatch = false,
    this.mayDismiss,
    this.onDismiss,
    void Function(bool open)? onOpenChanged,
    VoidCallback? onDelayClosed,
    VoidCallback? onDispose,
    ZoPopperDirection? direction,
    bool preventOverflow = true,
    ZoTransitionType? transitionType,
    ZoOverlayAnimationWrap? animationWrap,
    Curve curve = ZoTransition.defaultCurve,
    Duration duration = ZoTransition.defaultDuration,
  }) : _onDispose = onDispose,
       _onDelayClosed = onDelayClosed,
       _onOpenChanged = onOpenChanged,
       _dismissMode = dismissMode,
       _animationWrap = animationWrap,
       _transitionType = transitionType,
       _preventOverflow = preventOverflow,
       _direction = direction,
       _requestFocus = requestFocus,
       _escapeClosable = escapeClosable,
       _tapAwayClosable = tapAwayClosable,
       _barrier = barrier,
       _alignment = alignment,
       _rect = rect,
       _offset = offset,
       _builder = builder,
       _curve = curve,
       _duration = duration,
       assert(offset != null || rect != null || alignment != null);

  double changeId = 0;

  /// 当前所在的 overlay
  ZoOverlay? overlay;

  /// 记录了最近一次 open 变为 true 的时间
  DateTime? lastOpenTime;

  /// 与 [onOpenChanged] 触发时机相同
  final openChangedEvent = EventTrigger<bool>();

  /// 与 [onDelayClosed] 触发时机相同
  final delayClosedEvent = VoidEventTrigger();

  /// 与 [onDispose] 触发时机相同
  final disposeEvent = VoidEventTrigger();

  /// 层当前的显示状态, 此项必须由 [ZoOverlay] 通过其 open / close 等 api 更改, 否则会产生未定义行为
  bool _localOpen = false;

  /// 层当前的显示状态
  bool get currentOpen => _localOpen;

  set _open(bool value) {
    if (value == _localOpen) return;

    if (value) {
      lastOpenTime = DateTime.now();
    }

    _localOpen = value;
    changed();
  }

  // # # # # # # # 核心 # # # # # # #

  WidgetBuilder? _builder;

  /// 构造层内容
  WidgetBuilder? get builder => _builder;

  set builder(WidgetBuilder? value) {
    _builder = value;
    changed();
  }

  Offset? _offset;

  /// 通过 Offset 进行定位
  Offset? get offset => _offset;

  set offset(Offset? value) {
    _offset = value;
    _rect = null;
    _alignment = null;
    changed();
  }

  Rect? _rect;

  /// 通过 Rect 进行定位, 一般用于 [direction] 布局, 如果未传入 [direction], 使用rect的
  /// 左上角作为位置
  Rect? get rect => _rect;

  set rect(Rect? value) {
    _rect = value;
    _offset = null;
    _alignment = null;
    changed();
  }

  Alignment? _alignment;

  /// 通过 Alignment 进行定位
  Alignment? get alignment => _alignment;

  set alignment(Alignment? value) {
    _alignment = value;
    _offset = null;
    _rect = null;
    changed();
  }

  // # # # # # # # 路由层 # # # # # # #

  /// 如果是一个 [route] 层, 在开启时, 会将层对应的路由设置到此项
  ZoOverlayRoute? _attachRoute;

  /// 表示当前是一个 route overlay, 它会在 open 时向路由栈 push 一个新的路由,
  /// 用户可通过 Navigator.pop() 等路由 api 来关闭路由层
  ///
  /// 当通过 moveToTop / moveToBottom 等api改变路由层的位置时, 只会改变其视觉位置,
  /// 路由栈顺序不会改变, 所以在执行返回等路由操作时, 仍然会以其打开的顺序进行关闭
  final bool route;

  // # # # # # # # 杂项 # # # # # # #

  bool _barrier;

  /// 是否显示遮罩
  bool get barrier => _barrier;

  set barrier(bool value) {
    _barrier = value;
    changed();
  }

  bool _tapAwayClosable;

  /// 点击层内容之外时是否关闭, 如果当前层之上有其他启用该配置的层, 则不会关闭
  bool get tapAwayClosable => _tapAwayClosable;

  set tapAwayClosable(bool value) {
    _tapAwayClosable = value;
    changed();
  }

  bool _escapeClosable;

  /// 点击 esc 键是否关闭层, 如果当前层之上有其他启用该配置的层, 则不会关闭
  bool get escapeClosable => _escapeClosable;

  set escapeClosable(bool value) {
    _escapeClosable = value;
    changed();
  }

  bool _requestFocus;

  /// 层是否需要获取焦点
  bool get requestFocus => _requestFocus;

  set requestFocus(bool value) {
    _requestFocus = value;
    changed();
  }

  // # # # # # # # 状态和行为 # # # # # # #

  /// 使层始终显示在最顶部
  ///
  /// 如果有多个 [alwaysOnTop] 层, 按插入顺序显示它们, 使用 [moveToTop] 也能对其进行调整
  ///
  /// 更改此值时, 不会自动调整层的位置, 需要通过 [moveToTop] 等 api 手动调整
  bool alwaysOnTop;

  /// 若此项为 true, 在执行 closeAll / disposeAll 时不会将其关闭, 适合搭配 [alwaysOnTop]
  /// 实现一些永远固定在顶部的层, 比如 notice
  ///
  /// close / dispose 不受影响
  bool persistentInBatch;

  ZoOverlayDismissMode _dismissMode;

  /// 控制在通过 escapeClosable 和 tapAwayClosable 关闭时, 是销毁还是仅关闭层
  ZoOverlayDismissMode get dismissMode => _dismissMode;

  set dismissMode(ZoOverlayDismissMode value) {
    _dismissMode = value;
    changed();
  }

  /// 是否可安全关闭或销毁, 返回 false 可阻止, 随后, 可以在 onDismiss 中监听被拦截的操作
  bool Function()? mayDismiss;

  /// 关闭或销毁时调用, 无论它是否成功, 可在此处添加拦截询问等操作
  void Function(bool didDismiss, dynamic result)? onDismiss;

  /// 执行 mayDismiss 检测
  bool _mayDismiss() {
    if (mayDismiss != null) return mayDismiss!();
    return true;
  }

  /// 执行 onDismiss 通知
  void _onDismiss(bool didDismiss, dynamic result) {
    onDismiss?.call(didDismiss, result);
  }

  void Function(bool open)? _onOpenChanged;

  /// [currentOpen] 状态变更时调用
  void Function(bool open)? get onOpenChanged => _onOpenChanged;

  set onOpenChanged(void Function(bool open)? value) {
    _onOpenChanged = value;
    changed();
  }

  VoidCallback? _onDelayClosed;

  /// 在关闭或销毁时, 如果包含延迟关闭动画, 会在其结束后调用
  VoidCallback? get onDelayClosed => _onDelayClosed;

  set onDelayClosed(VoidCallback? value) {
    _onDelayClosed = value;
    changed();
  }

  VoidCallback? _onDispose;

  /// 销毁时调用
  VoidCallback? get onDispose => _onDispose;

  set onDispose(VoidCallback? value) {
    _onDispose = value;
    changed();
  }

  // # # # # # # # Popper 相关 # # # # # # #

  ZoPopperDirection? _direction;

  /// 显示的方向, 如果设置, overlay 会采用 Popper 定位模式, 显示在目标位置的指定方向上
  ZoPopperDirection? get direction => _direction;

  set direction(ZoPopperDirection? value) {
    _direction = value;
    changed();
  }

  bool _preventOverflow;

  /// 如果当前定位所用空间不足时, 是否自动调整位置防止被遮挡, 具体表现为
  ///
  /// - 对定位主轴, 如果当前方向被折叠, 并且另一侧可用, 会将子级翻转到另一侧
  /// - 对于定位交叉轴, 如果当前存在被遮挡部分, 会尝试移动子级使其可见
  ///
  /// 当前 [ZoPopperDirection] 表示左右时, 主轴为横轴, 表示上下时, 主轴为纵轴
  bool get preventOverflow => _preventOverflow;

  set preventOverflow(bool value) {
    _preventOverflow = value;
    changed();
  }

  // # # # # # # # 动画 # # # # # # #

  ZoTransitionType? _transitionType;

  /// 动画类型
  ZoTransitionType? get transitionType => _transitionType;

  set transitionType(ZoTransitionType? value) {
    _transitionType = value;
    changed();
  }

  /// 配置动画曲线
  Curve _curve;

  /// 配置动画曲线
  Curve get curve => _curve;

  /// 配置动画曲线
  set curve(Curve value) {
    _curve = value;
    changed();
  }

  /// 动画持续时间
  Duration _duration;

  /// 动画持续时间
  Duration get duration => _duration;

  /// 动画持续时间
  set duration(Duration value) {
    _duration = value;
    changed();
  }

  ZoOverlayAnimationWrap? _animationWrap;

  /// 自定义动画包装器, 组件内部会使用 [ZoTransition] 来实现动画, 通过此项你可以为将子级包装到 [ZoTransitionBase]
  /// 这类的组件中来添加自定义动画
  ZoOverlayAnimationWrap? get animationWrap => _animationWrap;

  set animationWrap(ZoOverlayAnimationWrap? value) {
    _animationWrap = value;
    changed();
  }

  /// 临时锁定并不触发通知
  bool _lockNotify = false;

  /// 通知层发生了变更
  void changed() {
    changeId = math.Random().nextDouble();
    if (!_lockNotify) notifyListeners();
  }

  /// 在 popper 布局中, 控制气泡和目标的间距
  double get distance => 0;

  /// 批量更改状态, 在需要同时更改多个状态时, 可以使用此方法减少通知次数
  void batch(VoidCallback callback) {
    _lockNotify = true;
    callback();
    _lockNotify = false;
    notifyListeners();
  }

  /// 等待某些异步操作完成, 比如, 如果当前是路由层, 在层插入后, 可通过此项等待,
  /// 如果通过 Navigator.pop(val) 进行了返回, 可通过它监听和接收值
  Future wait() {
    return _attachRoute?.popped ?? Future.value();
  }

  /// 子类可通过重写此方法来定义层的内容, 它应该在内部调用 [builder] 方法
  @protected
  Widget overlayBuilder(BuildContext context) {
    if (builder == null) return const SizedBox.shrink();
    return builder!(context);
  }

  /// 在层完成绘制后调用, 可以覆盖此方法对绘制进行自定义
  @protected
  void customPaint(
    OverlayPositionedRenderObject rb,
    PaintingContext context,
    ZoOverlayCustomPaintData data,
  ) {}

  /// [currentOpen] 变更时调用
  ///
  /// 注: 在 dispose 时, 如果包含动画, 会先执行关闭动画再 dispose, 此时也会触发 onOpenChange(false)
  @protected
  @mustCallSuper
  void openChanged(bool open) {
    onOpenChanged?.call(open);
    openChangedEvent.emit(open);
  }

  /// 在关闭或销毁时, 如果包含延迟关闭动画, 会在其结束后调用
  @protected
  @mustCallSuper
  void delayClosed() {
    onDelayClosed?.call();
    delayClosedEvent.emit();
  }

  /// 在层可进行拖动时, 会通过此方法获取可拖动的区域, 返回 null 时可取消限制,
  /// 参数为当前容器的矩形区域, 也是默认的限制范围
  ///
  /// rubber 返回 false 时, 将禁用阻尼效果
  @protected
  ({Rect bound, bool rubber})? getDragBound(
    Rect containerRect,
    Rect overlayRect,
  ) {
    return (bound: containerRect, rubber: true);
  }

  /// 拖动结束时调用, 可用于特定场景(如drawer)中, 根据拖动位置决定是否要关闭层
  ///
  /// 该方法可返回 bool 值来控制拖动结束后的行为
  /// - 为 true 时, 会立即还原位置
  /// - 为 false 时, 会延迟到关闭动画完成后还原
  @protected
  bool? onDragEnd(ZoOverlayDragEndData data) {
    return null;
  }

  /// 关闭层, 层关闭后, 其状态仍会保留, 可以在稍后重新开启它
  close() {
    if (overlay == null) return;
    overlay!.close(this);
  }

  /// 开启层并将其其移动到顶部
  open() {
    if (overlay == null) return;
    overlay!.open(this);
  }

  bool _disposeByParent = false;

  /// 完全移除层, 被销毁的层不能被再次使用
  @override
  void dispose() {
    if (overlay == null || _disposeByParent) {
      onDispose?.call();
      disposeEvent.emit();

      overlay = null;
      _attachRoute = null;

      _disposeByParent = false;

      super.dispose();
      return;
    }

    overlay!.dispose(this);
  }

  /// 将层移动到顶部
  ///
  /// 注: 对于路由层, 只会改变其视觉位置, 路由栈顺序不会改变, 所以在执行返回等路由操作时, 仍然会以其打开的顺序进行关闭
  void moveToTop() {
    if (overlay == null) return;
    overlay!.moveToTop(this);
  }

  /// 将层移动到最底部
  ///
  /// 注: 对于路由层, 只会改变其视觉位置, 路由栈顺序不会改变, 所以在执行返回等路由操作时, 仍然会以其打开的顺序进行关闭
  void moveToBottom() {
    if (overlay == null) return;
    overlay!.moveToBottom(this);
  }
}

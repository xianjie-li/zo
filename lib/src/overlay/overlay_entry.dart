part of "package:zo/src/overlay/overlay.dart";

/// [ZoOverlayEntry] 的变更状态
enum ZoOverlayEntryStatus {
  /// 显示
  open,

  /// 关闭
  close,

  /// 销毁
  dispose,
}

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
    required WidgetBuilder builder,
    Offset? offset,
    Rect? rect,
    Alignment? alignment,
    this.route = false,
    bool barrier = false,
    bool tapAwayClosable = false,
    bool escapeClosable = true,
    ZoOverlayDismissMode dismissMode = ZoOverlayDismissMode.dispose,
    bool draggable = false,
    bool requestFocus = true,
    this.mayDismiss,
    this.onDismiss,
    this.onStatusChanged,
    ZoPopperDirection? direction,
    bool preventOverflow = false,
    double distance = 0,
    bool arrow = false,
    Size? arrowSize,
    ZoTransitionType? transitionType,
    ZoOverlayAnimationWrap? animationWrap,

    /// 设置默认延迟以默认满足大部分包含动画的场景
    Duration? exitAnimationDuration = ZoTransition.defaultDuration,
  }) : _dismissMode = dismissMode,
       _animationWrap = animationWrap,
       _exitAnimationDuration = exitAnimationDuration,
       _transitionType = transitionType,
       _arrowSize = arrowSize,
       _arrow = arrow,
       _distance = distance,
       _preventOverflow = preventOverflow,
       _direction = direction,
       _requestFocus = requestFocus,
       _draggable = draggable,
       _escapeClosable = escapeClosable,
       _tapAwayClosable = tapAwayClosable,
       _barrier = barrier,
       _alignment = alignment,
       _rect = rect,
       _offset = offset,
       _builder = builder,
       assert(offset != null || rect != null || alignment != null);

  double changeId = 0;

  /// 当前所在的 overlay
  ZoOverlay? overlay;

  /// 记录了最近一次 open 变为 true 的时间
  DateTime? lastOpenTime;

  bool _localOpen = false;

  /// 层当前的显示状态, 此项必须由 [ZoOverlay] 通过其 open / close 等 api 更改, 否则会产生未定义行为
  bool get _open => _localOpen;

  set _open(bool value) {
    if (value == _localOpen) return;

    if (value) {
      lastOpenTime = DateTime.now();
    }

    _localOpen = value;
    _changed();
  }

  // # # # # # # # 核心 # # # # # # #

  WidgetBuilder _builder;

  /// 构造层内容
  WidgetBuilder get builder => _builder;

  set builder(WidgetBuilder value) {
    _builder = value;
    _changed();
  }

  Offset? _offset;

  /// 通过 Offset 进行定位
  Offset? get offset => _offset;

  set offset(Offset? value) {
    _offset = value;
    _rect = null;
    _alignment = null;
    _changed();
  }

  Rect? _rect;

  /// 通过 Rect 进行定位, 一般用于 [direction] 布局, 如果未传入 [direction], 使用rect的
  /// 左上角作为位置
  Rect? get rect => _rect;

  set rect(Rect? value) {
    _rect = value;
    _offset = null;
    _alignment = null;
    _changed();
  }

  Alignment? _alignment;

  /// 通过 Alignment 进行定位
  Alignment? get alignment => _alignment;

  set alignment(Alignment? value) {
    _alignment = value;
    _offset = null;
    _rect = null;
    _changed();
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
    _changed();
  }

  bool _tapAwayClosable;

  /// 点击层内容之外时是否关闭, 如果当前层之上有其他启用该配置的层, 则不会关闭
  bool get tapAwayClosable => _tapAwayClosable;

  set tapAwayClosable(bool value) {
    _tapAwayClosable = value;
    _changed();
  }

  bool _escapeClosable;

  /// 点击 esc 键是否关闭层, 如果当前层之上有其他启用该配置的层, 则不会关闭
  bool get escapeClosable => _escapeClosable;

  set escapeClosable(bool value) {
    _escapeClosable = value;
    _changed();
  }

  bool _draggable;

  /// 是否可拖动, 可在层内添加 DragHandle 来限制可拖动的区域
  bool get draggable => _draggable;

  set draggable(bool value) {
    _draggable = value;
    _changed();
  }

  bool _requestFocus;

  /// 层是否需要获取焦点
  bool get requestFocus => _requestFocus;

  set requestFocus(bool value) {
    _requestFocus = value;
    _changed();
  }

  // # # # # # # # 状态和行为 # # # # # # #

  ZoOverlayDismissMode _dismissMode;

  /// 控制在通过 escapeClosable 和 tapAwayClosable 关闭时, 是销毁还是仅关闭层
  ZoOverlayDismissMode get dismissMode => _dismissMode;

  set dismissMode(ZoOverlayDismissMode value) {
    _dismissMode = value;
    _changed();
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

  /// 特定状态变更时发出通知
  void Function(ZoOverlayEntryStatus status)? onStatusChanged;

  // # # # # # # # Popper 相关 # # # # # # #

  ZoPopperDirection? _direction;

  /// 显示的方向, 如果设置, overlay 会采用 Popper 定位模式, 显示在目标位置的指定方向上
  ZoPopperDirection? get direction => _direction;

  set direction(ZoPopperDirection? value) {
    _direction = value;
    _changed();
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
    _changed();
  }

  /// 在 Popper 模式下, 设置距离原点的偏移
  double _distance;

  /// 在 Popper 模式下, 设置距离原点的偏移
  double get distance => _distance;

  /// 在 Popper 模式下, 设置距离原点的偏移
  set distance(double value) {
    _distance = value;
    _changed();
  }

  /// 是否显示箭头
  bool _arrow;

  /// 是否显示箭头
  bool get arrow => _arrow;

  /// 是否显示箭头
  set arrow(bool value) {
    _arrow = value;
    _changed();
  }

  /// 箭头的尺寸
  Size? _arrowSize;

  /// 箭头的尺寸
  Size? get arrowSize => _arrowSize;

  /// 箭头的尺寸
  set arrowSize(Size? value) {
    _arrowSize = value;
    _changed();
  }

  // # # # # # # # 动画 # # # # # # #

  ZoTransitionType? _transitionType;

  /// 动画类型
  ZoTransitionType? get transitionType => _transitionType;

  set transitionType(ZoTransitionType? value) {
    _transitionType = value;
    _changed();
  }

  ZoOverlayAnimationWrap? _animationWrap;

  /// 自定义动画包装器, 组件内部会使用 [ZoTransition] 来实现动画, 通过此项你可以为将子级包装到 [ZoTransitionBase]
  /// 这类的组件中来添加自定义动画
  ZoOverlayAnimationWrap? get animationWrap => _animationWrap;

  set animationWrap(ZoOverlayAnimationWrap? value) {
    _animationWrap = value;
    _changed();
  }

  Duration? _exitAnimationDuration;

  /// 销毁层时, 如果其存在动画, 需要设置此项来使其延迟销毁
  Duration? get exitAnimationDuration => _exitAnimationDuration;

  set exitAnimationDuration(Duration? value) {
    _exitAnimationDuration = value;
    _changed();
  }

  /// 变更changeId为随机数
  void _changed() {
    changeId = math.Random().nextDouble();
    notifyListeners();
  }

  /// 等待某些异步操作完成, 比如, 如果当前是路由层, 在层插入后, 可通过此项等待,
  /// 如果通过 Navigator.pop(val) 进行了返回, 可通过它监听和接收值
  Future wait() {
    return _attachRoute?.popped ?? Future.value();
  }

  /// 销毁实例, 销毁后不可再添加到任何 [ZoOverlay] 中
  @override
  void dispose() {
    overlay = null;
    _attachRoute = null;

    super.dispose();
  }
}

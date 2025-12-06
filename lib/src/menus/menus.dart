/// 通过 [ZoOverlayEntry] 实现层渲染，[ZoOptionViewList] 渲染具体的列表，[ZoOptionController] 管理选项数据，
/// 每个层级的菜单单独持有一个 [ZoMenuEntry] 层，同级菜单复用一个层实例
library;

import "dart:async";

import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:zo/zo.dart";

/// 渲染菜单层，支持树选项、选中处理、筛选、选项定制等
class ZoMenuEntry extends ZoOverlayEntry {
  ZoMenuEntry({
    required List<ZoOption> options,
    Iterable<Object>? selected,
    ZoOption? option,
    this.selectionType = ZoSelectionType.none,
    this.branchSelectable = false,
    this.dismissOnSelect = true,
    ZoSize? size,
    Widget? toolbar,
    double? maxHeight,
    double maxHeightFactor = ZoOptionViewList.defaultHeightFactor,
    double width = ZoMenuEntry.defaultMenuWidth,
    this.inheritWidth = true,
    bool loading = false,
    String? matchString,
    RegExp? matchRegexp,
    this.onTap,
    this.onActiveChanged,
    this.onFocusChanged,
    super.groupId,
    // super.builder,
    super.offset,
    super.rect,
    super.alignment = Alignment.center,
    // super.route = false,
    // super.barrier = false,
    super.tapAwayClosable,
    super.dismissMode,
    super.requestFocus,
    super.autoFocus,
    // super.alwaysOnTop,
    // super.mayDismiss,
    // super.onDismiss,
    super.onHoverChanged,
    super.onKeyEvent,
    super.onOpenChanged,
    super.onDelayClosed,
    super.onDispose,
    super.direction = ZoPopperDirection.bottomLeft,
    super.preventOverflow = true,
    super.transitionType,
    super.animationWrap,
    super.customWrap,
    super.curve,
    super.duration = Duration.zero,
  }) : _option = option,
       _loading = loading,
       _width = width,
       _maxHeightFactor = maxHeightFactor,
       _maxHeight = maxHeight,
       _size = size,
       _toolbar = toolbar {
    // menu 自行处理esc关闭行为
    super.escapeClosable = false;

    _openOptions = ZoSelector();

    if (option == null) {
      _initController(
        ZoOptionController(
          data: options,
          // menu 自行管理 open 状态
          expandAll: true,
          selected: selected,
          matchRegexp: matchRegexp,
          matchString: matchString,
        ),
      );
    }
  }

  /// 在独立控制器管理选项，便于后续在同样需要树形结构的组件中复用逻辑
  late final ZoOptionController controller;

  /// 选中项控制，选中项以扁平的列表方式维护，可以通过 [ZoOptionSelectedData] 和 [ZoOptionController.flatList]
  /// 获取包含树信息的选中项数据
  ZoSelector<Object, ZoOption> get selector => controller.selector;

  /// 包含选中项各种信息的对象，相比 [selector] 包含更树形结构的选中信息，如果选项是扁平的或无需树信息，
  /// 优先使用 [selector], 因为本属性会对整个树进行遍历
  ZoOptionSelectedData get selectedDatas {
    return ZoOptionSelectedData.fromSelected(
      selector.getSelected(),
      controller.flatList,
    );
  }

  /// 选项列表
  List<ZoOption> get options => _options;
  List<ZoOption> _options = [];
  set options(List<ZoOption> value) {
    assert(option == null);
    controller.data = value;
    changedAndCloseDescendantMenus();
  }

  /// 用于过滤选项的文本, 传入后只显示包含该文本的选项
  String? get matchString => controller.matchString;
  set matchString(String? value) {
    assert(option == null);
    controller.matchString = value;
    changedAndCloseDescendantMenus();
  }

  /// 用于过滤选项的正则, 传入后只显示匹配的选项
  RegExp? get matchRegexp => controller.matchRegexp;
  set matchRegexp(RegExp? value) {
    assert(option == null);
    controller.matchRegexp = value;
    changedAndCloseDescendantMenus();
  }

  /// 菜单对应的选项, 只有子菜单会存在此项, 传入时, 如果 options 没有值, 并且选项包含了 loadOptions
  /// 配置, 会通过 loadOptions 加载选项
  ///
  /// 只会由菜单内部为其子菜单设置, 对根菜单无效
  ZoOption? get option => _option;
  ZoOption? _option;
  set option(ZoOption? value) {
    // 仅子菜单可更改选项
    assert(_option != null && value != null);
    _option = value;
    changedAndCloseDescendantMenus();
  }

  /// 控制选择类型
  ZoSelectionType selectionType;

  /// 分支节点是否可选中
  bool branchSelectable;

  /// 单选或未启用选中时, 点击项后是否自动关闭层
  bool dismissOnSelect;

  /// 选项尺寸
  ZoSize? get size => _size;
  ZoSize? _size;
  set size(ZoSize? value) {
    _size = value;
    changed();
  }

  /// 在顶部渲染工具栏
  Widget? get toolbar => _toolbar;
  Widget? _toolbar;
  set toolbar(Widget? value) {
    _toolbar = value;
    changed();
  }

  /// 最大高度, 默认会根据视口尺寸和 [maxHeightFactor] 进行限制
  double? get maxHeight => _maxHeight;
  double? _maxHeight;
  set maxHeight(double? value) {
    _maxHeight = value;
    changed();
  }

  /// 最大高度的比例, 设置 [maxHeight] 后此项无效
  double get maxHeightFactor => _maxHeightFactor;
  double _maxHeightFactor;
  set maxHeightFactor(double value) {
    _maxHeightFactor = value;
    changed();
  }

  /// 菜单宽度
  double get width => _width;
  double _width;
  set width(double value) {
    _width = value;
    changed();
  }

  /// 若子选项未设置宽度，是否继承父级宽度
  bool inheritWidth;

  /// 是否处于加载状态
  bool get loading => _loading;
  bool _loading;
  set loading(bool value) {
    _loading = value;
    changed();
  }

  /// 选项被点击, 若返回一个 future, 可进入loading状态
  dynamic Function(ZoTriggerEvent event)? onTap;

  /// 选项活动状态变更
  /// - 鼠标: 表示位于组件上方
  /// - 触摸设备: 按下触发, 松开或移动时关闭
  ZoTriggerListener<ZoTriggerToggleEvent>? onActiveChanged;

  /// 焦点变更事件
  ZoTriggerListener<ZoTriggerToggleEvent>? onFocusChanged;

  /// 标记当前层级菜单所有开启子菜单的选项, 它在每个层级的菜单间独立
  ///
  /// 仅作为标记, 组件内部需要负责同步开启状态的菜单与此项一致
  late final ZoSelector<Object, ZoOption> _openOptions;

  /// 菜单默认宽度
  static const defaultMenuWidth = 240.0;

  /// 父菜单层
  ZoMenuEntry? _parent;

  /// 子菜单层, 同一级的所有选项复用一个层
  ZoMenuEntry? _child;

  /// 滚动控制器
  final _scrollController = ScrollController();

  /// 控制子菜单延迟开启
  Timer? _openChildMenuTimer;

  /// 最后一次有子菜单开启的时间，此属性只在顶层菜单写入
  DateTime? _lastChildOpenTime;

  /// 用于内部控制loading状态
  bool _localLoading = false;

  /// 全选行为标记，用于在全选和取消之间切换
  bool _selectAllFlag = false;

  /// 左移键
  final _leftActivator = const SingleActivator(
    LogicalKeyboardKey.arrowLeft,
    includeRepeats: false,
  );

  /// 右移键
  final _rightActivator = const SingleActivator(
    LogicalKeyboardKey.arrowRight,
    includeRepeats: false,
  );

  /// 全选按键
  final _allSelectActivator = ZoShortcutsHelper.platformAwareActivator(
    LogicalKeyboardKey.keyA,
    includeRepeats: false,
  );

  /// 关闭
  final _closeActivator = const SingleActivator(
    LogicalKeyboardKey.escape,
    includeRepeats: false,
  );

  @override
  void dispose() {
    _unbindEvents();
    _scrollController.dispose();
    _openChildMenuTimer?.cancel();
    controller.dispose();
    super.dispose();
  }

  @override
  void openChanged(bool open) {
    super.openChanged(open);

    // 层关闭时一律关闭所有子菜单
    if (!open) {
      closeDescendantMenus();

      // 取消所有高亮
      _openOptions.unselectAll();
    }
  }

  /// 覆盖 escapeClosable 关闭行为，关闭所有关联窗口
  @override
  @protected
  KeyEventResult keyEvent(FocusNode node, KeyEvent event) {
    if (!currentOpen) return KeyEventResult.ignored;

    if (ZoShortcutsHelper.checkEvent(_closeActivator, event)) {
      return _onShortcutsClose();
    } else if (ZoShortcutsHelper.checkEvent(_leftActivator, event)) {
      return _onShortcutsMove(true);
    } else if (ZoShortcutsHelper.checkEvent(_rightActivator, event)) {
      return _onShortcutsMove(false);
    } else if (ZoShortcutsHelper.checkEvent(_allSelectActivator, event)) {
      return _onShortcutsAllSelector();
    }

    return KeyEventResult.ignored;
  }

  /// 通过按键关闭所有层
  KeyEventResult _onShortcutsClose() {
    _getRelativeOverlay().forEach((entry) {
      entry.close();
    });
    return KeyEventResult.handled;
  }

  /// 通过按键在相邻层之间移动焦点
  KeyEventResult _onShortcutsMove(bool isLeft) {
    final List<ZoMenuEntry?> list = [_child, _parent]; // 子项放在前面，优先匹配

    final Rect? rect = positionedRenderObject?.overlayRect;

    if (rect == null) return KeyEventResult.ignored;

    for (final entry in list) {
      if (entry == null) continue;

      final otherRect = entry.positionedRenderObject?.overlayRect;

      if (otherRect == null) continue;

      final atLeft = otherRect.left < rect.left;
      final atRight = otherRect.right > rect.right;

      if ((isLeft && atLeft) || (!isLeft && atRight)) {
        final focused = entry.focusChild();

        return focused ? KeyEventResult.handled : KeyEventResult.ignored;
      }
    }

    return KeyEventResult.ignored;
  }

  /// 通过按键全选当前层所有选项
  KeyEventResult _onShortcutsAllSelector() {
    if (selectionType != ZoSelectionType.multiple) {
      return KeyEventResult.ignored;
    }

    final List<Object> values = [];

    for (final opt in options) {
      if (branchSelectable || !opt.isBranch) {
        values.add(opt.value);
      }
    }

    if (_selectAllFlag) {
      controller.selector.unselectList(values);
    } else {
      controller.selector.selectList(values);
    }

    _selectAllFlag = !_selectAllFlag;

    return KeyEventResult.handled;
  }

  /// 通知所有关联菜单层进行更新
  void menusChanged() {
    if (_parent != null) return;
    for (final menu in _getRelativeOverlay()) {
      menu.changed();
    }
  }

  /// 更新当前菜单, 并关闭所有子菜单
  void changedAndCloseDescendantMenus() {
    _options = controller.getChildren(value: option?.value);
    changed();
    closeDescendantMenus();
  }

  /// 关闭所有子孙菜单
  void closeDescendantMenus() {
    var child = _child;

    _openOptions.unselectAll();

    while (child != null) {
      if (child.currentOpen) child.close();
      child._openOptions.unselectAll();

      child = child._child;
    }
  }

  /// 初始化控制器
  void _initController(ZoOptionController controller) {
    this.controller = controller;
    _options = controller.getChildren(value: option?.value);
    _bindEvents();
  }

  void _bindEvents() {
    controller.selector.addListener(changed);
    _openOptions.addListener(changed);
    hoverEvent.on(_onHover);
  }

  void _unbindEvents() {
    controller.selector.removeListener(changed);
    _openOptions.removeListener(changed);
    hoverEvent.off(_onHover);
  }

  void _onHover(bool hover) {
    // 处于hover状态时，确保当前层获得了焦点，否则键盘事件无效会不符合直觉
    if (hover && !focusScopeNode.hasFocus) {
      // 如果有子菜单刚开启，取消聚焦，防止菜单出现在鼠标现有位置导致异常的焦点行为
      final lastTime = _getTopOverlay()._lastChildOpenTime;

      if (lastTime != null) {
        final diff = DateTime.now().difference(lastTime);

        if (diff < const Duration(milliseconds: 100)) {
          return;
        }
      }

      focusScopeNode.requestScopeFocus();
    }
  }

  void _onTap(ZoTriggerEvent event) {
    onTap?.call(event);

    final ZoOptionEventData(:option) = event.data;

    if (!option.enabled) return;

    if (!branchSelectable && option.isBranch) return;

    final isTouchLike = ZoTrigger.isTouchLike(event.deviceKind);

    // 如果是触摸触发, 并且当前是分支节点, 需要禁止选择后关闭行为
    final isBranchTouch = isTouchLike && option.isBranch;

    if (selectionType == ZoSelectionType.none) {
      if (dismissOnSelect && !isBranchTouch) {
        _getTopOverlay().dismiss();
      }
      return;
    }

    if (selectionType == ZoSelectionType.single) {
      controller.selector.setSelected([option.value]);

      if (dismissOnSelect && !isBranchTouch) {
        _getTopOverlay().dismiss();
      }
    } else {
      controller.selector.toggle(option.value);
    }
  }

  void _onActiveChanged(ZoTriggerToggleEvent event) {
    onActiveChanged?.call(event);
    _childMenuOpenCommonHandler(event);
  }

  void _onFocusChanged(ZoTriggerToggleEvent event) {
    onFocusChanged?.call(event);
    _childMenuOpenCommonHandler(event);
  }

  void _childMenuOpenCommonHandler(ZoTriggerToggleEvent event) {
    final ZoOptionEventData(:option, :context) = event.data;

    if (!event.toggle) return;

    if (_openOptions.isSelected(option.value)) return;

    final hasChildren = option.children != null && option.children!.isNotEmpty;
    final hasLoader = option.loader != null;

    // 关闭所有子级菜单
    closeDescendantMenus();

    // 取消所有子菜单打开操作
    if (_openChildMenuTimer != null) {
      _openChildMenuTimer!.cancel();
    }

    // 取消所有高亮状态
    if (_openOptions.hasSelected()) {
      _openOptions.unselectAll();
    }

    // 没有可用子菜单
    if (!hasChildren && !hasLoader) return;

    if (ZoTrigger.isTouchLike(event.deviceKind)) {
      _openChildMenu(context, option);
    } else {
      _delayOpenChildMenu(context, option);
    }
  }

  /// 延迟开启子菜单, 防止滚动和快速划过时一次造成过多加载
  void _delayOpenChildMenu(BuildContext context, ZoOption option) {
    if (_openChildMenuTimer != null) {
      _openChildMenuTimer!.cancel();
    }
    _openChildMenuTimer = Timer(
      const Duration(milliseconds: 80),
      () {
        _openChildMenuTimer = null;

        if (!context.mounted) return;
        _openChildMenu(context, option);
      },
    );
  }

  /// 开启子菜单
  void _openChildMenu(BuildContext context, ZoOption option) {
    final renderBox = context.findRenderObject() as RenderBox?;

    if (renderBox == null || !renderBox.attached) return;

    // 高亮当前项
    _openOptions.setSelected([option.value]);

    final rect = renderBox.localToGlobal(Offset.zero) & renderBox.size;

    final style = context.zoStyle;

    final target = _adjustTarget(rect, style);

    final child = _initOrUpdateChildOverlay(option, target);

    _getTopOverlay()._lastChildOpenTime = DateTime.now();
    child.open();
  }

  /// 获取最上层的 overlay
  ZoMenuEntry _getTopOverlay() {
    var parent = _parent;

    while (parent != null) {
      if (parent._parent != null) {
        parent = parent._parent;
      } else {
        break;
      }
    }

    return parent ?? this;
  }

  /// 获取包括自身在内的所有关联层, 按从父级到子级的顺序排序
  List<ZoMenuEntry> _getRelativeOverlay() {
    final List<ZoMenuEntry> parents = [];
    final List<ZoMenuEntry> children = [];

    var parent = _parent;
    var child = _child;

    while (parent != null) {
      parents.insert(0, parent);
      parent = parent._parent;
    }

    while (child != null) {
      children.add(child);
      child = child._child;
    }

    return [...parents, this, ...children];
  }

  /// 用于根据边距等微调子菜单相对于选项的位置
  Rect _adjustTarget(Rect target, ZoStyle style) {
    return target.shift(Offset(0, -style.space2));
  }

  /// 初始化或更新子菜单所在的层
  ZoMenuEntry _initOrUpdateChildOverlay(ZoOption option, Rect target) {
    // 子菜单固定使用已经 flip 的方向
    final currentDirection = _parent == null
        ? null
        : positionedRenderObject?.direction;

    final direction = currentDirection ?? ZoPopperDirection.rightTop;

    final fallbackWidth = inheritWidth
        ? _getTopOverlay().width
        : ZoMenuEntry.defaultMenuWidth;

    final width = option.optionsWidth ?? fallbackWidth;

    ZoMenuEntry child;

    if (_child == null) {
      child = ZoMenuEntry(
        rect: target,
        options: [],
        option: option,
        selectionType: selectionType,
        branchSelectable: branchSelectable,
        dismissOnSelect: dismissOnSelect,
        // maxHeight: maxHeight,
        // maxHeightFactor: maxHeightFactor,
        size: size,
        width: width,
        inheritWidth: inheritWidth,
        onTap: onTap,
        onActiveChanged: onActiveChanged,
        onFocusChanged: onFocusChanged,
        groupId: groupId,
        direction: direction,
        dismissMode: ZoOverlayDismissMode.close,
        tapAwayClosable: false,
        autoFocus: false,
      );

      child._parent = this;
      child._initController(controller);
    } else {
      child = _child!;
      child._parent = this;

      child.actions(() {
        child.rect = target;
        child.option = option;
        child.selectionType = selectionType;
        child.branchSelectable = branchSelectable;
        child.dismissOnSelect = dismissOnSelect;
        // child.maxHeight = maxHeight;
        // child.maxHeightFactor = maxHeightFactor;
        child.width = width;
        child.onTap = onTap;
        child.onActiveChanged = onActiveChanged;
        child.onFocusChanged = onFocusChanged;
        child.groupId = groupId;
        child.direction = direction;
        child._localLoading = false;
      });
    }

    _child = child;

    // 获取异步选项
    if ((option.children == null || option.children!.isEmpty) &&
        option.loader != null) {
      final curVal = option.value;
      _child!._localLoading = true;
      controller.loadChildren(option.value).whenComplete(() {
        if (_child != null && curVal == _child!.option!.value) {
          _child!._localLoading = false;
          _child!.changedAndCloseDescendantMenus();
        }
      });
    }

    return child;
  }

  bool _isActive(ZoOption option) {
    return selector.isSelected(option.value);
  }

  bool _isHighlight(ZoOption option) {
    return _openOptions.isSelected(option.value) ||
        controller.hasSelectedChild(option.value);
  }

  @protected
  @override
  Widget overlayBuilder(BuildContext context) {
    return SizedBox(
      width: width,
      child: ZoOptionViewList(
        options: options,
        option: option,
        activeCheck: _isActive,
        highlightCheck: _isHighlight,
        size: size,
        toolbar: toolbar,
        maxHeight: maxHeight,
        maxHeightFactor: maxHeightFactor,
        loading: loading || _localLoading,
        scrollController: _scrollController,
        onTap: _onTap,
        onActiveChanged: _onActiveChanged,
        onFocusChanged: _onFocusChanged,
      ),
    );
  }
}

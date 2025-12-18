import "dart:async";

import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:zo/zo.dart";

/// 菜单层的基类，抽象了 [ZoMenu] 和 [ZoTreeMenu] 的一些通用行为, 该类不假设菜单的具体样式，
/// 但包含了最基础的行为，如定位、基础事件、尺寸控制、选中行为控制等
abstract class ZoMenuEntry extends ZoOverlayEntry {
  ZoMenuEntry({
    // required List<ZoOption> options, // 几个属性子类可能会想要接收并传递给 controller
    // Iterable<Object>? selected,
    // String? matchString,
    // RegExp? matchRegexp,
    // ZoTreeDataFilter<ZoOption>? filter,
    this.selectionType = ZoSelectionType.none,
    this.branchSelectable = false,
    this.dismissOnSelect = true,
    ZoSize? size,
    Widget? toolbar,
    Widget? footer,
    double? maxHeight,
    double? width,
    bool loading = false,
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
    super.escapeClosable,
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
    super.direction = ZoPopperDirection.rightTop,
    super.preventOverflow = true,
    super.transitionType,
    super.animationWrap,
    super.customWrap,
    super.curve,
    // 关闭动画，让响应更高效
    super.duration = const Duration(seconds: 0),
    super.constrainsToView,
  }) : _loading = loading,
       _width = width,
       _maxHeight = maxHeight,
       _size = size,
       _toolbar = toolbar,
       _footer = footer;

  /// 菜单默认宽度
  static double defaultWidth = 240.0;

  /// 在独立控制器管理选项，便于后续在同样需要树形结构的组件中复用逻辑
  late final ZoOptionController controller;

  /// 选中项控制，选中项以扁平的列表方式维护，可以通过 [ZoOptionSelectedData] 和 [ZoOptionController.flatList]
  /// 获取包含树信息的选中项数据
  ZoSelector<Object, ZoOption> get selector => controller.selector;

  /// 包含选中项各种信息的对象，相比 [selector] 包含树形化的选中信息，如果选项是扁平的或无需树信息，
  /// 优先使用 [selector], 因为 [selectedDatas] 会包含对整个树的遍历
  ZoOptionSelectedData get selectedDatas {
    return ZoOptionSelectedData.fromSelected(
      selector.getSelected(),
      controller.flatList,
    );
  }

  /// 选项列表
  List<ZoOption> get options => controller.data;
  set options(List<ZoOption> value) {
    controller.data = value;
  }

  /// 通过自定义查询文本筛选选项，具体用法见 [ZoOptionController.matchRegexp]
  String? get matchString => controller.matchString;
  set matchString(String? value) {
    controller.matchString = value;
  }

  /// 通过自定义正则筛选选项，具体用法见 [ZoOptionController.matchRegexp]
  RegExp? get matchRegexp => controller.matchRegexp;
  set matchRegexp(RegExp? value) {
    controller.matchRegexp = value;
  }

  /// 通过自定义方法筛选选项，具体用法见 [ZoOptionController.filter]
  ZoTreeDataFilter<ZoOption>? get filter => controller.filter;
  set filter(ZoTreeDataFilter<ZoOption>? filter) {
    controller.filter = filter;
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

  /// 在底部渲染内容
  Widget? get footer => _footer;
  Widget? _footer;
  set footer(Widget? value) {
    _footer = value;
    changed();
  }

  /// 最大高度
  double? get maxHeight => _maxHeight;
  double? _maxHeight;
  set maxHeight(double? value) {
    _maxHeight = value;
    changed();
  }

  /// 菜单宽度
  double get width => _width ?? defaultWidth;
  double? _width;
  set width(double? value) {
    _width = value;
    changed();
  }

  /// 是否处于加载状态
  bool get loading => _loading;
  bool _loading;
  set loading(bool value) {
    _loading = value;
    changed();
  }

  /// 选项被点击, 若返回一个 future, 可进入loading状态
  dynamic Function(ZoTreeDataNode<ZoOption> event)? onTap;

  /// 选项活动状态变更
  /// - 鼠标: 表示位于组件上方
  /// - 触摸设备: 按下触发, 松开或移动时关闭
  ZoTriggerListener<ZoTriggerToggleEvent>? onActiveChanged;

  /// 选项焦点变更事件
  ZoTriggerListener<ZoTriggerToggleEvent>? onFocusChanged;

  @override
  @protected
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @protected
  void activeChanged(ZoTriggerToggleEvent event) {
    onActiveChanged?.call(event);
  }

  @protected
  void focusChanged(ZoTriggerToggleEvent event) {
    onFocusChanged?.call(event);
  }

  @protected
  @override
  Widget overlayBuilder(BuildContext context) {
    var menuNode = buildMenus(context);

    final style = context.zoStyle;

    if (toolbar != null || footer != null) {
      menuNode = Column(
        spacing: context.zoStyle.space1,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ?toolbar,
          Flexible(
            child: menuNode,
          ),
          ?footer,
        ],
      );
    }

    return SizedBox(
      width: width,
      child: Container(
        padding: EdgeInsets.all(
          (size ?? style.widgetSize) == ZoSize.small
              ? style.space1
              : style.space2,
        ),
        decoration: BoxDecoration(
          color: style.surfaceContainerColor,
          borderRadius: BorderRadius.circular(style.borderRadius),
          border: Border.all(color: style.outlineColor),
          boxShadow: [style.overlayShadow],
        ),
        child: menuNode,
      ),
    );
  }

  /// 子类需覆盖此方法来构造具体的菜单
  @protected
  Widget buildMenus(BuildContext context) {
    return const SizedBox.shrink();
  }
}

/// 渲染菜单层，支持级联展示、选中处理、筛选、选项定制等
///
/// 另见：
/// - [ZoOverlayEntry]: 菜单控件继承至此类, 可以通过层 api 管理菜单的显示，或是用于更进阶的场景
/// - [ZoOverlay]：进阶的层控制
/// - [ZoSelect]：基于此组件渲染弹出层，但额外添加了用于交互的输入框等
/// - [ZoTreeMenu]：通过树组件的菜单
class ZoMenu extends ZoMenuEntry {
  ZoMenu({
    required List<ZoOption> options,
    Iterable<Object>? selected,
    String? matchString,
    RegExp? matchRegexp,
    ZoTreeDataFilter<ZoOption>? filter,
    super.selectionType = ZoSelectionType.none,
    super.branchSelectable = false,
    super.dismissOnSelect = true,
    super.size,
    super.toolbar,
    super.footer,
    super.maxHeight,
    double? maxHeightFactor, // 新增
    super.width,
    super.loading,
    ZoOption? option,
    this.inheritWidth = true,
    super.onTap,
    super.onActiveChanged,
    super.onFocusChanged,
    super.groupId,
    // super.builder,
    super.offset,
    super.rect,
    super.alignment,
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
    super.direction,
    super.preventOverflow,
    super.transitionType,
    super.animationWrap,
    super.customWrap,
    super.curve,
    super.duration,
    super.constrainsToView,
  }) : _option = option,
       _maxHeightFactor = maxHeightFactor {
    // menu 自行处理 esc 关闭行为
    super.escapeClosable = false;

    // menu 自行管理 open 状态
    _openOptions = ZoSelector();

    if (option == null) {
      _initController(
        ZoOptionController(
          data: options,
          // 强制所有项视为展开，由层自行管理
          expandAll: true,
          selected: selected,
          matchRegexp: matchRegexp,
          matchString: matchString,
          filter: filter,
        ),
      );
    }
  }

  /// 菜单默认宽度
  static double defaultMenuWidth = 240.0;

  /// 选项列表, 设置为当前要显示的子选项
  List<ZoOption> viewOption = [];

  /// 重写为获取显示的选项
  @override
  List<ZoOption> get options => viewOption;

  /// 设置选项时直接设置到 controller 而不是用于内部的 _option
  @override
  set options(List<ZoOption> value) {
    assert(option == null);
    controller.data = value;
    changedAndCloseDescendantMenus();
  }

  /// 通过自定义查询文本筛选选项，具体用法见 [ZoOptionController.matchRegexp]
  @override
  set matchString(String? value) {
    assert(option == null);
    controller.matchString = value;
    changedAndCloseDescendantMenus();
  }

  /// 通过自定义正则筛选选项，具体用法见 [ZoOptionController.matchRegexp]
  @override
  set matchRegexp(RegExp? value) {
    assert(option == null);
    controller.matchRegexp = value;
    changedAndCloseDescendantMenus();
  }

  /// 通过自定义方法筛选选项，具体用法见 [ZoOptionController.filter]
  @override
  set filter(ZoTreeDataFilter<ZoOption>? filter) {
    assert(option == null);
    controller.filter = filter;
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

  /// 最大高度的比例, 设置 [maxHeight] 后此项无效
  double get maxHeightFactor =>
      _maxHeightFactor ?? ZoOptionViewList.defaultHeightFactor;
  double? _maxHeightFactor;
  set maxHeightFactor(double? value) {
    _maxHeightFactor = value;
    changed();
  }

  /// 菜单宽度
  @override
  double get width => _width ?? defaultMenuWidth;

  /// 若子选项未设置宽度，是否继承父级宽度
  bool inheritWidth;

  /// 标记当前层级菜单所有开启子菜单的选项, 它在每个层级的菜单间独立
  ///
  /// 仅作为标记, 组件内部需要负责同步开启状态的菜单与此项一致
  late final ZoSelector<Object, ZoOption> _openOptions;

  /// 父菜单层
  ZoMenu? _parent;

  /// 子菜单层, 同一级的所有选项复用一个层
  ZoMenu? _child;

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
  @protected
  void dispose() {
    _unbindEvents();
    _scrollController.dispose();
    _openChildMenuTimer?.cancel();
    super.dispose();
  }

  @override
  void activeChanged(ZoTriggerToggleEvent event) {
    super.activeChanged(event);
    _childMenuOpenCommonHandler(event);
  }

  @override
  void focusChanged(ZoTriggerToggleEvent event) {
    super.focusChanged(event);
    _childMenuOpenCommonHandler(event);
  }

  @override
  @protected
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
    final List<ZoMenu?> list = [_child, _parent]; // 子项放在前面，优先匹配

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

    for (final opt in viewOption) {
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
    viewOption = controller.getChildren(value: option?.value);
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
    viewOption = controller.getChildren(value: option?.value);
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
    final ZoOptionEventData(:option) = event.data;

    final node = controller.getNode(option.value);

    if (node == null) return;

    onTap?.call(node);

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
  ZoMenu _getTopOverlay() {
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
  List<ZoMenu> _getRelativeOverlay() {
    final List<ZoMenu> parents = [];
    final List<ZoMenu> children = [];

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
  ZoMenu _initOrUpdateChildOverlay(ZoOption option, Rect target) {
    // 子菜单固定使用已经 flip 的方向
    final currentDirection = _parent == null
        ? null
        : positionedRenderObject?.direction;

    final direction = currentDirection ?? ZoPopperDirection.rightTop;

    final fallbackWidth = inheritWidth
        ? _getTopOverlay().width
        : ZoMenu.defaultMenuWidth;

    final width = option.optionsWidth ?? fallbackWidth;

    ZoMenu child;

    if (_child == null) {
      child = ZoMenu(
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
  Widget buildMenus(BuildContext context) {
    return ZoOptionViewList(
      options: options,
      option: option,
      activeCheck: _isActive,
      highlightCheck: _isHighlight,
      size: size,
      maxHeight: maxHeight,
      maxHeightFactor: maxHeightFactor,
      loading: loading || _localLoading,
      scrollController: _scrollController,
      onTap: _onTap,
      onActiveChanged: activeChanged,
      onFocusChanged: focusChanged,
      hasDecoration: false,
    );
  }
}

/// [ZoMenu] 的变体，它通过树组件渲染菜单层
///
/// 另见：
/// - [ZoOverlayEntry]: 菜单控件继承至此类, 可以通过层 api 管理菜单的显示，或是用于更进阶的场景
/// - [ZoOverlay]：进阶的层控制
/// - [ZoSelect]：基于此组件渲染弹出层，但额外添加了用于交互的输入框等
/// - [ZoMenu]：常规的级联菜单
/// - [ZoTree]：内部使用的树形控件
class ZoTreeMenu extends ZoMenuEntry {
  ZoTreeMenu({
    required List<ZoOption> options,
    Iterable<Object>? selected,
    String? matchString,
    RegExp? matchRegexp,
    ZoTreeDataFilter<ZoOption>? filter,
    super.selectionType = ZoSelectionType.none,
    super.branchSelectable = false,
    super.dismissOnSelect = true,
    super.size,
    super.toolbar,
    super.footer,
    super.maxHeight,
    super.width,
    super.loading,
    super.onTap,
    super.onActiveChanged,
    super.onFocusChanged,
    super.groupId,
    // super.builder,
    super.offset,
    super.rect,
    super.alignment,
    // super.route = false,
    // super.barrier = false,
    super.tapAwayClosable,
    super.escapeClosable,
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
    super.direction,
    super.preventOverflow,
    super.transitionType,
    super.animationWrap,
    super.customWrap,
    super.curve,
    super.duration,
    super.constrainsToView,
  }) {
    controller = ZoOptionController(
      data: options,
      expandAll: false,
      selected: selected,
      matchString: matchString,
      matchRegexp: matchRegexp,
      filter: filter,
    );
  }

  /// 菜单默认宽度
  static double defaultWidth = 460.0;

  /// 菜单默认最大高度
  static double defaultMaxHeight = 380.0;

  /// 最大菜单高度
  @override
  double get maxHeight => _maxHeight ?? defaultMaxHeight;

  /// 菜单宽度
  @override
  double get width => _width ?? defaultWidth;

  @protected
  void tapHandle(ZoTreeEvent event) {
    onTap?.call(event.node);

    // 未启用选择关闭或多选模式，无需关闭菜单
    if (!dismissOnSelect || selectionType == ZoSelectionType.multiple) return;

    // 分支节点不可选时阻止关闭
    if (event.node.data.isBranch && !branchSelectable) return;

    dismiss();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  @protected
  Widget buildMenus(BuildContext context) {
    return ZoTree(
      optionController: controller,
      options: options,
      selectionType: selectionType,
      branchSelectable: branchSelectable,
      implicitMultipleSelection: false,
      onTap: tapHandle,
      onActiveChanged: activeChanged,
      onFocusChanged: focusChanged,
      padding: const EdgeInsets.all(0),
      size: size,
      maxHeight: maxHeight,
      matchString: matchString,
      matchRegexp: matchRegexp,
      filter: filter,
      pinedActiveBranch: false,
    );
  }
}

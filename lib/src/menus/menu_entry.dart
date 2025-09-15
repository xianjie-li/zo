import "dart:async";
import "dart:collection";

import "package:flutter/widgets.dart";
import "package:zo/src/menus/option.dart";
import "package:zo/zo.dart";

class ZoMenuEntry extends ZoOverlayEntry {
  ZoMenuEntry({
    List<ZoOption> options = const [],
    ZoOption? option,
    this.selectionType = ZoSelectionType.none,
    this.branchSelectable = false,
    this.dismissOnSelect = true,
    Widget? toolbar,
    double? maxHeight,
    double maxHeightFactor = ZoOptionViewList.defaultHeightFactor,
    double width = ZoMenuEntry.defaultMenuWidth,
    bool loading = false,
    String? matchString,
    RegExp? matchRegexp,
    Selector<Object, ZoOption>? selector,
    this.onTap,
    this.onActiveChanged,
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
    // super.alwaysOnTop,
    // super.mayDismiss,
    // super.onDismiss,
    super.onOpenChanged,
    super.onDelayClosed,
    super.onDispose,
    super.direction = ZoPopperDirection.bottomLeft,
    super.preventOverflow = true,
    super.transitionType,
    super.animationWrap,
    super.curve,
    super.duration = Duration.zero,
  }) : _matchRegexp = matchRegexp,
       _matchString = matchString,
       _option = option,
       _loading = loading,
       _width = width,
       _maxHeightFactor = maxHeightFactor,
       _maxHeight = maxHeight,
       _toolbar = toolbar,
       _options = options {
    this.selector = selector ?? Selector();
    _openOptions = Selector();

    _bindEvents();
  }

  /// 选项列表
  List<ZoOption> get options => _options;
  List<ZoOption> _options;
  set options(List<ZoOption> value) {
    _options = value;
    changedAndCloseDescendantMenus();
  }

  ZoOption? _option;

  /// 菜单对应的选项, 只有子菜单会存在此项, 传入时, 如果 options 没有值, 并且选项包含了 loadOptions
  /// 配置, 会通过 loadOptions 加载选项
  ///
  /// 此选项通常只会由菜单内部为其子菜单设置, 对根菜单无效
  ZoOption? get option => _option;

  set option(ZoOption? value) {
    _option = value;
    changed();
  }

  /// 控制选择类型, 默认为单选
  ZoSelectionType selectionType;

  /// 分支节点是否可选中
  bool branchSelectable;

  /// 单选或未启用选中时, 点击项后是否自动关闭层
  bool dismissOnSelect;

  Widget? _toolbar;

  /// 在顶部渲染工具栏
  Widget? get toolbar => _toolbar;

  set toolbar(Widget? value) {
    _toolbar = value;
    changed();
  }

  double? _maxHeight;

  /// 最大高度, 默认会根据视口尺寸和 [maxHeightFactor] 进行限制
  double? get maxHeight => _maxHeight;

  set maxHeight(double? value) {
    _maxHeight = value;
    changed();
  }

  double _maxHeightFactor;

  /// 最大高度的比例, 设置 [maxHeight] 后此项无效
  double get maxHeightFactor => _maxHeightFactor;

  set maxHeightFactor(double value) {
    _maxHeightFactor = value;
    changed();
  }

  double _width;

  /// 菜单宽度
  double get width => _width;

  set width(double value) {
    _width = value;
    changed();
  }

  bool _loading;

  /// 是否处于加载状态
  bool get loading => _loading;

  set loading(bool value) {
    _loading = value;
    changed();
  }

  String? _matchString;

  /// 用于过滤选项的文本, 传入后只显示包含该文本的选项
  String? get matchString => _matchString;

  set matchString(String? value) {
    _matchString = value;
    changedAndCloseDescendantMenus();
  }

  RegExp? _matchRegexp;

  /// 用于过滤选项的正则, 传入后只显示匹配的选项
  RegExp? get matchRegexp => _matchRegexp;

  set matchRegexp(RegExp? value) {
    _matchRegexp = value;
    changedAndCloseDescendantMenus();
  }

  /// 选项被点击, 若返回一个 future, 可进入loading状态
  dynamic Function(ZoTriggerEvent event)? onTap;

  /// 选项活动状态变更
  /// - 鼠标: 表示位于组件上方
  /// - 触摸设备: 按下触发, 松开或移动时关闭
  ZoTriggerListener<ZoTriggerToggleEvent>? onActiveChanged;

  /// 控制选中的选项
  late final Selector<Object, ZoOption> selector;

  /// 标记所有开启子菜单的选项, 与 [selector] 不同, 它在每个层级的菜单间独立
  ///
  /// 仅作为标记, 组件内部需要负责同步开启状态的菜单与此项一致
  late final Selector<Object, ZoOption> _openOptions;

  /// 菜单默认宽度
  static const defaultMenuWidth = 240.0;

  /// 父菜单层
  ZoMenuEntry? _parent;

  /// 子菜单层, 同一级的所有选项复用一个层
  ZoMenuEntry? _child;

  /// 滚动控制器
  final _scrollController = ScrollController();

  // 控制子菜单延迟开启
  Timer? _openChildMenuTimer;

  /// 异步加载的选项缓存, 以 value 为 key 进行存储
  final HashMap<Object, List<ZoOption>> _asyncOptionCaches = HashMap();

  /// 选项是否正在进行异步加载
  final HashMap<Object, bool> _asyncOptionLoading = HashMap();

  @override
  void dispose() {
    _unbindEvents();
    _scrollController.dispose();
    _openChildMenuTimer?.cancel();
    _asyncOptionCaches.clear();
    _asyncOptionLoading.clear();
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

  /// 通知所有关联菜单层进行更新
  void menusChanged() {
    if (_parent != null) return;
    for (final menu in _getRelativeOverlay()) {
      menu.changed();
    }
  }

  /// 更新当前菜单, 并关闭所有子菜单
  void changedAndCloseDescendantMenus() {
    changed();
    closeDescendantMenus();
  }

  /// 关闭所有子孙菜单
  void closeDescendantMenus() {
    var child = _child;

    while (child != null) {
      if (child.currentOpen) child.close();
      if (child._openOptions.hasSelected()) {
        child._openOptions.unselectAll();
      }

      child = child._child;
    }
  }

  /// 将当前选项组装为完整的树结构返回, 主要用于异步数据的合并
  List<ZoOption> get treeOptions {
    var currentOptions = options.toList();

    if (currentOptions.isEmpty && option != null) {
      final asyncData = _asyncOptionCaches[option!.value];

      if (asyncData != null) {
        currentOptions = asyncData.toList();
      }
    }

    /// 将所有异步获取的选项同步到选项列表
    void syncAsyncOptions(List<ZoOption> list) {
      for (var i = 0; i < list.length; i++) {
        final opt = list[i];

        var optChildren = opt.options;

        // 加载动态选项
        if (optChildren == null || optChildren.isEmpty) {
          final asyncData = _asyncOptionCaches[opt.value];

          if (asyncData != null) {
            optChildren = asyncData.toList();

            list[i] = opt.copyWith(
              options: optChildren,
            );
          }
        }

        if (optChildren != null && optChildren.isNotEmpty) {
          syncAsyncOptions(optChildren);
        }
      }
    }

    syncAsyncOptions(currentOptions);

    return currentOptions;
  }

  /// 获取选中项， 包含子菜单的选中项
  Set<Object> get selected {
    var child = _child;
    final Set<Object> set = selector.getSelected().toSet();

    while (child != null) {
      set.addAll(child.selector.getSelected());
      child = child._child;
    }

    return set;
  }

  /// 获取更完整的选中项信息, 相比 [selected] 它会递归对选项进行获取,
  /// 如果选项总量非常大, 应该避免频繁调用
  ZoOptionSelectedData get selectedData {
    return ZoOptionSelectedData.fromSelected(selected, treeOptions);
  }

  void _bindEvents() {
    selector.addListener(changed);
    _openOptions.addListener(changed);
  }

  void _unbindEvents() {
    selector.removeListener(changed);
    _openOptions.removeListener(changed);
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
      selector.setSelected([option.value]);

      if (dismissOnSelect && !isBranchTouch) {
        _getTopOverlay().dismiss();
      }
    } else {
      selector.toggle(option.value);
    }
  }

  void _onActiveChanged(ZoTriggerToggleEvent event) {
    onActiveChanged?.call(event);

    final ZoOptionEventData(:option, :context) = event.data;

    if (!event.toggle) return;

    if (_openOptions.isSelected(option.value)) return;

    final hasChildren = option.options != null && option.options!.isNotEmpty;
    final hasLoader = option.loadOptions != null;

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

    // 没有子菜单
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

  /// 异步选项加载处理
  void _onOptionsLoad(ZoOptionLoadEvent event) {
    final entry = _getTopOverlay();

    /// 根菜单
    if (entry == this) return;

    final localOption = event.option;

    if (event.loading) {
      entry._asyncOptionLoading[localOption.value] = true;

      /// 仅当前选项仍然活动时更新
      if (localOption == option) {
        changed();
      }

      return;
    }

    if (event.options != null) {
      entry._asyncOptionCaches[localOption.value] = event.options!;
    }

    entry._asyncOptionLoading[localOption.value] = false;

    if (localOption == option) {
      changed();
    }
  }

  /// 初始化或更新子菜单所在的层
  ZoMenuEntry _initOrUpdateChildOverlay(ZoOption option, Rect target) {
    // 子菜单固定使用已经 flip 的方向
    final currentDirection = _parent == null
        ? null
        : positionedRenderObject?.direction;

    final direction = currentDirection ?? ZoPopperDirection.rightTop;

    final width = option.optionsWidth ?? _getTopOverlay().width;

    if (_child == null) {
      _child = ZoMenuEntry(
        rect: target,
        options: option.options ?? [],
        option: option,
        selectionType: selectionType,
        branchSelectable: branchSelectable,
        dismissOnSelect: dismissOnSelect,
        // maxHeight: maxHeight,
        // maxHeightFactor: maxHeightFactor,
        width: width,
        onTap: onTap,
        onActiveChanged: onActiveChanged,
        groupId: groupId,
        direction: direction,
        dismissMode: ZoOverlayDismissMode.close,
        tapAwayClosable: false,
        selector: selector,
      );

      _child!._parent = this;

      return _child!;
    }

    final child = _child!;

    _child!._parent = this;

    child.actions(() {
      child.rect = target;
      child.options = option.options ?? [];
      child.option = option;
      child.selectionType = selectionType;
      child.branchSelectable = branchSelectable;
      child.dismissOnSelect = dismissOnSelect;
      // child.maxHeight = maxHeight;
      // child.maxHeightFactor = maxHeightFactor;
      child.width = width;
      child.onTap = onTap;
      child.onActiveChanged = onActiveChanged;
      child.groupId = groupId;
      child.direction = direction;
    });

    return child;
  }

  @protected
  @override
  Widget overlayBuilder(BuildContext context) {
    final topEntry = _getTopOverlay();

    // 是否正在加载异步选项
    var optionsLoading = false;

    // 已有异步选项缓存
    List<ZoOption>? optionsCache;

    if (option != null) {
      if (topEntry._asyncOptionLoading[option!.value] == true) {
        optionsLoading = true;
      }

      optionsCache = topEntry._asyncOptionCaches[option!.value];
    }

    return SizedBox(
      width: width,
      child: ZoOptionViewList(
        options: optionsCache ?? options,
        option: option,
        activeOptions: selector.getSelected(),
        highlightOptions: _openOptions.getSelected(),
        toolbar: toolbar,
        maxHeight: maxHeight,
        maxHeightFactor: maxHeightFactor,
        loading: optionsLoading || loading,
        matchString: topEntry.matchString,
        matchRegexp: topEntry.matchRegexp,
        scrollController: _scrollController,
        onTap: _onTap,
        onActiveChanged: _onActiveChanged,
        onOptionLoad: _onOptionsLoad,
      ),
    );
  }
}

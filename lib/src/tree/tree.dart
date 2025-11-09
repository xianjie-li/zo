import "dart:collection";
import "dart:math";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";

import "../../zo.dart";
import "../form/form_state.dart";

/// 树形组件
///
/// 表单控件支持：支持 [ZoTree.value] / [ZoTree.onChanged] 进行选项控制，可以方便的集成为表单控件
///
/// 异步选项：只在通过 [ZoTreeState.toggle] / [ZoTreeState.expand] 展开时才会触发异步选项获取，
/// 全部展开等操作不会触发，这是为了避免存在大量异步加载选项时瞬间触发过多的加载请求
class ZoTree extends ZoCustomFormWidget<Iterable<Object>> {
  const ZoTree({
    super.key,
    super.value = const [],
    super.onChanged,
    required this.options,
    this.onOptionsMutation,
    this.selectionType = ZoSelectionType.multiple,
    this.branchSelectable = true,
    this.implicitMultipleSelection = true,
    this.scrollController,
    this.onTap,
    this.onContextAction,
    this.expandByTapRow,
    this.padding = const EdgeInsets.all(8),
    this.maxHeight,
    this.indentSize = const Size(24, 24),
    this.togglerIcon,
    this.leadingBuilder,
    this.trailingBuilder,
    this.empty,
    this.matchString,
    this.caseSensitive = false,
    this.matchRegexp,
    this.filter,
    this.onOptionLoadError,
    this.onFilterComplete,
    this.activeColor,
    this.highlightColor,
    this.expandAll = false,
    this.expandTopLevel = false,
    this.expands = const [],
    this.enable = true,
    this.indentDots = true,
    this.onlyLeafIndentDot = true,
    this.pinedActiveBranch = true,
    this.pinedActiveBranchMaxLevel,
    this.sortable = false,
  });

  /// 树形选项列表
  ///
  /// 避免传入字面量：出于性能考虑，组件会在每次选项变更时做一些预处理，比如缓存树节点关系，
  /// 用于加速后续查询，传入字面量会导致每次build都进行预处理导致更低的性能
  final List<ZoOption> options;

  /// TODO
  /// 选项在组件内部发生了变更, 在回调内将其断言为各种子类后进行处理
  final ValueChanged<ZoOptionMutationAction>? onOptionsMutation;

  /// 控制选择类型, 默认为单选
  final ZoSelectionType selectionType;

  /// 分支节点是否可选中
  final bool branchSelectable;

  /// 常规点击交互时表现得像单选，但是仍然可通过快捷键选中多个节点
  final bool implicitMultipleSelection;

  /// 滚动控制
  final ScrollController? scrollController;

  /// 点击行
  final void Function(ZoTreeEvent event)? onTap;

  /// 行上下文事件
  final void Function(ZoTreeEvent event, ZoTriggerEvent triggerEvent)?
  onContextAction;

  /// 默认情况下，行会在点击后展开，通过此项返回 false, 使其只能通过点击展开图标等操作进行展开
  final bool Function(ZoOptionNode node)? expandByTapRow;

  /// 间距
  final EdgeInsets padding;

  /// 默认情况下组件使用可用的最大高度作为尺寸，在一些场景下，会需要根据内容决定尺寸，此时可通过设置最大高度来实现
  final double? maxHeight;

  /// 宽度控制每一级缩进的尺寸，高度控制展开按钮的尺寸
  final Size indentSize;

  /// 展开图标，需要传入一个指向右侧的标记图标，内部会在展开后指定应用旋转
  final IconData? togglerIcon;

  /// 自定义行开头节点
  final Widget Function(ZoTreeEvent event)? leadingBuilder;

  /// 自定义行结尾节点
  final Widget Function(ZoTreeEvent event)? trailingBuilder;

  /// 自定义空反馈节点
  final Widget? empty;

  /// 用于过滤选项的文本, 设置后只显示包含该文本的选项
  ///
  /// 间接匹配：节点的父级、子级、自身任意一项匹配都会视为匹配
  final String? matchString;

  /// 匹配时是否区分大小写, 仅用于 [matchString], [matchRegexp] 等过滤方式请通过自有参数实现
  final bool caseSensitive;

  /// 用于过滤选项的正则, 设置后只显示匹配的选项
  ///
  /// 间接匹配：节点的父级、子级、自身任意一项匹配都会视为匹配
  final RegExp? matchRegexp;

  /// 自定义筛选器，明细见： [ZoOptionController.filter]
  ///
  /// 避免传入字面量，仅应在筛选条件变更时更新
  ///
  /// 间接匹配：节点的父级、子级、自身任意一项匹配都会视为匹配
  final ZoOptionFilter? filter;

  /// 异步加载选项失败时触发
  final void Function(Object error, [StackTrace? stackTrace])?
  onOptionLoadError;

  /// 在存在筛选条件时，如果存在匹配项, 会在完成筛选后调用此方法进行通知，回调会传入所有严格匹配的选项
  final void Function(List<ZoOptionNode> matchList)? onFilterComplete;

  /// active 状态的背景色
  final Color? activeColor;

  /// highlight 状态的背景色
  final Color? highlightColor;

  /// 初始化时展开所有行
  final bool expandAll;

  /// 初始时展开最层的行
  final bool expandTopLevel;

  /// 指定初始化时要展开的行
  final List<Object> expands;

  /// 设置为 false 可禁止选中、排序等操作
  final bool enable;

  /// 渲染缩进标记 dot
  final bool indentDots;

  /// 只为叶子节点渲染缩进标记 dot
  final bool onlyLeafIndentDot;

  /// 将当前活动分支选项固定在顶部
  final bool pinedActiveBranch;

  /// 控制 [pinedActiveBranch] 可固定的最大层数
  final int? pinedActiveBranchMaxLevel;

  /// 是否可拖动节点进行排序
  final bool sortable;

  @override
  State<ZoTree> createState() => ZoTreeState();
}

class ZoTreeState extends ZoCustomFormState<Iterable<Object>, ZoTree> {
  /// 选项、树形数据等管理
  ZoOptionController get controller => _controller;
  late ZoOptionController _controller;

  /// 控制选中项
  Selector<Object, ZoOption> get selector => controller.selector;

  /// 滚动控制
  ScrollController get scrollController =>
      widget.scrollController ?? _innerScrollController;
  final ScrollController _innerScrollController = ScrollController();

  /// 存储展开项, 防止重新生成 node 树时丢失状态, 为避免冗余的存储，单独提供了 [isExpandAll]
  /// 来记录是否展开全部
  ///
  /// 截止开发时，TreeSliverController 的展开控制api在全部折叠时会出现报错，并且实现上与当前组件有一些不融洽的地方，
  /// 为了方便实现，展开状态由组件自身管理，并代理所有展开操作来实现同步
  ///
  /// [expandSet] 与内部的 TreeSliverNode 可能不是严格同步的
  final HashSet<Object> expandSet = HashSet();

  /// 表示是否已全部展开
  bool? isExpandAll = false;

  /// 树滚动控制器
  final TreeSliverController _treeSliverController = TreeSliverController();

  /// 用于渲染的 TreeSliverNode，会保持与 [widget.options] 同步
  List<TreeSliverNode<Object>> _treeNodes = [];

  /// 在 eachNode 循环时临时存储子项列表列表
  final HashMap<Object, List<TreeSliverNode<Object>>> _childrenMap = HashMap();

  /// 是否处于初始化阶段
  bool _isInit = false;

  /// 是否应强制使用亮色文本、icon
  bool? _useLightText;

  /// 控制active状态应该使用的文本色
  Color? _activeTextColor;

  /// 缓存 focusNode， 用于选项获得焦点
  final HashMap<Object, FocusNode?> _focusNodes = HashMap();

  /// 样式
  ZoStyle? _style;

  /// 如果有值，需要将组件高度设置为该固定尺寸，用于实现 maxHeight
  double? _fixedHeight;

  /// 防止 _fixedHeight 频繁更新
  final _fixedHeightUpdateDebouncer = Debouncer(delay: Durations.short1);

  /// 控制组件容器的焦点
  final FocusNode _focusNode = FocusNode();

  /// 缓存已创建的树节点
  final HashMap<Object, TreeSliverNode<Object>> _nodeCache = HashMap();

  /// 全选操作计数
  int _allSelectActionCount = 0;

  /// 当前聚焦选项的值
  Object? currentFocusValue;

  /// 最后一个通过非批量操作选中的节点的值
  Object? lastSelectedNodeValue;

  /// 缓存的选项滚动偏移信息，不包含不可见选项
  final HashMap<Object, double> _offsetCache = HashMap();

  /// 按选项上下顺序排序的 _offsetCache 值列表，用于从上往下获取选项
  final List<Object> _offsetCacheValueList = [];

  /// 固定在顶部显示的选项
  List<Object> _fixedOptions = [];

  /// 固定选项中高度，由 _fixedOptionBuilder 动态计算
  double _fixedOptionsHeight = 0;

  /// 固定渲染容器上下的间距
  final double _fixedOptionsPadding = 2;

  /// 防止 _fixedOptions 频繁更新
  final _fixedOptionsUpdateDebouncer = Throttler(
    delay: const Duration(milliseconds: 150),
  );

  /// 全选按键
  final allSelectActivator = ZoShortcutsHelper.platformAwareActivator(
    LogicalKeyboardKey.keyA,
    includeRepeats: false,
  );

  /// 左键
  final leftActivator = const SingleActivator(
    LogicalKeyboardKey.arrowLeft,
  );

  /// 右键
  final rightActivator = const SingleActivator(
    LogicalKeyboardKey.arrowRight,
  );

  /// 上键
  final upActivator = const SingleActivator(
    LogicalKeyboardKey.arrowUp,
  );

  /// 下键
  final downActivator = const SingleActivator(
    LogicalKeyboardKey.arrowDown,
  );

  /// 清空选中
  final clearActivator = const SingleActivator(
    LogicalKeyboardKey.escape,
  );

  @override
  @protected
  void initState() {
    super.initState();

    _isInit = true;

    if (widget.expandAll) {
      isExpandAll = true;
    }

    if (widget.expands.isNotEmpty) {
      expandSet.addAll(widget.expands);
    }

    _controller = ZoOptionController(
      options: widget.options,
      selected: widget.value,
      // TreeSliver 自带了隐藏控制，不需要open状态
      ignoreOpenStatus: true,
      matchString: widget.matchString,
      matchRegexp: widget.matchRegexp,
      caseSensitive: widget.caseSensitive,
      filter: widget.filter,
      each: _eachNode,
      eachStart: _eachNodeStart,
      eachEnd: _eachNodeEnd,
      onFilterComplete: _onFilterComplete,
    );

    selector.addListener(_onSelectChanged);
    scrollController.addListener(_onScrollChanged);

    _calcUseLightText();

    _updateFixedHeight();

    _updateOptionOffsetCache();

    _isInit = false;
  }

  @override
  @protected
  void didUpdateWidget(ZoTree oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.options != widget.options) {
      _resetExpand();
      controller.options = widget.options;
      _updateFixedHeight();
    }

    if (oldWidget.matchString != widget.matchString) {
      _resetExpand();
      controller.matchString = widget.matchString;
      _updateFixedHeight();
    }

    if (oldWidget.matchRegexp != widget.matchRegexp) {
      _resetExpand();
      controller.matchRegexp = widget.matchRegexp;
      _updateFixedHeight();
    }

    if (oldWidget.filter != widget.filter) {
      _resetExpand();
      controller.filter = widget.filter;
      _updateFixedHeight();
    }

    if (oldWidget.caseSensitive != widget.caseSensitive) {
      _resetExpand();
      controller.caseSensitive = widget.caseSensitive;
      _updateFixedHeight();
    }

    if (oldWidget.maxHeight != widget.maxHeight) {
      _updateFixedHeight();
    }

    if (oldWidget.activeColor != widget.activeColor) {
      _calcUseLightText();
    }

    if (widget.scrollController != oldWidget.scrollController) {
      scrollController.removeListener(_onScrollChanged);

      if (oldWidget.scrollController != null) {
        oldWidget.scrollController!.removeListener(_onScrollChanged);
      }

      scrollController.addListener(_onScrollChanged);
    }
  }

  @override
  @protected
  dispose() {
    selector.removeListener(_onSelectChanged);
    scrollController.removeListener(_onScrollChanged);
    _controller.dispose();
    _style = null;
    expandSet.clear();
    _fixedOptionsUpdateDebouncer.cancel();
    _innerScrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// 同步value变更到selector
  @override
  @protected
  void onPropValueChanged() {
    selector.setSelected(widget.value ?? []);
  }

  /// 检测是否展开
  bool isExpanded(Object value) {
    final node = _treeSliverController.getNodeFor(value);

    if (node == null) return false;

    return _treeSliverController.isExpanded(node);
  }

  /// 检测节点的所有父节点是否展开
  bool isExpandedAllParents(Object value) {
    final node = controller.getNode(value);

    if (node == null) return false;

    var parent = node.parent;

    while (parent != null) {
      if (!isExpanded(parent.value)) {
        return false;
      }
      parent = parent.parent;
    }

    return true;
  }

  /// 是否已展开所有选项
  ///
  /// 该检测并非完全准确的，在实现上，全部展开是一个单独存储的标记变量，
  /// 这能避免在执行全部展开等操作时存储冗余的选项信息，且不利于持久化存储，[isAllExpanded]
  /// 更多是用来检测最后一次展开操作是否是全部展开
  bool isAllExpanded() {
    return isExpandAll == true;
  }

  /// 展开指定项, 如果父级未展开，会自动将其展开
  void expand(Object value) {
    final node = _treeSliverController.getNodeFor(value);

    if (node == null || node.content == null) return;

    final optNode = controller.getNode(node.content!);

    if (optNode == null) return;

    final List<ZoOption> list = [];

    ZoOptionNode? curNode = optNode;

    while (curNode != null) {
      list.add(curNode.option);

      if (curNode.parent != null) {
        curNode = curNode.parent;
      } else {
        curNode = null;
      }
    }

    /// 倒序展开所有父级，防止 expandNode 报错
    for (var i = list.length - 1; i >= 0; i--) {
      final n = list[i];
      final sNode = _treeSliverController.getNodeFor(n.value);

      if (sNode == null) continue;

      expandSet.add(n.value);
      _treeSliverController.expandNode(sNode);
    }

    _asyncLoadHandler(value);

    isExpandAll = null;
  }

  /// 收起指定项
  void collapse(Object value) {
    final node = _treeSliverController.getNodeFor(value);

    if (node == null) return;

    expandSet.remove(value);
    _treeSliverController.collapseNode(node);

    isExpandAll = null;
  }

  /// 展开\收起指定项, 返回新的展开状态
  bool toggle(Object value) {
    final node = _treeSliverController.getNodeFor(value);

    if (node == null) return false;

    final isExpand = _treeSliverController.isExpanded(node);

    _treeSliverController.toggleNode(node);

    if (isExpand) {
      expandSet.remove(value);
    } else {
      expandSet.add(value);
      _asyncLoadHandler(value);
    }

    isExpandAll = null;

    return !isExpand;
  }

  /// 展开全部
  void expandAll() {
    _treeSliverController.expandAll();

    // 与全部展开独立
    expandSet.clear();
    isExpandAll = true;
  }

  /// 收起全部
  void collapseAll() {
    // _treeSliverController.collapseAll(); 存在报错，先使用自定义实现

    _resetExpand();

    controller.refreshFilters();
  }

  /// 获取所有选择的选项，可用于持久化存储, 仅记录手动展开的项，如果通过 [isAllExpanded] 展开了全部，
  /// 可能需要单独记录该状态
  HashSet<Object> getExpands() {
    return expandSet;
  }

  /// 聚焦指定的选项, 选项未渲染时调用无效
  void focusOption(Object value) {
    final fNode = _focusNodes[value];

    if (fNode == null) return;

    fNode.requestFocus();
  }

  /// 跳转到指定项, 会自动对选项进行展开和聚焦操作
  ///
  /// - [offset] 为调整位置设置一定的偏移，使其不要与顶部刚好对齐
  /// - [animation] 滚动动画
  /// - [autoFocus] 是否自动聚焦跳转到的节点
  /// - [smartScroll] 将选项滚动到最接近的视口边缘，如果选项完全可见则跳过滚动
  void jumpTo(
    Object value, {
    double offset = 12,
    bool animation = false,
    bool autoFocus = true,
    bool smartScroll = true,
  }) {
    final node = controller.getNode(value);

    if (node == null) return;

    // 确保选项的父级已展开
    if (node.parent != null) {
      expand(node.parent!.value);
    }

    final itemTop = _getOptionOffset(value) + widget.padding.top;

    final fixedOptionData = _getOptionFixedOptions(value);

    // 根据选项顶部的固定区域尺寸调整后的offset
    final adjustOffset = offset + fixedOptionData.fixedHeight;

    var position = max(itemTop - adjustOffset, 0.0);

    if (smartScroll) {
      final scrollOffset = scrollController.offset;
      final viewportHeight = scrollController.position.viewportDimension;

      final visibleTop = scrollOffset + fixedOptionData.fixedHeight;
      final visibleBottom = scrollOffset + viewportHeight;

      final itemBottom = itemTop + node.option.height;

      // 是否完全可见
      final isVisible = itemTop >= visibleTop && itemBottom <= visibleBottom;

      if (isVisible) {
        if (autoFocus) {
          WidgetsBinding.instance.addPostFrameCallback((d) {
            // 防止节点是被折叠节点
            if (mounted) {
              focusOption(value);
            }
          });
          setState(() {}); // 防止 addPostFrameCallback 之后没有绘制帧导致无法正常更新
        }
        return;
      } else {
        // 选项在下方时，跳转到底部
        final midLine = scrollOffset + viewportHeight / 2;
        final itemMid = itemTop + node.option.height / 2;

        if (itemMid > midLine) {
          position = max(
            itemTop - viewportHeight + node.option.height + offset,
            0.0,
          );
        }
      }
    }

    if (animation) {
      scrollController
          .animateTo(
            position,
            duration: Durations.short4,
            curve: Curves.bounceOut,
          )
          .whenComplete(() {
            if (autoFocus) {
              focusOption(value);
            }
          });
    } else {
      scrollController.jumpTo(position);

      if (autoFocus) {
        WidgetsBinding.instance.addPostFrameCallback((d) {
          if (mounted) {
            focusOption(value);
          }
        });
      }
    }
  }

  /// 重置展开状态，但不触发刷新操作
  void _resetExpand() {
    isExpandAll = null;
    expandSet.clear();
  }

  /// 更新 _fixedHeight
  void _updateFixedHeight() {
    if (widget.maxHeight == null) {
      _fixedHeight = null;
      return;
    }

    final maxHeight = widget.maxHeight!;

    double contentHeight = widget.padding.top + widget.padding.bottom;

    _eachSliverNodes((sliverNode, optionNode) {
      if (contentHeight > maxHeight) {
        // 计算大于最大高度的内容是多余的，主动阻止它
        return true;
      }

      if (optionNode != null) {
        contentHeight += optionNode.option.height;
      }

      return false;
    });

    final newFixedHeight = min(contentHeight, maxHeight);

    final isChanged = newFixedHeight != _fixedHeight;

    _fixedHeight = newFixedHeight;

    if (isChanged && !_isInit) {
      setState(() {});
    }
  }

  /// 获取指定选项的滚动偏移，需要确保选项父级全部展开后调用
  double _getOptionOffset(Object value) {
    final node = controller.getNode(value);

    assert(node != null);

    double height = 0;

    _eachSliverNodes((sliverNode, optionNode) {
      if (sliverNode.content == value) {
        return true;
      }

      if (optionNode != null) {
        height += optionNode.option.height;
      }

      return false;
    });

    return height;
  }

  /// 递归遍历当前可见的 sliver node 树，若返回true会中断后续的遍历
  void _eachSliverNodes(
    bool Function(TreeSliverNode<Object> sliverNode, ZoOptionNode? optionNode)
    fn,
  ) {
    bool isBreak = false;

    void loop(List<TreeSliverNode<Object>> list) {
      for (var i = 0; i < list.length; i++) {
        final cur = list[i];

        if (isBreak) return;

        final optNode = controller.getNode(cur.content);

        final b = fn(cur, optNode);

        if (b) {
          isBreak = true;
          return;
        }

        if (cur.isExpanded && cur.children.isNotEmpty) {
          loop(cur.children);
        }
      }
    }

    loop(_treeNodes);
  }

  /// 更新selector的选中项到value并进行rerender
  void _onSelectChanged() {
    setState(() {
      value = selector.getSelected();
    });
  }

  /// 循环选项时，同步到当前 [TreeSliverNode] 树
  void _eachNode(ZoOptionEachArgs args) {
    if (!_isInit && controller.selectChangedProcessing) return;

    /// 将扁平倒序循环的树结构还原为 TreeSliverNode 树
    final node = args.node;

    bool isExpanded = false;

    if (isExpandAll == true || expandSet.contains(node.value)) {
      isExpanded = true;
    }

    /// 如果在初始化阶段并启用了展开顶层，将他们写入展开项并展开
    if (!isExpanded && _isInit && widget.expandTopLevel && node.level == 0) {
      isExpanded = true;
      expandSet.add(node.value);
    }

    final treeNode = TreeSliverNode(
      node.value,
      children: _childrenMap[node.value],
      expanded: isExpanded,
    );

    if (node.parent != null) {
      _childrenMap[node.parent!.value] ??= [];
      _childrenMap[node.parent!.value]!.insert(0, treeNode);
    } else {
      _treeNodes.insert(0, treeNode);
    }

    _nodeCache[node.value] = treeNode;
  }

  void _eachNodeStart() {
    if (!_isInit && controller.selectChangedProcessing) return;
    _treeNodes = [];
  }

  void _eachNodeEnd() {
    if (!_isInit && controller.selectChangedProcessing) return;

    _childrenMap.clear();

    if (!_isInit) {
      _updateFixedHeight();
      _updateOptionOffsetCache();
    }

    if (!_isInit) {
      setState(() {});
    }
  }

  /// 对指定的单个节点执行选中行为
  void _selectHandle(ZoOptionNode node) {
    if (!widget.enable) return;

    final isBranch = node.option.isBranch;

    if (widget.selectionType == ZoSelectionType.none) return;

    if (!widget.branchSelectable && isBranch) return;

    if (widget.selectionType == ZoSelectionType.multiple) {
      _multipleSelectHandle(node);
    } else {
      selector.setSelected([node.value]);
    }
  }

  /// 对多选的处理
  void _multipleSelectHandle(ZoOptionNode node) {
    final isSelected = selector.isSelected(node.value);

    if (ZoShortcutsHelper.isSingleKeyPressed &&
        ZoShortcutsHelper.isCommandPressed) {
      selector.toggle(node.value);

      if (!isSelected) {
        lastSelectedNodeValue = node.value;
      }
      return;
    }

    if (ZoShortcutsHelper.isSingleKeyPressed &&
        ZoShortcutsHelper.isShiftPressed &&
        lastSelectedNodeValue != null) {
      selector.setSelected(
        _getRangeVisibleValues(lastSelectedNodeValue!, node.value),
      );
      return;
    }

    if (widget.implicitMultipleSelection) {
      selector.setSelected([node.value]);

      lastSelectedNodeValue = node.value;
    } else {
      selector.toggle(node.value);

      if (!isSelected) {
        lastSelectedNodeValue = node.value;
      }
    }
  }

  /// 获取value1到value2区间的可见选项值
  List<Object> _getRangeVisibleValues(Object value1, Object value2) {
    final values = <Object>[];

    if (value1 == value2) {
      return [value1];
    }

    bool startFlag = false;

    _eachSliverNodes((sliverNode, optionNode) {
      final value = sliverNode.content;

      if (startFlag) {
        values.add(value);
      }

      if (value == value1 || value == value2) {
        values.add(value);

        if (!startFlag) {
          startFlag = true;
        } else {
          return true;
        }
      }

      return false;
    });

    return values;
  }

  /// 根据传入值获取选项应该使用的文本和图标颜色
  Color _getActiveTextColor() {
    final darkStyle = _style!.getSpecifiedTheme(Brightness.dark);
    final lightStyle = _style!.getSpecifiedTheme(Brightness.light);

    // 传入 activeColors 时
    if (_useLightText != null) {
      // 主题和其文本色在语言上是相反的，黑色主题使用亮色文本
      return _useLightText!
          ? darkStyle.titleTextColor
          : lightStyle.titleTextColor;
    }

    // 未传入时，使用的是 primaryColor，固定使用亮色文本
    return darkStyle.titleTextColor;
  }

  /// 构造行节点
  Widget _treeNodeBuilder(
    BuildContext context,
    TreeSliverNode<Object?> node,
    AnimationStyle animationStyle, {
    bool isFixedBuilder = false,
  }) {
    final value = node.content;

    if (value == null) return const SizedBox.shrink();

    final optNode = controller.getNode(value);

    if (optNode == null) return const SizedBox.shrink();

    final option = optNode.option;

    // 是否分支节点
    final isBranch = option.isBranch;

    bool expandByRow = widget.expandByTapRow != null
        ? true
        : widget.expandByTapRow!(optNode);

    // 固定渲染时只能通过折叠按钮展开关闭
    if (isFixedBuilder) {
      expandByRow = false;
    }

    final isSelected =
        widget.selectionType != ZoSelectionType.none &&
        selector.isSelected(value);

    final tEvent = ZoTreeEvent(node: optNode, instance: this);

    return ZoOptionView(
      key: ValueKey(node.content),
      option: optNode.option,
      arrow: false,
      active: isSelected,
      padding: EdgeInsets.symmetric(
        horizontal: _style!.space1,
        vertical: 0,
      ),
      activeColor: widget.activeColor,
      highlightColor: widget.highlightColor,
      loading: controller.isAsyncOptionLoading(value),
      onTap: (event) => _onOptionTap(event, expandByRow),
      onContextAction: _onContextAction,
      onFocusChanged: _onFocusChanged,
      leading: Row(
        spacing: 4,
        children: [
          // 有子级并且未按行展开，渲染交互按钮
          _buildLeadingNode(
            optNode: optNode,
            node: node,
            isFixedBuilder: isFixedBuilder,
            isBranch: isBranch,
            isSelected: isSelected,
            expandByRow: expandByRow,
          ),
          ?option.leading,
          ?widget.leadingBuilder?.call(tEvent),
        ],
      ),
      trailing: widget.trailingBuilder?.call(tEvent),
    );
  }

  /// 构造选项的前置节点
  Widget _buildLeadingNode({
    required ZoOptionNode optNode,
    required TreeSliverNode<Object?> node,
    required bool isFixedBuilder,
    required bool isBranch,
    required bool isSelected,
    required bool expandByRow,
  }) {
    final indentSpaceNumber = isBranch ? node.depth! : node.depth! + 1;

    final leadingNode = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isBranch
          ? () => _onToggleButtonTap(optNode, isFixedBuilder)
          : null,
      child: Row(
        children: [
          for (int i = 0; i < indentSpaceNumber; i++)
            SizedBox.square(
              dimension: widget.indentSize.width,
              key: ValueKey(i),
              child: _identDotBuilder(
                index: i,
                isBranch: isBranch,
                indentSpaceNumber: indentSpaceNumber,
              ),
            ),
          if (isBranch)
            SizedBox(
              key: const ValueKey("__Expand"),
              height: widget.indentSize.height,
              width: widget.indentSize.width,
              child: AnimatedRotation(
                turns: node.isExpanded ? 0.25 : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  widget.togglerIcon ?? Icons.arrow_right_rounded,
                  size: widget.indentSize.height,
                  color: isSelected
                      // 因为嵌入到了 ZoInteractiveBox 中，需要确保颜色与选项文本一致
                      ? _activeTextColor
                      : _style!.textColor,
                ),
              ),
            ),
        ],
      ),
    );

    // 有子级并且未按行展开，渲染交互按钮
    if (isBranch && !expandByRow) {
      return ZoInteractiveBox(
        plain: true,
        child: leadingNode,
      );
    }

    return leadingNode;
  }

  double _treeRowExtentBuilder(
    TreeSliverNode<Object?> node,
    SliverLayoutDimensions dimensions,
  ) {
    if (node.content == null) return 0;
    final optNode = controller.getNode(node.content!)!;
    return optNode.option.height;
  }

  /// 渲染缩进 dot
  Widget? _identDotBuilder({
    required bool isBranch,
    required int index,
    required int indentSpaceNumber,
  }) {
    if (!widget.indentDots) return null;

    final show = widget.onlyLeafIndentDot
        ? !isBranch && index == indentSpaceNumber - 1
        : true;

    if (!show) return null;

    return const Center(
      child: _ZoTreeIndentIndicator(),
    );
  }

  /// 根据 _fixedOptions 构造固定在顶部的选项
  Widget? _fixedOptionBuilder() {
    if (_fixedOptions.isEmpty) return const SizedBox.shrink();

    final List<Widget> ls = [];

    for (var optionValue in _fixedOptions) {
      final node = controller.getNode(optionValue);
      TreeSliverNode<Object?>? sliverNode;
      try {
        // 初始化阶段节点可能还未挂载到控制器，直接跳过即可
        sliverNode = _treeSliverController.getNodeFor(optionValue);
      } catch (e) {
        continue;
      }

      if (node == null || sliverNode == null) continue;

      // 构造选项节点，组件目前固定无动画，如果后续要支持应该需要调整此处
      final fixedNode = ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: node.option.height,
        ),
        child: _treeNodeBuilder(
          context,
          sliverNode,
          AnimationStyle.noAnimation,
          isFixedBuilder: true,
        ),
      );

      ls.add(fixedNode);
    }

    if (ls.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _style?.surfaceColor,
          ),
          padding: EdgeInsets.fromLTRB(
            widget.padding.left,
            _fixedOptionsPadding,
            widget.padding.right,
            _fixedOptionsPadding,
          ),
          height: _fixedOptionsHeight,
          child: Column(
            children: ls,
          ),
        ),
        // 在底部绘制阴影
        Container(
          height: 8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _style!.shadowGradientColors,
            ),
          ),
        ),
      ],
    );
  }

  Widget? _emptyBuilder() {
    if (_treeNodes.isNotEmpty) return null;

    return widget.empty ??
        Center(
          // 防止贴合顶部
          heightFactor: 8,
          child: ZoResult(
            simpleResult: true,
            icon: const Icon(Icons.info_outline),
            title: Text(context.zoLocale.noData),
          ),
        );
  }

  /// 更新 _useLightText 的值
  void _calcUseLightText() {
    if (widget.activeColor == null) {
      _useLightText = null;
      return;
    }

    _useLightText =
        widget.activeColor!.computeLuminance() < lightLuminanceValue;
  }

  /// 接收 FocusNode 的创建并缓存，用于后续聚焦操作，使用这种方式是为了避免大规模的创建 FocusNode 和管理
  bool _onFocusNodeNotification(
    ZoTriggerFocusNodeChangedNotification notification,
  ) {
    if (notification.data is ZoOptionEventData) {
      final data = notification.data as ZoOptionEventData;
      final option = data.option;

      if (notification.active) {
        _focusNodes[option.value] = notification.focusNode;
      } else if (_focusNodes[option.value] == notification.focusNode) {
        // 避免新旧组件挂载顺序不一致导致的错误销毁
        _focusNodes.remove(option.value);
      }
    }
    return false;
  }

  void _onNodeToggle(TreeSliverNode<Object?> node) {
    _fixedHeightUpdateDebouncer.run(() {
      _updateFixedHeight();

      // 展开操作触发情况： _onNodeToggle
      // toggle: true
      // collapseAll: false, 需要单独处理
      // expandAll: true
      _updateOptionOffsetCache();
    });
  }

  void _onOptionTap(ZoTriggerEvent event, bool expandByRow) {
    final node = _getNodeByEvent(event);

    widget.onTap?.call(ZoTreeEvent(node: node, instance: this));

    // 按下特定修饰键时，避免进行展开或收起操作，体验会更好
    final isModifierKeyPressed =
        ZoShortcutsHelper.isCommandPressed || ZoShortcutsHelper.isShiftPressed;

    if (expandByRow && !isModifierKeyPressed) {
      toggle(node.value);
    }

    _selectHandle(node);
  }

  /// 选项前方展开按钮和缩进区域点击
  void _onToggleButtonTap(ZoOptionNode node, bool isFixedBuilder) {
    // 顶部固定选项关闭处理，将滚动位置调整到选项当前位置
    if (isFixedBuilder) {
      collapse(node.value);

      jumpTo(
        node.value,
        offset: 0,
        autoFocus: true,
        smartScroll: false,
      );

      return;
    }

    toggle(node.value);
    focusOption(node.value);
  }

  void _onContextAction(ZoTriggerEvent event) {
    final node = _getNodeByEvent(event);

    widget.onContextAction?.call(
      ZoTreeEvent(node: node, instance: this),
      event,
    );
  }

  void _onFocusChanged(ZoTriggerToggleEvent event) {
    final node = _getNodeByEvent(event);

    if (event.toggle) {
      currentFocusValue = node.value;
    } else {
      currentFocusValue = null;
    }
  }

  ZoOptionNode _getNodeByEvent(ZoTriggerEvent event) {
    final option = (event.data as ZoOptionEventData).option;
    final node = controller.getNode(option.value)!;
    return node;
  }

  /// 执行异步加载操作
  ///
  /// - 展开时，如果有异步选项并且没有已加载数据对其进行加载，展开所有时不触发
  /// - 如果已经在加载过程中则跳过
  /// - 对选项显示加载标识，并在加载完成后自动展开
  /// - 异步加载的数据触发变异事件时，需要携带特殊标记
  void _asyncLoadHandler(Object value) async {
    final optionNode = controller.getNode(value);

    if (optionNode == null) return;

    final option = optionNode.option;

    // 非空时跳过
    if (option.options != null && option.options!.isNotEmpty) return;

    // 不存在异步加载器时跳过
    if (option.loadOptions == null) return;

    // 已经在进行异步加载
    if (controller.isAsyncOptionLoading(value)) return;

    try {
      final future = controller.loadOptions(value);

      // 更新组件以更新选项加载UI
      setState(() {});

      await future;
    } catch (e, stack) {
      widget.onOptionLoadError?.call(e, stack);
    } finally {
      // 刷新组件以更新选项加载UI
      setState(() {});
    }
  }

  /// 筛选完成后，自动滚动到首选项
  void _onFilterComplete(List<ZoOptionNode> matchList) {
    final first = matchList.first;

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      if (mounted) {
        jumpTo(first.value, autoFocus: false);
      }
    });

    widget.onFilterComplete?.call(matchList);
  }

  /// 滚动中触发
  void _onScrollChanged() {
    _fixedOptionsUpdateDebouncer.run(_updateFixedOptions);
  }

  /// 更新要显示的固定项
  void _updateFixedOptions() {
    if (!widget.pinedActiveBranch) {
      if (_fixedOptions.isNotEmpty) {
        setState(() {
          _fixedOptions = [];
          _fixedOptionsHeight = 0;
        });
      }
      return;
    }

    List<Object> newFixedOptions = [];
    double newFixedOptionsHeight = 0;

    for (final optValue in _offsetCacheValueList) {
      // 获取父级和占用的fixed高度
      final (:parents, :fixedHeight, :node) = _getOptionFixedOptions(optValue);

      if (node == null) continue;

      // 展开的选项检测顶部可见性、未展开的检测底部可见性
      final optionOffset = isExpanded(optValue)
          ? _offsetCache[optValue]!
          : _offsetCache[optValue]! + node.option.height;

      final offset = scrollController.position.pixels + fixedHeight;

      if (optionOffset > offset) {
        newFixedOptions = parents;
        newFixedOptionsHeight = fixedHeight;
        break;
      }
    }

    if (!listEquals(newFixedOptions, _fixedOptions)) {
      setState(() {
        _fixedOptions = newFixedOptions;
        _fixedOptionsHeight = newFixedOptionsHeight;
      });
    }
  }

  /// 获取指定选项父级及其占用的顶部固定高度
  ({List<Object> parents, double fixedHeight, ZoOptionNode? node})
  _getOptionFixedOptions(
    Object optionValue,
  ) {
    final node = controller.getNode(optionValue);
    final parents = <Object>[];
    double fixedHeight = _fixedOptionsPadding * 2;

    if (node == null || !widget.pinedActiveBranch) {
      return (parents: parents, fixedHeight: fixedHeight, node: node);
    }

    var parentNode = node.parent;

    while (parentNode != null) {
      if (widget.pinedActiveBranchMaxLevel != null) {
        if (parentNode.level > widget.pinedActiveBranchMaxLevel! - 1) {
          parentNode = parentNode.parent;
          continue;
        }
      }

      parents.insert(0, parentNode.value);
      fixedHeight += parentNode.option.height;

      parentNode = parentNode.parent;
    }

    return (parents: parents, fixedHeight: fixedHeight, node: node);
  }

  /// 更新 [_offsetCache]，应在任何高度、顺序变更后调用
  void _updateOptionOffsetCache() {
    _offsetCache.clear();
    _offsetCacheValueList.clear();

    double offset = widget.padding.top;

    _eachSliverNodes((sliverNode, optionNode) {
      if (optionNode != null) {
        _offsetCache[optionNode.value] = offset;
        _offsetCacheValueList.add(optionNode.value);
        offset += optionNode.option.height;
      }
      return false;
    });

    if (!_isInit) {
      _updateFixedOptions();
    }
  }

  /// 处理按键操作
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    bool isAllSelect = false;

    // 更新全选计数
    if (event is KeyDownEvent) {
      isAllSelect = ZoShortcutsHelper.checkEvent(allSelectActivator, event);

      if (isAllSelect) {
        _allSelectActionCount++;
      } else {
        _allSelectActionCount = 0;
      }
    }

    if (isAllSelect) {
      return _onShortcutsAllSelect();
    } else if (ZoShortcutsHelper.checkEvent(upActivator, event)) {
      return _onShortcutsUp();
    } else if (ZoShortcutsHelper.checkEvent(downActivator, event)) {
      return _onShortcutsDown();
    } else if (ZoShortcutsHelper.checkEvent(leftActivator, event)) {
      return _onShortcutsLeft();
    } else if (ZoShortcutsHelper.checkEvent(rightActivator, event)) {
      return _onShortcutsRight();
    } else if (ZoShortcutsHelper.checkEvent(clearActivator, event)) {
      return _onShortcutsClear();
    }

    return KeyEventResult.ignored;
  }

  /// 全选操作
  ///
  /// 实现目标
  /// 全选操作可重叠，第一次全选当前焦点所在层，下一次选中当前层的父级，依次执行直到根节点为止
  ///
  /// 中断条件
  /// 聚焦节点变更 or 全选按键非连续
  ///
  /// 操作类型：
  /// - 全选：选中当前参照节点所在层的所有节点，下一次操作改为移动到父级
  /// - 移动到父级：移动后，下一次操作改为全选当前层
  KeyEventResult _onShortcutsAllSelect() {
    if (currentFocusValue == null ||
        widget.selectionType != ZoSelectionType.multiple) {
      _allSelectActionCount = 0;
      return KeyEventResult.ignored;
    }

    final focusNode = controller.getNode(currentFocusValue!);

    assert(focusNode != null);

    // 首次全选操作：清空当前所有选中，然后选中当前层所有节点
    if (_allSelectActionCount == 1) {
      final list = controller.getSiblings(focusNode!, false);
      final values = list.map((o) => o.value);

      selector.setSelected(values);

      return KeyEventResult.handled;
    }

    // 除了第一层外，所有层因为存在父级自身和整层的选中，需要占用两个计数
    var moveLevel = (_allSelectActionCount / 2).floor();

    // 当前操作时选中父级自身
    final isParentSelectAction = _allSelectActionCount / 2 % 1 == 0;

    // 计数已超过当前层，跳过
    final isOverflow = moveLevel > focusNode!.level;

    if (isOverflow || moveLevel <= 0) {
      return KeyEventResult.ignored;
    }

    // 查找当前要处理的层对应的父节点
    ZoOptionNode? lastMoveParent = focusNode;

    while (moveLevel > 0) {
      moveLevel--;
      lastMoveParent = lastMoveParent?.parent;
    }

    if (lastMoveParent == null) return KeyEventResult.ignored;

    if (isParentSelectAction) {
      selector.select(lastMoveParent.value);
      return KeyEventResult.handled;
    }

    final list = controller.getSiblings(lastMoveParent, false);

    final values = list.map((o) => o.value);

    selector.selectList(values);

    return KeyEventResult.handled;
  }

  /// 左键操作：收起当前层，如果已经收起，移动焦点到父节点
  KeyEventResult _onShortcutsLeft() {
    if (currentFocusValue == null) return KeyEventResult.ignored;

    if (isExpanded(currentFocusValue!)) {
      collapse(currentFocusValue!);
      return KeyEventResult.handled;
    } else {
      final node = controller.getNode(currentFocusValue!);

      if (node != null && node.parent != null) {
        jumpTo(node.parent!.value);

        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  /// 右键操作：打开选项，如果已打开或者是一个leaf节点，向后移动焦点
  KeyEventResult _onShortcutsRight() {
    if (currentFocusValue == null) return KeyEventResult.ignored;

    final node = controller.getNode(currentFocusValue!);

    if (node == null) return KeyEventResult.ignored;

    final isBranch = node.option.isBranch;
    final isExpand = isExpanded(node.value);

    if (!isBranch || isExpand) {
      final next = controller.getNextNode(
        node,
        filter: (node) => !node.option.enabled,
      );

      if (next != null) {
        jumpTo(next.value);
      }
    } else if (!isExpand) {
      expand(node.value);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// 上键操作：跳转到前一个可见节点，这与默认焦点行为一样，但默认行为有时候调整顺序会有异常，
  /// 且会被顶部固定选项遮挡，改为自行实现
  KeyEventResult _onShortcutsUp() {
    if (currentFocusValue == null) return KeyEventResult.ignored;

    final node = controller.getNode(currentFocusValue!);

    if (node == null) return KeyEventResult.ignored;

    final prev = controller.getPrevNode(
      node,
      filter: (node) =>
          !node.option.enabled ||
          !controller.isVisible(node.value) ||
          !isExpandedAllParents(node.value),
    );

    if (prev == null) return KeyEventResult.ignored;

    jumpTo(prev.value);

    // 反正固定项未更新导致遮挡
    _updateFixedOptions();
    return KeyEventResult.handled;
  }

  // 下键操作：跳转到下一个可见节点，这与默认焦点行为一样，但默认行为有时候调整顺序会有异常，改为自行实现
  KeyEventResult _onShortcutsDown() {
    if (currentFocusValue == null) return KeyEventResult.ignored;

    final node = controller.getNode(currentFocusValue!);

    if (node == null) return KeyEventResult.ignored;

    final next = controller.getNextNode(
      node,
      filter: (node) =>
          !node.option.enabled ||
          !controller.isVisible(node.value) ||
          !isExpandedAllParents(node.value),
    );

    if (next == null) return KeyEventResult.ignored;

    jumpTo(next.value);

    return KeyEventResult.handled;
  }

  /// 清空选中
  KeyEventResult _onShortcutsClear() {
    if (selector.hasSelected()) {
      selector.unselectAll();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  @protected
  Widget build(BuildContext context) {
    _style = context.zoStyle;

    _activeTextColor = _getActiveTextColor();

    return SizedBox(
      height: _treeNodes.isEmpty ? widget.maxHeight : _fixedHeight,
      child: Stack(
        children: [
          NotificationListener<ZoTriggerFocusNodeChangedNotification>(
            onNotification: _onFocusNodeNotification,
            child: Focus(
              focusNode: _focusNode,
              onKeyEvent: _onKeyEvent,
              skipTraversal: true,
              child: CustomScrollView(
                controller: scrollController,
                slivers: <Widget>[
                  SliverPadding(
                    padding: widget.padding,
                    sliver: TreeSliver<Object>(
                      tree: _treeNodes,
                      controller: _treeSliverController,
                      treeNodeBuilder: _treeNodeBuilder,
                      treeRowExtentBuilder: _treeRowExtentBuilder,
                      toggleAnimationStyle: AnimationStyle.noAnimation,
                      indentation: TreeSliverIndentationType.none,
                      onNodeToggle: _onNodeToggle,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // 空反馈节点
          ?_emptyBuilder(),
          // 顶部固定选项
          ?_fixedOptionBuilder(),
        ],
      ),
    );
  }
}

/// 渲染树节点前方的缩进指示点
class _ZoTreeIndentIndicator extends StatelessWidget {
  const _ZoTreeIndentIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 2.4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

/// 用于树组件部分回调的参数，提供了一些有用的上下文信息
class ZoTreeEvent {
  ZoTreeEvent({
    required this.node,
    required this.instance,
  });
  ZoOptionNode node;

  ZoTreeState instance;
}

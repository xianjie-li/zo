import "dart:collection";
import "dart:math";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";
import "package:zo/src/trigger/listenable_notifier.dart";

import "../../zo.dart";

part "base.dart";
part "view.dart";
part "shortcuts.dart";
part "tree_actions.dart";
part "drag_sort.dart";

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
    this.onOptionLoadChanged,
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
    this.draggableDetector,
    this.droppableDetector,
  });

  /// 树形选项列表
  ///
  /// 避免传入字面量：出于性能考虑，组件会在每次选项变更时做一些预处理，比如缓存树节点关系，
  /// 用于加速后续查询，传入字面量会导致每次build都进行预处理导致更低的性能
  final List<ZoOption> options;

  /// TODO
  /// 选项在组件内部发生了变更, [ZoOptionMutationEvent] 包含 [ZoOptionAddOperation]、
  /// [ZoOptionRemoveOperation]、[ZoRowDataMoveOperation] 三个子类，可在内部进行类型判断处理
  ///
  /// 注：异步选项加载成功后不会通过此方法通知，请通过 [onOptionLoadChanged] 接收事件
  final ValueChanged<ZoOptionMutationEvent>? onOptionsMutation;

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

  /// TODO: 废弃 异步加载选项失败时触发
  final void Function(Object error, [StackTrace? stackTrace])?
  onOptionLoadError;

  /// 异步选项加载状态变更时触发，加载中 > 成功 | 失败
  final void Function(ZoOptionLoadEvent event)? onOptionLoadChanged;

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

  /// 在启用 [sortable] 后，额外用于检测选项是否可拖动, 默认所有节点均可拖动
  final bool Function(ZoOptionNode node)? draggableDetector;

  /// 在启用 [sortable] 后，额外用于检测选项是否可放置, 默认所有节点均可放置
  final bool Function(ZoOptionNode node, ZoOptionNode? dragNode)?
  droppableDetector;

  @override
  State<ZoTree> createState() => ZoTreeState();
}

class ZoTreeState extends ZoCustomFormState<Iterable<Object>, ZoTree>
    with
        _TreeBaseMixin,
        _TreeActionsMixin,
        _TreeViewMixin,
        _TreeShortcutsMixin,
        _TreeDragSortMixin {
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

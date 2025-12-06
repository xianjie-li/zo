import "dart:collection";
import "dart:math";

import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:flutter/services.dart";

import "../../zo.dart";

part "base.dart";
part "view.dart";
part "shortcuts.dart";
part "tree_actions.dart";
part "drag_sort.dart";

/// 树形组件，它渲染一组 [ZoOption], 并提供了树控件的几乎所有常用功能，例如缩进展示、展开/折叠、选择、拖拽排序、数据变更、筛选等，
/// 也提供了丰富的自定义渲染接口
///
/// 表单控件支持：支持 [ZoTree.value] / [ZoTree.onChanged] 进行选项控制，可以方便的集成为表单控件
///
/// 操作实例：在一些高级场景中，比如要主动跳转到某个选项、手动控制选中、展开等，
/// 可以获取 [ZoTreeState] 实例并使用其提供的 api 进行操作，以下是一个可能的使用场景：
/// - [ZoTreeState.controller] 选项控制器，提供了对数据进行增删改查的丰富接口、筛选、展开控制等
/// - [ZoTreeState.selector] 手动控制选中项，作为表单控件时通常会通过 [ZoTree.value] / [ZoTree.onChanged] 控制
/// - [ZoTreeState.jumpTo] 和 [ZoTreeState.focusOption] 跳转到指定选项
class ZoTree extends ZoCustomFormWidget<Iterable<Object>> {
  const ZoTree({
    super.key,
    super.value = const [],
    super.onChanged,
    required this.options,
    this.selectionType = ZoSelectionType.multiple,
    this.branchSelectable = true,
    this.implicitMultipleSelection = true,
    this.scrollController,
    this.onTap,
    this.onContextAction,
    this.onMutation,
    this.expandByTapRow,
    this.padding,
    this.size,
    this.maxHeight,
    this.indentSize,
    this.togglerIcon,
    this.leadingBuilder,
    this.trailingBuilder,
    this.headerBuilder,
    this.empty,
    this.matchString,
    this.caseSensitive = false,
    this.matchRegexp,
    this.filter,
    this.onLoadStatusChanged,
    this.onFilterComplete,
    this.activeColor,
    this.highlightColor,
    this.iconTheme,
    this.textStyle,
    this.expandAll = false,
    this.expandTopLevel = false,
    this.expands = const [],
    this.enable = true,
    this.leafDot = true,
    this.indentLine = true,
    this.pinedActiveBranch = true,
    this.pinedActiveBranchMaxLevel,
    this.sortable = false,
    this.onSortConfirm,
    this.smartSortConfirm = true,
    this.draggableDetector,
    this.droppableDetector,
  });

  /// 树形选项列表
  ///
  /// 避免传入字面量：出于性能考虑，组件会在每次选项变更时做一些预处理，比如缓存树节点关系，
  /// 用于加速后续查询，传入字面量会导致每次build都进行预处理导致更低的性能
  final List<ZoOption> options;

  /// 控制选择类型, 默认为单选
  final ZoSelectionType selectionType;

  /// 分支节点是否可选中
  final bool branchSelectable;

  /// 常规点击交互时表现得像单选，但是仍然可通过快捷键选中多个节点
  final bool implicitMultipleSelection;

  /// 滚动控制
  final ScrollController? scrollController;

  /// 点击行触发
  final void Function(ZoTreeEvent event)? onTap;

  /// 行上下文事件
  final void Function(ZoTreeEvent event, ZoTriggerEvent triggerEvent)?
  onContextAction;

  /// 发生变更操作时通过此方法进行通知
  final void Function(ZoMutatorDetails<ZoTreeDataOperation> details)?
  onMutation;

  /// 默认情况下，行会在点击后展开，通过此项返回 false, 使其只能通过点击展开图标等操作进行展开
  final bool Function(ZoTreeDataNode node)? expandByTapRow;

  /// 间距
  final EdgeInsets? padding;

  /// 组件整体尺寸
  final ZoSize? size;

  /// 默认情况下组件使用可用的最大高度作为尺寸，在一些场景下，会需要根据内容决定尺寸，此时可通过设置最大高度来实现
  final double? maxHeight;

  /// 宽度控制每一级缩进的尺寸，高度控制展开按钮的尺寸
  final Size? indentSize;

  /// 展开图标，需要传入一个指向右侧的标记图标，内部会在展开后指定应用旋转
  final IconData? togglerIcon;

  /// 自定义行开头节点
  final Widget Function(ZoTreeEvent event)? leadingBuilder;

  /// 自定义行结尾节点
  final Widget Function(ZoTreeEvent event)? trailingBuilder;

  /// 自定义主文本区域内容结尾节点，优先级低于 [ZoOption.builder]
  final Widget Function(ZoTreeEvent event)? headerBuilder;

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
  final ZoTreeDataFilter<ZoOption>? filter;

  /// 异步加载子选项数据时，每次加载状态变更时调用
  final void Function(ZoTreeDataLoadEvent<ZoOption> event)? onLoadStatusChanged;

  /// 在存在筛选条件时，如果存在匹配项, 会在完成筛选后调用此方法进行通知，回调会传入所有严格匹配的选项
  final void Function(List<ZoTreeDataNode<ZoOption>> matchList)?
  onFilterComplete;

  /// active 状态的背景色
  final Color? activeColor;

  /// highlight 状态的背景色
  final Color? highlightColor;

  /// 调整图标样式
  final IconThemeData? iconTheme;

  /// 文本样式
  final TextStyle? textStyle;

  /// 初始化时展开所有行
  final bool expandAll;

  /// 初始时展开最层的行
  final bool expandTopLevel;

  /// 指定初始化时要展开的行
  final List<Object> expands;

  /// 设置为 false 可禁止选中、排序等操作
  final bool enable;

  /// 在叶子节点左侧显示标记点
  final bool leafDot;

  /// 显示缩进参考线
  final bool indentLine;

  /// 将当前活动分支选项固定在顶部
  final bool pinedActiveBranch;

  /// 控制 [pinedActiveBranch] 可固定的最大层数
  final int? pinedActiveBranchMaxLevel;

  /// 是否可拖动节点进行排序
  final bool sortable;

  /// 拖拽排序触发前调用，用于向用户发起询问操作，以确认是否需要进行实际的拖放操作
  ///
  /// 为了防止确认期间其他变更导致移动数据失效(比如删除了移动节点), 确认期间所有变更会被缓冲，
  /// 并在确认操作完成后才执行，因此必须确保确认操作不会被挂起，否则将导致后续所有操作被拦截
  ///
  ///
  final Future<bool> Function(ZoTreeMoveConfirmArgs args)? onSortConfirm;

  /// 智能判断是否需要使用 onSortConfirm 提示，开启后，以下情况不再触发确认：
  /// - 移动到同父级节点下
  /// - 移动节点总数只有一个（含子级）
  final bool smartSortConfirm;

  /// 在启用 [sortable] 后，额外用于检测选项是否可拖动, 默认所有节点均可拖动
  final bool Function(ZoTreeDataNode<ZoOption> node)? draggableDetector;

  /// 在启用 [sortable] 后，额外用于检测选项是否可放置, 默认所有节点均可放置
  final bool Function(
    ZoTreeDataNode<ZoOption> node,
    ZoTreeDataNode<ZoOption>? dragNode,
  )?
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

    _controller = ZoOptionController(
      data: widget.options,
      selected: widget.value,
      expandAll: widget.expandAll,
      matchString: widget.matchString,
      matchRegexp: widget.matchRegexp,
      caseSensitive: widget.caseSensitive,
      filter: widget.filter,
      onUpdateStart: _onUpdateStart,
      onUpdateEach: _onUpdateEach,
      onUpdateEnd: _onUpdateEnd,
      onFilterCompleted: _onFilterComplete,
      onMutation: widget.onMutation,
      onLoadStatusChanged: widget.onLoadStatusChanged,
    );

    if (widget.expands.isNotEmpty) {
      _controller.expander.setSelected(widget.expands);
    } else if (_tempInitSelected.isNotEmpty) {
      _controller.expander.setSelected(_tempInitSelected);
    }

    selector.addListener(_onSelectChanged);
    _controller.expander.addListener(_onExpandChanged);
    scrollController.addListener(_onScrollChanged);

    _calcUseLightText();

    _isInit = false;
  }

  bool _isFirstChangeDependencies = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final isFirst = _isFirstChangeDependencies;
    _isFirstChangeDependencies = false;

    _style = context.zoStyle;

    _itemIconTheme = IconThemeData(
      size: _style!.getSizedIconSize(widget.size),
    ).merge(widget.iconTheme);
    _itemTextStyle = TextStyle(
      fontSize: _style!.getSizedFontSize(widget.size),
    ).merge(widget.textStyle);

    _padding =
        widget.padding ??
        EdgeInsets.all(
          _style!.getSizedSpace(widget.size),
        );

    _indentSize =
        widget.indentSize ??
        switch (widget.size ?? _style!.widgetSize) {
          ZoSize.small => const Size.square(20),
          ZoSize.medium => const Size.square(22),
          ZoSize.large => const Size.square(28),
        };

    // 这些方法依赖 inherited widget, 需要延迟到这里初始化
    if (isFirst) {
      _isInit = true;
      _updateOptionOffsetCache();
      _updateFixedHeight();
      _isInit = false;
    }
  }

  @override
  @protected
  void didUpdateWidget(ZoTree oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.options != widget.options) {
      _resetExpand();
      controller.data = widget.options;
      _updateFixedHeight(true);
    }

    if (oldWidget.matchString != widget.matchString) {
      _resetExpand();
      controller.matchString = widget.matchString;
      _updateFixedHeight(true);
    }

    if (oldWidget.matchRegexp != widget.matchRegexp) {
      _resetExpand();
      controller.matchRegexp = widget.matchRegexp;
      _updateFixedHeight(true);
    }

    if (oldWidget.filter != widget.filter) {
      _resetExpand();
      controller.filter = widget.filter;
      _updateFixedHeight(true);
    }

    if (oldWidget.caseSensitive != widget.caseSensitive) {
      _resetExpand();
      controller.caseSensitive = widget.caseSensitive;
      _updateFixedHeight(true);
    }

    if (oldWidget.onMutation != widget.onMutation) {
      controller.onMutation = widget.onMutation;
    }

    if (oldWidget.onLoadStatusChanged != widget.onLoadStatusChanged) {
      controller.onLoadStatusChanged = widget.onLoadStatusChanged;
    }

    if (oldWidget.maxHeight != widget.maxHeight) {
      _updateFixedHeight(true);
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
    _controller.expander.removeListener(_onExpandChanged);
    _controller.dispose();
    _style = null;
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

  /// 展开项变更
  void _onExpandChanged() {
    _fixedHeightUpdateDebouncer.run(() {
      _updateFixedHeight();
      _updateOptionOffsetCache();
    });
  }

  void _onUpdateStart() {
    if (_isInit) {
      _tempInitSelected.clear();
    }
  }

  void _onUpdateEach(ZoTreeDataEachArgs args) {
    if (_isInit) {
      if (widget.expandAll) {
        _tempInitSelected.add(args.node.value);
      } else if (widget.expandTopLevel && args.node.level == 0) {
        _tempInitSelected.add(args.node.value);
      }
    }
  }

  /// 每次列表变更时更新组件
  void _onUpdateEnd() {
    if (!_isInit && controller.isSelectChangedRefreshing) return;

    if (!_isInit) {
      _updateFixedHeight();
      _updateOptionOffsetCache();
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
  void _onFilterComplete(List<ZoTreeDataNode<ZoOption>> matchList) {
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
    _activeTextColor = _getActiveTextColor();

    return SizedBox(
      height: controller.filteredFlatList.isEmpty
          ? widget.maxHeight
          : _fixedHeight,
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
                    padding: _padding,
                    sliver: SliverVariedExtentList.builder(
                      itemBuilder: _treeNodeBuilderWithIndex,
                      itemExtentBuilder: _treeRowExtentBuilder,
                      itemCount: controller.filteredFlatList.length,
                      findChildIndexCallback: _findChildIndexCallback,
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

/// 用于树组件部分回调的参数，提供了一些有用的上下文信息
class ZoTreeEvent {
  const ZoTreeEvent({
    required this.node,
    required this.instance,
  });
  final ZoTreeDataNode<ZoOption> node;

  final ZoTreeState instance;
}

/// 移动确认时提供的参数
class ZoTreeMoveConfirmArgs {
  const ZoTreeMoveConfirmArgs({
    required this.from,
    required this.to,
    required this.position,
  });

  /// 移动的节点
  final List<ZoTreeDataNode<ZoOption>> from;

  /// 移动到的节点
  final ZoTreeDataNode<ZoOption> to;

  /// 移动到的位置
  final ZoTreeDataRefPosition position;
}

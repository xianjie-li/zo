import "dart:collection";
import "dart:math";

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";

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
    this.branchSelectable = false,
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
    this.onOptionLoadError,
    this.activeColor,
    this.highlightColor,
    this.expandAll = false,
    this.expandTopLevel = false,
    this.expands = const [],
    this.enable = true,
    this.indentDots = true,
    this.sortable = false,
  });

  /// 树形选项列表
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

  /// 异步加载选项失败时触发
  final void Function(Object error, [StackTrace? stackTrace])?
  onOptionLoadError;

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

  /// 为每个缩进渲染缩进标记
  final bool indentDots;

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

  /// 存储展开项管理, 防止重新生成 node 树时丢失状态, 为避免冗余的存储，单独提供了 [_expandAll]
  /// 来记录是否展开全部
  ///
  /// 截止开发时，TreeSliverController 的展开控制api在全部折叠时会出现报错，并且实现上与当前组件有一些不融洽的地方，
  /// 为了方便实现，展开状态由组件自身管理，并代理所有展开操作来实现同步
  final HashSet<Object> _expandSet = HashSet();

  /// 表示是否已全部展开
  bool? _expandAll = false;

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

  /// 控制组件整体的焦点
  FocusNode _focusNode = FocusNode();

  @override
  @protected
  void initState() {
    super.initState();

    _isInit = true;

    if (widget.expandAll) {
      _expandAll = true;
    }

    if (widget.expands.isNotEmpty) {
      _expandSet.addAll(widget.expands);
    }

    _controller = ZoOptionController(
      options: widget.options,
      selected: widget.value,
      // TreeSliver 自带了隐藏控制，不需要open状态
      ignoreOpenStatus: true,
      each: _eachNode,
      eachStart: _eachNodeStart,
      eachEnd: _eachNodeEnd,
    );

    selector.addListener(_onSelectChanged);

    _calcUseLightText();

    _updateFixedHeight();

    _isInit = false;
  }

  @override
  @protected
  void didUpdateWidget(ZoTree oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.options != widget.options) {
      controller.options = widget.options;
      _updateFixedHeight();
    }

    if (oldWidget.maxHeight != widget.maxHeight) {
      _updateFixedHeight();
    }

    if (oldWidget.activeColor != widget.activeColor) {
      _calcUseLightText();
    }
  }

  @override
  @protected
  dispose() {
    selector.removeListener(_onSelectChanged);
    _controller.dispose();
    _style = null;
    _expandSet.clear();
    _innerScrollController.dispose();
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

  /// 是否已展开所有选项
  ///
  /// 该检测并非完全准确的，在实现上，全部展开是一个单独存储的标记变量，
  /// 这能避免在执行全部展开等操作时存储冗余的选项信息，且不利于持久化存储，[isAllExpanded]
  /// 更多是用来检测最后一次展开操作是否是全部展开
  bool isAllExpanded() {
    return _expandAll == true;
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
        curNode = controller.getNode(curNode.parent!.value);
      } else {
        curNode = null;
      }
    }

    /// 倒序展开所有父级，防止 expandNode 报错
    for (var i = list.length - 1; i >= 0; i--) {
      final n = list[i];
      final sNode = _treeSliverController.getNodeFor(n.value);

      if (sNode == null) continue;

      _expandSet.add(n.value);
      _treeSliverController.expandNode(sNode);
    }

    _asyncLoadHandler(value);

    _expandAll = null;
  }

  /// 收起指定项
  void collapse(Object value) {
    final node = _treeSliverController.getNodeFor(value);

    if (node == null) return;

    _expandSet.remove(value);
    _treeSliverController.collapseNode(node);

    _expandAll = null;
  }

  /// 展开\收起指定项, 返回新的展开状态
  bool toggle(Object value) {
    final node = _treeSliverController.getNodeFor(value);

    if (node == null) return false;

    final isExpand = _treeSliverController.isExpanded(node);

    _treeSliverController.toggleNode(node);

    if (isExpand) {
      _expandSet.remove(value);
    } else {
      _expandSet.add(value);
      _asyncLoadHandler(value);
    }

    _expandAll = null;

    return !isExpand;
  }

  /// 展开全部
  void expandAll() {
    _treeSliverController.expandAll();

    // 与全部展开独立
    _expandSet.clear();
    _expandAll = true;
  }

  /// 收起全部
  void collapseAll() {
    // _treeSliverController.collapseAll(); 存在报错，先使用自定义实现

    _expandAll = null;

    _expandSet.clear();
    controller.refreshFilters();

    // 收起全部时不会触发 _onNodeToggle？
    _fixedHeightUpdateDebouncer.run(_updateFixedHeight);
  }

  /// 获取所有选择的选项，可用于持久化存储, 仅记录手动展开的项，如果通过 [isAllExpanded] 展开了全部，
  /// 可能需要单独记录该状态
  HashSet<Object> getExpands() {
    return _expandSet;
  }

  /// 聚焦指定的选项, 选项未渲染时调用无效
  void focusOption(Object value) {
    final fNode = _focusNodes[value];

    if (fNode == null) return;

    fNode.requestFocus();
  }

  /// 跳转到指定项, 会自动对选项进行展开操作
  ///
  /// - [offset] 为调整位置设置一定的偏移，使其不要与顶部刚好对齐
  /// - [animation] 滚动动画
  /// - [autoFocus] 是否自动聚焦跳转到的节点
  void jumpTo(
    Object value, {
    double offset = 40,
    bool animation = false,
    bool autoFocus = true,
  }) {
    // 确保选项已展开
    expand(value);

    final position = max(_getOptionOffset(value) - offset, 0.0);

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

  /// 缓存已创建的树节点
  final HashMap<Object, TreeSliverNode<Object>> _nodeCache = HashMap();

  /// 循环选项时，同步到当前 [TreeSliverNode] 树
  void _eachNode(ZoOptionEachArgs args) {
    if (!_isInit && controller.selectChangedProcessing) return;

    /// 将扁平倒序循环的树结构还原为 TreeSliverNode 树
    final node = args.node;

    bool isExpanded = false;

    if (_expandAll == true || _expandSet.contains(node.value)) {
      isExpanded = true;
    }

    /// 如果在初始化阶段并启用了展开顶层，将他们写入展开项并展开
    if (!isExpanded && _isInit && widget.expandTopLevel && node.level == 0) {
      isExpanded = true;
      _expandSet.add(node.value);
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
      setState(() {});
    }
  }

  /// 构造选项前方的缩进点
  Widget _builderIndentDots(int number) {
    if (number == 0) return const SizedBox.shrink();
    return Row(
      children: [
        for (int i = 0; i < number; i++)
          SizedBox.square(
            dimension: widget.indentSize.width,
            child: widget.indentDots
                ? const Center(
                    child: _ZoTreeIndentDot(),
                  )
                : null,
          ),
      ],
    );
  }

  /// 对指定的单个节点至少选中行为
  void _selectHandle(ZoOptionNode node) {
    if (!widget.enable) return;

    final isBranch = node.option.isBranch;

    if (widget.selectionType == ZoSelectionType.none) return;

    if (!widget.branchSelectable && isBranch) return;

    if (widget.selectionType == ZoSelectionType.multiple) {
      if (widget.implicitMultipleSelection) {
        selector.setSelected([node.value]);
      } else {
        selector.toggle(node.value);
      }
    } else {
      selector.setSelected([node.value]);
    }
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

  Widget _treeNodeBuilder(
    BuildContext context,
    TreeSliverNode<Object?> node,
    AnimationStyle animationStyle,
  ) {
    final value = node.content;

    if (value == null) return const SizedBox.shrink();

    final optNode = controller.getNode(value);

    if (optNode == null) return const SizedBox.shrink();

    final option = optNode.option;

    // 是否分支节点
    final isBranch = option.isBranch;

    final indentSpaceNumber = isBranch ? node.depth! : node.depth! + 1;

    final expandByRow = widget.expandByTapRow == null
        ? true
        : widget.expandByTapRow!(optNode);

    final isSelected =
        widget.selectionType != ZoSelectionType.none &&
        selector.isSelected(value);

    final leadingNodes = Row(
      children: [
        _builderIndentDots(indentSpaceNumber),
        if (isBranch)
          SizedBox(
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
    );

    final tEvent = ZoTreeEvent(node: optNode, instance: this);

    return ZoOptionView(
      key: ValueKey(node.content),
      option: optNode.option,
      arrow: false,
      active: isSelected,
      padding: EdgeInsets.all(_style!.space1),
      activeColor: widget.activeColor,
      highlightColor: widget.highlightColor,
      loading: controller.isAsyncOptionLoading(value),
      onTap: (event) {
        widget.onTap?.call(tEvent);

        if (expandByRow) {
          toggle(value);
        }

        _selectHandle(optNode);
      },
      onContextAction: (event) {
        widget.onContextAction?.call(tEvent, event);
      },
      leading: Row(
        spacing: 4,
        children: [
          // 有子级并且未按行展开，渲染交互按钮
          isBranch && !expandByRow
              ? ZoInteractiveBox(
                  plain: true,
                  child: leadingNodes,
                  onTap: (event) {
                    toggle(value);
                  },
                )
              : leadingNodes,
          ?option.leading,
          ?widget.leadingBuilder?.call(tEvent),
        ],
      ),
      trailing: widget.trailingBuilder?.call(tEvent),
    );
  }

  double _treeRowExtentBuilder(
    TreeSliverNode<Object?> node,
    SliverLayoutDimensions dimensions,
  ) {
    if (node.content == null) return 0;
    final optNode = controller.getNode(node.content!)!;
    return optNode.option.height;
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

      _focusNodes[option.value] = notification.focusNode;
    }
    return false;
  }

  void _onNodeToggle(TreeSliverNode<Object?> node) {
    _fixedHeightUpdateDebouncer.run(_updateFixedHeight);
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

  /// 筛选：支持传入 match 值、 filter 函数，都可监听变更

  /// 处理按键操作
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    return KeyEventResult.ignored;
  }

  @override
  @protected
  Widget build(BuildContext context) {
    _style = context.zoStyle;

    _activeTextColor = _getActiveTextColor();

    return SizedBox(
      height: _fixedHeight,
      child: NotificationListener<ZoTriggerFocusNodeChangedNotification>(
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
    );
  }
}

/// 渲染树节点前方的缩进指示点
class _ZoTreeIndentDot extends StatefulWidget {
  const _ZoTreeIndentDot({super.key});

  @override
  State<_ZoTreeIndentDot> createState() => _ZoTreeIndentDotState();
}

class _ZoTreeIndentDotState extends State<_ZoTreeIndentDot> {
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

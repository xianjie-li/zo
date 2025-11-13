part of "tree.dart";

/// 基础成员, 它们在不同功能共享
mixin _TreeBaseMixin on ZoCustomFormState<Iterable<Object>, ZoTree> {
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
  /// 截止开发时，TreeSliverController 的展开控制api在全部折叠时会出现报错，并且实现上与当前组件有一些不适配的地方，
  /// 为了方便实现，展开状态由组件自身管理，并代理所有展开操作来实现同步
  ///
  /// [expandSet] 与内部的 TreeSliverNode 可能不是严格同步的
  final HashSet<Object> expandSet = HashSet();

  /// 表示是否已全部展开
  bool? isExpandAll = false;

  /// 当前聚焦选项的值
  Object? currentFocusValue;

  /// 最后一个通过非批量操作选中的节点的值
  Object? lastSelectedNodeValue;

  /// treeSliver 树控制器
  final TreeSliverController _treeSliverController = TreeSliverController();

  /// 用于渲染的 TreeSliverNode，会保持与 [ZoTree.options] 同步
  List<TreeSliverNode<Object>> _treeNodes = [];

  /// 以value为key缓存已创建的树节点
  final HashMap<Object, TreeSliverNode<Object>> _nodeCache = HashMap();

  /// 是否处于初始化阶段
  bool _isInit = false;

  /// 控制组件容器的焦点
  final FocusNode _focusNode = FocusNode();

  /// 在 eachNode 循环时临时存储子项列表列表
  final HashMap<Object, List<TreeSliverNode<Object>>> _childrenMap = HashMap();

  /// 缓存 focusNode， 用于选项获得焦点
  final HashMap<Object, FocusNode?> _focusNodes = HashMap();

  /// 缓存的选项滚动偏移信息，不包含不可见选项
  final HashMap<Object, double> _offsetCache = HashMap();

  /// 按选项上下顺序排序的 _offsetCache 值列表，用于从上往下获取选项
  final List<Object> _offsetCacheValueList = [];

  /// 是否应强制使用亮色文本、icon
  bool? _useLightText;

  /// 控制active状态应该使用的文本色
  Color? _activeTextColor;

  /// 样式
  ZoStyle? _style;

  /// 如果有值，需要将组件高度设置为该固定尺寸，用于实现 maxHeight
  double? _fixedHeight;

  /// 防止 _fixedHeight 频繁更新
  final _fixedHeightUpdateDebouncer = Debouncer(delay: Durations.short1);

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
}

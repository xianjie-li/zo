part of "tree.dart";

/// 基础成员, 它们在不同功能共享
mixin _TreeBaseMixin on ZoCustomFormState<Iterable<Object>, ZoTree> {
  /// 选项、树形数据等管理
  ZoOptionController get controller => _controller;
  late ZoOptionController _controller;

  /// 控制选中项
  ZoSelector<Object, ZoOption> get selector => controller.selector;

  /// 控制展开项，使用 [controller] 提供的api会更方便
  ZoSelector<Object, ZoOption> get expander => controller.expander;

  /// 变更数据
  ZoMutator<ZoTreeDataOperation> get mutator => controller.mutator;

  /// 滚动控制
  ScrollController get scrollController =>
      widget.scrollController ?? _innerScrollController;
  final ScrollController _innerScrollController = ScrollController();

  /// 当前聚焦选项的值
  Object? currentFocusValue;

  /// 最后一个通过非批量操作选中的节点的值
  Object? lastSelectedNodeValue;

  /// 是否处于初始化阶段
  bool _isInit = false;

  /// 初始化完成后，如果存在值，将其设置为选中项
  final HashSet<Object> _tempInitSelected = HashSet();

  /// 控制组件容器的焦点
  final FocusNode _focusNode = FocusNode();

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

  /// 预构建的图标样式，在列表项中使用，目的是减少构造次数
  IconThemeData? _itemIconTheme;

  /// 预构建的文本样式，在列表项中使用，目的是减少构造次数
  TextStyle? _itemTextStyle;

  /// 容器内边距, 根据参数和主题等动态计算得到
  late EdgeInsets _padding;

  /// 缩进尺寸，根据参数和主题等动态计算得到
  late Size _indentSize;

  /// 获取指定选项的滚动偏移，需要确保选项父级全部展开后调用
  double _getOptionOffset(Object value) {
    final node = controller.getNode(value);

    assert(node != null);

    double height = 0;

    final defaultHeight = _style!.getSizedExtent(widget.size);

    for (final option in controller.filteredFlatList) {
      if (option.value == value) {
        break;
      }

      height += option.height ?? defaultHeight;
    }

    return height;
  }

  /// 获取指定选项父级及其占用的顶部固定高度
  ({List<Object> parents, double fixedHeight, ZoTreeDataNode<ZoOption>? node})
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
    final defaultHeight = _style!.getSizedExtent(widget.size);

    while (parentNode != null) {
      if (widget.pinedActiveBranchMaxLevel != null) {
        if (parentNode.level > widget.pinedActiveBranchMaxLevel! - 1) {
          parentNode = parentNode.parent;
          continue;
        }
      }

      parents.insert(0, parentNode.value);
      fixedHeight += parentNode.data.height ?? defaultHeight;

      parentNode = parentNode.parent;
    }

    return (parents: parents, fixedHeight: fixedHeight, node: node);
  }
}

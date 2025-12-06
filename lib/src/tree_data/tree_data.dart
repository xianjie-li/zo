import "dart:async";
import "dart:collection";

import "package:flutter/widgets.dart";
import "package:zo/zo.dart";

part "base.dart";
part "index_path.dart";
part "mutation.dart";
part "node.dart";
part "status.dart";
part "expands.dart";

/// 树形数据管理器，它在初始化节点缓存必要信息，用于后续进行高效的树节点查询，并提供了树数据处理和渲染的很多工具，
/// 比如展开管理、选中管理、筛选、变更操作、异步加载、节点查询方法、用于渲染的平铺列表等
///
/// [ZoTreeDataController] 被设计为数据类型不可知的，需要通过继承该类并通过泛型 [D] 指定数据的类型，
/// 然后实现 [cloneData]、 [getValue]、[getChildrenList] 等方法来适配具体的类型
///
/// 选中和展开管理：传入 selected、expands 控制初始的选中、展开项，通过 [selector] 和 [expander] 管理选中和展开项，
/// 类本身还提供了 [isExpanded] 、[expand] 等便捷api进行展开控制
///
/// 数据筛选：通过 [matchString]、[matchRegexp]、[filter] 之一来筛选要显示的数据
///
/// 数据变更：内部通过 [ZoMutator] 管理变更，你可以使用它来通过操作对数据进行增删、移动,
/// 通过 [onMutation] 可以监听数据的所有变更操作，[mutator] 获取实例，
/// 控制器还提供了 [add]、 [remove]、 [move] 三个简化方法
///
/// 分级更新：由于存在缓存数据，更新操作分为下面三个级别，以减少不必要的性能浪费
/// - [reload] 数据源需要通过外部数据完全替换时使用，此操作会清理所有缓存信息并重载跟数据
/// - [refresh] 数据在内部被可控的更新，比如通过内部 api 新增、删除、排序等，此操作会重新计算节点的关联关系、flatList 等
/// - [update] 重新根据展开、筛选状态更新要展示的列表，关联信息等
///
/// 内部会自动在合适的时机调用对应的更新函数，除非需要自行扩展行为，否则大部分情况无需手动调用这些方法
abstract class ZoTreeDataController<D> {
  ZoTreeDataController({
    required List<D> data,
    Iterable<Object>? selected,
    Iterable<Object>? expands,
    this.expandAll = true,
    String? matchString,
    bool caseSensitive = false,
    RegExp? matchRegexp,
    ZoTreeDataFilter<D>? filter,
    this.onUpdateEach,
    this.onUpdateStart,
    this.onUpdateEnd,
    this.onReloadEach,
    this.onReloadStart,
    this.onReloadEnd,
    this.onRefreshEach,
    this.onRefreshStart,
    this.onRefreshEnd,
    this.onFilterCompleted,
    this.onMutation,
    this.onLoadStatusChanged,
  }) : _matchRegexp = matchRegexp,
       _matchString = matchString,
       _caseSensitive = caseSensitive,
       _filter = filter,
       _data = data {
    selector = ZoSelector(
      selected: selected,
      valueGetter: getValue,
      optionsGetter: () => flatList,
    );

    expander = ZoSelector(
      selected: expands,
      valueGetter: getValue,
      // optionsGetter: () => flatList, 仅分支节点需要，这避免了用户通过全选进行不必要的操作
    );

    mutator = ZoMutator<ZoTreeDataOperation>(
      operationHandle: _operationHandle,
      onMutation: _onMutation,
    );

    // 选中项更新时，更新筛选信息
    selector.addListener(() {
      _selectChangedProcessing = true;
      update();
      _selectChangedProcessing = false;
    });

    // 展开项更新时，更新筛选信息
    expander.addListener(() {
      update();
    });

    reload();
  }

  /// 是否将所有选项视为开启，在不需要管理展开状态的组件中，可以始终保持此项为 true 来确保所有选项都是打开的
  ///
  /// 用户也可以手段管理此项来表示常见的“展开/收起全部”功能，但需要自行调用 [update] 更新列表
  bool expandAll;

  /// 当前是否由于选中项变更而正在执行 [update], 该类型的变更计算只用于处理关联关系计算，
  /// 显示数据的总量和结构没有变更，可以由此来辅助判断是否要跳过某些行为
  bool get isSelectChangedRefreshing => _selectChangedProcessing;
  bool _selectChangedProcessing = false;

  /// 用于过滤数据的文本, 设置后只显示包含该文本的数据
  ///
  /// 间接匹配：节点的父级、子级、自身任意一项匹配都会视为匹配
  String? get matchString => _matchString;
  String? _matchString;
  String? _matchStringLowercase;
  set matchString(String? value) {
    _matchString = value;

    if (_matchString != null) {
      _matchStringLowercase = _matchString!.toLowerCase();
    }

    _matchStatus.clear();
    update();
  }

  /// 匹配时是否区分大小写, 仅用于 [matchString]
  bool get caseSensitive => _caseSensitive;
  bool _caseSensitive;
  set caseSensitive(bool newCaseSensitive) {
    if (_caseSensitive == newCaseSensitive) return;
    _caseSensitive = newCaseSensitive;
    _matchStatus.clear();
    update();
  }

  /// 用于过滤数据的正则, 设置后只显示匹配的数据
  ///
  /// 间接匹配：节点的父级、子级、自身任意一项匹配都会视为匹配
  RegExp? get matchRegexp => _matchRegexp;
  RegExp? _matchRegexp;
  set matchRegexp(RegExp? value) {
    _matchRegexp = value;
    _matchStatus.clear();
    update();
  }

  /// 筛选阶段会对每个符合显示条件的数据调用，可以返回 false 将数据过滤掉,
  /// 可将该方法当做 [matchString] / [matchRegexp] 的扩展版本使用，提供更进一步的筛选能力
  ///
  /// 间接匹配：节点的父级、子级、自身任意一项匹配都会视为匹配
  ///
  /// filter 以数据的实际顺序倒序调用
  ZoTreeDataFilter<D>? get filter => _filter;
  ZoTreeDataFilter<D>? _filter;
  set filter(ZoTreeDataFilter<D>? filter) {
    _filter = filter;
    _matchStatus.clear();
    update();
  }

  /// 未经处理的原始数据，设置后会完全替换当前数据缓存并重载缓存
  List<D> get data => _data;
  List<D> _data;
  set data(List<D> value) {
    _data = value;
    reload();
  }

  /// [data] 的副本，可通过 [add]、[remove]、[move] 等方法进行变更
  List<D> get processedData => _processedData;
  List<D> _processedData = [];

  /// [processedData] 的扁平列表，用于在某些组件中更容易的渲染
  List<D> get flatList => _flatList;
  List<D> _flatList = [];

  /// 通过展开、筛选配置过滤后的 [flatList]，可用于最终渲染
  List<D> get filteredFlatList => _filteredFlatList;
  List<D> _filteredFlatList = [];

  /// 内部通过 [update] 对数据循环处理时，会在循环中对满足显示条件的每个数据调用该方法，
  /// 可以用来做一些外部的数据同步工作，它以实际节点顺序的倒序循环
  ValueChanged<ZoTreeDataEachArgs>? onUpdateEach;

  /// 在 [update] 开始之前调用
  VoidCallback? onUpdateStart;

  /// 在 [update] 结束后调用
  VoidCallback? onUpdateEnd;

  /// 内部通过 [reload] 对数据循环处理时，会在循环中的每个数据调用该方法，
  /// 可以用来做一些外部的数据同步工作
  ValueChanged<ZoTreeDataEachArgs>? onReloadEach;

  /// 在 [reload] 开始之前调用
  VoidCallback? onReloadStart;

  /// 在 [reload] 结束后调用
  VoidCallback? onReloadEnd;

  /// 内部通过 [refresh] 对数据循环处理时，会在循环中的每个数据调用该方法，
  /// 可以用来做一些外部的数据同步工作
  ValueChanged<ZoTreeDataEachArgs>? onRefreshEach;

  /// 在 [refresh] 开始之前调用
  VoidCallback? onRefreshStart;

  /// 在 [refresh] 结束后调用
  VoidCallback? onRefreshEnd;

  /// 在存在筛选条件时，如果存在匹配项, 会在完成筛选后调用此方法进行通知，回调会传入所有严格匹配的数据，
  /// 可以在用来在筛选完成后添加高亮首选项等优化
  ///
  /// 与 [onUpdateEnd] 很相似，但它仅在筛选包含变更时才调用
  ValueChanged<List<ZoTreeDataNode<D>>>? onFilterCompleted;

  /// 发生变更操作时通过此方法进行通知
  void Function(ZoMutatorDetails<ZoTreeDataOperation> details)? onMutation;

  /// 异步加载子选项数据时，每次加载状态变更时调用
  void Function(ZoTreeDataLoadEvent<D> event)? onLoadStatusChanged;

  /// 控制选中项
  late final ZoSelector<Object, D> selector;

  /// 控制展开项，通常只在树形组件中使用，Select、Menu 组件的展开行为较轻量，通过组件自身管理更合适
  late final ZoSelector<Object, D> expander;

  /// 数据突变器，管理数据源的变更和通知
  late final ZoMutator<ZoTreeDataOperation> mutator;

  /// 包含被选中子项的分支节点
  final HashMap<Object, bool> _branchesHasSelectedChild = HashMap();

  /// 所有节点
  final HashMap<Object, ZoTreeDataNode<D>> _nodes = HashMap();

  /// 通过字符串化的 [ZoIndexPath] 查询对应节点的 value，用于通过索引快速获取节点
  final HashMap<String, Object> _indexNodes = HashMap();

  /// 筛选结果缓存
  final HashMap<Object, ({bool isOpen, bool isMatch})> _filterCache = HashMap();

  /// 缓存节点 [matchString] / [matchRegexp] / [filter] 的匹配结果
  final HashMap<Object, bool> _matchStatus = HashMap();

  /// 可见性(根据筛选)缓存
  final HashMap<Object, bool> _visibleCache = HashMap();

  /// 异步加载的数据缓存, 以 value 为 key 进行存储
  final HashMap<Object, List<D>> _asyncRowCaches = HashMap();

  /// 数据是否正在进行异步加载及对应的future
  final HashMap<Object, Future> _asyncRowTask = HashMap();

  /// 最后一次筛选使用的筛选参数
  String? _lastMatchString;
  RegExp? _lastMatchRegexp;
  ZoTreeDataFilter<D>? _lastFilter;

  /// 记录 [filteredFlatList] 中所有项的索引, 因为筛选操作是反向处理，对应索引也是是反向的，
  /// 请通过 [getFilteredIndex] 使用，它会自动进行方向处理
  final HashMap<Object, int> _filteredReverseIndex = HashMap();

  // # # # # # # # 数据 D 适配方法 # # # # # # #

  /// 获取传入数据的浅拷贝版本
  @protected
  D cloneData(D data);

  /// 从数据中获取唯一的 value 值
  @protected
  Object getValue(D data);

  /// 从数据中获取用于筛选的字符串
  @protected
  String? getKeyword(D data);

  /// 获取指定数据的子数据
  @protected
  List<D>? getChildrenList(D data);

  /// 设置数据的子数据
  @protected
  void setChildrenList(D data, List<D>? children);

  /// 获取子数据加载器
  @protected
  ZoTreeDataLoader<D>? getDataLoader(D data);

  /// 判断数据是不是分支节点
  @protected
  bool isBranch(D data);

  // # # # # # # # 更新方法 # # # # # # #

  /// 数据源需要通过外部数据完全替换时使用，此操作会清理所有缓存信息并重载跟数据
  void reload() {
    // 清理现有缓存、clone 数据, 同时创建node，生成各 processedData / flatList
    onReloadStart?.call();

    _processedData = [];
    _flatList = [];
    _nodes.clear();
    _indexNodes.clear();

    ZoTreeDataNode<D>? lastNode;

    void loop({
      required List<D> list,
      ZoTreeDataNode<D>? parent,
      required ZoIndexPath path,
    }) {
      final List<D> newList = parent != null ? [] : _processedData;

      for (var i = 0; i < list.length; i++) {
        final rawData = list[i];
        final cloned = cloneData(rawData);

        final ZoIndexPath indexPath = [...path, i];

        final value = getValue(cloned);

        final node = ZoTreeDataNode<D>(
          value: value,
          data: cloned,
          parent: parent,
          level: path.length,
          index: i,
          path: indexPath,
        );

        _indexNodes[ZoIndexPathHelper.stringify(indexPath)] = value;

        node.prev = lastNode;
        lastNode?.next = node;
        lastNode = node;

        newList.add(cloned);
        _flatList.add(cloned);
        _nodes[value] = node;

        reloadEach(
          ZoTreeDataEachArgs<D>(
            index: i,
            data: cloned,
            node: node,
          ),
        );

        // 处理子项
        if (isBranch(cloned)) {
          // 附加异步数据
          if (getChildrenList(cloned) == null) {
            final cacheRows = _asyncRowCaches[value];

            if (cacheRows != null) {
              setChildrenList(cloned, cacheRows);
            }
          }

          final children = getChildrenList(cloned);

          // 递归处理子项
          if (children != null && children.isNotEmpty) {
            loop(
              list: children,
              parent: node,
              path: node.path,
            );
          }
        }
      }

      if (parent != null) {
        setChildrenList(parent.data, newList);
      }
    }

    loop(
      list: data,
      parent: null,
      path: [],
    );

    update();

    onReloadEnd?.call();
  }

  /// 数据在内部被可控的更新，比如通过内部 api 新增、删除、排序等，此操作会重新计算节点的关联关系、flatList 等
  void refresh() {
    onRefreshStart?.call();

    _flatList = [];
    _nodes.clear();
    _indexNodes.clear();

    ZoTreeDataNode<D>? lastNode;

    void loop({
      required List<D> list,
      ZoTreeDataNode<D>? parent,
      required ZoIndexPath path,
    }) {
      for (var i = 0; i < list.length; i++) {
        final curData = list[i];

        final ZoIndexPath indexPath = [...path, i];

        final value = getValue(curData);

        final node = ZoTreeDataNode<D>(
          value: value,
          data: curData,
          parent: parent,
          level: path.length,
          index: i,
          path: indexPath,
        );

        _indexNodes[ZoIndexPathHelper.stringify(indexPath)] = value;

        node.prev = lastNode;
        lastNode?.next = node;
        lastNode = node;

        _flatList.add(curData);
        _nodes[value] = node;

        refreshEach(
          ZoTreeDataEachArgs<D>(
            index: i,
            data: curData,
            node: node,
          ),
        );

        // 处理子项
        if (isBranch(curData)) {
          final children = getChildrenList(curData);

          // 递归处理子项
          if (children != null && children.isNotEmpty) {
            loop(
              list: children,
              parent: node,
              path: node.path,
            );
          }
        }
      }
    }

    loop(
      list: _processedData,
      parent: null,
      path: [],
    );

    update();

    onRefreshEnd?.call();
  }

  /// 重新根据展开、筛选状态更新要展示的列表，关联信息等
  void update() {
    onUpdateStart?.call();

    final List<D> filteredList = [];

    _branchesHasSelectedChild.clear();
    _matchStatus.clear();
    _filterCache.clear();
    _visibleCache.clear();
    _filteredReverseIndex.clear();

    // 记录包含匹配子项的节点
    final HashMap<Object, bool> rowsHasMatchChild = HashMap();

    // 直接匹配的数据
    final List<ZoTreeDataNode<D>> exactMatchNode = [];

    final filterChanged =
        _lastMatchString != matchString ||
        _lastMatchRegexp != matchRegexp ||
        _lastFilter != filter;

    _lastMatchString = matchString;
    _lastMatchRegexp = matchRegexp;
    _lastFilter = filter;

    final needEmitFilterEvent =
        filterChanged &&
        !isSelectChangedRefreshing &&
        onFilterCompleted != null;

    var cacheIndex = 0;

    // 倒序处理每一项，因为父节点会依赖子节点的匹配状态
    for (var i = flatList.length - 1; i >= 0; i--) {
      final curData = flatList[i];
      final value = getValue(curData);
      final node = _nodes[value]!;

      final (:isOpen, :isMatch) = getFilterStatus(node);
      final isSelected = selector.isSelected(node.value);

      var everyParentIsOpen = true;
      var parentHasMatch = false;

      ZoTreeDataNode<D>? parent = node.parent;

      if (isMatch && needEmitFilterEvent) {
        exactMatchNode.insert(0, node);
      }

      // 检测所有父级
      while (parent != null) {
        final parentFilter = getFilterStatus(parent);

        if (!parentFilter.isOpen) {
          everyParentIsOpen = false;
        }

        if (parentFilter.isMatch) {
          parentHasMatch = true;
        }

        if (isMatch) {
          rowsHasMatchChild[parent.value] = true;
        }

        if (isSelected) {
          _branchesHasSelectedChild[parent.value] = true;
        }

        parent = parent.parent;
      }

      final childHasMatch = rowsHasMatchChild[node.value] == true;

      // 所有父级均展开，且父、子、自身任意一项匹配，则节点可见
      final isVisible =
          everyParentIsOpen && (isMatch || parentHasMatch || childHasMatch);

      _visibleCache[node.value] = isVisible;

      if (isVisible) {
        filteredList.insert(0, curData);
        _filteredReverseIndex[value] = cacheIndex;

        cacheIndex++;

        updateEach(
          ZoTreeDataEachArgs<D>(
            index: i,
            data: curData,
            node: node,
          ),
        );
      }
    }

    _filteredFlatList = filteredList;

    if (needEmitFilterEvent && exactMatchNode.isNotEmpty) {
      onFilterCompleted!(exactMatchNode);
    }

    onUpdateEnd?.call();
  }

  // # # # # # # # Hook # # # # # # #

  /// 内部通过 [reload] 对数据循环处理时，会在每个 node 构造完成后调用
  ///
  /// 注意：由于遍历尚未完成，[ZoTreeDataNode.next] 等依赖后续节点或子级遍历结果的属性不可用
  @protected
  void reloadEach(ZoTreeDataEachArgs args) {
    onReloadEach?.call(args);
  }

  /// 内部通过 [update] 对数据循环处理时，会在每个 node 构造完成后调用
  ///
  /// 注意：由于遍历尚未完成，[ZoTreeDataNode.next] 等依赖后续节点或子级遍历结果的属性不可用
  @protected
  void refreshEach(ZoTreeDataEachArgs args) {
    onRefreshEach?.call(args);
  }

  /// 内部通过 [update] 对数据循环处理时，会在循环中对满足显示条件的每个数据调用该方法，
  /// 可以用来做一些外部的数据同步工作，它以实际节点顺序的倒序循环
  @protected
  @mustCallSuper
  void updateEach(ZoTreeDataEachArgs args) {
    onUpdateEach?.call(args);
  }

  /// 销毁对象
  void dispose() {
    _data = [];
    _processedData.clear();
    _flatList.clear();
    _filteredFlatList.clear();
    _branchesHasSelectedChild.clear();
    _matchStatus.clear();
    _nodes.clear();
    _filterCache.clear();
    _visibleCache.clear();
    _asyncRowCaches.clear();
    _asyncRowTask.clear();
    _filteredReverseIndex.clear();
    _indexNodes.clear();

    selector.dispose();
    expander.dispose();
  }
}

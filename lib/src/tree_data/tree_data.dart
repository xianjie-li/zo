import "dart:async";
import "dart:collection";

import "package:flutter/widgets.dart";
import "package:zo/zo.dart";

part "base.dart";
part "index_path.dart";

/// 树形数据管理器，它在初始化节点缓存必要信息，用于后续进行高效的树节点查询，并提供了树数据处理和渲染的很多工具，
/// 比如展开管理、选中管理、筛选、变更操作、异步加载、节点查询方法、用于渲染的平铺列表等
///
/// [ZoTreeDataController] 被设计为数据类型不可知的，需要通过继承该类并通过泛型 [D] 指定数据的类型，
/// 然后实现 [cloneData]、 [getValue]、[getChildrenList] 等方法来适配具体的类型
///
/// 选中和展开管理：传入 selected、expands 控制初始的选中、展开项，通过 [selector] 和 [expander] 管理选中和展开项
///
/// 数据筛选：通过 [matchString]、[matchRegexp]、[filter] 之一来筛选要显示的数据
///
/// 数据变更：内置了一个 [ZoMutator] 实例，你可以使用它来通过操作对数据进行增删、移动,
/// 通过 [onMutation] 可以监听数据的所有变更操作
///
/// 分级更新：由于存在缓存数据，更新操作分为下面三个级别，以减少不必要的性能浪费
/// - [reload] 数据源需要通过外部数据完全替换时使用，此操作会清理所有缓存信息并重载跟数据
/// - [refresh] 数据在内部被可控的更新，比如通过内部 api 新增、删除、排序等，此操作会重新计算节点的关联关系、flatList 等
/// - [update] 重新根据展开、筛选状态更新要展示的列表，关联信息等
///
/// 内部会自动在合适的时机调用对应的更新函数，除非需要自行扩展行为，否则大部分情况无需手动调用这些方法
abstract class ZoTreeDataController<D extends Object> {
  ZoTreeDataController({
    required List<D> data,
    Iterable<Object>? selected,
    Iterable<Object>? expands,
    this.expandAll = true,
    String? matchString,
    bool caseSensitive = false,
    RegExp? matchRegexp,
    ZoTreeDataFilter<D>? filter,
    this.onUpdate,
    this.onUpdateStart,
    this.onUpdateEnd,
    this.onFilterCompleted,
    this.onMutation,
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
      onMutation: onMutation,
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

  /// 内部通过 [update] 对列表循环处理时，会在循环中对满足显示条件的每个数据调用该方法，
  /// 可以用来做一些外部的数据同步工作，它已实际节点顺序的倒序循环
  ValueChanged<ZoTreeDataEachArgs>? onUpdate;

  /// 在 [update] 开始之前调用
  VoidCallback? onUpdateStart;

  /// 在 [update] 结束后调用
  VoidCallback? onUpdateEnd;

  /// 在存在筛选条件时，如果存在匹配项, 会在完成筛选后调用此方法进行通知，回调会传入所有严格匹配的数据，
  /// 可以在用来在筛选完成后添加高亮首选项等优化
  ///
  /// 与 [onUpdateEnd] 很相似，但它仅在筛选包含变更时才调用
  ValueChanged<List<ZoTreeDataNode<D>>>? onFilterCompleted;

  /// 发生变更操作时通过此方法进行通知
  void Function(ZoMutatorDetails<ZoTreeDataOperation> details)? onMutation;

  /// 控制选中项
  late final ZoSelector<Object, D> selector;

  /// 控制展开项，通常只在树形组件中使用，Select、Menu 组件的展开行为较轻量，通过组件自身管理更合适
  late final ZoSelector<Object, D> expander;

  /// 数据突变器，管理数据源的变更和通知
  late final ZoMutator<ZoTreeDataOperation> mutator;

  /// 异步加载子选项数据时，每次加载状态变更时调用
  final asyncLoadTrigger = EventTrigger<ZoTreeDataLoadEvent>();

  /// [data] 的副本，可通过 [mutator] 变更
  List<D> get processedData => _processedData;
  List<D> _processedData = [];

  /// [processedData] 的扁平列表，用于在某些组件中更容易的渲染
  List<D> get flatList => _flatList;
  List<D> _flatList = [];

  /// 通过展开、筛选配置过滤后的 [flatList]，可用于最终渲染
  List<D> get filteredFlatList => _filteredFlatList;
  List<D> _filteredFlatList = [];

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

  /// 获取传入数据的浅拷贝版本
  D cloneData(D data);

  /// 从数据中获取唯一的 value 值
  Object getValue(D data);

  /// 从数据中获取用于筛选的字符串
  String? getKeyword(D data);

  /// 获取指定数据的子数据
  List<D>? getChildrenList(D data);

  /// 设置数据的子数据
  void setChildrenList(D data, List<D>? children);

  /// 获取子数据加载器
  ZoTreeDataLoader<D>? getDataLoader(D data);

  /// 判断数据是不是分支节点
  bool isBranch(D data);

  /// 数据源需要通过外部数据完全替换时使用，此操作会清理所有缓存信息并重载跟数据
  void reload() {
    // 清理现有缓存、clone 数据, 同时创建node，生成各 processedData / flatList

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
  }

  /// 数据在内部被可控的更新，比如通过内部 api 新增、删除、排序等，此操作会重新计算节点的关联关系、flatList 等
  void refresh() {
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
  }

  /// 重新根据展开、筛选状态更新要展示的列表，关联信息等
  void update() {
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

    onUpdateStart?.call();

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

        onUpdate?.call(
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

  /// 加载指定数据的子级, 如果数据已加载过会直接跳过
  Future loadChildren(Object value) async {
    final cache = _asyncRowCaches[value];

    if (cache != null && cache.isNotEmpty) return;

    final node = getNode(value);

    assert(node != null);

    if (node == null) return;

    final task = _asyncRowTask[node.value];

    if (task != null) return task;

    final row = node.data;

    final children = getChildrenList(row);

    if (children != null && children.isNotEmpty) return;

    final loader = getDataLoader(row);

    if (loader == null) return;

    final completer = Completer();

    _asyncRowTask[value] = completer.future;

    asyncLoadTrigger.emit(
      ZoTreeDataLoadEvent<D>(
        data: row,
        loading: true,
      ),
    );

    try {
      final res = await loader(row);

      if (res.isNotEmpty) {
        mutator.mutation(
          ZoMutatorCommand(
            operation: [
              ZoTreeDataAddOperation(
                data: res,
                toValue: value,
                position: ZoTreeDataRefPosition.inside,
              ),
            ],
            source: ZoMutatorSource.server,
          ),
        );

        _asyncRowCaches[value] = res;
      }

      _asyncRowTask.remove(value);

      asyncLoadTrigger.emit(
        ZoTreeDataLoadEvent<D>(
          data: row,
          children: res,
          loading: false,
        ),
      );

      completer.complete();
    } catch (e, stack) {
      _asyncRowTask.remove(value);

      asyncLoadTrigger.emit(
        ZoTreeDataLoadEvent(
          data: row,
          error: e,
          loading: false,
        ),
      );

      completer.completeError(e, stack);
    }

    return completer.future;
  }

  /// 判断指定 node 的 filter 状态，会优先读取缓存
  ({
    bool isOpen,
    bool isMatch,
  })
  getFilterStatus(
    ZoTreeDataNode<D> node,
  ) {
    final cache = _filterCache[node.value];

    if (cache != null) return cache;

    final isOpen = expandAll ? true : expander.isSelected(node.value);

    var isMatch = _matchStatus[node.value];

    if (isMatch == null) {
      isMatch = _isMatch(node.value);
      _matchStatus[node.value] = isMatch;
    }

    final newCache = (isMatch: isMatch, isOpen: isOpen);

    _filterCache[node.value] = newCache;

    return newCache;
  }

  /// 检测数据是否匹配(满足各种filter条件)
  bool isMatch(Object value) {
    return _matchStatus[value] ?? false;
  }

  /// 判断数据是否与 [matchString] / [matchRegexp] / [filter] 匹配
  bool _isMatch(Object value) {
    final node = getNode(value);

    assert(node != null);

    if (filter != null) {
      if (filter!(node!)) return true;
    }

    if (matchString == null && matchRegexp == null) {
      return true;
    }

    final String? text = getKeyword(node!.data);

    // 未获取到文本的数据一律视为不匹配
    if (text == null) return false;

    if (matchString != null) {
      if (!caseSensitive && _matchStringLowercase != null) {
        final lowerCaseText = text.toLowerCase();
        return lowerCaseText.contains(_matchStringLowercase!);
      } else {
        return text.contains(matchString!);
      }
    } else {
      return matchRegexp!.hasMatch(text);
    }
  }

  /// 指定数据是否包含被选中子级
  bool hasSelectedChild(Object value) {
    return _branchesHasSelectedChild[value] ?? false;
  }

  /// 数据是否可见, 即是否在 [filteredFlatList] 列表中
  bool isVisible(Object value) {
    return _visibleCache[value] ?? false;
  }

  /// 是否正在加载异步选项数据
  bool isAsyncLoading(Object value) {
    final task = _asyncRowTask[value];
    return task != null;
  }

  /// 当前是否包含有效的筛选条件（包含展开状态）
  bool hasFilterCondition() {
    return matchString != null ||
        matchRegexp != null ||
        expander.getSelected().isNotEmpty;
  }

  /// 获取特定数据的子项，不传入 [value] 时返回根数据列表，[filtered] 可以控制是否使用过滤后的数据
  List<D> getChildren({
    Object? value,
    bool filtered = true,
  }) {
    List<D> list;

    if (value == null) {
      list = _processedData;
    } else {
      final node = getNode(value);

      assert(node != null);

      D? curData;

      for (var i = 0; i < node!.path.length; i++) {
        final curInd = node.path[i];

        final children = curData == null ? null : getChildrenList(curData);

        final curList = children ?? _processedData;

        curData = curList[curInd];
      }

      list = getChildrenList(curData!) ?? [];
    }

    if (filtered) {
      return list.where((i) => isVisible(getValue(i))).toList();
    }

    return list;
  }

  /// 获取指定数据的节点信息，其中预缓存了一些树节点的有用信息
  ZoTreeDataNode<D>? getNode(Object value) {
    return _nodes[value];
  }

  /// 根据路径索引获取节点信息
  ZoTreeDataNode<D>? getNodeByIndexPath(ZoIndexPath path) {
    final value = _indexNodes[ZoIndexPathHelper.stringify(path)];
    if (value == null) return null;
    return getNode(value);
  }

  /// 获取前一个节点，[filter] 可过滤掉不满足条件的数据
  ZoTreeDataNode<D>? getPrevNode(
    ZoTreeDataNode<D> node, {
    bool Function(ZoTreeDataNode<D> node)? filter,
  }) {
    var curNode = node.prev;

    while (curNode != null) {
      if (filter != null && !filter(curNode)) {
        break;
      } else {
        curNode = curNode.prev;
      }
    }

    return curNode;
  }

  /// 获取后一个节点，[filter] 可过滤掉不满足条件的数据
  ZoTreeDataNode<D>? getNextNode(
    ZoTreeDataNode<D> node, {
    bool Function(ZoTreeDataNode<D> node)? filter,
  }) {
    var curNode = node.next;

    while (curNode != null) {
      if (filter != null && !filter(curNode)) {
        break;
      } else {
        curNode = curNode.next;
      }
    }

    return curNode;
  }

  /// 获取前一个兄弟节点
  ZoTreeDataNode<D>? getPrevSiblingNode(ZoTreeDataNode<D> node) {
    final [...prev, index] = node.path;

    final newPath = [...prev, index - 1];

    return getNodeByIndexPath(newPath);
  }

  /// 获取后一个兄弟节点
  ZoTreeDataNode<D>? getNextSiblingNode(ZoTreeDataNode<D> node) {
    final [...prev, index] = node.path;

    final newPath = [...prev, index + 1];

    return getNodeByIndexPath(newPath);
  }

  /// 获取所有兄弟节点
  List<D> getSiblings(
    ZoTreeDataNode<D> node, [
    bool filtered = false,
  ]) {
    List<D> list = [];

    if (node.level == 0) {
      list = _processedData;
    } else if (node.parent != null) {
      list = getChildrenList(node.parent!.data) ?? [];
    }

    if (!filtered) {
      return list;
    }

    return list.where((o) {
      return isVisible(getValue(o));
    }).toList();
  }

  /// 获取选项在 [filteredFlatList] 中的索引, 选项不可见时返回 null
  int? getFilteredIndex(Object value) {
    final reverseIndex = _filteredReverseIndex[value];
    if (reverseIndex == null) return null;
    return _filteredFlatList.length - 1 - reverseIndex;
  }

  /// 实现 [ZoMutatorOperationHandle]
  List<ZoTreeDataOperation>? _operationHandle(
    ZoTreeDataOperation operation,
    ZoMutatorCommand<ZoTreeDataOperation> command,
  ) {
    if (operation is ZoTreeDataAddOperation<D>) {
      return _operationAddHandle(operation, command);
    }

    if (operation is TreeDataRemoveOperation) {
      return _operationRemoveHandle(operation, command).reverseOperation;
    }

    if (operation is TreeDataMoveOperation) {
      return _operationMoveHandle(operation, command);
    }

    throw ZoException("Unknown operation type ${operation.runtimeType}");
  }

  /// 实现 [ZoMutatorOperationHandle] 的新增操作
  List<ZoTreeDataOperation>? _operationAddHandle(
    ZoTreeDataAddOperation<D> operation,
    ZoMutatorCommand<ZoTreeDataOperation> command,
  ) {
    // 过滤已存在的选项
    final data = operation.data
        .where((i) => getNode(getValue(i)) == null)
        .toList();

    if (data.isEmpty) return null;

    // 首先获取到插入到的目标索引
    ZoIndexPath? indexPath;

    if (operation.toValue == null) {
      if (operation.position == ZoTreeDataRefPosition.after) {
        indexPath = [processedData.length - 1];
      } else {
        indexPath = [0];
      }
    } else {
      indexPath = _getReferenceIndex(
        getNode(operation.toValue!),
        operation.position,
      );
    }

    if (indexPath == null || indexPath.isEmpty) return null;

    // 执行实际的插入过程
    final inserted = _insertOptionsToIndexPath(data, indexPath);

    if (inserted) {
      refresh();
    }

    if (!inserted || command.source != ZoMutatorSource.local) return null;

    // 返回回退操作
    return [
      TreeDataRemoveOperation(
        values: data.map(getValue).toList(),
      ),
    ];
  }

  /// 实现 [ZoMutatorOperationHandle] 的移除操作
  ({
    List<ZoTreeDataOperation>? reverseOperation,
    List<ZoTreeDataNode<D>> removedNodes,
  })
  _operationRemoveHandle(
    TreeDataRemoveOperation operation,
    ZoMutatorCommand<ZoTreeDataOperation> command,
  ) {
    final values = operation.values;

    // 被删除的节点
    final List<ZoTreeDataNode<D>> removedNodes = [];

    if (values.isEmpty) {
      return (reverseOperation: null, removedNodes: removedNodes);
    }

    // 取 values 对应的所有节点的索引路径
    final List<ZoIndexPath> paths = [];

    for (final value in values) {
      final node = getNode(value);
      if (node != null) {
        paths.add(node.path);
      }
    }

    if (paths.isEmpty) {
      return (reverseOperation: null, removedNodes: removedNodes);
    }

    // 去掉重叠节点，因为如果选项的父级也被删除，则子项无需再处理
    final noOverlapsList = ZoIndexPathHelper.removeOverlaps(paths);

    final needReverse = command.source == ZoMutatorSource.local;

    List<ZoTreeDataAddOperation<D>>? reverseOperation;

    if (needReverse) {
      // 按是否连续进行分组
      final consecutiveGroups = ZoIndexPathHelper.groupByConsecutiveSibling(
        noOverlapsList,
      );

      // 反向操作, 按整数逐个新增，并合并相邻兄弟节点为一组操作
      // 在执行删除操作前进行，防止数据错乱
      reverseOperation = _getAddOperationByRemoveGroups(
        consecutiveGroups,
      );
    }

    // 执行删除，反向删除防止影响后续操作
    for (var i = noOverlapsList.length - 1; i >= 0; i--) {
      final path = noOverlapsList[i];
      final node = getNodeByIndexPath(path);

      if (node == null) continue;

      final removed = _removeOptionByIndexPath(path);

      if (removed) {
        removedNodes.insert(0, node);
      }
    }

    refresh();

    return (reverseOperation: reverseOperation, removedNodes: removedNodes);
  }

  /// 实现 [ZoMutatorOperationHandle] 的移动操作
  List<ZoTreeDataOperation>? _operationMoveHandle(
    TreeDataMoveOperation operation,
    ZoMutatorCommand<ZoTreeDataOperation> command,
  ) {
    // 创建移除操作来进行移除
    final removeResult = _operationRemoveHandle(
      TreeDataRemoveOperation(
        values: operation.values,
      ),
      command,
    );

    // 创建新增操作来将其添加到对应位置
    final addReverse = _operationAddHandle(
      ZoTreeDataAddOperation<D>(
        data: removeResult.removedNodes.map((i) => i.data).toList(),
        toValue: operation.toValue,
        position: operation.position,
      ),
      command,
    );

    if (command.source != ZoMutatorSource.local) return null;

    final List<ZoTreeDataOperation> reverseOperations = [
      ...?addReverse,
      ...?removeResult.reverseOperation,
    ];

    if (reverseOperations.isEmpty) return null;

    return reverseOperations;
  }

  /// 获取传入节点指定方向的索引，若不存在有效路径索引，返回 null
  ZoIndexPath? _getReferenceIndex(
    ZoTreeDataNode<D>? node,
    ZoTreeDataRefPosition position,
  ) {
    if (node == null) return null;

    final path = node.path;

    final [...prev, index] = path;

    if (position == ZoTreeDataRefPosition.after) {
      return [...prev, index + 1];
    } else if (position == ZoTreeDataRefPosition.inside) {
      final children = getChildrenList(node.data);

      if (children == null || children.isEmpty) {
        return [...path, 0];
      } else {
        return [...path, children.length];
      }
    } else {
      return [...prev, index];
    }
  }

  /// 将选项插入到 indexPath 指定的位置, 插入失败时会返回 false
  bool _insertOptionsToIndexPath(List<D> datas, ZoIndexPath path) {
    if (path.isEmpty) return false;

    if (path.length == 1) {
      _insertData(path.first, processedData, datas);
      return true;
    }

    final [...prev, index] = path;

    var list = processedData;

    for (var i = 0; i < prev.length; i++) {
      final p = prev[i];

      final currentItem = list.elementAtOrNull(p);

      if (currentItem == null) return false;

      final children = getChildrenList(currentItem);

      if (children == null) {
        setChildrenList(currentItem, []);
      }

      list = getChildrenList(currentItem)!;
    }

    _insertData(index, list, datas);

    return true;
  }

  /// 插入数据到一个数据列表，如果索引超出可用范围会改为插入到尾部
  void _insertData(
    int index,
    List<D> list,
    List<D> newData,
  ) {
    if (index > list.length) {
      list.addAll(newData);
    } else {
      list.insertAll(index, newData);
    }
  }

  /// 删除指定索引路径的节点, 删除失败时会返回 false
  bool _removeOptionByIndexPath(ZoIndexPath path) {
    if (path.isEmpty) return false;

    if (path.length == 1) {
      if (path.first < processedData.length) {
        processedData.removeAt(path.first);
        return true;
      }
      return false;
    }

    final [...prev, index] = path;

    var list = processedData;

    for (var i = 0; i < prev.length; i++) {
      final p = prev[i];

      final currentItem = list.elementAtOrNull(p);

      if (currentItem == null || getChildrenList(currentItem) == null) {
        return false;
      }

      list = getChildrenList(currentItem)!;
    }

    if (list.isEmpty || index >= list.length) return false;

    list.removeAt(index);

    return true;
  }

  /// 使用 [ZoIndexPathHelper.groupByConsecutiveSibling] 分组过的删除项列表创建 [ZoTreeDataAddOperation]
  List<ZoTreeDataAddOperation<D>> _getAddOperationByRemoveGroups(
    List<List<ZoIndexPath>> pathGroups,
  ) {
    final List<ZoTreeDataAddOperation<D>> list = [];

    /// 如果有兄弟参照节点，toValue 取参照节点
    /// 如果没有，取父级
    /// 都没有，添加到根

    for (final group in pathGroups) {
      if (group.isEmpty) continue;

      final nodes = group.map((i) => getNodeByIndexPath(i)!);

      final first = nodes.first;
      final last = nodes.last;

      // 前方的有效参照兄弟节点
      final prevRefNode = getPrevSiblingNode(first);

      // 后方的有效参照兄弟节点
      final nextRefNode = getNextSiblingNode(last);

      final parentRefNode = first.parent;

      // 参照节点
      Object? toValue;
      var position = ZoTreeDataRefPosition.before;

      if (prevRefNode != null) {
        toValue = prevRefNode.value;
        position = ZoTreeDataRefPosition.after;
      } else if (nextRefNode != null) {
        toValue = nextRefNode.value;
        position = ZoTreeDataRefPosition.before;
      } else if (parentRefNode != null) {
        toValue = parentRefNode.value;
        position = ZoTreeDataRefPosition.inside;
      }

      list.add(
        ZoTreeDataAddOperation(
          data: nodes.map((i) => i.data).toList(),
          toValue: toValue,
          position: position,
        ),
      );
    }

    return list;
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

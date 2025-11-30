part of "tree_data.dart";

/// 变更相关方法
extension TreeDataMutationExtension<D> on ZoTreeDataController<D> {
  /// 执行单个新增数据操作的便捷方法，参数说明请参阅 [ZoMutatorCommand]、[ZoTreeDataAddOperation]
  ZoMutatorDetails<ZoTreeDataOperation>? add({
    required List<D> data,
    Object? toValue,
    ZoTreeDataRefPosition position = ZoTreeDataRefPosition.before,
    bool force = false,
    ZoMutatorSource source = ZoMutatorSource.local,
  }) {
    return mutator.mutation(
      ZoMutatorCommand(
        force: force,
        source: source,
        operation: [
          ZoTreeDataAddOperation(
            data: data,
            toValue: toValue,
            position: position,
          ),
        ],
      ),
    );
  }

  /// 执行单个删除数据操作的便捷方法，参数说明请参阅 [ZoMutatorCommand]、[ZoTreeDataRemoveOperation]
  ZoMutatorDetails<ZoTreeDataOperation>? remove({
    required List<Object> values,
    bool force = false,
    ZoMutatorSource source = ZoMutatorSource.local,
  }) {
    return mutator.mutation(
      ZoMutatorCommand(
        force: force,
        source: source,
        operation: [
          ZoTreeDataRemoveOperation(
            values: values,
          ),
        ],
      ),
    );
  }

  /// 执行单个移动数据操作的便捷方法，参数说明请参阅 [ZoMutatorCommand]、[ZoTreeDataMoveOperation]
  ZoMutatorDetails<ZoTreeDataOperation>? move({
    required List<Object> values,
    required Object toValue,
    ZoTreeDataRefPosition position = ZoTreeDataRefPosition.before,
    bool force = false,
    ZoMutatorSource source = ZoMutatorSource.local,
  }) {
    return mutator.mutation(
      ZoMutatorCommand(
        force: force,
        source: source,
        operation: [
          ZoTreeDataMoveOperation(
            values: values,
            toValue: toValue,
            position: position,
          ),
        ],
      ),
    );
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

    onLoadStatusChanged?.call(
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

      onLoadStatusChanged?.call(
        ZoTreeDataLoadEvent<D>(
          data: row,
          children: res,
          loading: false,
        ),
      );

      completer.complete();
    } catch (e, stack) {
      _asyncRowTask.remove(value);

      onLoadStatusChanged?.call(
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

  /// 变更通知
  void _onMutation(ZoMutatorDetails<ZoTreeDataOperation> details) {
    onMutation?.call(details);
  }

  /// 实现 [ZoMutatorOperationHandle]
  List<ZoTreeDataOperation>? _operationHandle(
    ZoTreeDataOperation operation,
    ZoMutatorCommand<ZoTreeDataOperation> command,
  ) {
    if (operation is ZoTreeDataAddOperation<D>) {
      return _operationAddHandle(operation, command);
    }

    if (operation is ZoTreeDataRemoveOperation) {
      return _operationRemoveHandle(operation, command).reverseOperation;
    }

    if (operation is ZoTreeDataMoveOperation) {
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
      ZoTreeDataRemoveOperation(
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
    ZoTreeDataRemoveOperation operation,
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
    ZoTreeDataMoveOperation operation,
    ZoMutatorCommand<ZoTreeDataOperation> command,
  ) {
    // 创建移除操作来进行移除
    final removeResult = _operationRemoveHandle(
      ZoTreeDataRemoveOperation(
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
}

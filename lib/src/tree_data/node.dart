part of "tree_data.dart";

/// 提供节点相关的查询方法
extension ZoTreeDataNodeExtension<D> on ZoTreeDataController<D> {
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
    ZoTreeDataFilter<D>? filter,
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
    ZoTreeDataFilter<D>? filter,
  ]) {
    List<D> list = [];

    if (node.level == 0) {
      list = _processedData;
    } else if (node.parent != null) {
      list = getChildrenList(node.parent!.data) ?? [];
    }

    if (filter == null) {
      return list;
    }

    return list.where((o) {
      return filter(getNode(getValue(o))!);
    }).toList();
  }

  /// 获取数据在 [filteredFlatList] 中的索引, 选项不可见时返回 null
  int? getFilteredIndex(Object value) {
    final reverseIndex = _filteredReverseIndex[value];
    if (reverseIndex == null) return null;
    return _filteredFlatList.length - 1 - reverseIndex;
  }
}

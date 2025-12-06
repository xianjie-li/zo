part of "tree_data.dart";

/// 展开控制相关方法
extension TreeDataExpandsExtension<D> on ZoTreeDataController<D> {
  /// 检测是否展开
  bool isExpanded(Object value) {
    return expander.isSelected(value);
  }

  /// 检测节点的所有父节点是否展开
  bool isExpandedAllParents(Object value) {
    final node = getNode(value);

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

  /// 展开指定项, 如果父级未展开，会自动将其展开
  void expand(Object value) {
    final optNode = getNode(value);

    if (optNode == null) return;

    final List<Object> list = [];

    ZoTreeDataNode<D>? curNode = optNode;

    while (curNode != null) {
      list.add(curNode.value);

      if (curNode.parent != null) {
        curNode = curNode.parent;
      } else {
        curNode = null;
      }
    }

    expandAll = false;
    expander.selectList(list);

    loadChildren(value).catchError((_) {});
  }

  /// 收起指定项
  void collapse(Object value) {
    expandAll = false;
    expander.unselect(value);
  }

  /// 展开/收起指定项, 返回新的展开状态
  bool toggle(Object value) {
    final node = getNode(value);

    if (node == null) return false;

    final isExpand = expander.isSelected(value);

    if (!isExpand) {
      loadChildren(value).catchError((_) {});
    }

    expandAll = false;
    expander.toggle(value);

    return !isExpand;
  }

  /// 展开全部
  void expandsAll() {
    expandAll = true;
    final allValue = flatList.map(getValue);
    expander.setSelected(allValue);
  }

  /// 收起全部
  void collapseAll() {
    expandAll = false;
    expander.batch(expander.unselectAll, false);
    update();
  }

  /// 是否已展开所有选项
  ///
  /// 该检测并非完全准确的，在实现上，全部展开是一个单独存储的标记变量，
  /// 这能避免在执行全部展开等操作时存储冗余的选项信息，更利于持久化存储，[isAllExpanded]
  /// 更多是用来检测最后一次展开操作是否是全部展开
  bool isAllExpanded() {
    return expandAll;
  }

  /// 获取所有选择的选项，可用于持久化存储, 仅记录手动展开的项，如果通过 [isAllExpanded] 展开了全部，
  /// 可能需要单独记录该状态
  HashSet<Object> getExpands() {
    return expander.getSelected();
  }
}

part of "tree_data.dart";

/// 提供节点相关的查询方法
extension ZoTreeDataStatusExtension<D> on ZoTreeDataController<D> {
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

  /// 当前是否包含有效的筛选条件、展开状态
  bool hasFilterCondition() {
    return matchString != null ||
        matchRegexp != null ||
        expander.getSelected().isNotEmpty;
  }
}

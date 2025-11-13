part of "tree.dart";

/// 向外暴露的树视图操作方法,也包含部分内部使用的操作方法
mixin _TreeActionsMixin on ZoCustomFormState<Iterable<Object>, ZoTree>
    implements _TreeBaseMixin {
  /// 检测是否展开
  bool isExpanded(Object value) {
    final node = _treeSliverController.getNodeFor(value);

    if (node == null) return false;

    return _treeSliverController.isExpanded(node);
  }

  /// 检测节点的所有父节点是否展开
  bool isExpandedAllParents(Object value) {
    final node = controller.getNode(value);

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

  /// 是否已展开所有选项
  ///
  /// 该检测并非完全准确的，在实现上，全部展开是一个单独存储的标记变量，
  /// 这能避免在执行全部展开等操作时存储冗余的选项信息，且不利于持久化存储，[isAllExpanded]
  /// 更多是用来检测最后一次展开操作是否是全部展开
  bool isAllExpanded() {
    return isExpandAll == true;
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
        curNode = curNode.parent;
      } else {
        curNode = null;
      }
    }

    /// 倒序展开所有父级，防止 expandNode 报错
    for (var i = list.length - 1; i >= 0; i--) {
      final n = list[i];
      final sNode = _treeSliverController.getNodeFor(n.value);

      if (sNode == null) continue;

      expandSet.add(n.value);
      _treeSliverController.expandNode(sNode);
    }

    _asyncLoadHandler(value);

    isExpandAll = null;
  }

  /// 收起指定项
  void collapse(Object value) {
    final node = _treeSliverController.getNodeFor(value);

    if (node == null) return;

    expandSet.remove(value);
    _treeSliverController.collapseNode(node);

    isExpandAll = null;
  }

  /// 展开\收起指定项, 返回新的展开状态
  bool toggle(Object value) {
    final node = _treeSliverController.getNodeFor(value);

    if (node == null) return false;

    final isExpand = _treeSliverController.isExpanded(node);

    _treeSliverController.toggleNode(node);

    if (isExpand) {
      expandSet.remove(value);
    } else {
      expandSet.add(value);
      _asyncLoadHandler(value);
    }

    isExpandAll = null;

    return !isExpand;
  }

  /// 展开全部
  void expandAll() {
    _treeSliverController.expandAll();

    // 与全部展开独立
    expandSet.clear();
    isExpandAll = true;
  }

  /// 收起全部
  void collapseAll() {
    // _treeSliverController.collapseAll(); 存在报错，先使用自定义实现

    _resetExpand();

    controller.refreshFilters();
  }

  /// 获取所有选择的选项，可用于持久化存储, 仅记录手动展开的项，如果通过 [isAllExpanded] 展开了全部，
  /// 可能需要单独记录该状态
  HashSet<Object> getExpands() {
    return expandSet;
  }

  /// 聚焦指定的选项, 选项未渲染时调用无效
  void focusOption(Object value) {
    final fNode = _focusNodes[value];

    if (fNode == null) return;

    fNode.requestFocus();
  }

  /// 跳转到指定项, 会自动对选项进行展开和聚焦操作
  ///
  /// - [offset] 为跳转位置设置一定的偏移，使其不要与顶部刚好对齐
  /// - [animation] 滚动动画
  /// - [autoFocus] 是否自动聚焦跳转到的节点
  /// - [smartScroll] 将选项滚动到最接近的视口边缘，如果选项完全可见则跳过滚动
  void jumpTo(
    Object value, {
    double offset = 12,
    bool animation = false,
    bool autoFocus = true,
    bool smartScroll = true,
  }) {
    final node = controller.getNode(value);

    if (node == null) return;

    // 确保选项的父级已展开
    if (node.parent != null) {
      expand(node.parent!.value);
    }

    final itemTop = _getOptionOffset(value) + widget.padding.top;

    final fixedOptionData = _getOptionFixedOptions(value);

    // 根据选项顶部的固定区域尺寸调整后的offset
    final adjustOffset = offset + fixedOptionData.fixedHeight;

    var position = max(itemTop - adjustOffset, 0.0);

    if (smartScroll) {
      final scrollOffset = scrollController.offset;
      final viewportHeight = scrollController.position.viewportDimension;

      final visibleTop = scrollOffset + fixedOptionData.fixedHeight;
      final visibleBottom = scrollOffset + viewportHeight;

      final itemBottom = itemTop + node.option.height;

      // 是否完全可见
      final isVisible = itemTop >= visibleTop && itemBottom <= visibleBottom;

      if (isVisible) {
        if (autoFocus) {
          WidgetsBinding.instance.addPostFrameCallback((d) {
            // 防止节点是被折叠节点
            if (mounted) {
              focusOption(value);
            }
          });
          setState(() {}); // 防止 addPostFrameCallback 之后没有绘制帧导致无法正常更新
        }
        return;
      } else {
        // 选项在下方时，跳转到底部
        final midLine = scrollOffset + viewportHeight / 2;
        final itemMid = itemTop + node.option.height / 2;

        if (itemMid > midLine) {
          position = max(
            itemTop - viewportHeight + node.option.height + offset,
            0.0,
          );
        }
      }
    }

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

  /// 重置展开状态，但不触发刷新操作
  void _resetExpand() {
    isExpandAll = null;
    expandSet.clear();
  }

  /// 对指定的单个节点执行选中行为
  void _selectHandle(ZoOptionNode node) {
    if (!widget.enable) return;

    final isBranch = node.option.isBranch;

    if (widget.selectionType == ZoSelectionType.none) return;

    if (!widget.branchSelectable && isBranch) return;

    if (widget.selectionType == ZoSelectionType.multiple) {
      _multipleSelectHandle(node);
    } else {
      selector.setSelected([node.value]);
    }
  }

  /// 对多选的处理
  void _multipleSelectHandle(ZoOptionNode node) {
    final isSelected = selector.isSelected(node.value);

    if (ZoShortcutsHelper.isSingleKeyPressed &&
        ZoShortcutsHelper.isCommandPressed) {
      selector.toggle(node.value);

      if (!isSelected) {
        lastSelectedNodeValue = node.value;
      }
      return;
    }

    if (ZoShortcutsHelper.isSingleKeyPressed &&
        ZoShortcutsHelper.isShiftPressed &&
        lastSelectedNodeValue != null) {
      selector.setSelected(
        _getRangeVisibleValues(lastSelectedNodeValue!, node.value),
      );
      return;
    }

    if (widget.implicitMultipleSelection) {
      selector.setSelected([node.value]);

      lastSelectedNodeValue = node.value;
    } else {
      selector.toggle(node.value);

      if (!isSelected) {
        lastSelectedNodeValue = node.value;
      }
    }
  }

  /// 获取value1到value2区间的可见选项值
  List<Object> _getRangeVisibleValues(Object value1, Object value2) {
    final values = <Object>[];

    if (value1 == value2) {
      return [value1];
    }

    bool startFlag = false;

    _eachSliverNodes((sliverNode, optionNode) {
      final value = sliverNode.content;

      if (startFlag) {
        values.add(value);
      }

      if (value == value1 || value == value2) {
        values.add(value);

        if (!startFlag) {
          startFlag = true;
        } else {
          return true;
        }
      }

      return false;
    });

    return values;
  }
}

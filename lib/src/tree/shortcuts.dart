part of "tree.dart";

/// 快捷键操作
mixin _TreeShortcutsMixin on ZoCustomFormState<Iterable<Object>, ZoTree>
    implements _TreeBaseMixin, _TreeActionsMixin, _TreeViewMixin {
  /// 全选操作计数
  int _allSelectActionCount = 0;

  /// 全选按键
  final allSelectActivator = ZoShortcutsHelper.platformAwareActivator(
    LogicalKeyboardKey.keyA,
    includeRepeats: false,
  );

  /// 左键
  final leftActivator = const SingleActivator(
    LogicalKeyboardKey.arrowLeft,
  );

  /// 右键
  final rightActivator = const SingleActivator(
    LogicalKeyboardKey.arrowRight,
  );

  /// 上键
  final upActivator = const SingleActivator(
    LogicalKeyboardKey.arrowUp,
  );

  /// 下键
  final downActivator = const SingleActivator(
    LogicalKeyboardKey.arrowDown,
  );

  /// 清空选中
  final clearActivator = const SingleActivator(
    LogicalKeyboardKey.escape,
    includeRepeats: false,
  );

  /// 处理按键操作
  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    bool isAllSelect = false;

    // 更新全选计数
    if (event is KeyDownEvent) {
      isAllSelect = ZoShortcutsHelper.checkEvent(allSelectActivator, event);

      if (isAllSelect) {
        _allSelectActionCount++;
      } else {
        _allSelectActionCount = 0;
      }
    }

    if (isAllSelect) {
      return _onShortcutsAllSelect();
    } else if (ZoShortcutsHelper.checkEvent(upActivator, event)) {
      return _onShortcutsUp();
    } else if (ZoShortcutsHelper.checkEvent(downActivator, event)) {
      return _onShortcutsDown();
    } else if (ZoShortcutsHelper.checkEvent(leftActivator, event)) {
      return _onShortcutsLeft();
    } else if (ZoShortcutsHelper.checkEvent(rightActivator, event)) {
      return _onShortcutsRight();
    } else if (ZoShortcutsHelper.checkEvent(clearActivator, event)) {
      return _onShortcutsClear();
    }

    return KeyEventResult.ignored;
  }

  /// 全选操作
  ///
  /// 实现目标
  /// 全选操作可重叠，第一次全选当前焦点所在层，下一次选中当前层的父级，依次执行直到根节点为止
  ///
  /// 中断条件
  /// 聚焦节点变更 or 全选按键非连续
  ///
  /// 操作类型：
  /// - 全选：选中当前参照节点所在层的所有节点，下一次操作改为移动到父级
  /// - 移动到父级：移动后，下一次操作改为全选当前层
  KeyEventResult _onShortcutsAllSelect() {
    if (currentFocusValue == null ||
        widget.selectionType != ZoSelectionType.multiple) {
      _allSelectActionCount = 0;
      return KeyEventResult.ignored;
    }

    final focusNode = controller.getNode(currentFocusValue!);

    assert(focusNode != null);

    // 首次全选操作：清空当前所有选中，然后选中当前层所有节点
    if (_allSelectActionCount == 1) {
      final list = controller.getSiblings(focusNode!, _canSelected);
      final values = list.map((o) => o.value);

      selector.setSelected(values);

      return KeyEventResult.handled;
    }

    // 除了第一层外，所有层因为存在父级自身和整层的选中，需要占用两个计数
    var moveLevel = (_allSelectActionCount / 2).floor();

    // 当前操作时选中父级自身
    final isParentSelectAction = _allSelectActionCount / 2 % 1 == 0;

    // 计数已超过当前层，跳过
    final isOverflow = moveLevel > focusNode!.level;

    if (isOverflow || moveLevel <= 0) {
      return KeyEventResult.ignored;
    }

    // 查找当前要处理的层对应的父节点
    ZoTreeDataNode<ZoOption>? lastMoveParent = focusNode;

    while (moveLevel > 0) {
      moveLevel--;
      lastMoveParent = lastMoveParent?.parent;
    }

    if (lastMoveParent == null) return KeyEventResult.ignored;

    if (isParentSelectAction) {
      selector.select(lastMoveParent.value);
      return KeyEventResult.handled;
    }

    final list = controller.getSiblings(lastMoveParent, _canSelected);

    final values = list.map((o) => o.value);

    selector.selectList(values);

    return KeyEventResult.handled;
  }

  /// 左键操作：收起当前层，如果已经收起，移动焦点到父节点
  KeyEventResult _onShortcutsLeft() {
    if (currentFocusValue == null) return KeyEventResult.ignored;

    if (controller.isExpanded(currentFocusValue!)) {
      controller.collapse(currentFocusValue!);
      return KeyEventResult.handled;
    } else {
      final node = controller.getNode(currentFocusValue!);

      if (node != null && node.parent != null) {
        jumpTo(node.parent!.value);

        return KeyEventResult.handled;
      }
    }

    return KeyEventResult.ignored;
  }

  /// 右键操作：打开选项，如果已打开或者是一个leaf节点，向后移动焦点
  KeyEventResult _onShortcutsRight() {
    if (currentFocusValue == null) return KeyEventResult.ignored;

    final node = controller.getNode(currentFocusValue!);

    if (node == null) return KeyEventResult.ignored;

    final isBranch = node.data.isBranch;
    final isExpand = controller.isExpanded(node.value);

    if (!isBranch || isExpand) {
      final next = controller.getNextNode(
        node,
        filter: (node) => !node.data.enabled,
      );

      if (next != null) {
        jumpTo(next.value);
      }
    } else if (!isExpand) {
      controller.expand(node.value);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  /// 上键操作：跳转到前一个可见节点，这与默认焦点行为一样，但默认行为有时候调整顺序会有异常，
  /// 且会被顶部固定选项遮挡，改为自行实现
  KeyEventResult _onShortcutsUp() {
    if (currentFocusValue == null) return KeyEventResult.ignored;

    final node = controller.getNode(currentFocusValue!);

    if (node == null) return KeyEventResult.ignored;

    final prev = controller.getPrevNode(
      node,
      filter: (node) =>
          !node.data.enabled ||
          !controller.isVisible(node.value) ||
          !controller.isExpandedAllParents(node.value),
    );

    if (prev == null) return KeyEventResult.ignored;

    jumpTo(prev.value);

    // 反正固定项未更新导致遮挡
    _updateFixedOptions();
    return KeyEventResult.handled;
  }

  // 下键操作：跳转到下一个可见节点，这与默认焦点行为一样，但默认行为有时候调整顺序会有异常，改为自行实现
  KeyEventResult _onShortcutsDown() {
    if (currentFocusValue == null) return KeyEventResult.ignored;

    final node = controller.getNode(currentFocusValue!);

    if (node == null) return KeyEventResult.ignored;

    final next = controller.getNextNode(
      node,
      filter: (node) =>
          !node.data.enabled ||
          !controller.isVisible(node.value) ||
          !controller.isExpandedAllParents(node.value),
    );

    if (next == null) return KeyEventResult.ignored;

    jumpTo(next.value);

    return KeyEventResult.handled;
  }

  /// 清空选中
  KeyEventResult _onShortcutsClear() {
    if (selector.hasSelected()) {
      selector.unselectAll();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }
}

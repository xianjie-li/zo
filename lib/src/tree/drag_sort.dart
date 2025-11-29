part of "tree.dart";

/// 快捷键操作
mixin _TreeDragSortMixin on ZoCustomFormState<Iterable<Object>, ZoTree>
    implements _TreeBaseMixin, _TreeActionsMixin {
  /// 通知keepAlive启用，防止在拖动过程在当前组件被销毁导致事件中断
  ListenableNotifier? _keepAliveNotifier;

  /// 存储所有本次参与拖动排序的节点
  final HashMap<Object, ZoTreeDataNode<ZoOption>> _draggingNodes = HashMap();

  /// 是否正在进行拖动处理
  bool _dragging = false;

  @override
  @protected
  void dispose() {
    super.dispose();

    if (_keepAliveNotifier != null) {
      _keepAliveNotifier!.dispose();
    }
  }

  /// 构造反馈节点
  Widget _dndFeedbackBuilder(Widget? child) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: 2,
        horizontal: _style!.space2,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: _style!.primaryColor),
        borderRadius: BorderRadius.circular(_style!.borderRadiusLG),
        color: _style!.primaryColor.withAlpha(50),
      ),
      child: child,
    );
  }

  /// 构造dnd节点
  Widget _dndNodeBuilder({
    required Widget Function(ZoDNDBuildContext? dndContext) builder,
    required ZoTreeDataNode<ZoOption> optNode,
    required Key key,
    required bool isFixedBuilder,
    required double identWidth,
  }) {
    if (!widget.sortable || isFixedBuilder) return builder(null);

    return Builder(
      key: key,
      builder: (context) {
        return ZoDND(
          groupId: this,
          data: optNode,
          draggableDetector: _draggableDetector,
          droppablePositionDetector: _droppablePositionDetector,
          // 上下添加少量偏移，让指示线能刚好放置在选项中间，左侧添加缩进距离偏移
          dropIndicatorPadding: EdgeInsets.fromLTRB(identWidth, -1, 0, -1),
          feedback: _dndFeedbackBuilder(optNode.data.title),
          onDragStart: (e) => _onDragStart(
            event: e,
            optNode: optNode,
            context: context,
          ),
          onDragEnd: (e) => _onDragEnd(
            event: e,
            optNode: optNode,
            context: context,
          ),
          onExpand: (e) => _onDragExpand(
            event: e,
            optNode: optNode,
            context: context,
          ),
          onAccept: (e) => _onDragAccept(
            event: e,
            optNode: optNode,
            context: context,
          ),
          builder: (context, dndContext) {
            return builder(dndContext);
          },
        );
      },
    );
  }

  /// 可拖动检测
  bool _draggableDetector(ZoDND dnd) {
    final currentNode = dnd.data as ZoTreeDataNode<ZoOption>;

    if (widget.draggableDetector == null) {
      return true;
    }

    return widget.draggableDetector!(currentNode);
  }

  /// 可放置检测
  ZoDNDPosition _droppablePositionDetector(ZoDND currentDND, ZoDND? dragDND) {
    final currentNode = currentDND.data as ZoTreeDataNode<ZoOption>;
    final dragNode = dragDND?.data as ZoTreeDataNode<ZoOption>?;

    // 禁止正在拖动的节点及其祖先被放置
    if (dragNode != null && _draggingNodes.isNotEmpty) {
      // 当前项是正在拖动的节点
      if (_draggingNodes[currentNode.value] != null) {
        return const ZoDNDPosition();
      }

      // 检测
      var parent = currentNode.parent;

      while (parent != null) {
        if (_draggingNodes[parent.value] != null) {
          return const ZoDNDPosition();
        }
        parent = parent.parent;
      }
    }

    if (widget.droppableDetector == null) {
      return const ZoDNDPosition(
        top: true,
        center: true,
        bottom: true,
      );
    }

    final droppable = widget.droppableDetector!(currentNode, dragNode);

    if (droppable) {
      return const ZoDNDPosition(
        top: true,
        center: true,
        bottom: true,
      );
    } else {
      return const ZoDNDPosition();
    }
  }

  /// 更新要随此次拖动进行排序的节点
  ///
  /// - 已选中数量小于等于1 / 拖动节点未被选中: 正常处理拖动节点
  /// - 否则同时拖动所有选中节点
  void _updateDragSortOptions(ZoTreeDataNode<ZoOption> dragNode) {
    _draggingNodes.clear();

    final selected = selector.getSelected();

    final dragSelected = selector.isSelected(dragNode.value);

    if (selected.length <= 1 || !dragSelected) {
      _draggingNodes[dragNode.value] = dragNode;
    } else {
      for (final value in selected) {
        final node = controller.getNode(value);

        if (node != null) {
          _draggingNodes[node.value] = node;
        }
      }

      ZoDNDManager.instance.updateFeedback(
        _dndFeedbackBuilder(Text(selected.length.toString())),
      );
    }
  }

  /// 拖动结束时，触发move
  void _triggerDragSort(ZoDNDDropEvent event) {
    final List<Object> values = [];
    final toNode = event.dropDND.data as ZoTreeDataNode<ZoOption>;

    final activePosition = event.activePosition;

    for (final element in _draggingNodes.entries) {
      values.add(element.value.value);
    }

    _draggingNodes.clear();

    ZoTreeDataRefPosition? position;

    if (activePosition.center) {
      position = ZoTreeDataRefPosition.inside;
    } else if (activePosition.top) {
      position = ZoTreeDataRefPosition.before;
    } else if (activePosition.bottom) {
      position = ZoTreeDataRefPosition.after;
    }

    if (position == null) return;

    controller.mutator.mutation(
      ZoMutatorCommand(
        operation: [
          TreeDataMoveOperation(
            values: values,
            toValue: toNode.value,
            position: position,
          ),
        ],
      ),
    );
  }

  void _onDragStart({
    required ZoDNDEvent event,
    required ZoTreeDataNode<ZoOption> optNode,
    required BuildContext context,
  }) {
    final dragNode = event.dragDND.data as ZoTreeDataNode<ZoOption>;

    // 拖动组件保活，防止销毁导致事件中断
    if (optNode.value == dragNode.value) {
      // 防止有遗漏的事件
      if (_keepAliveNotifier != null) {
        _keepAliveNotifier!.notifyListeners();
        _keepAliveNotifier!.dispose();
      }

      _keepAliveNotifier = ListenableNotifier();

      KeepAliveNotification(_keepAliveNotifier!).dispatch(context);
    }

    // 第一次触发时更新待拖动节点
    if (!_dragging) {
      _updateDragSortOptions(dragNode);
    }

    setState(() {
      _dragging = true;
    });
  }

  void _onDragEnd({
    required ZoDNDEvent event,
    required ZoTreeDataNode<ZoOption> optNode,
    required BuildContext context,
  }) {
    final dragNode = event.dragDND.data as ZoTreeDataNode<ZoOption>;

    // 仅处理拖动节点的事件
    if (optNode.value == dragNode.value && _keepAliveNotifier != null) {
      _keepAliveNotifier!.notifyListeners();
      _keepAliveNotifier!.dispose();
      _keepAliveNotifier = null;
    }

    setState(() {
      _dragging = false;
    });
  }

  void _onDragExpand({
    required ZoDNDEvent event,
    required ZoTreeDataNode<ZoOption> optNode,
    required BuildContext context,
  }) {
    if (!isExpanded(optNode.value)) {
      expand(optNode.value);
    }
  }

  void _onDragAccept({
    required ZoDNDEvent event,
    required ZoTreeDataNode<ZoOption> optNode,
    required BuildContext context,
  }) {
    _triggerDragSort(event as ZoDNDDropEvent);
  }
}

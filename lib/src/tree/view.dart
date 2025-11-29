part of "tree.dart";

/// widget 构造相关
mixin _TreeViewMixin on ZoCustomFormState<Iterable<Object>, ZoTree>
    implements _TreeBaseMixin, _TreeActionsMixin, _TreeDragSortMixin {
  /// 更新 _fixedHeight
  void _updateFixedHeight() {
    if (widget.maxHeight == null) {
      _fixedHeight = null;
      return;
    }

    final maxHeight = widget.maxHeight!;

    double contentHeight = widget.padding.top + widget.padding.bottom;

    for (final option in controller.filteredFlatList) {
      if (contentHeight > maxHeight) {
        // 计算大于最大高度的内容是多余的，主动阻止它
        break;
      }

      contentHeight += option.height;
    }

    final newFixedHeight = min(contentHeight, maxHeight);

    final isChanged = newFixedHeight != _fixedHeight;

    _fixedHeight = newFixedHeight;

    if (isChanged && !_isInit) {
      setState(() {});
    }
  }

  /// 根据当前配置获取选项应该使用的文本和图标颜色
  Color _getActiveTextColor() {
    final darkStyle = _style!.darkStyle;
    final lightStyle = _style!.lightStyle;

    // 传入 activeColors 时
    if (_useLightText != null) {
      // 主题和其文本色在语言上是相反的，黑色主题使用亮色文本
      return _useLightText!
          ? darkStyle.titleTextColor
          : lightStyle.titleTextColor;
    }

    // 未传入时，使用的是 primaryColor，固定使用亮色文本
    return darkStyle.titleTextColor;
  }

  /// 构造行节点
  Widget _treeNodeBuilderWithIndex(BuildContext context, int index) {
    final option = controller.filteredFlatList.elementAtOrNull(index);

    if (option == null) {
      return const SizedBox.shrink();
    }

    return _treeNodeBuilder(context, option);
  }

  /// 构造行节点
  Widget _treeNodeBuilder(
    BuildContext context,
    ZoOption option, {
    bool isFixedBuilder = false,
  }) {
    final value = option.value;

    final optNode = controller.getNode(value);

    if (optNode == null) return const SizedBox.shrink();

    // 是否分支节点
    final isBranch = option.isBranch;

    bool expandByRow = widget.expandByTapRow == null
        ? true
        : widget.expandByTapRow!(optNode);

    // 固定渲染时只能通过折叠按钮展开关闭
    if (isFixedBuilder) {
      expandByRow = false;
    }

    final isSelected =
        widget.selectionType != ZoSelectionType.none &&
        selector.isSelected(value);

    final tEvent = ZoTreeEvent(node: optNode, instance: this as ZoTreeState);

    final (leadNode, identWidth) = _buildLeadingNode(
      optNode: optNode,
      isFixedBuilder: isFixedBuilder,
      isBranch: isBranch,
      isSelected: isSelected,
      expandByRow: expandByRow,
    );

    // 左右间距、leading等节点之间的间距
    final horizontalSpace = _style!.space1;

    // 左侧预估总间距，用于修正 identWidth
    final estimatedIdentSpacing = horizontalSpace;

    Widget renderChild(ZoDNDBuildContext? dndContext) {
      return ZoOptionView(
        key: ValueKey(value),
        option: option,
        arrow: false,
        active: isSelected,
        padding: EdgeInsets.symmetric(
          horizontal: horizontalSpace,
          vertical: 0,
        ),
        horizontalSpacing: horizontalSpace,
        activeColor: widget.activeColor,
        highlightColor: widget.highlightColor,
        loading: controller.isAsyncLoading(value),
        onTap: (event) => _onOptionTap(event, expandByRow),
        onContextAction: widget.onContextAction == null
            ? null
            : _onContextAction,
        onFocusChanged: _onFocusChanged,
        leading: Row(
          spacing: horizontalSpace,
          children: [
            // 有子级并且未按行展开，渲染交互按钮
            leadNode,
            ?option.leading,
            ?widget.leadingBuilder?.call(tEvent),
          ],
        ),
        trailing: widget.trailingBuilder?.call(tEvent),
      );
    }

    return _dndNodeBuilder(
      builder: renderChild,
      optNode: optNode,
      key: ValueKey(value),
      isFixedBuilder: isFixedBuilder,
      identWidth: -identWidth - estimatedIdentSpacing,
    );
  }

  /// 构造选项的前置节点, 同时会返回缩进展开节点总宽度
  (Widget, double) _buildLeadingNode({
    required ZoTreeDataNode<ZoOption> optNode,
    required bool isFixedBuilder,
    required bool isBranch,
    required bool isSelected,
    required bool expandByRow,
  }) {
    final indentSpaceNumber = isBranch ? optNode.level : optNode.level + 1;

    final oneWidth = widget.indentSize.width;

    var identWidth = oneWidth * indentSpaceNumber;

    if (isBranch) {
      identWidth += oneWidth;
    }

    final leadingNode = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isBranch
          ? () => _onToggleButtonTap(optNode, isFixedBuilder)
          : null,
      child: Row(
        children: [
          for (int i = 0; i < indentSpaceNumber; i++)
            SizedBox.square(
              dimension: oneWidth,
              key: ValueKey(i),
              child: _identDotBuilder(
                index: i,
                isBranch: isBranch,
                indentSpaceNumber: indentSpaceNumber,
              ),
            ),
          if (isBranch)
            SizedBox(
              key: const ValueKey("__Expand"),
              height: widget.indentSize.height,
              width: oneWidth,
              child: AnimatedRotation(
                turns: controller.expander.isSelected(optNode.value)
                    ? 0.25
                    : 0.0,
                duration: const Duration(milliseconds: 150),
                child: Icon(
                  widget.togglerIcon ?? Icons.arrow_right_rounded,
                  size: widget.indentSize.height,
                  color: isSelected
                      // 因为嵌入到了 ZoInteractiveBox 中，需要确保颜色与选项文本一致
                      ? _activeTextColor
                      : _style!.textColor,
                ),
              ),
            ),
        ],
      ),
    );

    // 有子级并且未按行展开，渲染交互按钮
    if (isBranch && !expandByRow) {
      return (
        ZoInteractiveBox(
          plain: true,
          child: leadingNode,
        ),
        identWidth,
      );
    }

    return (leadingNode, identWidth);
  }

  double _treeRowExtentBuilder(
    int index,
    SliverLayoutDimensions layoutDimensions,
  ) {
    final option = controller.filteredFlatList.elementAtOrNull(index);
    if (option == null) return 0;
    return option.height;
  }

  /// 渲染缩进 dot
  Widget? _identDotBuilder({
    required bool isBranch,
    required int index,
    required int indentSpaceNumber,
  }) {
    if (!widget.indentDots) return null;

    final show = widget.onlyLeafIndentDot
        ? !isBranch && index == indentSpaceNumber - 1
        : true;

    if (!show) return null;

    return const Center(
      child: _ZoTreeIndentIndicator(),
    );
  }

  Widget? _emptyBuilder() {
    if (controller.filteredFlatList.isNotEmpty) return null;

    return widget.empty ??
        Center(
          // 防止贴合顶部
          heightFactor: 8,
          child: ZoResult(
            simpleResult: true,
            icon: const Icon(Icons.info_outline),
            title: Text(context.zoLocale.noData),
          ),
        );
  }

  /// 更新 [_offsetCache]，应在任何高度、顺序变更后调用
  void _updateOptionOffsetCache() {
    _offsetCache.clear();
    _offsetCacheValueList.clear();

    double offset = widget.padding.top;

    for (final option in controller.filteredFlatList) {
      _offsetCache[option.value] = offset;
      _offsetCacheValueList.add(option.value);
      offset += option.height;
    }

    if (!_isInit) {
      _updateFixedOptions();
    }
  }

  /// 更新要显示的固定项
  void _updateFixedOptions() {
    if (!widget.pinedActiveBranch) {
      if (_fixedOptions.isNotEmpty) {
        setState(() {
          _fixedOptions = [];
          _fixedOptionsHeight = 0;
        });
      }
      return;
    }

    List<Object> newFixedOptions = [];
    double newFixedOptionsHeight = 0;

    for (final optValue in _offsetCacheValueList) {
      // 获取父级和占用的fixed高度
      final (:parents, :fixedHeight, :node) = _getOptionFixedOptions(optValue);

      if (node == null) continue;

      // 展开的选项检测顶部可见性、未展开的检测底部可见性
      final optionOffset = isExpanded(optValue)
          ? _offsetCache[optValue]!
          : _offsetCache[optValue]! + node.data.height;

      final offset = scrollController.position.pixels + fixedHeight;

      if (optionOffset > offset) {
        newFixedOptions = parents;
        newFixedOptionsHeight = fixedHeight;
        break;
      }
    }

    if (!listEquals(newFixedOptions, _fixedOptions)) {
      setState(() {
        _fixedOptions = newFixedOptions;
        _fixedOptionsHeight = newFixedOptionsHeight;
      });
    }
  }

  /// 根据 _fixedOptions 构造固定在顶部的选项
  Widget? _fixedOptionBuilder() {
    if (_fixedOptions.isEmpty || _dragging) return const SizedBox.shrink();

    final List<Widget> ls = [];

    for (var optionValue in _fixedOptions) {
      final node = controller.getNode(optionValue);

      if (node == null) continue;

      // 构造选项节点，组件目前固定无动画，如果后续要支持应该需要调整此处
      final fixedNode = ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: node.data.height,
        ),
        child: _treeNodeBuilder(
          context,
          node.data,
          isFixedBuilder: true,
        ),
      );

      ls.add(fixedNode);
    }

    if (ls.isEmpty) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _style?.surfaceColor,
          ),
          padding: EdgeInsets.fromLTRB(
            widget.padding.left,
            _fixedOptionsPadding,
            widget.padding.right,
            _fixedOptionsPadding,
          ),
          height: _fixedOptionsHeight,
          child: Column(
            children: ls,
          ),
        ),
        // 在底部绘制阴影
        Container(
          height: 8,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _style!.shadowGradientColors,
            ),
          ),
        ),
      ],
    );
  }

  void _onOptionTap(ZoTriggerEvent event, bool expandByRow) {
    final node = _getNodeByEvent(event);

    widget.onTap?.call(ZoTreeEvent(node: node, instance: this as ZoTreeState));

    // 按下特定修饰键时，避免进行展开或收起操作，体验会更好
    final isModifierKeyPressed =
        ZoShortcutsHelper.isCommandPressed || ZoShortcutsHelper.isShiftPressed;

    if (expandByRow && !isModifierKeyPressed) {
      toggle(node.value);
    }

    _selectHandle(node);
  }

  /// 选项前方展开按钮和缩进区域点击
  void _onToggleButtonTap(ZoTreeDataNode<ZoOption> node, bool isFixedBuilder) {
    // 顶部固定选项关闭处理，将滚动位置调整到选项当前位置
    if (isFixedBuilder) {
      collapse(node.value);

      jumpTo(
        node.value,
        offset: 0,
        autoFocus: true,
        smartScroll: false,
      );

      return;
    }

    toggle(node.value);
    focusOption(node.value);
  }

  void _onContextAction(ZoTriggerEvent event) {
    final node = _getNodeByEvent(event);

    widget.onContextAction?.call(
      ZoTreeEvent(node: node, instance: this as ZoTreeState),
      event,
    );
  }

  void _onFocusChanged(ZoTriggerToggleEvent event) {
    final node = _getNodeByEvent(event);

    if (event.toggle) {
      currentFocusValue = node.value;
    } else {
      currentFocusValue = null;
    }
  }

  ZoTreeDataNode<ZoOption> _getNodeByEvent(ZoTriggerEvent event) {
    final option = (event.data as ZoOptionEventData).option;
    final node = controller.getNode(option.value)!;
    return node;
  }

  /// 更新 _useLightText 的值
  void _calcUseLightText() {
    if (widget.activeColor == null) {
      _useLightText = null;
      return;
    }

    _useLightText = useLighterText(widget.activeColor!);
  }
}

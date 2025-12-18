part of "tree.dart";

/// widget 构造相关
mixin _TreeViewMixin on ZoCustomFormState<Iterable<Object>, ZoTree>
    implements _TreeBaseMixin, _TreeActionsMixin, _TreeDragSortMixin {
  /// 更新 _fixedHeight
  void _updateFixedHeight([bool skipUpdate = false]) {
    if (widget.maxHeight == null) {
      _fixedHeight = null;
      return;
    }

    final maxHeight = widget.maxHeight!;

    double contentHeight = _padding.top + _padding.bottom;

    final defaultHeight = _style!.getSizedExtent(widget.size);

    for (final option in controller.filteredFlatList) {
      if (contentHeight > maxHeight) {
        // 计算大于最大高度的内容是多余的，主动阻止它
        break;
      }

      contentHeight += (option.height ?? defaultHeight);
    }

    final newFixedHeight = min(contentHeight, maxHeight);

    final isChanged = newFixedHeight != _fixedHeight;

    _fixedHeight = newFixedHeight;

    if (isChanged && !_isInit && !skipUpdate) {
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
      isBranch: option.isBranch,
      isSelected: isSelected,
      expandByRow: expandByRow,
    );

    // 左右间距、leading等节点之间的间距
    final horizontalSpace = _style!.space1;

    // 左侧预估总间距，用于修正 identWidth
    final estimatedIdentSpacing = horizontalSpace;

    final optionPadding = EdgeInsets.only(
      // 左侧因为有展开图标本身的空白，需要设置得更小
      left: horizontalSpace,
      // 右侧设置固定间距，因为容器本身有间距了，这里只是让右侧内容看起来不那么拥挤
      right: _style!.space2,
    );

    Widget? header;

    if (option.builder != null) {
      header = option.builder!(context);
    } else if (widget.headerBuilder != null) {
      header = widget.headerBuilder!(tEvent);
    } else if (option.title != null) {
      header = DefaultTextStyle.merge(
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        child: option.title!,
      );
    }

    Widget renderChild(ZoDNDBuildContext? dndContext) {
      return ZoTile(
        key: ValueKey(value),
        header: header,
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
        enabled: option.enabled,
        arrow: false,
        active: isSelected,
        loading: controller.isAsyncLoading(value),
        crossAxisAlignment: CrossAxisAlignment.center,
        padding: optionPadding,
        horizontalSpacing: horizontalSpace,
        decorationPadding: const EdgeInsets.symmetric(vertical: 1),
        disabledColor: Colors.transparent,
        activeColor: widget.activeColor,
        highlightColor: widget.highlightColor,
        data: (option: option, context: context),
        iconTheme: _itemIconTheme,
        textStyle: _itemTextStyle,
        backgroundWidget: Positioned.fill(
          key: const ValueKey("__IndentLine"),
          child: IgnorePointer(
            child: Padding(
              padding: EdgeInsetsGeometry.only(left: horizontalSpace),
              child: _indentLineBuilder(
                optNode: optNode,
                isFixedBuilder: isFixedBuilder,
              ),
            ),
          ),
        ),
        onTap: MemoCallback(
          (ZoTriggerEvent event) => _onOptionTap(event, expandByRow),
        ),
        onContextAction: widget.onContextAction == null
            ? null
            : _onContextAction,
        onFocusChanged: _onFocusChanged,
        onActiveChanged: widget.onActiveChanged,
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

    final oneWidth = _indentSize.width;

    var identWidth = oneWidth * indentSpaceNumber;

    var hasChildren = false;

    if (isBranch) {
      identWidth += oneWidth;
      hasChildren = optNode.data.children?.isNotEmpty ?? false;
    }

    Color? togglerColor = _style!.textColor;

    // 包含选中子级时高亮显示展开图标
    if (isSelected) {
      togglerColor = _activeTextColor;
    } else if (!isFixedBuilder && controller.hasSelectedChild(optNode.value)) {
      togglerColor = _style!.selectedColor;
    }

    final leadingNode = GestureDetector(
      key: const ValueKey("__ExpandNode"),
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
              key: const ValueKey("__ExpandIcon"),
              height: _indentSize.height,
              width: oneWidth,
              child: Opacity(
                opacity: hasChildren ? 1 : _style!.disableOpacity,
                child: AnimatedRotation(
                  turns: controller.isExpanded(optNode.value) ? 0.25 : 0.0,
                  duration: const Duration(milliseconds: 150),
                  child: Transform.scale(
                    // 适当放大，让展开图标更明细一些
                    scale: 1.2,
                    child: IconTheme.merge(
                      data: IconThemeData(
                        size: _indentSize.height,
                        color: togglerColor,
                      ).merge(widget.iconTheme),
                      child: Icon(
                        widget.togglerIcon ?? Icons.arrow_right_rounded,
                      ),
                    ),
                  ),
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

  /// 渲染缩进线
  Widget _indentLineBuilder({
    required ZoTreeDataNode<ZoOption> optNode,
    required bool isFixedBuilder,
  }) {
    if (isFixedBuilder || !widget.indentLine) return const SizedBox.shrink();

    final belongList = optNode.parent?.data.children ?? [];
    final isLast = belongList.lastOrNull == optNode.data;

    final num = optNode.level;

    final oneWidth = _indentSize.width;

    final lastStatusList = _getLastStatusList(optNode);

    final List<Widget> children = [];

    for (int i = 0; i < num; i++) {
      final isLevelLast = lastStatusList[i];
      final isCurrentLast = i == num - 1;

      if (isLevelLast && !isCurrentLast) {
        children.add(
          SizedBox(
            key: ValueKey(i),
            width: oneWidth,
          ),
        );
      } else {
        children.add(
          _ZoTreeIndentLineIndicator(
            key: ValueKey(i),
            width: oneWidth,
            color: _style!.outlineColor,
            isCorner: i == num - 1 ? isLast : false,
          ),
        );
      }
    }

    return Row(
      children: children,
    );
  }

  /// 获取节点及其所有祖先是不是各自所在节点的最后一个节点
  List<bool> _getLastStatusList(ZoTreeDataNode<ZoOption> node) {
    final List<bool> list = [];

    ZoTreeDataNode<ZoOption>? curNode = node;

    while (curNode != null) {
      // 根层级没有参考线
      if (curNode.level == 0) break;

      final lastParentChild = curNode.parent?.data.children?.lastOrNull;

      list.insert(0, lastParentChild == curNode.data);

      curNode = curNode.parent;
    }

    return list;
  }

  double _treeRowExtentBuilder(
    int index,
    SliverLayoutDimensions layoutDimensions,
  ) {
    final option = controller.filteredFlatList.elementAtOrNull(index);
    if (option == null) return 0;

    return option.height ?? _style!.getSizedExtent(widget.size);
  }

  /// 传递给 SliverVariedExtentList 以便复用 renderObject，另一个主要原因是，
  /// 节点变更后滚动组件后方的所有节点renderObject状态会丢失，从下方拖动到上方时事件被中断
  int? _findChildIndexCallback(Key key) {
    if (key is ValueKey) {
      final index = controller.getFilteredIndex(key.value);
      return index;
    }

    return null;
  }

  /// 渲染缩进 dot
  Widget? _identDotBuilder({
    required bool isBranch,
    required int index,
    required int indentSpaceNumber,
  }) {
    if (!widget.leafDot) return null;

    final show = !isBranch && index == indentSpaceNumber - 1;

    if (!show) return null;

    return const Center(
      child: _ZoTreeIndentDotIndicator(),
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

    double offset = _padding.top;

    final defaultHeight = _style!.getSizedExtent(widget.size);

    for (final option in controller.filteredFlatList) {
      _offsetCache[option.value] = offset;
      _offsetCacheValueList.add(option.value);
      offset += option.height ?? defaultHeight;
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

    final defaultHeight = _style!.getSizedExtent(widget.size);

    for (final optValue in _offsetCacheValueList) {
      // 获取父级和占用的fixed高度
      final (:parents, :fixedHeight, :node) = _getOptionFixedOptions(optValue);

      if (node == null) continue;

      // 展开的选项检测顶部可见性、未展开的检测底部可见性
      final optionOffset = controller.isExpanded(optValue)
          ? _offsetCache[optValue]!
          : _offsetCache[optValue]! + (node.data.height ?? defaultHeight);

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
    if (_fixedOptions.isEmpty) return const SizedBox.shrink();

    final List<Widget> ls = [];

    final defaultHeight = _style!.getSizedExtent(widget.size);

    for (var optionValue in _fixedOptions) {
      final node = controller.getNode(optionValue);

      if (node == null) continue;

      // 构造选项节点，组件目前固定无动画，如果后续要支持应该需要调整此处
      final fixedNode = SizedBox(
        height: node.data.height ?? defaultHeight,
        child: _treeNodeBuilder(
          context,
          node.data,
          isFixedBuilder: true,
        ),
      );

      ls.add(fixedNode);
    }

    if (ls.isEmpty) return const SizedBox.shrink();

    return ZoTransition(
      open: !_dragging,
      appear: false,
      unmountOnExit: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            decoration: BoxDecoration(
              color:
                  widget.pinedContainerBackgroundColor ?? _style?.surfaceColor,
            ),
            padding: EdgeInsets.fromLTRB(
              _padding.left,
              _fixedOptionsPadding,
              _padding.right,
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
      ),
    );
  }

  void _onOptionTap(ZoTriggerEvent event, bool expandByRow) {
    final node = _getNodeByEvent(event);

    widget.onTap?.call(ZoTreeEvent(node: node, instance: this as ZoTreeState));

    // 按下特定修饰键时，避免进行展开或收起操作，体验会更好
    final isModifierKeyPressed =
        ZoShortcutsHelper.isCommandPressed || ZoShortcutsHelper.isShiftPressed;

    if (expandByRow && !isModifierKeyPressed) {
      controller.toggle(node.value);
    }

    _selectHandle(node);
  }

  /// 选项前方展开按钮和缩进区域点击
  void _onToggleButtonTap(ZoTreeDataNode<ZoOption> node, bool isFixedBuilder) {
    // 顶部固定选项关闭处理，将滚动位置调整到选项当前位置
    if (isFixedBuilder) {
      controller.collapse(node.value);

      jumpTo(
        node.value,
        offset: 0,
        autoFocus: true,
        smartScroll: false,
      );

      return;
    }

    controller.toggle(node.value);
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
    widget.onFocusChanged?.call(event);

    final option = _getOptionByEvent(event);

    if (event.toggle) {
      currentFocusValue = option.value;
    } else {
      currentFocusValue = null;
    }
  }

  ZoTreeDataNode<ZoOption> _getNodeByEvent(ZoTriggerEvent event) {
    final option = (event.data as ZoOptionEventData).option;
    final node = controller.getNode(option.value)!;
    return node;
  }

  ZoOption _getOptionByEvent(ZoTriggerEvent event) {
    return (event.data as ZoOptionEventData).option;
  }

  /// 更新 _useLightText 的值
  void _calcUseLightText() {
    if (widget.activeColor == null) {
      _useLightText = null;
      return;
    }

    _useLightText = isDarkColor(widget.activeColor!);
  }
}

/// 渲染树节点前方的缩进指示点
class _ZoTreeIndentDotIndicator extends StatelessWidget {
  const _ZoTreeIndentDotIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 2.4,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.grey[400],
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}

/// 渲染树节点前方的缩进指示线
class _ZoTreeIndentLineIndicator extends StatelessWidget {
  const _ZoTreeIndentLineIndicator({
    super.key,
    required this.width,
    required this.color,
    this.isCorner = false,
  });

  /// 渲染拐角
  final bool isCorner;

  /// 宽度
  final double width;

  /// 颜色
  final Color color;

  @override
  Widget build(BuildContext context) {
    Widget node;

    if (isCorner) {
      node = Align(
        alignment: Alignment.topRight,
        child: FractionallySizedBox(
          heightFactor: 0.52,
          child: Container(
            width: width / 2 + 0.5,
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  width: 1,
                  color: color,
                ),
                bottom: BorderSide(
                  width: 1,
                  color: color,
                ),
                top: BorderSide.none,
                right: BorderSide.none,
              ),
            ),
          ),
        ),
      );
    } else {
      node = Center(
        child: Container(
          width: 1,
          decoration: BoxDecoration(
            color: color,
          ),
        ),
      );
    }

    return SizedBox(
      width: width,
      child: node,
    );
  }
}

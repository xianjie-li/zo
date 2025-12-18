import "dart:collection";

import "package:flutter/material.dart";
import "package:zo/zo.dart";

class ZoTabsEntry {
  ZoTabsEntry({
    required this.label,
    required this.value,
    this.icon,
    this.enable = true,
  });

  /// tab 文本
  String label;

  /// tab 的唯一值
  Object value;

  /// tab 图标
  Widget? icon;

  /// 是否启用
  bool enable;

  @override
  String toString() {
    return "ZoTabsEntry(label: $label, value: $value, icon: $icon, enable: $enable)";
  }

  ZoTabsEntry copyWith({
    String? label,
    Object? value,
    Widget? icon,
    bool? enable,
  }) {
    return ZoTabsEntry(
      label: label ?? this.label,
      value: value ?? this.value,
      icon: icon ?? this.icon,
      enable: enable ?? this.enable,
    );
  }
}

/// 内部菜单，在自定义菜单时可通过此项复用内部选项
class ZoTabsInternalContextActions {
  ZoTabsInternalContextActions({
    required this.closeActions,
    required this.pinnedActions,
  });

  /// 关闭操作
  List<ZoOption> closeActions;

  /// 钉住操作
  List<ZoOption> pinnedActions;
}

/// 触发上下文操作时提供的信息对象
class ZoTabsContextAction {
  ZoTabsContextAction({
    required this.entry,
    required this.option,
    required this.internal,
  });

  /// 操作的 tab
  ZoTabsEntry entry;

  /// 触发的选项
  ZoOption option;

  /// 是否是内部选项
  bool internal;
}

enum ZoTabsType {
  /// 胶囊型 tab
  capsule,

  /// 扁平 tab
  flat,
}

/// tab 的变更操作
abstract class ZoTabsChangedEvent {
  const ZoTabsChangedEvent();
}

///
///
/// 作为表单控件： 通过 [value] / [onChanged], 可将组件作为支持单选、多选的标签选择控件使用
class ZoTabs extends ZoCustomFormWidget<Iterable<Object>> {
  const ZoTabs({
    super.key,
    super.value,
    super.onChanged,
    required this.tabs,
    this.onTabsChanged,
    this.selectionType = ZoSelectionType.single,
    this.direction = Axis.horizontal,
    this.pinedTabs,
    this.onPinedTabsChanged,
    this.pinedTabsOnlyShowIcon = true,
    this.wrapTabs = false,
    this.type = ZoTabsType.capsule,
    this.size,
    this.tabHeight,
    this.tabMinWidth,
    this.labelMaxWidth = 260,
    this.leading,
    this.trailing,
    this.fixedTrailing,
    this.closeIcon,
    this.showCloseButton = true,
    this.alwaysShowCloseButton = true,
    this.markers,
    this.buildMarker,
    this.buildText,
    this.enableContextMenu = true,
    this.customContextMenu,
    this.onContextMenuTrigger,
    this.onContextAction,
    this.activeIndicator,
    this.showBorder,
    this.color,
    this.borderColor,
    this.activeColor,
    this.hoverColor,
    this.tapEffectColor,
    this.sortable = true,
    this.groupId,
    this.onActiveChanged,
    this.onFocusChanged,
    this.onCloseConfirm,
    this.onClosed,
  }) : assert(direction != Axis.vertical || (!wrapTabs && tabMinWidth == null));

  /// 要显示的 tab 项
  ///
  /// ⚠️：请勿直接传入非常量字面量
  final List<ZoTabsEntry> tabs;

  /// tabs 发生变更时触发
  final ValueChanged<List<ZoTabsEntry>>? onTabsChanged;

  /// 控制选择类型, 默认为单选
  final ZoSelectionType selectionType;

  /// 显示方向
  final Axis direction;

  /// 要固定在左侧显示的 tab 项，钉住的 tab 项不能会被关闭其他等间接操作关闭
  ///
  /// ⚠️：请勿直接传入非常量字面量
  final List<Object>? pinedTabs;

  /// [pinedTabs] 变更时触发，必须将更新同步到 [pinedTabs] 内部才会实际变更
  final ValueChanged<List<Object>>? onPinedTabsChanged;

  /// 钉在左侧的 tab 只显示图标，对无图标的项和纵向tab无效，启用此项后，只能通过api取消固定，
  /// 可能需要在上下文菜单中提供相关操作
  final bool pinedTabsOnlyShowIcon;

  /// 当超出时，是否换行显示, 关闭可滚动查看超出部分，对纵向 tab 无效
  final bool wrapTabs;

  /// 显示风格
  final ZoTabsType type;

  /// 组件整体尺寸
  final ZoSize? size;

  /// tab 项的高度
  final double? tabHeight;

  /// tab 项的最小宽度, 在纵向布局中无效，默认 tab 宽度视内容而定
  final double? tabMinWidth;

  /// 文本区域最大宽度, 在纵向布局中无效
  final double? labelMaxWidth;

  /// 在所有 tab 之前放置的内容
  final Widget? leading;

  /// 在所有 tab 之后放置的内容
  final Widget? trailing;

  /// 固定在 tabBar 后方的内容，与 [trailing] 不同的是无论内容多少，它始终在最右侧,
  /// 对纵向 tab 无效
  final Widget? fixedTrailing;

  /// 自定义关闭图标
  final IconData? closeIcon;

  /// 是否显示关闭图标
  final bool showCloseButton;

  /// 是否始终显示关闭图标, 设为false后将只在聚焦和光标悬浮时显示
  final bool alwaysShowCloseButton;

  /// 要显示标记的 tab，可用展示一个圆形角标，可通过 [buildMarker] 自定义展示内容
  final Set<Object>? markers;

  /// 自定义 marks 节点
  final Widget Function(ZoTabsEntry entry)? buildMarker;

  /// 自定义文本节点的构造方式
  final Widget Function(ZoTabsEntry entry)? buildText;

  /// 是否启用上下文菜单
  final bool enableContextMenu;

  /// 自定义上下文菜单内容
  final List<ZoOption> Function(
    ZoTabsInternalContextActions internalActions,
  )?
  customContextMenu;

  /// 触发上下文操作, 如果是内部操作，可返回 true 来跳过内部处理
  final bool Function(ZoTabsContextAction action)? onContextMenuTrigger;

  /// 监听上下文事件，传入后会完全覆盖内部的 [enableContextMenu] / [onContextMenuTrigger]
  /// 等配置，可用于更深程度的定制
  ///
  /// 触发放松：
  /// - 鼠标: 右键点击
  /// - 触摸设备: 长按
  final void Function(ZoTriggerEvent event)? onContextAction;

  /// 自定义 active 指示器, 指示器是覆盖在 tab 项上独立节点，大小与 tab 一致，指示器不参与任何事件交互
  final Widget? activeIndicator;

  /// 是否显示 tab 边框
  final bool? showBorder;

  /// tab 项背景色
  final Color? color;

  /// 边框颜色
  final Color? borderColor;

  /// 活动 tab 的背景色，用于活动标签
  final Color? activeColor;

  /// 光标悬浮状态的颜色
  final Color? hoverColor;

  /// 点击时的反馈色
  final Color? tapEffectColor;

  /// 是否支持拖动 tab 调整顺序
  final bool sortable;

  /// 组 id, 具有相同组 id 的 [ZoTabs] 和 [ZoTabsDropArea] 可以互相拖放
  final String? groupId;

  /// tab 活动状态变更
  /// - 鼠标: 表示位于组件上方
  /// - 触摸设备: 按下触发, 松开或移动时关闭
  final ZoTriggerListener<ZoTriggerToggleEvent>? onActiveChanged;

  /// tab 焦点变更, 传入此项后会自动启用 focus 功能
  final ZoTriggerListener<ZoTriggerToggleEvent>? onFocusChanged;

  /// 点击按钮关闭 tab 时，会通过此方法进行确认，如果返回 false，则取消关闭，
  /// 对 api 或其他关闭操作无效
  final Future<bool> Function(ZoTabsEntry entry)? onCloseConfirm;

  /// tab 项被关闭时触发
  final ZoTriggerListener<ZoTabsEntry>? onClosed;

  @override
  ZoCustomFormState<Iterable<Object>, ZoTabs> createState() => ZoTabsState();
}

class ZoTabsState extends ZoCustomFormState<Iterable<Object>, ZoTabs> {
  /// 当前主题样式
  late ZoStyle style;

  /// 滚动容器
  ScrollController scrollController = ScrollController();

  /// tabs 的副本，用于内部直接修改
  List<ZoTabsEntry> tabs = [];

  bool get isHorizontal => widget.direction == Axis.horizontal;

  bool get wrapTabs => isHorizontal && widget.wrapTabs;

  /// 管理选中项
  late ZoSelector<Object, ZoTabsEntry> selector;

  /// 用于快速查询固定的 tab
  final HashMap<Object, bool> _pinnedTabs = HashMap();

  @override
  @protected
  void initState() {
    super.initState();

    _updateTabsConfigByWidget();

    selector = ZoSelector(
      selected: value,
      valueGetter: (entry) => entry.value,
      optionsGetter: () => tabs,
    );

    selector.addListener(_onSelectChanged);
  }

  @override
  @protected
  void didChangeDependencies() {
    super.didChangeDependencies();

    style = context.zoStyle;
  }

  @override
  @protected
  void didUpdateWidget(covariant ZoTabs oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.tabs != widget.tabs) {
      _updateTabsConfigByWidget();
    }

    if (oldWidget.pinedTabs != widget.pinedTabs) {
      _rearrangePinedTabs();
    }
  }

  @override
  @protected
  void dispose() {
    super.dispose();

    scrollController.dispose();
    selector.removeListener(_onSelectChanged);
  }

  /// 同步 value 变更到 selector
  @override
  @protected
  void onPropValueChanged() {
    selector.setSelected(widget.value ?? []);
  }

  /// tab 是否被固定
  bool isPinned(Object value) {
    return _pinnedTabs[value] ?? false;
  }

  /// 关闭选项卡
  void close(List<Object> values) {
    final List<ZoTabsEntry> newTabs = [];
    final List<ZoTabsEntry> closeTabs = [];

    for (final tab in tabs) {
      if (values.contains(tab.value)) {
        closeTabs.add(tab);
      } else {
        newTabs.add(tab);
      }
    }

    if (closeTabs.isNotEmpty) {
      tabs = newTabs;
      selector.unselectList(closeTabs.map((i) => i.value));
      widget.onClosed?.call(closeTabs.first);
    } else {
      setState(() {
        tabs = newTabs;
      });
    }

    _onTapsChanged(tabs);
  }

  /// 执行 onManualCloseConfirm 确认后关闭 tab
  void _manualConfirmCloseTab(ZoTabsEntry entry) async {
    if (widget.onCloseConfirm == null) {
      close([entry.value]);
      return;
    }

    final confirm = await widget.onCloseConfirm!(entry);

    if (confirm) {
      close([entry.value]);
    }
  }

  /// 固定指定选项卡
  void pin(Object value) {
    if (isPinned(value)) return;
    widget.onPinedTabsChanged?.call([...?widget.pinedTabs, value]);
  }

  /// 取消固定指定选项卡
  void unpin(Object value) {
    if (!isPinned(value) || widget.pinedTabs == null) return;
    widget.onPinedTabsChanged?.call(
      widget.pinedTabs!.where((e) => e != value).toList(),
    );
  }

  /// tabs 在内部变更时，统一调用此方法
  void _onTapsChanged(List<ZoTabsEntry> tabs) {
    widget.onTabsChanged?.call(tabs);
    _rearrangePinedTabs();
  }

  /// 更新 selector 的选中项到 value 并进行 rerender, 组件内均通过 selector 更改值，
  /// 不直接设置 value
  void _onSelectChanged() {
    setState(() {
      value = selector.getSelected();
    });
  }

  /// 点击 tab 项
  void _onTap(ZoTriggerEvent event) {
    final props = event.data as _MainContentProps;
    final entry = props.entry;

    if (widget.selectionType == ZoSelectionType.single) {
      selector.setSelected([entry.value]);
      return;
    }

    if (widget.selectionType == ZoSelectionType.multiple) {
      selector.toggle(entry.value);
      return;
    }
  }

  /// 上下文操作
  void _onContextMenu(ZoTriggerEvent event) {
    if (widget.onContextAction != null) {
      widget.onContextAction!(event);
      return;
    }
  }

  /// 从组件配置获取 tabs 副本并设置到状态中
  void _updateTabsConfigByWidget() {
    tabs = widget.tabs.map((i) => i.copyWith()).toList();
    _rearrangePinedTabs();
  }

  /// 将设置为固定的 tab 移动到最前面，如果没有发生任何移动操作返回 false，发生变更时会自动通过 onTabsChanged 通知
  bool _rearrangePinedTabs() {
    _pinnedTabs.clear();

    if (widget.pinedTabs == null || widget.pinedTabs!.isEmpty) return false;

    // 分离固定项和非固定项
    final List<ZoTabsEntry> pinnedItems = [];
    final List<ZoTabsEntry> unpinnedItems = [];

    for (var item in tabs) {
      if (widget.pinedTabs!.contains(item.value)) {
        pinnedItems.add(item);
      } else {
        unpinnedItems.add(item);
      }
    }

    // 组合成理想的新顺序
    final newOrder = [...pinnedItems, ...unpinnedItems];

    for (int i = 0; i < pinnedItems.length; i++) {
      final pinnedItem = pinnedItems[i];
      _pinnedTabs[pinnedItem.value] = true;
    }

    // 检查是否发生了变化
    bool hasChanged = false;

    if (tabs.length != newOrder.length) {
      hasChanged = true;
    } else {
      for (int i = 0; i < pinnedItems.length; i++) {
        final pinnedItem = pinnedItems[i];
        final originalItem = tabs[i];

        if (pinnedItem.value != originalItem.value) {
          hasChanged = true;
          break;
        }
      }
    }

    if (hasChanged) {
      tabs = newOrder;
      widget.onTabsChanged?.call(tabs);
    }

    return hasChanged;
  }

  /// 根据配置获取要显示的边框
  BoxBorder? _getBorder(bool isActive) {
    if (widget.showBorder != true) return null;

    final borderColor = widget.borderColor ?? style.outlineColor;

    return BoxBorder.all(
      color: isActive ? style.outlineColorVariant : borderColor,
    );
  }

  EdgeInsets? _getDecorationPadding() {
    // tab 外边距，用于为 tab 之间添加间隔
    if (isHorizontal) return EdgeInsets.only(right: style.space1);

    return EdgeInsets.only(bottom: style.space1);
  }

  /// 获取附加给 tab 的限制尺寸
  BoxConstraints? _getConstraints() {
    if (!isHorizontal || widget.tabMinWidth == null) return null;

    return BoxConstraints(
      minWidth: widget.tabMinWidth!,
    );
  }

  List<Widget> _buildTabs({
    required double tabHeight,
    required double itemSpace,
    EdgeInsets? decorationPadding,
  }) {
    final size = widget.size ?? style.widgetSize;
    // 将内部按钮等设置为小一号的尺寸
    final smallerSize = style.getSmallerSize(size);

    // 关闭按钮尺寸
    final closeButtonSize = style.getSizedSmallExtent(size);

    // 图标尺寸
    final iconSize = style.getSizedIconSize(smallerSize);

    // 字号
    final sizedFontSize = style.getSizedFontSize(size);

    final radius = switch (widget.type) {
      ZoTabsType.capsule => null,
      ZoTabsType.flat => BorderRadius.circular(0),
    };

    final activeColor = widget.activeColor ?? style.hoverColor;

    // 添加盒限制
    final constraints = _getConstraints();

    // tab 两侧的内边距，右侧因为按钮自带一些空白区域，所以使用更小的间距
    final horizontalPadding = switch (widget.size ?? style.widgetSize) {
      ZoSize.medium => EdgeInsets.only(
        left: style.space3,
        // 微调，让视觉上更融洽
        right: style.space1 + 2,
      ),
      ZoSize.large => EdgeInsets.only(
        left: style.space4,
        right: style.space2,
      ),
      ZoSize.small => EdgeInsets.only(
        left: style.space2,
        right: style.space1,
      ),
    };

    return tabs.map((i) {
      final curIsActive = selector.isSelected(i.value);

      final textAndIconColor = curIsActive
          ? style.titleTextColor
          : style.textColor;

      final textStyle = TextStyle(
        fontSize: sizedFontSize,
        color: textAndIconColor,
        overflow: TextOverflow.ellipsis,
      );

      final iconData = IconThemeData(
        size: iconSize,
        color: textAndIconColor,
      );

      // 使用简化版本的 tab，用于固定且仅显示 icon 的场景
      final showSimpleTab =
          isHorizontal &&
          isPinned(i.value) &&
          widget.pinedTabsOnlyShowIcon &&
          i.icon != null;

      final showMarker =
          widget.markers != null && widget.markers!.contains(i.value);

      final hasTrining =
          widget.showCloseButton || isPinned(i.value) || showMarker;

      // 若 showSimpleTab 启用或没有右侧内容，将右侧间距调整为和左侧已知
      final padding = showSimpleTab || !hasTrining
          ? horizontalPadding.copyWith(right: horizontalPadding.left)
          : horizontalPadding;

      final contextMenuEnable =
          widget.enableContextMenu || widget.onContextAction != null;

      return DefaultTextStyle.merge(
        key: ValueKey(i.value),
        style: textStyle,
        child: IconTheme.merge(
          data: iconData,
          child: ZoInteractiveBox(
            height: tabHeight,
            constraints: constraints,
            textStyle: textStyle,
            iconTheme: iconData,
            padding: padding,
            decorationPadding: decorationPadding,
            foregroundWidget: curIsActive
                ? _buildActiveIndicator(decorationPadding: decorationPadding)
                : null,
            textColorAdjust: true,
            key: ValueKey(i.value),
            focusOnTap: false,
            color: curIsActive ? activeColor : widget.color,
            border: _getBorder(curIsActive),
            hoverColor: widget.hoverColor,
            tapEffectColor: widget.tapEffectColor,
            radius: radius,
            onTap: _onTap,
            builder: _tabItemMainContent,
            onActiveChanged: widget.onActiveChanged,
            onFocusChanged: widget.onFocusChanged,
            onContextAction: contextMenuEnable ? _onContextMenu : null,
            data: _MainContentProps(
              entry: i,
              closeButtonSize: closeButtonSize,
              iconData: iconData,
              itemSpace: itemSpace,
              showSimpleTab: showSimpleTab,
              textStyle: textStyle,
              showMarker: showMarker,
              hasTrining: hasTrining,
            ),
          ),
        ),
      );
    }).toList();
  }

  /// 构造活动 tab 指示器
  Widget _buildActiveIndicator({
    EdgeInsets? decorationPadding,
  }) {
    Widget indicator;

    if (widget.activeIndicator != null) {
      indicator = widget.activeIndicator!;
    } else {
      final side = BorderSide(
        color: style.primaryColor,
        width: isHorizontal ? 1.4 : 2,
      );

      indicator = Container(
        decoration: BoxDecoration(
          border: isHorizontal ? Border(bottom: side) : Border(left: side),
          borderRadius: widget.type == ZoTabsType.capsule
              ? BorderRadius.circular(style.borderRadius)
              : null,
        ),
        // color: style.primaryColor,
      );
    }

    return Positioned(
      left: decorationPadding?.left ?? 0,
      right: decorationPadding?.right ?? 0,
      bottom: decorationPadding?.bottom ?? 0,
      top: 0,
      child: IgnorePointer(
        child: indicator,
      ),
    );
  }

  /// tab项主要内容构造
  Widget _tabItemMainContent(ZoInteractiveBoxBuildArgs args) {
    final props = args.data as _MainContentProps;
    final highlight = args.active || args.focus;

    final trailingNode = _buildTrailingNode(
      highlight: highlight,
      props: props,
    );

    return Row(
      spacing: props.itemSpace,
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      mainAxisSize: isHorizontal ? MainAxisSize.min : MainAxisSize.max,
      children: _buildTabInnerContent(
        trailingNode: trailingNode,
        props: props,
      ),
    );
  }

  /// tab 内部主要内容构造
  List<Widget> _buildTabInnerContent({
    required Widget? trailingNode,
    required _MainContentProps props,
  }) {
    final entry = props.entry;
    final showMarker = props.showMarker;
    final showIconOnly = props.showSimpleTab;
    final itemSpace = props.itemSpace;

    Widget? label;

    if (widget.buildText != null) {
      label = widget.buildText!(entry);
    } else {
      label = Text(entry.label);
    }

    if (isHorizontal && widget.labelMaxWidth != null) {
      label = ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: widget.labelMaxWidth!,
        ),
        child: label,
      );
    }

    Widget? icon = trailingNode;

    if (isHorizontal) {
      // 固定项
      if (showIconOnly) {
        label = null;

        // 如果有marker显示，不隐藏
        if (!showMarker) icon = null;
      }

      return [
        // 由于会放置在 unbounded 的滚动容器，不能直接使用 Expanded 包装 label,
        // 需要多嵌套一层防止 label 被居中
        Row(
          spacing: itemSpace,
          mainAxisSize: MainAxisSize.min,
          children: [
            ?entry.icon,
            ?label,
          ],
        ),
        ?icon,
      ];
    }

    return [
      ?entry.icon,
      Expanded(
        child: label,
      ),
      ?icon,
    ];
  }

  /// 构造尾随区域，包含关闭按钮、mark标记等
  Widget? _buildTrailingNode({
    required bool highlight,
    required _MainContentProps props,
  }) {
    if (!props.hasTrining) {
      return null;
    }

    final entry = props.entry;
    final showMarker = props.showMarker;
    final extent = props.closeButtonSize;
    final textStyle = props.textStyle;
    final iconData = props.iconData;

    final pinned = isPinned(entry.value);

    final hasPinnedOrCloseButton = pinned || widget.showCloseButton;

    // marker 只在非highlight状态显示，且优先于关闭按钮显示
    if (showMarker && (!highlight || !hasPinnedOrCloseButton)) {
      final markerWidget = widget.buildMarker != null
          ? widget.buildMarker!(entry)
          : null;

      return SizedBox(
        width: extent,
        height: extent,
        child: Center(
          child:
              markerWidget ??
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: textStyle.color,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
        ),
      );
    }

    if (pinned) {
      return ZoInteractiveBox(
        width: extent,
        height: extent,
        plain: true,
        focusOnTap: false,
        iconTheme: iconData,
        onTap: (e) => unpin(entry.value),
        child: Icon(
          Icons.push_pin,
          color: highlight ? null : style.disabledTextColor,
        ),
      );
    }

    final icon = pinned
        ? Icon(
            Icons.push_pin,
            color: highlight ? null : style.disabledTextColor,
          )
        : Icon(
            widget.closeIcon ?? Icons.close,
            color: highlight ? null : style.disabledTextColor,
          );

    return ZoInteractiveBox(
      width: extent,
      height: extent,
      plain: true,
      focusOnTap: false,
      iconTheme: iconData,
      onTap: pinned
          ? (e) => unpin(entry.value)
          : (e) => _manualConfirmCloseTab(entry),
      child: (widget.alwaysShowCloseButton || highlight) ? icon : null,
    );
  }

  /// 列表型容器
  Widget _withListView({
    required double tabHeight,
    required List<Widget> children,
  }) {
    return ScrollConfiguration(
      behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
      child: ListView(
        scrollDirection: widget.direction,
        controller: scrollController,
        // 纵向滚动时可以使用固定高度优化
        itemExtent: isHorizontal ? null : tabHeight,
        children: children,
      ),
    );
  }

  /// wrap 型容器
  Widget _withWrap({
    required double tabHeight,
    required List<Widget> children,
    required double itemSpace,
  }) {
    return Wrap(
      runSpacing: itemSpace,
      children: children,
    );
  }

  /// 按需向 children 添加 leading 和 trailing
  void _attachLeadingTrailing(List<Widget> children) {
    // 添加前置节点
    if (widget.leading != null) {
      children.insert(
        0,
        widget.leading!,
      );
    }

    // 添加后置节点
    if (widget.trailing != null) {
      children.add(widget.trailing!);
    }
  }

  /// 构造 fixedTrailing
  Widget _buildFixedTrailing(Widget child, double tabHeight) {
    if (!isHorizontal || widget.fixedTrailing == null) return child;

    return Row(
      spacing: style.space1,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: child),
        SizedBox(
          height: tabHeight,
          child: widget.fixedTrailing!,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // 额外填充边距
    final decorationPadding = _getDecorationPadding();
    final bottomDecorationPadding = (decorationPadding?.bottom ?? 0);

    // tab 项的高度, 纵向 tab 需要额外加上填充的边距
    final tabHeight =
        (widget.tabHeight ?? style.getSizedExtent(widget.size)) +
        (isHorizontal ? 0.0 : bottomDecorationPadding);

    // 用于 tab 内部项和项之间的间距
    final itemSpace = style.getSizedSpace(widget.size);

    final children = _buildTabs(
      tabHeight: tabHeight,
      // 启用 wrapTabs 时，改为通过 Wrap 添加间距，项只剩
      itemSpace: itemSpace,
      decorationPadding: decorationPadding,
    );

    _attachLeadingTrailing(children);

    var child = wrapTabs
        ? _withWrap(
            tabHeight: tabHeight,
            itemSpace: itemSpace,
            children: children,
          )
        : _withListView(
            tabHeight: tabHeight,
            children: children,
          );

    child = _buildFixedTrailing(child, tabHeight);

    return SizedBox(
      // 仅横向非 wrap 需要设置容器高度
      height: (isHorizontal && !wrapTabs) ? tabHeight : null,
      child: child,
    );
  }
}

class _MainContentProps {
  const _MainContentProps({
    required this.closeButtonSize,
    required this.iconData,
    required this.itemSpace,
    required this.entry,
    required this.showSimpleTab,
    required this.textStyle,
    required this.showMarker,
    required this.hasTrining,
  });

  final double closeButtonSize;

  final IconThemeData iconData;

  final double itemSpace;

  final ZoTabsEntry entry;

  final bool showSimpleTab;

  final TextStyle textStyle;

  final bool showMarker;

  final bool hasTrining;
}

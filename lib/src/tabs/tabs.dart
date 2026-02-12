import "dart:async";
import "dart:collection";

import "package:flutter/material.dart";
import "package:zo/src/utils/scroll_indicator_container.dart";
import "package:zo/src/utils/text.dart";
import "package:zo/zo.dart";

/// Tab 的单个配置项
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
    required this.pinActions,
  });

  /// 关闭操作
  List<ZoOption> closeActions;

  /// 钉住操作
  List<ZoOption> pinActions;
}

/// 触发上下文操作时提供的信息对象
class ZoTabsContextAction {
  ZoTabsContextAction({
    required this.entry,
    required this.option,
    required this.internal,
    required this.state,
  });

  /// 操作的 tab
  ZoTabsEntry entry;

  /// 触发的选项
  ZoOption option;

  /// 是否是内部操作
  bool internal;

  /// tabs 实例
  ZoTabsState state;
}

/// tab 项显示风格
enum ZoTabsType {
  /// 胶囊型 tab
  capsule,

  /// 扁平 tab
  flat,
}

/// tab 选中指示风格
enum ZoTabsSelectedStyle {
  /// 下方或左侧显示指示线
  indicationLine,

  /// 背景色
  background,
}

/// tab 的变更操作
abstract class ZoTabsChangedEvent {
  const ZoTabsChangedEvent();
}

/// 选项卡组件，支持横纵向、多行tab、拖动排序、内置的上下文菜单、变更标记、固定选项卡等。
///
/// 定制：组件预设了两种主要风格 [ZoTabsType], 在此基础上，可以通过 [selectedStyle] 切换选中项表现方式，
/// 通过 [simplyTab] 让 tab 仅显示图标、通过 [showBorder] 控制是否显示边框等等。
///
/// 拖动实现：基于 [ZoDND] 实现，相同组的 tab 可以互相拖放，甚至可以拖动到其它相同组的不同类型组件。
///
/// 作为表单控件： 通过 [value] / [onChanged], 可将组件作为支持单选、多选的标签选择控件使用。
class ZoTabs extends ZoCustomFormWidget<Iterable<Object>> {
  const ZoTabs({
    super.key,
    super.value,
    super.onChanged,
    required this.tabs,
    this.onTabsChanged,
    this.selectionType = ZoSelectionType.single,
    this.direction = Axis.horizontal,
    this.transitionActiveStatus = false,
    this.pinedTabs,
    this.onPinedTabsChanged,
    this.pinedTabsOnlyShowIcon = false,
    this.wrapTabs = false,
    this.type = ZoTabsType.capsule,
    this.selectedStyle = ZoTabsSelectedStyle.indicationLine,
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
    this.simplyTab = false,
    this.markers,
    this.buildMarker,
    this.buildText,
    this.enableContextMenu = false,
    this.alignContextMenuOptions = true,
    this.customContextMenu,
    this.onContextMenuTrigger,
    this.onContextAction,
    this.activeIndicator,
    this.showBorder,
    this.color,
    this.borderColor,
    this.selectedColor,
    this.activeColor,
    this.tapEffectColor,
    this.onActiveChanged,
    this.onFocusChanged,
    this.onCloseConfirm,
    this.onClosed,
    this.draggable = true,
    this.groupId,
    this.onTransferOut,
    this.onTransferIn,
    this.autoTooltip = false,
    this.autoTooltipWaitDuration = ZoPopper.defaultWaitDuration,
    this.autoTooltipDirection = ZoPopperDirection.top,
    this.scrollIndicator = true,
  }) : assert(direction != Axis.vertical || (!wrapTabs && tabMinWidth == null)),
       assert(
         !transitionActiveStatus || selectionType == ZoSelectionType.single,
       );

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

  /// 活动 tab 被关闭时，是否自动切换活动状态到相邻 tab, 只对单选有效
  final bool transitionActiveStatus;

  /// 要固定在左侧显示的 tab 项，钉住的 tab 项不能会被`关闭其他`等间接操作关闭
  ///
  /// ⚠️：请勿直接传入非常量字面量
  final List<Object>? pinedTabs;

  /// [pinedTabs] 变更时触发，组件内部不管理 pin 状态，必须在此处将更新同步到 [pinedTabs] 内部才会实际变更
  final ValueChanged<List<Object>>? onPinedTabsChanged;

  /// 钉在左侧的 tab 只显示图标，对无图标的项和纵向tab无效，启用此项后，只能通过api取消固定，
  /// 可能需要在上下文菜单中提供相关操作
  final bool pinedTabsOnlyShowIcon;

  /// 当超出时，是否换行显示, 关闭可滚动查看超出部分，对纵向 tab 无效
  final bool wrapTabs;

  /// 显示风格
  final ZoTabsType type;

  /// 选中指示器风格
  final ZoTabsSelectedStyle selectedStyle;

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

  /// 简化 tab，只显示图标，仅设置了 icon 的 tab 有效
  final bool simplyTab;

  /// 要显示标记的 tab，可用展示一个圆形角标，可通过 [buildMarker] 自定义展示内容
  final Set<Object>? markers;

  /// 自定义 marks 节点
  final Widget Function(ZoTabsEntry entry)? buildMarker;

  /// 自定义文本节点的构造方式
  final Widget Function(ZoTabsEntry entry)? buildText;

  /// 是否启用上下文菜单
  final bool enableContextMenu;

  /// 对于无图标的内部上下文选项，是否自动填充左间距来将它们和有图标的项对齐
  final bool alignContextMenuOptions;

  /// 自定义上下文菜单内容
  final List<ZoOption> Function(
    ZoTabsInternalContextActions internalActions,
  )?
  customContextMenu;

  /// 触发上下文操作, 如果是内部操作，可返回 true 来跳过内部处理
  final bool Function(ZoTabsContextAction action)? onContextMenuTrigger;

  /// 监听上下文事件，传入后会完全覆盖内部的 [customContextMenu] / [onContextMenuTrigger]
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
  final Color? selectedColor;

  /// 活动状态颜色，活动状态的定义见 [onActiveChanged]
  final Color? activeColor;

  /// 点击时的反馈色
  final Color? tapEffectColor;

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

  /// 是否支持拖动 tab 调整顺序
  final bool draggable;

  /// 组 id, 具有相同组 id 的 [ZoTabs] 和其他 [ZoDND] 可以互相拖放
  final String? groupId;

  /// 当 Tab 被移动到另一个组件时触发 (本组件失去该 Tab), 同时也会触发 [onTabsChanged]
  final void Function(ZoTabsEntry entry)? onTransferOut;

  /// 当 Tab 从另一个组件移动进来时触发 (本组件获得该 Tab), 同时也会触发 [onTabsChanged]
  final void Function(ZoTabsEntry entry)? onTransferIn;

  /// label 显示不够或因为其他配置隐藏时，是否通过通过气泡组件显示 label，此配置对 [simplyTab] 也有效
  final bool autoTooltip;

  /// 设置后，[autoTooltip] 会延迟一段时间后打开
  final Duration? autoTooltipWaitDuration;

  /// 设置气泡提示方向
  final ZoPopperDirection autoTooltipDirection;

  /// 是否在可滚动方向显示阴影指示器
  final bool scrollIndicator;

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

  /// 该组件在更新时不会传入新对象，而是更改了内部值的 Iterable<Object>，需要主动跳过检测
  @override
  @protected
  bool get skipValueEqualCheck => true;

  bool get isHorizontal => widget.direction == Axis.horizontal;

  bool get wrapTabs => isHorizontal && widget.wrapTabs;

  /// 管理选中项
  late ZoSelector<Object, ZoTabsEntry> selector;

  /// 是否处于滚动状态
  bool loading = false;

  /// 用于快速查询固定的 tab
  final HashMap<Object, bool> _pinnedTabs = HashMap();

  /// 控制上下文菜单显示
  late ZoMenu _contextMenu;

  /// 最后一次触发上下文操作的 tab
  ZoTabsEntry? _currentContextMenuEntry;

  /// 通知keepAlive启用，防止在拖动过程在当前组件被销毁导致事件中断
  ListenableNotifier? _keepAliveNotifier;

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

    _contextMenu = ZoMenu(
      options: [],
      size: widget.size,
      dismissMode: ZoOverlayDismissMode.close,
      onTap: _onContextActionTap,
      autoFocus: true,
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

    if (_keepAliveNotifier != null) {
      _keepAliveNotifier!.dispose();
    }

    scrollController.dispose();
    selector.removeListener(_onSelectChanged);
    _contextMenu.disposeSelf();
    interactiveBoxStates.clear();
    _scrollNotificationDebouncer.cancel();
    _labelLayoutDatas.clear();
    _currentContextMenuEntry = null;
  }

  /// 同步 value 变更到 selector
  @override
  @protected
  void onPropValueChanged() {
    selector.batch(() {
      selector.setSelected(widget.value ?? []);
    }, false);
  }

  /// tab 是否被固定
  bool isPinned(Object value) {
    return _pinnedTabs[value] ?? false;
  }

  /// 批量关闭选项卡
  void closeTabs(List<Object> values) {
    final List<ZoTabsEntry> newTabs = [];
    final List<ZoTabsEntry> closeTabs = [];

    // 记录最后一个未关闭节点
    ZoTabsEntry? lastUnclosed;

    // 记录关闭项后方第一个未关闭节点
    ZoTabsEntry? afterFirstUnclosed;

    // 是否已命中 active 节点
    bool activeFlag = false;

    final transitionActiveStatus =
        widget.selectionType == ZoSelectionType.single &&
        widget.transitionActiveStatus &&
        values.isNotEmpty;

    for (final tab in tabs) {
      final isActive = values.contains(tab.value);

      if (transitionActiveStatus) {
        if (isActive) {
          activeFlag = true;
        }

        if (activeFlag && !isActive && afterFirstUnclosed == null) {
          afterFirstUnclosed = tab;
        }

        if (!activeFlag) {
          lastUnclosed = tab;
        }
      }

      if (isActive) {
        closeTabs.add(tab);
      } else {
        newTabs.add(tab);
      }
    }

    // 如果包含有效的选中项，并且启用了 transitionActiveStatus
    final ZoTabsEntry? newActiveTab = transitionActiveStatus && activeFlag
        ? (afterFirstUnclosed ?? lastUnclosed)
        : null;

    if (closeTabs.isNotEmpty) {
      tabs = newTabs;

      selector.batch(() {
        selector.unselectList(closeTabs.map((i) => i.value));

        if (newActiveTab != null) {
          selector.select(newActiveTab.value);
        }
      });

      for (final closed in closeTabs) {
        widget.onClosed?.call(closed);
      }
    } else {
      // 根上面区分设置，因为 unselectList 也会触发组件更新, 这样避免了多一次更新
      setState(() {
        tabs = newTabs;
      });
    }

    _onTapsChanged(tabs);
  }

  /// 关闭指定选项卡
  void close(Object value) {
    closeTabs([value]);
  }

  /// 关闭指定选项卡之外的所有选项卡
  void closeOthers(List<Object> values) {
    final List<Object> keepTabs = [];
    final List<Object> otherTabs = [];

    for (final tab in tabs) {
      if (values.contains(tab.value)) {
        keepTabs.add(tab.value);
      } else {
        otherTabs.add(tab.value);
      }
    }

    if (otherTabs.isNotEmpty) {
      closeTabs(otherTabs);
    }
  }

  /// 关闭指定选项卡之后的所有选项卡
  void closeAllAfter(Object value) {
    final List<Object> list = [];

    bool closeFlag = false;

    for (final tab in tabs) {
      if (closeFlag) {
        list.add(tab.value);
      }
      if (tab.value == value) {
        closeFlag = true;
      }
    }

    if (list.isNotEmpty) {
      closeTabs(list);
    }
  }

  /// 关闭指定选项卡之后的所有选项卡
  void closeAll() {
    if (tabs.isEmpty) return;

    selector.batch(selector.unselectAll, false);

    for (final closed in tabs) {
      widget.onClosed?.call(closed);
    }

    setState(() {
      tabs = [];
    });

    _onTapsChanged(tabs);
  }

  /// 执行 onManualCloseConfirm 确认后关闭 tab
  void _manualConfirmCloseTab(ZoTabsEntry entry) async {
    if (widget.onCloseConfirm == null) {
      closeTabs([entry.value]);
      return;
    }

    final confirm = await widget.onCloseConfirm!(entry);

    if (confirm) {
      closeTabs([entry.value]);
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

    final props = event.data as _MainContentProps;
    final entry = props.entry;

    final List<ZoOption> options = _getContextOptions(entry);

    if (options.isEmpty) return;

    _contextMenu.actions(() {
      _contextMenu.options = options;
      _contextMenu.offset = event.position;
    });

    _currentContextMenuEntry = entry;

    zoOverlay.open(_contextMenu);
  }

  /// 上下文选项点击
  void _onContextActionTap(ZoTreeDataNode<ZoOption> node) {
    if (_currentContextMenuEntry == null) return;

    final option = node.data;
    final isInternal = isInternalContextAction(option);

    if (widget.onContextMenuTrigger != null) {
      final ret = widget.onContextMenuTrigger!(
        ZoTabsContextAction(
          entry: _currentContextMenuEntry!,
          option: option,
          internal: isInternal,
          state: this,
        ),
      );

      if (ret) return;
    }

    if (!isInternal) return;

    final value = _currentContextMenuEntry!.value;

    switch (option.value as _ContextType) {
      case _ContextType.close:
        close(value);
      case _ContextType.closeOther:
        closeOthers([value]);
      case _ContextType.closeAll:
        closeAll();
      case _ContextType.closeAllAfter:
        closeAllAfter(value);
      case _ContextType.pin:
        pin(value);
      case _ContextType.unpin:
        unpin(value);
    }
  }

  /// 判断传入的操作是不是内部操作
  bool isInternalContextAction(ZoOption option) {
    return option.value is _ContextType;
  }

  /// 获取用于显示的上下文选项
  List<ZoOption> _getContextOptions(ZoTabsEntry entry) {
    final actions = ZoTabsInternalContextActions(
      closeActions: [],
      pinActions: [],
    );

    final locale = context.zoLocale;

    final isLast = tabs.lastOrNull == entry;

    /// 使用一个真实图标来作为左侧填充物
    final paddingIcon = widget.alignContextMenuOptions
        ? const Visibility.maintain(
            visible: false,
            child: Icon(Icons.check_box_outline_blank),
          )
        : null;

    actions.closeActions.addAll([
      ZoOption(
        leading: paddingIcon,
        title: Text(locale.close),
        value: _ContextType.close,
      ),
      ZoOption(
        leading: paddingIcon,
        title: Text(locale.closeOther),
        value: _ContextType.closeOther,
        enabled: tabs.length > 1,
      ),
      ZoOption(
        leading: paddingIcon,
        title: Text(locale.closeAllAfter),
        value: _ContextType.closeAllAfter,
        enabled: !isLast,
      ),
      ZoOption(
        leading: paddingIcon,
        title: Text(locale.closeAll),
        value: _ContextType.closeAll,
      ),
    ]);

    actions.pinActions.add(
      isPinned(entry.value)
          ? ZoOption(
              leading: const Icon(Icons.push_pin_outlined),
              title: Text(locale.unpin),
              value: _ContextType.unpin,
            )
          : ZoOption(
              leading: const Icon(Icons.push_pin_rounded),
              title: Text(locale.pin),
              value: _ContextType.pin,
            ),
    );

    List<ZoOption> options;

    if (widget.customContextMenu != null) {
      options = widget.customContextMenu!(actions);
    } else {
      options = [
        ...actions.closeActions,
        ZoOptionDivider(),
        ...actions.pinActions,
      ];
    }

    return options;
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

  /// 与 entry.value 为 key 存储 ZoInteractiveBox 实例，用来主动触发高亮等操作
  HashMap<Object, ZoInteractiveBoxState?> interactiveBoxStates = HashMap();

  void _refState(ZoTabsEntry entry, ZoInteractiveBoxState? interactiveState) {
    interactiveBoxStates[entry.value] = interactiveState;
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

    final isBackgroundSelectedStyle =
        widget.selectedStyle == ZoTabsSelectedStyle.background;

    final defaultSelectedColor = isBackgroundSelectedStyle
        ? style.selectedColor
        : style.hoverColor;

    final selectedColor = widget.selectedColor ?? defaultSelectedColor;

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

    /// 选中边框色
    BoxBorder? selectedBorder;

    /// 非 background 模式下如果显示边框，将选中边框色
    if (widget.selectedStyle != ZoTabsSelectedStyle.background &&
        widget.showBorder == true) {
      // 将选中边框色还原为灰色
      selectedBorder = Border.all(color: style.outlineColorVariant);
    }

    final selectedTextColor = isBackgroundSelectedStyle
        ? style.primaryColor
        : null;

    return tabs.map((i) {
      final selected = selector.isSelected(i.value);

      final textColor = selected ? selectedTextColor : null;

      final textStyle = TextStyle(
        fontSize: sizedFontSize,
        color: textColor,
        overflow: TextOverflow.ellipsis,
      );

      final iconData = IconThemeData(
        size: iconSize,
        color: textColor,
      );

      // 使用简化版本的 tab，用于固定且仅显示 icon 的场景
      final showSimpleTab = _shouldShowSimpleTab(i);

      final showMarker =
          widget.markers != null && widget.markers!.contains(i.value);

      final hasTrining =
          widget.showCloseButton || isPinned(i.value) || showMarker;

      EdgeInsets? padding;

      if (showSimpleTab) {
        // 简化tab单独设置边距，使其更方
        const pad = 2.0;
        padding = switch (widget.size ?? style.widgetSize) {
          ZoSize.medium => EdgeInsets.symmetric(horizontal: style.space2 + pad),
          ZoSize.large => EdgeInsets.symmetric(horizontal: style.space3),
          ZoSize.small => EdgeInsets.symmetric(horizontal: style.space1 + pad),
        };
      } else if (!hasTrining) {
        // 没有右侧内容，将右侧间距调整为和左侧一致
        padding = horizontalPadding.copyWith(right: horizontalPadding.left);
      } else {
        padding = horizontalPadding;
      }

      final contextMenuEnable =
          widget.enableContextMenu || widget.onContextAction != null;

      final tabWidget = DefaultTextStyle.merge(
        key: ValueKey(i.value),
        style: textStyle,
        child: IconTheme.merge(
          data: iconData,
          child: ZoInteractiveBox(
            key: ValueKey(i.value),
            height: tabHeight,
            // 启用 showSimpleTab 时允许更小的尺寸
            constraints: showSimpleTab ? null : constraints,
            focusBorderType: ZoInteractiveBoxFocusBorderType.origin,
            textStyle: textStyle,
            iconTheme: iconData,
            padding: padding,
            decorationPadding: decorationPadding,
            ref: (boxState) => _refState(i, boxState),
            foregroundWidget: selected
                ? _buildActiveIndicator(decorationPadding: decorationPadding)
                : null,
            focusOnTap: false,
            selected: selected,
            color: widget.color,
            selectedColor: selectedColor,
            activeColor: widget.activeColor,
            tapEffectColor: widget.tapEffectColor,
            selectedBorder: selectedBorder,
            style: widget.showBorder == true
                ? ZoInteractiveBoxStyle.border
                : ZoInteractiveBoxStyle.normal,
            radius: radius,
            onTap: _onTap,
            builder: _tabItemMainContent,
            onActiveChanged: _onActiveChanged,
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

      return _buildDragNode(
        child: tabWidget,
        entry: i,
        decorationPadding: decorationPadding,
      );
    }).toList();
  }

  /// 默认的拖动组id
  final _defaultDragGroup = Object();

  /// 拖动相关节点构造
  Widget _buildDragNode({
    required Widget child,
    required ZoTabsEntry entry,
    required EdgeInsets? decorationPadding,
  }) {
    if (!widget.draggable) return child;

    final paddingSpace = isHorizontal
        ? decorationPadding?.right
        : decorationPadding?.bottom;

    // 将指示线的位置修正到刚好对齐padding
    EdgeInsets? dropIndicatorPadding;

    // 如果有填充距离，用来调整指示线位置
    if (paddingSpace != null) {
      const startSpace = 1.0;
      final endSpace = -paddingSpace + startSpace;
      dropIndicatorPadding = isHorizontal
          ? EdgeInsets.fromLTRB(startSpace, 0, endSpace, 0) // 去掉右边距并添加1px
          : EdgeInsets.fromLTRB(0, startSpace, 0, endSpace);
    }

    return Builder(
      key: ValueKey(entry.value),
      builder: (context) {
        return ZoDND(
          groupId: widget.groupId ?? _defaultDragGroup,
          data: _DragContextData(
            entry: entry,
            state: this,
          ),
          draggable: entry.enable,
          droppablePosition: isHorizontal
              ? const ZoDNDPosition(left: true, right: true)
              : const ZoDNDPosition(top: true, bottom: true),
          dropIndicatorPadding: dropIndicatorPadding,
          feedback: ZoDNDFeedbackBadge(child: Text(entry.label)),
          onAccept: _onDragAccept,
          onDragStart: MemoCallback(
            (ZoDNDEvent e) => _onDragStart(
              event: e,
              entry: entry,
              context: context,
            ),
          ),
          onDragEnd: MemoCallback(
            (ZoDNDEvent e) => _onDragEnd(
              event: e,
              entry: entry,
              context: context,
            ),
          ),
          child: child,
        );
      },
    );
  }

  /// 拖放成功处理
  ///
  /// - tab互相拖动时，从拖出的组件移除tab，并移除拖入组件相同value的tab，防止出现重复
  /// - 拖动到 dropArea 时，从拖出的组件移除tab，触发 dropArea 的对应事件
  void _onDragAccept(ZoDNDDropEvent event) {
    final dragData = event.dragDND.data as _DragContextData;
    final dropData = event.dropDND.data as _DragContextData;

    final dropPosition = event.activePosition;

    // 处理拖动发起组件的状态更新
    if (dragData.state.mounted) {
      dragData.state.setState(() {
        dragData.state.tabs = dragData.state.tabs
            .where((i) => i.value != dragData.entry.value)
            .toList();

        // 取消选中拖出标签
        dragData.state.selector.batch(() {
          selector.unselect(dragData.entry.value);
        }, false);

        dragData.state._onTapsChanged(dragData.state.tabs);
      });

      dragData.state.widget.onTransferOut?.call(dragData.entry);
    }

    // 接收组件（当前）状态更新
    dropData.state.setState(() {
      final dropValue = dropData.entry.value;

      // 先移除已有重复节点
      final list = dropData.state.tabs
          .where(
            (i) => i.value != dragData.entry.value,
          )
          .toList();

      // 目标节点的索引
      final index = list.indexWhere((i) => i.value == dropValue);

      if (index == -1) return;

      final isBefore = isHorizontal ? dropPosition.left : dropPosition.top;
      final isAfter = isHorizontal ? dropPosition.right : dropPosition.bottom;

      if (!isBefore && !isAfter) return;

      int newIndex;

      if (isBefore) {
        newIndex = index;
      } else {
        newIndex = index + 1;
      }

      newIndex = newIndex.clamp(0, list.length);

      dropData.state.setState(() {
        list.insert(newIndex, dragData.entry);

        dropData.state.tabs = list;
      });

      dropData.state._onTapsChanged(dropData.state.tabs);

      // 高亮被拖入标签
      WidgetsBinding.instance.addPostFrameCallback((d) {
        final state = interactiveBoxStates[dragData.entry.value];

        if (state == null || !mounted) return;

        state.triggerHighlight();
      });

      dropData.state.widget.onTransferIn?.call(dragData.entry);
    });
  }

  void _onDragStart({
    required ZoDNDEvent event,
    required ZoTabsEntry entry,
    required BuildContext context,
  }) {
    final dragData = event.dragDND.data as _DragContextData;

    // 拖动组件保活，防止销毁导致事件中断
    if (dragData.entry.value == entry.value) {
      // 防止有遗漏的事件
      if (_keepAliveNotifier != null) {
        _keepAliveNotifier!.notifyListeners();
        _keepAliveNotifier!.dispose();
      }

      _keepAliveNotifier = ListenableNotifier();

      KeepAliveNotification(_keepAliveNotifier!).dispatch(context);
    }
  }

  void _onDragEnd({
    required ZoDNDEvent event,
    required ZoTabsEntry entry,
    required BuildContext context,
  }) {
    final dragData = event.dragDND.data as _DragContextData;

    // 仅处理拖动节点的事件
    if (dragData.entry.value == entry.value && _keepAliveNotifier != null) {
      _keepAliveNotifier!.notifyListeners();
      _keepAliveNotifier!.dispose();
      _keepAliveNotifier = null;
    }
  }

  /// 活动状态变更，如果启用了 autoTooltip 会按需出现气泡显示
  void _onActiveChanged(ZoTriggerToggleEvent event) {
    widget.onActiveChanged?.call(event);

    if (!event.toggle) {
      _labelPopperManager?.delayClose();
      if (_labelPopperManager != null &&
          _labelPopperManager!.entry.currentOpen) {
        _labelPopperManager!.delayClose();
      }
      return;
    }

    if (!widget.autoTooltip) return;

    final props = event.data as _MainContentProps;

    final isOverflow = _isLabelOverflow(props.entry);

    if (!isOverflow) return;

    final obj = event.context.findRenderObject() as RenderBox;
    final tabRect = obj.localToGlobal(Offset.zero) & obj.size;

    _labelPopperManager ??= ZoPopperManager(
      entry: ZoPopperEntry(
        content: Text(props.entry.label),
        rect: tabRect,
        dismissMode: ZoOverlayDismissMode.close,
        distance: style.space1,
        direction: widget.autoTooltipDirection,
        customWrap: (context, child) => IgnorePointer(child: child),
      ),
    );

    final entry = _labelPopperManager!.entry;

    final isDelay =
        widget.autoTooltipWaitDuration != null &&
        widget.autoTooltipWaitDuration != Duration.zero;

    entry.actions(() {
      entry.content = Text(props.entry.label);
      entry.rect = tabRect;
      entry.direction = widget.autoTooltipDirection;
    });

    _labelPopperManager!.open(
      waitDuration: widget.autoTooltipWaitDuration,
      target: props.entry.value,
      beforeOpen: () {
        if (isDelay && context.mounted) {
          final obj = event.context.findRenderObject() as RenderBox;
          final tabRect = obj.localToGlobal(Offset.zero) & obj.size;
          entry.rect = tabRect;
        }
      },
    );
  }

  /// 构造活动 tab 指示器
  Widget? _buildActiveIndicator({
    EdgeInsets? decorationPadding,
  }) {
    Widget? indicator;

    if (widget.activeIndicator != null) {
      indicator = widget.activeIndicator!;
    } else if (widget.selectedStyle == ZoTabsSelectedStyle.indicationLine) {
      final side = BorderSide(
        color: style.primaryColor,
        width: 1.4,
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

    if (indicator == null) return null;

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

    if (widget.autoTooltip) {
      label = RenderTrigger(
        onLayoutImmediately: (box) => _onLabelLayout(
          renderBox: box,
          style: props.textStyle,
          entry: entry,
        ),
        child: label,
      );
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

    // 固定项
    if (showIconOnly) {
      label = null;

      // 如果有marker显示，不隐藏
      if (!showMarker) icon = null;
    }

    if (isHorizontal) {
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
      if (label != null)
        Expanded(
          child: label,
        ),
      ?icon,
    ];
  }

  /// 存储 label 布局信息
  final HashMap<Object, _LabelLayoutData> _labelLayoutDatas = HashMap();

  /// label 布局时存储必要信息，用于 active 时判断是否需要根据隐藏显示气泡 label
  void _onLabelLayout({
    required RenderBox renderBox,
    required TextStyle style,
    required ZoTabsEntry entry,
  }) {
    _labelLayoutDatas[entry.value] = _LabelLayoutData(
      label: entry.label,
      style: style,
      maxWidth: renderBox.constraints.maxWidth,
    );
  }

  /// 根据 _labelLayoutDatas 检测 label 是否超出
  bool _isLabelOverflow(ZoTabsEntry entry) {
    // 简单tab始终视为超出
    if (_shouldShowSimpleTab(entry)) return true;

    final data = _labelLayoutDatas[entry.value];

    if (data == null) return false;

    return hasTextOverflow(
      data.label,
      data.style,
      textScaler: MediaQuery.textScalerOf(context),
      textDirection: Directionality.of(context),
      maxWidth: data.maxWidth,
    );
  }

  bool _shouldShowSimpleTab(ZoTabsEntry entry) {
    return (widget.simplyTab && entry.icon != null) || // 主动配置
        (isHorizontal && // 检测配置
            isPinned(entry.value) &&
            widget.pinedTabsOnlyShowIcon &&
            entry.icon != null);
  }

  /// 构造尾随区域，包含关闭按钮、mark标记等
  Widget? _buildTrailingNode({
    required bool highlight,
    required _MainContentProps props,
  }) {
    if (!props.hasTrining) {
      return null;
    }

    final showSimpleTab = props.showSimpleTab;

    if (showSimpleTab) return null;

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
        padding: const EdgeInsets.all(0),
        focusBorderType: ZoInteractiveBoxFocusBorderType.origin,
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
      padding: const EdgeInsets.all(0),
      focusBorderType: ZoInteractiveBoxFocusBorderType.origin,
      iconTheme: iconData,
      onTap: pinned
          ? (e) => unpin(entry.value)
          : (e) => _manualConfirmCloseTab(entry),
      child: (widget.alwaysShowCloseButton || highlight) ? icon : null,
    );
  }

  final Debouncer _scrollNotificationDebouncer = Debouncer(
    delay: Durations.medium1,
  );

  bool _onScrollNotification(ScrollNotification notification) {
    loading = true;
    // if (_labelPopperManager != null) _labelPopperManager!.enable = false;

    _scrollNotificationDebouncer.run(() {
      // if (_labelPopperManager != null) _labelPopperManager!.enable = true;
      loading = false;
    });
    return false;
  }

  /// 列表型容器
  Widget _withListView({
    required double tabHeight,
    required List<Widget> children,
  }) {
    final child = NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView(
          scrollDirection: widget.direction,
          controller: scrollController,
          // 纵向滚动时可以使用固定高度优化
          itemExtent: isHorizontal ? null : tabHeight,
          children: children,
        ),
      ),
    );

    if (!widget.scrollIndicator) return child;

    return ScrollIndicatorContainer(
      axis: widget.direction,
      child: child,
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
            // warp下使用与tab项右边距相同的边距
            itemSpace: decorationPadding?.right ?? 2,
            children: children,
          )
        : _withListView(
            tabHeight: tabHeight,
            children: children,
          );

    if (widget.draggable) {
      child = ZoDND(
        proxy: true,
        groupId: widget.groupId ?? _defaultDragGroup,
        child: child,
      );
    }

    child = _buildFixedTrailing(child, tabHeight);

    return SizedBox(
      // 仅横向非 wrap 需要设置容器高度
      height: (isHorizontal && !wrapTabs) ? tabHeight : null,
      child: child,
    );
  }
}

/// 用于 overflow label 显示的层，所有 tab 复用一个层，它在整个应用生命周期存在
ZoPopperManager? _labelPopperManager;

/// 上下文操作类型
enum _ContextType {
  close,
  closeOther,
  closeAll,
  closeAllAfter,
  pin,
  unpin,
}

/// 通过 ZoInteractiveBox 共享的一些状态
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

/// 在拖动事件中共享的状态
class _DragContextData {
  _DragContextData({
    required this.entry,
    required this.state,
  });

  ZoTabsEntry entry;

  ZoTabsState state;
}

/// label 布局时写入的特定信息，目前用于判断遮挡状态
class _LabelLayoutData {
  _LabelLayoutData({
    required this.label,
    required this.style,
    required this.maxWidth,
  });

  String label;

  TextStyle style;

  double maxWidth;
}

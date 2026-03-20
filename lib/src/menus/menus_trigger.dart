/// 组合 [ZoMenu] 和 [ZoTreeMenu] 的菜单触发器组件
library;

import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:zo/zo.dart";

/// 选项层类型
enum ZoMenusTriggerType {
  /// 常规菜单
  ///
  /// 子级以级联菜单展示
  menu,

  /// 树形菜单
  ///
  /// 子级以内联树展开展示
  treeMenu,
}

/// 触发目标构造参数
class ZoMenusTriggerBuilderArgs {
  const ZoMenusTriggerBuilderArgs({
    required this.context,
    required this.widget,
    required this.state,
    required this.focusNode,
    required this.bindFocusWrapper,
  });

  /// 构建上下文
  final BuildContext context;

  /// 组件实例
  final ZoMenusTrigger widget;

  /// 状态实例
  ///
  /// 可通过 [ZoMenusTriggerState.selector] 和 [ZoMenusTriggerState.menuEntry] 读取选中项与弹层
  ///
  /// 可通过 [ZoMenusTriggerState.toggle]、[ZoMenusTriggerState.openMenu]、[ZoMenusTriggerState.closeMenu] 控制开关
  final ZoMenusTriggerState state;

  /// 绑定到触发目标上的焦点节点
  ///
  /// 主要用于上层组件透出焦点能力
  final FocusNode focusNode;

  /// 绑定焦点事件到指定子节点
  ///
  /// 子级存在多个可聚焦节点时可手动调用
  ///
  /// 不调用时会自动包裹在最外层
  final Widget Function(Widget child) bindFocusWrapper;
}

/// 触发目标构造器
typedef ZoMenusTriggerBuilder =
    Widget Function(
      ZoMenusTriggerBuilderArgs args,
    );

/// 将 [ZoMenu] 或 [ZoTreeMenu] 绑定到任意触发目标
///
/// 负责菜单实例控制、定位、焦点和快捷键处理
///
/// 是 [ZoSelect] 和 [ZoDropdown] 的底层能力组件，常见场景优先使用这些上层组件
class ZoMenusTrigger extends ZoFormWidget<Iterable<Object>> {
  const ZoMenusTrigger({
    super.key,
    super.value,
    super.onChanged,
    required this.options,
    this.builder,
    this.selectionType = ZoSelectionType.single,
    this.branchSelectable = false,
    this.selectMenuType = ZoMenusTriggerType.menu,
    this.toolbar,
    this.size,
    this.menuWidth,
    this.maxSelectedShowNumber = 10,
    this.enabled = true,
    this.openOnFocus = true,
    this.focusNode,
  });

  /// 选项列表
  final List<ZoOption> options;

  /// 触发目标构造器
  ///
  /// 可在构造内容中调用 [ZoMenusTriggerState.toggle] 控制开关
  ///
  /// 需要焦点行为时建议渲染可聚焦组件并绑定焦点节点
  final ZoMenusTriggerBuilder? builder;

  /// 选择类型
  ///
  /// 默认为单选
  final ZoSelectionType selectionType;

  /// 选项层类型
  final ZoMenusTriggerType selectMenuType;

  /// 分支节点是否可选
  final bool branchSelectable;

  /// 列表顶部自定义内容
  final Widget? toolbar;

  /// 菜单尺寸
  final ZoSize? size;

  /// 菜单宽度
  ///
  /// 不传时与触发目标宽度一致
  final double? menuWidth;

  /// 文本拼接时显示的最大选中项数量
  final int maxSelectedShowNumber;

  /// 是否启用
  final bool enabled;

  /// 触发目标获取焦点时是否自动打开菜单
  final bool openOnFocus;

  /// 外部传入的触发目标焦点
  final FocusNode? focusNode;

  @override
  State<StatefulWidget> createState() {
    return ZoMenusTriggerState();
  }
}

class ZoMenusTriggerState<W extends ZoMenusTrigger>
    extends ZoFormState<Iterable<Object>, W> {
  /// 菜单弹层实例
  late ZoMenuEntry menuEntry;

  /// 选中控制器
  ZoSelector<Object, ZoOption> get selector => menuEntry.selector;

  /// 选项控制器
  ZoOptionController get optionController => menuEntry.controller;

  /// 触发目标是否聚焦
  bool isFocus = false;

  /// 触发目标焦点节点
  late FocusNode focusNode;

  /// 当前状态下是否允许打开菜单
  @protected
  bool get canOpenMenu {
    return widget.enabled;
  }

  /// 切换菜单开关
  void toggle() {
    if (menuEntry.currentOpen) {
      closeMenu();
    } else {
      openMenu();
    }
  }

  /// 打开菜单
  void openMenu() {
    if (!canOpenMenu) return;

    if (!menuEntry.currentOpen) {
      stopOpenTimer();
      _openTimer = Timer(Duration.zero, menuEntry.open);
    }
  }

  /// 关闭菜单
  void closeMenu() {
    if (menuEntry.currentOpen) {
      stopOpenTimer();
      menuEntry.close();
    }
  }

  /// 获取已选中项列表
  ///
  /// 可传入长度限制, 当值没有对应选项时，`option` 为 `null`
  List<(Object value, ZoOption? option)> getSelectedOptionList(int length) {
    final List<(Object value, ZoOption? option)> list = [];

    final selected = selector.getSelected();

    for (final val in selected) {
      final node = menuEntry.controller.getNode(val);
      list.add((val, node?.data));
      if (list.length >= length) break;
    }

    return list;
  }

  /// 获取用于展示的选中文本
  ///
  /// 超出 [ZoMenusTrigger.maxSelectedShowNumber] 时追加 `...`
  String getSelectedText() {
    final selected = getSelectedOptionList(widget.maxSelectedShowNumber);
    final length = selector.getSelected().length;

    final showMoreTips = length > widget.maxSelectedShowNumber;

    var text = selected
        .map((opt) {
          final (value, option) = opt;
          return option?.getTitleText() ?? value.toString();
        })
        .join(", ");

    if (showMoreTips) {
      text += ", ...";
    }

    return text;
  }

  /// 触发目标最近一次绘制区域
  Rect? _lastRect;

  /// 打开快捷键
  final _downActivator = const SingleActivator(
    LogicalKeyboardKey.arrowDown,
    includeRepeats: false,
  );

  /// 关闭快捷键
  final _closeActivator = const SingleActivator(
    LogicalKeyboardKey.escape,
    includeRepeats: false,
  );

  /// 目标位置更新节流
  // final _rectUpdateThrottler = Throttler(
  //   delay: Durations.short1,
  // );

  @override
  @protected
  void initState() {
    super.initState();

    _init();

    focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  @protected
  void didUpdateWidget(W oldWidget) {
    super.didUpdateWidget(oldWidget);

    menuEntry.actions(() {
      if (oldWidget.options != widget.options) {
        menuEntry.options = widget.options;
      }
      if (oldWidget.selectionType != widget.selectionType) {
        menuEntry.selectionType = widget.selectionType;
      }
      if (oldWidget.branchSelectable != widget.branchSelectable) {
        menuEntry.branchSelectable = widget.branchSelectable;
      }
      if (oldWidget.size != widget.size) {
        menuEntry.size = widget.size;
      }
      if (oldWidget.toolbar != widget.toolbar) {
        menuEntry.toolbar = widget.toolbar;
      }
      if (oldWidget.focusNode != widget.focusNode) {
        // 如果旧的focusNode是内部创建的，将其销毁
        if (oldWidget.focusNode != focusNode) {
          focusNode.dispose();
        }
        focusNode = widget.focusNode ?? FocusNode();
      }
    }, false);
  }

  @override
  @protected
  void dispose() {
    super.dispose();
    stopOpenTimer();

    selector.removeListener(_onSelectChanged);
    menuEntry.openChangedEvent.off(onOpenChanged);
    menuEntry.disposeSelf();

    // 如果旧的focusNode是内部创建的，将其销毁
    if (widget.focusNode != focusNode) {
      focusNode.dispose();
    }
  }

  /// 初始化菜单实例和监听
  void _init() {
    if (widget.selectMenuType == ZoMenusTriggerType.menu) {
      menuEntry = _getMenu();
    } else {
      menuEntry = _getTreeMenu();
    }

    selector.addListener(_onSelectChanged);
    menuEntry.openChangedEvent.on(onOpenChanged);
  }

  ZoMenuEntry _getMenu() {
    return ZoMenu(
      options: widget.options,
      selected: value,
      selectionType: widget.selectionType,
      branchSelectable: widget.branchSelectable,
      size: widget.size,
      toolbar: widget.toolbar,
      dismissMode: ZoOverlayDismissMode.close,
      direction: ZoPopperDirection.bottomLeft,
      autoFocus: false, // 手动控制
      inheritWidth: false,
      // height/width/matchString/autoFocus
    );
  }

  ZoMenuEntry _getTreeMenu() {
    return ZoTreeMenu(
      options: widget.options,
      selected: value,
      selectionType: widget.selectionType,
      branchSelectable: widget.branchSelectable,
      size: widget.size,
      toolbar: widget.toolbar,
      dismissMode: ZoOverlayDismissMode.close,
      direction: ZoPopperDirection.bottomLeft,
      autoFocus: false, // 手动控制
      // height/width/matchString/autoFocus
    );
  }

  /// 处理触发目标焦点变化
  ///
  /// 聚焦时尝试打开菜单
  ///
  /// 失焦且菜单未被按压、菜单内无焦点时关闭菜单
  void _onFocusChanged(bool focus) {
    // 聚焦时显示下拉层, 失焦时，延迟一定时间，如果下一焦点不是当前层或未处于按下则关闭
    if (focus && widget.openOnFocus && canOpenMenu) {
      final lastCloseTime = menuEntry.lastCloseTime;

      if (lastCloseTime != null) {
        final diff = DateTime.now().difference(lastCloseTime);

        if (diff > const Duration(milliseconds: 80)) {
          openMenu();
        }
      } else {
        openMenu();
      }
    } else if (!menuEntry.pressed && !menuEntry.focusScopeNode.hasFocus) {
      menuEntry.close();
    }

    setState(() {
      isFocus = focus;
    });
  }

  /// 层打开状态变更
  @protected
  void onOpenChanged(bool open) {
    setState(() {});
  }

  /// 同步选中项到 value 并刷新
  void _onSelectChanged() {
    value = selector.getSelected().toSet();
    setState(() {});
  }

  /// 延迟打开定时器
  ///
  /// 用于给其他事件留出抢占机会, 目前是用于 select 中点击 tag 的关闭按钮时,
  /// 防止层打开
  Timer? _openTimer;

  /// 清理延迟打开定时器
  @protected
  void stopOpenTimer() {
    _openTimer?.cancel();
    _openTimer = null;
  }

  /// 处理关闭快捷键
  KeyEventResult _onShortcutsClose() {
    menuEntry.close();
    return KeyEventResult.handled;
  }

  /// 处理打开快捷键
  KeyEventResult _onShortcutsOpen() {
    if (!canOpenMenu) return KeyEventResult.ignored;

    if (menuEntry.currentOpen) {
      menuEntry.focusChild();
    } else {
      openMenu();
    }

    return KeyEventResult.handled;
  }

  /// 同步外部 value 到 selector
  @override
  @protected
  void onPropValueChanged() {
    // 立即更新，但避免进行通知
    selector.batch(() {
      selector.setSelected(widget.value ?? {});
    }, false);

    // 延迟通知层进行更新
    WidgetsBinding.instance.addPostFrameCallback((d) {
      menuEntry.changed();
    });
  }

  /// 记录触发目标区域并同步菜单定位
  @protected
  void onPaint(RenderBox box) {
    _lastRect = box.localToGlobal(Offset.zero) & box.size;

    _updateOverlayPosition(_lastRect!);

    // _rectUpdateThrottler.run(() {
    //   _updateOverlayPosition(_lastRect!);
    // });
  }

  /// 根据触发目标位置更新菜单定位信息
  void _updateOverlayPosition(Rect rect) {
    menuEntry.actions(() {
      menuEntry.rect = _lastRect;

      if (widget.menuWidth != null) {
        menuEntry.width = widget.menuWidth!;
      } else {
        menuEntry.width = rect.width;
      }
    }, menuEntry.currentOpen);
  }

  /// 处理触发目标键盘事件
  KeyEventResult _keyEvent(FocusNode node, KeyEvent event) {
    if (ZoShortcutsHelper.checkEvent(_closeActivator, event)) {
      return _onShortcutsClose();
    } else if (ZoShortcutsHelper.checkEvent(_downActivator, event)) {
      return _onShortcutsOpen();
    }
    return KeyEventResult.ignored;
  }

  /// 绑定焦点与键盘事件到指定节点
  @protected
  Widget bindFocusWrapper(Widget child) {
    return Focus(
      canRequestFocus: widget.enabled,
      onKeyEvent: _keyEvent,
      onFocusChange: _onFocusChanged,
      skipTraversal: true,
      child: child,
    );
  }

  @protected
  Widget buildTarget(BuildContext context, Widget child) {
    return RenderTrigger(
      onPaint: onPaint,
      child: TapRegion(
        groupId: menuEntry.groupId,
        child: child,
      ),
    );
  }

  /// 构建触发目标并补齐默认焦点包装
  @override
  @protected
  Widget build(BuildContext context) {
    if (widget.builder == null) {
      return const SizedBox.shrink();
    }

    var bindFlag = false;

    Widget localBind(Widget child) {
      bindFlag = true;
      return bindFocusWrapper(child);
    }

    final args = ZoMenusTriggerBuilderArgs(
      context: context,
      widget: widget,
      state: this,
      focusNode: focusNode,
      bindFocusWrapper: localBind,
    );

    var child = widget.builder!(args);

    // 未手动绑定时自动包裹 focus 容器
    if (!bindFlag) {
      child = bindFocusWrapper(child);
    }

    return buildTarget(context, child);
  }
}

import "dart:collection";

import "package:flutter/material.dart";
import "package:zo/zo.dart";

/// 用于 accordion 实现，面变展开时会进行通知，如果父级拥有相同父级应关闭面板
final _accordionTrigger =
    EventTrigger<(Element? parent, BuildContext current)>();

/// 根据组id按组存储所有面板实例，无分组的面板不存放
HashMap<Object, HashSet<ZoExpanderState>> _groupedMap = HashMap();

/// 支持展开/收起的容器，包含固定显示的顶部区域和可收起的内容区域。
///
/// 组操作： [ZoExpanderState] 实例或其提供的 [ZoExpanderState.openToLevel] 等 api
/// 可以批量操作实例的展开、收起状态
///
/// 表单控件：组件支持通过 [value] / [onChanged] 接口作为表单控件使用
///
/// 嵌套面板：[ZoExpander] 内部存在其他 [ZoExpander] 时，彼此都会被视为嵌套面板，
/// 子面板左侧会添加缩进，并可配置参考线等
///
/// 性能：默认情况下，内容在首次初始化时才挂载，并在再次关闭时保持状态，可通过 [mountOnEnter]
/// 和 [unmountOnExit] 调整行为，在需要大量渲染
class ZoExpander extends ZoFormWidget<bool> {
  const ZoExpander({
    super.key,
    required this.title,
    required this.child,
    this.describe,
    this.trailing,
    this.headerBuilder,
    this.size,
    this.indentLine = true,
    this.groupId,
    this.accordion = false,
    this.enable = true,
    this.duration = Durations.short4,
    this.curve,
    this.mountOnEnter = true,
    this.unmountOnExit = false,
    this.ref,
  });

  /// 标题
  final Widget title;

  /// 面板内容
  final Widget child;

  /// 显示在标题下方的描述
  final Widget? describe;

  /// 标题右侧显示的内容
  final Widget? trailing;

  /// 完全自定义顶部内容
  final Widget Function(ZoExpanderState state)? headerBuilder;

  /// 组件尺寸
  final ZoSize? size;

  /// 显示缩进参考线，仅对面板包含嵌套关系时有效
  final bool indentLine;

  /// 组id，可通过 [ZoExpander] 上提供的静态方法批量控制展开、折叠等
  final Object? groupId;

  /// 手风琴模式，同级的 [ZoExpander] 只会同时打开一个，只会影响同级组件中同样启用 [accordion]
  /// 的组件
  final bool accordion;

  /// 是否启用
  final bool enable;

  /// 动画持续时间
  final Duration duration;

  /// 展开动画曲线
  final Curve? curve;

  /// 如果初始 open 不是 true, 是否需要挂载组件
  final bool mountOnEnter;

  /// 关闭后是否销毁组件
  final bool unmountOnExit;

  /// 获取 state 的引用, 会在实例可用、销毁时调用，可用来便捷的访问 state 而无需创建 globalKey
  final void Function(ZoExpanderState? state)? ref;

  @override
  State<ZoExpander> createState() => ZoExpanderState();
}

class ZoExpanderState extends ZoFormState<bool, ZoExpander> {
  /// 是否包含父面板或子面板
  bool get nested => _parentLinker != null || _children.isNotEmpty;

  /// 面板层级，如果嵌套在其他面板内，会有更高的层级
  int get level => _level;
  int _level = 0;

  /// 子面板
  final HashSet<ZoExpanderState> _children = HashSet();

  /// 父面板
  _ExpansibleLinker? _parentLinker;

  late ZoStyle _style;

  /// 展开指定组的所有 [ZoExpander]
  static void openAll(Object groupId) {
    final group = _groupedMap[groupId];

    if (group == null) return;

    for (final element in group) {
      element.value = true;
    }
  }

  static void closeAll(Object groupId) {
    final group = _groupedMap[groupId];

    if (group == null) return;

    for (final element in group) {
      element.value = false;
    }
  }

  /// 展开指定组指定层级的所有 [ZoExpander]，如果它们存在未展开的父级，也会一同展开
  static void openToLevel(Object groupId, int level) {
    final group = _groupedMap[groupId];

    if (group == null) return;

    for (final element in group) {
      if (element.level != level) continue;
      openToRoot(element);
    }
  }

  /// 展开指定层和其所有父级
  static void openToRoot(ZoExpanderState state) {
    ZoExpanderState? current = state;

    while (current != null) {
      current.value = true;
      current = current._parentLinker?.current;
    }
  }

  /// 切换组件展开状态
  void toggle() {
    value = !nonNullValue;
  }

  @protected
  @override
  bool? get fallbackValue => false;

  @override
  @protected
  void initState() {
    super.initState();

    _accordionTrigger.on(_accordionHandle);

    _storageToGroupMap(widget.groupId);

    widget.ref?.call(this);
  }

  @override
  @protected
  void didUpdateWidget(covariant ZoExpander oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.groupId != widget.groupId) {
      _removeFromGroupMap(oldWidget.groupId);
      _storageToGroupMap(widget.groupId);
    }
  }

  @override
  @protected
  void dispose() {
    widget.ref?.call(null);

    _accordionTrigger.off(_accordionHandle);

    if (_parentLinker != null) {
      _parentLinker!.current._children.remove(this);
      _parentLinker = null;
    }

    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _parentLinker = _ExpansibleLinker.maybeOf(context);

    if (_parentLinker != null) {
      final alreadyContain = _parentLinker!.current._children.contains(this);

      if (!alreadyContain) {
        final isEmpty = _parentLinker!.current._children.isEmpty;
        _parentLinker!.current._children.add(this);

        // 父级未注册子级时，需要主动更新，方便其立即根据 nested 状态更新ui
        if (isEmpty) {
          WidgetsBinding.instance.addPostFrameCallback((d) {
            _parentLinker!.current.setState(() {});
          });
        }
      }

      _level = _parentLinker!.current.level + 1;
    }
  }

  @override
  @protected
  void onChanged(bool? newValue) {
    if (widget.accordion && nonNullValue) {
      _accordionTrigger.emit((_getParentElement(), context));
    }

    super.onChanged(newValue);
  }

  @override
  @protected
  void onPropValueChanged() {
    if (widget.accordion && nonNullValue) {
      _accordionTrigger.emit((_getParentElement(), context));
    }
  }

  /// 将实例存储到指定的组
  void _storageToGroupMap(Object? groupId) {
    if (groupId == null) return;

    var group = _groupedMap[groupId];

    if (group == null) {
      group = HashSet();
      _groupedMap[groupId] = group;
    }

    group.add(this);
  }

  /// 将实例从指定组移除
  void _removeFromGroupMap(Object? groupId) {
    if (groupId == null) return;

    final group = _groupedMap[groupId];

    if (group != null) {
      group.remove(groupId);
    }
  }

  /// 接收 accordion 展开通知，符合条件时关闭自身
  void _accordionHandle((Element? parent, BuildContext current) args) {
    if (!widget.accordion || args.$2 == context) return;

    final parentElement = _getParentElement();

    if (parentElement != null && parentElement == args.$1) {
      value = false;
    }
  }

  void _onTap(ZoTriggerEvent event) {
    toggle();
  }

  Element? _getParentElement() {
    Element? firstElement;

    // 查找首个父级
    context.visitAncestorElements((el) {
      firstElement = el;
      return false;
    });

    return firstElement;
  }

  Widget _headerBuilder() {
    if (widget.headerBuilder != null) widget.headerBuilder!(this);

    final padding = switch (widget.size ?? _style.widgetSize) {
      ZoSize.small => const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      ZoSize.medium => const EdgeInsets.all(4),
      ZoSize.large => const EdgeInsets.all(6),
    };

    final fontSize = _style.getSizedFontSize(widget.size);

    return DefaultTextStyle.merge(
      key: const ValueKey("__head__"),
      style: TextStyle(fontSize: fontSize),
      child: ZoInteractiveBox(
        color: _style.surfaceContainerColor,
        enableColorEffect: false,
        style: ZoInteractiveBoxStyle.border,
        radius: BorderRadius.circular(_style.borderRadius),
        padding: padding,
        focusOnTap: false,
        enabled: widget.enable,
        onTap: _onTap,
        child: ZoTile(
          horizontalSpacing: 0,
          verticalSpacing: 0,
          // 单行时保持居中对齐
          crossAxisAlignment: widget.describe == null
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          leading: AnimatedRotation(
            turns: nonNullValue ? 0.25 : 0,
            duration: widget.duration,
            curve: widget.curve ?? ZoTransition.defaultCurve,
            child: const Icon(Icons.arrow_right_rounded),
          ),
          header: widget.title,
          content: widget.describe,
          trailing: widget.trailing,
        ),
      ),
    );
  }

  Widget _bodyBuilder(ZoTransitionBuilderArgs<double> args) {
    final indentLine = nested && widget.indentLine
        ? BorderSide(color: _style.outlineColor)
        : BorderSide.none;

    final horizontalPadding = _style.space1;
    final verticalPadding = _style.space2;

    final identSize = nested ? _style.space5 : 0.0;

    // 调整参考线偏移和尺寸，防止和容器尺寸贴合过紧
    const indentLineOffset = 4.0;

    return SizeTransition(
      sizeFactor: args.animation,
      // 从顶部开始收缩
      axisAlignment: -1,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          if (nested)
            Positioned(
              width: indentLineOffset * 2,
              left: indentLineOffset,
              top: indentLineOffset * 2,
              bottom: indentLineOffset * 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    left: indentLine,
                    bottom: indentLine,
                  ),
                ),
              ),
            ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              // 嵌套视图下左侧显示为缩进尺寸
              nested ? identSize : horizontalPadding,
              verticalPadding,
              // 嵌套视图下不添加右边距
              nested ? 0 : horizontalPadding,
              verticalPadding,
            ),
            child: widget.child,
          ),
        ],
      ),
    );
  }

  @override
  @protected
  Widget build(BuildContext context) {
    _style = context.zoStyle;

    return _ExpansibleLinker(
      current: this,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headerBuilder(),
          ZoTransitionBase<double>(
            key: const ValueKey("__body__"),
            open: nonNullValue,
            appear: false,
            mountOnEnter: widget.mountOnEnter,
            unmountOnExit: widget.unmountOnExit,
            changeVisible: false,
            autoAlpha: false,
            curve: widget.curve ?? ZoTransition.defaultCurve,
            duration: widget.duration,
            builder: _bodyBuilder,
          ),
        ],
      ),
    );
  }
}

class _ExpansibleLinker extends InheritedWidget {
  const _ExpansibleLinker({
    super.key,
    required super.child,
    required this.current,
  });

  final ZoExpanderState current;

  static _ExpansibleLinker? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_ExpansibleLinker>();
  }

  @override
  bool updateShouldNotify(_ExpansibleLinker oldWidget) {
    return oldWidget.current != current ||
        oldWidget.current.level != current.level;
  }
}

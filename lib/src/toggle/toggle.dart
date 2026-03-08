import "dart:math" as math;

import "package:flutter/material.dart";
import "package:zo/zo.dart";

/// 显示类型
enum ZoToggleType {
  checkbox,
  switcher,
  radio,
}

/// 自定义构造时传入的参数
class ZoToggleBuilderArgs {
  ZoToggleBuilderArgs(
    this.context,
    this.state,
  );

  final BuildContext context;

  /// 当前组件的 state
  final ToggleState state;
}

/// 一个 boolean 输入控件, 它可渲染为 CheckBox、Radio、Switch 三种不同风格,
/// 还可使用 [ZoToggleGroup] 来批量管理子级 [ZoToggle], 并将选中值收集到一个集合中
class ZoToggle extends ZoCustomFormWidget<bool> {
  const ZoToggle({
    super.key,
    super.value,
    super.onChanged,
    this.type = ZoToggleType.checkbox,
    this.groupValue,
    this.prefix,
    this.suffix,
    this.alignment,
    this.enable = true,
    this.indeterminate = false,
    this.builder,
    this.size = ZoSize.medium,
    this.borderColor,
    this.activeBorderColor,
    this.color,
    this.activeColor,
  }) : assert(groupValue == null || value == null);

  /// 控件显示类型
  final ZoToggleType type;

  /// 搭配 [ZoToggleGroup] 使用时, 作为选中时的值, 未设置此项的不会被视为组选项,
  /// 当选项由组管理时, 不应再自行管理选中状态
  final Object? groupValue;

  /// 组件后显示的内容
  final Widget? suffix;

  /// 组件前显示的内容,
  final Widget? prefix;

  /// 组件与 [suffix] 和 [prefix] 的对齐方式
  final CrossAxisAlignment? alignment;

  /// 是否启用
  final bool enable;

  /// [ZoToggleType.checkbox] 模式下，设置组件为不确定状态，不影响实际值
  final bool indeterminate;

  /// 自定义构造内容
  final Widget Function(ZoToggleBuilderArgs args)? builder;

  /// 组件尺寸
  final ZoSize? size;

  /// 边框色
  final Color? borderColor;

  /// 选中时的边框色
  final Color? activeBorderColor;

  /// 背景色
  final Color? color;

  /// 选中时的背景色
  final Color? activeColor;

  @override
  ZoCustomFormState<bool, ZoToggle> createState() => ToggleState();
}

class ToggleState extends ZoCustomFormState<bool, ZoToggle> {
  @override
  @protected
  bool? get fallbackValue => false;

  /// 是否启用, 作为组控件时, 合并了父级的启用状态
  bool get enable {
    if (_groupLiner == null) return widget.enable;

    return _groupLiner!.enable && widget.enable;
  }

  /// 组实现
  _GroupLinker? _groupLiner;

  bool _firstChangeDependenciesCall = true;

  /// 在内部更新状态时防止内部触发更新
  bool _blockNotify = false;

  @override
  @protected
  void didChangeDependencies() {
    super.didChangeDependencies();

    _groupLiner = _GroupLinker.maybeOf(context);

    // 同步到组
    if (_firstChangeDependenciesCall) {
      _bindGroup(widget);
    }

    _firstChangeDependenciesCall = false;
  }

  @override
  @protected
  void didUpdateWidget(ZoToggle oldWidget) {
    super.didUpdateWidget(oldWidget);

    // groupValue 更新时绑定或解绑
    if (_groupLiner != null && oldWidget.groupValue != widget.groupValue) {
      _unbindGroup(oldWidget);
      _bindGroup(widget);
    }
  }

  @override
  @protected
  void dispose() {
    // 解绑
    _unbindGroup(widget);

    _groupLiner = null;

    super.dispose();
  }

  /// 绑定到组
  void _bindGroup(ZoToggle toggleWidget) {
    if (_groupLiner != null && toggleWidget.groupValue != null) {
      _groupLiner!.bind(toggleWidget);

      // 将初始选中状态同步到当前值
      final curChecked = _groupLiner!.selector.isSelected(widget.groupValue!);

      if (curChecked) {
        // 由于方法的执行时机, 需要用 innerValue 避免更新组件
        formBinder.innerValue = curChecked;
      }

      _groupLiner!.selector.addListener(_onSelectorChanged);
    }
  }

  /// 从组解绑
  void _unbindGroup(ZoToggle toggleWidget) {
    if (_groupLiner != null && toggleWidget.groupValue != null) {
      _groupLiner!.unbind(toggleWidget);
      _groupLiner!.selector.removeListener(_onSelectorChanged);

      // 已选中项移除时将其取消选中
      if (_groupLiner!.selector.isSelected(toggleWidget.groupValue!)) {
        _blockNotify = true;
        _groupLiner!.selector.unselect(toggleWidget.groupValue!);
        _blockNotify = false;
      }
    }
  }

  /// 值从 selector 更新时, 更新到组件
  _onSelectorChanged() {
    if (_groupLiner == null || widget.groupValue == null || _blockNotify) {
      return;
    }

    final curChecked = _groupLiner!.selector.isSelected(widget.groupValue!);

    if (curChecked != nonNullValue) {
      _blockNotify = true;
      value = curChecked;
      _blockNotify = false;
    }
  }

  @override
  @protected
  void onPropValueChanged() {
    super.onPropValueChanged();

    _updateGroupValue();
  }

  @override
  @protected
  void onChanged(bool? newValue) {
    super.onChanged(newValue);

    _updateGroupValue();
  }

  /// 值从组件更新时, 更新到 selector
  void _updateGroupValue() {
    if (_groupLiner == null || widget.groupValue == null || _blockNotify) {
      return;
    }

    final curChecked = _groupLiner!.selector.isSelected(widget.groupValue!);

    if (curChecked != nonNullValue) {
      _blockNotify = true;
      nonNullValue
          ? _groupLiner!.selector.select(widget.groupValue!)
          : _groupLiner!.selector.unselect(widget.groupValue!);
      _blockNotify = false;
    }
  }

  Widget? _wrapGesture(Widget? child, bool isSuffix) {
    if (child == null) return null;
    final style = context.zoStyle;

    return GestureDetector(
      onTap: () {
        if (!enable) return;
        value = !nonNullValue;
      },
      // 配合下面的间距, 使填充部分也可以点击, 防止出现异常体验
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsetsGeometry.only(
          left: isSuffix ? style.space2 : 0,
          right: !isSuffix ? style.space2 : 0,
        ),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final args = ZoToggleBuilderArgs(context, this);

    final builder =
        widget.builder ??
        switch (widget.type) {
          ZoToggleType.checkbox ||
          ZoToggleType.radio => _checkboxAndRadioBuilder,
          ZoToggleType.switcher => _switcherBuilder,
        };

    final child = builder(args);

    if (widget.suffix != null || widget.prefix != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: widget.alignment ?? CrossAxisAlignment.center,
        children: [
          ?_wrapGesture(widget.prefix, false),
          child,
          ?_wrapGesture(widget.suffix, true),
        ],
      );
    }

    return child;
  }
}

/// 管理子级的 [ZoToggle], 根据他们的选中状态将 [ZoToggle.groupValue] 添加为选中值,
/// 未设置 [ZoToggle.groupValue] 的项不会被视为组选项
class ZoToggleGroup extends ZoCustomFormWidget<Iterable<Object>> {
  const ZoToggleGroup({
    super.key,
    super.value,
    super.onChanged,
    required this.child,
    this.selectionType = ZoSelectionType.multiple,
    this.ref,
    this.enable = true,
  });

  /// 控制选择类型, 默认为多选
  final ZoSelectionType selectionType;

  /// 获取 state 的引用, 会在实例可用、销毁时调用，可用来便捷的访问 state 而无需创建 globalKey
  final void Function(ZoToggleGroupState? state)? ref;

  /// 空制整组是否启用
  final bool enable;

  /// 子级, 通常需要包含一组带 [ZoToggle.groupValue] 的 [ZoToggle]
  final Widget child;

  @override
  State<ZoToggleGroup> createState() => ZoToggleGroupState();
}

class ZoToggleGroupState
    extends ZoCustomFormState<Iterable<Object>, ZoToggleGroup> {
  /// 所有选项
  final options = <Object>{};

  /// 控制选中项
  late final ZoSelector<Object, Object> selector;

  /// 在内部更新 selector 时防止内部触发更新
  bool _blockNotify = false;

  @override
  @protected
  void initState() {
    super.initState();

    selector = ZoSelector<Object, Object>(
      selected: value,
      optionsGetter: () => options,
      valueGetter: (option) => option,
    );

    formBinder.innerValue = value;

    selector.addListener(_onSelectChanged);

    widget.ref?.call(this);
  }

  @override
  @protected
  void dispose() {
    widget.ref?.call(null);

    selector.removeListener(_onSelectChanged);

    super.dispose();
  }

  @override
  @protected
  void onPropValueChanged() {
    super.onPropValueChanged();

    // 更新 props.value 变更到选择器
    selector.batch(() {
      selector.setSelected(widget.value ?? []);
    }, false);

    // 延迟更新, 防止触发 toggle 组件的 setState
    WidgetsBinding.instance.addPostFrameCallback((d) {
      _blockNotify = true;
      selector.notifyListeners();
      _blockNotify = false;
    });
  }

  /// 更新selector的选中项到value
  void _onSelectChanged() {
    if (_blockNotify) return;

    final selected = selector.getSelected();

    value = !isMultiple() && selected.isNotEmpty
        ? {selected.last}
        : selector.getSelected();
  }

  void bind(ZoToggle widget) {
    if (widget.groupValue == null) return;
    options.add(widget.groupValue!);
  }

  void unbind(ZoToggle widget) {
    if (widget.groupValue == null) return;
    options.remove(widget.groupValue!);
  }

  bool isMultiple() {
    return widget.selectionType == ZoSelectionType.multiple;
  }

  @override
  @protected
  Widget build(BuildContext context) {
    return _GroupLinker(
      bind: bind,
      unbind: unbind,
      selector: selector,
      enable: widget.enable,
      child: widget.child,
    );
  }
}

/// 连接 group 和其子级的 toggle
class _GroupLinker extends InheritedWidget {
  const _GroupLinker({
    super.key,
    required super.child,
    required this.bind,
    required this.unbind,
    required this.selector,
    required this.enable,
  });

  /// 绑定到当前组
  final void Function(ZoToggle) bind;

  /// 从当前组解绑
  final void Function(ZoToggle) unbind;

  /// 选中控制
  final ZoSelector<Object, Object> selector;

  /// 是否启用
  final bool enable;

  static _GroupLinker? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_GroupLinker>();
  }

  @override
  bool updateShouldNotify(_GroupLinker oldWidget) {
    return oldWidget.enable != enable;
  }
}

/// checkbox & radio 构造
Widget _checkboxAndRadioBuilder(ZoToggleBuilderArgs args) {
  final state = args.state;
  final widget = state.widget;
  final style = args.context.zoStyle;

  final size = style.getSizedSmallExtent(widget.size);

  final widgetSize = widget.size ?? style.widgetSize;

  final borderWidth = switch (widgetSize) {
    ZoSize.small || ZoSize.medium => 2.0,
    ZoSize.large => 3.0,
  };

  final isCheckbox = widget.type == ZoToggleType.checkbox;

  final selectedAndActiveBorder = Border.all(
    color: widget.activeBorderColor ?? style.primaryColor,
    width: borderWidth,
  );

  final checkedColor = widget.activeColor ?? style.primaryColor;

  final useSelectedStyle = isCheckbox
      ? widget.indeterminate || state.nonNullValue
      : state.nonNullValue;

  final enable = state.enable;

  Widget centerWidget;

  if (widget.type == ZoToggleType.checkbox) {
    centerWidget = widget.indeterminate
        ? _ToggleCheckedCenterIcon(
            color: enable ? checkedColor : style.disabledColor,
            size: widgetSize,
            radius: BorderRadius.circular(4),
          )
        : _ToggleCheckedIcon(
            color: enable ? Colors.white : style.disabledTextColor,
            size: widgetSize,
          );
  } else {
    centerWidget = _ToggleCheckedCenterIcon(
      color: enable ? checkedColor : style.disabledColor,
      size: widgetSize,
      radius: BorderRadius.circular(10),
    );
  }

  return ZoInteractiveBox(
    enabled: enable,
    interactive: !widget.indeterminate,
    enableColorEffect: false,
    focusOnTap: false,
    selected: useSelectedStyle,
    style: ZoInteractiveBoxStyle.border,
    color: widget.color ?? style.surfaceContainerColor,
    // 半选和 radio 始终使用灰色背景
    selectedColor: widget.indeterminate || !isCheckbox
        ? style.surfaceContainerColor
        : checkedColor,
    border: Border.all(
      color: widget.borderColor ?? style.outlineColor,
      width: borderWidth,
    ),
    activeBorder: selectedAndActiveBorder,
    selectedBorder: selectedAndActiveBorder,
    radius: isCheckbox ? BorderRadius.circular(8) : BorderRadius.circular(20),
    width: size,
    height: size,
    padding: const EdgeInsets.all(0),
    onTap: MemoCallback<ZoTriggerEvent, void>((arg) {
      state.value = !state.nonNullValue;
    }),
    child: ZoTransition(
      type: ZoTransitionType.zoom,
      open: useSelectedStyle,
      appear: false,
      mountOnEnter: false,
      duration: Durations.extralong2,
      reverseDuration: Duration.zero,
      curve: Curves.elasticOut,
      child: centerWidget,
    ),
  );
}

/// 构造 switch 主体
Widget _switcherBuilder(ZoToggleBuilderArgs args) {
  final state = args.state;
  final widget = state.widget;
  final style = args.context.zoStyle;

  final height = style.getSizedSmallExtent(widget.size) + 6;
  final width = height * 1.8;

  const thumbOffset = 3.0;
  final thumbSize = height - 2 * thumbOffset;

  final radius = BorderRadius.circular(30);

  final checkedColor = widget.activeColor ?? style.primaryColor;

  final enable = state.enable;

  return ZoInteractiveBox(
    enabled: enable,
    focusOnTap: false,
    color: widget.color ?? style.disabledColor,
    disabledColor: style.hoverColor,
    radius: radius,
    width: width,
    height: height,
    padding: const EdgeInsets.all(0),
    onTap: MemoCallback<ZoTriggerEvent, void>((arg) {
      state.value = !state.nonNullValue;
    }),
    builder: (interactiveArgs) {
      return ZoTransitionBase<double>.persistence(
        open: state.nonNullValue,
        duration: Durations.short4,
        animationBuilder: (animate) {
          return Stack(
            children: [
              Positioned.fill(
                child: FadeTransition(
                  opacity: animate.animation,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: enable ? checkedColor : style.selectedColor,
                      borderRadius: radius,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                left: thumbOffset,
                right: thumbOffset,
                child: AlignTransition(
                  alignment: Tween<AlignmentGeometry>(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ).animate(animate.animation),
                  child: AnimatedScale(
                    scale: interactiveArgs.down ? 1.1 : 1,
                    duration: Durations.short2,
                    child: Container(
                      width: thumbSize,
                      height: thumbSize,
                      decoration: BoxDecoration(
                        color: style.isLight
                            ? Colors.white
                            : style.surfaceContainerColor,
                        borderRadius: radius,
                        // border: Border.all(color: style.hoverColor),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      );
    },
  );
}

/// 渲染 checkbox 的 check icon
class _ToggleCheckedIcon extends StatelessWidget {
  const _ToggleCheckedIcon({
    super.key,
    required this.color,
    required this.size,
  });

  final Color color;

  final ZoSize size;

  @override
  Widget build(BuildContext context) {
    final side = BorderSide(
      width: 3.4,
      color: color,
    );

    final scale = switch (size) {
      ZoSize.small => 0.8,
      ZoSize.medium => 1.0,
      ZoSize.large => 1.2,
    };

    return Align(
      alignment: Alignment.center,
      child: Transform(
        transform: Matrix4.identity()
          ..rotateZ(-math.pi / 4)
          ..scaleByDouble(scale, scale, scale, 1),
        transformHitTests: false,
        alignment: const Alignment(-0.2, -0.2),
        child: Container(
          width: 14,
          height: 8,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.all(Radius.circular(2)),
            border: Border(
              left: side,
              bottom: side,
              // top: side,
              // right: side,
            ),
          ),
        ),
      ),
    );
  }
}

/// 渲染 checkbox 的 indeterminate 或 checkbox 的中心圆
class _ToggleCheckedCenterIcon extends StatelessWidget {
  const _ToggleCheckedCenterIcon({
    super.key,
    required this.color,
    required this.size,
    required this.radius,
  });

  final Color color;

  final ZoSize size;

  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.center,
      child: FractionallySizedBox(
        widthFactor: 0.56,
        heightFactor: 0.56,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: radius,
          ),
        ),
      ),
    );
  }
}

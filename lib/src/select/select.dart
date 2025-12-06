/// 组合 [ZoMenuEntry] 和 [ZoInput] 实现的下拉选择器
library;

import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:zo/zo.dart";

/// 下拉选择组件
class ZoSelect extends ZoCustomFormWidget<Iterable<Object>> {
  const ZoSelect({
    super.key,
    super.value = const [],
    super.onChanged,
    required this.options,
    this.selectionType = ZoSelectionType.single,
    this.branchSelectable = false,
    this.toolbar,
    this.localSearch = true,
    this.onInputChanged,
    this.maxSelectedShowNumber = 10,
    this.showOpenIndicator = true,
    this.customTagDecoration,
    this.clear = true,
    this.size = ZoSize.medium,
    this.hintText,
    this.leading,
    this.trailing,
    this.padding,
    this.constraints,
    this.autofocus = false,
    this.controller,
    this.enabled = true,
    this.focusNode,
    this.readOnly = false,
    this.style,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.textInputAction,
  }) : assert(selectionType != ZoSelectionType.none);

  /// 选项列表
  final List<ZoOption> options;

  /// 控制选择类型, 默认为单选
  final ZoSelectionType selectionType;

  /// 分支节点是否可选中
  final bool branchSelectable;

  /// 在下拉列表顶部渲染自定义内容，例如一个工具栏
  final Widget? toolbar;

  /// 启用本地搜索
  final bool localSearch;

  /// 输入框的值变更时触发，设置后，输入组件可聚焦并进行输入，可借此实现服务端搜索
  final ZoFormOnChanged<String>? onInputChanged;

  /// 要在输入框处显示的已选中项最大数量
  final int maxSelectedShowNumber;

  /// 在输入框右侧显示下拉展开指示器
  final bool showOpenIndicator;

  /// 自定义标签装饰, 当value不存在对应的选项时，option 可能为空
  final BoxDecoration Function(Object value, ZoOption? option)?
  customTagDecoration;

  // # # # # # # # Input # # # # # # #

  /// 在包含已选择内容时, 显示清除按钮
  final bool clear;

  /// 组件尺寸
  final ZoSize size;

  /// 提示文本
  final Widget? hintText;

  /// 前导内容
  final List<Widget>? leading;

  /// 后导内容
  final List<Widget>? trailing;

  /// 内间距
  final EdgeInsetsGeometry? padding;

  /// 尺寸控制
  final BoxConstraints? constraints;

  final bool autofocus;

  final TextEditingController? controller;

  final bool enabled;

  final FocusNode? focusNode;

  final bool readOnly;

  final TextStyle? style;

  final TextAlign textAlign;

  final TextDirection? textDirection;

  final TextInputAction? textInputAction;

  @override
  State<StatefulWidget> createState() {
    return ZoSelectState();
  }
}

class ZoSelectState extends ZoCustomFormState<Iterable<Object>, ZoSelect> {
  /// 下拉列表的渲染层
  late ZoMenuEntry menuEntry;

  /// 选中项控制
  ZoSelector<Object, ZoOption> get selector => menuEntry.selector;

  /// 选项控制器
  ZoOptionController get optionController => menuEntry.controller;

  /// input 最后绘制的位置信息
  Rect? _lastRect;

  /// 最后关闭的时间
  DateTime? _lastCloseTime;

  /// 输入框是否聚焦
  bool _isFocus = false;

  /// 输入框的值
  String? _inputValue;

  /// 控制数据框焦点
  late FocusNode _focusNode;

  /// 按下方向键下
  final _downActivator = const SingleActivator(
    LogicalKeyboardKey.arrowDown,
    includeRepeats: false,
  );

  /// 关闭键
  final _closeActivator = const SingleActivator(
    LogicalKeyboardKey.escape,
    includeRepeats: false,
  );

  /// 箭头动画旋转区间
  final _arrowTween = Tween<double>(begin: 0, end: 0.5);

  /// 本地搜索防抖
  final _localSearchDebuncer = Debouncer(
    delay: Durations.medium1,
  );

  @override
  @protected
  void initState() {
    super.initState();

    _focusNode = widget.focusNode ?? FocusNode();

    menuEntry = ZoMenuEntry(
      options: widget.options,
      selected: value,
      selectionType: widget.selectionType,
      branchSelectable: widget.branchSelectable,
      size: widget.size,
      toolbar: widget.toolbar,
      dismissMode: ZoOverlayDismissMode.close,
      autoFocus: false, // 手动控制
      inheritWidth: false,
      // height/width/matchString/autoFocus
    );
    selector.addListener(_onSelectChanged);
    menuEntry.openChangedEvent.on(_onOpenChanged);
  }

  @override
  @protected
  void didUpdateWidget(ZoSelect oldWidget) {
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
        if (oldWidget.focusNode != _focusNode) {
          _focusNode.dispose();
        }
        _focusNode = widget.focusNode ?? FocusNode();
      }
    }, false);
  }

  @override
  @protected
  void dispose() {
    super.dispose();
    _localSearchDebuncer.cancel();
    selector.removeListener(_onSelectChanged);
    menuEntry.openChangedEvent.off(_onOpenChanged);
    menuEntry.disposeSelf();
    // 如果旧的focusNode是内部创建的，将其销毁
    if (widget.focusNode != _focusNode) {
      _focusNode.dispose();
    }
  }

  /// 切换菜单层开启状态
  void toggle() {
    if (menuEntry.currentOpen) {
      menuEntry.close();
    } else {
      menuEntry.open();
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        menuEntry.focus();
      });
    }
  }

  /// 聚焦处理
  ///
  /// 层的打开和关闭以及焦点处理
  /// 1. 焦点：聚焦时打开层，失焦时，如果还层不处于按下状态、也未获得焦点，将其关闭
  /// 2. 为了防止菜单层关闭后焦点回到输入框导致重新打开，需要设置一个时间值，小于时间值时不打开层
  /// 3. 输入框具有焦点时：按方向键下时，打开并移动焦点到菜单层，按escape键时，关闭层
  /// 4. 点击Input，如果层未打开，则打开层，防止第2、3步主动关闭后用户重新打开的情况
  void _onFocusChanged(bool focus) {
    // 聚焦时显示下拉层, 失焦时，延迟一定时间，如果下一焦点不是当前层或未处于按下则关闭
    if (focus) {
      if (_lastCloseTime != null) {
        final diff = DateTime.now().difference(_lastCloseTime!);

        if (diff > const Duration(milliseconds: 80)) {
          menuEntry.open();
        }
      } else {
        menuEntry.open();
      }
    } else if (!menuEntry.pressed && !menuEntry.focusScopeNode.hasFocus) {
      menuEntry.close();
    }

    setState(() {
      _isFocus = focus;
    });
  }

  void _onChanged(String? newValue) {
    setState(() {
      _inputValue = newValue;
    });
    widget.onInputChanged?.call(newValue);

    _changeLocalSearch();
  }

  void _onOpenChanged(bool open) {
    if (!open) {
      _lastCloseTime = DateTime.now();
    }
    setState(() {});
  }

  /// 更新selector的选中项到value并进行rerender
  void _onSelectChanged() {
    value = selector.getSelected();
    setState(() {});
  }

  /// 输入框区域点击
  void _onTap(PointerDownEvent event) {
    if (!menuEntry.currentOpen) {
      menuEntry.open();
    }
  }

  /// 点击清理按钮
  void _onClear() {
    if (_inputValue != null && _inputValue!.isNotEmpty) {
      setState(() {
        _inputValue = "";
      });
      widget.onInputChanged?.call("");
      _changeLocalSearch();
      return;
    }

    selector.unselectAll();
  }

  void _changeLocalSearch() {
    if (widget.localSearch) {
      _localSearchDebuncer.run(() {
        menuEntry.matchString = _inputValue;
        menuEntry.open();
      });
    } else if (menuEntry.matchString != null) {
      menuEntry.matchString = null;
    }
  }

  /// 通过快捷键关闭
  KeyEventResult _onShortcutsClose() {
    menuEntry.close();
    return KeyEventResult.handled;
  }

  /// 通过快捷键打开
  KeyEventResult _onShortcutsOpen() {
    if (menuEntry.currentOpen) {
      menuEntry.focusChild();
    } else {
      menuEntry.open();
    }

    return KeyEventResult.handled;
  }

  /// 同步value变更到selector
  @override
  @protected
  void onPropValueChanged() {
    selector.setSelected(widget.value ?? []);
  }

  @protected
  void onPaint(RenderBox box) {
    _lastRect = box.localToGlobal(Offset.zero) & box.size;

    menuEntry.actions(() {
      menuEntry.rect = _lastRect;
      menuEntry.width = box.size.width;
    }, false);
  }

  KeyEventResult _keyEvent(FocusNode node, KeyEvent event) {
    if (ZoShortcutsHelper.checkEvent(_closeActivator, event)) {
      return _onShortcutsClose();
    } else if (ZoShortcutsHelper.checkEvent(_downActivator, event)) {
      return _onShortcutsOpen();
    }
    return KeyEventResult.ignored;
  }

  /// 获取已选中项的选项列表，可传入长度限制获取数量, 列表项为一个二元组，当值没有对应的选项时选项会为null
  List<(Object value, ZoOption? option)> _getShowOptionList(int length) {
    final List<(Object value, ZoOption? option)> list = [];

    final selected = selector.getSelected();

    for (final val in selected) {
      final node = menuEntry.controller.getNode(val);
      list.add((val, node?.data));
      if (list.length >= length) break;
    }

    return list;
  }

  /// 获取用于渲染的tag或文本
  ///
  /// tag的显示逻辑：
  /// - 必要：包含选中项
  /// - 输入框聚焦，无输入值，标签整体右移; 有值时，隐藏标签
  /// - enableInput 为 false，固定显示
  Widget? _getShowTags() {
    final style = context.zoStyle;
    final isDarkMode = style.brightness == Brightness.dark;

    final selected = _getShowOptionList(widget.maxSelectedShowNumber);

    if (selected.isEmpty) return null;

    if (widget.selectionType != ZoSelectionType.multiple) {
      final (value, option) = selected.first;
      final text = option?.getTitleText() ?? value.toString();
      return Text(text);
    }

    final length = selector.getSelected().length;

    final showMoreTips = length > widget.maxSelectedShowNumber;

    // 是否在左侧显示额外的间距，防止与光标重叠
    final showLeftPadding = _isFocus && length > 0;

    final list = selected.map((opt) {
      final (value, option) = opt;
      final text = option?.getTitleText() ?? value.toString();

      final double height = switch (widget.size) {
        ZoSize.medium => 26,
        ZoSize.small => 20,
        ZoSize.large => 30,
      };

      final isSmall = widget.size == ZoSize.small;

      final decoration = widget.customTagDecoration != null
          ? widget.customTagDecoration!(value, option)
          : BoxDecoration(
              border: Border.all(color: style.outlineColor),
              borderRadius: BorderRadius.circular(style.borderRadius),
            );

      Color? textColor;

      if (decoration.color != null) {
        final useLightText = useLighterText(decoration.color!);
        if (useLightText && !isDarkMode) {
          textColor = Colors.white;
        }
      }

      // 通过 stack 实现
      return Stack(
        key: ValueKey(value),
        alignment: AlignmentGeometry.center,
        children: [
          IgnorePointer(
            child: Container(
              key: ValueKey(value),
              decoration: decoration,
              height: height,
              padding: EdgeInsets.only(
                left: isSmall ? style.space1 : style.space2,
                right: 24,
              ),
              constraints: const BoxConstraints(maxWidth: 180),
              child: Center(
                widthFactor: 1,
                child: Text(
                  text,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: isSmall ? style.fontSizeSM : null,
                    color: textColor,
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: 2,
            child: Transform.scale(
              scale: isSmall ? 0.6 : 0.8,
              child: ZoButton(
                canRequestFocus: false,
                icon: Icon(
                  Icons.close,
                  color: textColor,
                ),
                size: ZoSize.small,
                plain: true,
                onTap: () {
                  selector.unselect(value);
                },
              ),
            ),
          ),
        ],
      );
    }).toList();

    return Transform.translate(
      // 让标签视觉上更对其输入框
      offset: const Offset(-4, 0),
      child: Padding(
        padding: EdgeInsets.only(left: showLeftPadding ? 16 : 0),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          hitTestBehavior: HitTestBehavior.translucent,
          child: Row(
            spacing: style.space1,
            children: showMoreTips ? [...list, const Text("...")] : list,
          ),
        ),
      ),
    );
  }

  /// 添加箭头动画
  Widget _buildArrowAnimation(ZoTransitionBuilderArgs<double> animate) {
    return RotationTransition(
      turns: animate.animation,
      child: animate.child,
    );
  }

  /// 自定义尾随节点，添加展开指示器
  List<Widget>? _buildCustomTrailing() {
    if (!widget.showOpenIndicator && !widget.clear) return widget.trailing;

    final openIndicator = ZoTransitionBase<double>(
      key: const ValueKey("_ZO_SELECT_DROPDOWN_BUTTON"),
      open: menuEntry.currentOpen,
      appear: false,
      mountOnEnter: false,
      changeVisible: false,
      autoAlpha: false,
      tween: _arrowTween,
      animationBuilder: _buildArrowAnimation,
      child: ZoButton(
        size: ZoSize.small,
        plain: true,
        onTap: toggle,
        icon: const Icon(
          Icons.arrow_drop_down_rounded,
          size: 24,
        ),
      ),
    );

    final clearButton = ZoButton(
      key: const ValueKey("_ZO_SELECT_CLEAR_BUTTON"),
      icon: const Icon(Icons.clear),
      plain: true,
      size: ZoSize.small,
      onTap: _onClear,
    );

    // 清空按钮显示逻辑：输入框有输入内容或包含两项以上的选中项
    var showClearButton = false;

    final inputEmpty = _inputValue == null || _inputValue!.isEmpty;

    if (!inputEmpty || selector.getSelected().length > 1) {
      showClearButton = true;
    }

    return [
      if (showClearButton) clearButton,
      if (widget.showOpenIndicator) openIndicator,
      ...?widget.trailing,
    ];
  }

  Widget _mainWrapper(BuildContext context, Widget mainWidget) {
    return TapRegion(
      onTapInside: _onTap,
      child: Focus(
        onKeyEvent: _keyEvent,
        skipTraversal: true,
        child: mainWidget,
      ),
    );
  }

  @override
  @protected
  Widget build(BuildContext context) {
    final enableInput = widget.localSearch || widget.onInputChanged != null;

    Widget? tags;

    final inputEmpty = _inputValue != null && _inputValue!.isNotEmpty;

    if (!enableInput || !inputEmpty) {
      tags = _getShowTags();
    }

    return RenderTrigger(
      onPaint: onPaint,
      child: TapRegion(
        groupId: menuEntry.groupId,
        child: ZoInput<String>(
          // 需要完全定制
          clear: false,
          // 覆盖padding
          size: widget.size,
          extra: tags,
          mainWrapper: _mainWrapper,
          // tags显示时，始终隐藏
          hintText: tags == null ? widget.hintText : null,
          leading: widget.leading, // 改造
          trailing: _buildCustomTrailing(), // 改造
          padding: widget.padding,
          constraints: widget.constraints,
          autofocus: widget.autofocus,
          controller: widget.controller,
          enabled: widget.enabled,
          focusNode: _focusNode,
          readOnly: widget.readOnly || !enableInput,
          style: widget.style,
          textAlign: widget.textAlign,
          textDirection: widget.textDirection,
          textInputAction: widget.textInputAction,
          onFocusChanged: _onFocusChanged,
          value: _inputValue,
          onChanged: _onChanged,
        ),
      ),
    );
  }
}

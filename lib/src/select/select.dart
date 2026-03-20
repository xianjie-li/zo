/// 组合 [ZoMenu] 和 [ZoInput] 实现的下拉选择器
library;

import "package:flutter/material.dart";
import "package:zo/zo.dart";

/// 选项显示的菜单类型
enum ZoSelectMenuType {
  menu,
  treeMenu,
}

/// 组合 [ZoInput] 和菜单弹层的下拉选择器
///
/// 支持本地搜索、远程搜索接入、单选多选、标签展示和菜单类型切换
///
/// 可根据场景选择 [ZoMenu] 或 [ZoTreeMenu]
class ZoSelect extends ZoMenusTrigger {
  const ZoSelect({
    super.key,
    super.value,
    super.onChanged,
    required super.options,
    super.selectionType,
    super.branchSelectable,
    super.selectMenuType,
    super.toolbar,
    super.size,
    super.menuWidth,
    super.maxSelectedShowNumber,
    super.enabled,
    super.openOnFocus,
    super.focusNode,

    this.localSearch = true,
    this.onInputChanged,
    this.showOpenIndicator = true,
    this.customTag,
    this.forceTextDisplay = false,
    this.clear = true,
    this.hintText,
    this.leading,
    this.trailing,
    this.constraints,
    this.autofocus = false,
    this.textController,
    this.readOnly = false,
    this.textStyle,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.textInputAction,
  }) : assert(selectionType != ZoSelectionType.none);

  /// 启用本地搜索
  final bool localSearch;

  /// 输入框值变更回调
  ///
  /// 设置后输入组件可输入内容，可借此接入服务端搜索
  final ZoFormOnChanged<String>? onInputChanged;

  /// 在输入框右侧显示下拉展开指示器
  final bool showOpenIndicator;

  /// 自定义已选标签配置
  ///
  /// 回调返回的 [ZoTag] 仅使用外观相关配置
  ///
  /// 当值不存在对应选项时，`option` 可能为 `null`
  final ZoTag Function(Object value, ZoOption? option)? customTag;

  /// 是否强制使用文本显示选中项
  ///
  /// 默认情况下，多选使用标签，单选使用文本
  final bool forceTextDisplay;

  /// 在包含已选内容时显示清除按钮
  final bool clear;

  /// 提示文本
  final Widget? hintText;

  /// 前导内容
  final List<Widget>? leading;

  /// 后导内容
  final List<Widget>? trailing;

  /// 尺寸控制
  final BoxConstraints? constraints;

  /// 是否自动聚焦
  final bool autofocus;

  /// 输入框控制器
  final TextEditingController? textController;

  /// 是否只读
  final bool readOnly;

  /// 输入框文本样式
  final TextStyle? textStyle;

  /// 输入框文本对齐方式
  final TextAlign textAlign;

  /// 输入框文本方向
  final TextDirection? textDirection;

  /// 输入框的键盘动作按钮类型
  final TextInputAction? textInputAction;

  @override
  State<StatefulWidget> createState() {
    return ZoSelectState();
  }
}

class ZoSelectState extends ZoMenusTriggerState<ZoSelect> {
  /// 输入框的值
  String? _inputValue;

  /// 箭头动画旋转区间
  final _arrowTween = Tween<double>(begin: 0, end: 0.5);

  /// 本地搜索防抖
  final _localSearchDebuncer = Debouncer(
    delay: Durations.medium1,
  );

  /// 识别关闭是否由 esc 触发的时间窗口
  static const _escapeCloseThreshold = Duration(milliseconds: 80);

  @override
  @protected
  bool get canOpenMenu {
    return super.canOpenMenu && !widget.readOnly;
  }

  @override
  @protected
  void dispose() {
    _localSearchDebuncer.cancel();

    super.dispose();
  }

  void _onChanged(String? newValue) {
    setState(() {
      _inputValue = newValue;
    });

    widget.onInputChanged?.call(newValue);

    _changeLocalSearch();
  }

  /// 覆盖父级层开关回调，补充输入焦点处理
  @override
  @protected
  void onOpenChanged(bool open) {
    if (!open) {
      final now = DateTime.now();

      final lastEscapeTime = zoOverlay.lastEscapeTime;

      final closeByEscape =
          lastEscapeTime != null &&
          now.difference(lastEscapeTime) <= _escapeCloseThreshold;

      // 如果最近一次关闭不是 escape 键触发的，则主动失焦输入框,
      // 防止自动的焦点回退导致不太自然的输入框聚焦行为
      if (!closeByEscape) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            focusNode.unfocus();
            return;
          }
        });
      }
    }
    setState(() {});
  }

  /// 处理清空操作
  ///
  /// 优先清空输入内容，否则清空选中值
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

  /// 同步本地搜索关键字
  void _changeLocalSearch() {
    if (!canOpenMenu) return;

    if (widget.localSearch) {
      _localSearchDebuncer.run(() {
        menuEntry.matchString = _inputValue;
        openMenu();
      });
    } else if (menuEntry.matchString != null) {
      menuEntry.matchString = null;
    }
  }

  /// 获取标签外观配置
  ZoTag _getTagConfig(Object value, ZoOption? option) {
    return widget.customTag?.call(value, option) ??
        ZoTag(
          type: ZoTagType.outline,
          size: widget.size,
          borderRadius: context.zoStyle.getSizedRadius(widget.size),
          child: const SizedBox.shrink(),
        );
  }

  /// 构建多选标签内容
  Widget _buildSelectTag({
    required Object value,
    required ZoOption? option,
    required String text,
    required bool isSmall,
  }) {
    final tag = _getTagConfig(value, option);
    final style = context.zoStyle;
    final currentSize = widget.size;
    final currentWidgetSize = currentSize ?? style.widgetSize;
    final adjustHeight = switch (currentWidgetSize) {
      ZoSize.small || ZoSize.medium => 8,
      ZoSize.large => 10,
    };
    final tagHeight = style.getSizedExtent(currentSize) - adjustHeight;
    final closeSpace = switch (widget.size ?? style.widgetSize) {
      ZoSize.small => 16.0,
      ZoSize.medium => 16.0,
      ZoSize.large => 14.0,
    };

    return ZoTag(
      type: ZoTagType.outline,
      color: tag.color,
      size: currentSize,
      height: tagHeight,
      textStyle: tag.textStyle,
      backgroundAlpha: tag.backgroundAlpha,
      borderRadius: tag.borderRadius,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 180),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                text,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: isSmall ? style.fontSizeSM : null,
                ),
              ),
            ),
            if (canOpenMenu) SizedBox(width: closeSpace),
          ],
        ),
      ),
    );
  }

  /// 获取标签文本颜色
  Color? _getTagTextColor(ZoTag tag, ZoStyle style) {
    return tag.textStyle?.color ?? tag.color ?? style.textColor;
  }

  /// 获取用于渲染的标签或文本
  ///
  /// 多选默认显示标签
  ///
  /// 单选或强制文本模式显示逗号分隔文本
  Widget? _getShowTags() {
    final style = context.zoStyle;

    final length = selector.getSelected().length;

    if (length == 0) return null;

    if (widget.selectionType != ZoSelectionType.multiple ||
        widget.forceTextDisplay) {
      final text = getSelectedText();
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        hitTestBehavior: HitTestBehavior.translucent,
        child: IgnorePointer(
          child: Text(text),
        ),
      );
    }

    final selected = getSelectedOptionList(widget.maxSelectedShowNumber);

    final showMoreTips = length > widget.maxSelectedShowNumber;

    // 是否在左侧显示额外的间距，防止与光标重叠
    final showLeftPadding = canOpenMenu && isFocus && length > 0;

    final list = selected.map((opt) {
      final (value, option) = opt;
      final text = option?.getTitleText() ?? value.toString();

      final isSmall = widget.size == ZoSize.small;

      final tagConfig = _getTagConfig(value, option);
      final textColor = _getTagTextColor(tagConfig, style);

      // 通过 stack 实现
      return Stack(
        key: ValueKey(value),
        alignment: AlignmentGeometry.center,
        children: [
          IgnorePointer(
            child: _buildSelectTag(
              value: value,
              option: option,
              text: text,
              isSmall: isSmall,
            ),
          ),
          if (canOpenMenu)
            Positioned(
              right: 4,
              child: Transform.scale(
                scale: isSmall ? 0.6 : 0.8,
                alignment: Alignment.centerRight,
                child: ZoButton(
                  canRequestFocus: false,
                  icon: Icon(
                    Icons.close,
                    color: textColor,
                  ),
                  size: ZoSize.small,
                  plain: true,
                  onTap: () {
                    // 阻止点击导致层打开
                    stopOpenTimer();
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
      child: AnimatedPadding(
        padding: EdgeInsets.only(left: showLeftPadding ? 24 : 0),
        curve: Curves.easeInOut,
        duration: Durations.medium1,
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

  /// 构建展开指示器旋转动画
  Widget _buildArrowAnimation(ZoTransitionBuilderArgs<double> animate) {
    return RotationTransition(
      turns: animate.animation,
      child: animate.child,
    );
  }

  /// 构建输入框尾随区域
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
        enabled: canOpenMenu,
        icon: const Icon(
          Icons.arrow_drop_down_rounded,
          size: 24,
        ),
      ),
    );

    final Widget? clearButton = canOpenMenu
        ? ZoButton(
            key: const ValueKey("_ZO_SELECT_CLEAR_BUTTON"),
            icon: const Icon(Icons.clear),
            plain: true,
            size: ZoSize.small,
            onTap: _onClear,
          )
        : null;

    // 清空按钮显示逻辑：输入框有输入内容或包含两项以上的选中项
    var showClearButton = false;

    final inputEmpty = _inputValue == null || _inputValue!.isEmpty;

    if (!inputEmpty || selector.getSelected().length > 1) {
      showClearButton = true;
    }

    return [
      if (showClearButton && clearButton != null) clearButton,
      if (widget.showOpenIndicator) openIndicator,
      ...?widget.trailing,
    ];
  }

  /// 点击输入框区域时打开菜单
  void _onTap(PointerUpEvent event) {
    openMenu();
  }

  /// 构建输入框外层点击区域
  Widget _mainWrapper(BuildContext context, Widget mainWidget) {
    return TapRegion(
      onTapUpInside: _onTap,
      child: bindFocusWrapper(mainWidget),
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

    return buildTarget(
      context,
      ZoInput<String>(
        // 需要完全定制
        clear: false,
        // 覆盖padding
        size: widget.size,
        extra: tags,
        mainWrapper: _mainWrapper,
        // tags显示时，始终隐藏
        hintText: tags == null ? widget.hintText : null,
        leading: widget.leading,
        trailing: _buildCustomTrailing(),
        constraints: widget.constraints,
        autofocus: widget.autofocus,
        controller: widget.textController,
        enabled: widget.enabled,
        focusNode: focusNode,
        readOnly: widget.readOnly || !enableInput,
        style: widget.textStyle,
        textAlign: widget.textAlign,
        textDirection: widget.textDirection,
        textInputAction: widget.textInputAction,
        value: _inputValue,
        onChanged: _onChanged,
      ),
    );
  }
}

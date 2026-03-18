import "dart:async";

import "package:flutter/material.dart";
import "package:zo/zo.dart";

class ZoInteractiveBoxBuildArgs {
  ZoInteractiveBoxBuildArgs({
    required this.loading,
    required this.enabled,
    required this.interactive,
    required this.selected,
    required this.highlight,
    required this.active,
    required this.focus,
    required this.down,
    this.data,
  });

  final bool loading;

  final bool enabled;

  final bool interactive;

  final bool selected;

  final bool highlight;

  final bool active;

  final bool focus;

  /// 是否处于按下状态
  final bool down;

  /// 传递给组件的原始 data
  final dynamic data;
}

/// [ZoInteractiveBox] 预设样式
enum ZoInteractiveBoxStyle {
  /// 默认风格
  normal,

  /// 边框风格
  border,

  /// 填充背景色
  filled,
}

/// 聚焦边框类型
enum ZoInteractiveBoxFocusBorderType {
  /// 独立外边框
  outline,

  /// 设置到现有 box 的边框
  origin,
}

/// 预置了交互样式和常用事件的通用容器, 用于为 按钮 / 列表项 / 卡片 等提供通用的交互反馈行为和样式
class ZoInteractiveBox extends StatefulWidget {
  const ZoInteractiveBox({
    super.key,
    this.child,
    this.builder,

    this.loading = false,
    this.enabled = true,
    this.interactive = true,
    this.selected = false,
    this.highlight = false,
    this.enableColorEffect = true,

    this.style = ZoInteractiveBoxStyle.normal,
    this.status,
    this.color,
    this.selectedColor,
    this.highlightColor,
    this.disabledColor,
    this.activeColor,
    this.tapEffectColor,
    this.border,
    this.selectedBorder,
    this.highlightBorder,
    this.activeBorder,
    this.textColorAdjust = true,
    this.blendBackgroundColor,
    this.plain = false,
    this.radius,
    this.decoration,
    this.progressType = ZoProgressType.circle,
    this.iconTheme,
    this.textStyle,

    this.onTap,
    this.onContextAction,
    this.onActiveChanged,
    this.onFocusChanged,
    this.onDrag,
    this.data,

    this.focusNode,
    this.autofocus = false,
    this.canRequestFocus = true,
    this.focusOnTap = true,
    this.enableFocusBorder = true,
    this.focusBorder,
    this.focusBorderType = ZoInteractiveBoxFocusBorderType.outline,

    this.alignment,
    this.padding,
    this.decorationPadding,
    this.backgroundWidget,
    this.foregroundWidget,
    this.width,
    this.height,
    this.constraints,
    this.changeCursor = true,
    this.cursors,

    this.ref,
  });

  /// 主要内容
  final Widget? child;

  /// 通过方法构造 child，会传入 active、focus 等状态
  final Widget Function(ZoInteractiveBoxBuildArgs args)? builder;

  /// 是否显示加载状态
  final bool loading;

  /// 是否启用
  final bool enabled;

  /// 是否可进行交互, 与 enabled = false 不同的是它不设置禁用样式, 只是阻止交互行为
  final bool interactive;

  /// 是否显示选中状态样式
  final bool selected;

  /// 高亮并突出当前项
  final bool highlight;

  /// 启用交互时的颜色交互效果，即 [activeColor] 和 [tapEffectColor] 对应的交互色
  final bool enableColorEffect;

  /// 显示的基础样式类型，优先级低于其他样式配置
  final ZoInteractiveBoxStyle style;

  /// 根据颜色显示不同的状态，，优先级低于其他样式配置
  final ZoStatus? status;

  /// 自定义颜色
  final Color? color;

  /// 选中状态的背景色
  final Color? selectedColor;

  /// 高亮状态的背景色
  final Color? highlightColor;

  /// 禁用状态的背景色
  final Color? disabledColor;

  /// 活动、聚焦状态的颜色，活动状态的定义见 [onActiveChanged]
  final Color? activeColor;

  /// 点击时的反馈色
  final Color? tapEffectColor;

  /// 边框
  final BoxBorder? border;

  /// 处于选中状态下显示的边框
  final BoxBorder? selectedBorder;

  /// 处于高亮状态下显示的边框
  final BoxBorder? highlightBorder;

  /// 处于活动状态下显示的边框
  final BoxBorder? activeBorder;

  /// 根据 color 使用合适的文本色, 设置为 false 或 color 为 null 时使用默认文本色
  final bool textColorAdjust;

  /// 设置了 [textColorAdjust] 时，如果当前颜色带透明度，组件下方的容器背景色做了特殊定制时，
  /// 可以传入此项来使其能更准确的识别亮色和暗色，默认会使用 [ZoStyle.surfaceColor]
  final Color? blendBackgroundColor;

  /// 隐藏边框 / 背景色等，如果设置了 color，会使用 color 作为文本色
  final bool plain;

  /// 圆角
  final BorderRadius? radius;

  /// 应用盒子装饰
  final BoxDecoration? decoration;

  /// 加载指示器的样式
  final ZoProgressType progressType;

  /// 调整图标样式
  final IconThemeData? iconTheme;

  /// 文本样式
  final TextStyle? textStyle;

  /// 点击, 若返回一个 future, 可使按钮进入loading状态
  final dynamic Function(ZoTriggerEvent event)? onTap;

  /// 是否活动状态
  /// - 鼠标: 表示位于组件上方
  /// - 触摸设备: 按下触发, 松开或移动时关闭
  final ZoTriggerListener<ZoTriggerToggleEvent>? onActiveChanged;

  /// 焦点变更
  final ZoTriggerListener<ZoTriggerToggleEvent>? onFocusChanged;

  /// 拖拽目标
  final ZoTriggerListener<ZoTriggerDragEvent>? onDrag;

  /// 触发上下文操作, 在鼠标操作中表示右键点击, 在触摸操作中表示长按
  final ZoTriggerListener<ZoTriggerEvent>? onContextAction;

  /// 传递到事件对象的额外信息, 可在事件回调中通过 event.data 访问
  final dynamic data;

  /// 焦点控制
  final FocusNode? focusNode;

  /// 自动聚焦
  final bool autofocus;

  /// 是否可获取焦点
  final bool canRequestFocus;

  /// 是否可通过点击获得焦点, 需要同事启用点击相关的事件才能生效
  final bool focusOnTap;

  /// 聚焦时是否显示聚焦边框
  final bool enableFocusBorder;

  /// 获取焦点时，为组件设置的外边框样式
  final BoxBorder? focusBorder;

  /// 聚焦边框的类型, 可以是独立的外边框(默认)或现有 box 上的边框
  final ZoInteractiveBoxFocusBorderType focusBorderType;

  /// 控制子级对齐
  final AlignmentGeometry? alignment;

  /// 边距
  final EdgeInsets? padding;

  /// 仅用于装饰的边距，不影响实际布局空间，用于多个相同组件并列时，添加间距，但是不影响事件触发的边距
  final EdgeInsets? decorationPadding;

  /// 额外挂载内容到子级所在 stack 的后方
  final Widget? backgroundWidget;

  /// 额外挂载内容到子级所在 stack 的前方
  final Widget? foregroundWidget;

  /// 宽度
  final double? width;

  /// 高度
  final double? height;

  /// 盒子约束
  final BoxConstraints? constraints;

  /// 是否显示适合当前事件的光标类型
  final bool changeCursor;

  /// 配置不同状态下显示的光标
  final Map<ZoTriggerCursorType, MouseCursor>? cursors;

  /// 获取 state 的引用, 会在实例可用、销毁时调用，可用来便捷的访问 state 而无需创建 globalKey
  final void Function(ZoInteractiveBoxState? state)? ref;

  @override
  State<ZoInteractiveBox> createState() => ZoInteractiveBoxState();
}

class ZoInteractiveBoxState extends State<ZoInteractiveBox> {
  bool active = false;

  bool focus = false;

  /// 是否处于按下状态
  bool down = false;

  bool _localLoading = false;

  bool get isLoading {
    return widget.loading || _localLoading;
  }

  bool get _interactive => widget.interactive && !isLoading;

  AnimationController? controller;

  /// 临时的点击效果颜色
  Color? _tempTapEffectColor;

  @override
  @protected
  void initState() {
    super.initState();
    widget.ref?.call(this);
  }

  @override
  void dispose() {
    widget.ref?.call(null);

    if (_highlightTimer != null) {
      _highlightTimer!.cancel();
      _highlightTimer = null;
    }

    super.dispose();
  }

  /// 触发点击交互，需要在稍后或立即通过 [closeEffect] 关闭, 可传入只在该次反馈生效的反馈颜色
  void triggerEffect([Color? effectColor]) {
    if (controller == null || !_interactive) return;

    if (_highlightTimer != null) {
      _highlightTimer!.cancel();
      _highlightTimer = null;
    }

    _tempTapEffectColor = effectColor;

    controller!.forward(from: 0);
  }

  /// 关闭交互效果
  void closeEffect() {
    if (controller == null || !_interactive) return;
    controller!.reverse(from: 1);
  }

  Timer? _highlightTimer;

  /// 通过触发一次交互效果来短暂高亮组件
  void triggerHighlight([Color? effectColor]) {
    if (!_interactive) return;
    triggerEffect(effectColor ?? context.zoStyle.primaryColor.withAlpha(50));

    _highlightTimer = Timer(Durations.short4, closeEffect);
  }

  void _onActiveChanged(ZoTriggerToggleEvent event) {
    widget.onActiveChanged?.call(event);

    if (active == event.toggle) return;

    setState(() {
      active = event.toggle;
    });
  }

  void _onContextAction(ZoTriggerEvent event) {
    if (isLoading) return;

    widget.onContextAction?.call(event);
  }

  void _onFocusChanged(ZoTriggerToggleEvent event) {
    widget.onFocusChanged?.call(event);

    if (focus == event.toggle) return;
    setState(() {
      focus = event.toggle;
    });
  }

  void _onTap(ZoTriggerEvent event) {
    closeEffect();

    if (down) {
      setState(() {
        down = false;
      });
    }

    if (isLoading) return;

    if (widget.onTap == null) return;

    final ret = widget.onTap!(event);

    if (ret is Future) {
      setState(() {
        _localLoading = true;
      });

      ret.whenComplete(() {
        setState(() {
          _localLoading = false;
        });
      }).ignore();
    }
  }

  void _onTapDown(ZoTriggerEvent event) {
    triggerEffect();

    if (_interactive) {
      setState(() {
        down = true;
      });
    }
  }

  void _onTapCancel(ZoTriggerEvent event) {
    closeEffect();

    if (down) {
      setState(() {
        down = false;
      });
    }
  }

  void _controllerRef(AnimationController? controller) {
    this.controller = controller;
  }

  Widget _buildTapEffect(ZoStyle style, Color maskColor, BorderRadius radius) {
    return ZoTransitionBase<double>(
      controllerRef: _controllerRef,
      open: false,
      changeVisible: false,
      appear: false,
      autoAlpha: false,
      mountOnEnter: false,
      duration: const Duration(milliseconds: 40),
      reverseDuration: const Duration(milliseconds: 400),
      builder: (animate) {
        return FadeTransition(
          opacity: animate.animation,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              color: _tempTapEffectColor ?? maskColor,
            ),
          ),
        );
      },
    );
  }

  /// 获取背景色
  Color? _getBgColor(ZoStyle style) {
    if (!widget.enabled) {
      return widget.disabledColor ?? style.disabledColor;
    }

    if (widget.plain) return null;

    if (widget.selected) {
      return widget.selectedColor ?? style.selectedColor;
    }

    if (widget.highlight) {
      return widget.highlightColor ?? style.highlightColor;
    }

    if (widget.color != null) {
      return widget.color;
    }

    if (widget.status != null) {
      final statusColor = _getStatusColor(style);

      return statusColor?.withAlpha(style.alphaColorValue);
    }

    return switch (widget.style) {
      ZoInteractiveBoxStyle.normal || ZoInteractiveBoxStyle.border => null,
      ZoInteractiveBoxStyle.filled =>
        style.isDark ? Colors.white.withAlpha(24) : Colors.black.withAlpha(12),
    };
  }

  /// 获取当前要显示的文本色，传入样式和当前背景色
  Color? _getTextColor(ZoStyle style, Color? color) {
    if (!widget.enabled) {
      return style.disabledTextColor;
    }

    // 设置 plain 时按需使用 color 或默认文本色
    if (widget.plain) {
      return widget.color ?? style.textColor;
    }

    // 带主色并且需要按需调整颜色时进行调整
    if (widget.textColorAdjust && color != null) {
      // 使用固定色
      return isDarkColor(
            color,
            widget.blendBackgroundColor ?? style.surfaceColor,
          )
          ? style.darkStyle.titleTextColor
          : style.lightStyle.textColor;
    }

    // 包含传入主色，但未显示背景色，通常是因为设置了 plain 等，使用 color 作为文本色
    if (widget.color != null) {
      return widget.color;
    }

    // 其他情况使用默认文本色
    return style.textColor;
  }

  /// 获取 active、聚焦等状态显示的遮罩色
  (Color, Color) _getMaskColor(
    ZoStyle style,
    Color? color,
  ) {
    Color? effectColor = widget.tapEffectColor;

    // 包含背景色且未主动设置 tapEffectColor 时，根据背景色相反明度的点击遮罩色
    if (effectColor == null && color != null) {
      effectColor =
          isDarkColor(
            color,
            widget.blendBackgroundColor ?? style.surfaceColor,
          )
          // 有背景色时使用更深的遮罩代替 hoverColor
          ? Colors.white.withAlpha(50)
          : Colors.black.withAlpha(25);
    } else {
      effectColor = style.hoverColor;
    }

    if (active && widget.activeColor != null) {
      return (widget.activeColor!, effectColor);
    }

    return (style.hoverColor, effectColor);
  }

  /// 按需添加文本和图标色
  Widget _withTextAndIconColor(Widget child, Color? textColor) {
    if (textColor == null) return child;

    final iconTheme = IconThemeData(color: textColor).merge(widget.iconTheme);

    final textStyle = TextStyle(
      color: textColor,
    ).merge(widget.textStyle);

    return IconTheme.merge(
      data: iconTheme,
      child: DefaultTextStyle.merge(
        style: textStyle,
        child: child,
      ),
    );
  }

  /// 获取显示的边框
  BoxBorder? _getBorder(ZoStyle style, Color? color) {
    if (widget.focusBorderType == ZoInteractiveBoxFocusBorderType.origin &&
        focus &&
        widget.enableFocusBorder) {
      if (widget.focusBorder != null) return widget.focusBorder;

      // 根据背景色调整边框颜色, 放置出现叠色
      final fullbackFocusBorderColor = style.isLight
          ? Colors.black.withAlpha(100)
          : Colors.white.withAlpha(100);
      final focusBorderColor = style.primaryColor == color && color?.a == 1
          ? fullbackFocusBorderColor
          : style.primaryColor;

      return Border.all(color: focusBorderColor, width: 2);
    }

    // plain 模式下边框优先于 enable
    if (widget.plain) return null;

    // 常规状态下是否显示边框
    final hasNormalBorder =
        widget.style == ZoInteractiveBoxStyle.border || widget.border != null;

    // 未启用时, 若包含常态边框，设置默认的灰色边框
    if (!widget.enabled) {
      return hasNormalBorder ? Border.all(color: style.outlineColor) : null;
    }

    // 选中时, 依次使用设置的选中边框 > 主色边框
    if (widget.selected) {
      if (widget.selectedBorder != null) return widget.selectedBorder;

      // 包含边框并选中时，使用主色作作为边框色
      if (hasNormalBorder) return Border.all(color: style.primaryColor);

      return null;
    }

    if (widget.highlight) {
      if (widget.highlightBorder != null) return widget.highlightBorder;
      return null;
    }

    if (active && widget.activeBorder != null) {
      if (widget.activeBorder != null) return widget.activeBorder;
    }

    if (widget.border != null) {
      return widget.border;
    }

    if (widget.status != null && hasNormalBorder) {
      final statusColor = _getStatusColor(style);

      if (statusColor != null) return Border.all(color: statusColor);
    }

    return hasNormalBorder
        ? Border.all(
            color: (active || focus)
                ? style.outlineColorVariant
                : style.outlineColor,
          )
        : null;
  }

  /// 返回当前应显示的状态色
  Color? _getStatusColor(ZoStyle zoStyle) {
    return switch (widget.status) {
      ZoStatus.success => zoStyle.successColor,
      ZoStatus.error => zoStyle.errorColor,
      ZoStatus.warning => zoStyle.warningColor,
      ZoStatus.info => zoStyle.infoColor,
      _ => null,
    };
  }

  /// 根据状态获取图标
  Widget? _getStatusIcon(ZoStyle zoStyle) {
    final statusColor = _getStatusColor(zoStyle);

    return switch (widget.status) {
      ZoStatus.success => Icon(Icons.check_circle_rounded, color: statusColor),
      ZoStatus.error => Icon(Icons.cancel_rounded, color: statusColor),
      ZoStatus.warning => Icon(Icons.warning_rounded, color: statusColor),
      ZoStatus.info => Icon(Icons.info, color: statusColor),
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    /// 状态应用优先级
    /// - enable
    /// - plain
    /// - selected
    /// - highlight
    /// - active：仅边框
    /// - 直接传入的属性
    /// - status
    /// - style

    // 优化builder函数
    final style = context.zoStyle;

    // 背景色
    final color = _getBgColor(style);

    // 文本和图标颜色
    final textColor = _getTextColor(style, color);

    // 交互反馈的遮罩色
    final (maskColor, tapMaskColor) = _getMaskColor(style, color);

    // 边框
    final border = _getBorder(style, color);

    // 状态图图标
    final statusIcon = _getStatusIcon(style);

    // 圆角
    final radius = widget.radius ?? BorderRadius.circular(style.borderRadius);

    // 显示遮罩
    final needMask = focus || active;

    final decoration = widget.decoration ?? const BoxDecoration();

    final decorationPadding = widget.decorationPadding ?? EdgeInsets.zero;

    var padding =
        widget.padding ??
        // 添加适当的默认边距，方便直接使用该组件的场景
        EdgeInsets.symmetric(
          vertical: style.space2,
          horizontal: style.space3,
        );

    // 内容区域的 padding 需要加上 decorationPadding, 否则会内容移除背景区域，
    // 这对用户来说会很不直观
    if (widget.decorationPadding != null && widget.padding != null) {
      padding = EdgeInsets.fromLTRB(
        (widget.padding?.left ?? 0) + decorationPadding.left,
        (widget.padding?.top ?? 0) + decorationPadding.top,
        (widget.padding?.right ?? 0) + decorationPadding.right,
        (widget.padding?.bottom ?? 0) + decorationPadding.bottom,
      );
    }

    var child = widget.builder != null
        ? widget.builder!(
            ZoInteractiveBoxBuildArgs(
              loading: isLoading,
              enabled: widget.enabled,
              interactive: _interactive,
              selected: widget.selected,
              highlight: widget.highlight,
              active: active,
              focus: focus,
              down: down,
              data: widget.data,
            ),
          )
        : widget.child;

    if (statusIcon != null) {
      // 默认情况组件尽量占用较少空间，如果子级是 ZoTile，由于其需要一个明确尺寸，
      // 需要包装到 Expanded 中，
      final childIsTile = child is ZoTile;

      child = Row(
        spacing: style.space2,
        mainAxisSize: MainAxisSize.min,
        children: [
          statusIcon,
          ?childIsTile ? Expanded(child: child) : child,
        ],
      );
    }

    return _withTextAndIconColor(
      ZoTrigger(
        enabled: widget.enabled && _interactive,
        changeCursor: widget.changeCursor && _interactive,
        cursors: widget.cursors,
        canRequestFocus: _interactive && widget.canRequestFocus && !isLoading,
        onActiveChanged: _onActiveChanged,
        onFocusChanged: _onFocusChanged,
        onTap: _onTap,
        onTapDown: _onTapDown,
        onTapCancel: _onTapCancel,
        // context 不是必要事件，按需传入
        onContextAction: widget.onContextAction == null
            ? null
            : _onContextAction,
        onDrag: widget.onDrag,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        focusOnTap: widget.focusOnTap,
        data: widget.data,
        child: ZoProgress(
          open: isLoading,
          size: ZoSize.small,
          type: widget.progressType,
          borderRadius: radius,
          child: Stack(
            fit: StackFit.passthrough,
            children: [
              ?widget.backgroundWidget,
              // 背景层, 和内容分开, 防止被遮罩反馈影响显示
              Positioned.fill(
                key: const ValueKey("BG"),
                left: decorationPadding.left,
                top: decorationPadding.top,
                right: decorationPadding.right,
                bottom: decorationPadding.bottom,
                child: DecoratedBox(
                  decoration: decoration.copyWith(
                    color: color,
                    borderRadius: radius,
                    border: border,
                  ),
                ),
              ),
              // 聚焦边框
              if (widget.enabled &&
                  focus &&
                  widget.focusBorderType ==
                      ZoInteractiveBoxFocusBorderType.outline &&
                  widget.enableFocusBorder)
                Positioned.fill(
                  key: const ValueKey("FOCUS"),
                  left: decorationPadding.left,
                  top: decorationPadding.top,
                  right: decorationPadding.right,
                  bottom: decorationPadding.bottom,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        border:
                            widget.focusBorder ??
                            Border.all(
                              color: style.primaryColor,
                              width: 2.6,
                              strokeAlign: 2,
                            ),
                      ),
                    ),
                  ),
                ),
              // 活动或聚焦时显示的遮罩层
              if (_interactive && widget.enableColorEffect)
                Positioned.fill(
                  key: const ValueKey("ACTIVE"),
                  left: decorationPadding.left,
                  top: decorationPadding.top,
                  right: decorationPadding.right,
                  bottom: decorationPadding.bottom,
                  child: IgnorePointer(
                    child: Visibility(
                      visible: !isLoading && needMask,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          color: maskColor,
                        ),
                      ),
                    ),
                  ),
                ),
              // 点按反馈层
              if (_interactive && widget.enableColorEffect)
                Positioned.fill(
                  key: const ValueKey("FEEDBACK"),
                  left: decorationPadding.left,
                  top: decorationPadding.top,
                  right: decorationPadding.right,
                  bottom: decorationPadding.bottom,
                  child: IgnorePointer(
                    child: Visibility(
                      visible: !isLoading,
                      child: _buildTapEffect(
                        style,
                        widget.tapEffectColor ?? tapMaskColor,
                        radius,
                      ),
                    ),
                  ),
                ),
              // 按钮主要内容
              Container(
                key: const ValueKey("CONTENT"),
                alignment: widget.alignment,
                padding: padding,
                width: widget.width,
                height: widget.height,
                constraints: widget.constraints,
                child: child,
              ),
              ?widget.foregroundWidget,
            ],
          ),
        ),
      ),
      textColor,
    );
  }
}

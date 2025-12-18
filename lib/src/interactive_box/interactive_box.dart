import "package:flutter/material.dart";
import "package:zo/zo.dart";

class ZoInteractiveBoxBuildArgs {
  ZoInteractiveBoxBuildArgs({
    required this.loading,
    required this.enabled,
    required this.interactive,
    required this.active,
    required this.focus,
    this.data,
  });

  final bool loading;

  final bool enabled;

  final bool interactive;

  final bool active;

  final bool focus;

  /// 传递给组件的原始 data
  final dynamic data;
}

/// 一个预置了交互样式和回调的通用容器, 用于为 按钮 / 列表项 / 卡片 等提供通用的交互反馈行为,
/// 它会在用户进行 点击 / 按下 / hover 等操作时自动添加适当的样式
class ZoInteractiveBox extends StatefulWidget {
  const ZoInteractiveBox({
    super.key,
    this.child,
    this.builder,
    this.loading = false,
    this.enabled = true,
    this.color,
    this.radius,
    this.border,
    this.activeBorder,
    this.onTap,
    this.onContextAction,
    this.onActiveChanged,
    this.onFocusChanged,
    this.data,
    this.focusNode,
    this.autofocus = false,
    this.canRequestFocus = true,
    this.focusOnTap = true,
    this.focusBorder = true,
    this.alignment,
    this.padding,
    this.decorationPadding,
    this.backgroundWidget,
    this.foregroundWidget,
    this.width,
    this.height,
    this.constraints,
    this.decoration,
    this.interactive = true,
    this.progressType = ZoProgressType.circle,
    this.plain = false,
    this.textColorAdjust = true,
    this.disabledColor,
    this.hoverColor,
    this.tapEffectColor,
    this.iconTheme,
    this.textStyle,
  });

  /// 按钮主要内容
  final Widget? child;

  /// 通过方法构造 child，会传入 active、focus 等状态
  final Widget Function(ZoInteractiveBoxBuildArgs args)? builder;

  /// 是否显示加载状态
  final bool loading;

  /// 是否启用
  final bool enabled;

  /// 自定义颜色
  final Color? color;

  /// 圆角
  final BorderRadius? radius;

  /// 边框
  final BoxBorder? border;

  /// 处于活动状态下显示的边框
  final BoxBorder? activeBorder;

  /// 点击, 若返回一个 future, 可使按钮进入loading状态
  final dynamic Function(ZoTriggerEvent event)? onTap;

  /// 是否活动状态
  /// - 鼠标: 表示位于组件上方
  /// - 触摸设备: 按下触发, 松开或移动时关闭
  final ZoTriggerListener<ZoTriggerToggleEvent>? onActiveChanged;

  /// 焦点变更
  final ZoTriggerListener<ZoTriggerToggleEvent>? onFocusChanged;

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

  /// 获取焦点时，是否为组件设置边框样式
  final bool focusBorder;

  /// 控制子级对齐
  final AlignmentGeometry? alignment;

  /// 边距
  final EdgeInsets? padding;

  /// 仅用于装饰的边距，不影响实际布局空间，用于多个相同组件并列时，添加间距，但是不影响事件触发的边距
  final EdgeInsets? decorationPadding;

  /// 额外挂载内容到与内容所在的 stack 后方
  final Widget? backgroundWidget;

  /// 额外挂载内容到与内容所在的 stack 前方
  final Widget? foregroundWidget;

  /// 宽度
  final double? width;

  /// 高度
  final double? height;

  /// 盒子约束
  final BoxConstraints? constraints;

  /// 应用盒子装饰
  final BoxDecoration? decoration;

  /// 常规状态下隐藏边框 / 填充等, 仅在交互中显示
  final bool plain;

  /// 是否可进行交互, 与 enabled = false 不同的是它不设置禁用样式, 只是阻止交互行为
  final bool interactive;

  /// 加载指示器的样式
  final ZoProgressType progressType;

  /// 根据 color 使用合适的文本色, 设置为 false 或 color 为 null 时使用默认文本色
  final bool textColorAdjust;

  /// 禁用状态的背景色
  final Color? disabledColor;

  /// 光标悬浮状态的颜色
  final Color? hoverColor;

  /// 点击时的反馈色
  final Color? tapEffectColor;

  /// 调整图标样式
  final IconThemeData? iconTheme;

  /// 文本样式
  final TextStyle? textStyle;

  @override
  State<ZoInteractiveBox> createState() => _ZoInteractiveBoxState();
}

class _ZoInteractiveBoxState extends State<ZoInteractiveBox> {
  bool active = false;

  bool focus = false;

  bool localLoading = false;

  bool get isLoading {
    return widget.loading || localLoading;
  }

  AnimationController? controller;

  void onActiveChanged(ZoTriggerToggleEvent event) {
    widget.onActiveChanged?.call(event);

    setState(() {
      active = event.toggle;
    });
  }

  void onContextAction(ZoTriggerEvent event) {
    if (isLoading) return;

    widget.onContextAction?.call(event);
  }

  void onFocusChanged(ZoTriggerToggleEvent event) {
    widget.onFocusChanged?.call(event);

    setState(() {
      focus = event.toggle;
    });
  }

  void onTap(ZoTriggerEvent event) {
    if (isLoading) return;

    closeEffect();

    if (widget.onTap == null) return;

    final ret = widget.onTap!(event);

    if (ret is Future) {
      setState(() {
        localLoading = true;
      });

      ret.whenComplete(() {
        setState(() {
          localLoading = false;
        });
      }).ignore();
    }
  }

  void onTapDown(ZoTriggerEvent event) {
    triggerEffect();
  }

  void onTapCancel(ZoTriggerEvent event) {
    closeEffect();
  }

  void controllerRef(AnimationController? controller) {
    this.controller = controller;
  }

  void triggerEffect() {
    if (controller == null || !widget.interactive) return;
    controller!.forward(from: 0);
  }

  void closeEffect() {
    if (controller == null || !widget.interactive) return;
    controller!.reverse(from: 1);
  }

  Widget buildTapEffect(ZoStyle style, Color maskColor, BorderRadius radius) {
    return ZoTransitionBase<double>(
      controllerRef: controllerRef,
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
              color: maskColor,
            ),
          ),
        );
      },
    );
  }

  Color? getBgColor(ZoStyle style) {
    // 背景色
    Color? color;

    if (widget.plain) {
      color = null;
    } else if (!widget.enabled) {
      color = widget.disabledColor ?? style.disabledColor;
    } else if (widget.color != null) {
      color = widget.color;
    }

    return color;
  }

  Color? getTextColor(ZoStyle style, Color? color) {
    // 文本和图标颜色
    Color? textColor;

    if (widget.enabled && widget.textColorAdjust) {
      if (color != null) {
        if (isDarkColor(color)) {
          // 固定使用白色
          textColor = Colors.white;
        } else {
          // 固定取黑色文本
          textColor = style.lightStyle.textColor;
        }
      } else if (widget.color != null) {
        // 无背景色的带主色按钮, 使用主色
        textColor = widget.color;
      } else {
        // 其他情况使用默认文本色
        textColor = style.textColor;
      }
    } else if (!widget.enabled) {
      textColor = style.disabledTextColor;
    } else {
      textColor = style.textColor;
    }

    return textColor;
  }

  (Color, Color) getMaskColor(
    ZoStyle style,
    Color? color,
  ) {
    // 按钮交互时显示的遮罩色
    Color maskColor;

    if (widget.hoverColor != null) {
      maskColor = widget.hoverColor!;
    } else if (color != null) {
      // 根据背景色明度使用不同的遮罩色，alphaBlend 用于处理颜色带透明通道的场景，传入 surfaceColor
      // 是针对最常见情况，如果有异化的背景色，用户需要自行传入 widget.hoverColor 明确指定颜色
      maskColor = isDarkColor(Color.alphaBlend(color, style.surfaceColor))
          ? style.darkStyle.hoverColor
          : style.lightStyle.hoverColor;
    } else {
      // 使用hover色
      maskColor = style.hoverColor;
    }

    // 覆盖到 maskColor 之上，增加明度或暗度
    Color tapMaskColor;

    if (color != null || widget.hoverColor != null) {
      tapMaskColor =
          isDarkColor(
            Color.alphaBlend(color ?? widget.hoverColor!, style.surfaceColor),
          )
          ? Colors.white.withAlpha(80)
          : Colors.black.withAlpha(15);
    } else {
      tapMaskColor = maskColor;
    }

    return (maskColor, tapMaskColor);
  }

  /// 按需添加文本和图标色
  Widget withTextAndIconColor(Widget child, Color? textColor) {
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

  BoxBorder? getBorder(ZoStyle style, Color? color) {
    if (focus && widget.focusBorder) {
      return Border.all(color: style.primaryColor, width: 2);
    }

    if (focus || active) {
      return widget.activeBorder ?? widget.border;
    }

    return widget.border;
  }

  @override
  Widget build(BuildContext context) {
    // 优化builder函数
    final style = context.zoStyle;

    // 背景色
    final color = getBgColor(style);

    // 文本和图标颜色
    final textColor = getTextColor(style, color);

    // 交互反馈的遮罩色
    final (maskColor, tapMaskColor) = getMaskColor(style, color);

    // 圆角
    final radius = widget.radius ?? BorderRadius.circular(style.borderRadius);

    // 添加高亮样式
    final needHighlight = focus || active;

    final decoration = widget.decoration ?? const BoxDecoration();

    final decorationPadding = widget.decorationPadding ?? EdgeInsets.zero;

    var padding = widget.padding;

    // 内容区域的padding 需要加上 decorationPadding, 否则会内容移除背景区域，
    // 这对用户来说会很不直观
    if (widget.decorationPadding != null && widget.padding != null) {
      padding = EdgeInsets.fromLTRB(
        (widget.padding?.left ?? 0) + decorationPadding.left,
        (widget.padding?.top ?? 0) + decorationPadding.top,
        (widget.padding?.right ?? 0) + decorationPadding.right,
        (widget.padding?.bottom ?? 0) + decorationPadding.bottom,
      );
    }

    final child = widget.builder != null
        ? widget.builder!(
            ZoInteractiveBoxBuildArgs(
              loading: isLoading,
              enabled: widget.enabled,
              interactive: widget.interactive,
              active: active,
              focus: focus,
              data: widget.data,
            ),
          )
        : widget.child;

    return withTextAndIconColor(
      ZoTrigger(
        enabled: widget.enabled && widget.interactive,
        changeCursor: widget.interactive,
        canRequestFocus: widget.interactive && widget.canRequestFocus,
        onActiveChanged: onActiveChanged,
        onFocusChanged: onFocusChanged,
        onTap: onTap,
        onTapDown: onTapDown,
        onTapCancel: onTapCancel,
        // context 不是必要事件，按需传入
        onContextAction: widget.onContextAction == null
            ? null
            : onContextAction,
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
                    border: getBorder(style, color),
                  ),
                ),
              ),
              // 活动或聚焦时显示的遮罩层
              if (widget.interactive)
                Positioned.fill(
                  key: const ValueKey("ACTIVE"),
                  left: decorationPadding.left,
                  top: decorationPadding.top,
                  right: decorationPadding.right,
                  bottom: decorationPadding.bottom,
                  child: IgnorePointer(
                    child: Visibility(
                      visible: !isLoading && needHighlight,
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
              if (widget.interactive)
                Positioned.fill(
                  key: const ValueKey("FEEDBACK"),
                  left: decorationPadding.left,
                  top: decorationPadding.top,
                  right: decorationPadding.right,
                  bottom: decorationPadding.bottom,
                  child: IgnorePointer(
                    child: Visibility(
                      visible: !isLoading,
                      child: buildTapEffect(
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

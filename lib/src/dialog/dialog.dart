import "dart:async";

import "package:flutter/material.dart";
import "package:zo/src/result/status_icon.dart";
import "package:zo/zo.dart";

/// [ZoOverlayEntry] 的 dialog 实现, 支持各种常见的 dialog 用法, 同时还支持通过 [drawer]
/// 实现抽屉功能
class ZoDialog extends ZoOverlayEntry {
  ZoDialog({
    Widget? content,
    Widget? title,
    Widget? footer,
    ZoStatus? status,
    bool loading = false,
    Widget? icon,
    dynamic Function()? onConfirm,
    String? confirmText,
    String? cancelText,
    bool cancelButton = true,
    bool? closeButton,
    bool draggable = true,
    AxisDirection? drawer,
    double? width,
    double? height,
    EdgeInsets? padding,
    super.groupId,
    super.builder,
    super.offset,
    super.rect,
    super.alignment = Alignment.center,
    super.route = true,
    super.barrier = true,
    super.tapAwayClosable,
    super.escapeClosable,
    super.dismissMode,
    super.requestFocus,
    super.autoFocus,
    super.alwaysOnTop,
    super.mayDismiss,
    super.onDismiss,
    super.onHoverChanged,
    super.onKeyEvent,
    super.onOpenChanged,
    super.onDelayClosed,
    super.onDispose,
    // super.direction = ZoPopperDirection.top,
    super.preventOverflow = false,
    super.transitionType,
    super.animationWrap,
    super.customWrap,
    super.curve,
    super.duration,
  }) : _draggable = draggable,
       _drawer = drawer,
       _height = height,
       _width = width,
       _padding = padding,
       _closeButton = closeButton,
       _cancelButton = cancelButton,
       _cancelText = cancelText,
       _confirmText = confirmText,
       _onConfirm = onConfirm,
       _icon = icon,
       _loading = loading,
       _status = status,
       _footer = footer,
       _title = title,
       _content = content {
    if (drawer != null) {
      alignment = switch (drawer) {
        AxisDirection.up => Alignment.topCenter,
        AxisDirection.down => Alignment.bottomCenter,
        AxisDirection.left => Alignment.centerLeft,
        AxisDirection.right => Alignment.centerRight,
      };

      transitionType = switch (drawer) {
        AxisDirection.up => ZoTransitionType.slideTop,
        AxisDirection.down => ZoTransitionType.slideBottom,
        AxisDirection.left => ZoTransitionType.slideLeft,
        AxisDirection.right => ZoTransitionType.slideRight,
      };
    }
  }

  static const defaultWidth = 320.0;

  static const defaultDrawerWidth = 400.0;

  Widget? _content;

  /// 主体内容
  Widget? get content => _content;

  set content(Widget? value) {
    _content = value;
    changed();
  }

  Widget? _title;

  /// 标题
  Widget? get title => _title;

  set title(Widget? value) {
    _title = value;
    changed();
  }

  Widget? _footer;

  /// 底部内容, 此项会覆盖预置的地步操作配置, 如 onConfirm
  Widget? get footer => _footer;

  set footer(Widget? value) {
    _footer = value;
    changed();
  }

  ZoStatus? _status;

  /// 状态显示, 显示在 [title] 左侧, 所以需要同时设置
  ZoStatus? get status => _status;

  set status(ZoStatus? value) {
    _status = value;
    changed();
  }

  bool _loading;

  /// 显示 loading 状态
  bool get loading => _loading;

  set loading(bool value) {
    _loading = value;
    changed();
  }

  bool __localLoading = false;

  /// 内部 loading 状态
  bool get _localLoading => __localLoading;

  set _localLoading(bool value) {
    __localLoading = value;
    changed();
  }

  Widget? _icon;

  /// 自定义图标, 通常用于表示状态
  Widget? get icon => _icon;

  set icon(Widget? value) {
    _icon = value;
    changed();
  }

  dynamic Function()? _onConfirm;

  /// 传入时, 显示底部确认栏, 并在确认后回调
  dynamic Function()? get onConfirm => _onConfirm;

  set onConfirm(dynamic Function()? value) {
    _onConfirm = value;
    changed();
  }

  String? _confirmText;

  /// 确认按钮文本
  String? get confirmText => _confirmText;

  set confirmText(String? value) {
    _confirmText = value;
    changed();
  }

  String? _cancelText;

  /// 取消按钮文本
  String? get cancelText => _cancelText;

  set cancelText(String? value) {
    _cancelText = value;
    changed();
  }

  bool _cancelButton;

  /// 是否显示取消按钮, 为 null 时, 在显示确认按钮时, 显示取消按钮, 为 false 时强制隐藏
  bool get cancelButton => _cancelButton;

  set cancelButton(bool value) {
    _cancelButton = value;
    changed();
  }

  bool? _closeButton;

  /// 是否显示右上角关闭按钮
  bool? get closeButton => _closeButton;

  set closeButton(bool? value) {
    _closeButton = value;
    changed();
  }

  bool _draggable;

  /// 是否可拖拽移动, 设置后常规对话框的 [title] 区域可进行拖拽, 需要同时设置 [title],
  /// drawer 则是层整体可拖动
  bool get draggable => _draggable;

  set draggable(bool value) {
    _draggable = value;
    changed();
  }

  AxisDirection? _drawer;

  /// 设置后, 以抽屉模式显示, 会自动为以下属性设置值
  ///
  /// alignment / transitionType: 根据不同轴向, 会自动设置不同的值
  /// width/height: 根据方向会自动设置不同的预置尺寸
  /// closeButton: true
  AxisDirection? get drawer => _drawer;

  set drawer(AxisDirection? value) {
    _drawer = value;
    changed();
  }

  double? _width;

  /// 控制 dialog 宽度的便捷属性, 且根据具体值具有以下含义:
  /// - null: 以内容确认大小, 最小尺寸
  /// - 0 ~ 1的值: 占屏幕的百分比
  /// - 大于1的值: dialog 的绝对尺寸
  double? get width => _width;

  set width(double? value) {
    _width = value;
    changed();
  }

  double? _height;

  /// 控制 dialog 高度的便捷属性, 且根据具体值具有以下含义:
  /// - null: 以内容确认大小, 最小尺寸
  /// - 0 ~ 1的值: 占屏幕的百分比
  /// - 大于1的值: dialog 的绝对尺寸
  double? get height => _height;

  set height(double? value) {
    _height = value;
    changed();
  }

  /// 自定义边距
  EdgeInsets? _padding;

  /// 自定义边距
  EdgeInsets? get padding => _padding;

  /// 自定义边距
  set padding(EdgeInsets? value) {
    _padding = value;
    changed();
  }

  void _cancel() {
    if (overlay == null) return;
    dismiss();
  }

  Timer? delayCloseLoadingTimer;

  void _confirm() {
    if (overlay == null) return;
    final res = onConfirm?.call();

    if (res is Future) {
      _localLoading = true;
      res.whenComplete(() {
        overlay!.skipDismissCheck(dismiss);
        // 延迟一点关闭 loading 状态, 防止和关闭动画同时进行造成闪烁
        delayCloseLoadingTimer = Timer(duration, () {
          if (!_localLoading) return;
          _localLoading = false;
        });
      });
    } else {
      overlay!.skipDismissCheck(dismiss);
    }
  }

  Widget _buildWrap(BuildContext context, Widget child, bool showCloseButton) {
    final style = context.zoStyle;

    final (w, h) = _calcSize(context);

    var borderRadius = BorderRadius.circular(style.borderRadiusLG);

    if (drawer != null) {
      borderRadius = BorderRadius.only(
        topLeft: drawer == AxisDirection.left || drawer == AxisDirection.up
            ? Radius.zero
            : Radius.circular(style.borderRadiusLG),
        topRight: drawer == AxisDirection.right || drawer == AxisDirection.up
            ? Radius.zero
            : Radius.circular(style.borderRadiusLG),
        bottomLeft: drawer == AxisDirection.left || drawer == AxisDirection.down
            ? Radius.zero
            : Radius.circular(style.borderRadiusLG),
        bottomRight:
            drawer == AxisDirection.right || drawer == AxisDirection.down
            ? Radius.zero
            : Radius.circular(style.borderRadiusLG),
      );
    }

    child = Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        border: Border.all(color: style.outlineColor),
        color: style.surfaceContainerColor,
        borderRadius: borderRadius,
        boxShadow: style.brightness == Brightness.dark
            ? null
            : [style.modalShadow],
      ),
      padding: padding ?? EdgeInsets.all(style.space3),
      child: child,
    );

    if (draggable && drawer != null) {
      child = _buildDragTrigger(context, child);
    }

    // drawer 模式如果未主动关闭, 则显示关闭按钮
    if (showCloseButton) {
      child = _buildCloseButton(context, child);
    }

    return ZoProgress(
      open: loading || _localLoading,
      borderRadius: BorderRadius.circular(style.borderRadiusLG),
      child: child,
    );
  }

  Widget? _buildFooter(BuildContext context) {
    final style = context.zoStyle;
    final locale = context.zoLocale;
    if (footer != null) return footer;

    if (onConfirm != null) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.end,
        spacing: style.space2,
        children: [
          if (cancelButton)
            ZoButton(
              onTap: _cancel,
              child: Text(cancelText ?? locale.cancel),
            ),
          ZoButton(
            onTap: _confirm,
            primary: true,
            child: Text(confirmText ?? locale.confirm),
          ),
        ],
      );
    }
    return null;
  }

  Widget _buildCloseButton(BuildContext context, Widget child) {
    final style = context.zoStyle;

    return Stack(
      children: [
        child,
        Positioned(
          top: style.space2,
          right: style.space2,
          child: ZoButton(
            onTap: _cancel,
            plain: true,
            icon: const Icon(Icons.close),
          ),
        ),
      ],
    );
  }

  // 一个空的 drag handle, 用于强制启用 ZoTrigger
  void _onDrag(ZoTriggerDragEvent event) {}

  Widget _buildDragTrigger(BuildContext context, Widget child) {
    if (!draggable) return child;

    final axis = switch (drawer) {
      AxisDirection.left || AxisDirection.right => Axis.horizontal,
      AxisDirection.up || AxisDirection.down => Axis.vertical,
      _ => null,
    };

    return ZoTrigger(
      data: this,
      changeCursor: drawer == null,
      dragAxis: axis,
      onDrag: _onDrag,
      behavior: HitTestBehavior.opaque,
      canRequestFocus: false,
      notification: true,
      child: child,
    );
  }

  (double?, double?) _calcSize(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    double? cWidth;
    double? cHeight;

    if (width != null) {
      cWidth = width! <= 1 ? screenSize.width * width! : width;
    }

    if (height != null) {
      cHeight = height! <= 1 ? screenSize.height * height! : height;
    }

    if (drawer != null) {
      cWidth ??= switch (drawer!) {
        AxisDirection.left || AxisDirection.right => defaultDrawerWidth,
        AxisDirection.up || AxisDirection.down => screenSize.width,
      };
      cHeight ??= switch (drawer!) {
        AxisDirection.left || AxisDirection.right => screenSize.height,
        AxisDirection.up || AxisDirection.down => null,
      };
    }

    cWidth ??= defaultWidth;

    return (cWidth, cHeight);
  }

  /// 定义拖动边界
  @protected
  @override
  ({Rect bound, bool rubber})? getDragBound(
    Rect containerRect,
    Rect overlayRect,
  ) {
    if (!draggable) return null;

    if (drawer != null) {
      var left = containerRect.left;
      var right = containerRect.right;
      var top = containerRect.top;
      var bottom = containerRect.bottom;

      if (drawer == AxisDirection.down) {
        top = containerRect.bottom - overlayRect.height;
        bottom = containerRect.bottom + overlayRect.height;
      }

      if (drawer == AxisDirection.up) {
        top = containerRect.top - overlayRect.height;
        bottom = containerRect.top + overlayRect.height;
      }

      if (drawer == AxisDirection.right) {
        left = containerRect.right - overlayRect.width;
        right = containerRect.right + overlayRect.width;
      }

      if (drawer == AxisDirection.left) {
        left = containerRect.left - overlayRect.width;
        right = containerRect.left + overlayRect.width;
      }

      return (
        bound: Rect.fromLTRB(
          left,
          top,
          right,
          bottom,
        ),
        rubber: false,
      );
    }
    return (bound: containerRect, rubber: true);
  }

  /// 拖动达到此速度时执行关闭
  final _closeVelocity = 1800;

  /// 拖动结束时, 如果是 drawer, 判断是否需要关闭
  @protected
  @override
  bool? onDragEnd(ZoOverlayDragEndData data) {
    if (drawer == null) return null;

    final event = data.event;
    final overlayRect = data.overlayRect;
    final overlayStartRect = data.overlayStartRect;

    var shouldClose = false;

    if (drawer == AxisDirection.down &&
        event.velocity.pixelsPerSecond.dy > _closeVelocity) {
      shouldClose = true;
    }

    if (drawer == AxisDirection.up &&
        event.velocity.pixelsPerSecond.dy < -_closeVelocity) {
      shouldClose = true;
    }

    if (drawer == AxisDirection.right &&
        event.velocity.pixelsPerSecond.dx > _closeVelocity) {
      shouldClose = true;
    }

    if (drawer == AxisDirection.left &&
        event.velocity.pixelsPerSecond.dx < -_closeVelocity) {
      shouldClose = true;
    }

    if (shouldClose) {
      _cancel();
      return false;
    }

    final halfHeight = overlayRect.height / 2;
    final halfWidth = overlayRect.width / 2;

    if (drawer == AxisDirection.down) {
      if (overlayRect.top - overlayStartRect.top > halfHeight) {
        shouldClose = true;
      }
    }

    if (drawer == AxisDirection.up) {
      if (overlayStartRect.top - overlayRect.top > halfHeight) {
        shouldClose = true;
      }
    }

    if (drawer == AxisDirection.right) {
      if (overlayRect.left - overlayStartRect.left > halfWidth) {
        shouldClose = true;
      }
    }

    if (drawer == AxisDirection.left) {
      if (overlayStartRect.left - overlayRect.left > halfWidth) {
        shouldClose = true;
      }
    }

    if (shouldClose) {
      _cancel();
      return false;
    }

    return true;
  }

  @protected
  @override
  void openChanged(open) {
    super.openChanged(open);

    if (delayCloseLoadingTimer != null) {
      delayCloseLoadingTimer!.cancel();
      delayCloseLoadingTimer = null;
    }
  }

  @protected
  @override
  Widget overlayBuilder(BuildContext context) {
    final style = context.zoStyle;

    final showCloseButton =
        closeButton == true || (closeButton == null && drawer != null);

    if (builder != null) {
      return _buildWrap(
        context,
        builder!(context),
        showCloseButton,
      );
    }

    final footer = _buildFooter(context);

    final iconNode = status == null ? icon : ZoStatusIcon(status: status);

    final mainNode = Row(
      spacing: style.space2,
      children: [
        ?iconNode,
        Flexible(child: title!),
      ],
    );

    final List<Widget> children = [
      if (title != null)
        DefaultTextStyle.merge(
          style: TextStyle(
            fontSize: style.fontSizeMD,
            color: style.titleTextColor,
          ),
          child: Padding(
            padding: EdgeInsets.only(
              right: showCloseButton ? style.space5 : 0,
            ),
            child: draggable && drawer == null
                ? _buildDragTrigger(
                    context,
                    mainNode,
                  )
                : mainNode,
          ),
        ),
      if (content != null)
        ConstrainedBox(
          constraints: const BoxConstraints(
            // 固定添加一个最小尺寸
            minHeight: 50,
          ),
          child: content,
        ),
      ?footer,
    ];

    return _buildWrap(
      context,
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        spacing: style.space2,
        children: children,
      ),
      showCloseButton,
    );
  }
}

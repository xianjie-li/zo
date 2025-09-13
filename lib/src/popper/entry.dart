part of "popper.dart";

/// [ZoOverlayEntry] 的气泡实现, 提供了气泡层相关的定位 / 箭头等基础功能, 还提供了状态,
/// 快捷确认等便捷功能
///
/// 通常会使用 child / title / status 等快速配置, 如果完全定制气泡内容, 请使用 [builder],
/// 它仅保留最基本的底色 / 阴影 / 箭头样式
///
/// 大部分情况下, 会使用 [ZoPopper] 组件, 而不是直接通常 entry 使用, 除非需要在很多触发点复用
/// 同一个实例
class ZoPopperEntry extends ZoOverlayEntry {
  ZoPopperEntry({
    Widget? content,
    Widget? icon,
    ZoStatus? status,
    Widget? title,
    VoidCallback? onConfirm,
    String? confirmText,
    String? cancelText,
    double distance = 0,
    bool arrow = false,
    Size arrowSize = const Size(24, 8),
    Color? color,
    Color? borderColor,
    double? maxWidth = 180,
    EdgeInsets? padding,
    super.groupId,
    super.builder,
    super.offset,
    super.rect,
    super.alignment,
    super.route,
    super.barrier,
    super.tapAwayClosable,
    super.escapeClosable,
    super.dismissMode,
    super.requestFocus = false,
    super.alwaysOnTop,
    super.mayDismiss,
    super.onDismiss,
    super.onOpenChanged,
    super.onDelayClosed,
    super.onDispose,
    super.direction = ZoPopperDirection.top,
    super.preventOverflow,
    super.transitionType,
    super.animationWrap,
    super.curve,
    super.duration,
  }) : _padding = padding,
       _borderColor = borderColor,
       _color = color,
       _arrowSize = arrowSize,
       _arrow = arrow,
       _distance = distance,
       _content = content,
       _icon = icon,
       _status = status,
       _title = title,
       _onConfirm = onConfirm,
       _confirmText = confirmText,
       _cancelText = cancelText,
       _maxWidth = maxWidth;

  Widget? _content;

  /// 显示的主要内容
  Widget? get content => _content;

  set content(Widget? value) {
    _content = value;
    changed();
  }

  Widget? _icon;

  /// 自定义图标, 通常用于表示状态
  Widget? get icon => _icon;

  set icon(Widget? value) {
    _icon = value;
    changed();
  }

  ZoStatus? _status;

  /// 指定状态, 会在内容之前显示不同的状态图标
  ZoStatus? get status => _status;

  set status(ZoStatus? value) {
    _status = value;
    changed();
  }

  Widget? _title;

  /// 显示标题
  Widget? get title => _title;

  set title(Widget? value) {
    _title = value;
    changed();
  }

  VoidCallback? _onConfirm;

  /// 传入时, 显示底部确认栏, 并在确认后回调
  VoidCallback? get onConfirm => _onConfirm;

  set onConfirm(VoidCallback? value) {
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

  /// 取消按钮文本, 传入时显示取消按钮, 需要同时传入 [onConfirm] 才会生效
  String? get cancelText => _cancelText;

  set cancelText(String? value) {
    _cancelText = value;
    changed();
  }

  double? _maxWidth;

  /// 设置最大宽度, 默认会包含一个 180 的最大宽度, 防止 tooltip 等快捷提示占用太大宽度而显得突兀
  double? get maxWidth => _maxWidth;

  set maxWidth(double? value) {
    _maxWidth = value;
    changed();
  }

  EdgeInsets? _padding;

  /// 外间距
  EdgeInsets? get padding => _padding;

  set padding(EdgeInsets? value) {
    _padding = value;
    changed();
  }

  Color? _color;

  /// 气泡框背景色
  Color? get color => _color;

  set color(Color? value) {
    _color = value;
    changed();
  }

  Color? _borderColor;

  /// 边框色
  Color? get borderColor => _borderColor;

  set borderColor(Color? value) {
    _borderColor = value;
    changed();
  }

  /// 箭头与目标之前额外添加的间距
  final double _arrowSpace = 4;

  /// 箭头距离气泡边缘的保留区域, 用于防止箭头与气泡边缘贴合
  final double _arrowEdgeSpace = 12;

  double _distance;

  /// 距离目标的偏移, 如果设置了 [arrow], 会使用 [arrowSize] 的高度作为间距值
  @override
  double get distance {
    if (!arrow) return _distance;
    return arrowSize.height + _arrowSpace;
  }

  set distance(double value) {
    _distance = value;
    changed();
  }

  bool _arrow;

  /// 是否显示箭头
  bool get arrow => _arrow;

  set arrow(bool value) {
    _arrow = value;
    changed();
  }

  Size _arrowSize;

  /// 箭头的尺寸, 建议宽高比为 2 / 1
  Size get arrowSize => _arrowSize;

  set arrowSize(Size value) {
    _arrowSize = value;
    changed();
  }

  /// 自定义绘制, 主用确定箭头位置并进行绘制
  @override
  @protected
  void customPaint(
    OverlayPositionedRenderObject rb,
    PaintingContext context,
    ZoOverlayCustomPaintData data,
  ) {
    if (data.directionLayoutData == null) return;
    if (!arrow || arrowSize.width <= 0 || arrowSize.height <= 0) return;

    final directionData = data.directionLayoutData!;
    final offset = data.offset;
    final direction = directionData.direction;
    final size = rb.overlaySize;

    // 布局方向对应的轴方向
    final axisDirection = axisDirectionToPopperDirection(direction);

    final isVertical =
        axisDirection == AxisDirection.up ||
        axisDirection == AxisDirection.down;

    // 箭头绘制尺寸
    final paintSize = isVertical ? arrowSize : arrowSize.flipped;

    Rect? rect;

    // 将箭头移动此距离使其刚好贴合气泡容器的边框
    final fitSpace = switch (axisDirection) {
      AxisDirection.up => -2,
      AxisDirection.down => 2,
      AxisDirection.left => -1,
      AxisDirection.right => 1,
    };

    if (axisDirection == AxisDirection.up ||
        axisDirection == AxisDirection.down) {
      // 箭头大于内容尺寸时不绘制
      if (arrowSize.width > size.width) return;

      // 如果箭头边缘保留区域加上箭头尺寸大于气泡尺寸, 则强制居中显示箭头
      final forceCenter = (_arrowEdgeSpace * 2 + paintSize.width) > size.width;

      // up / down 两个方向的左中右位置
      final leftPos = offset.dx + _arrowEdgeSpace;
      final rightPos =
          offset.dx + size.width - paintSize.width - _arrowEdgeSpace;
      final centerPos = offset.dx + size.width / 2 - paintSize.width / 2;

      final mainPos = axisDirection == AxisDirection.down
          ? offset.dy - paintSize.height
          : offset.dy + size.height;

      final crossPos = switch (direction) {
        ZoPopperDirection.topLeft || ZoPopperDirection.bottomLeft => leftPos,
        ZoPopperDirection.topRight || ZoPopperDirection.bottomRight => rightPos,
        _ => centerPos,
      };

      rect = Rect.fromLTWH(
        // 交叉轴位置需要根据当前遮挡调整的偏移进行移动, 使箭头能尽量固定在视口之内
        forceCenter
            ? centerPos
            : (crossPos - directionData.crossOverflowDistance).clamp(
                leftPos,
                rightPos,
              ),
        mainPos + fitSpace,
        paintSize.width,
        paintSize.height,
      );
    } else {
      // 箭头大于内容尺寸时不绘制
      if (arrowSize.width > size.height) return;

      // 如果箭头边缘保留区域加上箭头尺寸大于气泡尺寸, 则强制居中显示箭头
      final forceCenter =
          (_arrowEdgeSpace * 2 + paintSize.height) > size.height;

      // left / right 两个方向的左中右位置
      final topPos = offset.dy + _arrowEdgeSpace;
      final bottomPos =
          offset.dy + size.height - paintSize.height - _arrowEdgeSpace;
      final centerPos = offset.dy + size.height / 2 - paintSize.height / 2;

      final mainPos = axisDirection == AxisDirection.right
          ? offset.dx - paintSize.width
          : offset.dx + size.width;

      final crossPos = switch (direction) {
        ZoPopperDirection.leftTop || ZoPopperDirection.rightTop => topPos,
        ZoPopperDirection.leftBottom ||
        ZoPopperDirection.rightBottom => bottomPos,
        _ => centerPos,
      };

      rect = Rect.fromLTWH(
        mainPos + fitSpace,
        // 交叉轴位置需要根据当前遮挡调整的偏移进行移动, 使箭头能尽量固定在视口之内
        forceCenter
            ? centerPos
            : (crossPos - directionData.crossOverflowDistance).clamp(
                topPos,
                bottomPos,
              ),
        paintSize.width,
        paintSize.height,
      );
    }

    _paintArrow(
      rb: rb,
      canvas: context.canvas,
      rect: rect,
      axisDirection: axisDirection,
    );
  }

  /// 在指定的 rect 内绘制箭头主体
  void _paintArrow({
    required OverlayPositionedRenderObject rb,
    required Canvas canvas,
    required Rect rect,
    required AxisDirection axisDirection,
  }) {
    final isVertical =
        axisDirection == AxisDirection.up ||
        axisDirection == AxisDirection.down;

    canvas.save();

    // 移动到箭头中心
    canvas.translate(rect.center.dx, rect.center.dy);

    // 从中心旋转
    switch (axisDirection) {
      case AxisDirection.up:
        canvas.rotate(math.pi);
        break;
      case AxisDirection.right:
        canvas.rotate(-math.pi / 2);
        break;
      case AxisDirection.left:
        canvas.rotate(math.pi / 2);
        break;
      case AxisDirection.down:
    }

    if (isVertical) {
      // 还原画布原点到左上角
      canvas.translate(-rect.center.dx, -rect.center.dy);
      // 从箭头左上角开始绘制
      canvas.translate(rect.left, rect.top);
    } else {
      // 横轴时, 由于宽高调换, 需要使用相反的方向
      canvas.translate(-rect.center.dy, -rect.center.dx);
      canvas.translate(rect.top, rect.left);
    }

    final style = rb.style;
    final size = rect.size;

    final ow = size.width;
    final oh = size.height - 1; // 为底部预留一像素的白底区域, 用于贴合气泡

    final w = isVertical ? ow : oh;
    final h = isVertical ? oh : ow;

    final halfW = w / 2;

    // 控制点位置占尺寸的比例
    const p1 = 0.66;
    const p2 = 0.78;

    final c1x = halfW * p1;
    final c1y = h * p2;

    final c2x = w - c1x;
    final c2y = c1y;

    final path = Path()
      ..moveTo(0, h)
      ..cubicTo(c1x, c1y, c1x, c1y, halfW, 0)
      ..cubicTo(c2x, c2y, c2x, c2y, w, h);

    canvas.drawPath(
      path,
      Paint()
        ..color = color ?? style.surfaceContainerColor
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor ?? style.outlineColor
        ..strokeWidth = 1
        ..blendMode = BlendMode.src
        ..style = PaintingStyle.stroke,
    );

    // 绘制一个底色线条来遮挡住箭头和气泡衔接处的毛边
    canvas.drawLine(
      Offset(0, h + 1),
      Offset(w, h + 1),
      Paint()
        ..color = color ?? style.surfaceContainerColor
        ..strokeWidth = 2
        ..blendMode = BlendMode.src,
    );

    canvas.restore();
  }

  void _cancel() {
    if (overlay == null) return;
    dismiss();
  }

  void _confirm() {
    if (overlay == null) return;
    dismiss();
    onConfirm?.call();
  }

  @override
  @protected
  Widget overlayBuilder(BuildContext context) {
    final style = context.zoStyle;
    final local = context.zoLocale;

    assert(content != null || builder != null);

    if (builder != null) {
      return Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor ?? style.outlineColor),
          color: color ?? style.surfaceContainerColor,
          borderRadius: BorderRadius.circular(style.borderRadius),
          boxShadow: style.brightness == Brightness.dark
              ? null
              : [style.overlayShadow],
        ),
        padding: padding,
        child: builder!(context),
      );
    }

    var child = content!;

    final hasHeader = title != null;
    final hasFooter = onConfirm != null;

    final iconNode = status == null ? icon : ZoStatusIcon(status: status);

    if (hasHeader || hasFooter) {
      child = Column(
        spacing: style.space2,
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasHeader)
            Row(
              spacing: style.space2,
              mainAxisSize: MainAxisSize.min,
              children: [
                ?iconNode,
                DefaultTextStyle.merge(
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: style.textColor,
                  ),
                  child: title!,
                ),
              ],
            ),
          child,
          if (hasFooter)
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              spacing: style.space2,
              children: [
                ZoButton(
                  size: ZoSize.small,
                  onTap: _cancel,
                  child: Text(cancelText ?? local.cancel),
                ),
                ZoButton(
                  size: ZoSize.small,
                  primary: true,
                  onTap: _confirm,
                  child: Text(confirmText ?? local.confirm),
                ),
              ],
            ),
        ],
      );
    } else if (iconNode != null) {
      child = Row(
        spacing: style.space2,
        mainAxisSize: MainAxisSize.min,
        children: [
          iconNode,
          Flexible(child: child),
        ],
      );
    }

    if (maxWidth != null) {
      child = ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth!),
        child: child,
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor ?? style.outlineColor),
        color: color ?? style.surfaceContainerColor,
        borderRadius: BorderRadius.circular(style.borderRadius),
        boxShadow: style.brightness == Brightness.dark
            ? null
            : [style.overlayShadow],
      ),
      padding:
          padding ??
          EdgeInsets.symmetric(
            // 单行文本时减少纵向间距
            vertical: hasHeader || hasFooter ? style.space3 : style.space2,
            horizontal: style.space3,
          ),
      child: child,
    );
  }
}

import "package:flutter/widgets.dart";
import "package:flutter/rendering.dart";

/// 用于监听 child 的布局和绘制, 并获取其 RenderBox, 只可用于渲染对象为 RenderBox 的子级
class RenderTrigger extends SingleChildRenderObjectWidget {
  const RenderTrigger({
    super.key,
    this.onLayout,
    this.onLayoutImmediately,
    this.onPaint,
    this.onPaintImmediately,
    this.isRepaintBoundary = false,
    required super.child,
  });

  /// 布局完成后, 在下一个渲染帧触发
  final void Function(RenderBox box)? onLayout;

  /// 布局完成后同步触发, 该回调中不可通过 setState 等方法修改状态
  final void Function(RenderBox box)? onLayoutImmediately;

  /// 绘制完成后, 在下一个渲染帧触发
  final void Function(RenderBox box)? onPaint;

  /// child 绘制完成后同步触发, 该回调中不可通过 setState 等方法修改状态
  ///
  /// 与 [onLayoutImmediately] 调用实际大部分情况下一致
  final void Function(RenderBox box)? onPaintImmediately;

  /// 将组件区域在单独的层中绘制, 这能有效减少 [onPaint] 的触发次数, 因为默认情况下,
  /// 父级和兄弟节点的绘制也会导致组件 paint 触发, 但过多的独立层也会造成性能浪费,
  /// 需使用者自行斟酌
  final bool isRepaintBoundary;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderLayoutTrigger(this);
  }

  @override
  void updateRenderObject(context, RenderLayoutTrigger renderObject) {
    renderObject.widget = this;
  }
}

base class RenderLayoutTrigger extends RenderProxyBox {
  RenderLayoutTrigger(this.widget);

  RenderTrigger widget;

  /// 减少不必要的 paint 调用
  // @override
  // bool get isRepaintBoundary => true;

  @override
  void performLayout() {
    super.performLayout();

    widget.onLayoutImmediately?.call(child!);

    if (widget.onLayout != null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        widget.onLayout?.call(child!);
      });
    }
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    super.paint(context, offset);

    widget.onPaintImmediately?.call(child!);

    if (widget.onPaint != null) {
      WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
        widget.onPaint?.call(child!);
      });
    }
  }
}

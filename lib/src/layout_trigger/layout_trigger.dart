import "package:flutter/material.dart";
import "package:flutter/rendering.dart";

/// 用于在 child 完成布局获取它的 RenderBox, 使用者需要保证 child 的渲染对象为 RenderBox
class LayoutTrigger extends SingleChildRenderObjectWidget {
  const LayoutTrigger({
    super.key,
    this.onTrigger,
    this.onImmediately,
    required super.child,
  });

  /// child 布局完成后, 在下一个渲染帧触发
  final void Function(RenderBox box)? onTrigger;

  /// child 布局完成后同步触发, 此时不可通过 setState 等方法修改状态, 但可以立即拿到已确认
  /// 尺寸的子级
  final void Function(RenderBox box)? onImmediately;

  @override
  RenderObject createRenderObject(BuildContext context) {
    return RenderLayoutTrigger(onTrigger, onImmediately);
  }

  @override
  void updateRenderObject(context, RenderLayoutTrigger renderObject) {
    renderObject.onTrigger = onTrigger;
  }
}

base class RenderLayoutTrigger extends RenderProxyBox {
  RenderLayoutTrigger(this.onTrigger, this.onImmediately);

  ValueChanged<RenderBox>? onTrigger;

  ValueChanged<RenderBox>? onImmediately;

  @override
  void performLayout() {
    super.performLayout();

    onImmediately?.call(child!);

    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      onTrigger?.call(child!);
    });
  }
}

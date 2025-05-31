import "package:flutter/material.dart";

typedef ZoTransitionBuilderArgs<T> = ({
  BuildContext context,

  /// 动画对象, 它结合了参数中配置的 curve 和 tween
  Animation<T> animation,

  /// 动画控制器
  AnimationController controller,

  /// 不带 tween 的曲线动画
  Animation<double> curveAnimation,

  /// 同组件接收的 child
  Widget? child,
});

typedef ZoTransitionBuilder<T> =
    Widget Function(ZoTransitionBuilderArgs<T> animate);

/// 用于方便的实现开关/补间类型的显式动画, 它内置了 [AnimationController] 并提供 tween, \
/// curve 等常用动画配置, 可以结合现有显式动画组件或普通组件来实现动画效果
class ZoTransitionBase<T> extends StatefulWidget {
  const ZoTransitionBase({
    super.key,
    this.open = true,
    this.appear = true,
    this.mountOnEnter = true,
    this.unmountOnExit = false,
    this.changeVisible = true,
    this.autoAlpha = true,
    this.child,
    this.tween,
    this.curve = Curves.ease,
    this.duration = Durations.medium4,
    this.builder,
    this.animationBuilder,
    this.controller,
    this.controllerRef,
    this.onStatusChange,
  });

  /// 控制动画切换
  final bool open;

  /// open 初始值为 true 时, 是否显示入场动画
  final bool appear;

  /// 如果初始 open 不是 true, 是否需要挂载组件
  final bool mountOnEnter;

  /// 动画结束后是否自动销毁组件
  final bool unmountOnExit;

  /// 关闭状态下是否自动隐藏组件
  final bool changeVisible;

  /// 是否自动添加透明度动画
  final bool autoAlpha;

  /// 子项, 子级包含与动画无关节点时, 可通过此项传入并在builder中获取, 从而减少构建
  final Widget? child;

  /// 配置补间器
  final Tween<T>? tween;

  /// 配置动画曲线
  final Curve curve;

  /// 动画持续时间
  final Duration? duration;

  /// 根据现有显式动画组件(比如 [SlideTransition]) 实现动画时使用
  final ZoTransitionBuilder<T>? builder;

  /// 需要根据动画值绑定到常规组件实现动画时使用
  final ZoTransitionBuilder<T>? animationBuilder;

  /// 自行传入控制器, 仅在需要进一步手动控制动画或监听相关行为时使用, 使用 [controllerRef]
  /// 获取内部的 controller 会更方便
  final AnimationController? controller;

  /// 在内部动画 controller 变更时调用, 用于便捷获取和使用 controller,
  /// 该 controller 由组件内部管理, 不可在外部调用 dispose
  final ValueChanged<AnimationController?>? controllerRef;

  /// 动画状态变更时进行通知
  final AnimationStatusListener? onStatusChange;

  @override
  State<ZoTransitionBase> createState() => _ZoTransitionBaseState<T>();
}

class _ZoTransitionBaseState<T> extends State<ZoTransitionBase<T>>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  /// 根据 curve 生成的动画对象
  late Animation<double> curveAnimation;

  /// 根据 curve 和 tween 生成的动画对象
  late Animation<T> animation;

  /// 当前动画状态
  late AnimationStatus status;

  /// 用于实现 mountOnEnter, 强制在build内终端build
  bool breakBuild = false;

  @override
  void initState() {
    super.initState();

    status = widget.appear
        ? AnimationStatus.dismissed
        : AnimationStatus.completed;

    controller =
        widget.controller ??
        AnimationController(
          value: widget.appear ? 0 : 1,
          vsync: this,
          duration: widget.duration,
        );

    if (widget.controller != null) {
      controller.value = widget.appear ? 0 : 1;
      controller.duration = widget.duration;
    }

    if (widget.mountOnEnter && !widget.open) {
      breakBuild = true;
    }

    updateController(null);
    updateAnimation();

    syncOpen();
  }

  @override
  void didUpdateWidget(ZoTransitionBase<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      updateController(oldWidget.controller);
    }

    if (oldWidget.tween != widget.tween || widget.curve != widget.curve) {
      updateAnimation();
    }

    if (oldWidget.duration != widget.duration) {
      controller.duration = widget.duration;
    }

    if (oldWidget.open != widget.open) {
      if (widget.open && breakBuild) {
        breakBuild = false;
      }
      syncOpen();
    }
  }

  @override
  void dispose() {
    if (controller != widget.controller) {
      widget.controllerRef?.call(null);
      controller.dispose();
    }
    super.dispose();
  }

  // 根据当前参数更新 Animation
  void updateAnimation() {
    controller = widget.controller ?? controller;

    curveAnimation = CurvedAnimation(parent: controller, curve: widget.curve);

    if (widget.tween == null) {
      animation = curveAnimation as Animation<T>;
    } else {
      animation = widget.tween!.animate(curveAnimation);
    }
  }

  /// 更新动画控制器并监听状态
  void updateController(AnimationController? oldController) {
    if (oldController != null) {
      oldController.removeStatusListener(onStatusChange);
    }
    controller.addStatusListener(onStatusChange);
    widget.controllerRef?.call(controller);
  }

  void syncOpen() {
    if (widget.open) {
      controller.forward();
    } else {
      controller.reverse();
    }
  }

  void onStatusChange(AnimationStatus status) {
    widget.onStatusChange?.call(status);
    setState(() {
      this.status = status;
    });
  }

  @override
  Widget build(BuildContext context) {
    assert(widget.builder != null || widget.animationBuilder != null);

    if (breakBuild) {
      return const SizedBox.shrink();
    }

    final args = (
      context: context,
      animation: animation,
      controller: controller,
      child: widget.child,
      curveAnimation: curveAnimation,
    );

    Widget? node;

    if (widget.builder != null) {
      node = widget.builder!(args);
    }

    if (widget.animationBuilder != null) {
      node = AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return widget.animationBuilder!(args);
        },
      );
    }

    if (widget.autoAlpha) {
      node = FadeTransition(opacity: curveAnimation, child: node!);
    }

    return Visibility(
      visible: widget.changeVisible
          ? status != AnimationStatus.dismissed
          : true,
      maintainState: !widget.unmountOnExit,
      child: node!,
    );
  }
}

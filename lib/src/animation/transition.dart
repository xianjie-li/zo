import "package:flutter/material.dart";
import "package:zo/src/animation/transition_base.dart";

/// 预置动画类型
enum ZoTransitionType {
  fade,
  zoom,
  punch,
  slideLeft,
  slideRight,
  slideTop,
  slideBottom,
}

/// 提供预置的开关动画, 如果需要更多自定义开关/补间动画, 可以使用 [ZoTransitionBase], 它是本组件的底层组件
class ZoTransition extends StatelessWidget {
  const ZoTransition({
    super.key,
    required this.child,
    this.type = ZoTransitionType.fade,
    this.open = true,
    this.appear = true,
    this.mountOnEnter = true,
    this.unmountOnExit = false,
    this.changeVisible = true,
    this.autoAlpha = true,
    this.curve = ZoTransition.defaultCurve,
    this.duration = ZoTransition.defaultDuration,
    this.reverseDuration,
    this.controller,
    this.controllerRef,
    this.onStatusChange,
  });

  static const Duration defaultDuration = Durations.medium1;

  static const Curve defaultCurve = Curves.ease;

  /// 动画类型
  final ZoTransitionType type;

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

  /// 子项
  final Widget child;

  /// 配置动画曲线
  final Curve curve;

  /// 动画持续时间
  final Duration? duration;

  /// 反向动画的持续时间
  final Duration? reverseDuration;

  /// 自行传入控制器, 仅在需要进一步手动控制动画时使用
  final AnimationController? controller;

  /// 在内部动画 controller 变更时调用, 用于便捷获取和使用 controller,
  /// 该 controller 由组件内部管理, 不可在外部调用 dispose
  final ValueChanged<AnimationController?>? controllerRef;

  /// 动画状态变更时进行通知
  final AnimationStatusListener? onStatusChange;

  Widget buildFadeUnit(ZoTransitionBuilderArgs<double> animate) {
    return child;
  }

  Widget buildFade() {
    return ZoTransitionBase<double>(
      open: open,
      appear: appear,
      mountOnEnter: mountOnEnter,
      unmountOnExit: unmountOnExit,
      changeVisible: changeVisible,
      autoAlpha: true,
      duration: duration,
      reverseDuration: reverseDuration,
      curve: curve,
      tween: Tween(begin: 1, end: 0),
      builder: buildFadeUnit,
      controller: controller,
      controllerRef: controllerRef,
      onStatusChange: onStatusChange,
    );
  }

  Widget buildZoomPunchUnit(ZoTransitionBuilderArgs<double> animate) {
    return ScaleTransition(scale: animate.animation, child: child);
  }

  Widget buildZoomPunch() {
    Tween<double> tween;

    if (type == ZoTransitionType.zoom) {
      tween = Tween(begin: 0, end: 1);
    } else {
      tween = Tween(begin: 2, end: 1);
    }

    return ZoTransitionBase<double>(
      open: open,
      appear: appear,
      mountOnEnter: mountOnEnter,
      unmountOnExit: unmountOnExit,
      changeVisible: changeVisible,
      autoAlpha: autoAlpha,
      duration: duration,
      reverseDuration: reverseDuration,
      curve: curve,
      tween: tween,
      builder: buildZoomPunchUnit,
      controller: controller,
      controllerRef: controllerRef,
      onStatusChange: onStatusChange,
    );
  }

  Widget buildSlideUnit(ZoTransitionBuilderArgs<Offset> animate) {
    return SlideTransition(position: animate.animation, child: child);
  }

  Widget buildSlide() {
    Tween<Offset> tween;

    if (type == ZoTransitionType.slideRight) {
      tween = Tween(begin: const Offset(1, 0), end: const Offset(0, 0));
    } else if (type == ZoTransitionType.slideLeft) {
      tween = Tween(begin: const Offset(-1, 0), end: const Offset(0, 0));
    } else if (type == ZoTransitionType.slideTop) {
      tween = Tween(begin: const Offset(0, -1), end: const Offset(0, 0));
    } else {
      tween = Tween(begin: const Offset(0, 1), end: const Offset(0, 0));
    }

    return ZoTransitionBase<Offset>(
      open: open,
      appear: appear,
      mountOnEnter: mountOnEnter,
      unmountOnExit: unmountOnExit,
      changeVisible: changeVisible,
      autoAlpha: autoAlpha,
      duration: duration,
      reverseDuration: reverseDuration,
      curve: curve,
      tween: tween,
      builder: buildSlideUnit,
      controller: controller,
      controllerRef: controllerRef,
      onStatusChange: onStatusChange,
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (type) {
      ZoTransitionType.fade => buildFade(),
      ZoTransitionType.punch || ZoTransitionType.zoom => buildZoomPunch(),
      ZoTransitionType.slideBottom ||
      ZoTransitionType.slideLeft ||
      ZoTransitionType.slideRight ||
      ZoTransitionType.slideTop => buildSlide(),
    };
  }
}

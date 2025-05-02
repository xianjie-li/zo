import "package:flutter/material.dart";
import "package:zo/src/transition/transition_base.dart";

export "transition_base.dart";

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
    this.curve = Curves.ease,
    this.duration = Durations.medium4,
    this.controller,
  });

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

  /// 自行传入控制器, 仅在需要进一步手动控制动画时使用
  final AnimationController? controller;

  Widget buildFade() {
    return ZoTransitionBase<double>(
      open: open,
      appear: appear,
      mountOnEnter: mountOnEnter,
      unmountOnExit: unmountOnExit,
      changeVisible: changeVisible,
      autoAlpha: true,
      duration: duration,
      curve: curve,
      tween: Tween(begin: 1, end: 0),
      builder: (animate) => child,
    );
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
      curve: curve,
      tween: tween,
      builder: (animate) {
        return ScaleTransition(scale: animate.animation, child: child);
      },
    );
  }

  Widget buildSlide() {
    Tween<Offset> tween;

    if (type == ZoTransitionType.slideRight) {
      tween = Tween(begin: Offset(1, 0), end: Offset(0, 0));
    } else if (type == ZoTransitionType.slideLeft) {
      tween = Tween(begin: Offset(-1, 0), end: Offset(0, 0));
    } else if (type == ZoTransitionType.slideTop) {
      tween = Tween(begin: Offset(0, -1), end: Offset(0, 0));
    } else {
      tween = Tween(begin: Offset(0, 1), end: Offset(0, 0));
    }

    return ZoTransitionBase<Offset>(
      open: open,
      appear: appear,
      mountOnEnter: mountOnEnter,
      unmountOnExit: unmountOnExit,
      changeVisible: changeVisible,
      autoAlpha: autoAlpha,
      duration: duration,
      curve: curve,
      tween: tween,
      builder: (animate) {
        return SlideTransition(position: animate.animation, child: child);
      },
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

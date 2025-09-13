import "dart:async";

import "package:flutter/material.dart";
import "package:flutter/scheduler.dart";

final zoAnimationKit = ZoAnimationKit();

/// 提供常用动画工具, 其本身还是一个 [TickerProvider], 每次调用 [createTicker] 都会创建一个新的 ticker
///
/// 提供的工具方法:
/// - [tickerCaller]: 限制方法只在每帧调用一次
/// - [animation]: 指令式的执行动画
class ZoAnimationKit extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }

  /// 用于 [tickerCaller] 的 ticker
  Ticker? _callerTicker;

  /// 在一段时间没有调用时, 销毁 ticker
  Timer? _callerTimer;

  /// 记录所有活动的 [tickerCaller] callback
  final Map<dynamic, VoidCallback> _callerMap = {};

  /// 对一高频调用的方法, 可以通过此方法间接调用, 它保证每一帧只会调用一次 [callback],
  /// [key] 用于标识调用者
  void tickerCaller(dynamic key, VoidCallback callback) {
    if (_callerTimer != null) {
      _callerTimer!.cancel();
    }

    _callerMap[key] = callback;

    _callerTicker ??= createTicker(_tickerCallerCallback)..start();

    _callerTimer = Timer(
      const Duration(seconds: 1),
      () {
        if (_callerTicker != null) {
          _callerTicker!.dispose();
          _callerTicker = null;
          _callerTimer = null;
          _callerMap.remove(key);
        }
      },
    );
  }

  void _tickerCallerCallback(Duration duration) {
    final removeKeys = <dynamic>[];
    _callerMap.forEach((k, v) {
      v();
      removeKeys.add(k);
    });
    for (final key in removeKeys) {
      _callerMap.remove(key);
    }
  }

  /// 指令式的创建并执行动画, 通过返回的函数可提前关闭动画
  ///
  /// 它会在内部创建一个临时的 [AnimationController], 并在动画完成后消耗它
  VoidCallback animation<T>({
    Curve curve = Curves.ease,
    Tween<T>? tween,
    Duration? duration = Durations.medium3,
    required ValueChanged<Animation<T>> onAnimation,
    VoidCallback? onEnd,
  }) {
    final controller = AnimationController(
      vsync: this,
      duration: duration,
    );

    final Animation<double> curveAnimation = CurvedAnimation(
      parent: controller,
      curve: curve,
    );
    Animation<T> animation;

    if (tween == null) {
      animation = curveAnimation as Animation<T>;
    } else {
      animation = tween.animate(curveAnimation);
    }

    controller.addListener(() {
      onAnimation(animation);
    });

    var disposed = false;

    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (disposed) return;
        disposed = true;
        onEnd?.call();
        controller.dispose();
      }
    });

    controller.forward();

    return () {
      if (disposed) return;
      disposed = true;
      onEnd?.call();
      controller.dispose();
    };
  }
}

class ZoTickerCaller {
  Ticker? ticker;

  void call(VoidCallback callback) {}
}

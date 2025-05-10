import "package:flutter/scheduler.dart";
import "package:flutter/widgets.dart";

class _AppVisibleChecker extends ChangeNotifier {
  _AppVisibleChecker() {
    _setVisibleByState(SchedulerBinding.instance.lifecycleState);

    _listener = AppLifecycleListener(
      onShow: () {
        visible = true;
      },
      onHide: () {
        visible = false;
      },
    );
  }

  late AppLifecycleListener _listener;

  bool visible = false;

  // 根据 AppLifecycleState 推测 visible 状态
  void _setVisibleByState(AppLifecycleState? state) {
    visible = switch (state) {
      AppLifecycleState.detached ||
      AppLifecycleState.inactive ||
      AppLifecycleState.paused ||
      AppLifecycleState.hidden => false,
      AppLifecycleState.resumed => true,
      _ => true, // 默认视为活动, 防止错误的阻止应用行为
    };
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }
}

/// 用于便捷的判断应用的可见状态
var appVisibleChecker = _AppVisibleChecker();

import "package:flutter/widgets.dart";

/// 一个将 [notifyListeners] 作为 public 方法暴露的 [ChangeNotifier],
/// 使在子类以外调用该方法成为可能
class ListenableNotifier extends ChangeNotifier {
  @override
  bool get hasListeners => super.hasListeners;

  @override
  void notifyListeners() {
    super.notifyListeners();
  }
}

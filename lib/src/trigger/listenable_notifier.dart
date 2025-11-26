import "package:flutter/widgets.dart";

/// 一个可随时触发的 [ChangeNotifier]
class ListenableNotifier extends ChangeNotifier {
  @override
  bool get hasListeners => super.hasListeners;

  @override
  void notifyListeners() {
    super.notifyListeners();
  }
}

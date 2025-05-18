part of "package:zo/src/overlay/overlay.dart";

class ZoOverlayRoute extends OverlayRoute {
  ZoOverlayRoute({this.onDispose, this.onPop, this.mayPop})
    : super(requestFocus: false);

  /// 路由被销毁时调用
  VoidCallback? onDispose;

  /// 路由是否可安全弹出, 返回 false 可阻止弹出
  bool Function()? mayPop;

  /// 路由弹出时调用, 无论它是否弹层成功, 可在此处添加拦截询问等操作
  void Function(bool didPop, dynamic result)? onPop;

  @override
  RoutePopDisposition get popDisposition {
    if (mayPop != null && !mayPop!()) return RoutePopDisposition.doNotPop;
    return super.popDisposition;
  }

  @override
  void onPopInvokedWithResult(bool didPop, dynamic result) {
    if (onPop == null) {
      super.onPopInvokedWithResult(didPop, result);
    } else {
      onPop!(didPop, result);
    }
  }

  late var entry = [
    OverlayEntry(
      builder: (context) {
        return const SizedBox.shrink();
      },
    ),
  ];

  @override
  void dispose() {
    onDispose?.call();
    super.dispose();
  }

  @override
  List<OverlayEntry> createOverlayEntries() {
    return entry;
  }
}

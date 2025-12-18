import "package:flutter/widgets.dart";

/// 为子级所有组件提供通用常量配置, 这些配置不会响应变更, 用于提供超时时间、重试次数等不需要经常更新的配置
class ZoConfig extends InheritedWidget {
  const ZoConfig({
    super.key,
    this.message = "",
    required super.child,
  });

  final String message;

  static ZoConfig? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ZoConfig>();
  }

  static ZoConfig of(BuildContext context) {
    final ZoConfig? result = maybeOf(context);
    assert(result != null, "No ZoConfig found in context");
    return result!;
  }

  @override
  bool updateShouldNotify(ZoConfig oldWidget) => false;
}

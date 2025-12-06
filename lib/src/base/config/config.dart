import "package:flutter/material.dart";
import "../style/style.dart";

/// 为子级所有组件提供通用配置, 配置不会响应变更, 应在挂载时确定
///
/// 样式类配置应放在 [ZoStyle] 而不是此处
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

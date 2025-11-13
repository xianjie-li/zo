import "package:flutter/widgets.dart";

/// 组件常用的几种尺寸
enum ZoSize { small, medium, large }

/// 组件常用的几种状态
enum ZoStatus { info, success, warning, error }

/// 带child的ContextBuilder
typedef WidgetChildBuilder =
    Widget Function(BuildContext context, Widget child);

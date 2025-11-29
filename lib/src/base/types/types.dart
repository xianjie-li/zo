import "package:flutter/widgets.dart";

/// 组件常用的几种尺寸
enum ZoSize { small, medium, large }

/// 组件常用的几种状态
enum ZoStatus { info, success, warning, error }

/// 选择类型
enum ZoSelectionType {
  /// 单选
  single,

  /// 多选
  multiple,

  /// 不可选
  none,
}

/// 带child的ContextBuilder
typedef WidgetChildBuilder =
    Widget Function(BuildContext context, Widget child);

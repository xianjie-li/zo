import "package:flutter/foundation.dart";

export "event_trigger.dart";
export "action_history.dart";
export "select_manager.dart";

const int maxIntValue = kIsWeb ? 9007199254740991 : 9223372036854775807;
const int minIntValue = kIsWeb ? -9007199254740991 : -9223372036854775808;

/// Zo 中通用的异常类型
class ZoException implements Exception {
  final String message;

  ZoException(this.message);

  @override
  String toString() {
    return "ZoException: $message";
  }
}

var _uniqueId = 0;

/// 返回一个相对于应用生命周期唯一的id
int createTempId() {
  _uniqueId++;
  return _uniqueId;
}

/// 数值显示, 不带小数类型正常显示, 带小数时显示指定未数
String displayNumber(num value, [int? precision]) {
  if (value % 1 == 0) {
    return value.toInt().toString();
  } else {
    return precision == null
        ? value.toString()
        : value.toStringAsFixed(precision);
  }
}

/// 检测传入类型是否为空值, 支持常见类型: null "" 0 false List Set Map Iterable
bool isNil(dynamic value) {
  if (value == null) {
    return true;
  } else if (value is String) {
    return value.isEmpty;
  } else if (value is num) {
    return value.toDouble() == 0;
  } else if (value is bool) {
    return !value;
  } else if (value is List) {
    return value.isEmpty;
  } else if (value is Map) {
    return value.isEmpty;
  } else if (value is Set) {
    return value.isEmpty;
  } else if (value is Iterable) {
    return value.isEmpty;
  }

  return false;
}

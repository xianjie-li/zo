import "dart:async";

import "package:flutter/widgets.dart";

export "../trigger/event_trigger.dart";
export "action_history.dart";
export "selector.dart";
export "shortcuts.dart";

// const int maxIntValue = kIsWeb ? 9007199254740991 : 9223372036854775807;
// const int minIntValue = kIsWeb ? -9007199254740991 : -9223372036854775808;

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
String createTempId() {
  _uniqueId++;
  return _uniqueId.toString();
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

/// 根据传入对象递归获取hash, 会尝试对 list / map / set 等常见结构进行递归获取, 传入对象不
/// 可包含递归结构
int deepHash(Object? value) {
  if (value == null) return value.hashCode;

  if (value is List) {
    return Object.hashAll(value.map(deepHash));
  }

  if (value is Map) {
    return Object.hashAll(
      value.entries.map((e) => Object.hash(deepHash(e.key), deepHash(e.value))),
    );
  }

  if (value is Set) {
    return Object.hashAll(value.map(deepHash).toList()..sort()); // 无序处理
  }

  // 其他情况: 尝试使用 hashCode, 可能由于对象实现 hashCode 而导致不一致, 但对于大多数标准库
  // 类型来说这是正常的
  return value.hashCode;
}

/// 防抖
class Debouncer {
  final Duration delay;
  Timer? _timer;

  Debouncer({required this.delay});

  // 当调用 run 时，它会启动或重置计时器
  void run(VoidCallback action) {
    // 如果已有计时器，先取消
    _timer?.cancel();
    // 创建一个新的计时器，在 delay 时间后执行 action
    _timer = Timer(delay, action);
  }

  // 可以在 Widget dispose 时调用，以确保没有悬挂的计时器
  void cancel() {
    _timer?.cancel();
  }
}

/// 节流
class Throttler {
  final Duration delay;
  Timer? _timer;
  bool _isReady = true;

  Throttler({required this.delay});

  void run(VoidCallback action) {
    if (!_isReady) {
      return;
    }

    action();
    _isReady = false;
    // 启动计时器，在 delay 时间后恢复 _isReady
    _timer = Timer(delay, () {
      _isReady = true;
    });
  }

  void cancel() {
    _timer?.cancel();
    _isReady = true;
  }
}

import "dart:async";

import "package:flutter/widgets.dart";

export "operation_history.dart";
export "app_state.dart";
export "global_cursor.dart";
export "mutator.dart";
export "selector.dart";
export "shortcuts.dart";
export "tree_utils.dart";

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

  /// 是否执行尾随请求，假设正在对滚动操作进行节流，可能会因为接到导致没有对最终的滚动位置进行响应，
  /// 设置后会在所有操作结束后必定执行一次操作
  final bool trailing;

  Timer? _timer;

  /// 是否存在被拦截的操作
  bool _hasBlocked = false;

  Throttler({
    required this.delay,
    this.trailing = true,
  });

  void run(VoidCallback action) {
    if (_timer != null) {
      _hasBlocked = true;
      return;
    }

    action();

    void delayCall() {
      // 延迟一段时间后重新接收执行，如果期间存在新的执行请求，在末尾执行
      _timer = Timer(delay, () {
        // 处理被拦截操作
        if (trailing && _hasBlocked) {
          _hasBlocked = false;
          action();

          // 重新设置计时器
          delayCall();
        } else {
          _timer = null;
        }
      });
    }

    delayCall();
  }

  void cancel() {
    _timer?.cancel();
  }
}

/// 判断指定颜色是否应使用浅色文本
bool useLighterText(Color color) {
  // 如果颜色包含较大的透明度，则使用浅色文本
  if (color.a < 0.5) return false;

  return color.computeLuminance() < 0.5;
}

import "dart:math" as math;

/// 数学相关的一写静态工具方法
class ZoMathUtils {
  /// 容差常数, 防止因为浮点数精度问题导致的抖动导致对比异常, 以及提供一个合理的零值比较范围
  static const double _kEpsilon = 1e-9;

  /// 10 的 10 次方, 用于精度截断
  static const double _kFractionMultiplier = 10000000000.0;

  /// 安全正数判断, 截断了非常小的正数, 避免因为浮点数精度问题导致的抖动导致的对比异常
  static bool isPositive(double value) {
    return value > _kEpsilon;
  }

  /// 零值归一化, 避免出现 0.30000000000000004
  static double normalizeZero(double value) {
    return value.abs() < _kEpsilon ? 0.0 : value;
  }

  /// 保留指定位数的小数，砍掉后面的精度尾巴, 避免因为浮点数精度问题导致的抖动
  static double roundStable(double value) {
    return (value * _kFractionMultiplier).roundToDouble() /
        _kFractionMultiplier;
  }

  /// 支持自定义精度的 [roundStable]
  static double round(double value, [int fractionDigits = 2]) {
    final factor = math.pow(10, fractionDigits).toDouble();
    return (value * factor).roundToDouble() / factor;
  }

  /// 归一化值, 先保留一定的小数，再进行零值归一化
  static double normalize(double value, [int fractionDigits = 10]) {
    if (fractionDigits == 10) {
      return normalizeZero(roundStable(value));
    } else {
      return normalizeZero(round(value, fractionDigits));
    }
  }

  /// 安全零值判断, 用于处理非常接近 0 的浮点数。
  static bool isZero(double value, [double epsilon = _kEpsilon]) {
    return value.abs() <= epsilon;
  }

  /// 两个值是否在给定容差范围内视为相等。
  static bool equals(double a, double b, [double epsilon = _kEpsilon]) {
    return isZero(a - b, epsilon);
  }

  /// 小于判断, 会避开 epsilon 范围内的抖动。
  static bool lessThan(double a, double b, [double epsilon = _kEpsilon]) {
    return a < b - epsilon;
  }

  /// 小于等于判断, 会将 epsilon 范围内的抖动视为相等。
  static bool lessThanOrEqual(
    double a,
    double b, [
    double epsilon = _kEpsilon,
  ]) {
    return lessThan(a, b, epsilon) || equals(a, b, epsilon);
  }

  /// 大于判断, 会避开 epsilon 范围内的抖动。
  static bool greaterThan(double a, double b, [double epsilon = _kEpsilon]) {
    return a > b + epsilon;
  }

  /// 大于等于判断, 会将 epsilon 范围内的抖动视为相等。
  static bool greaterThanOrEqual(
    double a,
    double b, [
    double epsilon = _kEpsilon,
  ]) {
    return greaterThan(a, b, epsilon) || equals(a, b, epsilon);
  }

  /// 当值接近目标值时，直接吸附到目标值。
  static double snapTo(
    double value,
    double target, [
    double threshold = _kEpsilon,
  ]) {
    final safeThreshold = math.max(threshold.abs(), _kEpsilon);
    return equals(value, target, safeThreshold) ? target : value;
  }

  /// 带容差的 clamp，接近边界时会直接贴边。
  static double clamp(
    double value,
    double min,
    double max, [
    double epsilon = _kEpsilon,
  ]) {
    assert(min <= max, "min must be less than or equal to max");

    if (lessThanOrEqual(value, min, epsilon)) {
      return min;
    }

    if (greaterThanOrEqual(value, max, epsilon)) {
      return max;
    }

    return value;
  }
}

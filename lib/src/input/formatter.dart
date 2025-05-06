import "package:flutter/services.dart";
import "package:zo/zo.dart";

/// 处理数值类型格式化
class NumberTextInputFormatter extends TextInputFormatter {
  const NumberTextInputFormatter({this.isInteger = false, this.max, this.min});

  /// 最大值
  final double? max;

  /// 最小值
  final double? min;

  /// 只能输入整数
  final bool isInteger;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var text = newValue.text;
    if (newValue.text.isEmpty) return newValue;

    // 阻止非小数的数值以0开始
    if (text.startsWith(RegExp(r"[0][0-9]"))) {
      return oldValue;
    }

    var endInd = newValue.selection.end;

    var newOffset = endInd;

    // 拆分光标前后的字符串
    var prevStr = text.substring(0, endInd);
    var lastStr = text.substring(endInd);

    var hasNegativeSing = text.startsWith("-");

    // 整形输入时只保留数字, 浮点型输入保留dot和数字
    var reg = isInteger ? RegExp(r"[^0-9]+") : RegExp(r"[^\.0-9]+");

    // 计算结束光标前所有reg字符总数
    var prevMatches = reg.allMatches(prevStr, 0);

    var prevCount = prevMatches
        .map((i) => i.end - i.start)
        .fold(0, (prev, cur) => prev + cur);

    newOffset -= prevCount;

    // 移除所有非reg字符
    var str = (prevStr + lastStr).replaceAll(reg, "");

    /// 查找所有dot中最接近光标位置的
    int? nearDotIndex;
    var matchDots = RegExp(r"\.").allMatches(str);

    for (var i in matchDots) {
      if (nearDotIndex == null) {
        nearDotIndex = i.start;
        continue;
      }

      var prevDiff = (nearDotIndex - newOffset).abs();
      var diff = (i.start - newOffset).abs();

      if (diff < prevDiff) {
        nearDotIndex = i.start;
      }
    }

    // 处理dot, 只保留 nearDotIndex
    if (!isInteger && nearDotIndex != null) {
      // 拆分dot前后的字符串, 并去掉所有dot
      var prevDotStr = str.substring(0, nearDotIndex);
      var lastDotStr = str.substring(nearDotIndex + 1);

      var prevStr = prevDotStr.replaceAll(".", "");
      var lastStr = lastDotStr.replaceAll(".", "");

      // 计算光标前的dot数量, 并前移光标
      var prevCursorDotStr = str.substring(0, newOffset);
      var prevCursorDotStrLen = prevCursorDotStr.length;
      var prevCursorDotNum =
          prevCursorDotStrLen - prevCursorDotStr.replaceAll(".", "").length;

      // 需要移动光标
      if (prevCursorDotNum > 0) {
        // 如果光标后还有其他dot则前移删除总数, 否则少移动一位
        var diff =
            newOffset > nearDotIndex ? prevCursorDotNum - 1 : prevCursorDotNum;
        newOffset -= diff;
      }

      // 处理dot后的字符串
      str = "$prevStr.$lastStr";

      // 防止处理后以0开头
      if (str.startsWith(RegExp(r"[0][0-9]"))) {
        str = str.substring(1);
        newOffset -= 1;
      }
    }

    // 处理sign
    if (hasNegativeSing) {
      str = "-$str";
      newOffset += 1;
    }

    // max / min 处理
    if (min != null) {
      if (isInteger) {
        var iVal = int.tryParse(str);
        if (iVal != null) {
          if (iVal < min!) {
            str = displayNumber(min!);
            newOffset = str.length;
          }
        }
      } else {
        var dVal = double.tryParse(str);
        if (dVal != null) {
          if (dVal < min!) {
            str = displayNumber(min!);
            newOffset = str.length;
          }
        }
      }
    }

    if (max != null) {
      if (isInteger) {
        var iVal = int.tryParse(str);
        if (iVal != null) {
          if (iVal > max!) {
            str = displayNumber(max!);
            newOffset = str.length;
          }
        }
      } else {
        var dVal = double.tryParse(str);
        if (dVal != null) {
          if (dVal > max!) {
            str = displayNumber(max!);
            newOffset = str.length;
          }
        }
      }
    }

    if (str == newValue.text) return newValue;

    return TextEditingValue(
      text: str,
      selection: TextSelection.collapsed(offset: newOffset),
      composing: TextRange.empty,
    );
  }
}

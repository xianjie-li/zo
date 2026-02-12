import "package:flutter/widgets.dart";

/// 检测文本是否溢出
bool hasTextOverflow(
  String text,
  TextStyle style, {
  required TextScaler textScaler,
  required double maxWidth,
  int maxLines = 1,
  TextDirection textDirection = TextDirection.ltr,
}) {
  final TextPainter textPainter = TextPainter(
    text: TextSpan(text: text, style: style),
    maxLines: maxLines,
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  )..layout(maxWidth: maxWidth);

  return textPainter.didExceedMaxLines;
}

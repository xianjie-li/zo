import "package:flutter/material.dart";
import "package:zo/zo.dart";

MouseCursor? _cursor;

ZoOverlayEntry? _currentEntry;

/// 全局更改光标的样式
class GlobalCursor {
  /// 当前正在显示的光标
  static MouseCursor? get currentCursor => _cursor;

  /// 显示全局光标, 设置 block 为 true 则会阻止下方事件触发
  static void show(MouseCursor cursor, [bool block = false]) {
    _cursor = cursor;

    Widget builder(BuildContext context) {
      return MouseRegion(
        opaque: block,
        hitTestBehavior: block
            ? HitTestBehavior.opaque
            : HitTestBehavior.translucent,
        cursor: cursor,
      );
    }

    if (_currentEntry != null) {
      _currentEntry!.builder = builder;
      return;
    }

    _currentEntry = ZoOverlayEntry(
      offset: Offset.zero,
      tapAwayClosable: false,
      escapeClosable: false,
      requestFocus: false,
      preventOverflow: false,
      alwaysOnTop: true,
      duration: Duration.zero,
      builder: builder,
    );

    zoOverlay.open(_currentEntry!);
  }

  /// 恢复默认光标
  static void hide() {
    _cursor = null;

    if (_currentEntry != null) {
      _currentEntry!.disposeSelf();
      _currentEntry = null;
    }
  }
}

import "package:flutter/foundation.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";

/// 一些用于按键事件处理的工具
class ZoShortcutsHelper {
  /// 使用兼容不同平台的命令键构造实例，在mac这类系统使用 meta 键作为控制键，其他系统则使用 control
  static SingleActivator platformAwareActivator(
    LogicalKeyboardKey trigger, {
    bool shift = false,
    bool alt = false,
    LockState numLock = LockState.ignored,
    bool includeRepeats =
        false, // 这与 SingleActivator 预设不同，因为使用控制键时大部分情况不需要 repeat 行为
  }) {
    return SingleActivator(
      trigger,
      meta: useMetaKey,
      control: !useMetaKey,
      shift: shift,
      alt: alt,
      numLock: numLock,
      includeRepeats: includeRepeats,
    );
  }

  /// 检测 [event] 是否符合触发 [activator] 的条件
  static bool checkEvent(SingleActivator activator, KeyEvent event) {
    return activator.accepts(event, HardwareKeyboard.instance);
  }

  /// 当前平台是否应该使用meta作为控制键
  static bool get useMetaKey {
    return defaultTargetPlatform == TargetPlatform.macOS ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  /// 当前是否只按下了单个按键
  static bool get isSingleKeyPressed {
    return HardwareKeyboard.instance.physicalKeysPressed.length == 1 ||
        HardwareKeyboard.instance.logicalKeysPressed.length == 1;
  }

  /// 是否按下了平台特定的控制键, 在mac这类系统使用 meta 键作为控制键，其他系统则使用 control
  static bool get isCommandPressed {
    return useMetaKey ? isMetaPressed : isControlPressed;
  }

  static get isControlPressed {
    return HardwareKeyboard.instance.isControlPressed;
  }

  static get isMetaPressed {
    return HardwareKeyboard.instance.isMetaPressed;
  }

  static get isAltPressed {
    return HardwareKeyboard.instance.isAltPressed;
  }

  static get isShiftPressed {
    return HardwareKeyboard.instance.isShiftPressed;
  }
}

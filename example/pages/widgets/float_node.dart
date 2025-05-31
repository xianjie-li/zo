import "package:flutter/material.dart";
import "package:flutter/services.dart"; // For LogicalKeyboardKey

// 定义回调函数类型
typedef RectChangedCallback = void Function(Rect globalRect);

/// 用于调试 overlay 的定位
class FocusMoveOverlayWidget extends StatefulWidget {
  /// 锚点Widget，点击它会尝试显示悬浮层
  final Widget anchorChild;

  /// 悬浮层中显示的Widget
  final Widget overlayContentChild;

  /// 悬浮层位置或尺寸变化时的回调
  final RectChangedCallback onRectChanged;

  /// 每次按键移动的步长
  final double moveStep;

  /// 悬浮层的初始偏移量 (相对于Overlay的左上角)
  final Offset initialPosition;

  const FocusMoveOverlayWidget({
    super.key,
    required this.anchorChild,
    required this.overlayContentChild,
    required this.onRectChanged,
    this.moveStep = 20.0,
    this.initialPosition = const Offset(50, 50),
  });

  @override
  State<FocusMoveOverlayWidget> createState() => _FocusMoveOverlayWidgetState();
}

class _FocusMoveOverlayWidgetState extends State<FocusMoveOverlayWidget> {
  final OverlayPortalController _overlayController = OverlayPortalController();
  final FocusNode _focusNode = FocusNode();
  final GlobalKey _overlayContentKey = GlobalKey(); // 用于获取悬浮内容的尺寸和位置

  late Offset _currentPosition;
  bool _isPortalShown = false;

  @override
  void initState() {
    super.initState();
    _currentPosition = widget.initialPosition;
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    // _overlayController is managed by OverlayPortal, no need to dispose explicitly
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus && _isPortalShown) {
      // 如果失去焦点，可以选择隐藏悬浮层
      // _togglePortalVisibility(show: false);
      // 或者根据产品需求决定是否隐藏
      print("Overlay content lost focus");
    } else if (_focusNode.hasFocus) {
      print("Overlay content gained focus");
      _reportRect(); // 获得焦点时也报告一次位置
    }
  }

  void _togglePortalVisibility({bool? show}) {
    setState(() {
      if (show != null) {
        _isPortalShown = show;
      } else {
        _isPortalShown = !_isPortalShown;
      }

      if (_isPortalShown) {
        _overlayController.show();
        // 确保悬浮层构建完成后再请求焦点并报告位置
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _focusNode.requestFocus();
          _reportRect();
        });
      } else {
        _overlayController.hide();
        // 如果有锚点可以重新获得焦点，则将焦点移回
        // FocusScope.of(context).requestFocus(FocusNode()); // Or a specific node
      }
    });
  }

  KeyEventResult _handleKeyPress(FocusNode node, KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      bool moved = false;
      Offset newPosition = _currentPosition;

      if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
        newPosition = Offset(
          _currentPosition.dx,
          _currentPosition.dy - widget.moveStep,
        );
        moved = true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
        newPosition = Offset(
          _currentPosition.dx,
          _currentPosition.dy + widget.moveStep,
        );
        moved = true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {
        newPosition = Offset(
          _currentPosition.dx - widget.moveStep,
          _currentPosition.dy,
        );
        moved = true;
      } else if (event.logicalKey == LogicalKeyboardKey.arrowRight) {
        newPosition = Offset(
          _currentPosition.dx + widget.moveStep,
          _currentPosition.dy,
        );
        moved = true;
      }

      if (moved) {
        setState(() {
          _currentPosition = newPosition;
        });
        // 位置变化后，在下一帧报告新的Rect
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _reportRect();
        });
        return KeyEventResult.handled; // 表示事件已处理
      }
    }
    return KeyEventResult.ignored; // 表示事件未处理，继续传递
  }

  void _reportRect() {
    if (!_isPortalShown || _overlayContentKey.currentContext == null) {
      return;
    }
    final RenderBox? renderBox =
        _overlayContentKey.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final size = renderBox.size;
      final offset = renderBox.localToGlobal(Offset.zero); // 获取全局偏移
      final globalRect = Rect.fromLTWH(
        offset.dx,
        offset.dy,
        size.width,
        size.height,
      );
      widget.onRectChanged(globalRect);
      // print('Overlay Rect: $globalRect');
    }
  }

  @override
  Widget build(BuildContext context) {
    return OverlayPortal(
      controller: _overlayController,
      overlayChildBuilder: (BuildContext context) {
        // 使用 RepaintBoundary 可以优化移动时的重绘性能
        // 使用 KeyedSubtree 确保 GlobalKey 总是关联到正确的 Widget 实例
        return Positioned(
          top: _currentPosition.dy,
          left: _currentPosition.dx,
          child: RepaintBoundary(
            child: KeyedSubtree(
              key: _overlayContentKey, // 用于获取悬浮内容的 RenderBox
              child: Focus(
                focusNode: _focusNode,
                onKeyEvent: _handleKeyPress, // 监听按键事件
                autofocus: false, // 通常不由Focus小部件直接自动对焦，而是由代码控制
                child: widget.overlayContentChild,
              ),
            ),
          ),
        );
      },
      // 锚点Widget
      child: GestureDetector(
        onTap: () {
          _togglePortalVisibility();
        },
        child: widget.anchorChild,
      ),
    );
  }
}

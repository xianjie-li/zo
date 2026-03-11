import "package:flutter/material.dart";
import "package:zo/zo.dart";

/// 用于为滚动容器添加可滚动阴影指示器
class ZoScrollIndicatorContainer extends StatefulWidget {
  final Widget child;
  final Axis axis;
  final List<Color>? shadowColor;
  final double shadowSize;

  const ZoScrollIndicatorContainer({
    super.key,
    required this.child,
    this.axis = Axis.horizontal, // 默认横向，适合 Tab 场景
    this.shadowColor, // 阴影颜色
    this.shadowSize = 12.0, // 阴影宽度/高度
  });

  @override
  State<ZoScrollIndicatorContainer> createState() =>
      _ZoScrollIndicatorContainerState();
}

class _ZoScrollIndicatorContainerState
    extends State<ZoScrollIndicatorContainer> {
  bool _showStart = false;
  bool _showEnd = false;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ViewportNotificationMixin>(
      onNotification: (notification) {
        // 处理 ScrollUpdateNotification (滚动中) 和 ScrollMetricsNotification (内容大小改变时)
        // 需要监听 ViewportNotificationMixin，否则在初始化时不会执行
        if (notification is ScrollUpdateNotification) {
          _updateShadows(notification.metrics);
        } else if (notification is ScrollMetricsNotification) {
          _updateShadows(notification.metrics);
        }
        return false; // 允许事件继续向上冒泡
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. 实际的滚动视图
          widget.child,

          // 2. 头部指示器 (Left / Top)
          if (_showStart) _getStartIndicator(),

          // 3. 尾部指示器 (Right / Bottom)
          if (_showEnd) _getEndIndicator(),
        ],
      ),
    );
  }

  Positioned _getStartIndicator() {
    if (widget.axis == Axis.horizontal) {
      return Positioned(
        key: const ValueKey("start"),
        left: 0,
        top: 0,
        bottom: 0,
        width: widget.shadowSize,
        child: _buildShadow(true),
      );
    }

    return Positioned(
      key: const ValueKey("start"),
      left: 0,
      top: 0,
      right: 0,
      height: widget.shadowSize,
      child: _buildShadow(true),
    );
  }

  Positioned _getEndIndicator() {
    if (widget.axis == Axis.horizontal) {
      return Positioned(
        key: const ValueKey("end"),
        top: 0,
        right: 0,
        bottom: 0,
        width: widget.shadowSize,
        child: _buildShadow(false),
      );
    }

    return Positioned(
      key: const ValueKey("end"),
      left: 0,
      bottom: 0,
      right: 0,
      height: widget.shadowSize,
      child: _buildShadow(false),
    );
  }

  void _updateShadows(ScrollMetrics metrics) {
    // 过滤掉非当前方向的滚动通知 (以防嵌套滚动)
    if (metrics.axis != widget.axis) return;

    // extentBefore > 0 意味着前面有内容被卷进去了 -> 显示头部阴影
    final showStart = metrics.extentBefore > 0;

    // extentAfter > 0 意味着后面还有内容没显示出来 -> 显示尾部阴影
    final showEnd = metrics.extentAfter > 0;

    if (_showStart != showStart || _showEnd != showEnd) {
      setState(() {
        _showStart = showStart;
        _showEnd = showEnd;
      });
    }
  }

  Widget _buildShadow(bool isStart) {
    final style = context.zoStyle;
    // 使用 IgnorePointer 防止阴影遮挡下面的点击事件
    return IgnorePointer(
      child: Container(
        width: widget.shadowSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2),
          gradient: LinearGradient(
            begin: isStart
                ? (widget.axis == Axis.horizontal
                      ? Alignment.centerLeft
                      : Alignment.topCenter)
                : (widget.axis == Axis.horizontal
                      ? Alignment.centerRight
                      : Alignment.bottomCenter),
            end: isStart
                ? (widget.axis == Axis.horizontal
                      ? Alignment.centerRight
                      : Alignment.bottomCenter)
                : (widget.axis == Axis.horizontal
                      ? Alignment.centerLeft
                      : Alignment.topCenter),
            colors: widget.shadowColor ?? style.shadowGradientColors,
          ),
        ),
      ),
    );
  }
}

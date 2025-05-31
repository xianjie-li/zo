import "package:flutter/material.dart";
import "package:zo/zo.dart";

/// 预置状态图标
class ZoStatusIcon extends StatelessWidget {
  const ZoStatusIcon({super.key, this.status, this.size});

  /// 状态
  final ZoStatus? status;

  /// 尺寸
  final double? size;

  @override
  Widget build(BuildContext context) {
    if (status == null) return const SizedBox.shrink();

    return switch (status!) {
      ZoStatus.success => Icon(
        Icons.check_circle_rounded,
        color: context.zoStyle.successColor,
        size: size,
      ),
      ZoStatus.error => Icon(
        Icons.cancel_rounded,
        color: context.zoStyle.errorColor,
        size: size,
      ),
      ZoStatus.warning => Icon(
        Icons.warning_rounded,
        color: context.zoStyle.warningColor,
        size: size,
      ),
      ZoStatus.info => Icon(
        Icons.info,
        color: context.zoStyle.infoColor,
        size: size,
      ),
    };
  }
}

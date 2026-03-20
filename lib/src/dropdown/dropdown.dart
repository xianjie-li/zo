import "package:flutter/material.dart";
import "package:zo/zo.dart";

/// 基于 [ZoMenusTrigger] 的下拉按钮组件
///
/// 默认显示 [child]
///
/// 有选中值时显示逗号分隔的选中文本
class ZoDropdown extends StatelessWidget {
  const ZoDropdown({
    super.key,
    this.value = const [],
    this.onChanged,
    required this.options,
    required this.child,
    this.selectionType = ZoSelectionType.single,
    this.branchSelectable = false,
    this.selectMenuType = ZoMenusTriggerType.menu,
    this.toolbar,
    this.size,
    this.buttonMinWidth,
    this.buttonMaxWidth,
    this.menuWidth = 200,
    this.maxSelectedShowNumber = 10,
    this.showOpenIndicator = true,
    this.enabled = true,
    this.openOnFocus = false,
    this.focusNode,
  }) : assert(
         buttonMaxWidth == null || buttonMaxWidth > 0,
         "buttonMaxWidth must be greater than 0",
       );

  /// 当前选中值
  ///
  /// 不传时按空选中集处理
  final Iterable<Object>? value;

  /// 选中值变更回调
  final ZoFormOnChanged<Iterable<Object>>? onChanged;

  /// 选项列表
  final List<ZoOption> options;

  /// 未选中时显示内容
  final Widget child;

  /// 选择类型
  final ZoSelectionType selectionType;

  /// 分支节点是否可选
  final bool branchSelectable;

  /// 选项层类型
  final ZoMenusTriggerType selectMenuType;

  /// 列表顶部自定义内容
  final Widget? toolbar;

  /// 菜单尺寸
  final ZoSize? size;

  /// 按钮最小宽度
  ///
  /// 不传时使用当前尺寸对应的默认高度作为最小宽度
  final double? buttonMinWidth;

  /// 按钮最大宽度
  final double? buttonMaxWidth;

  /// 菜单宽度
  ///
  /// 默认为 `200`
  ///
  /// 传入 `null` 时由 [ZoMenusTrigger] 跟随触发目标宽度
  final double? menuWidth;

  /// 文本拼接时显示的最大选中项数量
  final int maxSelectedShowNumber;

  /// 是否显示下拉指示图标
  final bool showOpenIndicator;

  /// 是否启用
  final bool enabled;

  /// 触发目标获取焦点时是否自动打开菜单
  final bool openOnFocus;

  /// 外部传入的触发目标焦点
  final FocusNode? focusNode;

  /// 默认按钮构造
  ///
  /// 保持按钮语义，同时复用 [ZoMenusTriggerState] 的选中态与开关能力
  Widget builder(ZoMenusTriggerBuilderArgs args) {
    final selectedText = args.state.getSelectedText();
    final hasSelected = selectedText.isNotEmpty;
    final style = args.context.zoStyle;
    final currentSize = size ?? style.widgetSize;
    final minWidth = buttonMinWidth ?? style.getSizedExtent(currentSize);
    final maxWidth = buttonMaxWidth ?? double.infinity;
    final buttonHeight = style.getSizedExtent(currentSize);

    final mainChild = hasSelected
        ? Text(
            selectedText,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          )
        : child;

    return ZoButton(
      enabled: enabled,
      focusNode: args.focusNode,
      size: currentSize,
      constraints: BoxConstraints(
        minWidth: minWidth,
        maxWidth: maxWidth,
        minHeight: buttonHeight,
      ),
      onTap: args.state.toggle,
      builder: (widget, args) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(child: mainChild),
            if (showOpenIndicator)
              Transform.translate(
                offset: const Offset(2, 0),
                child: const Icon(Icons.unfold_more_rounded),
              ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ZoMenusTrigger(
      value: value,
      onChanged: onChanged,
      options: options,
      selectionType: selectionType,
      branchSelectable: branchSelectable,
      selectMenuType: selectMenuType,
      toolbar: toolbar,
      size: size,
      menuWidth: menuWidth,
      maxSelectedShowNumber: maxSelectedShowNumber,
      enabled: enabled,
      openOnFocus: openOnFocus,
      focusNode: focusNode,
      builder: builder,
    );
  }
}

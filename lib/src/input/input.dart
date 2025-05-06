import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:zo/src/form/form_state.dart";
import "package:zo/src/input/formatter.dart";
import "package:zo/zo.dart";

/// 输入控件
///
/// 数值输入: 根据泛型 T 的类型不同, 组件的输入类型会自动进行调整, 可选类型为 String - 字符串输入
///  double - 浮点数输入 int - 整形输入, 若未明确声明类型且无法推断出T的类型, 会将其视为String
///
/// ```dart
/// Row(
///   children: [
///     ZoInput<String>(),
///     ZoInput<double>(),
///     ZoInput<int>(),
///     ZoInput(value: "Hello"),  // 如果传入了初始化值则可以自己推断类型
///   ],
/// )
/// ```
class ZoInput<T> extends ZoCustomFormWidget<T> {
  const ZoInput({
    super.key,
    super.value,
    super.onChanged,
    this.max = 999999999999999,
    this.min = -999999999999999,
    this.clear = true,
    this.size = ZoSize.medium,
    this.onFocusChanged,
    this.onHoverChanged,
    this.obscureText = false,
    this.hintText,
    this.leading,
    this.trailing,
    this.padding,
    this.constraints,
    this.borderless = false,
    this.border,
    this.color,

    this.autofocus = false,
    this.canRequestFocus = true,
    this.contextMenuBuilder,
    this.controller,
    this.enabled = true,
    this.readOnly = false,
    this.expands = false,
    this.focusNode,
    this.inputFormatters,
    this.keyboardType,
    this.maxLength,
    this.maxLines = 1,
    this.minLines,
    this.onEditingComplete,
    this.onSubmitted,
    this.onTapOutside,
    this.restorationId,
    this.selectionControls,
    this.style,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.textInputAction,
  });

  /// 仅数值类型的输入有效, 它表示最大数值
  final double? max;

  /// 仅数值类型的输入有效, 它表示最小数值
  final double? min;

  /// 在包含已输入内容时, 显示清楚按钮
  final bool clear;

  /// 组件尺寸
  final ZoSize size;

  /// 编辑完成时调用
  final ValueChanged<T>? onSubmitted;

  /// 焦点状态变更
  final ValueChanged<bool>? onFocusChanged;

  /// 悬浮状态变更
  final ValueChanged<bool>? onHoverChanged;

  /// 隐藏输入内容
  final bool obscureText;

  /// 提示文本
  final Widget? hintText;

  /// 前导内容
  final Widget? leading;

  /// 后导内容
  final Widget? trailing;

  /// 内间距
  final EdgeInsetsGeometry? padding;

  /// 尺寸控制
  final BoxConstraints? constraints;

  /// 是否显示边框, 为了表示聚焦/hover等状态, 即使设置了 [borderless] 仍会在触发对应交互时
  /// 显示边框, 若要完全隐藏, 可传入 [border] 并设置一个透明边框
  final bool borderless;

  /// 边框配置
  final BoxBorder? border;

  /// 背景色, 传入后会强制覆盖组件内部由禁用和只读状态添加的颜色
  final Color? color;

  // # # # # # # # TextField 属性 (只包含部分常用的) # # # # # # #
  final bool autofocus;

  final bool canRequestFocus;

  final EditableTextContextMenuBuilder? contextMenuBuilder;

  final TextEditingController? controller;

  final bool enabled;

  final bool expands;

  final FocusNode? focusNode;

  final List<TextInputFormatter>? inputFormatters;

  final TextInputType? keyboardType;

  final int? maxLength;

  final int maxLines;

  final int? minLines;

  final VoidCallback? onEditingComplete;

  final TapRegionCallback? onTapOutside;

  final bool readOnly;

  final String? restorationId;

  final TextSelectionControls? selectionControls;

  final TextStyle? style;

  final TextAlign textAlign;

  final TextDirection? textDirection;

  final TextInputAction? textInputAction;

  @override
  State<ZoInput> createState() => _ZoInputState<T>();
}

class _ZoInputState<T> extends ZoCustomFormState<T, ZoInput<T>> {
  TextEditingController? innerController;
  TextEditingController get controller {
    if (widget.controller != null) return widget.controller!;

    innerController ??= TextEditingController();

    return innerController!;
  }

  late WidgetStatesController widgetStatesController;

  /// 是否是数值输入
  bool get isNumberInput {
    return T == double || T == int;
  }

  /// 是否是多行输入
  bool get isMultipleLine {
    return widget.maxLines > 1;
  }

  bool obscureTextEnable = true;

  bool focused = false;

  bool hovered = false;

  /// 格式化器
  List<TextInputFormatter> inputFormatters = [];

  @override
  void initState() {
    super.initState();

    var val = valueToString();

    if (val != null) {
      controller.text = val;
    }

    updateInputFormatters();

    widgetStatesController = WidgetStatesController();

    inputStateChangeHandle();
  }

  @override
  void didUpdateWidget(ZoInput<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.inputFormatters != widget.inputFormatters ||
        oldWidget.max != oldWidget.max ||
        oldWidget.min != oldWidget.min) {
      updateInputFormatters();
    }
  }

  @override
  void dispose() {
    super.dispose();
    if (innerController != null) {
      innerController!.dispose();
    }

    widgetStatesController.dispose();
  }

  /// widget.value 变更, 同步到 controller
  @override
  void onPropValueChanged() {
    var val = value == null ? "" : valueToString();

    if (val != controller.text) {
      if (val == null || val == "") {
        controller.text = "";
      } else {
        controller.value = controller.value.copyWith(text: val);
      }
    }
  }

  /// 根据widget配置更新 inputFormatters
  void updateInputFormatters() {
    inputFormatters = [...?widget.inputFormatters];

    if (isNumberInput) {
      inputFormatters.add(
        NumberTextInputFormatter(
          isInteger: T == int,
          max: widget.max,
          min: widget.min,
        ),
      );
    }
  }

  /// 获取当前value的String字符串, 如果当前输入类型是数值输入, 会自动转换为字符串
  String? valueToString() {
    if (value == null) return null;
    if (!isNumberInput) return value.toString();
    if (T == double) return displayNumber(value as double);
    if (T == int) return (value as int).toString();
    return null;
  }

  void onTextFieldChanged(String? val) {
    onChanged(val);
  }

  /// 监听 TextField 并同步到 value
  void onChanged(String? val, [bool skipIncompleteNum = false]) {
    if (val == null) {
      value = null;
      return;
    }

    // 数值输入, 需要将字符串转换为对应数值类型
    if (isNumberInput) {
      // 如果是尚未输入完成的数值字符串, 先不设置和通知, 在输入完成后需要再进行一次处理
      if (!skipIncompleteNum && isIncompleteNum(val)) return;

      var num = double.tryParse(val);

      if (num == null) {
        value = null;

        // 输入框存在值, 但是不是有效数字, 将输入框同时清空
        controller.text = "";
        return;
      }

      value = (T == int ? num.toInt() : num) as T;
      return;
    }

    // 字符串输入
    value = val as T;
  }

  /// 检测字符串是否是尚未输入完成的数字字符串, 包含以下检测
  /// - 是否只包含 `-`
  /// - 是否以dot结尾
  bool isIncompleteNum(String s) {
    return s.endsWith(".") || s == "-";
  }

  /// onSubmitted 处理
  void onTextFieldSubmitted(String val) {
    if (widget.onSubmitted == null || value == null) return;
    widget.onSubmitted!(value as T);
  }

  /// 焦点变更时进行特殊处理
  void onFocusChanged() {
    var text = controller.text;

    // 如果是数值输入, 由于 isIncompleteNum 可能会存在输入未完成且未调用onChanged的情况
    // 对这些情况进行处理
    if (!focused && isNumberInput && isIncompleteNum(text)) {
      if (text == "-") {
        controller.text = "";
      }
      if (text.endsWith(".")) {
        controller.text = text.substring(0, text.length - 1);
      }
      onChanged(controller.text, true);
    }
  }

  /// 状态变更处理
  void inputStateChangeHandle() {
    widgetStatesController.addListener(() {
      var f = widgetStatesController.value.contains(WidgetState.focused);
      var h = widgetStatesController.value.contains(WidgetState.hovered);

      var focusChanged = f != focused;
      var hoverChanged = h != hovered;

      if (hoverChanged || focusChanged) {
        setState(() {
          focused = f;
          hovered = h;
        });
      }

      if (focusChanged) {
        onFocusChanged();
        widget.onFocusChanged?.call(f);
      }

      if (hoverChanged) {
        widget.onHoverChanged?.call(h);
      }
    });
  }

  TextInputType? getKeyboardType() {
    if (widget.keyboardType != null) return widget.keyboardType;

    if (isNumberInput) {
      return TextInputType.numberWithOptions(
        signed: true,
        decimal: T == double,
      );
    }

    return null;
  }

  void onClear() {
    controller.clear();
    onChanged(controller.text);
  }

  void onObscureTextEnableChange() {
    setState(() {
      obscureTextEnable = !obscureTextEnable;
    });
  }

  bool get isEmpty {
    if (isNumberInput) return value == null;
    return value == null || value == "";
  }

  /// 构造输入框右侧内容
  List<Widget> buildTrailing() {
    List<Widget> list = [];

    if (widget.clear && widget.enabled && !widget.readOnly) {
      if (!isEmpty) {
        list.add(
          ZoButton(
            icon: Icon(Icons.clear),
            size: ZoSize.small,
            square: true,
            onPressed: onClear,
          ),
        );
      }
    }

    if (widget.obscureText) {
      list.add(
        ZoButton(
          icon: Icon(
            obscureTextEnable
                ? Icons.visibility_outlined
                : Icons.visibility_off_rounded,
          ),
          size: ZoSize.small,
          square: true,
          onPressed: onObscureTextEnableChange,
        ),
      );
    }

    if (widget.trailing != null) {
      list.add(widget.trailing!);
    }

    return list;
  }

  /// 构造输入框左侧内容
  List<Widget> buildLeading() {
    List<Widget> list = [];

    if (widget.leading != null) {
      list.add(widget.leading!);
    }

    return list;
  }

  Widget? buildHintNode() {
    if (widget.hintText == null || !isEmpty) return null;

    var style = context.zoStyle;

    return Positioned.fill(
      child: IgnorePointer(
        child: Align(
          alignment: isMultipleLine ? Alignment.topLeft : Alignment.centerLeft,
          child: DefaultTextStyle(
            style: TextStyle(color: style.hintTextColor),
            child: widget.hintText!,
          ),
        ),
      ),
    );
  }

  double getStandardSize() {
    var style = context.zoStyle;
    return switch (widget.size) {
      ZoSize.small => style.smallSize,
      ZoSize.medium => style.mediumSize,
      ZoSize.large => style.largeSize,
    };
  }

  /// 根据 leading / trailing 动态设置边距, 当显示图标按钮时使用更小的间距使视觉上更舒适
  EdgeInsetsGeometry getPadding(List<Widget> leading, List<Widget> trailing) {
    if (widget.padding != null) return widget.padding!;

    var style = context.zoStyle;

    double left = style.space2;
    double right = style.space2;
    double verticalSpace = isMultipleLine ? style.space2 : 0;

    if (leading.isNotEmpty) {
      var first = leading.first;
      if (first is ZoButton && first.icon != null && first.child == null) {
        left = style.space1;
      }
    }

    if (trailing.isNotEmpty) {
      var last = trailing.last;
      if (last is ZoButton && last.icon != null && last.child == null) {
        right = style.space1;
      }
    }

    return EdgeInsets.only(
      left: left,
      right: right,
      top: verticalSpace,
      bottom: verticalSpace,
    );
  }

  /// 获取当前边框
  BoxBorder? getBorder() {
    var style = context.zoStyle;

    if (widget.border != null) return widget.border;

    if (focused) return Border.all(color: style.primaryColor);

    if (hovered) return Border.all(color: style.outlineColorVariant);

    if (widget.borderless) return Border.all(color: Colors.transparent);

    return Border.all(color: style.outlineColor);
  }

  /// 获取当前背景色
  Color? getColor() {
    if (widget.color != null) return widget.color;

    var style = context.zoStyle;

    if (!widget.enabled || widget.readOnly) {
      return style.disabledColor;
    }

    // 亮色背景显示白底, 用来使其在 ZoTile filled 等内部更自然
    if (style.brightness == Brightness.light) {
      return style.surfaceContainerColor;
    }

    return null;
  }

  /// 添加分割线
  Widget withDivider(
    Widget child,
    List<Widget> leading,
    List<Widget> trailing,
  ) {
    var style = context.zoStyle;

    double left = leading.isEmpty ? 0 : style.space1;
    double right = trailing.isEmpty ? 0 : style.space1;

    return Container(
      margin: EdgeInsets.only(left: left, right: right),
      padding: EdgeInsets.only(left: left, right: right),
      decoration: BoxDecoration(
        border: Border(
          left:
              (left == 0 || widget.borderless)
                  ? BorderSide.none
                  : BorderSide(color: style.outlineColor),
          right:
              (right == 0 || widget.borderless)
                  ? BorderSide.none
                  : BorderSide(color: style.outlineColor),
        ),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    var hintNode = buildHintNode();
    var style = context.zoStyle;
    var textTheme = context.zoTextTheme;

    var leading = buildLeading();
    var trailing = buildTrailing();

    var mainContent = Stack(
      children: [
        if (hintNode != null) hintNode,
        TextField(
          // 完全禁用预置样式
          decoration: null,
          onChanged: onTextFieldChanged,
          controller: controller,
          autofocus: widget.autofocus,
          canRequestFocus: widget.canRequestFocus,
          contextMenuBuilder: widget.contextMenuBuilder,
          enabled: widget.enabled,
          expands: widget.expands,
          focusNode: widget.focusNode,
          inputFormatters: inputFormatters,
          keyboardType: getKeyboardType(),
          maxLength: widget.maxLength,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          onEditingComplete: widget.onEditingComplete,
          onSubmitted: onTextFieldSubmitted,
          onTapOutside: widget.onTapOutside,
          readOnly: widget.readOnly,
          restorationId: widget.restorationId,
          selectionControls: widget.selectionControls,
          // style: widget.style,
          style: TextStyle(fontSize: textTheme.bodyMedium!.fontSize),
          textAlign: widget.textAlign,
          textDirection: widget.textDirection,
          textInputAction: widget.textInputAction,
          obscureText: obscureTextEnable ? widget.obscureText : false,
          statesController: widgetStatesController,
        ),
      ],
    );

    return IconTheme(
      data: IconThemeData(color: style.hintTextColor),
      child: Container(
        constraints:
            widget.constraints ??
            BoxConstraints(
              minHeight: getStandardSize(),
              maxWidth: style.breakPointSM,
            ),
        padding: getPadding(leading, trailing),
        decoration: BoxDecoration(
          border: getBorder(),
          borderRadius: BorderRadius.circular(style.borderRadius),
          color: getColor(),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment:
              isMultipleLine
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
          children: [
            ...leading,
            Expanded(child: withDivider(mainContent, leading, trailing)),
            ...trailing,
          ],
        ),
      ),
    );
  }
}

import "package:flutter/material.dart";

/// 表单值变更时通过此回调通知
typedef ZoFormOnChanged<T> = void Function(T? newValue);

/// 定义了表单控件通用的 [value] / [onChanged] 接口, 是当前库所有表单控件的基础
abstract class ZoFormWidget<T> extends StatefulWidget {
  const ZoFormWidget({
    super.key,
    this.value,
    this.onChanged,
  });

  /// 控件的当前值
  ///
  /// - 如果传入一个固定的值, 它的行为类似于默认值, 组件将使用该值作为初始化值, 需要避免传入
  /// 非 const 字面量, 否则会导致递归更新
  /// - 不传入 [value], 状态将完全在组件内部管理
  /// - 传入一个会变更的状态值, 组件会和该状态建立连接, [value] 变更时会同步到组件内部, 组件内部
  /// 值发生变更时会通过 [onChanged] 通知, 可在此时选择同步到外部状态
  ///
  /// [value] 的不可变性：
  /// value 应始终是不可变的, 每次变更都应提供一个新对象而不是修改原有对象,
  /// 组件内部通过 == 运算符判断 [value] 是否变更, 需要避免在 builder 中直接构造 [value],
  /// 除非该对象已正确重写了 == 运算符
  ///
  /// 表单值允许为 null，应将其与类型零值对应，比如字符串为 ""、 bool 值为 false、
  /// 数值为 0
  final T? value;

  /// 表单值变更时通过此回调通知
  final ZoFormOnChanged<T>? onChanged;
}

/// 提供了基于 [ZoFormWidget] 和 [ZoFormBinder] 的常用自定义表单逻辑实现，
/// 如果控件有多个 value / onChanged 属性，可考虑使用 [ZoFormBinder]
abstract class ZoFormState<T, W extends ZoFormWidget<T>> extends State<W> {
  /// 表单值绑定器
  late final ZoFormBinder<T> formBinder;

  /// 回退值, 在一些场景中，可能会需要将 null 视为指定值，比如布尔控件中 null 可能对应 false,
  /// 字符串输入时可能对应 "", 数值输入中可能对应 0
  ///
  /// 回退的值只会作为控件显示使用，通常不会实际进行回传
  ///
  /// 传入后可使用 [nonNullValue] 访问非空值
  @protected
  T? get fallbackValue => null;

  /// 非空值，设置 [fallbackValue] 后可用
  T get nonNullValue => formBinder.nonNullValue;

  @protected
  /// 获取控件的值
  T? get value => formBinder.value;

  /// 设置控件的值
  set value(T? n) {
    formBinder.value = n;
  }

  @override
  @mustCallSuper
  void initState() {
    super.initState();

    formBinder = ZoFormBinder(
      value: widget.value,
      onChanged: onChanged,
      onPropValueChanged: onPropValueChanged,
      fallbackValue: fallbackValue,
    );
  }

  @override
  @mustCallSuper
  void didUpdateWidget(covariant W oldWidget) {
    super.didUpdateWidget(oldWidget);

    formBinder.updateProps(widget.value, oldWidget.value, widget.onChanged);
  }

  /// 当 widget.value 变更时, 会调用此方法, 此时可通过 value 获取当前值
  /// 如果内部控件使用类似 TextEditingController 的 api 管理值, 可以在此处同步，
  /// 由于在 didUpdateWidget 内触发，此方法中不能也无需调用 setState
  void onPropValueChanged() {}

  /// 表单值在在内部被变更时通过此回调通知, 按照约定，覆盖此方法时 super.onChanged(newValue)
  /// 应写在方法下方，确保所有实现都以相同的循序进行通知和更新组件
  ///
  /// 在结束时会自动触发 setState 更新, 不需要再次调用
  @mustCallSuper
  void onChanged(T? newValue) {
    widget.onChanged?.call(newValue);
    setState(() {});
  }
}

/// 定义了表单控件通用的 [value] / [onChanged] 接口, 详情的说明请参考 [ZoFormWidget]
///
/// 大部分场景使用 [ZoFormWidget] / [ZoFormState] 即可，此类用于其内部实现，
/// 但在一些包含多个表单属性的组件也很有用
class ZoFormBinder<T> {
  ZoFormBinder({
    T? value,
    this.onChanged,
    this.onPropValueChanged,
    this.fallbackValue,
  }) {
    innerValue = value;
    initialValue = value;
  }

  ZoFormOnChanged<T>? onChanged;

  VoidCallback? onPropValueChanged;

  late final T? fallbackValue;

  /// 初始化时传入的值，可用于表单重置
  late final T? initialValue;

  T get nonNullValue {
    if (fallbackValue == null) throw UnimplementedError();
    return value ?? fallbackValue!;
  }

  /// 内部值, 通过 value 的 getter/setter 来读写, 如果需要跳过 widget.onChanged 调用,
  /// 可直接更改此属性的值
  T? get value => innerValue;
  T? innerValue;
  set value(T? n) {
    // 按需进行相等检测
    final oldValue = value ?? fallbackValue;

    if (oldValue == n) return;

    innerValue = n;

    onChanged?.call(n);
  }

  /// 实时同步 value 、 onChanged，可在 didUpdateWidget 中直接调用，无变更时内部会自动跳过
  void updateProps(T? newValue, T? oldValue, ZoFormOnChanged<T>? onChanged) {
    onChanged = onChanged;

    // 外部值变更后才进行同步
    if (newValue == oldValue) return;

    if (innerValue != newValue) {
      // 值从外部变更时，不需要通知或更新组件
      innerValue = newValue;
      onPropValueChanged?.call();
    }
  }
}

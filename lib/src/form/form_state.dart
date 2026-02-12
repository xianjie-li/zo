import "package:flutter/material.dart";

typedef ZoFormOnChanged<T> = void Function(T? newValue);

/// 定义了表单控件通用的 value / onChanged(newValue) 接口
///
///
abstract class ZoCustomFormWidget<T> extends StatefulWidget {
  const ZoCustomFormWidget({super.key, this.value, this.onChanged});

  /// 控件的当前值
  ///
  /// - 如果传入一个不变的值, 它的行为类似于默认值, 组件将使用该值作为初始化值
  /// - 不传入value, 状态将完全在组件内部管理
  /// - 传入一个会变更的状态值, 组件会和该状态建立连接, value变更时会同步到组件内部, 组件内部
  /// 值发生变更时会通过 [onChanged] 通知
  ///
  /// 组件内部通过 == 运算符判断value是否变更, 需要避免在builder中直接构造value,
  /// 除非该对象已正确重写了 == 运算符
  ///
  /// 表单值允许为 null，应将其与类型零值对应，比如字符串为 ""、 bool 值为 false、
  /// 数值为 0
  final T? value;

  /// 表单值变更时通过此回调通知
  final ZoFormOnChanged<T>? onChanged;
}

/// 提供了基于 [ZoCustomFormWidget] 和 [ZoCustomFormBinder] 的常用自定义表单逻辑实现，
/// 如果控件有多个 value / onChanged 属性，可考虑使用 [ZoCustomFormBinder]
abstract class ZoCustomFormState<T, W extends ZoCustomFormWidget<T>>
    extends State<W> {
  /// 表单值管理
  late final ZoCustomFormBinder<T> formBinder;

  /// 内部设置 value 时，进行简单的相等性检测，并在相等时跳过，如果表单的值是只改变内部值的复合结构，
  /// 可以设置为 true 来跳过对比
  ///
  /// 对于参数传入的 props.value 会始终在相等时跳过更新，所以组件外部更新内部值的方式始终是传入新的值对象
  @protected
  bool get skipValueEqualCheck => false;

  /// 未传入初始值时，将该值作为默认值传入给 [ZoCustomFormBinder.initialValue]
  @protected
  T? get defaultValue => null;

  /// 值为 null 时，改值可作为回退值，详情见 [ZoCustomFormBinder.fallbackValue],
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

    formBinder = ZoCustomFormBinder(
      value: widget.value ?? defaultValue,
      onChanged: onChanged,
      onPropValueChanged: onPropValueChanged,
      skipValueEqualCheck: skipValueEqualCheck,
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
  /// 如果内部控件使用类似 TextEditingController 的api管理值, 可以在此处同步，
  /// 由于在 didUpdateWidget 内触发，要避免在其中更新组件 state
  void onPropValueChanged() {}

  /// 表单值在在内部被变更时通过此回调通知, 按照约定，覆盖此方法时 super.onChanged(newValue)
  /// 应写在方法下方，确保所有实现都以相同的循序进行通知和更新组件
  @mustCallSuper
  void onChanged(T? newValue) {
    widget.onChanged?.call(newValue);
    setState(() {});
  }
}

/// 定义了表单控件通用的 value / onChanged(newValue) 接口的基本实现,
/// 大部分场景使用 [ZoCustomFormState] 即可，此类用于其内部实现，但在一些有多个表单属性的组件也很有用
class ZoCustomFormBinder<T> {
  ZoCustomFormBinder({
    T? value,
    this.onChanged,
    this.onPropValueChanged,
    this.skipValueEqualCheck = false,
    this.fallbackValue,
  }) {
    innerValue = value;
    initialValue = value;
  }

  /// 表单值在内部变更，详情见 [ZoCustomFormState.onChanged]
  ZoFormOnChanged<T>? onChanged;

  /// 参数值变更时调用, 详情见 [ZoCustomFormState.onPropValueChanged]
  VoidCallback? onPropValueChanged;

  /// 是否跳过内部变更的相等检测, 详情见 [ZoCustomFormState.skipValueEqualCheck]
  bool skipValueEqualCheck;

  /// 在一些场景中，可能会需要将 null 视为指定值，比如布尔控件中 null 可能对应 false,
  /// 字符串输入时可能对应 "", 数值输入中可能对应 0
  ///
  /// 通常回退的值只会作为控件显示使用，不会实际进行回传
  late final T? fallbackValue;

  /// 初始化时传入的值，可能会用于表单重置
  late final T? initialValue;

  /// 控件的当前值, 详情见 [ZoCustomFormWidget.value]
  T? get value => innerValue;

  /// 控件的非空值，在设置 [fallbackValue] 后生效
  T get nonNullValue {
    if (fallbackValue == null) throw UnimplementedError();
    return value ?? fallbackValue!;
  }

  /// 内部值, 通过 value 的 getter/setter 来读写, 如果需要跳过 widget.onChanged 调用,
  /// 可直接更改此属性的值
  T? innerValue;

  set value(T? n) {
    // 按需进行相等检测
    if (!skipValueEqualCheck) {
      final oldValue = value ?? fallbackValue;

      if (oldValue == n) return;
    }

    innerValue = n;

    onChanged?.call(n);
  }

  /// 实时同步 value 、 onChanged，可在 didUpdateWidget 中直接调用，无变更时内部会自动跳过
  void updateProps(T? newValue, T? oldValue, ZoFormOnChanged<T>? onChanged) {
    // 外部值变更后才进行同步
    if (newValue == oldValue) return;

    if (innerValue != newValue) {
      // 值从外部变更时，不需要通知或更新组件
      innerValue = newValue;
      onPropValueChanged?.call();
    }

    onChanged = onChanged;
  }
}

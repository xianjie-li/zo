import "package:flutter/material.dart";

typedef ZoFormOnChanged<T> = void Function(T? newValue);

/// 定义了表单控件通用的 value / onChanged(newValue) 接口
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

  T? get value => formBinder.value;
  set value(T? n) {
    formBinder.value = n;
  }

  @override
  @mustCallSuper
  void initState() {
    super.initState();

    formBinder = ZoCustomFormBinder(
      value: widget.value,
      onChanged: widget.onChanged,
      onInnerChanged: onChange,
      onPropValueChanged: onPropValueChanged,
    );
  }

  @override
  @mustCallSuper
  void didUpdateWidget(covariant W oldWidget) {
    super.didUpdateWidget(oldWidget);

    formBinder.updateProps(widget.value, widget.onChanged);
  }

  /// 当 widget.value 变更时, 会调用此方法, 此时可通过 value 获取当前值
  /// 如果内部控件使用类似 TextEditingController 的api管理值, 可以在此处同步
  void onPropValueChanged() {}

  /// 值在内部通过设置 value 变更后会通过此方法通知
  void onChange(T? newValue) {}
}

/// 定义了表单控件通用的 value / onChanged(newValue) 接口的基本实现,
/// 大部分场景使用 [ZoCustomFormState] 即可，此类用于其内部实现，但在一些有多个表单属性的组件也很有用
class ZoCustomFormBinder<T> {
  ZoCustomFormBinder({
    T? value,
    this.onChanged,
    this.onInnerChanged,
    this.onPropValueChanged,
  }) {
    innerValue = value;
  }

  /// 控件的当前值, 详情见 [ZoCustomFormWidget.value]
  T? get value => innerValue;

  /// 内部值, 通过 value 的 getter/setter 来读写, 如果需要跳过 widget.onChanged 调用,
  /// 可直接更改此属性的值
  T? innerValue;

  set value(T? n) {
    if (innerValue == n) return;

    innerValue = n;

    onInnerChanged?.call(n);
    onChanged?.call(n);
  }

  /// 表单值在在内部被变更时通过此回调通知, 该参数用于直接绑定到 props.onChanged
  ZoFormOnChanged<T>? onChanged;

  /// 与 [onChanged] 完全一样，但是用于 [ZoCustomFormBinder] 所在类内部使用
  ZoFormOnChanged<T>? onInnerChanged;

  /// 当传入的 value 变更时, 会调用此方法，如果内部控件使用类似 TextEditingController 的 api 管理值,
  /// 可以在此处同步
  VoidCallback? onPropValueChanged;

  /// 实时同步 value 、 onChanged，通常在 didUpdateWidget 中调用，无变更时内部会自动跳过
  void updateProps(T? value, ZoFormOnChanged<T>? onChanged) {
    if (innerValue != value) {
      // 值从外部变更时，不需要通知或更新组件
      innerValue = value;
      onPropValueChanged?.call();
    }

    onChanged = onChanged;
  }
}

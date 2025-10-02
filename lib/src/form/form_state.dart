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

/// 提供了基于 ZoCustomFormWidget 的常用自定义表单逻辑实现
abstract class ZoCustomFormState<T, W extends ZoCustomFormWidget<T>>
    extends State<W> {
  T? get value => _value;
  set value(T? n) {
    if (_value == n) return;

    _value = n;

    onChange(n);

    setState(() {});
  }

  /// 内部值, 通过 value 的 getter/setter 来读写, 如果需要跳过 widget.onChanged 调用,
  /// 可直接更改此属性的值
  T? _value;

  @override
  void initState() {
    super.initState();

    _value = widget.value;
  }

  @override
  void didUpdateWidget(covariant W oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.value != oldWidget.value) {
      _value = widget.value;
      onPropValueChanged();
    }
  }

  /// 当 widget.value 变更时, 会调用此方法, 此时可通过 value 获取当前值
  /// 如果内部控件使用类似 TextEditingController 的api管理值, 可以在此处同步
  void onPropValueChanged() {}

  /// 内部值变更后会通过此方法通知
  void onChange(T? newValue) {
    if (widget.onChanged != null) {
      widget.onChanged!(newValue);
    }
  }
}

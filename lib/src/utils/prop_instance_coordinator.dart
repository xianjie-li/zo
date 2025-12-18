/// 处理组件会内部创建实例或使用传入实例的特定场景，例如 controller 支持，
/// 如果传入了实例，则使用传入实例，否则内部创建实例，并在更新和销毁时根据实例的创建方式进行对应处理
///
/// 构造时，如果未传入 instance 会创建新的实例，在组件更新和销毁时需要分别调用 [updateInstance]
/// 和 [dispose] 来通知内部更新实例, 然后安全的使用 [instance] 访问实例
///
/// 固定实例：某些组件更新实例的成本可能较高，可以选择完全不调用 [updateInstance] 来跳过更新，
/// 始终使用初始化时确认的实例
class ZoPropInstanceCoordinator<T> {
  ZoPropInstanceCoordinator({
    T? instance,
    required this.create,
    required this.active,
    required this.inactive,
    required this.destroy,
  }) {
    if (instance == null) {
      this.instance = create(true);
      _internalInstance = this.instance;
    } else {
      this.instance = instance;
    }

    active(this.instance);
  }

  /// 活动实例，可能是传入的，也可能是内部创建的
  late T instance;

  /// 内部创建的实例
  T? _internalInstance;

  /// 创建实例
  final T Function(bool isInit) create;

  /// 活动实例变化时调用，可在此绑定事件，处理针对实例的初始化操作等
  final void Function(T ins) active;

  /// 实例不再获取，在此处清理实例上的事件，还原状态等
  final void Function(T ins) inactive;

  /// 销毁指定实例
  final void Function(T ins) destroy;

  /// 如果活跃实例是由内部创建的，返回 true
  bool get isInternal {
    return _internalInstance == instance;
  }

  /// 参数实例可能更新时调用此方法
  void updateInstance(T newPara, [T? oldPara]) {
    if (newPara != oldPara) {
      inactive(instance);

      if (newPara != null) {
        // 若传入了新的实例，将其设为活动实例
        instance = newPara;
      } else {
        // 未传入实例，创建或使用已有内部实例

        if (_internalInstance == null) {
          instance = create(false);
          _internalInstance = instance;
        } else {
          instance = _internalInstance as T;
        }
      }

      active(instance);
    }
  }

  /// 组件卸载时需调用此方法
  void dispose() {
    inactive(instance);

    if (_internalInstance != null) {
      if (_internalInstance != instance) {
        inactive(instance);
      }

      destroy(_internalInstance as T);
    }
  }
}

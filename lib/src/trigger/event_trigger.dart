typedef EventTriggerListener<T> = void Function(T);
typedef EventTriggerVoidListener = void Function();

/// 用于简单快速的实现订阅机制, 不同于 Listenable, 它更倾向于通过参数进行
/// 通知而不是实例本身, 在某些场景会更方便
///
/// 每个 listener 只能注册一次, 多次注册会覆盖掉之前的
class EventTrigger<Arg> {
  final _listeners = <EventTriggerListener<Arg>>{};

  int get length {
    return _listeners.length;
  }

  void on(EventTriggerListener<Arg> listener) {
    _listeners.add(listener);
  }

  void emit(Arg arg) {
    for (var listener in _listeners) {
      listener(arg);
    }
  }

  void off(EventTriggerListener<Arg> listener) {
    _listeners.remove(listener);
  }

  void clear() {
    _listeners.clear();
  }
}

/// 与 [EventTrigger] 一样, 但是参数为 void
class VoidEventTrigger {
  final _listeners = <EventTriggerVoidListener>{};

  int get length {
    return _listeners.length;
  }

  void on(EventTriggerVoidListener listener) {
    _listeners.add(listener);
  }

  void emit() {
    for (var listener in _listeners) {
      listener();
    }
  }

  void off(EventTriggerVoidListener listener) {
    _listeners.remove(listener);
  }

  void clear() {
    _listeners.clear();
  }
}

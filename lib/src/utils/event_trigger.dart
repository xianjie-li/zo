typedef EventListener<T> = void Function(T);
typedef VoidEventListener = void Function();

/// 一个简单的事件实现, 用于简单快速的实现订阅机制
///
/// 每个 listener 只能注册一次, 多次注册会覆盖掉之前的
class EventTrigger<Arg> {
  final _listeners = <EventListener<Arg>>{};

  int get length {
    return _listeners.length;
  }

  void on(EventListener<Arg> listener) {
    _listeners.add(listener);
  }

  void emit(Arg arg) {
    for (var listener in _listeners) {
      listener(arg);
    }
  }

  void off(EventListener<Arg> listener) {
    _listeners.remove(listener);
  }

  void clear() {
    _listeners.clear();
  }
}

/// 与 [EventListener] 一样, 但是参数为 void
class VoidEventTrigger {
  final _listeners = <VoidEventListener>{};

  int get length {
    return _listeners.length;
  }

  void on(VoidEventListener listener) {
    _listeners.add(listener);
  }

  void emit() {
    for (var listener in _listeners) {
      listener();
    }
  }

  void off(VoidEventListener listener) {
    _listeners.remove(listener);
  }

  void clear() {
    _listeners.clear();
  }
}

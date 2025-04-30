typedef ZoEventListener<T> = void Function(T);
typedef ZoVoidEventListener = void Function();

/// 一个简单的事件实现, 用于简单快速的实现订阅机制
///
/// 每个 listener 只能注册一次, 多次注册会覆盖掉之前的
class ZoEventTrigger<Arg> {
  final _listeners = <ZoEventListener<Arg>>{};

  int get length {
    return _listeners.length;
  }

  void on(ZoEventListener<Arg> listener) {
    _listeners.add(listener);
  }

  void emit(Arg arg) {
    for (var listener in _listeners) {
      listener(arg);
    }
  }

  void off(ZoEventListener<Arg> listener) {
    _listeners.remove(listener);
  }

  void clear() {
    _listeners.clear();
  }
}

/// 与 [ZoEventTrigger] 一样, 但是参数为 void
class ZoVoidEventTrigger {
  final _listeners = <ZoVoidEventListener>{};

  int get length {
    return _listeners.length;
  }

  void on(ZoVoidEventListener listener) {
    _listeners.add(listener);
  }

  void emit() {
    for (var listener in _listeners) {
      listener();
    }
  }

  void off(ZoVoidEventListener listener) {
    _listeners.remove(listener);
  }

  void clear() {
    _listeners.clear();
  }
}

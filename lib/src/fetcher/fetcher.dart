import "dart:async";
import "dart:collection";

import "package:flutter/widgets.dart";
import "package:zo/src/utils/app_state.dart";
import "package:zo/src/utils/utils.dart";

/// 包含参数响应的异步future获取函数
typedef FetcherFn<Data, Payload> = Future<Data> Function(Payload);

/// 无参数的异步future获取函数
typedef FetcherVoidFn<Data> = Future<Data> Function();

var _cache = _CacheBucket();

/// 一个强大的异步数据获取工具, 它包含诸多简化请求的有用功能
///
/// - 请求状态管理: 简化请求相关状态的声明和管理
/// - 收缩请求: 如果相同的请求在多个不同的地方发起, 它们只会执行一次请求, 并共用同一个结果
/// - 缓存和 stale fresh: 请求数据缓存和陈旧数据自动刷新
/// - 缓存同步: 执行请求后, 将最新的结果同步到其他已创建的实例
/// - 请求覆盖: 连续发起请求时, 永远使用最后发起请求的结果并忽略前面的请求, 防止结束时间不一致
/// 导致的异常
/// - 延迟加载: fetcher 实例会在第一次访问其状态(data/payload/error/loading)时才真正开始进行初始化工作, 这意味着你可以将其
/// 作为全局数据加载器, 这些加载器在组件整个生命周期存在, 并在不同组件间复用
///   - 全局使用时, 建议通过 cacheTime = Duration.zero 关闭缓存功能, 因为全局数据与缓存的作用是重叠的
///   - 仅读取操作会触发初始化, 所以在初始化前, 仍可对状态进行手动更改
/// - 更多用例: 分页查询, 执行操作型请求(比如发起一个POST请求)
class Fetcher<Data, Payload> extends ChangeNotifier {
  Fetcher({
    this.fetchFn,
    this.fetchVoidFn,
    Data? data,
    Payload? payload,
    this.payloadHash,
    this.dataBuild,
    this.initialFetch = true,
    this.staleTime = const Duration(minutes: 3),
    this.cacheTime = const Duration(minutes: 30),
    this.cachePayload = false,
    this.action = false,
    this.refetchInterval = Duration.zero,
    this.retry = 0,
    this.onSuccess,
    this.onError,
    this.onComplete,
  }) {
    assert(fetchFn != null || fetchVoidFn != null);

    this._data = data;
    this._payload = payload;
  }

  /// 是否已执行初始化操作
  var _instantiated = false;

  /// 实现 refetchInterval
  Timer? _refetchTimer;

  late int _hashKey;

  /// 根据当前 fetchFn + fetchVoidFn + payload 生成的 hash key, 用于作为识别请求唯一性的标识
  int get hashKey => _hashKey;

  /// 标记对象已被销毁, 需要阻止后续进行的通知等
  bool disposed = false;

  /// 将正在进行的异步任务设置到此处用于其他地方进行接收监听
  late Future<void> _future;

  /// 用于获取数据 future 的函数
  FetcherFn<Data, Payload>? fetchFn;

  /// 用于获取数据 future 的函数, 这是 fetchFn 的无参数版本, 两者必传其一
  final FetcherVoidFn<Data>? fetchVoidFn;

  Data? _data;

  /// 异步数据, 可手动设置来更新此值
  Data? get data {
    _ensureInit();
    return _data;
  }

  set data(Data? d) {
    _data = d;
    notifyListeners();
  }

  Object? _error;

  /// 异步获取失败时存储失败信息, 可手动设置来更新此值
  Object? get error {
    _ensureInit();
    return _error;
  }

  set error(Object? e) {
    _error = e;
    notifyListeners();
  }

  bool _loading = false;

  /// 是否正在获取数据, 可手动设置来更新加载状态
  bool get loading {
    _ensureInit();
    return _loading;
  }

  set loading(bool l) {
    if (l == _loading) return;
    _loading = l;
    notifyListeners();
  }

  Payload? _payload;

  /// 传递给 [fetchFn] 的参数, 手动设置值时, 会以新值发起请求
  ///
  /// 如果包含自定义类型, 并且这些类型未自行实现hashCode, 可能需要通过 [payloadHash] 自定
  /// 义hash, 在绝大多数情况下都不需要考虑此问题, 比在你如不需要请求复用和缓存功能, 或者
  /// payload 是由基础类型组成的复合类型时
  Payload? get payload {
    _ensureInit();
    return _payload;
  }

  set payload(Payload? p) {
    // 不做相等阻断, 允许用户传入可变的payload
    _payload = p;

    // 未初始化之前, 不执行后续操作
    if (!_instantiated) return;

    _updateHash();

    _runTask();
  }

  /// 初始化时是否自动发起请求
  final bool initialFetch;

  /// 最后一次更新 data / error 的时间
  DateTime? fetchAt;

  /// 定义如何从payload获取hash, 使用场景件 [payload] 文档, 此函数不可在实例创建后再变更,
  /// 否则会导致未定义的行为
  List Function(Payload)? payloadHash;

  /// 在获取到数据, 写入到data和缓存前, 会调用此函数, 可以在此处对其进行转换后返回, 可用于实现
  /// 上拉加载等场景
  Data? Function(Data? newData, Fetcher<Data, Payload> fh)? dataBuild;

  /// 在初始化时, 如果命中了缓存, 会额外根据 staleTime 进行判断, 如果缓存数据的时间超过
  /// 此时间, 会先使用缓存数据占位, 然后发起更新请求
  final Duration staleTime;

  /// 缓存时间, 初始化阶段如果存在缓存, 会直接取缓存结果, 此选项会作为缓存功能的整体开关, 当
  /// 设置为 [Duration.zero] 时, 缓存相关的功能均会被禁用
  final Duration cacheTime;

  /// 如果启用, 会将 payload 也进行缓存, 缓存以当前 fetchFn 为key
  final bool cachePayload;

  /// 表示当前fetch是一个action操作, 不会读写缓存, 也不会在初始化时自动fetch, 即使设置了 [initialFetch]
  ///
  /// 通常来说, 设置了action时, 应该只通过 [fetch] 方法来执行请求, 而不是通过设置 [payload]
  /// 等方式
  final bool action;

  /// 设置后, 会以指定间隔自动发起更新请求
  ///
  /// 计时从第一次触发请求后开始, 如果计时期间通过任意方式触发了请求, 则会在请求完毕后重新开始
  /// 计时
  final Duration refetchInterval;

  /// 获取数据失败时, 自动重新获取的次数
  final double retry;

  /// 如果正在进行 retry, 此项存储对应的次数
  int retryCount = 0;

  /// 获取成功时调用
  ValueChanged<Fetcher<Data, Payload>>? onSuccess;

  /// 获取失败时调用
  ValueChanged<Fetcher<Data, Payload>>? onError;

  /// 请求完成时调用, 无论成功失败
  ValueChanged<Fetcher<Data, Payload>>? onComplete;

  /// 如果当前存在异步任务, 等待其完成
  Future<void> wait() async {
    var curFuture = _future;

    await curFuture;

    // 防止任务内发起了新任务
    if (curFuture != _future) {
      await wait();
    }
  }

  /// 主动发起请求, 如果省略参数则视为更新
  Future<Data> fetch([Payload? payload]) async {
    _ensureInit();

    if (payload != null) {
      this.payload = payload;
    } else {
      _runTask();
    }

    await wait();

    if (error != null) throw error!;
    return data!;
  }

  /// 主动触发陈旧数据更新, 如果当前数据仍在 [staleTime] 设置的有效期内或实例尚未初始化,
  /// 则什么都不会发生, 非全局创建的 fetcher 通常无需调用此方法
  ///
  /// 一个理想的使用时机是在组件的 initState 中调用, 可确保组件不会拿到太旧的数据, 即使未启用
  /// 缓存此方法也能生效
  ///
  /// <br>
  ///
  /// 为什么不全局 fetcher 不默认启用 stale fresh?
  ///
  /// stale fresh 最理想的执行时机是组件初始化时, 而全局 fetcher 是无法感知到这个时机的,
  /// 尽管可以单纯的实现为在每次访问状态时检测数据是否 stale, 但是这可能造成用户正在交互时触发数据更新,
  /// 体验反而会更差
  void staleRefresh() {
    // 未加载数据, 未启用时直接跳过
    if (_instantiated =
        false || fetchAt == null || staleTime == Duration.zero || action) {
      return;
    }

    // 未进行过任何请求
    if (data == null && error == null) return;

    if (DateTime.now().difference(fetchAt!) > staleTime) {
      fetch();
    }
  }

  @override
  void dispose() {
    _cache.cacheSyncEvent.off(_cacheSync);

    _clearTimers();

    disposed = true;
    super.dispose();
  }

  /// 初始化, 若已经执行过则忽略, 用于延迟初始化实例
  void _ensureInit() {
    if (_instantiated) return;
    _instantiated = true;

    _future = Future.value();

    var needInitialLoad = initialFetch;

    _updateHash();

    // 尝试获取已有缓存
    if (!action && cacheTime > Duration.zero) {
      var cachePayload = _cache.get(fetchFn ?? fetchVoidFn!, true);

      // 获取 data, null也可能是有效缓存
      if (cachePayload != null &&
          (cachePayload.data is Payload || cachePayload.data == null)) {
        this._payload = cachePayload.data as Payload?;
        _updateHash();
      }

      var cacheData = _cache.get(_hashKey);

      // 获取 payload, null也可能是有效缓存
      if (cacheData != null &&
          (cacheData.data is Data || cacheData.data == null)) {
        this._data = cacheData.data as Data?;
        this.fetchAt = cacheData.time;

        // 有缓存是默认不用再查询
        needInitialLoad = false;

        // 处理 staleTime
        if (this.staleTime > Duration.zero) {
          var diff = DateTime.now().difference(cacheData.time);

          if (diff > this.staleTime) {
            needInitialLoad = true;
          }
        }
      }
    }

    if (action) {
      needInitialLoad = false;
    }

    if (needInitialLoad) {
      _loading = true;

      _runTask();
    }

    _cache.cacheSyncEvent.on(_cacheSync);
  }

  /// 以当前参数和配置发起请求
  void _runTask([int? retryCount]) async {
    _ensureInit();

    _clearTimers();

    var isError = false;

    var completer = Completer<void>();
    _future = completer.future;

    if (_loading != true) {
      _loading = true;
      notifyListeners();
    }

    // 如果存在进行中的相同请求, 复用该请求
    Future<Data>? cacheTask;

    if (retryCount != null) {
      this.retryCount = retryCount + 1;
    }

    if (!action) {
      var task = _cache.getTask(_hashKey);
      if (task is Future<Data>) {
        cacheTask = task;
      }
    }

    var curTask = (cacheTask ?? _fetchFnCall());

    var isCacheTask = cacheTask != null;

    if (!isCacheTask) {
      _cache.setTask(_hashKey, curTask);
    }

    try {
      Data? res = await curTask;

      if (dataBuild != null) {
        res = dataBuild!(res, this);
      }

      // action或非原始请求都不写入缓存
      // 不用执行 completer.future == future 对比, 因为即使请求已被覆盖, 前面请求的内容
      // 仍然值得缓存
      if (cacheTime > Duration.zero && !action && !isCacheTask) {
        _cache.set(_hashKey, res, cacheTime);
        _cache.cacheSyncEvent.emit((
          data: res,
          fetcher: this,
          hashKey: _hashKey,
          // ignore: require_trailing_commas  Formatter has conflict
        ));

        /// 缓存 payload, 另一个理想的时机是在 payload 的 setter 中, 但在请求完成后缓存能
        /// 使 payload 与 data 成对
        if (cachePayload) {
          _cache.set(fetchFn ?? fetchVoidFn!, payload, cacheTime, true);
        }
      }

      // 如果当前请求后发起了其他请求, 忽略当前结果
      if (completer.future == _future) {
        _data = res;
        _error = null;
        _loading = false;

        this.retryCount = 0;

        if (!disposed) {
          onSuccess?.call(this);
        }
      }
    } catch (err) {
      isError = true;

      if (completer.future == _future) {
        _error = err;
        _loading = false;

        if (!disposed) {
          onError?.call(this);
        }
      }
    } finally {
      if (completer.future == _future) {
        fetchAt = DateTime.now();

        // 重置future
        _future = Future.value();

        if (!disposed) {
          onComplete?.call(this);
          notifyListeners();
        }

        var isRetry = false;

        /// 由于在 completer.future == future 内执行, retry可以随时被新发起的请求中断
        /// 这是符合预期的
        if (isError && retry > 0) {
          var count = retryCount != null ? retryCount + 1 : 0;

          if (count < retry) {
            isRetry = true;

            Future.microtask(() {
              if (!disposed) {
                _runTask(count);
              }
            });
          } else {
            this.retryCount = 0;
          }
        }

        if (!isRetry) _startRefetch();
      }

      // 移除缓存任务
      if (!isCacheTask) {
        _cache.removeTask(_hashKey);
      }

      completer.complete();
    }
  }

  /// 清理计时器
  void _clearTimers() {
    if (_refetchTimer != null) {
      _refetchTimer!.cancel();
      _refetchTimer = null;
    }
  }

  /// 开启refetch计时
  void _startRefetch() {
    _clearTimers();

    if (refetchInterval > Duration.zero) {
      _refetchTimer = Timer(refetchInterval, () {
        if (appVisibleChecker.visible) {
          _runTask();
        } else {
          // 不可见时, 重新发起计时
          _startRefetch();
        }
      });
    }
  }

  /// 根据当前参数调用 fetchFn 或 fetchVoidFn
  Future<Data> _fetchFnCall() {
    if (fetchFn != null) {
      return fetchFn!(payload as Payload);
    } else {
      return fetchVoidFn!();
    }
  }

  /// 根据当前 fetchFn + fetchVoidFn + payload + payloadHash 更新 hashKey
  void _updateHash() {
    var payloadHashSeed =
        payloadHash != null && payload != null
            ? payloadHash!(payload as Payload)
            : deepHash(payload);
    _hashKey = Object.hash(fetchFn, fetchVoidFn, payloadHashSeed);
  }

  /// 接收其他fetcher的缓存通知, 如果有与当前请求相同的, 将其data设置到自身
  void _cacheSync(({int hashKey, Object? data, Fetcher fetcher}) arg) {
    // 如果自身在加载中不同步, 因为自己的数据可能才是最新的
    if (_loading) return;
    if (arg.fetcher == this || arg.hashKey != _hashKey) return;
    // 缓存未启用时不同步
    if (action || cacheTime == Duration.zero) return;

    if (arg.data is Data?) {
      data = arg.data as Data?;
    }
  }
}

/// 用于简化 fetcher 在 State 中的使用, 它会自动监听 fetcher 的更新并更新组件,
/// 并在组件销毁时销毁 fetcher
mixin FetcherHelper<T extends StatefulWidget> on State<T> {
  /// 要在此类注册的全局 fetcher, 列表内容必须在组件声明周期内保持不变
  List<Fetcher> get globalFetchers => [];

  /// 要在此类注册的局部 fetcher, 列表内容必须在组件声明周期内保持不变
  List<Fetcher> get fetchers => [];

  @override
  void initState() {
    super.initState();

    for (var i = 0; i < fetchers.length; i++) {
      var cur = fetchers[i];
      cur.addListener(_changeHandle);
    }

    for (var i = 0; i < globalFetchers.length; i++) {
      var cur = globalFetchers[i];
      cur.addListener(_changeHandle);
    }
  }

  void _changeHandle() {
    setState(() {});
  }

  @override
  void dispose() {
    for (var i = 0; i < fetchers.length; i++) {
      var cur = fetchers[i];
      cur.dispose();
    }

    for (var i = 0; i < globalFetchers.length; i++) {
      var cur = globalFetchers[i];
      cur.removeListener(_changeHandle);
    }

    super.dispose();
  }
}

/// 缓存项, 分别表示缓存数据, 缓存时间, 有效期
typedef _CacheItem = ({Object? data, DateTime time, Duration validPeriod});

/// 存储请求缓存的容器, 会定期清理失效缓存
class _CacheBucket {
  _CacheBucket() {
    _startCleanupTimer();
  }

  /// 用于实现缓存同步功能, fetcher在请求完成后会通过此事件派发通知, 其他 fetcher 可在监听
  /// 到相同 hashKey 的事件后同步自身的数据
  final ZoEventTrigger<({int hashKey, Object? data, Fetcher fetcher})>
  cacheSyncEvent = ZoEventTrigger();

  /// 数据缓存表，key 为唯一标识
  final HashMap<Object, _CacheItem> cache = HashMap();

  /// payload 缓存表，key 为唯一标识
  final HashMap<Object, _CacheItem> payloadCache = HashMap();

  /// 记录正在进行中的请求
  final HashMap<Object, Future> tasks = HashMap();

  /// 定时清理间隔时间
  final Duration cleanupInterval = const Duration(minutes: 20);

  Timer? _cleanupTimer;

  /// 定时清理失效缓存和任务
  void _startCleanupTimer() {
    _cleanupTimer = Timer.periodic(cleanupInterval, (_) {
      final now = DateTime.now();
      final expiredKeys = <Object>[];
      final payloadExpiredKeys = <Object>[];

      // 清理已失效的缓存
      cache.forEach((key, value) {
        if (now.difference(value.time) > value.validPeriod) {
          expiredKeys.add(key);
        }
      });

      payloadCache.forEach((key, value) {
        if (now.difference(value.time) > value.validPeriod) {
          payloadExpiredKeys.add(key);
        }
      });

      for (final key in expiredKeys) {
        cache.remove(key);
      }

      for (final key in payloadExpiredKeys) {
        payloadCache.remove(key);
      }

      // 清理已完成且未被清除的的任务
      tasks.forEach((key, task) {
        task.whenComplete(() {
          removeTask(key);
        });
      });
    });
  }

  /// 添加缓存项
  void set(
    Object key,
    Object? data,
    Duration validPeriod, [
    bool isPayload = false,
  ]) {
    var cur = isPayload ? payloadCache : cache;
    cur[key] = (data: data, time: DateTime.now(), validPeriod: validPeriod);
  }

  /// 删除指定的缓存
  void remove(Object key, [bool isPayload = false]) {
    var cur = isPayload ? payloadCache : cache;
    cur.remove(key);
  }

  /// 获取缓存项，如果已过期则返回 null
  _CacheItem? get(Object key, [bool isPayload = false]) {
    var cur = isPayload ? payloadCache : cache;

    final entry = cur[key];

    if (entry == null) return null;

    var diff = DateTime.now().difference(entry.time);

    if (diff > entry.validPeriod) {
      cur.remove(key);
      return null;
    }

    return entry;
  }

  /// 设置指定key的异步任务
  void setTask(Object key, Future task) {
    tasks[key] = task;
  }

  /// 获取指定key的异步任务
  Future? getTask(Object key) {
    return tasks[key];
  }

  /// 删除指定key的异步任务
  void removeTask(Object key) {
    tasks.remove(key);
  }

  /// 清理并销毁计时器
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    cache.clear();
    tasks.clear();
  }
}

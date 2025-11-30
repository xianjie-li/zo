import "dart:async";
import "dart:collection";

/// 用于分类操作的来源，例如，仅 [local] 类型的操作应计入历史，且不需要生成回退操作
enum ZoMutatorSource {
  /// 由本地交互以及api产生的常规操作
  local,

  /// 由历史记录生成的操作
  history,

  /// 从服务器发起的变更操作
  server,
}

/// 用于控制命令行为的额外配置
class ZoMutatorConfig {
  ZoMutatorConfig({
    this.force = false,
    this.source = ZoMutatorSource.local,
  });

  /// 即使正在批处理过程中，依然立即执行传入的操作
  final bool force;

  /// 操作的来源
  final ZoMutatorSource source;
}

/// 描述了一组操作和具体行为的对象
class ZoMutatorCommand<Operation> extends ZoMutatorConfig {
  ZoMutatorCommand({
    required this.operation,
    super.force,
    super.source,
  });

  /// 要执行的一组操作
  final List<Operation> operation;
}

/// 通过 [ZoMutator.onMutation] 通知的一个突变操作
class ZoMutatorDetails<Operation> extends ZoMutatorConfig {
  ZoMutatorDetails({
    required this.operation,
    super.force,
    super.source,
  });

  /// 包含了操作和反向操作的列表，其中项为元组，第一个元素为执行的操作，第二个元素为反向操作
  final List<ZoMutatorRecord<Operation>> operation;
}

/// 一条操作记录, 是包含了操作和其反向操作的元组
typedef ZoMutatorRecord<Operation> = (
  Operation operation,
  List<Operation>? reverseOperations,
);

/// 用户需实现一个表示 [Operation] 、[ZoMutatorOperationHandle] 的类型来描述和处理操作，
/// 当 [ZoMutatorCommand.source] 为 local 时需要提供反向操作来实现操作历史和回退功能，
/// 反向操作包含多个操作项时，应按正序排序，对于无效操作可以返回 null
typedef ZoMutatorOperationHandle<Operation> =
    List<Operation>? Function(
      Operation operation,
      ZoMutatorCommand<Operation> command,
    );

/// 对数据的变更操作进行管理，每一个变更操作都必须由 [mutation] 提交一个 [ZoMutatorCommand] 来进行，
/// [ZoMutatorCommand] 描述了变更的行为和具体要执行的操作 [Operation], 操作可选择生成回退操作，
/// 所有变更都会通过 [onMutation] 进行通知
///
/// 必须提供一个 [ZoMutatorOperationHandle] 实现来控制如何处理 [Operation]，以及生成反向操作
///
/// 操作缓冲：可通过 [batchMutation] 来缓冲接下来的操作，使其延迟执行，这在一些阻塞操作中很有用，例如：
/// - 在移动和删除数据时，可能需要向用户发起确认，在确认期间如果数据发生了更改可能会因为索引变更等导致当前操作失效，
/// 此时就可以在确认期间将操作缓冲下来，在操作完成后再应用
/// - 删除数据并向服务器同步时，先立即执行删除操作来乐观的更新ui，然后通过批处理缓冲接下来的更改并发起请求，
/// 如果出现异常，通过回退操作来恢复ui，这避免了中间插入其他操作导致回退操作失效
///
/// 操作同步的几种方案：
/// - 延迟统一同步：操作和历史完全本地化，安全且简单，但服务端只保存最后提交的端数据，实时性较差
/// - 操作同步：组件在初始化时从服务器获取完整数据，然后将本地操作定时或批量同步到服务端，服务器也可能会传入同步操作到本地，这是一种不健壮的同步方式，实现细节可见下方文档
/// - 实时协同：服务端通过成熟的协同数据格式（比如ot、crdt）来管理数据，并完全代理组件的 onMutation / mutation、历史记录等
///
/// 历史记录和撤销重做：
/// 历史记录功能交由外部实现，该类只作为操作提供者，例如：有 tree、table 两个组件需要实现历史记录，
/// 通常会需要合并两者的历史记录来实现统一的全局历史，此时可实现一个通用的 [Operation] 类型来作为操作表示，
/// 并创建一个历史记录管理类从两者的 [onMutation] 接收变更，根据变更记录管理回退，这种模式也能提升到服务端，
/// 做基于服务端的历史记录
///
/// 操作同步方式实现中的一些实现小tips：
/// - 在操作是基于数据索引时，顺序不同会导致结果产生很大的差异，一种减少差异的方式是为每个节点分配唯一的uuid, 并且移动删除都基于参照节点进行，这能适当减少操作参产生的差异
/// - 在从服务端同步操作前（尤其是删除操作），操作、历史都是可靠的，但服务端操作一但介入，就可能造成严重的混乱，通常在接收到删除等破坏性操作时，需要将本地的操作历史等清空
/// - 建议只进行客户端到服务端的单向同步
/// - 新增数据的id等信息需要同步至本地数据
/// - 同步失败添加回退机制
/// - 适当添加容错，比如删除时如果参照不存在或索引越界可选择跳过删除，这比错误的删除更好；新增时如果越界可选择添加到后方
/// - 服务器触发的操作不计入历史
class ZoMutator<Operation> {
  ZoMutator({
    required ZoMutatorOperationHandle<Operation> operationHandle,
    this.onMutation,
  }) : _operationHandle = operationHandle;

  /// 记录正在进行的 mutation 的 future
  final List<Future> _mutationFutures = [];

  /// 存储在 [batchMutation] 缓存的操作，key 是 [batchMutation] 中的 [Completer.future]
  final HashMap<Object, List<ZoMutatorCommand<Operation>>> _mutationBatches =
      HashMap();

  /// 用户实现的操作处理器
  final ZoMutatorOperationHandle<Operation> _operationHandle;

  /// 发生变更操作时通过此方法进行通知
  void Function(ZoMutatorDetails<Operation> details)? onMutation;

  /// 依次执行一组对数据的变更操作
  ///
  /// 对于非批处理且 [ZoMutatorCommand.source] 为 local 的变更，可能会返回回退操作，视具体的实现而定
  ZoMutatorDetails<Operation>? mutation(
    ZoMutatorCommand<Operation> command,
  ) {
    final batchKey = _mutationFutures.firstOrNull;

    // 加入缓冲区，稍后执行
    if (!command.force && batchKey != null) {
      if (_mutationBatches[batchKey] == null) {
        _mutationBatches[batchKey] = [];
      }

      _mutationBatches[batchKey]!.add(command);

      return null;
    }

    // 立即执行
    final record = _commandHandle(command);

    if (record.isNotEmpty) {
      final details = ZoMutatorDetails(
        operation: record,
        force: command.force,
        source: command.source,
      );

      onMutation?.call(details);

      return details;
    }

    return null;
  }

  /// 将一组 [ZoMutatorRecord] 的反向操作倒序并平铺后返回，可以用这些操作来快速构造用于撤销的回退命令
  ///
  /// 只在简单场景使用，负责场景请实现更健壮的操作历史功能
  List<Operation> reverseOperations(List<ZoMutatorRecord<Operation>> records) {
    final List<Operation> list = [];

    for (final record in records.reversed) {
      final rev = record.$2;
      if (rev != null) {
        list.addAll(rev);
      }
    }

    return list;
  }

  /// 批处理变更操作，内部进行的所有 [mutation] 会被缓冲到 [action] 结束后执行，
  /// 如果在该次 [batchMutation] 完成之前还有其他的 [batchMutation] 调用，该调用会被挂起直到前一个批处理操作完成
  ///
  /// 默认情况下，无论操作是否成功，被缓冲的操作都会执行，可以将 [ignoreError] 设置为false来阻止这种行为
  ///
  /// 注意：
  /// - [batchMutation] 不支持嵌套使用，会导致操作被彻底琐死
  /// - 如果一个操作可能永远挂起，最好实现某种机制来让它做出超时等行为，避免影响后续操作
  Future<T> batchMutation<T>(
    Future<T> Function() action, [
    bool ignoreError = true,
  ]) async {
    final lastBatchFuture = _mutationFutures.lastOrNull;

    if (lastBatchFuture != null) {
      await lastBatchFuture.catchError((_) {});
    }

    final batchCompleter = Completer<void>();

    _mutationFutures.add(batchCompleter.future);

    try {
      final result = await action();

      _flushBatch(batchCompleter.future);

      return result;
    } catch (e) {
      if (ignoreError) {
        _flushBatch(batchCompleter.future);
      }

      // action 错误需要重新抛给用户
      rethrow;
    } finally {
      // 完成通知时，将其清理
      final index = _mutationFutures.indexOf(batchCompleter.future);

      if (index != -1) {
        _mutationFutures.removeAt(index);
      }

      batchCompleter.complete();
    }
  }

  /// 销毁并清理数据
  void dispose() {
    _mutationFutures.clear();
    _mutationBatches.clear();
  }

  /// 执行指定 command 中的操作并返回操作记录
  List<ZoMutatorRecord<Operation>> _commandHandle(
    ZoMutatorCommand<Operation> command,
  ) {
    final List<ZoMutatorRecord<Operation>> records = [];

    for (final operation in command.operation) {
      final reverseOperation = _operationHandle(operation, command);

      records.add((operation, reverseOperation));
    }

    return records;
  }

  /// 执行指定 key 缓冲的所有操作并清理对应缓冲区
  void _flushBatch(Object key) {
    final commands = _mutationBatches[key];
    if (commands == null) return;

    /// 如果操作中有配置相同的，将它们的结果合并，减少通知数量
    final List<ZoMutatorDetails<Operation>> mergedResult = [];

    bool? lastForce;
    ZoMutatorSource? lastSource;
    List<ZoMutatorRecord<Operation>> lastRecords = [];

    for (var command in commands) {
      final records = _commandHandle(command);

      final isSameConfig =
          (lastForce == null || lastForce == command.force) &&
          (lastSource == null || lastSource == command.source);

      if (isSameConfig) {
        // 配置相同或第一次遍历，写入临时变量
        lastRecords.addAll(records);
      } else {
        // 配置变更，将其作为单条变更写入到结果
        if (lastRecords.isNotEmpty) {
          mergedResult.add(
            ZoMutatorDetails(
              operation: lastRecords,
              force: lastForce!,
              source: lastSource!,
            ),
          );
        }

        // 重新临时缓冲变量
        lastRecords = records;
      }

      lastForce = command.force;
      lastSource = command.source;
    }

    // 处理循环末尾的项
    if (lastRecords.isNotEmpty) {
      mergedResult.add(
        ZoMutatorDetails(
          operation: lastRecords,
          force: lastForce!,
          source: lastSource!,
        ),
      );
    }

    for (final details in mergedResult) {
      onMutation?.call(details);
    }

    _mutationBatches.remove(key);
  }
}

part of "tree_data.dart";

/// 根据选项预计算的节点信息，包含所在层级、父级等
class ZoTreeDataNode<D> {
  ZoTreeDataNode({
    required this.value,
    required this.data,
    this.parent,
    this.next,
    this.prev,
    required this.level,
    required this.index,
    required this.path,
  });

  /// 值
  final Object value;

  /// 对应的数据
  final D data;

  /// 父节点
  ZoTreeDataNode<D>? parent;

  /// 前一个节点
  ZoTreeDataNode<D>? prev;

  /// 后一个节点
  ZoTreeDataNode<D>? next;

  /// 所在层级
  int level;

  /// 在父级中的索引
  int index;

  /// 用于访问该项的索引列表
  ZoIndexPath path;
}

/// 在调用 [ZoTreeDataController.onUpdateEach] 等回调时传入参数
class ZoTreeDataEachArgs<D> {
  ZoTreeDataEachArgs({
    required this.data,
    required this.node,
    required this.index,
  });

  /// 当前数据
  D data;

  /// 当前节点
  ZoTreeDataNode<D> node;

  /// 当前索引，索引可能不是连续的，因为前方节点可能会被过滤
  int index;
}

/// 子数据加载器
typedef ZoTreeDataLoader<D> = Future<List<D>> Function(D data);

/// 数据筛选器
typedef ZoTreeDataFilter<D> = bool Function(ZoTreeDataNode<D> node);

/// 异步数据加载状态变更时的事件对象
class ZoTreeDataLoadEvent<D> {
  const ZoTreeDataLoadEvent({
    required this.data,
    this.children,
    this.error,
    this.loading = false,
  });

  /// 本次加载对应的父数据
  final D data;

  /// 获取到的子数据
  final List<D>? children;

  /// 加载失败时存放错误信息
  final Object? error;

  /// 是否正在加载中
  final bool loading;
}

/// 表示 [ZoTreeDataOperation] 中与某条数据关联位置
enum ZoTreeDataRefPosition {
  /// 数据的前方，这是未设置位置时的默认行为
  before,

  /// 数据的内部，默认应该移动到子列表的最后一项
  inside,

  /// 数据的后方
  after,
}

/// 数据的变更操作
abstract class ZoTreeDataOperation {
  const ZoTreeDataOperation();
}

/// 新增数据操作
class ZoTreeDataAddOperation<D> extends ZoTreeDataOperation {
  const ZoTreeDataAddOperation({
    required this.data,
    this.toValue,
    this.position = ZoTreeDataRefPosition.before,
  }) : assert(
         toValue != null || position != ZoTreeDataRefPosition.inside,
       );

  /// 新增的数据
  final List<D> data;

  /// 目标节点，不传时添加到根层级
  final Object? toValue;

  /// 指定新增数据的位置
  final ZoTreeDataRefPosition position;
}

/// 移除数据操作
class ZoTreeDataRemoveOperation extends ZoTreeDataOperation {
  const ZoTreeDataRemoveOperation({
    required this.values,
  });

  /// 待移除数据
  final List<Object> values;
}

/// 移动数据操作
class ZoTreeDataMoveOperation extends ZoTreeDataOperation {
  const ZoTreeDataMoveOperation({
    required this.values,
    required this.toValue,
    this.position = ZoTreeDataRefPosition.before,
  });

  /// 待移动数据的 value
  final List<Object> values;

  /// 移动到指定节点的位置，该节点后移
  final Object toValue;

  /// 指定移动的位置
  final ZoTreeDataRefPosition position;
}

import "dart:async";
import "dart:collection";

import "package:flutter/material.dart";
import "package:zo/zo.dart";

part "view.dart";

/// 选择类型
enum ZoSelectionType {
  /// 单选
  single,

  /// 多选
  multiple,

  /// 不可选
  none,
}

/// 子数据加载器
typedef ZoRowDataLoader<ZoOption> =
    Future<List<ZoOption>> Function(ZoOption option);

/// 异步数据加载状态变更时的事件对象
class ZoOptionLoadEvent {
  const ZoOptionLoadEvent({
    required this.option,
    this.options,
    this.error,
    this.loading = false,
  });

  /// 本次加载对应的父选项
  final ZoOption option;

  /// 获取到的选项数据
  final List<ZoOption>? options;

  /// 加载失败时存放错误信息
  final Object? error;

  /// 是否正在加载中
  final bool loading;
}

/// 包含选中项各种信息的对象
class ZoOptionSelectedData {
  const ZoOptionSelectedData({
    required this.selected,
    required this.selectedBranch,
    required this.selectedLeaf,
    required this.unlistedSelected,
    required this.options,
  });

  /// 所有选中项
  final List<ZoOption> selected;

  /// 所有选中的分支节点
  final List<ZoOption> selectedBranch;

  /// 所有选中的叶子节点
  final List<ZoOption> selectedLeaf;

  /// 当前已知数据中不存在的选中项
  final Set<Object> unlistedSelected;

  /// 当前所有选项
  final List<ZoOption> options;

  /// 根据选中项和完整数据创建 [ZoOptionSelectedData] 实例
  factory ZoOptionSelectedData.fromSelected(
    Iterable<Object> selected,
    List<ZoOption> options,
  ) {
    final List<ZoOption> selectedList = [];
    final List<ZoOption> selectedBranch = [];
    final List<ZoOption> selectedLeaf = [];

    final selectedSet = selected.toSet();

    // 存放已知选项
    final Set<Object> existSet = {};

    // 递归处理选项
    void call(
      List<ZoOption> list,
    ) {
      for (final row in list) {
        existSet.add(row.value);

        final isSelected = selectedSet.contains(row.value);

        if (row.children != null && row.children!.isNotEmpty) {
          call(row.children!);
        }

        if (isSelected) {
          selectedList.add(row);

          if (row.isBranch) {
            selectedBranch.add(row);
          } else {
            selectedLeaf.add(row);
          }
        }
      }
    }

    call(options);

    final unlistedSelected = selectedSet.difference(existSet);

    return ZoOptionSelectedData(
      selected: selectedList,
      selectedBranch: selectedBranch,
      selectedLeaf: selectedLeaf,
      unlistedSelected: unlistedSelected,
      options: options,
    );
  }
}

/// menu / select / tree 等组件使用的单个选项配置
class ZoOption {
  ZoOption({
    required this.value,
    this.title,
    this.children,
    this.loader,
    this.enabled = true,
    this.height = ZoOption.defaultHeight,
    this.matchString,
    this.data,
    this.builder,
    this.leading,
    this.trailing,
    this.interactive = true,
    this.optionsWidth,
  }) : assert(
         title != null || builder != null,
         "Must provide either title or builder",
       );

  /// 默认高度
  static const double defaultHeight = 34;

  /// 表示该项的唯一值
  Object value;

  /// 标题内容, 用于对数据进行过滤等，在菜单类组件中会作为标题显示
  Widget? title;

  /// 子选项, 没有 [children] 和 [loader] 的项视为叶子节点
  List<ZoOption>? children;

  /// 用于异步加载子选项，没有 [children] 和 [loader] 的项视为叶子节点
  ZoRowDataLoader<ZoOption>? loader;

  /// 是否启用
  bool enabled;

  /// 高度
  ///
  /// 每个选项都会有一个确切的高度, 用来在包含大量的数据时实现动态加载&卸载
  double height;

  /// 在搜索 / 过滤等功能中用作匹配该项的字符串, 如果未设置, 会尝试从 [title] 中获取文本,
  /// 但要求其必须是一个 Text 组件
  String? matchString;

  /// 可在此额外挂载一些信息，例如选项原始数据
  Object? data;

  /// 当前是否为分支节点
  bool get isBranch {
    return children != null || loader != null;
  }

  /// 自定义内容构造器, 会覆盖 [title] 等选项
  Widget Function(BuildContext context)? builder;

  /// 前导内容
  Widget? leading;

  /// 尾随内容
  Widget? trailing;

  /// 是否可参与交互, 用于分割线 / 分组等渲染
  bool interactive;

  /// 子菜单的宽度, 默认与父菜单相同, 对 menu 这类的组件有效, 对 tree 等组件可能无效
  double? optionsWidth;

  @override
  String toString() {
    return """ZoOption(value: $value, title: $title, options: [${children?.length ?? 0}]""";
  }

  /// 将选项信息转换为 json 对象, 只会保留 title / value / children 等关键字段
  ///
  /// [matchStringFallback] - 默认情况下 title 会依次从 [title] > [matchString] 获取,
  /// 设置为 false 可禁止从 [matchString] 获取 title
  ///
  /// 只有 [title] 是 Text 组件时才能正常从其内部获取到文本
  Map<String, dynamic> toJson({
    bool matchStringFallback = true,
    bool skipChildren = false,
    String titleField = "title",
    String valueField = "value",
    String childrenField = "children",
  }) {
    return {
      valueField: value,
      titleField: ?getTitleText(),
      if (!skipChildren && children != null && children!.isNotEmpty)
        childrenField: toJsonList(
          children!,
          matchStringFallback: matchStringFallback,
          skipChildren: skipChildren,
          titleField: titleField,
          valueField: valueField,
          childrenField: childrenField,
        ),
    };
  }

  /// 将指定列表转换为 json 对象, 参数的详细说明见 [toJson] 方法
  static List<Map<String, dynamic>> toJsonList(
    Iterable<ZoOption> rows, {
    bool matchStringFallback = true,
    bool skipChildren = false,
    String titleField = "title",
    String valueField = "value",
    String childrenField = "children",
  }) {
    return rows
        .map(
          (e) => e.toJson(
            matchStringFallback: matchStringFallback,
            skipChildren: skipChildren,
            titleField: titleField,
            valueField: valueField,
            childrenField: childrenField,
          ),
        )
        .toList();
  }

  /// 获取标题文本, 会依次从 [title] > [matchString] 获取
  String? getTitleText([bool matchStringFallback = true]) {
    if (title is Text) {
      return (title as Text).data;
    }
    if (matchStringFallback) {
      return matchString;
    }
    return null;
  }

  /// 根据传入值复制当前选项
  ///
  /// [children] 子项会原样移动, 不会进行复制
  ZoOption copyWith({
    Object? value,
    Widget? title,
    Widget Function(BuildContext context)? builder,
    Widget? leading,
    Widget? trailing,
    double? height,
    bool? enabled,
    bool? interactive,
    List<ZoOption>? children,
    ZoRowDataLoader<ZoOption>? loader,
    double? optionsWidth,
    String? matchString,
    Object? data,
  }) {
    return ZoOption(
      value: value ?? this.value,
      title: title ?? this.title,
      builder: builder ?? this.builder,
      leading: leading ?? this.leading,
      trailing: trailing ?? this.trailing,
      height: height ?? this.height,
      enabled: enabled ?? this.enabled,
      interactive: interactive ?? this.interactive,
      children: children ?? this.children,
      loader: loader ?? this.loader,
      optionsWidth: optionsWidth ?? this.optionsWidth,
      matchString: matchString ?? this.matchString,
      data: data ?? this.data,
    );
  }
}

/// 表示一个分组区域的 [ZoOption]
class ZoOptionSection extends ZoOption {
  ZoOptionSection(
    String title,
  ) : super(
        value: "ZoSection ${createTempId()}",
        interactive: false,
        builder: (context) {
          final style = context.zoStyle;

          return Container(
            height: ZoOption.defaultHeight - 2,
            alignment: Alignment.bottomLeft,
            padding: EdgeInsets.all(style.space2),
            child: Text(
              title,
              style: TextStyle(
                fontSize: style.fontSizeSM,
                color: style.hintTextColor,
              ),
            ),
          );
        },
      );
}

/// 表示一个分割线的 [ZoOption]
class ZoOptionDivider extends ZoOption {
  ZoOptionDivider()
    : super(
        value: "ZoDivider ${createTempId()}",
        interactive: false,
        builder: (context) {
          return const Center(
            child: Divider(
              height: 1,
            ),
          );
        },
      );

  /// 默认高度
  static const double defaultHeight = 24;
}

/// 根据选项预计算的节点信息，包含所在层级、父级等
class ZoOptionNode {
  ZoOptionNode({
    required this.value,
    required this.option,
    this.parent,
    this.next,
    this.prev,
    required this.level,
    required this.index,
    required this.path,
  });

  /// 值
  final Object value;

  /// 对应的选项
  final ZoOption option;

  /// 父节点
  ZoOptionNode? parent;

  /// 前一个节点
  ZoOptionNode? prev;

  /// 后一个节点
  ZoOptionNode? next;

  /// 所在层级
  int level;

  /// 在父级中的索引
  int index;

  /// 用于访问该项的索引列表
  List<int> path;
}

/// 在调用 [ZoOptionController.each] 时传入
class ZoOptionEachArgs {
  ZoOptionEachArgs({
    required this.option,
    required this.node,
    required this.index,
  });

  /// 当前选项
  ZoOption option;

  /// 当前节点
  ZoOptionNode node;

  /// 当前索引，索引可能不是连续的，因为前方节点可能会被过滤
  int index;
}

/// 选项筛选器
typedef ZoOptionFilter = bool Function(ZoOptionNode node);

/// 数据的变更操作
abstract class ZoOptionMutationEvent {
  const ZoOptionMutationEvent();
}

/// 新增数据操作
class ZoOptionAddOperation extends ZoOptionMutationEvent {
  const ZoOptionAddOperation({
    required this.data,
    this.toValue,
    this.insertAfter = false,
  });

  /// 新增的数据
  final List<ZoOption> data;

  /// 插入到指定节点的位置，该节点后移
  final Object? toValue;

  /// 插入到 to 的下方
  final bool insertAfter;
}

/// 移除数据操作
class ZoOptionRemoveOperation extends ZoOptionMutationEvent {
  const ZoOptionRemoveOperation({
    required this.values,
  });

  /// 待移除数据
  final List<Object> values;
}

/// 移动数据操作
class ZoRowDataMoveOperation extends ZoOptionMutationEvent {
  const ZoRowDataMoveOperation({
    required this.values,
    this.toValue,
    this.insertAfter = false,
  });

  /// 待移动的数据
  final List<Object> values;

  /// 移动到指定节点的位置，该节点后移
  final Object? toValue;

  /// 移动到 to 的下方
  final bool insertAfter;
}

/// 提选项数据管理、树形数据管理、高效的树节点查询、展开管理等通用行为
///
/// 由于存在缓存信息，需要在必要时对它们进行更新，通常有三种情况：
/// - [reload] 外部数据需要完全替换，此操作会清理所有缓存信息并重新计算
/// - [refresh] 数据在内部被可控的更新，比如通过内部api新增、删除、排序等，此操作会重新计算节点的关联关系、flatList 等
/// - [refreshFilters] 展开状态/筛选条件变更
///
/// 内部会自动在合适的时机调用对应的更新函数，除非需要自行扩展行为，否则大部分情况无需手动调用这些方法
class ZoOptionController {
  ZoOptionController({
    required List<ZoOption> options,
    this.ignoreOpenStatus = false,
    Iterable<Object>? selected,
    Iterable<Object>? openSelected,
    String? matchString,
    bool caseSensitive = false,
    RegExp? matchRegexp,
    ZoOptionFilter? filter,
    this.each,
    this.eachStart,
    this.eachEnd,
    this.onFilterComplete,
  }) : _matchRegexp = matchRegexp,
       _matchString = matchString,
       _caseSensitive = caseSensitive,
       _filter = filter,
       _options = options {
    selector = Selector(
      selected: selected,
      valueGetter: (opt) => opt.value,
      optionsGetter: () => flatList,
    );

    openSelector = Selector(
      selected: openSelected,
      valueGetter: (opt) => opt.value,
    );

    selector.addListener(() {
      _selectChangedProcessing = true;
      refreshFilters();
      _selectChangedProcessing = false;
    });

    openSelector.addListener(() {
      refreshFilters();
    });

    reload();
  }

  /// 对于不需要管理 open 状态的数据，可以设置为 true 来强制将所有项视为开启
  final bool ignoreOpenStatus;

  /// 当前是否由于选中项变更而正在执行 [refreshFilters], 该类型的变更计算只处理关联关系计算，
  /// 数据项的数量和结构没有变更，可以由此来辅助判断是否要跳过某些行为
  bool get selectChangedProcessing => _selectChangedProcessing;
  bool _selectChangedProcessing = false;

  /// 用于过滤数据的文本, 设置后只显示包含该文本的数据
  ///
  /// 间接匹配：节点的父级、子级、自身任意一项匹配都会视为匹配
  String? get matchString => _matchString;
  String? _matchString;
  String? _matchStringLowercase;
  set matchString(String? value) {
    _matchString = value;

    if (_matchString != null) {
      _matchStringLowercase = _matchString!.toLowerCase();
    }

    _matchStatus.clear();
    refreshFilters();
  }

  /// 匹配时是否区分大小写, 仅用于 [matchString], [matchRegexp] 等过滤方式请通过自有参数实现
  bool get caseSensitive => _caseSensitive;
  bool _caseSensitive;
  set caseSensitive(bool newCaseSensitive) {
    if (_caseSensitive == newCaseSensitive) return;
    _caseSensitive = newCaseSensitive;
    _matchStatus.clear();
    refreshFilters();
  }

  /// 用于过滤数据的正则, 设置后只显示匹配的数据
  ///
  /// 间接匹配：节点的父级、子级、自身任意一项匹配都会视为匹配
  RegExp? get matchRegexp => _matchRegexp;
  RegExp? _matchRegexp;
  set matchRegexp(RegExp? value) {
    _matchRegexp = value;
    _matchStatus.clear();
    refreshFilters();
  }

  /// 筛选阶段会对每个符合显示条件的数据调用，可以返回 false 将数据过滤掉,
  /// 可将该方法当做 [matchString] / [matchRegexp] 的扩展版本使用，提供更进一步的筛选能力
  ///
  /// 间接匹配：节点的父级、子级、自身任意一项匹配都会视为匹配
  ///
  /// filter 以数据的实际顺序倒序调用
  ZoOptionFilter? get filter => _filter;
  ZoOptionFilter? _filter;
  set filter(ZoOptionFilter? filter) {
    _filter = filter;
    _matchStatus.clear();
    refreshFilters();
  }

  /// 内部通过 [refreshFilters] 对列表进行最终筛选时，会对满足显示条件的每个数据调用该方法，
  /// 可以用来做一些外部的数据同步工作
  ///
  /// 提供此方法的目的是在一些需要遍历树的场景与控制器复用一次循环，避免在数据较多时性能浪费
  ///
  /// each 的循环顺序为倒序
  ValueChanged<ZoOptionEachArgs>? each;

  /// 在 [each] 开始之前调用
  VoidCallback? eachStart;

  /// 在 [each] 结束后调用
  VoidCallback? eachEnd;

  /// 在存在筛选条件时，如果存在匹配项, 会在完成筛选后调用此方法进行通知，回调会传入所有严格匹配的数据，
  /// 用于上层组件处理展开、聚焦等交互优化
  ValueChanged<List<ZoOptionNode>>? onFilterComplete;

  /// 未经处理的原始数据， 设置后会更新当前数据缓存
  List<ZoOption> get options => _options;
  List<ZoOption> _options;
  set options(List<ZoOption> value) {
    _options = value;
    reload();
  }

  /// 控制选中项
  late final Selector<Object, ZoOption> selector;

  /// 控制展开项，仅用于树形视图， menu等组件展开行为比较简单，由组件单独管理
  late final Selector<Object, ZoOption> openSelector;

  /// 异步数据加载状态变更时调用
  final asyncLoadTrigger = EventTrigger<ZoOptionLoadEvent>();

  /// [options] 的副本， 它可能额外包含异步加载的数据，数据也可能是经过排序的，
  /// 异步加载数据、数据编译操作会直接更改此对象
  List<ZoOption> get processedData => _processedData;
  List<ZoOption> _processedData = [];

  /// [_processedData] 的扁平列表
  List<ZoOption> get flatList => _flatList;
  List<ZoOption> _flatList = [];

  /// 经过 open、match 等配置过滤后的 [flatList]
  List<ZoOption> get filteredFlatList => _filteredFlatList;
  List<ZoOption> _filteredFlatList = [];

  /// 包含被选中子项的分支节点
  final HashMap<Object, bool> _branchesHasSelectedChild = HashMap();

  /// 检测节点 [matchString] / [matchRegexp] 的匹配状态
  final HashMap<Object, bool> _matchStatus = HashMap();

  /// 所有节点
  final HashMap<Object, ZoOptionNode> _nodes = HashMap();

  /// 筛选结果缓存
  final HashMap<Object, ({bool isOpen, bool isMatch})> _filterCache = HashMap();

  /// 可见性缓存
  final HashMap<Object, bool> _visibleCache = HashMap();

  /// 异步加载的数据缓存, 以 value 为 key 进行存储
  final HashMap<Object, List<ZoOption>> _asyncRowCaches = HashMap();

  /// 数据是否正在进行异步加载及对应的future
  final HashMap<Object, Future> _asyncRowTask = HashMap();

  /// [options] 变更时，用于重新计算所有缓存信息
  void reload() {
    // 流程: 清理现有缓存、 clone 数据, 同时创建node，生成各 processedData / flatList

    _processedData = [];
    _flatList = [];
    _nodes.clear();

    ZoOptionNode? lastNode;

    void loop({
      required List<ZoOption> list,
      ZoOptionNode? parent,
      required List<int> path,
    }) {
      final List<ZoOption> newList = parent != null ? [] : _processedData;

      for (var i = 0; i < list.length; i++) {
        final opt = list[i];
        final cloned = opt.copyWith();

        final node = ZoOptionNode(
          value: cloned.value,
          option: cloned,
          parent: parent,
          level: path.length,
          index: i,
          path: [...path, i],
        );

        node.prev = lastNode;
        lastNode?.next = node;
        lastNode = node;

        newList.add(cloned);
        _flatList.add(cloned);
        _nodes[cloned.value] = node;

        // 处理子项
        if (cloned.isBranch) {
          // 附加异步数据
          if (cloned.children == null) {
            final cacheRows = _asyncRowCaches[cloned.value];

            if (cacheRows != null) {
              cloned.children = cacheRows;
            }
          }

          // 递归处理子项
          if (cloned.children != null && cloned.children!.isNotEmpty) {
            loop(
              list: cloned.children!,
              parent: node,
              path: node.path,
            );
          }
        }
      }

      if (parent != null) {
        parent.option.children = newList;
      }
    }

    loop(
      list: options,
      parent: null,
      path: [],
    );

    refreshFilters();
  }

  /// [processedData] 变更时，用于重新计算必要信息，在新建数据、调整顺序等操作后调用
  void refresh() {
    _flatList = [];
    _nodes.clear();

    ZoOptionNode? lastNode;

    void loop({
      required List<ZoOption> list,
      ZoOptionNode? parent,
      required List<int> path,
    }) {
      for (var i = 0; i < list.length; i++) {
        final opt = list[i];

        final node = ZoOptionNode(
          value: opt.value,
          option: opt,
          parent: parent,
          level: path.length,
          index: i,
          path: [...path, i],
        );

        node.prev = lastNode;
        lastNode?.next = node;
        lastNode = node;

        _flatList.add(opt);
        _nodes[opt.value] = node;

        // 处理子项
        if (opt.isBranch) {
          // 递归处理子项
          if (opt.children != null && opt.children!.isNotEmpty) {
            loop(
              list: opt.children!,
              parent: node,
              path: node.path,
            );
          }
        }
      }
    }

    loop(
      list: _processedData,
      parent: null,
      path: [],
    );

    refreshFilters();
  }

  String? _lastMatchString;
  RegExp? _lastMatchRegexp;
  ZoOptionFilter? _lastFilter;

  /// 重新根据 open 、match、filter 等过滤状态更新 [filteredFlatList]，应在相关数据变更后调用
  void refreshFilters() {
    final List<ZoOption> filteredList = [];

    _branchesHasSelectedChild.clear();
    _matchStatus.clear();
    _filterCache.clear();
    _visibleCache.clear();

    // 记录包含匹配子项的节点
    final HashMap<Object, bool> rowsHasMatchChild = HashMap();

    eachStart?.call();

    // 直接匹配的数据
    final List<ZoOptionNode> exactMatchNode = [];

    final filterChanged =
        _lastMatchString != matchString ||
        _lastMatchRegexp != matchRegexp ||
        _lastFilter != filter;

    _lastMatchString = matchString;
    _lastMatchRegexp = matchRegexp;
    _lastFilter = filter;

    final needEmitFilterEvent =
        filterChanged && !selectChangedProcessing && onFilterComplete != null;

    // 倒序处理每一项，因为父节点会依赖子节点的匹配状态
    for (var i = flatList.length - 1; i >= 0; i--) {
      final opt = flatList[i];
      final node = _nodes[opt.value]!;

      final (:isOpen, :isMatch) = getFilterStatus(node);
      final isSelected = selector.isSelected(node.value);

      var everyParentIsOpen = true;
      var parentHasMatch = false;

      ZoOptionNode? parent = node.parent;

      if (isMatch && needEmitFilterEvent) {
        exactMatchNode.insert(0, node);
      }

      // 检测所有父级
      while (parent != null) {
        final parentFilter = getFilterStatus(parent);

        if (!parentFilter.isOpen) {
          everyParentIsOpen = false;
        }

        if (parentFilter.isMatch) {
          parentHasMatch = true;
        }

        if (isMatch) {
          rowsHasMatchChild[parent.value] = true;
        }

        if (isSelected) {
          _branchesHasSelectedChild[parent.value] = true;
        }

        parent = parent.parent;
      }

      final childHasMatch = rowsHasMatchChild[node.value] == true;

      // 所有父级均展开，且父、子、自身任意一项匹配，则节点可见
      final isVisible =
          everyParentIsOpen && (isMatch || parentHasMatch || childHasMatch);

      _visibleCache[node.value] = isVisible;

      if (isVisible) {
        filteredList.insert(0, opt);

        each?.call(
          ZoOptionEachArgs(
            index: i,
            option: opt,
            node: node,
          ),
        );
      }
    }

    _filteredFlatList = filteredList;

    if (needEmitFilterEvent && exactMatchNode.isNotEmpty) {
      onFilterComplete!(exactMatchNode);
    }

    eachEnd?.call();
  }

  /// 加载指定数据的子级, 如果数据已加载过会直接跳过
  Future loadChildren(Object value) async {
    final node = getNode(value);

    assert(node != null);

    if (node == null) return;

    final task = _asyncRowTask[node.value];

    if (task != null) return task;

    final row = node.option;

    if (row.children != null && row.children!.isNotEmpty) return;

    final loader = row.loader;

    if (loader == null) return;

    final completer = Completer();

    _asyncRowTask[row.value] = completer.future;

    asyncLoadTrigger.emit(
      ZoOptionLoadEvent(
        option: row,
        loading: true,
      ),
    );

    try {
      final res = await loader(row);

      row.children = res;

      refresh();

      _asyncRowTask.remove(row.value);

      asyncLoadTrigger.emit(
        ZoOptionLoadEvent(
          option: row,
          options: res,
          loading: false,
        ),
      );

      completer.complete();
    } catch (e, stack) {
      _asyncRowTask.remove(row.value);

      asyncLoadTrigger.emit(
        ZoOptionLoadEvent(
          option: row,
          error: e,
          loading: false,
        ),
      );

      completer.completeError(e, stack);
    }

    return completer.future;
  }

  /// 判断指定 node 的 filter 状态，会优先读取缓存
  ({bool isOpen, bool isMatch}) getFilterStatus(
    ZoOptionNode node,
  ) {
    final cache = _filterCache[node.value];

    if (cache != null) return cache;

    final isOpen = ignoreOpenStatus
        ? true
        : openSelector.isSelected(node.value);

    var isMatch = _matchStatus[node.value];

    if (isMatch == null) {
      isMatch = _isMatch(node.value);
      _matchStatus[node.value] = isMatch;
    }

    final newCache = (isMatch: isMatch, isOpen: isOpen);

    _filterCache[node.value] = newCache;

    return newCache;
  }

  /// 检测数据是否匹配
  bool isMatch(Object value) {
    return _matchStatus[value] ?? false;
  }

  /// 数据是否包含被选中子级
  bool hasSelectedChild(Object value) {
    return _branchesHasSelectedChild[value] ?? false;
  }

  /// 数据是否可见, 即是否在 [filteredFlatList] 列表中
  ///
  /// 当 [ignoreOpenStatus] 设置为 true 是，由于 open 状态不影响可见性，可能会产生不符合直觉的返回，但这是正常的
  bool isVisible(Object value) {
    return _visibleCache[value] ?? false;
  }

  /// 是否正在加载异步选项数据
  bool isAsyncLoading(Object value) {
    final task = _asyncRowTask[value];
    return task != null;
  }

  /// 判断数据是否与 [matchString] / [matchRegexp] / [filter] 匹配
  bool _isMatch(Object value) {
    final node = getNode(value);

    assert(node != null);

    if (filter != null) {
      if (filter!(node!)) return true;
    }

    if (matchString == null && matchRegexp == null) {
      return true;
    }

    final String? text = node!.option.getTitleText();

    // 未获取到文本的数据一律视为不匹配
    if (text == null) return false;

    if (matchString != null) {
      if (!caseSensitive && _matchStringLowercase != null) {
        final lowerCaseText = text.toLowerCase();
        return lowerCaseText.contains(_matchStringLowercase!);
      } else {
        return text.contains(matchString!);
      }
    } else {
      return matchRegexp!.hasMatch(text);
    }
  }

  /// 当前是否包含有效的筛选条件
  bool hasFilterCondition() {
    return matchString != null ||
        matchRegexp != null ||
        openSelector.getSelected().isNotEmpty;
  }

  /// 获取特定数据的子项，不传入 [value] 时返回根数据列表，[filtered] 可以控制是否使用过滤后的数据
  List<ZoOption> getChildren({
    Object? value,
    bool filtered = true,
  }) {
    List<ZoOption> list;

    if (value == null) {
      list = _processedData;
    } else {
      final node = getNode(value);

      assert(node != null);

      ZoOption? curOpt;
      for (var i = 0; i < node!.path.length; i++) {
        final curInd = node.path[i];

        final curList = curOpt?.children ?? _processedData;

        curOpt = curList[curInd];
      }
      list = curOpt!.children ?? [];
    }

    if (filtered) {
      return list.where((i) => isVisible(i.value)).toList();
    }

    return list;
  }

  /// 获取指定数据的节点信息，其中预缓存了一些树节点的有用信息
  ZoOptionNode? getNode(Object value) {
    return _nodes[value];
  }

  /// 获取前一个节点，[filter] 可过滤掉不满足条件的数据
  ZoOptionNode? getPrevNode(
    ZoOptionNode node, {
    bool Function(ZoOptionNode node)? filter,
  }) {
    var curNode = node.prev;

    while (curNode != null) {
      if (filter != null && !filter(curNode)) {
        break;
      } else {
        curNode = curNode.prev;
      }
    }

    return curNode;
  }

  /// 获取后一个节点，[filter] 可过滤掉不满足条件的数据
  ZoOptionNode? getNextNode(
    ZoOptionNode node, {
    bool Function(ZoOptionNode node)? filter,
  }) {
    var curNode = node.next;

    while (curNode != null) {
      if (filter != null && !filter(curNode)) {
        break;
      } else {
        curNode = curNode.next;
      }
    }

    return curNode;
  }

  /// 获取兄弟节点
  List<ZoOption> getSiblings(
    ZoOptionNode node, [
    bool includeInvisible = true,
  ]) {
    final list = node.level == 0
        ? _processedData
        : node.parent?.option.children ?? [];

    if (includeInvisible) {
      return list;
    }

    return list.where((o) {
      return isVisible(o.value);
    }).toList();
  }

  /// 销毁对象
  void dispose() {
    _options = [];
    _processedData.clear();
    _flatList.clear();
    _filteredFlatList.clear();
    _branchesHasSelectedChild.clear();
    _matchStatus.clear();
    _nodes.clear();
    _filterCache.clear();
    _visibleCache.clear();
    _asyncRowCaches.clear();
    _asyncRowTask.clear();

    selector.dispose();
    openSelector.dispose();
  }
}

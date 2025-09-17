/// 提供选项相关Widget需要的核心组件:
/// - 通用类型： [ZoSelectionType] / [ZoOptionSelectedData] 等
/// - 统一的选项接口: [ZoOption]
/// - 统一的选项渲染Widget: [ZoOptionViewList] / [ZoOptionView]
/// - 通用的选项逻辑控制器: [ZoOptionController] 选中项管理， 树形数据处理， 高效的父子逻辑查询、选项数据管理等
library;

import "dart:async";
import "dart:collection";

import "package:flutter/material.dart";
import "package:zo/zo.dart";

// # # # # # # # 通用类型 # # # # # # #

/// 选择类型
enum ZoSelectionType {
  /// 单选
  single,

  /// 多选
  multiple,

  /// 不可选
  none,
}

/// event.data 的类型
typedef ZoOptionEventData = ({ZoOption option, BuildContext context});

/// 异步选项加载时的事件对象
class ZoOptionLoadEvent {
  const ZoOptionLoadEvent({
    required this.option,
    this.options,
    this.error,
    this.loading = false,
  });

  /// 本次加载对应的选项
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

  /// 当前已知选项中不存在的选中项
  final Set<Object> unlistedSelected;

  /// 当前所有选项
  final List<ZoOption> options;

  /// 根据选中项和完整选项创建 [ZoOptionSelectedData] 实例
  factory ZoOptionSelectedData.fromSelected(
    Iterable<Object> selected,
    List<ZoOption> options,
  ) {
    final List<ZoOption> selected = [];
    final List<ZoOption> selectedBranch = [];
    final List<ZoOption> selectedLeaf = [];

    final selectedSet = selected.toSet();

    // 存放已知选项
    final Set<Object> existSet = {};

    // 递归处理选项
    void call(
      List<ZoOption> list,
    ) {
      for (final option in list) {
        existSet.add(option.value);

        final isSelected = selectedSet.contains(option.value);

        if (option.options != null && option.options!.isNotEmpty) {
          call(option.options!);
        }

        if (isSelected) {
          selected.add(option);

          if (option.isBranch) {
            selectedBranch.add(option);
          } else {
            selectedLeaf.add(option);
          }
        }
      }
    }

    call(options);

    final unlistedSelected = selectedSet.difference(existSet);

    return ZoOptionSelectedData(
      selected: selected,
      selectedBranch: selectedBranch,
      selectedLeaf: selectedLeaf,
      unlistedSelected: unlistedSelected,
      options: options,
    );
  }
}

// # # # # # # # 选项 # # # # # # #

/// 表示 menu / select / tree 等组件的单个选项
class ZoOption {
  ZoOption({
    required this.value,
    this.title,
    this.builder,
    this.leading,
    this.trailing,
    this.height = ZoOption.defaultHeight,
    this.enabled = true,
    this.interactive = true,
    this.options,
    this.loadOptions,
    this.optionsWidth,
    this.matchString,
  }) : assert(
         title != null || builder != null,
         "Must provide either title or builder",
       );

  /// 默认高度
  static const double defaultHeight = 35;

  /// 表示该项的唯一值
  Object value;

  /// 标题内容, 必须传入 [title] 或 [builder] 之一来配置显示的内容
  Widget? title;

  /// 自定义内容构造器, 会覆盖 [title] / [description] 等选项
  Widget Function(BuildContext context)? builder;

  /// 前导内容
  Widget? leading;

  /// 尾随内容
  Widget? trailing;

  /// 选项高度
  ///
  /// 每个选项都会有一个确切的高度, 用来在包含大量的选项时实现动态加载
  double height;

  /// 是否启用
  bool enabled;

  /// 是否可参与交互, 用于分割线 / 分组等渲染
  bool interactive;

  /// 子选项, 没有子选项和 [loadOptions] 的项视为叶子节点
  List<ZoOption>? options;

  /// 设置时, 用于异步加载子项
  Future<List<ZoOption>> Function(ZoOption option)? loadOptions;

  /// 子菜单的宽度, 默认与父菜单相同, 对 menu 这类的组件有效, 对 tree 等组件可能无效
  double? optionsWidth;

  /// 在搜索 / 过滤等功能中用作匹配该项的字符串, 如果未设置, 会尝试从 [title] 中获取文本,
  /// 但要求其必须是一个 Text 组件
  String? matchString;

  @override
  String toString() {
    return """ZoOption(value: $value, title: $title, options: [${options?.length ?? 0}]""";
  }

  /// 根据传入值复制当前选项
  ///
  /// [options] 子项会原样移动, 不会进行复制
  ZoOption copyWith({
    Object? value,
    Widget? title,
    Widget Function(BuildContext context)? builder,
    Widget? leading,
    Widget? trailing,
    double? height,
    bool? enabled,
    bool? interactive,
    List<ZoOption>? options,
    Future<List<ZoOption>> Function(ZoOption option)? loadOptions,
    double? optionsWidth,
    String? matchString,
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
      options: options ?? this.options,
      loadOptions: loadOptions ?? this.loadOptions,
      optionsWidth: optionsWidth ?? this.optionsWidth,
      matchString: matchString ?? this.matchString,
    );
  }

  /// 当前选项是否是分支节点
  bool get isBranch {
    return options != null || loadOptions != null;
  }

  /// 将选项转换为 json 对象, 只会保留 title / value / children 等关键字段
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
      if (!skipChildren && options != null && options!.isNotEmpty)
        childrenField: toJsonList(
          options!,
          matchStringFallback: matchStringFallback,
          skipChildren: skipChildren,
          titleField: titleField,
          valueField: valueField,
          childrenField: childrenField,
        ),
    };
  }

  /// 将指定选项列表转换为 json 对象, 参数的详细说明见 [toJson] 方法
  static List<Map<String, dynamic>> toJsonList(
    Iterable<ZoOption> options, {
    bool matchStringFallback = true,
    bool skipChildren = false,
    String titleField = "title",
    String valueField = "value",
    String childrenField = "children",
  }) {
    return options
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
            height: ZoOption.defaultHeight,
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
        height: defaultHeight,
        builder: (context) {
          return const SizedBox(
            height: defaultHeight,
            child: Center(
              child: Divider(
                height: 1,
              ),
            ),
          );
        },
      );

  /// 默认高度
  static const double defaultHeight = 24;
}

// # # # # # # # 渲染 # # # # # # #

/// 根据 [ZoOption] 构造的单个列表项, 它还对外暴露选项的各种交互事件
class ZoOptionView extends StatelessWidget {
  const ZoOptionView({
    super.key,
    required this.option,
    this.active = false,
    this.loading = false,
    this.highlight = false,
    this.onTap,
    this.onActiveChanged,
    this.onFocusChanged,
  });

  /// 图标尺寸
  static const double iconSize = 18;

  /// 一个空的 leading, 用于与带缩进的选项对对齐
  static const Widget emptyLeading = SizedBox(width: ZoOptionView.iconSize);

  /// 需要构造的选项
  final ZoOption option;

  /// 是否处于活动状态, 可用于表示交互和选中状态
  final bool active;

  /// 是否处于加载状态
  final bool loading;

  /// 是否处于高亮状态
  final bool highlight;

  /// 点击, 若返回一个 future, 可进入loading状态
  final dynamic Function(ZoTriggerEvent event)? onTap;

  /// 是否活动状态
  /// - 鼠标: 表示位于组件上方
  /// - 触摸设备: 按下触发, 松开或移动时关闭
  final ZoTriggerListener<ZoTriggerToggleEvent>? onActiveChanged;

  /// 焦点变更事件
  final ZoTriggerListener<ZoTriggerToggleEvent>? onFocusChanged;

  @override
  Widget build(BuildContext context) {
    final style = context.zoStyle;

    var hasChild = false;

    if (option.options != null && option.options!.isNotEmpty) {
      hasChild = true;
    }

    if (option.loadOptions != null) {
      hasChild = true;
    }

    Widget? header;
    Widget? leading;
    Widget? trailing;

    EdgeInsetsGeometry? padding = EdgeInsets.symmetric(
      horizontal: style.space2,
      vertical: style.space1 + 2,
    );

    if (option.builder != null) {
      header = option.builder!(context);
      // 完全自定义时去掉默认的部分样式
      padding = EdgeInsets.zero;
    } else {
      if (option.title != null) {
        header = DefaultTextStyle.merge(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: option.title!,
        );
      }

      leading = option.leading;
      trailing = option.trailing;
    }

    final ZoOptionEventData data = (option: option, context: context);

    return SizedBox(
      height: option.height,
      child: Center(
        child: ZoTile(
          header: header,
          leading: leading,
          trailing: trailing,
          enabled: option.enabled,
          arrow: hasChild,
          active: active,
          loading: loading,
          highlight: highlight,
          horizontalSpacing: style.space2,
          interactive: option.interactive,
          crossAxisAlignment: CrossAxisAlignment.center,
          disabledColor: Colors.transparent,
          padding: padding,
          iconTheme: const IconThemeData(size: ZoOptionView.iconSize),
          onTap: onTap,
          onActiveChanged: onActiveChanged,
          onFocusChanged: onFocusChanged,
          data: data,
        ),
      ),
    );
  }
}

/// 根据 [ZoOption] list 构造可滚动的选项列表
class ZoOptionViewList extends StatefulWidget {
  const ZoOptionViewList({
    super.key,
    required this.options,
    this.option,
    this.activeCheck,
    this.loadingCheck,
    this.highlightCheck,
    this.toolbar,
    this.maxHeight,
    this.maxHeightFactor = ZoOptionViewList.defaultHeightFactor,
    this.padding,
    this.loading = false,
    this.hasDecoration = true,
    this.scrollController,
    this.onTap,
    this.onActiveChanged,
    this.onFocusChanged,
  });

  static const defaultHeightFactor = 0.92;

  /// 选项列表
  final List<ZoOption> options;

  /// 菜单对应的父选项, 只有子菜单会存在此项
  final ZoOption? option;

  /// 用于判断选项是否应显示 active 样式
  final bool Function(ZoOption option)? activeCheck;

  /// 用于判断选项是否应显示 loading 样式
  final bool Function(ZoOption option)? loadingCheck;

  /// 用于判断选项是否应显示 highlight 样式
  final bool Function(ZoOption option)? highlightCheck;

  /// 在顶部渲染工具栏
  final Widget? toolbar;

  /// 最大高度, 默认会根据视口尺寸和 [maxHeightFactor] 进行限制
  final double? maxHeight;

  /// 最大高度的比例, 设置 [maxHeight] 后此项无效
  final double maxHeightFactor;

  /// 内间距
  final EdgeInsets? padding;

  /// 是否处于加载状态
  final bool loading;

  /// 是否使用容器装饰
  final bool hasDecoration;

  /// 滚动控制器
  final ScrollController? scrollController;

  /// 选项被点击, 若返回一个 future, 可进入loading状态
  final dynamic Function(ZoTriggerEvent event)? onTap;

  /// 选项活动状态变更
  /// - 鼠标: 表示位于组件上方
  /// - 触摸设备: 按下触发, 松开或移动时关闭
  final ZoTriggerListener<ZoTriggerToggleEvent>? onActiveChanged;

  /// 焦点变更
  final ZoTriggerListener<ZoTriggerToggleEvent>? onFocusChanged;

  @override
  State<ZoOptionViewList> createState() => _ZoOptionViewListState();
}

class _ZoOptionViewListState extends State<ZoOptionViewList> {
  /// 选项总高度
  double listHeight = 0;

  /// 是否可滚动
  bool scrollable = false;

  /// 是否处于加载状态
  bool loading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(covariant ZoOptionViewList oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.options != widget.options ||
        oldWidget.padding != widget.padding) {
      updateScrollDatas();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    updateScrollDatas();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 对比当前选项尺寸和视口的尺寸, 根据结果更新可滚动状态和容器高度
  void updateScrollDatas() {
    final size = MediaQuery.sizeOf(context);

    final maxHeight = widget.maxHeight ?? size.height * widget.maxHeightFactor;

    var height = 0.0;

    scrollable = false;

    for (final option in widget.options) {
      height += option.height;

      if (height > maxHeight) {
        scrollable = true;
        break;
      }
    }

    var paddingHeight = 0.0;

    if (widget.padding != null) {
      paddingHeight = widget.padding!.top + widget.padding!.bottom;
    }

    listHeight = height > 0 ? height + paddingHeight : 0;
  }

  Widget? itemBuilder(BuildContext context, int index) {
    final opt = widget.options.elementAtOrNull(index);

    if (opt == null) return null;

    final isActive = widget.activeCheck?.call(opt) ?? false;
    final isLoading = widget.loadingCheck?.call(opt) ?? false;
    final isHighlight = widget.highlightCheck?.call(opt) ?? false;

    return ZoOptionView(
      key: ValueKey(opt.value),
      onTap: widget.onTap,
      onActiveChanged: widget.onActiveChanged,
      onFocusChanged: widget.onFocusChanged,
      option: opt,
      active: isActive,
      loading: isLoading,
      highlight: isHighlight,
    );
  }

  double? itemExtent(index, dimensions) {
    final opt = widget.options.elementAtOrNull(index);
    return opt?.height;
  }

  Widget buildMain(ZoStyle style, ZoLocalizationsDefault locale) {
    if (loading || widget.loading) {
      return const ZoProgress(
        size: ZoSize.small,
      );
    }

    if (widget.options.isEmpty) {
      return ZoOptionView(
        option: ZoOption(
          title: Text(locale.noData, style: style.hintTextStyle),
          value: "__EMPTY__",
          interactive: false,
        ),
      );
    }

    return SizedBox(
      height: listHeight,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(
          context,
        ).copyWith(scrollbars: false),
        child: ListView.builder(
          controller: widget.scrollController,
          physics: scrollable ? null : const NeverScrollableScrollPhysics(),
          itemCount: widget.options.length,
          itemBuilder: itemBuilder,
          itemExtentBuilder: itemExtent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = context.zoStyle;
    final locale = context.zoLocale;

    return Container(
      padding: widget.padding ?? EdgeInsets.all(style.space2),
      width: double.infinity,
      decoration: !widget.hasDecoration
          ? null
          : BoxDecoration(
              color: style.surfaceGrayColor,
              borderRadius: BorderRadius.circular(style.borderRadius),
              border: Border.all(color: style.outlineColor),
              boxShadow: [style.overlayShadow],
            ),
      child: Column(
        spacing: style.space1,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ?widget.toolbar,
          buildMain(style, locale),
        ],
      ),
    );
  }
}

// # # # # # # # 选项控制器 # # # # # # #

/// 根据选项预计算的辅助节点信息，包含所在层级、父级等
class ZoOptionNode {
  const ZoOptionNode({
    required this.value,
    required this.option,
    required this.parent,
    required this.level,
    required this.index,
    required this.path,
  });

  /// 选项值
  final Object value;

  /// 当前选项
  final ZoOption option;

  /// 父级选项
  final ZoOption? parent;

  /// 选项所在层级
  final int level;

  /// 选项在父级选项中的索引
  final int index;

  /// 用于访问该项的索引列表
  final List<int> path;
}

/// 提供选中项管理、树形数据管理、高效的树节点查询、选项数据/展开管理等选项通用行为的处理
///
/// 由于存在缓存信息，需要在必要时对它们进行更新，通常有三种情况：
/// - [reload] 外部选项需要完全替换，此操作会清理所有缓存信息并重新计算
/// - [refresh] 选项在内部被可控的更新，此操作会重新计算节点的关联关系、flatList 等
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
    RegExp? matchRegexp,
  }) : _matchRegexp = matchRegexp,
       _matchString = matchString,
       _options = options {
    selector = Selector(
      selected: selected,
      valueGetter: (opt) => opt.value,
      optionsGetter: () => flatList,
    );

    openSelector = Selector(
      selected: selected,
      valueGetter: (opt) => opt.value,
    );

    selector.addListener(() {
      refreshFilters();
    });

    openSelector.addListener(() {
      refreshFilters();
    });

    reload();
  }

  /// 对于menus等不需要open状态的选项，可以设置为true来强制将所有项视为开启
  final bool ignoreOpenStatus;

  /// 用于过滤选项的文本, 设置后只显示包含该文本的选项
  String? get matchString => _matchString;
  String? _matchString;
  set matchString(String? value) {
    _matchString = value;
    _matchStatus.clear();
    refreshFilters();
  }

  /// 用于过滤选项的正则, 设置后只显示匹配的选项
  RegExp? get matchRegexp => _matchRegexp;
  RegExp? _matchRegexp;
  set matchRegexp(RegExp? value) {
    _matchRegexp = value;
    _matchStatus.clear();
    refreshFilters();
  }

  /// 未经处理的原始选项， 设置后会更新当前选项缓存
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

  /// [options] 的副本， 它可能额外包含异步加载的数据，数据也可能是经过排序的
  List<ZoOption> get processedOptions => _processedOptions;
  List<ZoOption> _processedOptions = [];

  /// [_processedOptions] 的扁平列表
  List<ZoOption> get flatList => _flatList;
  List<ZoOption> _flatList = [];

  /// 经过 open、match 等配置过滤后的 [flatList]
  List<ZoOption> get filteredFlatList => _filteredFlatList;
  List<ZoOption> _filteredFlatList = [];

  /// 包含被选中子项的分支节点
  final HashMap<Object, bool> _branchesHasSelectedChild = HashMap();

  /// 检测节点 [matchString] / [matchRegexp] 的选中状态
  final HashMap<Object, bool> _matchStatus = HashMap();

  /// 所有节点
  final HashMap<Object, ZoOptionNode> _nodes = HashMap();

  /// 筛选结果缓存
  final HashMap<Object, ({bool isOpen, bool isMatch})> _filterCache = HashMap();

  /// 可见性缓存
  final HashMap<Object, bool> _visibleCache = HashMap();

  /// 异步加载的选项缓存, 以 value 为 key 进行存储
  final HashMap<Object, List<ZoOption>> _asyncOptionCaches = HashMap();

  /// 选项是否正在进行异步加载及对应的future
  final HashMap<Object, Future> _asyncOptionTask = HashMap();

  /// [options] 变更时，用于重新计算所有缓存信息
  void reload() {
    // 流程: 清理现有缓存、 clone 选项, 同时创建node，生成各 processedOptions / flatList

    _processedOptions = [];
    _flatList = [];
    _nodes.clear();

    void loop({
      required List<ZoOption> list,
      ZoOption? parent,
      required List<int> path,
    }) {
      final List<ZoOption> newList = parent != null ? [] : _processedOptions;

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

        newList.add(cloned);
        _flatList.add(cloned);
        _nodes[cloned.value] = node;

        // 处理子项
        if (cloned.isBranch) {
          // 附加异步选项
          if (cloned.options == null) {
            final cacheOptions = _asyncOptionCaches[cloned.value];

            if (cacheOptions != null) {
              cloned.options = cacheOptions;
            }
          }

          // 递归处理子项
          if (cloned.options != null && cloned.options!.isNotEmpty) {
            loop(
              list: cloned.options!,
              parent: cloned,
              path: node.path,
            );
          }
        }
      }

      if (parent != null) {
        parent.options = newList;
      }
    }

    loop(
      list: options,
      parent: null,
      path: [],
    );

    refreshFilters();
  }

  /// [processedOptions] 变更时，用于重新计算必要信息，在新建选项、调整顺序等操作后调用
  void refresh() {
    _flatList = [];
    _nodes.clear();

    void loop({
      required List<ZoOption> list,
      ZoOption? parent,
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

        _flatList.add(opt);
        _nodes[opt.value] = node;

        // 处理子项
        if (opt.isBranch) {
          // 递归处理子项
          if (opt.options != null && opt.options!.isNotEmpty) {
            loop(
              list: opt.options!,
              parent: opt,
              path: node.path,
            );
          }
        }
      }
    }

    loop(
      list: _processedOptions,
      parent: null,
      path: [],
    );

    refreshFilters();
  }

  /// 重新计算 open 、match 相关的过滤状态，应在相关选项变更后调用
  void refreshFilters() {
    final List<ZoOption> filteredList = [];

    _branchesHasSelectedChild.clear();
    _matchStatus.clear();
    _filterCache.clear();
    _visibleCache.clear();

    // 记录包含匹配子项的节点
    final HashMap<Object, bool> optionsHasMatchChild = HashMap();

    // 倒序处理每一项，因为父节点会依赖子节点的匹配状态
    for (var i = flatList.length - 1; i >= 0; i--) {
      final opt = flatList[i];
      final node = _nodes[opt.value]!;

      final (:isOpen, :isMatch) = getFilterStatus(node);
      final isSelected = selector.isSelected(node.value);

      var everyParentIsOpen = true;
      var parentHasMatch = false;

      ZoOption? parent = node.parent;

      // 检测所有父级
      while (parent != null) {
        final parentNode = _nodes[parent.value]!;
        final parentFilter = getFilterStatus(parentNode);

        if (!parentFilter.isOpen) {
          everyParentIsOpen = false;
        }

        if (parentFilter.isMatch) {
          parentHasMatch = true;
        }

        if (isMatch) {
          optionsHasMatchChild[node.value] = true;
        }

        if (isSelected) {
          _branchesHasSelectedChild[parentNode.value] = true;
        }

        parent = parentNode.parent;
      }

      final childHasMatch = optionsHasMatchChild[node.value] == true;

      // 所有父级均展开，且父、子、自身任意一项匹配，则节点可见
      final isVisible =
          everyParentIsOpen && (isMatch || parentHasMatch || childHasMatch);

      // 本身是匹配项，不作更改，但父级要设置为间接匹配项
      if (isMatch) {
        ZoOption? parent = node.parent;

        while (parent != null) {
          final parentNode = _nodes[parent.value]!;
          optionsHasMatchChild[parentNode.value] = true;
          parent = parentNode.parent;
        }
      }

      _visibleCache[node.value] = isVisible;

      if (isVisible) {
        filteredList.insert(0, opt);
      }
    }

    _filteredFlatList = filteredList;
  }

  /// 加载指定选项的子级, 如果数据已加载过会直接跳过
  Future loadOptions(Object value) async {
    final node = getNode(value);

    assert(node != null);

    if (node == null) return;

    final task = _asyncOptionTask[node.value];

    if (task != null) return task;

    if (node.option.options != null && node.option.options!.isNotEmpty) return;

    final loadOptions = node.option.loadOptions;

    if (loadOptions == null) return;

    final completer = Completer();

    _asyncOptionTask[node.option.value] = completer.future;

    asyncLoadTrigger.emit(
      ZoOptionLoadEvent(
        option: node.option,
        loading: true,
      ),
    );

    try {
      final res = await loadOptions(node.option);

      node.option.options = res;

      refresh();

      _asyncOptionTask.remove(node.option.value);

      asyncLoadTrigger.emit(
        ZoOptionLoadEvent(
          option: node.option,
          options: res,
          loading: false,
        ),
      );

      completer.complete();
    } catch (e) {
      _asyncOptionTask.remove(node.option.value);

      asyncLoadTrigger.emit(
        ZoOptionLoadEvent(
          option: node.option,
          error: e,
          loading: false,
        ),
      );

      completer.completeError(e);
    }
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

  /// 检测选项是否匹配
  bool isMatch(Object value) {
    return _matchStatus[value] ?? false;
  }

  /// 选项是否包含被选中子项
  bool hasSelectedChild(Object value) {
    return _branchesHasSelectedChild[value] ?? false;
  }

  /// 选项是否可见
  bool isVisible(Object value) {
    return _visibleCache[value] ?? false;
  }

  /// 是否正在加载异步选项
  bool isAsyncOptionLoading(Object value) {
    final task = _asyncOptionTask[value];
    return task != null;
  }

  /// 判断选项是否与 [ZoOptionViewList.matchString] / [ZoOptionViewList.matchRegexp] 匹配
  bool _isMatch(Object value) {
    final node = getNode(value);

    assert(node != null);

    if (matchString == null && matchRegexp == null) {
      return true;
    }

    final String? text = node!.option.getTitleText();

    // 未获取到文本的选项一律视为不匹配
    if (text == null) return false;

    if (matchString != null) {
      return text.contains(matchString!);
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

  /// 获取特定选项的子项，不传入 [value] 时返回根选项，[filtered] 可以控制是否使用过滤后的选项
  List<ZoOption> getOptions({
    Object? value,
    bool filtered = true,
  }) {
    List<ZoOption> list;

    if (value == null) {
      list = _processedOptions;
    } else {
      final node = getNode(value);

      assert(node != null);

      ZoOption? curOpt;
      for (var i = 0; i < node!.path.length; i++) {
        final curInd = node.path[i];

        final curList = curOpt?.options ?? _processedOptions;

        curOpt = curList[curInd];
      }
      list = curOpt!.options ?? [];
    }

    if (filtered) {
      return list.where((i) => isVisible(i.value)).toList();
    }

    return list;
  }

  /// 获取指定选项的节点信息，其中预缓存了一些树节点的有用信息
  ZoOptionNode? getNode(Object value) {
    return _nodes[value];
  }

  /// 销毁对象
  void dispose() {
    _options = [];
    _processedOptions.clear();
    _flatList.clear();
    _filteredFlatList.clear();
    _branchesHasSelectedChild.clear();
    _matchStatus.clear();
    _nodes.clear();
    _filterCache.clear();
    _visibleCache.clear();
    _asyncOptionCaches.clear();
    _asyncOptionTask.clear();

    selector.dispose();
    openSelector.dispose();
  }
}

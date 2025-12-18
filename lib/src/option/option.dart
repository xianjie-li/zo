/// 提供了选项相关的抽象，这些选项用于 Select、Menu、Tree 等组件
///
/// 核心：[ZoOption] 类，表示一个树形的数据选项，它包含 [ZoOptionSection] / [ZoOptionDivider] 两个装饰用的变体
///
/// 数据管理: 通过 [ZoOptionController] 来管理选项数据，它对树形数据提供了强大的抽象，以及预置的
/// 展开管理、选中管理、筛选、变更操作、异步加载、节点查询方法、用于渲染的平铺列表等功能
///
/// 预设样式：使用 [ZoOptionViewList] 组件可基于选项渲染预设的样式，
/// 这也是内部组件使用的样式组件
library;

import "dart:collection";
import "dart:math";

import "package:flutter/material.dart";
import "package:zo/zo.dart";

part "view.dart";

/// menu / select / tree 等组件使用的单个选项配置
class ZoOption {
  ZoOption({
    required this.value,
    this.title,
    this.children,
    this.loader,
    this.enabled = true,
    this.height,
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

  /// 表示该项的唯一值
  Object value;

  /// 标题内容, 用于对数据进行过滤等，在菜单类组件中会作为标题显示
  Widget? title;

  /// 子选项, 没有 [children] 和 [loader] 的项视为叶子节点
  List<ZoOption>? children;

  /// 用于异步加载子选项，没有 [children] 和 [loader] 的项视为叶子节点
  ZoTreeDataLoader<ZoOption>? loader;

  /// 是否启用
  bool enabled;

  /// 高度
  ///
  /// 每个选项都会有一个确切的高度, 用来在包含大量的数据时实现动态加载&卸载，
  /// 不传时默认使用 [ZoStyle.getSizedExtent] 获取
  double? height;

  /// 在搜索 / 过滤等功能中用作匹配该项的字符串, 如果未设置, 会尝试从 [title] 中获取文本,
  /// 但要求其必须是一个 Text 组件
  String? matchString;

  /// 可在此额外挂载一些信息，例如选项原始数据
  Object? data;

  /// 当前是否为分支节点
  bool get isBranch {
    return children != null || loader != null;
  }

  /// 自定义内容构造器, 会覆盖 [title] 等选项, 不同的组件可能实现不同，也可能完全不支持
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
    List<ZoOption>? children,
    ZoTreeDataLoader<ZoOption>? loader,
    bool? enabled,
    double? height,
    String? matchString,
    Object? data,
    Widget Function(BuildContext context)? builder,
    Widget? leading,
    Widget? trailing,
    bool? interactive,
    double? optionsWidth,
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

/// 表示一个分组区域的 [ZoOption], 此选项不可用于树组件
class ZoOptionSection extends ZoOption {
  ZoOptionSection(
    String title,
  ) : super(
        value: "ZoSection ${createTempId()}",
        interactive: false,
        enabled: false,
        height: 32,
        builder: (context) {
          final style = context.zoStyle;

          return Container(
            height: 32,
            alignment: const Alignment(-1, 0.4),
            padding: EdgeInsets.symmetric(horizontal: style.space2),
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

/// 表示一个分割线的 [ZoOption], 此选项不可用于树组件
class ZoOptionDivider extends ZoOption {
  ZoOptionDivider()
    : super(
        value: "ZoDivider ${createTempId()}",
        interactive: false,
        enabled: false,
        height: 16,
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

/// 用于 [ZoOption] 的树数据管理，细节请见 [ZoTreeDataController] 类
class ZoOptionController extends ZoTreeDataController<ZoOption> {
  ZoOptionController({
    required super.data,
    super.selected,
    super.expands,
    super.expandAll,
    super.matchString,
    super.caseSensitive,
    super.matchRegexp,
    super.filter,
    super.onPhaseChanged,
    super.onUpdateEach,
    super.onReloadEach,
    super.onRefreshEach,
    super.onFiltered,
    super.onMutation,
    super.onLoadStatusChanged,
  });

  @override
  @protected
  ZoOption cloneData(ZoOption data) {
    return data.copyWith();
  }

  @override
  @protected
  List<ZoOption>? getChildrenList(ZoOption data) {
    return data.children;
  }

  @override
  @protected
  ZoTreeDataLoader<ZoOption>? getDataLoader(ZoOption data) {
    return data.loader;
  }

  @override
  @protected
  String? getKeyword(ZoOption data) {
    return data.getTitleText();
  }

  @override
  @protected
  Object getValue(ZoOption data) {
    return data.value;
  }

  @override
  @protected
  bool isBranch(ZoOption data) {
    return data.isBranch;
  }

  @override
  @protected
  void setChildrenList(ZoOption data, List<ZoOption>? children) {
    data.children = children;
  }
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

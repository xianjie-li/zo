part of "option.dart";

/// 通过 [ZoTile.data] 传递到事件回调中的对象
typedef ZoOptionEventData = ({ZoOption option, BuildContext context});

/// 根据 [ZoOption] 构造的单个列表项, 它还对外暴露选项的各种交互事件
class ZoOptionView extends StatelessWidget {
  const ZoOptionView({
    super.key,
    required this.option,
    this.active = false,
    this.loading = false,
    this.highlight = false,
    this.enabled = true,
    this.interactive = true,
    this.arrow = true,
    this.leading,
    this.trailing,
    this.padding,
    this.verticalSpacing,
    this.horizontalSpacing,
    this.activeColor,
    this.highlightColor,
    this.onTap,
    this.onContextAction,
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

  /// 是否启用
  final bool enabled;

  /// 是否可进行交互, 与 enabled = false 不同的是它不设置禁用样式, 只是阻止交互行为
  final bool interactive;

  /// 启用启用列表右侧的子项标识箭头，会在包含子选项时显示
  final bool arrow;

  /// 自定义前导内容，默认取 option.leading
  final Widget? leading;

  /// 自定义尾随内容，默认取 option.trailing
  final Widget? trailing;

  /// 间距
  final EdgeInsets? padding;

  /// 纵向内容间的间距
  final double? verticalSpacing;

  /// 横向内容间的间距
  final double? horizontalSpacing;

  /// active 状态的背景色
  final Color? activeColor;

  /// highlight 状态的背景色
  final Color? highlightColor;

  /// 点击, 若返回一个 future, 可进入loading状态
  final dynamic Function(ZoTriggerEvent event)? onTap;

  /// 触发上下文操作, 在鼠标操作中表示右键点击, 在触摸操作中表示长按
  final ZoTriggerListener<ZoTriggerEvent>? onContextAction;

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

    if (option.children != null && option.children!.isNotEmpty) {
      hasChild = true;
    }

    if (option.loader != null) {
      hasChild = true;
    }

    Widget? header;
    Widget? leadingNode;
    Widget? trailingNode;

    EdgeInsets? padding =
        this.padding ??
        EdgeInsets.symmetric(
          horizontal: style.space2,
        );

    if (option.builder != null) {
      header = option.builder!(context);
      // 完全自定义时去掉默认的部分样式
      padding = this.padding ?? EdgeInsets.zero;
    } else {
      if (option.title != null) {
        header = DefaultTextStyle.merge(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: option.title!,
        );
      }

      leadingNode = leading ?? option.leading;
      trailingNode = trailing ?? option.trailing;
    }

    final ZoOptionEventData data = (option: option, context: context);

    return SizedBox(
      height: option.height,
      child: ZoTile(
        header: header,
        leading: leadingNode,
        trailing: trailingNode,
        enabled: enabled && option.enabled,
        arrow: arrow && hasChild,
        active: active,
        loading: loading,
        highlight: highlight,
        interactive: interactive && option.interactive,
        crossAxisAlignment: CrossAxisAlignment.center,
        disabledColor: Colors.transparent,
        activeColor: activeColor,
        highlightColor: highlightColor,
        padding: padding,
        verticalSpacing: verticalSpacing,
        horizontalSpacing: horizontalSpacing ?? style.space1,
        decorationPadding: const EdgeInsets.symmetric(vertical: 1),
        iconTheme: const IconThemeData(size: ZoOptionView.iconSize),
        onTap: onTap,
        onContextAction: onContextAction,
        onActiveChanged: onActiveChanged,
        onFocusChanged: onFocusChanged,
        data: data,
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
          height: 28,
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

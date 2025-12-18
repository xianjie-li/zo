part of "option.dart";

/// 通过 [ZoTile.data] 传递到事件回调中的对象
typedef ZoOptionEventData = ({ZoOption option, BuildContext context});

/// 根据 [ZoOption] list 构造可滚动的选项列表
class ZoOptionViewList extends StatefulWidget {
  const ZoOptionViewList({
    super.key,
    required this.options,
    this.option,
    this.activeCheck,
    this.loadingCheck,
    this.highlightCheck,
    this.maxHeight,
    this.maxHeightFactor,
    this.padding,
    this.size,
    this.loading = false,
    this.hasDecoration = true,
    this.scrollController,
    this.onTap,
    this.onActiveChanged,
    this.onFocusChanged,
  });

  static double defaultHeightFactor = 1;

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

  /// 最大高度, 默认会根据视口尺寸和 [maxHeightFactor] 进行限制
  final double? maxHeight;

  /// 最大高度的比例, 设置 [maxHeight] 后此项无效
  final double? maxHeightFactor;

  /// 内间距
  final EdgeInsets? padding;

  /// 选项尺寸,优先级低于直接在选项中设置的高度
  final ZoSize? size;

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
  /// 列表最大高度
  double listHeight = 0;

  /// 是否可滚动
  bool scrollable = false;

  /// 是否处于加载状态
  bool loading = false;

  late ZoStyle style;

  /// 预计算一些信息，在每个 itemBuilder 中使用
  late double itemDefaultHeight;

  late IconThemeData itemIconTheme;

  late TextStyle itemTextStyle;

  late double itemHorizontalSpacing;

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

    style = context.zoStyle;

    // 这些计算在 didChangeDependencies 中执行, 避免每个itemBuilder重复计算
    itemDefaultHeight = style.getSizedExtent(widget.size);
    itemIconTheme = IconThemeData(size: style.getSizedIconSize(widget.size));
    itemTextStyle = TextStyle(fontSize: style.getSizedFontSize(widget.size));
    itemHorizontalSpacing = style.getSizedSpace(widget.size);

    updateScrollDatas();
  }

  @override
  void dispose() {
    super.dispose();
  }

  /// 对比当前选项尺寸和视口的尺寸, 根据结果更新可滚动状态和容器高度
  void updateScrollDatas() {
    final size = MediaQuery.sizeOf(context);

    final maxHeight =
        widget.maxHeight ??
        size.height *
            (widget.maxHeightFactor ?? ZoOptionViewList.defaultHeightFactor);

    var height = 0.0;

    final defaultHeight = style.getSizedExtent(widget.size);

    for (final option in widget.options) {
      height += option.height ?? defaultHeight;

      if (height > maxHeight) {
        break;
      }
    }

    listHeight = height > 0 ? min(height, maxHeight) : 0;
  }

  Widget? itemBuilder(BuildContext context, int index) {
    final opt = widget.options.elementAtOrNull(index);

    if (opt == null) return null;

    final isActive = widget.activeCheck?.call(opt) ?? false;
    final isLoading = widget.loadingCheck?.call(opt) ?? false;
    final isHighlight = widget.highlightCheck?.call(opt) ?? false;

    Widget? header;

    final EdgeInsets padding = EdgeInsets.symmetric(
      horizontal: style.space2,
    );

    if (opt.builder != null) {
      header = opt.builder!(context);
    } else {
      if (opt.title != null) {
        header = DefaultTextStyle.merge(
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          child: opt.title!,
        );
      }
    }

    return Builder(
      builder: (context) {
        final ZoOptionEventData data = (option: opt, context: context);

        return SizedBox(
          height: opt.height ?? itemDefaultHeight,
          child: ZoTile(
            key: ValueKey(opt.value),
            header: header,
            leading: opt.leading,
            trailing: opt.trailing,
            enabled: opt.enabled,
            arrow: opt.isBranch,
            active: isActive,
            loading: isLoading,
            highlight: isHighlight,
            interactive: opt.interactive,
            crossAxisAlignment: CrossAxisAlignment.center,
            disabledColor: Colors.transparent,
            padding: padding,
            horizontalSpacing: itemHorizontalSpacing,
            decorationPadding: const EdgeInsets.symmetric(vertical: 1),
            iconTheme: itemIconTheme,
            textStyle: itemTextStyle,
            onTap: widget.onTap,
            onActiveChanged: widget.onActiveChanged,
            onFocusChanged: widget.onFocusChanged,
            data: data,
          ),
        );
      },
    );
  }

  double? itemExtent(index, dimensions) {
    final opt = widget.options.elementAtOrNull(index);
    return opt?.height ?? style.getSizedExtent(widget.size);
  }

  Widget buildMain(ZoLocalizationsDefault locale) {
    if (loading || widget.loading) {
      return SizedBox(
        height: style.sizeSM,
        child: Padding(
          padding: EdgeInsetsGeometry.only(left: style.space1),
          child: const Align(
            alignment: AlignmentGeometry.centerLeft,
            child: ZoProgress(
              size: ZoSize.small,
            ),
          ),
        ),
      );
    }

    if (widget.options.isEmpty) {
      return SizedBox(
        height: style.sizeSM,
        child: Padding(
          padding: EdgeInsetsGeometry.only(left: style.space1),
          child: Align(
            alignment: AlignmentGeometry.centerLeft,
            child: Text(locale.noData, style: style.hintTextStyle),
          ),
        ),
      );
    }

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: listHeight,
      ),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(
          context,
        ).copyWith(scrollbars: false),
        child: ListView.builder(
          controller: widget.scrollController,
          // physics: scrollable ? null : const NeverScrollableScrollPhysics(),
          itemCount: widget.options.length,
          itemBuilder: itemBuilder,
          itemExtentBuilder: itemExtent,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.zoLocale;

    final widgetPadding =
        widget.padding ?? EdgeInsets.all(style.getSizedSpace(widget.size));

    if (!widget.hasDecoration) {
      return buildMain(locale);
    }

    return Container(
      padding: widgetPadding,
      width: double.infinity,
      decoration: BoxDecoration(
        color: style.surfaceContainerColor,
        borderRadius: BorderRadius.circular(style.borderRadius),
        border: Border.all(color: style.outlineColor),
        boxShadow: [style.overlayShadow],
      ),
      child: buildMain(locale),
    );
  }
}

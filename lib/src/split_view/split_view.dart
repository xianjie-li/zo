import "dart:collection";
import "dart:math" as math;
import "package:flutter/material.dart";
import "package:zo/zo.dart";

/// `ZoSplitView` 中单个面板的静态配置。
///
/// 该对象用于描述面板在初始化或恢复布局时的目标状态：
/// - 使用 [size] 表示固定像素尺寸
/// - 使用 [flex] 表示剩余空间中的占比权重
/// - 使用 [min] / [max] 约束面板可收缩和可扩张的范围
///
/// `size` 和 `flex` 只能二选一：
/// - 传入 [size] 时，当前面板按固定尺寸参与布局
/// - 传入 [flex] 时，当前面板按权重瓜分剩余空间
/// - 两者都不传时，会被视为“自动 fixed 面板”，并在初始化时按剩余空间均分
///
/// 分割器相关的交互约束，语义上作用于当前面板左侧的那条分割线。
class ZoSplitViewPanelConfig {
  const ZoSplitViewPanelConfig({
    required this.id,
    this.size,
    this.flex,
    this.min = 0,
    this.max,
    this.snapToMin,
    this.wrapScrollView = false,
  }) : assert(
         size == null || flex == null,
         "Panel cannot have both size and flex.",
       );

  /// 用于标识当前面板的唯一值。
  ///
  /// 该值会同时用于：
  /// - `LayoutId` 的 id
  /// - 面板查找、重置、最大化、最小化等 API 的目标标识
  ///
  /// 同一个 `ZoSplitView` 内必须保持唯一。
  final Object id;

  /// 固定像素尺寸。
  ///
  /// 传入后当前面板不再参与 flex 分配，而是先占用对应的布局空间。
  final double? size;

  /// 弹性权重。
  ///
  /// 当前面板会参与剩余空间分配，值越大，占到的空间越多。
  /// 一般推荐使用相对简单的数值，如 `1`、`2`、`3`。
  final double? flex;

  /// 最小尺寸。
  ///
  /// 当面板收缩到该值时，可视为折叠状态。
  final double min;

  /// 最大尺寸。
  ///
  /// 仅限制当前面板自身的最大可扩张范围；未传时表示不限制。
  final double? max;

  /// 折叠吸附阈值。
  ///
  /// 当面板从展开态向 [min] 收缩时，会先在该值附近停顿；继续拖动后再折叠到 [min]。
  /// 当面板起始已折叠时，重新展开也会先经过该阈值，以获得更稳定的交互手感。
  final double? snapToMin;

  /// 是否自动包裹滚动容器。
  ///
  /// 启用后，当面板内容大于当前可用空间时，会自动通过内部滚动查看内容。
  final bool wrapScrollView;
}

/// 单条分割线的运行时信息。
///
/// 该对象由 `ZoSplitView` 在布局计算后生成，常用于：
/// - 自定义分割器 UI
/// - 拖拽时判断可移动范围
/// - 在示例或业务逻辑中观察当前相邻面板状态
///
/// 这是运行时对象，请勿持久化保存。
class ZoSplitViewSeparatorInfo {
  ZoSplitViewSeparatorInfo({
    required this.min,
    required this.max,
    required this.separatorSize,
    required this.prevPanel,
    required this.nextPanel,
    required this.index,
  });

  /// 分割线向左移动的最大可用距离。
  ///
  /// 该值同时受左侧可收缩空间和右侧可扩张空间共同限制。
  double min;

  /// 分割线向右移动的最大可用距离。
  ///
  /// 该值同时受右侧可收缩空间和左侧可扩张空间共同限制。
  double max;

  /// 分割线当前的交互尺寸。
  ///
  /// 通常等于 `ZoSplitView.separatorSize`，会在构建分割器时写入。
  double separatorSize;

  /// 分割线前一个面板（左侧或上方）。
  ZoSplitViewPanelInfo prevPanel;

  /// 分割线后一个面板（右侧或下方）。
  ZoSplitViewPanelInfo nextPanel;

  /// 在当前 `separators` 列表中的索引。
  int index;
}

/// 单个面板的运行时信息。
///
/// 与 [ZoSplitViewPanelConfig] 不同，这个对象表示的是“当前布局结果”：
/// - [size] / [min] / [max] 是当前时刻真正参与布局的值
/// - [collapsed] 表示当前是否已经收缩到折叠状态
/// - [prev] / [next] 便于在运行时沿链表查找相邻面板
///
/// 通常在 `builder` 中读取该对象来决定内容渲染方式，
/// 不建议在不了解内部布局规则时直接修改其字段。
class ZoSplitViewPanelInfo {
  ZoSplitViewPanelInfo({
    required this.max,
    required this.min,
    required this.size,
    required this.collapsed,
    required this.config,
  });

  /// 当前布局下允许的最大尺寸。
  ///
  /// 这是结合相邻面板可移动空间后得到的运行时值，不一定等于原始配置中的 [ZoSplitViewPanelConfig.max]。
  double max;

  /// 当前布局下允许的最小尺寸。
  ///
  /// 一般等于 [ZoSplitViewPanelConfig.min]。
  double min;

  /// 当前布局结果中的像素尺寸。
  double size;

  /// 是否处于折叠状态。
  ///
  /// 当面板尺寸等于 [min] 时为 `true`。
  bool collapsed;

  /// 当前面板是否按 fixed 模式参与布局。
  ///
  /// 判断依据是原始配置中是否提供了 `flex`。
  bool get fixed => config.flex == null;

  /// 左侧或上方相邻面板。
  ZoSplitViewPanelInfo? prev;

  /// 右侧或下方相邻面板。
  ZoSplitViewPanelInfo? next;

  /// 当前面板对应的原始配置。
  ZoSplitViewPanelConfig config;
}

/// 可拖拽调整尺寸的拆分面板容器。
///
/// `ZoSplitView` 负责：
/// - 根据 [initialConfig] 初始化一组面板
/// - 在 fixed / flex 混合模式下分配可用空间
/// - 支持分割线并处理拖拽等交互
/// - 在 `builder` 中将当前 [ZoSplitViewPanelInfo] 传给面板内容
///
/// 适用于侧边栏、工作区分栏、可折叠区域等需要用户手动调整尺寸的场景。
class ZoSplitView extends StatefulWidget {
  const ZoSplitView({
    super.key,
    required this.initialConfig,
    required this.builder,
    this.direction = Axis.horizontal,
    this.resizable = true,
    this.separatorBuilder,
    this.separatorSize = 10,
    this.separatorLayoutSize = 1,
    this.separatorColor,
    this.ref,
  });

  /// 初始面板配置。
  ///
  /// - flex 项必须连续放置, 不能被固定尺寸项分隔开
  /// - 建议至少放置一个 flex 项, 防止出现面板总尺寸小于容器尺寸的情况
  final List<ZoSplitViewPanelConfig> initialConfig;

  /// 构造面板内容。
  ///
  /// 回调会收到当前面板的运行时信息，用户可根据尺寸、折叠状态等决定如何渲染内容。
  final Widget Function(BuildContext context, ZoSplitViewPanelInfo info)
  builder;

  /// 面板排列方向。
  ///
  /// - [Axis.horizontal]：从左到右排列
  /// - [Axis.vertical]：从上到下排列
  final Axis direction;

  /// 是否允许拖动分割线调整尺寸。
  final bool resizable;

  /// 自定义分割器构建回调。
  ///
  /// 如果不传，会使用组件内置的简单线条样式。
  /// 传入后可以根据 [ZoSplitViewSeparatorInfo] 和交互状态完全自定义表现。
  final Widget Function(
    BuildContext context,
    ZoSplitViewSeparatorInfo info,
    ZoInteractiveBoxBuildArgs interactiveArgs,
  )?
  separatorBuilder;

  /// 分割线的尺寸, 根据方向会表示宽或高, 该配置影响分割器大小, 但不占用实际布局空间,
  /// 可以设置为较大的值来扩大交互区域
  final double separatorSize;

  /// 分割线占用面板实际布局空间的尺寸, 如果分割器的尺寸较大,
  /// 可以设置一个合适的值来避免面板区域和分割线重叠
  final double separatorLayoutSize;

  /// 默认的分割线颜色。
  ///
  /// 仅在未提供 [separatorBuilder] 时生效。
  final Color? separatorColor;

  /// 获取 [ZoSplitViewState] 的引用。
  ///
  /// 会在实例可用和销毁时分别回调一次，可用来在不创建 `GlobalKey` 的情况下，
  /// 操作面板实例。
  final void Function(ZoSplitViewState? state)? ref;

  @override
  State<ZoSplitView> createState() => ZoSplitViewState();
}

/// `ZoSplitView` 的状态对象。
///
/// 该对象既负责内部布局计算，也暴露了一组可供外部调用的能力：
/// - 通过 [config] 重新设置整组面板配置
/// - 通过 [getCurrentConfig] 导出当前布局快照
/// - 通过 [update] 在直接改动运行时面板后重新计算布局
///
/// 大多数业务场景下，推荐通过 `ref` 拿到该对象后，只使用 `config` 和 [getCurrentConfig]，
/// 避免直接修改 [panels]。
class ZoSplitViewState extends State<ZoSplitView> {
  /// 当前容器尺寸。
  ///
  /// 会根据 [ZoSplitView.direction] 取宽或高。
  double? containerSize;

  /// 当前布局尺寸。
  ///
  /// 当所有面板的最小尺寸之和超过容器尺寸时，该值会大于 [containerSize]，
  /// 用于驱动外层滚动容器。
  double? layoutSize;

  /// 当前所有面板理论上需要的最小布局尺寸。
  double? minLayoutSize;

  /// 面板列表
  ///
  /// 可以手动更新面板对象的 size, 然后通过 update() 来重新计算其他面板的尺寸,
  /// 这是内部用于更新面板的方式, 如果你不清楚会发生什么, 请避免这样做, 改为更新 config
  List<ZoSplitViewPanelInfo> panels = [];

  /// 当前布局下生成的分割线列表。
  List<ZoSplitViewSeparatorInfo> separators = [];

  /// 当前正在使用的输入配置。
  ///
  /// 给它重新赋值会：
  /// - 重新校验配置是否合法
  /// - 清空当前运行时布局状态
  /// - 根据新配置重新初始化并刷新界面
  late List<ZoSplitViewPanelConfig> _config;

  /// 当前正在使用的输入配置。
  ///
  /// 一般用于读取上一次设置给 `ZoSplitView` 的配置，而不是“当前拖拽后的实时布局结果”。
  List<ZoSplitViewPanelConfig> get config => _config;

  /// 设置新的输入配置并立即重建布局。
  set config(List<ZoSplitViewPanelConfig> newConfig) {
    _config = newConfig;
    _verifyCurrentConfig();

    _resetLayoutState();

    update();
    setState(() {});
  }

  /// 获取当前布局配置快照。
  ///
  /// 返回的结果可直接用于持久化，或在后续重新赋值给 [config] 以恢复当前布局：
  /// - `min` / `max` / `snapToMin` / `wrapScrollView` 等约束沿用原始配置
  /// - fixed 面板记录当前像素尺寸到 `size`
  /// - flex 面板根据当前所有 flex 面板的尺寸占比重新生成 `flex`
  ///
  /// 注意：该方法返回的是“当前布局结果”的快照，不等同于 [config]
  List<ZoSplitViewPanelConfig> getCurrentConfig() {
    if (panels.isEmpty) {
      return config;
    }

    var totalFlexSize = 0.0;

    for (final panel in panels) {
      if (panel.fixed) {
        continue;
      }

      totalFlexSize += panel.size;
    }

    return [
      for (final panel in panels)
        panel.fixed
            ? _copyPanelConfig(panel.config, size: panel.size)
            : _copyPanelConfig(
                panel.config,
                flex: ZoMathUtils.isPositive(totalFlexSize)
                    ? ZoMathUtils.normalize(panel.size / totalFlexSize)
                    : (panel.config.flex ?? 1),
              ),
    ];
  }

  /// 根据当前的 [panels] 和容器尺寸更新每个面板的实际尺寸，并更新分割线、子级信息。
  ///
  /// 如果 [panels] 还未初始化，会先根据当前 [config] 完成初始化。
  ///
  /// 典型用途：
  /// - 内部拖拽流程在修改某些面板尺寸后重新结算布局
  /// - 外部明确修改了 [panels] 中的运行时值后，手动触发一次重新计算
  ///
  /// 更推荐的外部用法仍然是直接设置 [config]；只有在需要保留部分运行时状态时，
  /// 才建议直接操作 [panels] 再调用 [update]。
  ///
  /// 尺寸更新行为：
  /// - 所有面板都会受限与其 max、min 约束
  /// - 固定尺寸会优先分配, 占用剩余空间后再分配给 flex 项
  /// - flex 面板会根据 flex 值占比分配剩余空间
  ///
  /// 该方法会直接修改 [panels] 中面板的尺寸等信息, 但不会调用 setState, 调用方需要根据实际情况决定是否需要调用 setState 来触发重绘
  void update() {
    if (_constraints == null) return;

    final constraints = _constraints!;

    containerSize = widget.direction == Axis.horizontal
        ? constraints.maxWidth
        : constraints.maxHeight;

    assert(
      containerSize != double.infinity,
      "Container size must be finite",
    );

    // 面板尚未初始化过, 初始化对象
    if (panels.isEmpty) {
      _initPanels();
    }

    final List<ZoSplitViewPanelInfo> localPanels = [...panels];

    final List<ZoSplitViewSeparatorInfo> localSeparators = [];

    minLayoutSize = 0;

    /// 固定项占用的总尺寸
    var fixedSize = 0.0;

    /// flex 项的 min 之和
    var flexMinSize = 0.0;

    /// flex 的尺寸总量
    var totalFlexSize = 0.0;

    /// 记录已计算完成的项
    final processed = HashSet<Object>();

    // 第一轮处理：计算需要的最小容器尺寸, 并处理固定尺寸项和必要的总量统计
    for (var i = 0; i < panels.length; i++) {
      final info = panels[i];
      final config = info.config;

      // 是否固定项, 正在拖动的分割线两侧面板始终视为固定项处理
      if (!_isPanelFollowable(info)) {
        final curSize = info.size.clamp(
          config.min,
          config.max ?? double.infinity,
        );

        localPanels[i] = ZoSplitViewPanelInfo(
          // max 先占位, 在后续计算出总的最小尺寸后再作调整
          max: double.infinity,
          min: config.min,
          size: curSize,
          collapsed: curSize == info.min,
          config: info.config,
        );

        fixedSize += curSize;

        processed.add(info.config.id);
      } else {
        totalFlexSize += info.size;
        flexMinSize += info.min;
      }
    }

    minLayoutSize = fixedSize + flexMinSize;

    layoutSize = math.max(containerSize!, minLayoutSize!);

    // 扣除固定项后剩余的可用尺寸
    double remainSize = layoutSize! - fixedSize;

    /// 分配 flex 项尺寸, 如果出现被 max/min 截断的项, 将其推出分配池并递归重新分配剩余空间,
    /// 直到所有项分配完毕
    void flexAllocation([skipClamp = false]) {
      var hasClamp = false;

      // 计算包含 max、min 的 flex 项尺寸
      for (var i = 0; i < panels.length; i++) {
        final cur = panels[i];
        final config = cur.config;

        // 仅 flex 和未分配项参与后续分配
        if (processed.contains(config.id) || !_isPanelFollowable(cur)) {
          continue;
        }

        // 根据比例分配剩余尺寸
        final ratio = _getFlexRatioBySize(totalFlexSize, cur.size);
        final size = remainSize * ratio;

        // 已完成处理时, 剩余项之间平分剩余空间
        if (skipClamp) {
          localPanels[i] = ZoSplitViewPanelInfo(
            // max 先占位, 在后续计算出总的最小尺寸后再作调整
            max: double.infinity,
            min: config.min,
            size: size,
            collapsed: size == config.min,
            config: config,
          );
          processed.add(config.id);
          continue;
        }

        // 如果小于最小值, 设置尺寸为最小值, 并将补齐的部分从剩余尺寸扣掉并将其推出池子
        if (size <= config.min) {
          remainSize -= config.min;
          totalFlexSize -= cur.size;

          localPanels[i] = ZoSplitViewPanelInfo(
            // max 先占位, 在后续计算出总的最小尺寸后再作调整
            max: double.infinity,
            min: config.min,
            size: config.min,
            collapsed: true,
            config: config,
          );

          processed.add(config.id);
          hasClamp = true;
        }

        // 如果大于最大值, 将超出的部分从剩余尺寸扣掉并退出池子
        if (config.max != null &&
            config.max != double.infinity &&
            size >= config.max!) {
          remainSize -= config.max!;

          // 恢复原尺寸而不是 max
          totalFlexSize -= cur.size;

          localPanels[i] = ZoSplitViewPanelInfo(
            max: config.max!,
            min: config.min,
            size: config.max!,
            collapsed: config.max == config.min,
            config: config,
          );

          processed.add(config.id);
          hasClamp = true;
        }
      }

      if (skipClamp) return;

      // 如果没有被 clamp 掉的项, 直接重新分配剩余项
      flexAllocation(!hasClamp);
    }

    flexAllocation();

    panels = localPanels;

    ZoSplitViewPanelInfo? prev;

    for (var i = 0; i < panels.length; i++) {
      final cur = localPanels[i];

      cur.prev = prev;
      prev?.next = cur;
      prev = cur;
    }

    for (var i = 0; i < panels.length; i++) {
      final info = panels[i];

      final (leftMax, rightMax) = _getSeparatorAvailableSpace(info);

      if (i != 0) {
        localSeparators.add(
          ZoSplitViewSeparatorInfo(
            min: leftMax,
            max: rightMax,
            // 在 __updateChildren 中更新
            separatorSize: 0,
            prevPanel: info.prev!,
            nextPanel: info,
            index: i - 1,
          ),
        );
      }

      info.max = info.min + leftMax + rightMax;
    }

    separators = localSeparators;

    _updateChildren();
  }

  /// 子级列表, 包含面板和分割线
  List<LayoutId> _children = [];

  /// 当前正在拖动的分割线信息
  ZoSplitViewSeparatorInfo? _draggingSeparator;

  /// 开始拖动位置
  double? _startPosition;

  /// 开始拖动时左侧如果是固定面板, 记录其尺寸
  double? _startPrevFixedSize;

  /// 开始拖动时右侧如果是固定面板, 记录其尺寸
  double? _startNextFixedSize;

  /// 最后一次拖动的移动距离
  double? _lastDragDiff;

  /// 集合中的项会被视为固定项处理。
  ///
  /// 拖动分割线时，如果左右两侧都是 flex 项，会临时把它们视为 fixed，
  /// 这样本次拖动可以直接基于起始尺寸计算，而不是被后续 flex 重分配干扰。
  final Set<Object> _forceFixedPanels = {};

  /// 当前拖动中，已“释放展开吸附”的面板集合。
  ///
  /// 用于处理这种交互：
  /// - 面板已折叠在 min
  /// - 首次往外拖动时，先吸附在 min
  /// - 越过阈值后，先跳到 snapToMin
  /// - 同一次拖动后续继续展开时，不再重复触发这次“跳到 snapToMin”
  final Set<Object> _releasedExpandSnapPanels = {};

  /// 容器尺寸限制
  BoxConstraints? _constraints;

  @override
  @protected
  void initState() {
    super.initState();

    _config = widget.initialConfig;

    _verifyCurrentConfig();

    widget.ref?.call(this);
  }

  @override
  @protected
  void dispose() {
    widget.ref?.call(null);

    super.dispose();
  }

  /// 清空基于当前配置推导出来的布局与交互状态。
  void _resetLayoutState() {
    panels.clear();
    separators.clear();
    _children.clear();

    _draggingSeparator = null;
    _startPosition = null;
    _startPrevFixedSize = null;
    _startNextFixedSize = null;
    _lastDragDiff = null;

    _forceFixedPanels.clear();
    _releasedExpandSnapPanels.clear();
  }

  ZoSplitViewPanelConfig _copyPanelConfig(
    ZoSplitViewPanelConfig source, {
    double? size,
    double? flex,
  }) {
    return ZoSplitViewPanelConfig(
      id: source.id,
      size: size,
      flex: flex,
      min: source.min,
      max: source.max,
      snapToMin: source.snapToMin,
      wrapScrollView: source.wrapScrollView,
    );
  }

  /// 验证当前 [config] 是否满足要求
  void _verifyCurrentConfig() {
    // 限制当前 config 的 flex 项必须是连续的, 不能被固定尺寸项分隔开
    //  是否已经进入过 flex 段
    var startedFlexBlock = false;
    // 是否已经离开 flex 段
    var endedFlexBlock = false;

    for (var i = 0; i < config.length; i++) {
      final cur = config[i];
      final isFlex = cur.flex != null;

      if (isFlex) {
        assert(
          !endedFlexBlock,
          "Flex panels in config must be contiguous and cannot be separated by fixed-size panels.",
        );
        startedFlexBlock = true;
      } else if (startedFlexBlock) {
        endedFlexBlock = true;
      }
    }
  }

  /// 面板是否允许在拖动时跟随移动
  bool _isPanelFollowable(ZoSplitViewPanelInfo panel) {
    if (panel.fixed) return false;

    if (_forceFixedPanels.contains(panel.config.id)) {
      return false;
    }

    return true;
  }

  /// 判断当前面板在本次拖动中是否已经释放过“从 min 展开”的吸附状态。
  bool _isSnapReleased(ZoSplitViewPanelInfo panel) {
    return _releasedExpandSnapPanels.contains(panel.config.id);
  }

  /// 标记当前面板在本次拖动中已经释放过展开吸附。
  void _markSnapReleased(ZoSplitViewPanelInfo panel) {
    _releasedExpandSnapPanels.add(panel.config.id);
  }

  /// 清除当前面板的展开吸附释放状态。
  ///
  /// 当面板重新回到 min（再次折叠）时，需要重置状态，
  /// 这样同一次拖动里再次展开时仍然能重新获得吸附效果。
  void _resetSnapReleased(ZoSplitViewPanelInfo panel) {
    _releasedExpandSnapPanels.remove(panel.config.id);
  }

  /// 处理“起始就是折叠态(min)”时的展开吸附。
  ///
  /// 行为分三段：
  /// - rawSize <= min：保持折叠，同时重置 released 状态
  /// - min < rawSize <= snapSize：仍吸附在 min，不立即展开
  /// - rawSize > snapSize：
  ///   - 若尚未释放过吸附，本次先跳到 snapSize，并标记 released
  ///   - 若已释放，则允许继续正常展开
  ///
  /// 这样可以实现“拖一小段没反应，拖过阈值后直接弹开到 snapToMin”的手感。
  double _applyCollapsedStartSnap({
    required ZoSplitViewPanelInfo panel,
    required double rawSize,
    required double snapSize,
  }) {
    if (rawSize <= panel.min) {
      _resetSnapReleased(panel);
      return panel.min;
    }

    if (!_isSnapReleased(panel)) {
      if (rawSize <= snapSize) {
        return panel.min;
      }

      _markSnapReleased(panel);
      return snapSize;
    }

    if (rawSize < snapSize) {
      return snapSize;
    }

    return rawSize;
  }

  /// 处理“当前是展开态”时向 min 收缩的吸附。
  ///
  /// 行为分三段：
  /// - rawSize >= snapSize：正常收缩
  /// - min < rawSize < snapSize：吸附在 snapSize，形成停顿感
  /// - rawSize <= min：直接折叠到 min
  double _applyShrinkSnap({
    required ZoSplitViewPanelInfo panel,
    required double rawSize,
    required double snapSize,
  }) {
    if (rawSize >= snapSize) {
      return rawSize;
    }

    if (rawSize <= panel.min) {
      return panel.min;
    }

    return snapSize;
  }

  /// 对设置了 snapToMinSize 的面板应用吸附逻辑：
  ///
  /// 这里统一处理两类场景：
  /// 1. 起始已折叠：展开时先吸附在 min，越过阈值后跳到 snapToMin
  /// 2. 起始未折叠：收缩时先吸附在 snapToMin，继续拖动后折叠到 min
  ///
  /// 参数说明：
  /// - startSize：本次拖动开始时该面板的尺寸，用于判断“起始是否已折叠”
  /// - rawSize：本次拖动按原始位移计算出的理论尺寸
  ///
  /// 返回值不是最终布局结果，而是“吸附修正后的目标尺寸”，
  /// 调用方会再把它换算回 effectiveDiff。
  double _applySnapToMinSize({
    required ZoSplitViewPanelInfo panel,
    required double startSize,
    required double rawSize,
  }) {
    final snapSize = panel.config.snapToMin;

    if (snapSize == null || snapSize <= panel.min) {
      return rawSize;
    }

    final startsCollapsed = startSize <= panel.min;

    if (startsCollapsed) {
      return _applyCollapsedStartSnap(
        panel: panel,
        rawSize: rawSize,
        snapSize: snapSize,
      );
    }

    if (rawSize > startSize) {
      return rawSize;
    }

    return _applyShrinkSnap(
      panel: panel,
      rawSize: rawSize,
      snapSize: snapSize,
    );
  }

  /// 更新拖动期间的临时 fixed 锁定。
  ///
  /// 当分割线两侧都是 flex 项时，如果不临时锁定，
  /// `_update()` 里的 flex 重分配会让拖动反馈变得不稳定。
  /// 这里将分割线两侧面板临时视为 fixed，本次拖动结束后再恢复。
  void _updateDragLocks(
    ZoSplitViewPanelInfo prev,
    ZoSplitViewPanelInfo next,
  ) {
    _forceFixedPanels.clear();

    if (!prev.fixed && !next.fixed) {
      _forceFixedPanels.add(prev.config.id);
      _forceFixedPanels.add(next.config.id);
    }
  }

  /// 根据原始拖动位移计算真正应生效的位移。
  ///
  /// 之所以不直接使用 rawDiff，是因为某一侧面板可能触发了 snapToMin：
  /// - 收缩侧可能被吸附在 snapToMin 或 min
  /// - 已折叠侧在重新展开时，也可能先吸附在 min / snapToMin
  ///
  /// 因此这里会先把 rawDiff 换算为左右面板的理论尺寸，
  /// 再用 `_applySnapToMinSize()` 修正目标尺寸，
  /// 最后反推出真正应采用的 effectiveDiff。
  ///
  /// 优先级：
  /// - 向右拖(rawDiff > 0)：优先检查左侧(prev)是否触发展开吸附，再看右侧(next)收缩吸附
  /// - 向左拖(rawDiff < 0)：优先检查右侧(next)是否触发展开吸附，再看左侧(prev)收缩吸附
  ///
  /// 这样可以保证“从折叠态重新拖开”时，增长侧也能获得吸附效果。
  double _resolveEffectiveDiff({
    required double rawDiff,
    required ZoSplitViewPanelInfo prev,
    required ZoSplitViewPanelInfo next,
  }) {
    var effectiveDiff = rawDiff;

    if (rawDiff > 0) {
      if (_startPrevFixedSize != null) {
        final snappedPrevSize = _applySnapToMinSize(
          panel: prev,
          startSize: _startPrevFixedSize!,
          rawSize: _startPrevFixedSize! + rawDiff,
        );

        effectiveDiff = snappedPrevSize - _startPrevFixedSize!;
      }

      if (effectiveDiff == rawDiff && _startNextFixedSize != null) {
        final snappedNextSize = _applySnapToMinSize(
          panel: next,
          startSize: _startNextFixedSize!,
          rawSize: _startNextFixedSize! - rawDiff,
        );

        effectiveDiff = _startNextFixedSize! - snappedNextSize;
      }
    } else if (rawDiff < 0) {
      if (_startNextFixedSize != null) {
        final snappedNextSize = _applySnapToMinSize(
          panel: next,
          startSize: _startNextFixedSize!,
          rawSize: _startNextFixedSize! - rawDiff,
        );

        effectiveDiff = _startNextFixedSize! - snappedNextSize;
      }

      if (effectiveDiff == rawDiff && _startPrevFixedSize != null) {
        final snappedPrevSize = _applySnapToMinSize(
          panel: prev,
          startSize: _startPrevFixedSize!,
          rawSize: _startPrevFixedSize! + rawDiff,
        );

        effectiveDiff = snappedPrevSize - _startPrevFixedSize!;
      }
    }

    return effectiveDiff;
  }

  /// 拖动处理
  ///
  /// - 面板尺寸更新逻辑：判断对应方向是否可用, 面板同向放大, 逆向缩小
  ///   - 如果任意一侧存在固定尺寸的项, 只需更新固定项, 其余项在 [update] 中自动计算尺寸
  ///   - 如果只存在 flex 项, 将两侧都视为固定项处理, 直接更新尺寸, 其余项在 [update] 中自动计算尺寸
  void _onDrag(ZoTriggerDragEvent event) {
    if (!widget.resizable) {
      return;
    }

    final info = event.data as ZoSplitViewSeparatorInfo;
    final prev = info.prevPanel;
    final next = info.nextPanel;

    // 通过开始位置 + 移动距离来计算当前分割线的位置, 这能保证分割线位置始终和光标位置保持一致
    final position = widget.direction == Axis.horizontal
        ? event.position.dx
        : event.position.dy;

    // 保存开始时的位置、尺寸信息
    if (event.first) {
      _startPosition = position;
      _draggingSeparator = info;
      _releasedExpandSnapPanels.clear();

      _startPrevFixedSize = prev.size;
      _startNextFixedSize = next.size;
    }

    final rawDiff = (position - _startPosition!).clamp(
      -_draggingSeparator!.min,
      _draggingSeparator!.max,
    );

    _updateDragLocks(prev, next);

    final effectiveDiff = _resolveEffectiveDiff(
      rawDiff: rawDiff,
      prev: prev,
      next: next,
    );

    if (effectiveDiff != _lastDragDiff) {
      // 避免直接更新 flex 项
      final prevLock = !_isPanelFollowable(prev);
      final nextLock = !_isPanelFollowable(next);

      if (_startPrevFixedSize != null && prevLock) {
        prev.size = _startPrevFixedSize! + effectiveDiff;
      }

      if (_startNextFixedSize != null && nextLock) {
        next.size = _startNextFixedSize! - effectiveDiff;
      }

      update();

      // 避免和结束时的更新冗余
      if (!event.last) {
        setState(() {});
      }
      _lastDragDiff = effectiveDiff;
    }

    final freshInfo = separators.elementAtOrNull(info.index) ?? info;

    ZoGlobalCursor.show(_getCursorBySeparator(freshInfo), true);

    if (event.last) {
      _startPosition = null;
      _draggingSeparator = null;
      _startPrevFixedSize = null;
      _startNextFixedSize = null;
      _lastDragDiff = null;
      _forceFixedPanels.clear();
      _releasedExpandSnapPanels.clear();

      ZoGlobalCursor.hide();

      // 开始状态被清理后, 统一更新一次面板
      update();
      setState(() {});
    }
  }

  /// 构造分割器
  Widget _buildSeparator(ZoInteractiveBoxBuildArgs args) {
    final style = context.zoStyle;
    final info = args.data as ZoSplitViewSeparatorInfo;

    final isCollapsed = info.prevPanel.collapsed || info.nextPanel.collapsed;

    final isActive = args.active;
    final double lineSize = isActive ? 5 : 2;

    final separator = widget.separatorBuilder != null
        ? widget.separatorBuilder!(context, info, args)
        : Container(
            color: isCollapsed
                ? Colors.red
                : isActive
                ? style.primaryColor
                : widget.separatorColor ?? style.outlineColor,
            width: widget.direction == Axis.horizontal ? lineSize : null,
            height: widget.direction == Axis.horizontal ? null : lineSize,
          );

    final size = widget.separatorSize;

    info.separatorSize = size;

    return SizedBox(
      width: widget.direction == Axis.horizontal ? size : null,
      height: widget.direction == Axis.horizontal ? null : size,
      child: Align(
        alignment: Alignment.center,
        child: separator,
      ),
    );
  }

  /// 更新面板子级
  void _updateChildren() {
    if (panels.isEmpty) {
      _children = [];
      return;
    }

    final List<LayoutId> children = [];

    // 所有分割器, 放到数组最后, 以免被面板遮挡
    final List<LayoutId> separators = [];

    for (var i = 0; i < panels.length; i++) {
      final info = panels[i];

      var child = widget.builder(context, info);

      if (info.config.wrapScrollView) {
        child = _ScrollableWrapper(
          direction: widget.direction,
          child: child,
        );
      }

      child = RepaintBoundary(
        child: child,
      );

      if (widget.separatorLayoutSize > 0 && _config.length > 1) {
        final separatorSize = widget.separatorLayoutSize;
        final half = separatorSize / 2;

        EdgeInsetsGeometry padding = widget.direction == Axis.horizontal
            ? EdgeInsets.symmetric(horizontal: half)
            : EdgeInsets.symmetric(vertical: half);

        if (i == 0) {
          padding = widget.direction == Axis.horizontal
              ? EdgeInsets.only(right: half)
              : EdgeInsets.only(bottom: half);
        } else if (i == panels.length - 1) {
          padding = widget.direction == Axis.horizontal
              ? EdgeInsets.only(left: half)
              : EdgeInsets.only(top: half);
        }

        child = Padding(
          padding: padding,
          child: child,
        );
      }

      children.add(
        LayoutId(
          id: info.config.id,
          key: ValueKey(info.config.id),
          child: child,
        ),
      );
    }

    for (var i = 0; i < this.separators.length; i++) {
      final info = this.separators[i];

      final id = _getSplitID(i + 1);

      final separatorChild = ZoInteractiveBox(
        data: info,
        enableColorEffect: false,
        canRequestFocus: false,
        padding: const EdgeInsets.all(0),
        alignment: Alignment.center,
        changeCursor: false,
        cursors: {
          ZoTriggerCursorType.normal: _getCursorBySeparator(info),
        },
        onDrag: widget.resizable ? _onDrag : null,
        builder: _buildSeparator,
      );

      separators.add(
        LayoutId(
          id: id,
          key: ValueKey(id),
          child: separatorChild,
        ),
      );
    }

    children.addAll(separators);

    _children = children;
  }

  void _initPanels() {
    double totalFlex = 0;
    double explicitFixedSize = 0;
    int autoFixedCount = 0;

    for (var i = 0; i < _config.length; i++) {
      final cur = _config[i];

      if (cur.flex != null) {
        totalFlex += cur.flex ?? 1;
      } else if (cur.size != null) {
        explicitFixedSize += cur.size!;
      } else {
        autoFixedCount++;
      }

      panels.add(
        // 填入初始 panel 信息, 后续会根据实际容器尺寸进行调整
        ZoSplitViewPanelInfo(
          max: cur.max ?? double.infinity,
          min: cur.min,
          size: cur.size ?? 0,
          collapsed: false,
          config: cur,
        ),
      );
    }

    final remainSize = math.max(0.0, containerSize! - explicitFixedSize);
    final totalUnits = autoFixedCount + totalFlex;

    if (totalUnits == 0) {
      return;
    }

    final unitSize = remainSize / totalUnits;

    // 未传 size 的 fixed 项平均分配剩余空间, flex 项按权重分配剩余空间。
    // 这里不要求最终像素精确, 只需提供合理初始值供后续 _update 继续收敛。
    for (var i = 0; i < panels.length; i++) {
      final info = panels[i];

      if (info.fixed) {
        if (info.config.size == null) {
          info.size = unitSize;
        }
      } else {
        info.size = unitSize * (info.config.flex ?? 1);
      }
    }
  }

  /// 获取左侧分割线左右的可移动空间, 按以下规则获取：
  ///
  /// - 匹配项：分割线左右首个项和后续的 flex 项
  /// - 获取这些项的 min, 该方向的总尺寸减 min 之和为可移动距离
  /// - 同样方式获取这些项的 max 之和, 作为相反方向可移动距离的限制, 例如
  /// 右侧可移动 100, 但左侧最大值为 50, 则右侧只能移动 50
  ///
  /// 根据返回值获取传入面板的最大值： 左右之和 + 当前面板最小尺寸
  (double, double) _getSeparatorAvailableSpace(ZoSplitViewPanelInfo info) {
    // 第一个面板不存在分割线
    if (info.prev == null) return (0, 0);

    ({double min, double max, double size}) collect(
      ZoSplitViewPanelInfo? start,
      bool isPrev,
    ) {
      if (start == null) {
        return (min: 0, max: 0, size: 0);
      }

      var min = 0.0;
      var max = 0.0;
      var size = 0.0;

      // 首项固定获取
      ZoSplitViewPanelInfo? cur = start;

      while (cur != null) {
        final config = cur.config;

        min += config.min;

        // 任意一项未设置有限的 max, 就将 max 视为无限
        if (config.max != null &&
            size != double.infinity &&
            config.max != double.infinity) {
          max += config.max!;
        } else {
          max = double.infinity;
        }

        size += cur.size;

        final next = isPrev ? cur.prev : cur.next;

        // 只继续获取后续连续的 flex 项
        if (next == null || !_isPanelFollowable(next)) {
          break;
        }

        cur = next;
      }

      return (min: min, max: max, size: size);
    }

    // 左侧从前一面板开始，向左收集
    final left = collect(info.prev, true);

    // 右侧从当前面板开始，向右收集
    final right = collect(info, false);

    // 分割线向左移动：左侧缩小 + 右侧放大
    final leftShrink = math.max(0.0, left.size - left.min);
    final rightGrow = math.max(0.0, right.max - right.size);
    final moveLeft = math.min(leftShrink, rightGrow);

    // 分割线向右移动：左侧放大 + 右侧缩小
    final leftGrow = math.max(0.0, left.max - left.size);
    final rightShrink = math.max(0.0, right.size - right.min);
    final moveRight = math.min(leftGrow, rightShrink);

    return (
      ZoMathUtils.normalize(moveLeft),
      ZoMathUtils.normalize(moveRight),
    );
  }

  /// 根据分割线信息获取当前应该显示的鼠标样式
  MouseCursor _getCursorBySeparator(ZoSplitViewSeparatorInfo info) {
    if (!widget.resizable) {
      return MouseCursor.defer;
    }

    final leftDraggable = ZoMathUtils.isPositive(info.min);
    final rightDraggable = ZoMathUtils.isPositive(info.max);

    if (leftDraggable && rightDraggable) {
      return widget.direction == Axis.horizontal
          ? SystemMouseCursors.resizeLeftRight
          : SystemMouseCursors.resizeUpDown;
    } else if (leftDraggable) {
      return widget.direction == Axis.horizontal
          ? SystemMouseCursors.resizeLeft
          : SystemMouseCursors.resizeUp;
    } else if (rightDraggable) {
      return widget.direction == Axis.horizontal
          ? SystemMouseCursors.resizeRight
          : SystemMouseCursors.resizeDown;
    } else {
      return SystemMouseCursors.forbidden;
    }
  }

  /// 根据总尺寸和给定尺寸获取其 flex 系数
  double _getFlexRatioBySize(double totalFlexSize, double size) {
    if (!ZoMathUtils.isPositive(totalFlexSize)) {
      return 1;
    }

    final ratio = size / totalFlexSize;
    return ZoMathUtils.normalize(ratio);
  }

  @override
  @protected
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_constraints == null || _constraints != constraints) {
          _constraints = constraints;

          update();
        } else {
          _constraints = constraints;
        }

        return _ScrollableWrapper(
          direction: widget.direction,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: widget.direction == Axis.horizontal
                  ? layoutSize!
                  : constraints.maxWidth,
              maxHeight: widget.direction == Axis.horizontal
                  ? constraints.maxHeight
                  : layoutSize!,
            ),
            child: CustomMultiChildLayout(
              delegate: _LayoutDelegate(
                direction: widget.direction,
                panels: panels,
                separators: separators,
              ),
              children: _children,
            ),
          ),
        );
      },
    );
  }
}

class _ScrollableWrapper extends StatefulWidget {
  final Widget child;
  final Axis direction;

  const _ScrollableWrapper({
    super.key,
    required this.child,
    required this.direction,
  });

  @override
  State<_ScrollableWrapper> createState() => _ScrollableWrapperState();
}

class _ScrollableWrapperState extends State<_ScrollableWrapper> {
  final ScrollController _localController = ScrollController();

  @override
  void dispose() {
    _localController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Scrollbar(
          controller: _localController,
          child: SingleChildScrollView(
            controller: _localController,
            scrollDirection: widget.direction,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: widget.direction == Axis.vertical
                    ? constraints.maxHeight
                    : 0,
                minWidth: widget.direction == Axis.horizontal
                    ? constraints.maxWidth
                    : 0,
              ),
              child: widget.child,
            ),
          ),
        );
      },
    );
  }
}

/// 根据配置对子级进行布局
class _LayoutDelegate extends MultiChildLayoutDelegate {
  _LayoutDelegate({
    required this.direction,
    required this.panels,
    required this.separators,
  });

  /// 方向
  final Axis direction;

  /// 面板列表
  final List<ZoSplitViewPanelInfo> panels;

  /// 分割线列表
  final List<ZoSplitViewSeparatorInfo> separators;

  @override
  void performLayout(Size size) {
    var offset = 0.0;

    final isHorizontal = direction == Axis.horizontal;

    for (var i = 0; i < panels.length; i++) {
      final info = panels[i];
      final cur = info.config;

      if (!hasChild(cur.id)) continue;

      final roundSize = info.size;

      // 计算子级尺寸并布局
      final childSize = layoutChild(
        cur.id,
        BoxConstraints.tight(
          Size(
            isHorizontal ? roundSize : size.width,
            isHorizontal ? size.height : roundSize,
          ),
        ),
      );

      positionChild(
        cur.id,
        Offset(
          isHorizontal ? offset : 0,
          isHorizontal ? 0 : offset,
        ),
      );

      if (i != 0) {
        final info = separators[i - 1];
        final lineID = _getSplitID(i);

        layoutChild(
          lineID,
          BoxConstraints.tight(
            Size(
              isHorizontal ? info.separatorSize : size.width,
              isHorizontal ? size.height : info.separatorSize,
            ),
          ),
        );

        final half = info.separatorSize / 2;

        positionChild(
          lineID,
          Offset(
            isHorizontal ? offset - half : 0,
            isHorizontal ? 0 : offset - half,
          ),
        );
      }

      offset += isHorizontal ? childSize.width : childSize.height;
    }
  }

  @override
  bool shouldRelayout(_LayoutDelegate oldDelegate) {
    final update =
        oldDelegate.panels != panels ||
        oldDelegate.separators != separators ||
        oldDelegate.direction != direction;
    return update;
  }
}

String _getSplitID(int index) {
  return "SPLIT_$index";
}

import "dart:collection";
import "dart:math" as math;
import "package:flutter/material.dart";
import "package:zo/zo.dart";

/// 表示单个面板配置
///
/// 分割器相关的配置表示的是面板左侧的分割器
class ZoSplitViewPanelConfig {
  ZoSplitViewPanelConfig({
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

  /// 用于标识当前面板的唯一值
  final Object id;

  /// 绝对尺寸
  double? size;

  /// 弹性尺寸, 默认为 1
  final double? flex;

  /// 最小尺寸, 面板等于改值时可视为折叠状态
  final double min;

  /// 最大尺寸
  final double? max;

  /// 容器被拖动小于该尺寸时, 会先停顿一段距离, 继续向前拖动时, 会直接折叠到 [min] 尺寸
  final double? snapToMin;

  /// 是否添加滚动容器, 使面板过小时能进行滚动查看
  final bool wrapScrollView;
}

/// 分割线相关信息
class ZoSplitViewSeparatorInfo {
  ZoSplitViewSeparatorInfo({
    required this.min,
    required this.max,
    required this.separatorSize,
    required this.prevPanel,
    required this.nextPanel,
  });

  /// 左侧最大可用距离
  double min;

  /// 右侧最大可用距离
  double max;

  /// 分割线尺寸
  double separatorSize;

  /// 前方面板
  ZoSplitViewPanelInfo prevPanel;

  /// 后方面板
  ZoSplitViewPanelInfo nextPanel;
}

/// 面板的活动尺寸信息
class ZoSplitViewPanelInfo {
  ZoSplitViewPanelInfo({
    required this.max,
    required this.min,
    required this.size,
    required this.collapsed,
    required this.config,
  });

  /// 面板不可大于此尺寸
  double max;

  /// 面板不可小于此尺寸
  double min;

  /// 面板像素尺寸
  double size;

  /// 是否折叠, 即尺寸等于 min
  bool collapsed;

  /// 是否是固定尺寸的面板
  bool get fixed => config.flex == null;

  /// 左侧相邻面板信息
  ZoSplitViewPanelInfo? prev;

  /// 右侧相邻面板信息
  ZoSplitViewPanelInfo? next;

  /// 面板对应的配置
  ZoSplitViewPanelConfig config;
}

/// 渲染一组支持调整尺寸的拆分面板, 通过 [value] / [onChanged] 来像表单控件一样配置面板,
/// 并在 [builder] 中进行实际的渲染
class ZoSplitView extends StatefulWidget {
  const ZoSplitView({
    super.key,
    required this.initialConfig,
    required this.builder,
    this.direction = Axis.horizontal,
    this.enableDoubleTap = true,
    this.resizable = true,
    this.separatorBuilder,
    this.separatorSize = 10,
    this.separatorLayoutSize = 10,
    this.separatorColor,
    this.ref,
  });

  /// 面板配置, 包含以下限制
  ///
  /// - flex 项必须连续放置, 不能被固定尺寸项分隔开
  /// - 建议至少放置一个 flex 项, 防止出现面板总尺寸小于容器尺寸的情况
  final List<ZoSplitViewPanelConfig> initialConfig;

  /// 构造面板内容
  ///
  /// 用户可根据面板尺寸等信息决定是否需要挂载内容
  final Widget Function(BuildContext context, ZoSplitViewPanelInfo info)
  builder;

  /// 方向
  final Axis direction;

  /// 启用双击行为, 双击分割线时, 会重置面板大小
  final bool enableDoubleTap;

  /// 是否可调整尺寸
  final bool resizable;

  /// 自定义分割器
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

  /// 默认的分割线颜色
  final Color? separatorColor;

  /// 获取 state 的引用, 会在实例可用、销毁时调用，可用来便捷的访问 state 而无需创建 globalKey
  final void Function(ZoSplitViewState? state)? ref;

  @override
  State<ZoSplitView> createState() => ZoSplitViewState();
}

class ZoSplitViewState extends State<ZoSplitView> {
  /// 容器尺寸
  double? containerSize;

  /// 布局尺寸, 大于或等于容器尺寸
  double? layoutSize;

  /// 需要的最小布局尺寸
  double? minLayoutSize;

  /// 面板列表
  List<ZoSplitViewPanelInfo> _panels = [];

  /// 分割线列表
  List<ZoSplitViewSeparatorInfo> _separators = [];

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

    // 限制 initialConfig 的 flex 项必须是连续的, 不能被固定尺寸项分隔开
    //  是否已经进入过 flex 段
    var startedFlexBlock = false;
    // 是否已经离开 flex 段
    var endedFlexBlock = false;

    for (var i = 0; i < widget.initialConfig.length; i++) {
      final config = widget.initialConfig[i];
      final isFlex = config.flex != null;

      if (isFlex) {
        assert(
          !endedFlexBlock,
          "Flex panels in initialConfig must be contiguous and cannot be separated by fixed-size panels.",
        );
        startedFlexBlock = true;
      } else if (startedFlexBlock) {
        endedFlexBlock = true;
      }
    }

    widget.ref?.call(this);
  }

  @override
  @protected
  void dispose() {
    widget.ref?.call(null);

    super.dispose();
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
  ///   - 如果任意一侧存在固定尺寸的项, 只需更新固定项, 其余项在 [_update] 中自动计算尺寸
  ///   - 如果只存在 flex 项, 将两侧都视为固定项处理, 直接更新尺寸, 其余项在 [_update] 中自动计算尺寸
  void _onDrag(ZoTriggerDragEvent event) {
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

      _update();

      // 避免和结束时的更新冗余
      if (!event.last) {
        setState(() {});
      }
      _lastDragDiff = effectiveDiff;
    }

    if (event.last) {
      _startPosition = null;
      _draggingSeparator = null;
      _startPrevFixedSize = null;
      _startNextFixedSize = null;
      _lastDragDiff = null;
      _forceFixedPanels.clear();
      _releasedExpandSnapPanels.clear();

      // 开始状态被清理后, 统一更新一次面板
      _update();
      setState(() {});
    }
  }

  /// 构造分割器
  Widget _buildSeparator(ZoInteractiveBoxBuildArgs args) {
    final style = context.zoStyle;
    final info = args.data as ZoSplitViewSeparatorInfo;

    final isActive = args.active;
    final double lineSize = isActive ? 5 : 2;

    final separator = widget.separatorBuilder != null
        ? widget.separatorBuilder!(context, info, args)
        : Container(
            color: isActive
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
    if (_panels.isEmpty) {
      _children = [];
      return;
    }

    final List<LayoutId> children = [];

    // 所有分割器, 放到数组最后, 以免被面板遮挡
    final List<LayoutId> separators = [];

    for (var i = 0; i < _panels.length; i++) {
      final info = _panels[i];

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

      if (widget.separatorLayoutSize > 0 && widget.initialConfig.length > 1) {
        final separatorSize = widget.separatorLayoutSize;
        final half = separatorSize / 2;

        EdgeInsetsGeometry padding = widget.direction == Axis.horizontal
            ? EdgeInsets.symmetric(horizontal: half)
            : EdgeInsets.symmetric(vertical: half);

        if (i == 0) {
          padding = widget.direction == Axis.horizontal
              ? EdgeInsets.only(right: half)
              : EdgeInsets.only(bottom: half);
        } else if (i == _panels.length - 1) {
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

    for (var i = 0; i < _separators.length; i++) {
      final info = _separators[i];

      final id = _getSplitID(i + 1);

      final separatorChild = ZoInteractiveBox(
        data: info,
        enableColorEffect: false,
        canRequestFocus: false,
        padding: const EdgeInsets.all(0),
        alignment: Alignment.center,
        changeCursor: false,
        cursors: const {
          ZoTriggerCursorType.normal: SystemMouseCursors.resizeLeftRight,
        },
        onDrag: _onDrag,
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

  void initPanels() {
    double totalFlex = 0;
    double explicitFixedSize = 0;
    int autoFixedCount = 0;

    for (var i = 0; i < widget.initialConfig.length; i++) {
      final cur = widget.initialConfig[i];

      if (cur.flex != null) {
        totalFlex += cur.flex ?? 1;
      } else if (cur.size != null) {
        explicitFixedSize += cur.size!;
      } else {
        autoFixedCount++;
      }

      _panels.add(
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
    for (var i = 0; i < _panels.length; i++) {
      final info = _panels[i];

      if (info.fixed) {
        if (info.config.size == null) {
          info.size = unitSize;
        }
      } else {
        info.size = unitSize * (info.config.flex ?? 1);
      }
    }
  }

  /// 根据当前的面板 ZoSplitViewPanelInfo 数组和容器尺寸计算每个面板的实际尺寸, 并更新分割线、子级信息
  void _update() {
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
    if (_panels.isEmpty) {
      initPanels();
    }

    final List<ZoSplitViewPanelInfo> panels = [..._panels];

    final List<ZoSplitViewSeparatorInfo> separators = [];

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
    for (var i = 0; i < _panels.length; i++) {
      final info = _panels[i];
      final config = info.config;

      // 是否固定项, 正在拖动的分割线两侧面板始终视为固定项处理
      if (!_isPanelFollowable(info)) {
        final curSize = info.size.clamp(
          config.min,
          config.max ?? double.infinity,
        );

        panels[i] = ZoSplitViewPanelInfo(
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
      for (var i = 0; i < _panels.length; i++) {
        final cur = _panels[i];
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
          panels[i] = ZoSplitViewPanelInfo(
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

          panels[i] = ZoSplitViewPanelInfo(
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

          panels[i] = ZoSplitViewPanelInfo(
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

    _panels = panels;

    ZoSplitViewPanelInfo? prev;

    for (var i = 0; i < _panels.length; i++) {
      final cur = panels[i];

      cur.prev = prev;
      prev?.next = cur;
      prev = cur;
    }

    for (var i = 0; i < _panels.length; i++) {
      final info = _panels[i];

      final (leftMax, rightMax) = _getSeparatorAvailableSpace(info);

      if (i != 0) {
        separators.add(
          ZoSplitViewSeparatorInfo(
            min: leftMax,
            max: rightMax,
            // 在 __updateChildren 中更新
            separatorSize: 0,
            prevPanel: info.prev!,
            nextPanel: info,
          ),
        );
      }

      info.max = info.min + leftMax + rightMax;
    }

    _separators = separators;

    _updateChildren();
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

    return (moveLeft, moveRight);
  }

  /// 根据总尺寸和给定尺寸获取其 flex 系数
  double _getFlexRatioBySize(double totalFlexSize, double size) {
    if (totalFlexSize == 0) {
      return 1;
    }
    return size / totalFlexSize;
  }

  @override
  @protected
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (_constraints == null || _constraints != constraints) {
          _constraints = constraints;

          _update();
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
                panels: _panels,
                separators: _separators,
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

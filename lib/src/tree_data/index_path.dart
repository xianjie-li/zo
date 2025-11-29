part of "tree_data.dart";

/// 树形数据中的索引路径
typedef ZoIndexPath = List<int>;

/// 提供处理 [ZoIndexPath] 的一些工具方法
abstract class ZoIndexPathHelper {
  /// 获取 [ZoIndexPath] 的字符串表示
  static String stringify(ZoIndexPath path) {
    if (path.isEmpty) return "";
    if (path.length == 1) return "${path.first}";

    var str = "";

    for (var i = 0; i < path.length; i++) {
      final it = path[i];
      str += "$it${i == path.length - 1 ? "" : ","}";
    }

    return str;
  }

  /// 比较两个 path 的前后关系
  static int compareTo(ZoIndexPath path, ZoIndexPath path2) {
    if (path == path2) return 0;

    final int minLength = path.length < path2.length
        ? path.length
        : path2.length;

    for (int i = 0; i < minLength; i++) {
      final int comparison = path[i].compareTo(path2[i]);
      if (comparison != 0) {
        return comparison; // 一旦找到不同的元素，就返回比较结果
      }
    }

    // 如果前面部分相同，则较短的 Path 排在前面
    return path.length.compareTo(path2.length);
  }

  /// 移除重叠路径 (去重 & 保留祖先)
  ///
  /// 规则：
  /// 1. 如果列表中同时存在父节点和子节点 (如 `[0]` 和 `[0, 1]`)，只保留父节点 (`[0]`)。
  /// 2. 如果存在完全相同的路径，去重保留一个。
  /// 3. 返回一个新的列表，且已排序。
  static List<ZoIndexPath> removeOverlaps(List<ZoIndexPath> paths) {
    if (paths.isEmpty) return [];
    if (paths.length == 1) return List.from(paths);

    // 1. 先排序 (这样父节点一定在子节点前面)
    // 为了不修改原数组，先复制一份
    final sortedPaths = List<ZoIndexPath>.from(paths)..sort(compareTo);

    final List<ZoIndexPath> result = [];
    ZoIndexPath? lastKeep;

    for (final current in sortedPaths) {
      // 如果还没有保留任何节点，直接添加
      if (lastKeep == null) {
        result.add(current);
        lastKeep = current;
        continue;
      }

      // 2. 检查当前节点是否是上一个保留节点的“子孙”或“相同”
      // 因为已排序，所以只需要跟 result 中最后一个比较即可
      if (_isDescendantOrSame(parent: lastKeep, child: current)) {
        // 是子孙节点或重复节点，跳过（即移除）
        continue;
      }

      // 是无关的新节点，保留
      result.add(current);
      lastKeep = current;
    }

    return result;
  }

  /// 按相邻连续的兄弟节点分组
  ///
  /// 规则：
  /// 1. 拥有相同父节点
  /// 2. 索引必须连续。例如 `[0, 1]` 和 `[0, 2]` 会分一组，但 `[0, 1]` 和 `[0, 3]` 会分两组。
  static List<List<ZoIndexPath>> groupByConsecutiveSibling(
    List<ZoIndexPath> paths,
  ) {
    if (paths.isEmpty) return [];

    // 1. 先排序 (这是基础，确保如果存在连续节点，它们物理上也是挨着的)
    final sortedPaths = List<ZoIndexPath>.from(paths)..sort(compareTo);

    final List<List<ZoIndexPath>> groups = [];
    List<ZoIndexPath> currentGroup = [];

    for (final path in sortedPaths) {
      if (currentGroup.isEmpty) {
        currentGroup.add(path);
        continue;
      }

      // 获取当前组里最后一个元素
      final lastPath = currentGroup.last;

      // 2. 检查是否是"连续"的兄弟
      if (_isConsecutiveSibling(lastPath, path)) {
        currentGroup.add(path);
      } else {
        // 不连续（或者是兄弟但中间断层了），封存当前组，开启新组
        groups.add(currentGroup);
        currentGroup = [path];
      }
    }

    // 添加最后一组
    if (currentGroup.isNotEmpty) {
      groups.add(currentGroup);
    }

    return groups;
  }

  /// 判断 [child] 是否是 [parent] 的后代（或是同一个）
  /// 例如: parent=[0], child=[0, 1] -> true
  static bool _isDescendantOrSame({
    required ZoIndexPath parent,
    required ZoIndexPath child,
  }) {
    // 子节点长度必须 >= 父节点
    if (child.length < parent.length) return false;

    // 检查前缀是否完全一致
    for (var i = 0; i < parent.length; i++) {
      if (parent[i] != child[i]) return false;
    }
    return true;
  }

  /// 判断 [b] 是否是 [a] 的**连续**兄弟节点
  ///
  /// 前提：列表已排序，[b] 肯定在 [a] 后面
  static bool _isConsecutiveSibling(ZoIndexPath a, ZoIndexPath b) {
    // 基础检查
    if (a.isEmpty || b.isEmpty) return false;
    if (a.length != b.length) return false;

    // 关键逻辑：检查索引是否连续
    // 因为已排序，所以只需要检查 b 的尾数是否等于 a 的尾数 + 1
    if (b.last != a.last + 1) return false;

    // 检查父路径（前缀）是否完全一致
    for (var i = 0; i < a.length - 1; i++) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }
}

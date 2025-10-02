/// 树形组件，使用two_dimensional_scrollables作为底层组件，通过 [ZoOptionController] 管理选项和选中信息等，
///
/// options 在初始化和变更时需要同步到 [ZoOptionController] 后，需要同时构造对应的 [TreeViewNode] 结构并缓存
///
/// 组件尺寸：使用父级允许的最大尺寸
library;

import "package:flutter/material.dart";

/// 树形组件
class ZoTree extends StatefulWidget {
  const ZoTree({super.key});

  @override
  State<ZoTree> createState() => _ZoTreeState();
}

class _ZoTreeState extends State<ZoTree> {
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}

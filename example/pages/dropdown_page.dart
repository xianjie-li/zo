import "package:flutter/material.dart";
import "package:zo/zo.dart";

class DropdownPage extends StatefulWidget {
  const DropdownPage({super.key});

  @override
  State<DropdownPage> createState() => _DropdownPageState();
}

class _DropdownPageState extends State<DropdownPage> {
  final FocusNode _focusOpenNode = FocusNode();

  late final List<ZoOption> _fruitOptions = [
    ZoOption(value: "apple", title: const Text("Apple")),
    ZoOption(value: "banana", title: const Text("Banana")),
    ZoOption(value: "orange", title: const Text("Orange")),
    ZoOption(value: "grape", title: const Text("Grape")),
  ];

  late final List<ZoOption> _treeOptions = [
    ZoOption(
      value: "fruits",
      title: const Text("水果"),
      children: [
        ZoOption(value: "apple", title: const Text("Apple")),
        ZoOption(value: "banana", title: const Text("Banana")),
      ],
    ),
    ZoOption(
      value: "drink",
      title: const Text("饮品"),
      children: [
        ZoOption(value: "coffee", title: const Text("Coffee")),
        ZoOption(value: "tea", title: const Text("Tea")),
      ],
    ),
  ];

  Iterable<Object> _single = const [];
  Iterable<Object> _multiple = const ["banana", "orange"];
  Iterable<Object> _treeSelected = const ["tea"];
  Iterable<Object> _focusOpenSelected = const [];

  @override
  void dispose() {
    _focusOpenNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: "基础用法",
              description: "展示默认按钮触发和多选文本聚合效果",
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildDemoCard(
                    title: "单选",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ZoDropdown(
                          options: _fruitOptions,
                          value: _single,
                          onChanged: (value) {
                            setState(() {
                              _single = value ?? const [];
                            });
                          },
                          child: const Text("请选择水果"),
                        ),
                        const SizedBox(height: 12),
                        Text("当前值: ${_single.join(", ")}"),
                      ],
                    ),
                  ),
                  _buildDemoCard(
                    title: "多选",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ZoDropdown(
                          options: _fruitOptions,
                          value: _multiple,
                          maxSelectedShowNumber: 2,
                          selectionType: ZoSelectionType.multiple,
                          onChanged: (value) {
                            setState(() {
                              _multiple = value ?? const [];
                            });
                          },
                          child: const Text("请选择多个水果"),
                        ),
                        const SizedBox(height: 12),
                        Text("当前值: ${_multiple.join(", ")}"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "尺寸与宽度",
              description: "分别展示按钮尺寸、跟随触发目标宽度和固定菜单宽度",
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildDemoCard(
                    title: "不同尺寸",
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ZoDropdown(
                          options: _fruitOptions,
                          size: ZoSize.small,
                          child: const Text("小尺寸"),
                        ),
                        ZoDropdown(
                          options: _fruitOptions,
                          child: const Text("默认尺寸"),
                        ),
                        ZoDropdown(
                          options: _fruitOptions,
                          size: ZoSize.large,
                          child: const Text("大尺寸"),
                        ),
                      ],
                    ),
                  ),
                  _buildDemoCard(
                    title: "按钮与菜单宽度",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ZoDropdown(
                          options: _fruitOptions,
                          value: _single,
                          buttonMinWidth: 120,
                          buttonMaxWidth: 160,
                          menuWidth: null,
                          onChanged: (value) {
                            setState(() {
                              _single = value ?? const [];
                            });
                          },
                          child: const Text("菜单跟随按钮宽度"),
                        ),
                        const SizedBox(height: 12),
                        ZoDropdown(
                          options: _fruitOptions,
                          value: _multiple,
                          selectionType: ZoSelectionType.multiple,
                          buttonMaxWidth: 180,
                          menuWidth: 280,
                          onChanged: (value) {
                            setState(() {
                              _multiple = value ?? const [];
                            });
                          },
                          child: const Text("菜单固定宽度 280"),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "菜单类型",
              description: "展示 treeMenu 与可选分支节点配置",
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildDemoCard(
                    title: "树形菜单",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ZoDropdown(
                          options: _treeOptions,
                          value: _treeSelected,
                          selectionType: ZoSelectionType.multiple,
                          branchSelectable: true,
                          selectMenuType: ZoMenusTriggerType.treeMenu,
                          menuWidth: 280,
                          toolbar: const Padding(
                            padding: EdgeInsets.all(12),
                            child: Text("支持树形展开和分支选择"),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _treeSelected = value ?? const [];
                            });
                          },
                          child: const Text("请选择分类"),
                        ),
                        const SizedBox(height: 12),
                        Text("当前值: ${_treeSelected.join(", ")}"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "状态控制",
              description: "覆盖隐藏指示器、聚焦打开和禁用态",
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildDemoCard(
                    title: "隐藏指示器",
                    child: ZoDropdown(
                      options: _fruitOptions,
                      value: _single,
                      showOpenIndicator: false,
                      onChanged: (value) {
                        setState(() {
                          _single = value ?? const [];
                        });
                      },
                      child: const Text("不显示上下箭头"),
                    ),
                  ),
                  _buildDemoCard(
                    title: "聚焦自动打开",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ZoDropdown(
                          options: _fruitOptions,
                          value: _focusOpenSelected,
                          focusNode: _focusOpenNode,
                          openOnFocus: true,
                          onChanged: (value) {
                            setState(() {
                              _focusOpenSelected = value ?? const [];
                            });
                          },
                          child: const Text("聚焦后自动打开"),
                        ),
                        const SizedBox(height: 12),
                        ZoButton(
                          child: const Text("请求焦点"),
                          onTap: () {
                            _focusOpenNode.requestFocus();
                          },
                        ),
                      ],
                    ),
                  ),
                  _buildDemoCard(
                    title: "禁用",
                    child: ZoDropdown(
                      options: _fruitOptions,
                      value: const ["banana"],
                      enabled: false,
                      child: const Text("禁用状态"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? description,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 4),
          Text(description),
        ],
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildDemoCard({required String title, required Widget child}) {
    return SizedBox(
      width: 320,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: context.zoStyle.outlineColor),
          borderRadius: BorderRadius.circular(context.zoStyle.borderRadiusLG),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

import "dart:math";

import "package:flutter/material.dart";
import "package:zo/zo.dart";

class SelectPage extends StatefulWidget {
  const SelectPage({super.key});

  @override
  State<SelectPage> createState() => _SelectPageState();
}

class _SelectPageState extends State<SelectPage> {
  final GlobalKey<ZoSelectState> _inspectKey = GlobalKey();

  Iterable<Object> _singleValue = const ["Option 2-1"];
  Iterable<Object> _multipleValue = const ["Option 1", "Option 3-2"];
  Iterable<Object> _treeValue = const ["Option 2"];
  Iterable<Object> _remoteValue = const [];
  Iterable<Object> _readonlyValue = const ["Option 1", "Option 2"];
  String _inspectText = "";
  String _remoteKeyword = "";

  Future<List<ZoOption>> loadOptions(ZoOption option) async {
    final List<ZoOption> list = [];

    await Future.delayed(Duration(seconds: 1));

    if (Random().nextDouble() > 0.7) {
      return list;
    }

    for (int i = 0; i < 8; i++) {
      list.add(
        ZoOption(
          value: "${option.value}-$i",
          title: Text("选项-$i"),
          leading: Icon(Icons.copy),
        ),
      );
    }

    return list;
  }

  late final List<ZoOption> options = [
    ZoOption(
      value: "Option 1",
      title: Text("Option 1"),
    ),
    ZoOption(
      value: "Option 2",
      title: Text("Option 2"),
      children: [
        ZoOption(
          value: "Option 2-1",
          title: Text("Option 2-1"),
        ),
        ZoOption(
          value: "Option 2-2",
          title: Text("Option 2-2"),
        ),
      ],
    ),
    ZoOption(
      value: "Option 3",
      title: Text("Option 3"),
      children: [
        ZoOption(
          value: "Option 3-1",
          title: Text("Option 3-1"),
          loader: loadOptions,
        ),
        ZoOption(
          value: "Option 3-2",
          title: Text("Option 3-2"),
          loader: loadOptions,
        ),
      ],
    ),
  ];

  List<ZoOption> get remoteOptions {
    const source = [
      "Alpha",
      "Beta",
      "Gamma",
      "Delta",
      "Epsilon",
      "Zeta",
      "Eta",
      "Theta",
    ];

    final keyword = _remoteKeyword.trim().toLowerCase();

    final filtered = keyword.isEmpty
        ? source
        : source.where((item) => item.toLowerCase().contains(keyword));

    return [
      for (final item in filtered)
        ZoOption(
          value: item,
          title: Text(item),
        ),
    ];
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
              description: "展示单选和多选的默认输入框交互",
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildDemoCard(
                    title: "单选",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ZoSelect(
                          value: _singleValue,
                          selectionType: ZoSelectionType.single,
                          options: options,
                          hintText: const Text("请选择内容"),
                          onChanged: (value) {
                            setState(() {
                              _singleValue = value ?? const [];
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Text("当前值: ${_singleValue.join(", ")}"),
                      ],
                    ),
                  ),
                  _buildDemoCard(
                    title: "多选标签",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ZoSelect(
                          key: _inspectKey,
                          value: _multipleValue,
                          selectionType: ZoSelectionType.multiple,
                          options: options,
                          hintText: const Text("请选择多个内容"),
                          onChanged: (value) {
                            setState(() {
                              _multipleValue = value ?? const [];
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            ZoButton(
                              child: const Text("读取状态"),
                              onTap: () {
                                setState(() {
                                  _inspectText =
                                      _inspectKey.currentState
                                          ?.getSelectedText() ??
                                      "";
                                });
                              },
                            ),
                            Text(
                              _inspectText.isEmpty
                                  ? "当前未读取"
                                  : "读取结果: $_inspectText",
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "展示模式",
              description: "展示尺寸、文本模式和树形菜单模式",
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildDemoCard(
                    title: "不同尺寸",
                    child: Column(
                      children: [
                        ZoSelect(
                          value: const ["Option 2"],
                          selectionType: ZoSelectionType.multiple,
                          options: options,
                          size: ZoSize.small,
                        ),
                        const SizedBox(height: 12),
                        ZoSelect(
                          value: _multipleValue,
                          selectionType: ZoSelectionType.multiple,
                          options: options,
                          size: ZoSize.large,
                          onChanged: (value) {
                            setState(() {
                              _multipleValue = value ?? const [];
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  _buildDemoCard(
                    title: "强制文本展示",
                    child: ZoSelect(
                      value: _readonlyValue,
                      selectionType: ZoSelectionType.multiple,
                      options: options,
                      forceTextDisplay: true,
                      hintText: const Text("使用文本显示选中项"),
                      onChanged: (value) {
                        setState(() {
                          _readonlyValue = value ?? const [];
                        });
                      },
                    ),
                  ),
                  _buildDemoCard(
                    title: "树形菜单",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ZoSelect(
                          value: _treeValue,
                          selectionType: ZoSelectionType.multiple,
                          branchSelectable: true,
                          selectMenuType: ZoMenusTriggerType.treeMenu,
                          options: options,
                          hintText: const Text("树形菜单"),
                          onChanged: (value) {
                            setState(() {
                              _treeValue = value ?? const [];
                            });
                          },
                        ),
                        const SizedBox(height: 12),
                        Text("当前值: ${_treeValue.join(", ")}"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "搜索能力",
              description: "本地搜索直接过滤菜单，远程搜索场景可通过 `onInputChanged` 自行更新选项",
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildDemoCard(
                    title: "本地搜索",
                    child: ZoSelect(
                      selectionType: ZoSelectionType.single,
                      options: options,
                      localSearch: true,
                      hintText: const Text("输入关键字过滤选项"),
                    ),
                  ),
                  _buildDemoCard(
                    title: "远程搜索接入",
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ZoSelect(
                          value: _remoteValue,
                          selectionType: ZoSelectionType.single,
                          options: remoteOptions,
                          localSearch: false,
                          onInputChanged: (value) {
                            setState(() {
                              _remoteKeyword = value ?? "";
                            });
                          },
                          onChanged: (value) {
                            setState(() {
                              _remoteValue = value ?? const [];
                            });
                          },
                          hintText: const Text("输入关键字模拟远程搜索"),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _remoteKeyword.isEmpty
                              ? "当前关键字: 空"
                              : "当前关键字: $_remoteKeyword",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "状态控制",
              description: "展示只读和禁用态",
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildDemoCard(
                    title: "只读",
                    child: ZoSelect(
                      value: _readonlyValue,
                      selectionType: ZoSelectionType.multiple,
                      options: options,
                      readOnly: true,
                    ),
                  ),
                  _buildDemoCard(
                    title: "禁用",
                    child: ZoSelect(
                      value: const ["Option 1"],
                      selectionType: ZoSelectionType.single,
                      options: options,
                      enabled: false,
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
      width: 360,
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

import "dart:async";
import "dart:math";

import "package:flutter/material.dart";
import "package:zo/zo.dart";

class MenusPage extends StatefulWidget {
  const MenusPage({super.key});

  @override
  State<MenusPage> createState() => _MenusPageState();
}

class _MenusPageState extends State<MenusPage> {
  final GlobalKey<ZoMenusTriggerState> _triggerStateKey = GlobalKey();
  final FocusNode _triggerFocusNode = FocusNode();

  Iterable<Object> _triggerSingle = const [];
  Iterable<Object> _triggerMultiple = const ["Option 2"];
  Iterable<Object> _triggerFocusValue = const [];
  String _triggerReadText = "未读取";

  var options1 = [
    ZoOption(
      value: "Option 1",
      title: Text("Option 1"),
    ),
    ZoOption(
      value: "Option 2",
      title: Text("Option 2"),
    ),
    ZoOption(
      value: "Option 3",
      title: Text("Option 3"),
    ),
    ZoOptionSection("分组选项"),
    ZoOption(
      value: "Option 4",
      title: Text("Option 4"),
      leading: Icon(Icons.copy),
    ),
    ZoOption(
      value: "value 5",
      title: Text("选项内容AAA"),
      leading: SizedBox(
        width: 32,
      ),
      children: [
        ZoOption(
          value: "value51",
          title: Text("选项内容AAA"),
          leading: Icon(Icons.copy),
        ),
      ],
    ),
    ZoOption(
      value: "Option 6",
      title: Text("Option 5"),
      leading: Icon(Icons.call),
    ),
    ZoOptionDivider(),
    ZoOption(
      value: "value 7",
      title: Text("选项内容AAA选项内容AAA选项内容AAA选项内容AAA选项内容AAA"),
      leading: Icon(Icons.copy),
      enabled: false,
    ),
    ZoOption(
      value: "value 8",
      title: Text("选项内容AAA选项内容AAA选项内容AAA选项内容AAA选项内容AAA"),
      leading: Icon(Icons.copy),
      enabled: false,
    ),
  ];

  List<ZoOption> options2 = [];

  List<ZoOption> options3 = [];

  late List<ZoOption> options4 = [
    ZoOption(
      value: "Option 1",
      title: Text("Option 1"),
    ),
    ZoOption(
      value: "Option 2",
      title: Text("Option 2"),
    ),
    ZoOption(
      value: "Option 3",
      title: Text("Option 3"),
    ),
    ZoOptionSection("分组选项"),
    ZoOption(
      value: "Option 4",
      title: Text("Option 4"),
      leading: Icon(Icons.copy),
    ),
    ZoOption(
      value: "value 5",
      title: Text("选项内容AAA"),
      leading: SizedBox(
        width: 32,
      ),
      children: [
        ZoOption(
          value: "value51",
          title: Text("选项内容AAA"),
          leading: Icon(Icons.copy),
        ),
        ZoOption(
          value: "value51",
          title: Text("选项内容AAA"),
          leading: Icon(Icons.copy),
        ),
      ],
    ),
    ZoOption(
      value: "value 5d1",
      title: Text("选项内容AAA"),
      leading: SizedBox(
        width: 32,
      ),
      children: [
        ZoOption(
          value: "value 5d1-1",
          title: Text("选项内容BBB1"),
          leading: Icon(Icons.copy),
        ),
        ZoOption(
          value: "value 5d1-2",
          title: Text("选项内容BBB2"),
          leading: Icon(Icons.copy),
          children: [
            for (int i = 0; i < 30; i++)
              ZoOption(
                value: "value 5d1-2-$i",
                title: Text("选项内容BBB4-$i"),
                leading: Icon(Icons.copy),
                children: [
                  ZoOption(
                    value: "value 5d1-2-$i-1",
                    title: Text("选项内容AAA"),
                    leading: Icon(Icons.copy),
                    loader: loadOptions,
                  ),
                  ZoOption(
                    value: "value 5d1-2-$i-2",
                    title: Text("选项内容AAA"),
                    leading: Icon(Icons.copy),
                  ),
                ],
              ),
          ],
        ),
        ZoOption(
          value: "value 5d1-3",
          title: Text("选项内容BBB3"),
          leading: Icon(Icons.copy),
        ),
      ],
    ),
    ZoOption(
      value: "Option 6",
      title: Text("Option 5"),
      leading: Icon(Icons.call),
    ),
    ZoOptionDivider(),
    ZoOption(
      value: "value 7",
      title: Text(
        "选项内容AAA选项内容AAA选项内容AAA选项内容AAA选项内容AAA",
      ),
      leading: Icon(Icons.copy),
      enabled: false,
    ),
    ZoOption(
      value: "value 8",
      title: Text(
        "选项内容AAA选项内容AAA选项内容AAA选项内容AAA选项内容AAA",
      ),
      leading: Icon(Icons.copy),
      enabled: false,
    ),
  ];

  late List<ZoOption> optionsTree4 = [
    ZoOption(
      value: "Option 1",
      title: Text("Option 1"),
    ),
    ZoOption(
      value: "Option 2",
      title: Text("Option 2"),
    ),
    ZoOption(
      value: "Option 3",
      title: Text("Option 3"),
    ),
    ZoOption(
      value: "Option 4",
      title: Text("Option 4"),
      leading: Icon(Icons.copy),
    ),
    ZoOption(
      value: "value 5",
      title: Text("选项内容AAA"),
      children: [
        ZoOption(
          value: "value 5-11",
          title: Text("选项内容AAA"),
          leading: Icon(Icons.copy),
        ),
        ZoOption(
          value: "value 5-12",
          title: Text("选项内容AAA"),
          leading: Icon(Icons.copy),
        ),
      ],
    ),
    ZoOption(
      value: "value 5d1",
      title: Text("选项内容AAA"),
      children: [
        ZoOption(
          value: "value 5d1-1",
          title: Text("选项内容BBB1"),
          leading: Icon(Icons.copy),
        ),
        ZoOption(
          value: "value 5d1-2",
          title: Text("选项内容BBB2"),
          leading: Icon(Icons.copy),
          children: [
            for (int i = 0; i < 30; i++)
              ZoOption(
                value: "value 5d1-2-$i",
                title: Text("选项内容BBB4-$i"),
                leading: Icon(Icons.copy),
                children: [
                  ZoOption(
                    value: "value 5d1-2-$i-1",
                    title: Text("选项内容AAA"),
                    leading: Icon(Icons.copy),
                    loader: loadOptions,
                  ),
                  ZoOption(
                    value: "value 5d1-2-$i-2",
                    title: Text("选项内容AAA"),
                    leading: Icon(Icons.copy),
                  ),
                ],
              ),
          ],
        ),
        ZoOption(
          value: "value 5d1-3",
          title: Text("选项内容BBB3"),
          leading: Icon(Icons.copy),
        ),
      ],
    ),
    ZoOption(
      value: "Option 6",
      title: Text("Option 5"),
      leading: Icon(Icons.call),
    ),
    ZoOption(
      value: "value 7",
      title: Text(
        "选项内容AAA选项内容AAA选项内容AAA选项内容AAA选项内容AAA",
      ),
      leading: Icon(Icons.copy),
      enabled: false,
    ),
    ZoOption(
      value: "value 8",
      title: Text(
        "选项内容AAA选项内容AAA选项内容AAA选项内容AAA选项内容AAA",
      ),
      leading: Icon(Icons.copy),
      enabled: false,
    ),
  ];

  late ZoMenu menu4 = ZoMenu(
    options: options4,
    dismissMode: ZoOverlayDismissMode.close,
  );

  late ZoTreeMenu menuTree4 = ZoTreeMenu(
    options: optionsTree4,
    dismissMode: ZoOverlayDismissMode.close,
    selectionType: ZoSelectionType.multiple,
    toolbar: Text("工具栏自定义"),
    footer: Text("工具栏自定义"),
  );

  late List<ZoOption> options5 = [
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

  late ZoMenu menu5 = ZoMenu(
    options: options5,
    dismissMode: ZoOverlayDismissMode.close,
    selectionType: ZoSelectionType.multiple,
    branchSelectable: true,
  );

  late ZoTreeMenu menuTree5 = ZoTreeMenu(
    options: optionsTree4,
    dismissMode: ZoOverlayDismissMode.close,
    selectionType: ZoSelectionType.multiple,
    branchSelectable: true,
  );

  @override
  void dispose() {
    _triggerFocusNode.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    final List<ZoOption> options = [...options1];

    // 添加一些模拟选项到 options2 用于测试滚动
    for (int i = 0; i < 50; i++) {
      options.add(
        ZoOption(
          value: "value${i + 9}",
          title: Text("选项内容AAA选项内容AAA选项内容AAA选项内容AAA选项内容AAA"),
          leading: Icon(Icons.copy),
        ),
      );
    }

    options2 = options;
  }

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

  Widget _buildTriggerDemoItem({
    required String title,
    required Widget child,
  }) {
    return SizedBox(
      width: 320,
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
    );
  }

  Widget _buildMenusTriggerExamples(BuildContext context) {
    final style = context.zoStyle;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: style.outlineColor),
        borderRadius: BorderRadius.circular(style.borderRadiusLG),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "ZoMenusTrigger 示例",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            const Text("展示按钮触发、状态读取、聚焦打开和手动绑定用法"),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildTriggerDemoItem(
                  title: "按钮触发",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ZoMenusTrigger(
                        value: _triggerSingle,
                        options: options1,
                        menuWidth: 220,
                        onChanged: (value) {
                          setState(() {
                            _triggerSingle = value ?? const [];
                          });
                        },
                        builder: (args) {
                          final text = args.state.getSelectedText();

                          return ZoButton(
                            focusOnTap: true,
                            focusNode: args.focusNode,
                            onTap: args.state.toggle,
                            child: Text(
                              text.isEmpty ? "点击打开菜单" : text,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Text("当前值: ${_triggerSingle.join(", ")}"),
                    ],
                  ),
                ),
                _buildTriggerDemoItem(
                  title: "多选与状态读取",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ZoMenusTrigger(
                        key: _triggerStateKey,
                        value: _triggerMultiple,
                        options: options5,
                        selectionType: ZoSelectionType.multiple,
                        menuWidth: 260,
                        onChanged: (value) {
                          setState(() {
                            _triggerMultiple = value ?? const [];
                          });
                        },
                        builder: (args) {
                          final text = args.state.getSelectedText();

                          return ZoButton(
                            focusOnTap: true,
                            focusNode: args.focusNode,
                            onTap: args.state.toggle,
                            child: Text(
                              text.isEmpty ? "选择多个选项" : text,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ZoButton(
                            onTap: () {
                              setState(() {
                                _triggerReadText =
                                    _triggerStateKey.currentState
                                        ?.getSelectedText() ??
                                    "未读取";
                              });
                            },
                            child: const Text("读取当前文本"),
                          ),
                          Text(_triggerReadText),
                        ],
                      ),
                    ],
                  ),
                ),
                _buildTriggerDemoItem(
                  title: "聚焦自动打开",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ZoMenusTrigger(
                        value: _triggerFocusValue,
                        options: options5,
                        openOnFocus: true,
                        focusNode: _triggerFocusNode,
                        menuWidth: 240,
                        onChanged: (value) {
                          setState(() {
                            _triggerFocusValue = value ?? const [];
                          });
                        },
                        builder: (args) {
                          final text = args.state.getSelectedText();

                          return ZoButton(
                            focusNode: args.focusNode,
                            focusOnTap: true,
                            onTap: args.state.toggle,
                            child: Text(
                              text.isEmpty ? "聚焦或点击打开" : text,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 12),
                      ZoButton(
                        onTap: () {
                          _triggerFocusNode.requestFocus();
                        },
                        child: const Text("请求焦点"),
                      ),
                    ],
                  ),
                ),
                _buildTriggerDemoItem(
                  title: "手动绑定 focus 包装",
                  child: ZoMenusTrigger(
                    options: options1,
                    menuWidth: 220,
                    builder: (args) {
                      return args.bindFocusWrapper(
                        GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: args.state.toggle,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: style.outlineColor),
                              borderRadius: BorderRadius.circular(
                                style.borderRadiusLG,
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("自定义组合触发目标"),
                                SizedBox(width: 8),
                                Icon(Icons.unfold_more_rounded),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        clipBehavior: Clip.none,
        padding: EdgeInsets.all(24),
        child: ZoCells(
          children: [
            ZoCell(
              span: 2.8,
              child: ZoOptionViewList(
                options: options1,
                size: ZoSize.small,
              ),
            ),
            ZoCell(
              span: 2.8,
              child: ZoOptionViewList(options: options1),
            ),
            ZoCell(
              span: 3.6,
              child: ZoOptionViewList(options: options1, size: ZoSize.large),
            ),
            ZoCell(span: 0.4),
            ZoCell(
              span: 2.8,
              child: ZoOptionViewList(
                options: options2,
              ),
            ),
            ZoCell(span: 0.4),
            ZoCell(
              span: 2.8,
              child: Column(
                spacing: 4,
                children: [
                  ZoOptionViewList(
                    options: options3,
                    // toolbar: Text("共500项, 已选中5项"),
                  ),
                  ZoOptionViewList(
                    options: options3,
                    loading: true,
                    // toolbar: Text("共500项, 已选中5项"),
                  ),
                  ZoButton(
                    child: Text("打开菜单4"),
                    onContextAction: (event) {
                      menu4.offset = event.position;
                      zoOverlay.open(menu4);
                    },
                  ),
                  ZoButton(
                    child: Text("当前选项"),
                    onTap: () {
                      final val = menu4.controller.processedData;
                      print(val);
                    },
                  ),
                  ZoButton(
                    child: Text("打开菜单5"),
                    onContextAction: (event) {
                      menu5.offset = event.position;
                      zoOverlay.open(menu5);
                      // Timer(Duration(milliseconds: 5000), () {
                      //   print(111);
                      //   menu5.matchString = "5";
                      // });
                    },
                  ),
                  ZoButton(
                    child: Text("打开菜单 tree4"),
                    onContextAction: (event) {
                      menuTree4.offset = event.position;
                      zoOverlay.open(menuTree4);
                      // Timer(Duration(milliseconds: 5000), () {
                      //   print(111);
                      //   menu5.matchString = "5";
                      // });
                    },
                  ),
                  ZoButton(
                    child: Text("打开菜单 tree5"),
                    onContextAction: (event) {
                      menuTree5.offset = event.position;
                      zoOverlay.open(menuTree5);
                      // Timer(Duration(milliseconds: 5000), () {
                      //   print(111);
                      //   menu5.matchString = "5";
                      // });
                    },
                  ),
                  ZoButton(
                    child: Text("当前选项5"),
                    onTap: () {
                      final val = menu5.controller.processedData;
                      print(val);
                    },
                  ),
                  ZoButton(
                    child: Text("调试"),
                    onTap: () {
                      final c = ZoOptionController(data: options5);

                      print(c.flatList);
                    },
                  ),
                  FocusScope(
                    // node: focusScopeNode,
                    canRequestFocus: true,
                    onKeyEvent: (n, e) {
                      print("key: ${e.logicalKey}");
                      return KeyEventResult.ignored;
                    },
                    descendantsAreFocusable: true,
                    descendantsAreTraversable: true,
                    child: ZoButton(
                      child: Text("Test"),
                      onTap: () {
                        final c = ZoOptionController(data: options5);

                        print(c.flatList);
                      },
                    ),
                  ),
                ],
              ),
            ),
            ZoCell(
              span: 12,
              child: _buildMenusTriggerExamples(context),
            ),
          ],
        ),
      ),
    );
  }
}

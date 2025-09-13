import "dart:async";
import "dart:math";

import "package:flutter/material.dart";
import "package:zo/src/menus/menu_entry.dart";
import "package:zo/src/menus/option.dart";
import "package:zo/zo.dart";

class MenusPage extends StatefulWidget {
  const MenusPage({super.key});

  @override
  State<MenusPage> createState() => _MenusPageState();
}

class _MenusPageState extends State<MenusPage> {
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
      leading: ZoOptionView.emptyLeading,
      options: [
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
      leading: ZoOptionView.emptyLeading,
      optionsWidth: 160,
      options: [
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
      leading: ZoOptionView.emptyLeading,
      options: [
        ZoOption(
          value: "value 5d1-1",
          title: Text("选项内容BBB1"),
          leading: Icon(Icons.copy),
        ),
        ZoOption(
          value: "value 5d1-2",
          title: Text("选项内容BBB2"),
          leading: Icon(Icons.copy),
          options: [
            for (int i = 0; i < 30; i++)
              ZoOption(
                value: "value 5d1-2-$i",
                title: Text("选项内容BBB4-$i"),
                leading: Icon(Icons.copy),
                options: [
                  ZoOption(
                    value: "value 5d1-2-$i-1",
                    title: Text("选项内容AAA"),
                    leading: Icon(Icons.copy),
                    loadOptions: loadOptions,
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

  late ZoMenuEntry menu4 = ZoMenuEntry(
    options: options4,
    dismissMode: ZoOverlayDismissMode.close,
  );

  late List<ZoOption> options5 = [
    ZoOption(
      value: "Option 1",
      title: Text("Option 1"),
    ),
    ZoOption(
      value: "Option 2",
      title: Text("Option 2"),
      options: [
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
      options: [
        ZoOption(
          value: "Option 3-1",
          title: Text("Option 3-1"),
          loadOptions: loadOptions,
        ),
        ZoOption(
          value: "Option 3-2",
          title: Text("Option 3-2"),
          loadOptions: loadOptions,
        ),
      ],
    ),
  ];

  late ZoMenuEntry menu5 = ZoMenuEntry(
    options: options5,
    dismissMode: ZoOverlayDismissMode.close,
    selectionType: ZoSelectionType.single,
    branchSelectable: true,
  );

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

  @override
  Widget build(BuildContext context) {
    final style = context.zoStyle;

    return Scaffold(
      body: SingleChildScrollView(
        clipBehavior: Clip.none,
        padding: EdgeInsets.all(24),
        child: ZoCells(
          children: [
            ZoCell(
              span: 2.8,
              child: ZoOptionViewList(options: options1),
            ),
            ZoCell(span: 0.4),
            ZoCell(
              span: 2.8,
              child: ZoOptionViewList(
                options: options2,
                toolbar: Text("共500项, 已选中5项"),
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
                      print(ZoOption.toJsonList(menu4.treeOptions));
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
                    child: Text("当前选项5"),
                    onTap: () {
                      print(ZoOption.toJsonList(menu5.treeOptions));
                    },
                  ),
                  ZoButton(
                    child: Text("调试"),
                    onTap: () {
                      final c = ZoOptionController(options: options5);

                      print(c.flatList);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

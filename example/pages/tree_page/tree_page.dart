import "dart:async";
import "dart:math";

import "package:flutter/material.dart";
import "package:zo/zo.dart";

class TreePage extends StatefulWidget {
  const TreePage({super.key});

  @override
  State<TreePage> createState() => _TreePageState();
}

class _TreePageState extends State<TreePage> {
  Future<List<ZoOption>> loadOptions(ZoOption option) async {
    final List<ZoOption> list = [];

    await Future.delayed(Duration(seconds: 1));

    if (Random().nextDouble() > 0.4) {
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

  late List<ZoOption> options1 = [
    ZoOption(
      value: "value 0",
      title: Text("Option 0"),
      optionsWidth: 160,
      children: [
        ZoOption(
          value: "value0.1",
          title: Text("选项内容AAA"),
          loader: loadOptions,
        ),
        ZoOption(
          value: "value0.2",
          title: Text("选项内容AAA"),
          loader: loadOptions,
        ),
      ],
    ),
    ZoOption(
      value: "value 1",
      title: Text("Option 1"),
      optionsWidth: 160,
      children: [
        ZoOption(
          value: "value1.1",
          title: Text("选项内容AAA"),
          leading: Icon(Icons.copy),
        ),
        ZoOption(
          value: "value1.2",
          title: Text("选项内容AAA"),
          leading: Icon(Icons.copy),
        ),
      ],
    ),
    ZoOption(
      value: "value 2",
      title: Text("Option 2"),
      optionsWidth: 160,
      children: [
        ZoOption(
          value: "value2.1",
          title: Text("选项内容AAA2-1"),
          leading: Icon(Icons.copy),
        ),
        ZoOption(
          value: "value2.2",
          title: Text("选项内容AAA2-2"),
          leading: Icon(Icons.copy),
        ),
      ],
    ),
    ZoOption(
      value: "value 3",
      title: Text("Option 3"),
      optionsWidth: 160,
      children: [
        ZoOption(
          value: "value3.1",
          title: Text("选项内容AAA3-1"),
          leading: Icon(Icons.copy),
        ),
        ZoOption(
          value: "value3.2",
          title: Text("选项内容AAA3-2"),
          leading: Icon(Icons.copy),
        ),
      ],
    ),
    ZoOption(
      value: "value 4",
      title: Text("Option 4"),
      optionsWidth: 160,
    ),
    ZoOption(
      value: "value 5",
      title: Text("Option 5"),
      optionsWidth: 160,
      children: [
        ZoOption(
          value: "value51",
          title: Text("选项内容AAA"),
          leading: Icon(Icons.copy),
        ),
        ZoOption(
          value: "value52",
          title: Text("选项内容AAA"),
          leading: Icon(Icons.copy),
        ),
      ],
    ),
    ZoOption(
      value: "value 5d1",
      title: Text("Option 5d1"),
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
                    // loadOptions: loadOptions,
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
      title: Text("Option 6"),
      leading: Icon(Icons.call),
    ),
    // ZoOptionDivider(),
    ZoOption(
      value: "value 7",
      title: Text(
        "选项内容AAA选项内容",
      ),
      leading: Icon(Icons.copy),
      enabled: false,
    ),
    ZoOption(
      value: "value 8",
      title: Text(
        "选项内容AAA选项内容AAA选项内",
      ),
      leading: Icon(Icons.copy),
      enabled: false,
    ),
    ZoOption(
      value: "value 9",
      title: Text(
        "选项内容AAA选项内容AAA选项内",
      ),
      leading: Icon(Icons.copy),
    ),
  ];

  late List<ZoOption> options2 = [
    ZoOption(
      value: "value 1",
      title: Text("Option 1"),
      optionsWidth: 160,
      children: [
        ZoOption(
          value: "value1.1",
          title: Text("选项内容AAA"),
          leading: Icon(Icons.copy),
        ),
        ZoOption(
          value: "value1.2",
          title: Text("选项内容AAA"),
          leading: Icon(Icons.copy),
        ),
      ],
    ),
    ZoOption(
      value: "value 2",
      title: Text("Option 2"),
      optionsWidth: 160,
      children: [
        ZoOption(
          value: "value2.1",
          title: Text("选项内容AAA"),
          leading: Icon(Icons.copy),
        ),
        ZoOption(
          value: "value2.2",
          title: Text("选项内容AAA"),
          leading: Icon(Icons.copy),
        ),
      ],
    ),
  ];

  GlobalKey<ZoTreeState> treeKey = GlobalKey();

  String? filterString;

  List<ZoMutatorRecord<ZoTreeDataOperation>> history = [];

  int historyIndex = -1;

  void prevHistory() {
    if (historyIndex == -1) return;
    final cur = history[historyIndex];
    if (cur.$2 == null) return;

    historyIndex--;
    final controller = treeKey.currentState!.controller;

    controller.mutator.mutation(
      ZoMutatorCommand(operation: cur.$2!, source: ZoMutatorSource.history),
    );

    setState(() {});
  }

  void nextHistory() {
    if (historyIndex == history.length - 1) return;

    final cur = history[historyIndex + 1];

    historyIndex++;
    final controller = treeKey.currentState!.controller;

    controller.mutator.mutation(
      ZoMutatorCommand(operation: [cur.$1], source: ZoMutatorSource.history),
    );

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final style = context.zoStyle;

    return Scaffold(
      body: SingleChildScrollView(
        clipBehavior: Clip.none,
        padding: EdgeInsets.all(24),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            Text("Simple"),
            Container(
              height: 500,
              decoration: BoxDecoration(
                border: Border.all(
                  color: style.outlineColor,
                ),
              ),
              child: ZoTree(
                // maxHeight: 400,
                // pinedActiveBranch: true,
                key: treeKey,
                // textStyle: TextStyle(color: Colors.red),
                // iconTheme: IconThemeData(color: Colors.red),
                // size: ZoSize.large,
                options: options1,
                matchString: filterString,
                value: const ["value 4"],
                expands: const ["value 1", "value 2"],
                onMutation: (details) {
                  print("mutation: ${details.source}");

                  if (details.source == ZoMutatorSource.local) {
                    setState(() {
                      history = history.sublist(0, historyIndex + 1);

                      history.addAll(details.operation);
                      historyIndex = history.length - 1;
                    });
                  }
                },
                // headerBuilder: (event) {
                //   return Text(
                //     '${event.node.data.title}',
                //     style: TextStyle(
                //       fontWeight: FontWeight.bold,
                //       color: Colors.red,
                //     ),
                //   );
                // },
                // expandTopLevel: true,
                // expandAll: true,
                expandByTapRow: (node) {
                  return node.value != "value 2";
                },
                selectionType: ZoSelectionType.multiple,
                implicitMultipleSelection: true,
                // branchSelectable: false,
                onTap: (node) {
                  print("tapRow: ${node.node.value}");
                },
                // leadingBuilder: (event) {
                //   return ZoButton(
                //     plain: true,
                //     size: ZoSize.small,
                //     child: Text("新增"),
                //     constraints: BoxConstraints(minHeight: 24),
                //   );
                // },
                sortable: true,
                onContextAction: (event, triggerEvent) {
                  print("event $event $triggerEvent");
                },
                trailingBuilder: (event) {
                  return TestCount();
                },
                draggableDetector: (node) {
                  return node.value != "value 2";
                },
                droppableDetector: (node, dragNode) {
                  if (dragNode?.value == "value 0" && node.value == "value 1") {
                    return false;
                  }

                  return true;
                },
                onSortConfirm: (args) {
                  final completer = Completer<bool>();

                  bool isConfirm = false;

                  zoOverlay.open(
                    ZoDialog(
                      title: Text("提示"),
                      barrier: false,
                      tapAwayClosable: false,
                      content: Text(
                        "确认要将 ${args.from.map((i) => i.data.getTitleText())} 移动至 ${args.to.data.getTitleText()} 吗？",
                      ),
                      onConfirm: () {
                        print("confirm: true");
                        isConfirm = true;
                      },
                      onDismiss: (didDismiss, result) {
                        print("confirm: false");

                        completer.complete(isConfirm);
                      },
                    ),
                  );

                  return completer.future;
                },
                // indentDots: false,
                // enable: false,
                // indentSize: Size(18, 18),
                // togglerIcon: Icons.arrow_right_alt_outlined,
              ),
            ),
            ZoButton(
              child: Text("pop"),
              onTap: () {
                Navigator.maybePop(context);
              },
            ),
            ZoButton(
              child: Text("展开全部"),
              onTap: () {
                treeKey.currentState!.controller.expandsAll();
              },
            ),
            ZoButton(
              child: Text("收起全部"),
              onTap: () {
                treeKey.currentState!.controller.collapseAll();
              },
            ),
            ZoButton(
              child: Text("value 2 是否展开"),
              onTap: () {
                print(treeKey.currentState!.controller.isExpanded("value 2"));
              },
            ),
            ZoButton(
              child: Text("展开 value 5d1-2"),
              onTap: () {
                treeKey.currentState!.controller.expand("value 5d1-2");
              },
            ),
            ZoButton(
              child: Text("是否全部展开"),
              onTap: () {
                print(treeKey.currentState!.controller.isAllExpanded());
              },
            ),
            ZoButton(
              child: Text("获取全部展开值"),
              onTap: () {
                print(treeKey.currentState!.controller.getExpands());
              },
            ),
            ZoButton(
              child: Text("jump 5d1-2-6-1"),
              onTap: () {
                treeKey.currentState!.jumpTo("value 5d1-2-6-1");
              },
            ),
            ZoButton(
              child: Text("jump 5d1-2-6-1 with animation"),
              onTap: () {
                treeKey.currentState!.jumpTo(
                  "value 5d1-2-6-1",
                  animation: true,
                );
              },
            ),
            ZoButton(
              child: Text("focus 5d1-2-6-1"),
              onTap: () {
                treeKey.currentState!.focusOption("value 5d1-2-6-1");
              },
            ),
            ZoButton(
              child: Text("select all"),
              onTap: () {
                treeKey.currentState!.selector.selectAll(null);
              },
            ),
            SizedBox(
              width: 180,
              child: ZoInput<String>(
                hintText: Text("输入筛选内容"),
                value: filterString,
                onChanged: (newValue) {
                  setState(() {
                    filterString = newValue;
                  });
                },
              ),
            ),
            Text("Index ${historyIndex}"),
            ZoButton(
              child: Text("prev"),
              onTap: () {
                prevHistory();
              },
            ),
            ZoButton(
              child: Text("next"),
              onTap: () {
                nextHistory();
              },
            ),
            ZoButton(
              child: Text("add option to root"),
              onTap: () {
                final controller = treeKey.currentState!.controller;

                final id1 = Random().nextInt(5000000);
                final id2 = Random().nextInt(5000000);

                controller.add(
                  data: [
                    ZoOption(
                      value: "value $id1",
                      title: Text("选项内容-$id1"),
                      leading: Icon(Icons.copy),
                    ),
                    ZoOption(
                      value: "value $id2",
                      title: Text("选项内容-$id2"),
                      leading: Icon(Icons.copy),
                    ),
                  ],
                );
              },
            ),
            ZoButton(
              child: Text("add option Option 0"),
              onTap: () {
                final controller = treeKey.currentState!.controller;

                final id1 = Random().nextInt(5000000);
                final id2 = Random().nextInt(5000000);

                controller.add(
                  data: [
                    ZoOption(
                      value: "value $id1",
                      title: Text("选项内容-$id1"),
                      leading: Icon(Icons.copy),
                    ),
                    ZoOption(
                      value: "value $id2",
                      title: Text("选项内容-$id2"),
                      leading: Icon(Icons.copy),
                    ),
                  ],
                  toValue: "value 0",
                  position: ZoTreeDataRefPosition.inside,
                );
              },
            ),
            ZoButton(
              child: Text("add option Option 0 before"),
              onTap: () {
                final controller = treeKey.currentState!.controller;

                final id1 = Random().nextInt(5000000);
                final id2 = Random().nextInt(5000000);

                controller.add(
                  data: [
                    ZoOption(
                      value: "value $id1",
                      title: Text("选项内容-$id1"),
                      leading: Icon(Icons.copy),
                    ),
                    ZoOption(
                      value: "value $id2",
                      title: Text("选项内容-$id2"),
                      leading: Icon(Icons.copy),
                    ),
                  ],
                  toValue: "value 0",
                  position: ZoTreeDataRefPosition.before,
                );
              },
            ),
            ZoButton(
              child: Text("add option Option 0 after"),
              onTap: () {
                final controller = treeKey.currentState!.controller;

                final id1 = Random().nextInt(5000000);
                final id2 = Random().nextInt(5000000);

                controller.add(
                  data: [
                    ZoOption(
                      value: "value $id1",
                      title: Text("选项内容-$id1"),
                      leading: Icon(Icons.copy),
                    ),
                    ZoOption(
                      value: "value $id2",
                      title: Text("选项内容-$id2"),
                      leading: Icon(Icons.copy),
                    ),
                  ],
                  toValue: "value 0",
                  position: ZoTreeDataRefPosition.after,
                );
              },
            ),
            ZoButton(
              child: Text("remove Option 1 children"),
              onTap: () {
                final controller = treeKey.currentState!.controller;

                controller.remove(
                  values: ["value1.1", "value1.2"],
                );
              },
            ),
            Container(
              // height: 500,
              constraints: BoxConstraints(maxHeight: 500),
              decoration: BoxDecoration(
                border: Border.all(
                  color: style.outlineColor,
                ),
              ),
              child: Align(
                alignment: AlignmentGeometry.topLeft,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red),
                  ),
                  child: ZoTree(
                    // options: [],
                    options: options2,
                    maxHeight: 200,
                    // indentDots: false,
                    // enable: false,
                    // indentSize: Size(18, 18),
                    // togglerIcon: Icons.arrow_right_alt_outlined,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TestCount extends StatefulWidget {
  const TestCount({super.key});

  @override
  State<TestCount> createState() => _TestCountState();
}

class _TestCountState extends State<TestCount> {
  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    count = createTempId();
  }

  late String count;

  @override
  Widget build(BuildContext context) {
    return Text(count);
  }
}

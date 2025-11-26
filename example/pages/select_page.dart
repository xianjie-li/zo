import "dart:math";

import "package:flutter/material.dart";
import "package:zo/zo.dart";

class SelectPage extends StatefulWidget {
  const SelectPage({super.key});

  @override
  State<SelectPage> createState() => _SelectPageState();
}

class _SelectPageState extends State<SelectPage> {
  final GlobalKey<ZoSelectState> _key = GlobalKey();

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

  late List<ZoOption> options = [
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

  @override
  Widget build(BuildContext context) {
    print(123);
    return Scaffold(
      body: SingleChildScrollView(
        clipBehavior: Clip.none,
        padding: EdgeInsets.all(24),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            ZoInput(),
            SizedBox(
              width: 400,
              child: ZoSelect(
                key: _key,
                selectionType: ZoSelectionType.multiple,
                options: options,
                // trailing: Icon(Icons.arrow_drop_down_rounded),
                hintText: Text("请选择内容"),
                // autofocus: true,
                // selectionType: ZoSelectionType.single,
                // branchSelectable: true,
                // toolbar: Container(
                //   padding: EdgeInsets.all(12),
                //   child: Text("工具栏"),
                // ),
                // localSearch: true,
                // onInputChanged: (value) {
                //   print("输入值: $value");
                // },
                // onCreateOption: (value) {},
              ),
            ),
            ZoButton(
              child: Text("输出选中"),
              onTap: () {
                print(_key.currentState?.menuEntry.selectedDatas.selected);
              },
            ),
            SizedBox(
              width: 400,
              child: ZoSelect(
                value: const ["Option 2"],
                selectionType: ZoSelectionType.multiple,
                options: options,
                size: ZoSize.small,
              ),
            ),
            SizedBox(
              width: 400,
              child: ZoSelect(
                selectionType: ZoSelectionType.multiple,
                options: options,
                size: ZoSize.large,
              ),
            ),
            SizedBox(
              width: 400,
              child: ZoSelect(
                selectionType: ZoSelectionType.single,
                options: options,
                size: ZoSize.large,
              ),
            ),
            ZoInput(),
            Focus(
              onKeyEvent: (node, event) {
                print(event.logicalKey);
                return KeyEventResult.ignored;
              },
              skipTraversal: true,
              child: ZoInput(),
            ),
          ],
        ),
      ),
    );
  }
}

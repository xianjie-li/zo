import "package:flutter/material.dart";
import "package:zo/src/input/input.dart";
import "package:zo/zo.dart";

class InputPage2 extends StatefulWidget {
  const InputPage2({super.key});

  @override
  State<InputPage2> createState() => _InputPage2State();
}

class _InputPage2State extends State<InputPage2> {
  bool open = true;

  var value = 0.0;

  bool? checkValue = false;

  String radioValue = "type1";

  bool switchValue = false;

  String selectedValue = "type1";

  DateTime dateTime = DateTime.now();

  String? inpVal1 = "hello";

  double? inpVal2 = 100;

  int? inpVal3 = 100;

  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        clipBehavior: Clip.none,
        padding: EdgeInsets.all(24),
        child: ZoCells(
          spacing: 16,
          runSpacing: 24,
          children: [
            ZoCell(span: 3, child: ZoInput<String>(hintText: Text("请输入"))),
            ZoCell(
              span: 3,
              child: ZoInput<String>(hintText: Text("请输入"), obscureText: true),
            ),
            ZoCell(span: 3, child: ZoInput<double>(hintText: Text("请输入"))),
            ZoCell(span: 3, child: ZoInput<int>(hintText: Text("请输入"))),

            ZoCell(
              span: 3,
              child: ZoInput(
                leading: Text("前置"),
                hintText: Text("请输入"),
                trailing: Text("后置"),
              ),
            ),
            ZoCell(
              span: 3,
              child: ZoInput(
                leading: ZoButton(
                  icon: Icon(Icons.account_balance_wallet),
                  square: true,
                  size: ZoSize.small,
                  onPressed: () => {},
                ),
                hintText: Text("请输入"),
                trailing: ZoButton(
                  icon: Icon(Icons.ac_unit_rounded),
                  square: true,
                  size: ZoSize.small,
                  onPressed: () => {},
                ),
              ),
            ),
            ZoCell(
              span: 3,
              child: ZoInput(
                leading: ZoButton(
                  icon: Icon(Icons.account_balance_wallet),
                  square: true,
                  size: ZoSize.small,
                  onPressed: () => {},
                ),
                hintText: Text("请输入"),
                maxLines: 3,
                minLines: 1,
              ),
            ),
            ZoCell(
              span: 3,
              child: ZoInput(hintText: Text("请输入"), maxLines: 3, minLines: 2),
            ),

            ZoCell(
              span: 3,
              child: ZoInput(
                size: ZoSize.small,
                leading: ZoButton(
                  icon: Icon(Icons.account_balance_wallet),
                  square: true,
                  size: ZoSize.small,
                  onPressed: () => {},
                ),
                hintText: Text("请输入"),
                trailing: ZoButton(
                  icon: Icon(Icons.ac_unit_rounded),
                  square: true,
                  size: ZoSize.small,
                  onPressed: () => {},
                ),
              ),
            ),
            ZoCell(
              span: 3,
              child: ZoInput(
                leading: ZoButton(
                  icon: Icon(Icons.account_balance_wallet),
                  square: true,
                  size: ZoSize.small,
                  onPressed: () => {},
                ),
                hintText: Text("请输入"),
                trailing: ZoButton(
                  icon: Icon(Icons.ac_unit_rounded),
                  square: true,
                  size: ZoSize.small,
                  onPressed: () => {},
                ),
              ),
            ),
            ZoCell(
              span: 3,
              child: ZoInput(
                size: ZoSize.large,
                leading: ZoButton(
                  icon: Icon(Icons.account_balance_wallet),
                  square: true,
                  size: ZoSize.small,
                  onPressed: () => {},
                ),
                hintText: Text("请输入"),
                trailing: ZoButton(
                  icon: Icon(Icons.ac_unit_rounded),
                  square: true,
                  size: ZoSize.small,
                  onPressed: () => {},
                ),
              ),
            ),
            ZoCell(span: 3),

            ZoCell(
              span: 3,
              child: ZoInput(
                borderless: true,
                size: ZoSize.small,
                leading: ZoButton(
                  icon: Icon(Icons.account_balance_wallet),
                  square: true,
                  size: ZoSize.small,
                  onPressed: () => {},
                ),
                hintText: Text("请输入"),
                trailing: ZoButton(
                  icon: Icon(Icons.ac_unit_rounded),
                  square: true,
                  size: ZoSize.small,
                  onPressed: () => {},
                ),
              ),
            ),
            ZoCell(
              span: 3,
              child: ZoInput(
                borderless: true,
                leading: ZoButton(
                  icon: Icon(Icons.account_balance_wallet),
                  square: true,
                  size: ZoSize.small,
                  onPressed: () => {},
                ),
                hintText: Text("请输入"),
                trailing: ZoButton(
                  icon: Icon(Icons.ac_unit_rounded),
                  square: true,
                  size: ZoSize.small,
                  onPressed: () => {},
                ),
              ),
            ),
            ZoCell(
              span: 3,
              child: ZoInput(
                borderless: true,
                size: ZoSize.large,
                leading: ZoButton(
                  icon: Icon(Icons.account_balance_wallet),
                  square: true,
                  size: ZoSize.small,
                  onPressed: () => {},
                ),
                hintText: Text("请输入"),
                trailing: ZoButton(
                  icon: Icon(Icons.ac_unit_rounded),
                  square: true,
                  size: ZoSize.small,
                  onPressed: () => {},
                ),
              ),
            ),
            ZoCell(span: 3),

            ZoCell(
              span: 3,
              child: ZoInput(
                enabled: false,
                leading: ZoButton(
                  icon: Icon(Icons.account_balance_wallet),
                  square: true,
                  size: ZoSize.small,
                  onPressed: () => {},
                ),
                hintText: Text("请输入"),
                trailing: ZoButton(
                  icon: Icon(Icons.ac_unit_rounded),
                  square: true,
                  size: ZoSize.small,
                  onPressed: () => {},
                ),
              ),
            ),
            ZoCell(
              span: 3,
              child: ZoInput(
                value: "hello",
                enabled: false,
                borderless: true,
                leading: ZoButton(
                  icon: Icon(Icons.account_balance_wallet),
                  square: true,
                  size: ZoSize.small,
                  onPressed: () => {},
                ),
                hintText: Text("请输入"),
                trailing: ZoButton(
                  icon: Icon(Icons.ac_unit_rounded),
                  square: true,
                  size: ZoSize.small,
                  onPressed: () => {},
                ),
              ),
            ),
            ZoCell(
              span: 3,
              child: ZoInput(
                value: "默认值默认值默认值默认值默认值默认值默认值默认值默认值默认值默认值默认值默认值默认值",
                readOnly: true,
                borderless: true,
                leading: ZoButton(
                  icon: Icon(Icons.account_balance_wallet),
                  square: true,
                  size: ZoSize.small,
                  onPressed: () => {},
                ),
                hintText: Text("请输入"),
                trailing: ZoButton(
                  icon: Icon(Icons.ac_unit_rounded),
                  square: true,
                  size: ZoSize.small,
                  onPressed: () => {},
                ),
              ),
            ),
            ZoCell(
              span: 3,
              child: ZoProgress(
                type: ZoProgressType.linear,
                size: ZoSize.small,
                borderRadius: BorderRadius.circular(
                  context.zoStyle.borderRadius,
                ),
                child: ZoInput(
                  value: "Hello",
                  enabled: false,
                  borderless: true,
                  leading: ZoButton(
                    icon: Icon(Icons.account_balance_wallet),
                    square: true,
                    size: ZoSize.small,
                    onPressed: () => {},
                  ),
                  hintText: Text("请输入"),
                  trailing: ZoButton(
                    icon: Icon(Icons.ac_unit_rounded),
                    square: true,
                    size: ZoSize.small,
                    onPressed: () => {},
                  ),
                ),
              ),
            ),

            ZoCell(
              span: 3,
              child: ZoTile(
                header: Text("姓名"),
                content: ZoInput<String>(hintText: Text("请输入")),
              ),
            ),
            ZoCell(
              span: 3,
              child: ZoTile(
                horizontal: true,
                header: Text("姓名"),
                content: ZoInput<String>(hintText: Text("请输入")),
              ),
            ),
            ZoCell(
              span: 5,
              child: ZoTile(
                horizontal: true,
                leading: Icon(Icons.ac_unit_outlined),
                header: Text("姓名"),
                content: ZoInput<String>(hintText: Text("请输入")),
                trailing: Icon(Icons.ac_unit_outlined),
              ),
            ),
            ZoCell(span: 1),

            ZoCell(
              span: 3,
              child: ZoTile(
                header: Text("姓名"),
                style: ZoTileStyle.border,
                content: ZoInput<String>(hintText: Text("请输入")),
              ),
            ),
            ZoCell(
              span: 3,
              child: ZoTile(
                horizontal: true,
                style: ZoTileStyle.border,
                header: Text("姓名"),
                content: ZoInput<String>(hintText: Text("请输入")),
              ),
            ),
            ZoCell(
              span: 5,
              child: ZoTile(
                horizontal: true,
                style: ZoTileStyle.border,
                leading: Icon(Icons.ac_unit_outlined),
                header: Text("姓名"),
                content: ZoInput<String>(hintText: Text("请输入")),
                trailing: Icon(Icons.ac_unit_outlined),
              ),
            ),
            ZoCell(span: 1),

            ZoCell(
              span: 3,
              child: ZoTile(
                header: Text("姓名"),
                style: ZoTileStyle.filled,
                content: ZoInput<String>(hintText: Text("请输入")),
              ),
            ),
            ZoCell(
              span: 3,
              child: ZoTile(
                horizontal: true,
                style: ZoTileStyle.filled,
                header: Text("姓名"),
                content: ZoInput<String>(hintText: Text("请输入"), enabled: false),
              ),
            ),
            ZoCell(
              span: 5,
              child: ZoTile(
                horizontal: true,
                style: ZoTileStyle.filled,
                leading: Icon(Icons.ac_unit_outlined),
                header: Text("姓名"),
                content: ZoInput<String>(hintText: Text("请输入")),
                trailing: Icon(Icons.ac_unit_outlined),
              ),
            ),
            ZoCell(span: 1),
            ZoCell(
              span: 12,
              child: ZoTile(
                leading: Icon(Icons.ac_unit_outlined),
                header: Text("自动更新"),
                content: Text(
                  "开启后, 系统会自动更新相关数据系统会自动更新相关数据",
                  style: TextStyle(color: context.zoStyle.hintTextColor),
                ),
                trailing: SizedBox(
                  width: 240,
                  child: ZoInput<String>(hintText: Text("请输入")),
                ),
              ),
            ),
            ZoCell(
              span: 12,
              child: ZoTile(
                style: ZoTileStyle.filled,
                leading: Icon(Icons.ac_unit_outlined),
                header: Text("自动更新"),
                content: Text(
                  "开启后, 系统会自动更新相关数据系统会自动更新相关数据",
                  style: TextStyle(color: context.zoStyle.hintTextColor),
                ),
                trailing: SizedBox(
                  width: 240,
                  child: ZoInput<String>(hintText: Text("请输入")),
                ),
              ),
            ),
            ZoCell(
              span: 12,
              child: ZoTile(
                style: ZoTileStyle.filled,
                leading: Icon(Icons.ac_unit_outlined),
                header: Text("姓名"),
                content: Text(
                  "开启后, 系统会自动更新相关数据",
                  style: TextStyle(color: context.zoStyle.hintTextColor),
                ),
                trailing: Switch(value: false, onChanged: (val) {}),
              ),
            ),
            ZoCell(
              span: 12,
              child: ZoTile(
                style: ZoTileStyle.border,
                leading: Icon(Icons.ac_unit_outlined),
                header: Text("自动更新"),
                content: Text(
                  "开启后, 系统会自动更新相关数据系统会自动更新相关数据",
                  style: TextStyle(color: context.zoStyle.hintTextColor),
                ),
                trailing: SizedBox(
                  width: 240,
                  child: ZoInput<String>(hintText: Text("请输入")),
                ),
              ),
            ),
            ZoCell(
              span: 5,
              child: Column(
                spacing: 8,
                children: [
                  ZoTile(
                    header: Text("姓名"),
                    style: ZoTileStyle.border,
                    content: ZoInput<String>(hintText: Text("请输入")),
                  ),
                  ZoTile(
                    header: Text("手机号"),
                    style: ZoTileStyle.border,
                    content: ZoInput<String>(hintText: Text("请输入")),
                  ),
                  ZoTile(
                    header: Text("爱好"),
                    style: ZoTileStyle.border,
                    content: ZoInput<String>(hintText: Text("请输入")),
                  ),
                ],
              ),
            ),
            ZoCell(
              span: 5,
              child: Column(
                spacing: 8,
                children: [
                  ZoTile(
                    header: Text("姓名"),
                    style: ZoTileStyle.filled,
                    content: ZoInput<String>(hintText: Text("请输入")),
                  ),
                  ZoTile(
                    header: Text("手机号"),
                    style: ZoTileStyle.filled,
                    content: ZoInput<String>(hintText: Text("请输入")),
                  ),
                  ZoTile(
                    header: Text("爱好"),
                    style: ZoTileStyle.filled,
                    content: ZoInput<String>(hintText: Text("请输入")),
                  ),
                ],
              ),
            ),
            ZoCell(
              span: 5,
              child: Column(
                children: [
                  ZoTile(
                    horizontal: true,
                    header: SizedBox(
                      width: 80,
                      child: Text("姓名", textAlign: TextAlign.end),
                    ),
                    content: ZoInput<String>(hintText: Text("请输入")),
                  ),
                  ZoTile(
                    horizontal: true,
                    header: SizedBox(
                      width: 80,
                      child: Text("手机号", textAlign: TextAlign.end),
                    ),
                    content: ZoInput<String>(hintText: Text("请输入")),
                  ),
                  ZoTile(
                    horizontal: true,
                    header: SizedBox(
                      width: 80,
                      child: Text("爱好", textAlign: TextAlign.end),
                    ),
                    content: ZoInput<String>(hintText: Text("请输入")),
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

class BgWrap extends StatelessWidget {
  const BgWrap({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(color: Colors.black.withAlpha(10), child: child);
  }
}

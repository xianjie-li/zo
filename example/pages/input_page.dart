import "package:flutter/material.dart";
import "package:zo/src/input/input.dart";
import "package:zo/zo.dart";

class InputPage extends StatefulWidget {
  const InputPage({super.key});

  @override
  State<InputPage> createState() => _InputPageState();
}

class _InputPageState extends State<InputPage> {
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
    return SingleChildScrollView(
      clipBehavior: Clip.none,
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 400,
                child: Slider(
                  value: value,
                  max: 100,
                  onChanged: (value) => setState(() => this.value = value),
                ),
              ),
              ZoButton(
                size: ZoSize.small,
                child: Text("变更"),
                onPressed: () {
                  setState(() {
                    value = value + 1;
                  });
                },
              ),
              Text("当前值: $value"),
            ],
          ),
          Row(
            children: [
              Checkbox(
                value: checkValue,
                onChanged: (val) => setState(() => checkValue = val),
              ),
              ZoButton(
                size: ZoSize.small,
                child: Text("变更"),
                onPressed: () {
                  setState(() {
                    checkValue = !checkValue!;
                  });
                },
              ),
              Text("当前值: $checkValue"),
            ],
          ),
          Row(
            children: [
              Radio(
                value: "type1",
                groupValue: radioValue,
                onChanged: (val) => setState(() => radioValue = val!),
              ),
              Radio(
                value: "type2",
                groupValue: radioValue,
                onChanged: (val) => setState(() => radioValue = val!),
              ),
              ZoButton(
                size: ZoSize.small,
                child: Text("变更"),
                onPressed: () {
                  setState(() {
                    radioValue = radioValue == "type1" ? "type2" : "type1";
                  });
                },
              ),
              Text("当前值: $radioValue"),
            ],
          ),
          Row(
            children: [
              Switch(
                value: switchValue,
                onChanged: (value) => setState(() => switchValue = value),
                // inactiveThumbColor: Colors.grey,
              ),
              ZoButton(
                size: ZoSize.small,
                child: Text("变更"),
                onPressed: () {
                  setState(() {
                    switchValue = !switchValue;
                  });
                },
              ),
              Text("当前值: $switchValue"),
            ],
          ),
          Row(
            children: [
              DropdownMenu<String>(
                initialSelection: selectedValue,
                label: const Text("选择"),
                onSelected: (String? selected) {
                  setState(() {
                    selectedValue = selected!;
                  });
                },
                dropdownMenuEntries: [
                  DropdownMenuEntry(label: "选项1", value: "type1"),
                  DropdownMenuEntry(label: "选项2", value: "type2"),
                  DropdownMenuEntry(label: "选项3", value: "type3"),
                  DropdownMenuEntry(label: "选项4", value: "type4"),
                  DropdownMenuEntry(label: "选项5", value: "type5"),
                  DropdownMenuEntry(label: "选项6", value: "type6"),
                ],
              ),
              ZoButton(
                size: ZoSize.small,
                child: Text("变更"),
                onPressed: () {
                  setState(() {
                    selectedValue = "type3";
                  });
                },
              ),
              Text("当前值: $selectedValue"),
            ],
          ),
          Row(
            children: [
              SizedBox(
                width: 180,
                child: InputDatePickerFormField(
                  initialDate: dateTime,
                  firstDate: DateTime(2024),
                  lastDate: DateTime(2026),
                ),
              ),
              ZoButton(
                size: ZoSize.small,
                child: Text("变更"),
                onPressed: () {
                  setState(() {
                    dateTime = dateTime.add(Duration(days: 1));
                  });
                },
              ),
              Text("当前值: $dateTime"),
            ],
          ),
          Row(
            children: [
              SizedBox(
                width: 180,
                child: TextField(
                  decoration: InputDecoration(label: Text("姓名")),
                  buildCounter: (
                    context, {
                    required currentLength,
                    required isFocused,
                    required maxLength,
                  }) {
                    return Text("$currentLength/$maxLength");
                  },
                  onChanged: (value) {
                    print("val: $value");
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            spacing: 12,
            children: [
              SizedBox(
                width: 180,
                child: InputDecorator(
                  isHovering: true,
                  decoration: InputDecoration(
                    label: Text("姓名"),
                    // errorText: "错误!!!",
                    helperText: "帮助文本",
                    hintText: "提示文本",
                    counter: Text("0/10"),
                  ),
                  // child: Container(
                  //   width: 120,
                  //   height: 40,
                  //   color: Colors.grey.shade200,
                  // ),
                ),
              ),
              SizedBox(
                width: 180,
                child: InputDecorator(
                  isFocused: true,
                  decoration: InputDecoration(label: Text("姓名")),

                  child: Container(
                    width: 120,
                    height: 40,
                    color: Colors.grey.shade200,
                  ),
                ),
              ),
              SizedBox(
                width: 180,
                child: InputDecorator(
                  // isHovering: true,
                  // isFocused: true,
                  // isEmpty: true,
                  decoration: InputDecoration(
                    label: Text("姓名"),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.red),
                    ),
                    isCollapsed: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  child: Container(
                    width: 120,
                    height: 32,
                    color: Colors.black.withAlpha(10),
                  ),
                ),
              ),
              Container(
                width: 180,
                // decoration: BoxDecoration(border: Border.all()),
                child: InputDecorator(
                  // isHovering: true,
                  // isEmpty: true,
                  // isFocused: ,
                  decoration: InputDecoration(
                    label: Text("姓名"),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    border: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.transparent),
                    ),
                    // filled: true,
                    // isDense: true,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    isCollapsed: true,
                    // contentPadding: EdgeInsets.symmetric(
                    //   horizontal: 8,
                    //   vertical: 8,
                    // ),
                  ),
                  child: Container(
                    width: 120,
                    height: 32,
                    color: Colors.grey.withAlpha(40),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 32),
          Container(
            width: 180,
            decoration: BoxDecoration(
              border: Border.all(color: context.zoStyle.outlineColor),
            ),
            child: ZoInput(
              // value: inpVal1,
              onChanged: (newValue) {
                print("ZoInputBase.onChanged: $newValue");
              },
            ),
          ),
          SizedBox(height: 32),
          Container(
            width: 180,
            decoration: BoxDecoration(
              border: Border.all(color: context.zoStyle.outlineColor),
            ),
            child: ZoInput(
              value: inpVal1,
              onChanged: (newValue) {
                setState(() {
                  inpVal1 = newValue;
                });
                print("ZoInputBase.onChanged: $newValue");
              },
            ),
          ),
          SizedBox(height: 32),
          ZoButton(
            child: Text("change $inpVal1"),
            onPressed: () {
              setState(() {
                inpVal1 = "lixianjie";
              });
            },
          ),
          SizedBox(height: 32),
          Container(
            width: 180,
            decoration: BoxDecoration(
              border: Border.all(color: context.zoStyle.outlineColor),
            ),
            child: ZoInput(
              value: inpVal2,
              onChanged: (newValue) {
                setState(() {
                  inpVal2 = newValue;
                });
                print(
                  "ZoInputBase.onChanged: $newValue ${newValue.runtimeType}",
                );
              },
            ),
          ),
          SizedBox(height: 32),
          ZoButton(
            child: Text("change $inpVal2"),
            onPressed: () {
              setState(() {
                inpVal2 = 10000;
              });
            },
          ),
          SizedBox(height: 32),
          Container(
            width: 180,
            decoration: BoxDecoration(
              border: Border.all(color: context.zoStyle.outlineColor),
            ),
            child: ZoProgress(
              open: loading,
              size: ZoSize.small,
              type: ZoProgressType.linear,
              child: ZoInput(
                value: inpVal3,
                hintText: Text("请输入"),
                max: 1000,
                min: 0,
                onChanged: (newValue) {
                  setState(() {
                    inpVal3 = newValue;
                  });
                  print(
                    "ZoInputBase.onChanged: $newValue ${newValue.runtimeType}",
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 32),
          ZoButton(
            child: Text("change $inpVal3"),
            onPressed: () {
              setState(() {
                inpVal3 = 10000;
              });
            },
          ),
          ZoButton(
            child: Text("loading: $loading"),
            onPressed: () {
              setState(() {
                loading = !loading;
              });
            },
          ),
          SizedBox(height: 32),
          Container(
            width: 180,
            decoration: BoxDecoration(
              // border: Border.all(color: context.zoStyle.outlineColor),
            ),
            child: ZoProgress(
              open: loading,
              size: ZoSize.small,
              type: ZoProgressType.linear,
              child: ZoInput<double>(
                obscureText: true,
                min: 0,
                onChanged: (newValue) {
                  print(
                    "ZoInputBase.onChanged: $newValue ${newValue.runtimeType}",
                  );
                },
              ),
            ),
          ),
          SizedBox(height: 32),
          Container(
            width: 180,
            decoration: BoxDecoration(
              // border: Border.all(color: context.zoStyle.outlineColor),
            ),
            child: ZoProgress(
              open: loading,
              size: ZoSize.small,
              type: ZoProgressType.linear,
              child: ZoInput(
                clear: true,
                min: 0,
                hintText: Text("请输入"),
                onChanged: (newValue) {
                  print(
                    "ZoInputBase.onChanged: $newValue ${newValue.runtimeType}",
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

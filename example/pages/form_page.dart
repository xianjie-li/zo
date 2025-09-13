import "package:flutter/material.dart";
import "package:zo/zo.dart";

class FormPage extends StatefulWidget {
  const FormPage({super.key});

  @override
  State<FormPage> createState() => _FormPageState();
}

class _FormPageState extends State<FormPage> {
  bool open = true;

  var value = 0.0;

  bool? checkValue = false;

  String radioValue = "type1";

  bool switchValue = false;

  String selectedValue = "type1";

  DateTime dateTime = DateTime.now();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
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
                  onTap: () {
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
                  onTap: () {
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
                  onTap: () {
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
                  onTap: () {
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
                  onTap: () {
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
                  onTap: () {
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
                    onChanged: (value) {
                      print("val: $value");
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
}

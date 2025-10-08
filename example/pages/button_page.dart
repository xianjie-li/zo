import "package:flutter/material.dart";
import "package:zo/zo.dart";

class ButtonPage extends StatefulWidget {
  const ButtonPage({super.key});

  @override
  State<ButtonPage> createState() => _ButtonPageState();
}

class _ButtonPageState extends State<ButtonPage> {
  bool open = true;

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
              spacing: 4,
              children: [
                ZoButton(
                  child: Text("常规按钮"),
                  onTap: () {
                    print("onTap");
                    return Future.delayed(Duration(seconds: 1));
                  },
                  onContextAction: (event) {
                    print("onContextAction");
                  },
                ),
                ZoButton(
                  primary: true,
                  child: Text("主色按钮"),
                ),
                ZoButton(
                  primary: true,
                  child: Text("主色按钮"),
                  loading: true,
                ),
                ZoButton(
                  primary: true,
                  child: Text("主色按钮"),
                  loading: true,
                  size: ZoSize.small,
                ),
                ZoButton(
                  size: ZoSize.small,
                  icon: Icon(Icons.ac_unit),
                  child: Text("图标文字按钮"),
                ),
                ZoButton(
                  icon: Icon(Icons.ac_unit),
                  child: Text("图标文字按钮"),
                ),
                ZoButton(
                  size: ZoSize.large,
                  icon: Icon(Icons.ac_unit),
                  child: Text("图标文字按钮"),
                ),
                ZoButton(
                  primary: true,
                  icon: Icon(Icons.ac_unit),
                  child: Text("图标文字按钮"),
                ),
              ],
            ),
            SizedBox(height: 24),
            Row(
              spacing: 4,
              children: [
                ZoButton(
                  child: Text("常规按钮"),
                  enabled: false,
                ),
                ZoButton(
                  primary: true,
                  child: Text("主色按钮"),
                  enabled: false,
                ),
                ZoButton(
                  icon: Icon(Icons.ac_unit),
                  enabled: false,
                ),
                ZoButton(
                  plain: true,
                  primary: true,
                  icon: Icon(Icons.access_time),
                  enabled: false,
                ),
                ZoButton(
                  plain: true,
                  child: Text("文本按钮"),
                  enabled: false,
                ),
              ],
            ),
            SizedBox(height: 24),
            Row(
              spacing: 4,
              children: [
                ZoButton(
                  size: ZoSize.small,
                  icon: Icon(Icons.ac_unit),
                ),
                ZoButton(
                  icon: Icon(Icons.ac_unit),
                ),
                ZoButton(
                  primary: true,
                  icon: Icon(Icons.access_time),
                ),
                ZoButton(
                  icon: Icon(Icons.ac_unit),
                ),
                ZoButton(
                  primary: true,
                  icon: Icon(Icons.access_time),
                ),
                ZoButton(
                  primary: true,
                  icon: Icon(Icons.access_time),
                  size: ZoSize.large,
                ),
              ],
            ),
            SizedBox(height: 24),
            Row(
              spacing: 4,
              children: [
                ZoButton(
                  plain: true,
                  icon: Icon(Icons.ac_unit),
                ),
                ZoButton(
                  plain: true,
                  primary: true,
                  icon: Icon(Icons.access_time),
                ),
                ZoButton(
                  plain: true,
                  child: Text("文本按钮"),
                ),
                ZoButton(
                  plain: true,
                  primary: true,
                  child: Text("文本按钮"),
                ),
              ],
            ),
            SizedBox(height: 24),
            Row(
              spacing: 4,
              children: [
                ZoButton(
                  size: ZoSize.small,
                  plain: true,
                  icon: Icon(Icons.ac_unit),
                ),
                ZoButton(
                  plain: true,
                  icon: Icon(Icons.ac_unit),
                ),
                ZoButton(
                  size: ZoSize.large,
                  plain: true,
                  icon: Icon(Icons.ac_unit),
                ),
                ZoButton(
                  size: ZoSize.small,
                  plain: true,
                  child: Text("文本按钮"),
                ),
                ZoButton(
                  primary: true,
                  plain: true,
                  child: Text("文本按钮"),
                ),
                ZoButton(
                  size: ZoSize.large,
                  primary: true,
                  plain: true,
                  child: Text("文本按钮"),
                ),
                ZoButton(
                  size: ZoSize.small,
                  child: Text("小型按钮"),
                ),
                ZoButton(
                  child: Text("常规按钮"),
                ),
                ZoButton(
                  size: ZoSize.large,
                  child: Text("大型按钮"),
                ),
                ZoButton(
                  primary: true,
                  size: ZoSize.small,
                  child: Text("小型按钮"),
                ),
                ZoButton(
                  primary: true,
                  child: Text("常规按钮"),
                ),
                ZoButton(
                  primary: true,
                  size: ZoSize.large,
                  child: Text("大型按钮"),
                ),
              ],
            ),
            SizedBox(height: 24),
            Row(
              spacing: 4,
              children: [
                ZoButton(
                  color: Colors.red,
                  child: Text("颜色扩展"),
                ),
                ZoButton(
                  color: Colors.blue,
                  child: Text("颜色扩展"),
                ),
                ZoButton(
                  color: Colors.pink.shade100,
                  child: Text("颜色扩展"),
                ),
                ZoButton(
                  color: Colors.orange.shade100,
                  child: Text("颜色扩展"),
                ),
                ZoButton(
                  color: const Color.fromARGB(255, 234, 234, 234),
                  child: Text("颜色扩展"),
                ),

                ZoInteractiveBox(
                  border: Border.all(color: Colors.red),
                  activeBorder: Border.all(color: Colors.blue),
                  // color: Colors.red,
                  // plain: true,
                  // enabled: false,
                  interactive: false,
                  onTap: (e) {
                    print(123);
                  },
                  child: Container(
                    width: 200,
                    height: 100,
                    child: Row(
                      children: [
                        Icon(Icons.cabin_outlined),
                        Text("hello world"),
                      ],
                    ),
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

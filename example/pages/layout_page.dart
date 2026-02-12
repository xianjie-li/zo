import "package:flutter/material.dart";
import "package:zo/src/interactive_box/interactive_box.dart";
import "package:zo/src/tile/tile.dart";
import "package:zo/zo.dart";

import "widgets/title.dart";

class LayoutPage extends StatefulWidget {
  const LayoutPage({super.key});

  @override
  State<LayoutPage> createState() => _LayoutPageState();
}

class _LayoutPageState extends State<LayoutPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageTitle("ZoAdaptiveLayout"),
            Text("根据容器尺寸不同, 盒子会显示不同的颜色"),
            SizedBox(height: 12),
            ZoAdaptiveLayout<Color>(
              values: {
                ZoAdaptiveLayoutPointType.xs: Colors.red.shade300,
                ZoAdaptiveLayoutPointType.md: Colors.blue.shade300,
                ZoAdaptiveLayoutPointType.xl: Colors.green.shade300,
              },
              builder: (context, meta, child) {
                var text = "";

                if (meta.isSmall) {
                  text = "小屏";
                } else if (meta.isMedium) {
                  text = "中屏";
                } else if (meta.isLarge) {
                  text = "大屏";
                }

                return Container(
                  padding: EdgeInsets.all(16),
                  width: double.infinity,
                  color: meta.value,
                  child: Text(text, style: TextStyle(color: Colors.white)),
                );
              },
            ),
            SizedBox(height: 12),
            Text("根据容器尺寸不同, 盒子的尺寸会不同"),
            SizedBox(height: 12),
            ZoAdaptiveLayout(
              builder: (context, meta, child) {
                var width = 0.0;
                var text = "";

                if (meta.isSmall) {
                  width = 240;
                  text = "小屏";
                } else if (meta.isMedium) {
                  width = 400;
                  text = "中屏";
                } else if (meta.isLarge) {
                  width = 500;
                  text = "大屏";
                }

                return Container(
                  padding: EdgeInsets.all(16),
                  width: width,
                  color: Colors.blue.shade300,
                  child: Text(text, style: TextStyle(color: Colors.white)),
                );
              },
            ),
            PageTitle("ZoCells"),
            Text("使用 ZoCells 进行栅格系统布局"),
            SizedBox(height: 12),

            ZoCells(
              runSpacing: 12,
              spacing: 12,
              children: [
                ZoCell(
                  span: 12,
                  child: Container(color: Colors.grey.shade300, height: 30),
                ),
                ZoCell(
                  span: 4,
                  child: Container(color: Colors.grey.shade300, height: 30),
                ),
                ZoCell(
                  span: 4,
                  child: Container(color: Colors.grey.shade300, height: 30),
                ),
                ZoCell(
                  span: 4,
                  child: Container(color: Colors.grey.shade300, height: 30),
                ),
                ZoCell(
                  span: 6,
                  child: Container(color: Colors.grey.shade300, height: 30),
                ),
                ZoCell(
                  span: 3,
                  child: Container(color: Colors.grey.shade300, height: 30),
                ),
                ZoCell(
                  span: 3,
                  child: Container(color: Colors.grey.shade300, height: 30),
                ),
                ZoCell(
                  span: 3,
                  child: Container(color: Colors.grey.shade300, height: 30),
                ),
                ZoCell(
                  span: 1,
                  child: Container(color: Colors.grey.shade300, height: 30),
                ),
                ZoCell(
                  span: 8,
                  child: Container(color: Colors.grey.shade300, height: 30),
                ),
                ZoCell(
                  span: 3,
                  child: Container(color: Colors.grey.shade300, height: 30),
                ),
                ZoCell(
                  span: 3,
                  child: Container(color: Colors.grey.shade300, height: 30),
                ),
                ZoCell(
                  span: 6,
                  child: Container(color: Colors.grey.shade300, height: 30),
                ),
                ZoCell(
                  span: 2.4,
                  child: Container(color: Colors.grey.shade300, height: 30),
                ),
                ZoCell(
                  span: 2.4,
                  child: Container(color: Colors.grey.shade300, height: 30),
                ),
                ZoCell(
                  span: 2.4,
                  child: Container(color: Colors.grey.shade300, height: 30),
                ),
                ZoCell(
                  span: 2.4,
                  child: Container(color: Colors.grey.shade300, height: 30),
                ),
                ZoCell(
                  span: 2.4,
                  child: Container(color: Colors.grey.shade300, height: 30),
                ),
              ],
            ),
            SizedBox(height: 12),
            Text("结合 ZoAdaptiveLayout 和 ZoCells, 可以很简单的实现响应式栅格"),
            SizedBox(height: 12),
            ZoAdaptiveLayout<double>(
              values: {
                ZoAdaptiveLayoutPointType.xs: 12,
                ZoAdaptiveLayoutPointType.md: 6,
                ZoAdaptiveLayoutPointType.xl: 4,
                ZoAdaptiveLayoutPointType.xxl: 3,
              },
              builder: (context, meta, child) {
                return ZoCells(
                  runSpacing: 12,
                  spacing: 12,
                  children: List.generate(7, (ind) {
                    return ZoCell(
                      span: meta.value,
                      child: Container(color: Colors.grey.shade300, height: 30),
                    );
                  }),
                );
              },
            ),
            PageTitle("Grid"),
            Text("使用 ZoCells + AspectRatio 实现网格布局"),
            SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border(left: BorderSide(), top: BorderSide()),
              ),
              width: 500,
              child: ZoCells(
                children: List.generate(6, (ind) {
                  return ZoCell(
                    span: 4,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(),
                            right: BorderSide(),
                          ),
                        ),
                        child: Text("hello"),
                      ),
                    ),
                  );
                }),
              ),
            ),
            PageTitle("ZoInteractiveBox"),
            SizedBox(height: 12),
            SizedBox(
              width: 500,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  ZoInteractiveBox(child: Text("这是一段标题")),
                  ZoInteractiveBox(
                    style: ZoInteractiveBoxStyle.border,
                    child: Text("这是一段标题"),
                  ),
                  ZoInteractiveBox(
                    style: ZoInteractiveBoxStyle.filled,
                    child: Text("这是一段标题"),
                  ),
                  ZoInteractiveBox(
                    enabled: false,
                    child: Text("这是一段标题 disabled"),
                  ),
                  ZoInteractiveBox(
                    enabled: false,
                    style: ZoInteractiveBoxStyle.border,
                    child: Text("这是一段标题 disabled + border"),
                  ),
                  ZoInteractiveBox(
                    enabled: false,
                    style: ZoInteractiveBoxStyle.filled,
                    child: Text("这是一段标题 disabled + filled"),
                  ),
                  ZoInteractiveBox(
                    highlight: true,
                    child: Text("这是一段标题 highlight"),
                  ),
                  ZoInteractiveBox(
                    highlight: true,
                    style: ZoInteractiveBoxStyle.border,
                    child: Text("这是一段标题 highlight + border"),
                  ),
                  ZoInteractiveBox(
                    highlight: true,
                    style: ZoInteractiveBoxStyle.filled,
                    child: Text("这是一段标题 highlight + filled"),
                  ),
                  ZoInteractiveBox(
                    selected: true,
                    child: Text("这是一段标题 selected"),
                  ),
                  ZoInteractiveBox(
                    selected: true,
                    style: ZoInteractiveBoxStyle.border,
                    child: Text("这是一段标题 selected + border"),
                  ),
                  ZoInteractiveBox(
                    selected: true,
                    style: ZoInteractiveBoxStyle.filled,
                    child: Text("这是一段标题 selected + filled"),
                  ),
                  ZoInteractiveBox(
                    style: ZoInteractiveBoxStyle.normal,
                    status: ZoStatus.info,
                    child: Text("这是一段标题 info"),
                  ),
                  ZoInteractiveBox(
                    style: ZoInteractiveBoxStyle.filled,
                    status: ZoStatus.success,
                    child: Text("这是一段标题 success"),
                  ),
                  ZoInteractiveBox(
                    style: ZoInteractiveBoxStyle.border,
                    status: ZoStatus.warning,
                    child: Text("这是一段标题 warning + border"),
                  ),
                  ZoInteractiveBox(
                    style: ZoInteractiveBoxStyle.border,
                    status: ZoStatus.error,
                    child: Text("这是一段标题 error + border"),
                  ),

                  ZoInteractiveBox(
                    loading: true,
                    child: Text("这是一段标题"),
                    onTap: (event) {
                      print("tap");
                    },
                  ),
                  ZoInteractiveBox(
                    loading: true,
                    selected: true,
                    child: Text("这是一段标题"),
                    onTap: (event) {
                      print("tap");
                    },
                  ),

                  ZoInteractiveBox(
                    interactive: false,
                    child: Text("这是一段标题 interactive: false"),
                    style: ZoInteractiveBoxStyle.filled,
                  ),

                  ZoInteractiveBox(
                    color: Colors.red,
                    child: Text("这是一段标题 自定义颜色-深"),
                  ),

                  ZoInteractiveBox(
                    color: Colors.red.shade100,
                    child: Text("这是一段标题 自定义颜色-浅"),
                  ),

                  ZoInteractiveBox(
                    selected: true,
                    selectedColor: Colors.blue,
                    child: Text("这是一段标题 selectedColor"),
                  ),
                  ZoInteractiveBox(
                    highlight: true,
                    highlightColor: Colors.pink,
                    child: Text("这是一段标题 highlightColor"),
                  ),
                  ZoInteractiveBox(
                    enabled: false,
                    disabledColor: Colors.grey,
                    child: Text("这是一段标题 disabledColor"),
                  ),
                  ZoInteractiveBox(
                    activeColor: Colors.blue.shade300,
                    tapEffectColor: Colors.red.shade300,
                    child: Text("这是一段标题 activeColor tapEffectColor"),
                  ),

                  ZoInteractiveBox(
                    border: Border.all(color: Colors.red),
                    activeBorder: Border.all(color: Colors.blue),
                    child: Text("这是一段标题 border activeBorder"),
                  ),

                  ZoInteractiveBox(
                    selected: true,
                    selectedBorder: Border.all(color: Colors.red),
                    child: Text("这是一段标题 selectedBorder"),
                  ),

                  ZoInteractiveBox(
                    highlight: true,
                    highlightBorder: Border.all(color: Colors.blue),
                    child: Text("这是一段标题 highlightBorder"),
                  ),

                  ZoInteractiveBox(
                    enableFocusBorder: false,
                    child: Text("这是一段标题 focusBorder: false"),
                  ),

                  ZoInteractiveBox(
                    plain: true,
                    child: Text("这是一段标题 plain"),
                  ),

                  ZoInteractiveBox(
                    plain: true,
                    color: Colors.blue,
                    child: Text("这是一段标题 plain + color"),
                  ),

                  PageTitle("ZoInteractiveBox"),

                  ZoTile(
                    leading: Text("前置文本"),
                    header: Text("这是一段标题"),
                    content: Text(
                      "这是内容区域, 显示一些内容显示一些内容显示一些内容显示一些内容显示一些内容, 显示一些内容显示一些内容",
                      style: TextStyle(color: context.zoStyle.hintTextColor),
                    ),
                    trailing: Text("后置文本"),
                  ),
                  ZoTile(
                    leading: Icon(Icons.supervised_user_circle),
                    header: Text("这是一段标题"),
                    trailing: Icon(Icons.thermostat_sharp),
                  ),
                  ZoTile(
                    leading: Icon(Icons.supervised_user_circle),
                    header: Text("这是一段标题"),
                    content: Text(
                      "这是内容区域, 显示一些内容显示一些内容显示一些内容显示一些内容显示一些内容, 显示一些内容显示一些内容",
                      style: TextStyle(color: context.zoStyle.hintTextColor),
                    ),
                    trailing: Icon(Icons.thermostat_sharp),
                    footer: Row(
                      spacing: 12,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ZoButton(onTap: () {}, child: Text("取消")),
                        ZoButton(
                          primary: true,
                          onTap: () {},
                          child: Text("确认"),
                        ),
                      ],
                    ),
                  ),
                  ZoTile(
                    leading: Icon(Icons.supervised_user_circle),
                    header: Text("这是一段标题"),
                    content: Text(
                      "这是内容区域, 显示一些内容显示一些内容显示一些内容显示一些内容显示一些内容, 显示一些内容显示一些内容",
                      style: TextStyle(color: context.zoStyle.hintTextColor),
                    ),
                    trailing: Icon(Icons.thermostat_sharp),
                    innerFoot: true,
                    footer: Text(
                      "操作失败, 请稍后重试",
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                  ZoTile(
                    header: Text("这是一段标题"),
                    content: Text(
                      "这是内容区域, 显示一些内容显示一些内容显示一些内容显示一些内容显示一些内容, 显示一些内容显示一些内容",
                      style: TextStyle(color: context.zoStyle.hintTextColor),
                    ),
                    horizontal: true,
                    arrow: true,
                  ),
                  ZoTile(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    leading: Icon(Icons.supervised_user_circle),
                    header: Text("这是一段标题这"),
                    content: Text(
                      "这是内容区域, 显示一些内容显示一些内容显示一些内容显示一些内容显示一些内容, 显示一些内容显示一些内容显示一些内容显示一些内容显示一些内显示一些内容显示一些内容显示一些内显示一些内容显示一些内容显示一些内",
                      style: TextStyle(color: context.zoStyle.hintTextColor),
                    ),
                    trailing: Icon(Icons.thermostat_sharp),
                    innerFoot: true,
                    footer: Text(
                      "操作失败, 请稍后重试",
                      style: TextStyle(color: Colors.red),
                    ),
                    horizontal: true,
                    arrow: true,
                  ),
                  ZoTile(
                    leading: Icon(Icons.supervised_user_circle),
                    header: Text("这是一段标题"),
                    content: Text(
                      "这是内容区域, 显示一些内容显示一些内容显示一些内容显示一些内容显示一些内容, 显示一些内容显示一些内容",
                      style: TextStyle(color: context.zoStyle.hintTextColor),
                    ),
                    trailing: Icon(Icons.thermostat_sharp),
                    footer: Row(
                      spacing: 12,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ZoButton(onTap: () {}, child: Text("取消")),
                        ZoButton(
                          primary: true,
                          onTap: () {},
                          child: Text("确认"),
                        ),
                      ],
                    ),
                  ),

                  ZoTile(
                    header: Text("这是一段标题"),
                    content: Text(
                      "这是内容区域, 显示一些内容显示一些内容显示一些内容显示一些内容显示一些内容, 显示一些内容显示一些内容",
                      style: TextStyle(color: context.zoStyle.hintTextColor),
                    ),
                  ),
                  ZoTile(
                    leading: Icon(Icons.supervised_user_circle),
                    header: Text("这是一段标题"),
                    trailing: Icon(Icons.thermostat_sharp),
                  ),
                  ZoTile(
                    leading: Icon(Icons.supervised_user_circle),
                    header: Text("这是一段标题"),
                    content: Text(
                      "这是内容区域, 显示一些内容显示一些内容显示一些内容显示一些内容显示一些内容, 显示一些内容显示一些内容",
                      style: TextStyle(color: context.zoStyle.hintTextColor),
                    ),
                    trailing: Icon(Icons.thermostat_sharp),
                    footer: Row(
                      spacing: 12,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ZoButton(onTap: () {}, child: Text("取消")),
                        ZoButton(
                          primary: true,
                          onTap: () {},
                          child: Text("确认"),
                        ),
                      ],
                    ),
                  ),
                  ZoInteractiveBox(
                    status: ZoStatus.info,
                    child: ZoTile(
                      header: Text("这是一段标题"),
                      content: Text(
                        "这是内容区域, 显示一些内容显示一些内容显示一些内容显示一些内容显示一些内容, 显示一些内容显示一些内容",
                        style: TextStyle(
                          color: context.zoStyle.hintTextColor,
                        ),
                      ),
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
}

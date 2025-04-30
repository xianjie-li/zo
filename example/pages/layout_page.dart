import "package:flutter/material.dart";
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
    return SingleChildScrollView(
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
          PageTitle("ZoTile"),
          SizedBox(height: 12),
          SizedBox(
            width: 500,
            child: Column(
              spacing: 4,
              children: [
                ZoTile(header: Text("这是一段标题")),
                ZoTile(
                  header: Text("这是一段标题"),
                  content: Text(
                    "这是内容区域, 显示一些内容显示一些内容显示一些内容显示一些内容显示一些内容, 显示一些内容显示一些内容",
                    style: TextStyle(color: context.zoStyle.hintTextColor),
                  ),
                ),
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
                      FilledButton.tonal(onPressed: () {}, child: Text("取消")),
                      FilledButton(onPressed: () {}, child: Text("确认")),
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
                  rowContent: true,
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
                  rowContent: true,
                  arrow: true,
                ),

                ZoTile(header: Text("这是一段标题"), style: ZoTileStyle.border),
                ZoTile(
                  header: Text("这是一段标题"),
                  content: Text(
                    "这是内容区域, 显示一些内容显示一些内容显示一些内容显示一些内容显示一些内容, 显示一些内容显示一些内容",
                    style: TextStyle(color: context.zoStyle.hintTextColor),
                  ),
                  style: ZoTileStyle.border,
                ),
                ZoTile(
                  leading: Text("前置文本"),
                  header: Text("这是一段标题"),
                  content: Text(
                    "这是内容区域, 显示一些内容显示一些内容显示一些内容显示一些内容显示一些内容, 显示一些内容显示一些内容",
                    style: TextStyle(color: context.zoStyle.hintTextColor),
                  ),
                  trailing: Text("后置文本"),
                  style: ZoTileStyle.border,
                ),
                ZoTile(
                  leading: Icon(Icons.supervised_user_circle),
                  header: Text("这是一段标题"),
                  trailing: Icon(Icons.thermostat_sharp),
                  style: ZoTileStyle.border,
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
                      FilledButton.tonal(onPressed: () {}, child: Text("取消")),
                      FilledButton(onPressed: () {}, child: Text("确认")),
                    ],
                  ),
                  style: ZoTileStyle.border,
                ),

                ZoTile(header: Text("这是一段标题"), style: ZoTileStyle.color),
                ZoTile(
                  header: Text("这是一段标题"),
                  content: Text(
                    "这是内容区域, 显示一些内容显示一些内容显示一些内容显示一些内容显示一些内容, 显示一些内容显示一些内容",
                    style: TextStyle(color: context.zoStyle.hintTextColor),
                  ),
                  style: ZoTileStyle.color,
                ),
                ZoTile(
                  leading: Icon(Icons.supervised_user_circle),
                  header: Text("这是一段标题"),
                  trailing: Icon(Icons.thermostat_sharp),
                  style: ZoTileStyle.color,
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
                      FilledButton.tonal(onPressed: () {}, child: Text("取消")),
                      FilledButton(onPressed: () {}, child: Text("确认")),
                    ],
                  ),
                  style: ZoTileStyle.color,
                ),

                ZoTile(
                  enable: false,
                  header: Text(
                    "disabled 这是一段标题",
                    style: TextStyle(
                      fontSize: context.zoTextTheme.bodyLarge?.fontSize,
                    ),
                  ),
                  content: Text(
                    "这是内容区域, 显示一些内容显示一些内容显示一些内容显示一些内容显示一些内容, 显示一些内容显示一些内容",
                    style: TextStyle(color: context.zoStyle.hintTextColor),
                  ),
                  style: ZoTileStyle.color,
                ),
                ZoTile(
                  highlight: true,
                  header: Text(
                    "highlight 这是一段标题",
                    style: TextStyle(
                      fontSize: context.zoTextTheme.bodyLarge?.fontSize,
                    ),
                  ),
                  content: Text(
                    "这是内容区域, 显示一些内容显示一些内容显示一些内容显示一些内容显示一些内容, 显示一些内容显示一些内容",
                    style: TextStyle(color: context.zoStyle.hintTextColor),
                  ),
                  // style: ZoTileStyle.border,
                ),
                ZoTile(
                  active: true,
                  header: Text(
                    "active 这是一段标题",
                    style: TextStyle(
                      fontSize: context.zoTextTheme.bodyLarge?.fontSize,
                    ),
                  ),
                  content: Text(
                    "这是内容区域, 显示一些内容显示一些内容显示一些内容显示一些内容显示一些内容, 显示一些内容显示一些内容",
                    style: TextStyle(color: context.zoStyle.hintTextColor),
                  ),
                  // style: ZoTileStyle.border,
                ),
                ZoTile(
                  status: ZoStatus.info,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  header: Text(
                    "这是一段标题",
                    style: TextStyle(
                      fontSize: context.zoTextTheme.bodyLarge?.fontSize,
                    ),
                  ),
                  content: Text(
                    "这是内容区域, 显示一些内容显示一些内容显示一些内容显示一些内容显示一些内容, 显示一些内容显示一些内容",
                    style: TextStyle(color: context.zoStyle.hintTextColor),
                  ),
                  style: ZoTileStyle.border,
                ),
                ZoTile(
                  status: ZoStatus.success,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  header: Text(
                    "这是一段标题",
                    style: TextStyle(
                      fontSize: context.zoTextTheme.bodyLarge?.fontSize,
                    ),
                  ),
                  content: Text(
                    "这是内容区域, 显示一些内容显示一些内容显示一些内容显示一些内容显示一些内容, 显示一些内容显示一些内容",
                    style: TextStyle(color: context.zoStyle.hintTextColor),
                  ),
                  style: ZoTileStyle.border,
                ),
                ZoTile(
                  status: ZoStatus.warning,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  header: Text(
                    "这是一段标题",
                    style: TextStyle(
                      fontSize: context.zoTextTheme.bodyLarge?.fontSize,
                    ),
                  ),
                  content: Text(
                    "这是内容区域, 显示一些内容显示一些内容显示一些内容显示一些内容显示一些内容, 显示一些内容显示一些内容",
                    style: TextStyle(color: context.zoStyle.hintTextColor),
                  ),
                  // style: ZoTileStyle.border,
                ),
                ZoTile(
                  status: ZoStatus.error,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  header: Text(
                    "这是一段标题",
                    style: TextStyle(
                      fontSize: context.zoTextTheme.bodyLarge?.fontSize,
                    ),
                  ),
                  content: Text(
                    "这是内容区域, 显示一些内容显示一些内容显示一些内容显示一些内容显示一些内容, 显示一些内容显示一些内容",
                    style: TextStyle(color: context.zoStyle.hintTextColor),
                  ),
                  // style: ZoTileStyle.border,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

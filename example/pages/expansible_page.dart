import "dart:developer";

import "package:flutter/material.dart";
import "package:zo/zo.dart";

class ExpansiblePage extends StatefulWidget {
  const ExpansiblePage({super.key});

  @override
  State<ExpansiblePage> createState() => _ExpansiblePageState();
}

class _ExpansiblePageState extends State<ExpansiblePage> {
  int acceptedData = 0;

  ExpansibleController controller = ExpansibleController();

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final style = context.zoStyle;

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Wrap(
            runSpacing: 4,
            children: [
              ZoButton(
                child: Text("openAll"),
                onTap: () {
                  ZoExpanderState.openAll("12321");
                },
              ),
              ZoButton(
                child: Text("closeAll"),
                onTap: () {
                  ZoExpanderState.closeAll("12321");
                },
              ),
              ZoButton(
                child: Text("openToLevel"),
                onTap: () {
                  ZoExpanderState.openToLevel("12321", 0);
                },
              ),
              ZoExpander(
                key: PageStorageKey("myExpander"),
                title: Text("折叠面板1 fwfwqfwqf"),
                trailing: ZoButton(
                  size: ZoSize.small,
                  icon: Icon(Icons.more_horiz),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text('Hidden content revealed!'),
                    Text('Hidden content revealed!'),
                    LifeCycleTrigger(
                      initState: () {
                        print("initState");
                      },
                    ),
                    ZoExpander(
                      title: Text("折叠面板2-1 fwfwqfwqf"),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hidden content revealed!'),
                          Text('Hidden content revealed!'),
                          Text('Hidden content revealed!'),
                          Text('Hidden content revealed!'),
                        ],
                      ),
                    ),
                    ZoExpander(
                      title: Text("折叠面板2-2 fwfwqfwqf"),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Hidden content revealed!'),
                          Text('Hidden content revealed!'),
                          Text('Hidden content revealed!'),
                          Text('Hidden content revealed!'),
                        ],
                      ),
                    ),
                    Text('Hidden content revealed!'),
                  ],
                ),
              ),
              ZoExpander(
                size: ZoSize.small,
                title: Text("折叠面板2-2 fwfwqfwqf"),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hidden content revealed!'),
                    Text('Hidden content revealed!'),
                    Text('Hidden content revealed!'),
                    Text('Hidden content revealed!'),
                  ],
                ),
              ),
              ZoExpander(
                title: Text("折叠面板2-2 fwfwqfwqf"),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hidden content revealed!'),
                    Text('Hidden content revealed!'),
                    Text('Hidden content revealed!'),
                    Text('Hidden content revealed!'),
                  ],
                ),
              ),
              ZoExpander(
                indentLine: true,
                enable: false,
                title: Text("折叠面板2-2 fwfwqfwqf"),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hidden content revealed!'),
                  ],
                ),
              ),
              ZoExpander(
                size: ZoSize.large,
                title: Text("折叠面板2-2 fwfwqfwqf"),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hidden content revealed!'),
                    Text('Hidden content revealed!'),
                    Text('Hidden content revealed!'),
                    Text('Hidden content revealed!'),
                  ],
                ),
              ),
              ZoExpander(
                title: Text("折叠面板2 fwfwqfwqf"),
                describe: Text(
                  "这是一段子内容，描述了次要信息",
                  style: TextStyle(
                    color: style.hintTextColor,
                    fontSize: style.fontSizeSM,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Hidden content revealed!'),
                    Text('Hidden content revealed!'),
                    Text('Hidden content revealed!'),
                    Text('Hidden content revealed!'),
                  ],
                ),
              ),

              Container(
                height: 100,
                decoration: BoxDecoration(border: Border.all()),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

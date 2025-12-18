import "dart:async";

import "package:flutter/material.dart";
import "package:zo/src/tabs/tabs.dart";
import "package:zo/zo.dart";

class TabsPage extends StatefulWidget {
  const TabsPage({super.key});

  @override
  State<TabsPage> createState() => _TabsPageState();
}

class _TabsPageState extends State<TabsPage> {
  List<ZoTabsEntry> list = [
    ZoTabsEntry(label: "标签一", value: "1", icon: Icon(Icons.home)),
    ZoTabsEntry(label: "标签二", value: "2", icon: Icon(Icons.ac_unit)),
    ZoTabsEntry(
      label: "标签三标签三标签三",
      value: "3",
      icon: Icon(Icons.ac_unit),
    ),
    for (int i = 0; i < 3; i++)
      ZoTabsEntry(
        label: "标签${i + 4}",
        value: "${i + 4}",
        icon: Icon(Icons.settings),
      ),
  ];

  List<ZoTabsEntry> list2 = [
    ZoTabsEntry(label: "标签一", value: "1", icon: Icon(Icons.home)),
    ZoTabsEntry(label: "标签二", value: "2", icon: Icon(Icons.ac_unit)),
    ZoTabsEntry(
      label: "标签二",
      value: "3",
      icon: Icon(Icons.ac_unit),
    ),
    for (int i = 0; i < 10; i++)
      ZoTabsEntry(
        label: "标签${i + 4}",
        value: "${i + 4}",
        icon: Icon(Icons.settings),
      ),
  ];

  List<ZoTabsEntry> list3 = [
    ZoTabsEntry(label: "标签一", value: "1", icon: Icon(Icons.home)),
    ZoTabsEntry(label: "标签二", value: "2", icon: Icon(Icons.ac_unit)),
    ZoTabsEntry(
      label: "标签三标签三标签三",
      value: "3",
      icon: Icon(Icons.ac_unit),
    ),
    for (int i = 0; i < 30; i++)
      ZoTabsEntry(
        label: "标签${i + 4}",
        value: "${i + 4}",
        icon: Icon(Icons.settings),
      ),
  ];

  final value = ["2"];

  List<Object> pinedTabs = ["4", "5"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            width: 510,
            decoration: BoxDecoration(border: Border.all()),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              spacing: 8,
              children: [
                SizedBox(
                  width: 164,
                  child: ZoTabs(
                    tabs: list3,
                    value: value,
                    direction: Axis.vertical,
                  ),
                ),
                SizedBox(
                  width: 164,
                  child: ZoTabs(
                    tabs: list3,
                    value: value,
                    direction: Axis.vertical,
                    size: ZoSize.large,
                    showBorder: true,
                    pinedTabs: pinedTabs,
                    leading: Center(
                      child: Text("Custom Leading"),
                    ),
                    trailing: Center(
                      child: Text("Custom Trailing"),
                    ),
                    markers: const {"1"},
                  ),
                ),
                SizedBox(
                  width: 164,
                  child: ZoTabs(
                    tabs: list3,
                    value: value,
                    direction: Axis.vertical,
                    type: ZoTabsType.flat,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    ZoTabs(
                      tabs: list,
                      size: ZoSize.small,
                      value: value,
                    ),
                    ZoTabs(
                      tabs: list,
                      value: value,
                      pinedTabs: pinedTabs,
                      size: ZoSize.small,

                      markers: const {"4"},
                      onPinedTabsChanged: (value) {
                        setState(() {
                          pinedTabs = value;
                        });
                      },
                      leading: Text("Custom Leading"),
                      trailing: Text("Custom Trailing"),
                      fixedTrailing: ZoButton(
                        icon: Icon(Icons.settings),
                      ),
                      onCloseConfirm: (entry) {
                        final completer = Completer<bool>();

                        bool isConfirm = false;

                        zoOverlay.open(
                          ZoDialog(
                            title: Text("提示"),
                            barrier: false,
                            tapAwayClosable: false,
                            content: Text(
                              "确认要关闭 ${entry.value} 吗？",
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
                    ),
                    ZoTabs(
                      tabs: list,
                      showBorder: true,
                      value: value,
                      tabMinWidth: 150,
                      alwaysShowCloseButton: false,
                      markers: const {"1"},
                    ),
                    ZoTabs(
                      tabs: list,
                      size: ZoSize.large,
                      value: value,
                      markers: const {"1"},
                    ),
                    ZoTabs(
                      tabs: list,
                      size: ZoSize.large,
                      value: value,
                      showBorder: true,
                    ),
                    Text("背景覆盖"),
                    Container(
                      padding: EdgeInsets.all(4),
                      color: context.zoStyle.hoverColor,
                      child: ZoTabs(
                        tabs: list,
                        value: value,
                        // color: Colors.white,
                        activeColor: Colors.white.withAlpha(230),
                        hoverColor: Colors.white.withAlpha(200),
                        tapEffectColor: Colors.black.withAlpha(5),
                      ),
                    ),
                    Text("flat"),
                    ZoTabs(
                      tabs: list,
                      value: value,
                      type: ZoTabsType.flat,
                    ),
                    ZoTabs(
                      tabs: list,
                      value: value,
                      type: ZoTabsType.flat,
                      showBorder: true,
                    ),
                    Container(
                      width: double.infinity,
                      child: Text("wrap"),
                    ),
                    ZoTabs(
                      tabs: list2,
                      value: value,
                      wrapTabs: true,
                      leading: Text("Custom Leading"),
                      trailing: Text("Custom Trailing"),
                      fixedTrailing: ZoButton(
                        icon: Icon(Icons.settings),
                      ),
                    ),
                    ZoTabs(
                      tabs: list2,
                      value: value,
                      wrapTabs: true,
                      showBorder: true,
                    ),
                    ZoTabs(
                      tabs: list2,
                      value: value,
                      wrapTabs: true,
                      showBorder: true,
                      type: ZoTabsType.flat,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

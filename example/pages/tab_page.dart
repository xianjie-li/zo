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
    ZoTabsEntry(label: "标签a一", value: "a1", icon: Icon(Icons.home)),
    ZoTabsEntry(label: "标签a二", value: "a2", icon: Icon(Icons.ac_unit)),
    ZoTabsEntry(
      label: "标签a三标签三标签三",
      value: "a3",
      icon: Icon(Icons.ac_unit),
    ),
    for (int i = 0; i < 3; i++)
      ZoTabsEntry(
        label: "标签a${i + 4}",
        value: "a${i + 4}",
        icon: Icon(Icons.settings),
      ),
  ];

  List<ZoTabsEntry> list2 = [
    ZoTabsEntry(label: "标签b一", value: "b1", icon: Icon(Icons.home)),
    ZoTabsEntry(label: "标签b二", value: "b2", icon: Icon(Icons.ac_unit)),
    ZoTabsEntry(
      label: "标签b二",
      value: "b3",
      icon: Icon(Icons.ac_unit),
    ),
    for (int i = 0; i < 10; i++)
      ZoTabsEntry(
        label: "标签b${i + 4}",
        value: "b${i + 4}",
        icon: Icon(Icons.settings),
      ),
  ];

  List<ZoTabsEntry> list3 = [
    ZoTabsEntry(label: "标签c一", value: "c1", icon: Icon(Icons.home)),
    ZoTabsEntry(label: "标签c二", value: "c2", icon: Icon(Icons.ac_unit)),
    ZoTabsEntry(
      label: "标签c三标签三标签三",
      value: "c3",
      icon: Icon(Icons.ac_unit),
    ),
    for (int i = 0; i < 30; i++)
      ZoTabsEntry(
        label: "标签c${i + 4}",
        value: "c${i + 4}",
        icon: Icon(Icons.settings),
      ),
  ];

  final value = ["2"];

  List<Object> pinedTabs = ["a4", "a5"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            width: 170,
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
                      customContextMenu: (internalActions) {
                        return [
                          ZoOption(value: "123", title: Text("Do Nothing")),
                        ];
                      },
                      onContextMenuTrigger: (action) {
                        print("${action.option.value}");
                        return true;
                      },
                      enableContextMenu: true,
                    ),
                    ZoTabs(
                      tabs: list,
                      value: value,
                      pinedTabs: pinedTabs,
                      pinedTabsOnlyShowIcon: true,
                      size: ZoSize.small,
                      enableContextMenu: true,
                      markers: const {"a4"},
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
                      markers: const {"a1"},
                      pinedTabs: pinedTabs,
                      pinedTabsOnlyShowIcon: true,
                    ),
                    ZoTabs(
                      tabs: list,
                      size: ZoSize.large,
                      value: value,
                      markers: const {"a1"},
                      labelMaxWidth: 100,
                      autoTooltip: true,
                    ),
                    ZoTabs(
                      tabs: list,
                      size: ZoSize.large,
                      value: value,
                      showBorder: true,
                      pinedTabs: pinedTabs,
                      markers: const {"a1"},
                      pinedTabsOnlyShowIcon: true,
                      labelMaxWidth: 100,
                      autoTooltip: true,
                    ),
                    Text("背景覆盖"),
                    Container(
                      padding: EdgeInsets.all(4),
                      color: context.zoStyle.hoverColor,
                      child: ZoTabs(
                        tabs: list,
                        value: value,
                        // color: Colors.white,
                        selectedColor: Colors.white.withAlpha(230),
                        activeColor: Colors.white.withAlpha(200),
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
                      selectionType: ZoSelectionType.multiple,
                    ),
                    ZoTabs(
                      tabs: list3,
                      value: value,
                      wrapTabs: true,
                      showBorder: true,
                      onChanged: (newValue) {
                        print("newValue ${newValue}");
                      },
                      transitionActiveStatus: true,
                    ),
                    ZoTabs(
                      tabs: list,
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

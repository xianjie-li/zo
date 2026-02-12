import "dart:async";
import "dart:developer";

import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:zo/src/button/button.dart";
import "package:zo/src/dialog/dialog.dart";
import "package:zo/src/dnd/dnd.dart";
import "package:zo/src/trigger/trigger.dart";
import "package:zo/zo.dart";

import "play.dart";

class TogglePage extends StatefulWidget {
  const TogglePage({super.key});

  @override
  State<TogglePage> createState() => _TogglePageState();
}

class _TogglePageState extends State<TogglePage> {
  @override
  void initState() {
    super.initState();
  }

  ZoToggleGroupState? groupState;

  ZoToggleGroupState? groupState2;

  Set<Object>? list = <Object>{1, 4};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              const ZoToggle(
                type: ZoToggleType.checkbox,
                size: ZoSize.small,
              ),
              const ZoToggle(
                type: ZoToggleType.checkbox,
              ),
              const ZoToggle(
                type: ZoToggleType.checkbox,
                enable: false,
              ),
              const ZoToggle(
                type: ZoToggleType.checkbox,
                enable: false,
                value: true,
              ),
              const ZoToggle(
                type: ZoToggleType.checkbox,
                enable: false,
                value: false,
                indeterminate: true,
              ),
              const ZoToggle(
                type: ZoToggleType.checkbox,
                size: ZoSize.large,
              ),

              const ZoToggle(
                type: ZoToggleType.checkbox,
                enable: false,
                value: false,
                indeterminate: true,
                prefix: Text("开始选项"),
                suffix: Text("关闭选项"),
              ),

              const ZoToggle(
                type: ZoToggleType.checkbox,
                borderColor: Colors.red,
                activeBorderColor: Colors.purple,
                color: Colors.amber,
                activeColor: Colors.cyanAccent,
              ),

              const ZoToggle(
                type: ZoToggleType.checkbox,
                indeterminate: true,
                size: ZoSize.small,
              ),
              const ZoToggle(
                type: ZoToggleType.checkbox,
                indeterminate: true,
              ),
              const ZoToggle(
                type: ZoToggleType.checkbox,
                indeterminate: true,
              ),

              const Divider(),

              const ZoToggle(
                type: ZoToggleType.radio,
                size: ZoSize.small,
              ),
              const ZoToggle(
                type: ZoToggleType.radio,
              ),
              const ZoToggle(
                type: ZoToggleType.radio,
                enable: false,
              ),
              const ZoToggle(
                type: ZoToggleType.radio,
                enable: false,
                value: true,
              ),
              const ZoToggle(
                type: ZoToggleType.radio,
                size: ZoSize.large,
              ),
              const ZoToggle(
                type: ZoToggleType.radio,
                prefix: Text("开始选项"),
                suffix: Text("关闭选项"),
              ),

              const Divider(),

              const ZoToggle(
                type: ZoToggleType.switcher,
                size: ZoSize.small,
              ),

              const ZoToggle(
                type: ZoToggleType.switcher,
              ),

              const ZoToggle(
                type: ZoToggleType.switcher,
                value: true,
                enable: false,
              ),

              const ZoToggle(
                type: ZoToggleType.switcher,
                value: false,
                enable: false,
              ),

              const ZoToggle(
                type: ZoToggleType.switcher,
                size: ZoSize.large,
              ),

              const ZoToggle(
                type: ZoToggleType.switcher,
                prefix: Text("开始选项"),
                suffix: Text("关闭选项"),
              ),

              const Divider(),

              ZoToggleGroup(
                ref: (state) {
                  groupState = state;
                },
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    const ZoToggle(
                      type: ZoToggleType.checkbox,
                      groupValue: 1,
                      suffix: Text("选项 1"),
                    ),
                    const ZoToggle(
                      type: ZoToggleType.checkbox,
                      groupValue: 2,
                      suffix: Text("选项 2"),
                    ),
                    const ZoToggle(
                      type: ZoToggleType.checkbox,
                      groupValue: 3,
                      suffix: Text("选项 3"),
                    ),
                    const ZoToggle(
                      type: ZoToggleType.checkbox,
                      groupValue: 4,
                      suffix: Text("选项 4"),
                    ),

                    ZoButton(
                      child: Text("print options"),
                      onTap: () {
                        print(groupState?.options);
                      },
                    ),
                    ZoButton(
                      child: Text("getSelected"),
                      onTap: () {
                        print(groupState?.selector.getSelected());
                      },
                    ),
                    ZoButton(
                      child: Text("getSelectedFull"),
                      onTap: () {
                        inspect(groupState?.selector.getSelectionState());
                      },
                    ),
                    ZoButton(
                      child: Text("toggle"),
                      onTap: () {
                        groupState?.selector.toggleAll();
                      },
                    ),
                  ],
                ),
              ),

              ZoToggleGroup(
                ref: (state) => groupState2 = state,
                value: list,
                enable: false,
                onChanged: (newValue) {
                  setState(() {
                    list = newValue?.toSet();
                  });
                },
                child: Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    const ZoToggle(
                      type: ZoToggleType.checkbox,
                      groupValue: 1,
                      suffix: Text("选项 1"),
                    ),
                    const ZoToggle(
                      type: ZoToggleType.checkbox,
                      groupValue: 2,
                      suffix: Text("选项 2"),
                    ),
                    const ZoToggle(
                      type: ZoToggleType.checkbox,
                      groupValue: 3,
                      suffix: Text("选项 3"),
                    ),
                    ZoToggle(
                      type: ZoToggleType.checkbox,
                      groupValue: 4,
                      suffix: Text("选项 4"),
                    ),

                    Text("list ${list}"),
                    ZoButton(
                      child: Text("update"),
                      onTap: () {
                        setState(() {
                          list = {1, 3};
                        });
                      },
                    ),
                    ZoButton(
                      child: Text("toggle"),
                      onTap: () {
                        groupState2?.selector.toggleAll();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

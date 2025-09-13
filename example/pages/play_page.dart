import "package:flutter/material.dart";
import "package:zo/src/button/button.dart";
import "package:zo/src/dialog/dialog.dart";
import "package:zo/src/trigger/trigger.dart";
import "package:zo/zo.dart";

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  late final ZoDialog dialog;

  @override
  void initState() {
    super.initState();

    dialog = ZoDialog(
      barrier: false,
      tapAwayClosable: false,
      escapeClosable: false,
      dismissMode: ZoOverlayDismissMode.close,
      offset: Offset(100, 100),
      builder: (context) {
        return ZoTrigger(
          child: Container(
            width: 200,
            height: 200,
            color: Colors.pink.shade100,
          ),
          changeCursor: true,
          // onTap: (value) {
          //   print("onTap: $value");
          // },
          // onTapDown: (value) {
          //   print("onTapDown: $value");
          // },
          // onActiveChanged: (value) {
          //   print("onActiveChanged: $value");
          // },
          // onFocusChanged: (value) {
          //   print("onFocusChanged: $value");
          // },
          // onContextMenu: (value) {
          //   print("onContextMenu: $value");
          // },
          // onMove: (value) {
          //   print("onMove: $value");
          // },
          onDrag: (event) {
            dialog.offset = dialog.offset! + event.delta;

            if (event.last) {
              // dialog.offset = Offset.zero;
            }
          },
          // onTrigger: (e) {},
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ZoButton(
              child: Text('打开弹窗'),
              onTap: () {
                zoOverlay.open(dialog);
              },
            ),
            ZoTrigger(
              onTap: (value) {
                print("点击1");
              },
              child: Container(
                width: 150,
                height: 150,
                color: Colors.red,
                child: ZoTrigger(
                  onActiveChanged: (value) {
                    print(value);
                  },
                  child: UnconstrainedBox(
                    child: Container(
                      width: 50,
                      height: 50,
                      color: Colors.blue,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

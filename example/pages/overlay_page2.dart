import "dart:math" as math;

import "package:flutter/material.dart";
import "package:zo/src/overlay/overlay.dart";
import "package:zo/zo.dart";

class OverlayPage2 extends StatefulWidget {
  const OverlayPage2({super.key});

  @override
  State<OverlayPage2> createState() => _OverlayPage2State();
}

class _OverlayPage2State extends State<OverlayPage2> {
  Future<bool?> _showBackDialog() {
    return showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Are you sure?'),
          content: const Text('Are you sure you want to leave this page?'),
          actions: <Widget>[
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Nevermind'),
              onPressed: () {
                Navigator.pop(context, false);
              },
            ),
            TextButton(
              style: TextButton.styleFrom(
                textStyle: Theme.of(context).textTheme.labelLarge,
              ),
              child: const Text('Leave'),
              onPressed: () {
                Navigator.pop(context, true);
              },
            ),
          ],
        );
      },
    );
  }

  late final overlay1 = ZoOverlayEntry(
    alignment: Alignment(0, -0.5),
    route: true,
    builder: (BuildContext context) {
      return Container(
        width: 150,
        height: 150,
        color: Colors.red,
        child: Center(child: _Counter()),
      );
    },
    transitionType: ZoTransitionType.slideTop,
    // barrier: true,
    // tapAwayClosable: true,
    dismissMode: ZoOverlayDismissMode.close,
    mayDismiss: () => false,
    onDismiss: onDismiss,
  );

  void onDismiss(bool didDismiss, dynamic result) async {
    print("didDismiss $didDismiss result $result");

    if (didDismiss) {
      return;
    }

    final bool shouldPop = await _showBackDialog() ?? false;
    if (context.mounted && shouldPop) {
      // Navigator.pop(context, result);
      zoOverlay.skipDismissCheck(() {
        zoOverlay.close(overlay1);
      });
    }
  }

  late final overlay2 = ZoOverlayEntry(
    alignment: Alignment(0.1, 0.1),
    route: true,
    builder: (BuildContext context) {
      return Container(
        width: 150,
        height: 150,
        color: Colors.blue,
        child: Center(child: _Counter()),
      );
    },
    // barrier: true,
    // tapAwayClosable: true,
    dismissMode: ZoOverlayDismissMode.close,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("OverlayPage2")),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            ZoButton(
              child: Text("create"),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return Align(
                      child: Material(
                        child: Container(
                          width: 200,
                          height: 200,
                          color: Colors.blue,
                          child: ZoButton(
                            child: Text("rerance"),
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            ZoButton(
              child: Text("closeAll"),
              onPressed: () {
                zoOverlay.closeAll();
              },
            ),
            ZoButton(
              child: Text("openAll"),
              onPressed: () {
                zoOverlay.openAll();
              },
            ),
            ZoButton(
              child: Text("disposeAll"),
              onPressed: () {
                zoOverlay.disposeAll();
              },
            ),
            ZoButton(
              child: Text("open1"),
              onPressed: () {
                zoOverlay.open(overlay1);

                overlay1.wait().then((val) {
                  print("val $val");
                });
              },
            ),
            ZoButton(
              child: Text("open2"),
              onPressed: () {
                zoOverlay.open(overlay2);
              },
            ),
            ZoButton(
              child: Text("open together"),
              onPressed: () {
                zoOverlay.open(overlay1);
                zoOverlay.open(overlay2);
              },
            ),
            ZoButton(
              child: Text("close1"),
              onPressed: () {
                zoOverlay.close(overlay1);
              },
            ),
            ZoButton(
              child: Text("close2"),
              onPressed: () {
                zoOverlay.close(overlay2);
              },
            ),
            ZoButton(
              child: Text("change1 alignment"),
              onPressed: () {
                overlay1.alignment = Alignment(
                  math.Random().nextDouble() * 2 - 1,
                  math.Random().nextDouble() * 2 - 1,
                );
              },
            ),
            ZoButton(
              child: Text("change2 alignment"),
              onPressed: () {
                overlay2.alignment = Alignment(
                  math.Random().nextDouble() * 2 - 1,
                  math.Random().nextDouble() * 2 - 1,
                );
              },
            ),
            ZoButton(
              child: Text("moveToTop1"),
              onPressed: () {
                zoOverlay.moveToTop(overlay1);
              },
            ),
            ZoButton(
              child: Text("moveToTop2"),
              onPressed: () {
                zoOverlay.moveToTop(overlay2);
              },
            ),
            ZoButton(
              child: Text("moveToBottom1"),
              onPressed: () {
                zoOverlay.moveToBottom(overlay1);
              },
            ),
            ZoButton(
              child: Text("moveToBottom2"),
              onPressed: () {
                zoOverlay.moveToBottom(overlay2);
              },
            ),
            ZoButton(
              child: Text("dispose1"),
              onPressed: () {
                zoOverlay.dispose(overlay1);
              },
            ),
            ZoButton(
              child: Text("dispose2"),
              onPressed: () {
                zoOverlay.dispose(overlay2);
              },
            ),
            ZoButton(
              child: Text("pop"),
              onPressed: () {
                Navigator.of(context).pop(123);
              },
            ),
            ZoButton(
              child: Text("maybePop"),
              onPressed: () {
                Navigator.of(context).maybePop(123);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Counter extends StatefulWidget {
  const _Counter();

  @override
  State<_Counter> createState() => __CounterState();
}

class __CounterState extends State<_Counter> {
  int count = 0;
  @override
  Widget build(BuildContext context) {
    return ZoButton(
      child: Text("add  $count"),
      onPressed: () {
        setState(() {
          count++;
        });
      },
    );
  }
}

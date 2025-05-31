import "dart:async";
import "dart:collection";
import "dart:math" as math;

import "package:flutter/material.dart";
import "package:zo/src/dialog/dialog.dart";
import "package:zo/src/notice/notice.dart";
import "package:zo/src/overlay/overlay.dart";
import "package:zo/src/popper/popper.dart";
import "package:zo/src/animation/ticker.dart";
import "package:zo/zo.dart";

import "widgets/float_node.dart";

class OverlayPage2 extends StatefulWidget {
  const OverlayPage2({super.key});

  @override
  State<OverlayPage2> createState() => _OverlayPage2State();
}

typedef ColorEntry = DropdownMenuEntry<ColorLabel>;

enum ColorLabel {
  blue('Blue', Colors.blue),
  pink('Pink', Colors.pink),
  green('Green', Colors.green),
  yellow('Orange', Colors.orange),
  grey('Grey', Colors.grey);

  const ColorLabel(this.label, this.color);
  final String label;
  final Color color;

  static final List<ColorEntry> entries = UnmodifiableListView<ColorEntry>(
    values.map<ColorEntry>(
      (ColorLabel color) => ColorEntry(
        value: color,
        label: color.label,
        enabled: color.label != 'Grey',
        style: MenuItemButton.styleFrom(foregroundColor: color.color),
      ),
    ),
  );
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
    alignment: Alignment(0, 0),
    route: true,
    builder: (BuildContext context) {
      return Container(
        width: 320,
        height: 240,
        decoration: BoxDecoration(border: Border.all(), color: Colors.white),
        child: Center(child: _Counter()),
      );
    },
    transitionType: ZoTransitionType.slideTop,
    barrier: true,
    // tapAwayClosable: true,
    dismissMode: ZoOverlayDismissMode.close,
    // mayDismiss: () => false,
    // onDismiss: onDismiss,
  );

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
    barrier: true,
    // tapAwayClosable: true,
    dismissMode: ZoOverlayDismissMode.close,
  );

  late final popper1 = ZoPopperEntry(
    rect: Rect.fromLTWH(300, 300, 100, 40),
    direction: ZoPopperDirection.top,
    // status: ZoStatus.success,
    // title: Text("Popper提示"),
    route: true,
    dismissMode: ZoOverlayDismissMode.close,
    onConfirm: () {
      print("confirm");
    },
    arrow: true,
    tapAwayClosable: false,
    // distance: 24,
    content: Text("文本提示文本文"),
  );

  late final dialog1 = ZoDialog(
    // status: ZoStatus.success,
    // title: Text("Popper提示"),
    route: true,
    dismissMode: ZoOverlayDismissMode.close,
    // onConfirm: () {
    //   print("confirm");
    // },
    // tapAwayClosable: false,
    // distance: 24,
    closeButton: true,
    alwaysOnTop: true,
    status: ZoStatus.error,
    title: Text(
      "Dialog标题",
    ),
    content: Text(
      "文本提示文本文文本提示文本文文本提示文本文文本提示文本文文本提示文本文文本提示文本文文本",
    ),
    onConfirm: () {
      return Future.delayed(
        Duration(seconds: 2),
      );
    },
  );

  Widget builderDialog(BuildContext context) {
    return Tooltip(
      message: "date picker",
      child: ZoButton(
        child: Text("date picker"),
        onPressed: () {
          showDatePicker(
            useRootNavigator: false,
            context: context,
            initialDate: DateTime(2021, 7, 25),
            firstDate: DateTime(2021),
            lastDate: DateTime(2022),
          );

          // showGeneralDialog(
          //   context: context,
          //   barrierDismissible: true,
          //   barrierLabel: 'Custom',
          //   pageBuilder: (context, animation1, animation2) {
          //     return Text("abfqwfwqfwqfw");
          //   },
          // );
        },
      ),
    );
  }

  late final drawer1 = ZoDialog(
    // status: ZoStatus.success,
    // title: Text("Popper提示"),
    route: true,
    dismissMode: ZoOverlayDismissMode.close,
    // onConfirm: () {
    //   print("confirm");
    // },
    // tapAwayClosable: false,
    // distance: 24,
    // alignment: Alignment.centerRight,
    // width: 0.4,
    // height: 1,
    height: 0.92,
    drawer: AxisDirection.down,
    closeButton: true,
    status: ZoStatus.error,
    title: Text(
      "Dialog标题",
    ),
    content: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          "文本提示文本文文本提示文本文文本提示文本文文本提示文本文文本提示文本文文本提示文本文文本",
        ),
        Builder(
          builder: builderDialog,
        ),
        // DropdownMenu<ColorLabel>(
        //   initialSelection: ColorLabel.green,
        //   // The default requestFocusOnTap value depends on the platform.
        //   // On mobile, it defaults to false, and on desktop, it defaults to true.
        //   // Setting this to true will trigger a focus request on the text field, and
        //   // the virtual keyboard will appear afterward.
        //   requestFocusOnTap: true,
        //   label: const Text('Color'),
        //   onSelected: (ColorLabel? color) {
        //     setState(() {});
        //   },
        //   dropdownMenuEntries: ColorLabel.entries,
        // ),
      ],
    ),
    onConfirm: () {
      return Future.delayed(
        Duration(seconds: 2),
      );
    },
    transitionType: ZoTransitionType.slideRight,
  );

  void onDismiss(bool didDismiss, dynamic result) async {
    print("didDismiss $didDismiss result $result");

    if (didDismiss) {
      return;
    }

    try {
      zoOverlay.disableAllTapAwayClosable = true;

      final bool shouldPop = await _showBackDialog() ?? false;
      if (context.mounted && shouldPop) {
        // Navigator.pop(context, result);
        zoOverlay.skipDismissCheck(() {
          zoOverlay.close(overlay1);
        });
      }
    } catch (e) {
      print(e);
    } finally {
      zoOverlay.disableAllTapAwayClosable = false;
    }
  }

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
            ZoButton(
              child: Text("open popper1"),
              onPressed: () {
                zoOverlay.open(popper1);
              },
            ),
            FocusMoveOverlayWidget(
              anchorChild: Text("点击出现调试层"),
              overlayContentChild: Container(
                height: 44,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onRectChanged: (Rect globalRect) {
                popper1.rect = globalRect;
              },
              initialPosition: const Offset(100, 300),
              moveStep: 10.0,
            ),
            ZoButton(
              child: Text("open dialog1"),
              onPressed: () {
                zoOverlay.open(dialog1);
              },
            ),
            ZoButton(
              child: Text("open drawer1"),
              onPressed: () {
                zoOverlay.open(drawer1);
              },
            ),
            ZoButton(
              child: Text("open dialog1 drawer1"),
              onPressed: () {
                zoOverlay.open(dialog1);
                zoOverlay.open(drawer1);
              },
            ),
            ZoButton(
              child: Text("check active"),
              onPressed: () {
                zoOverlay.overlays.forEach((e) {
                  print(
                    "${e.runtimeType} ${zoOverlay.isActive(e)} ${e.currentOpen}",
                  );
                  print(
                    "${zoOverlay.isDelayClosing(e)} ${zoOverlay.isDelayDisposing(e)}",
                  );
                });
              },
            ),
            ZoButton(
              child: Text("timepicker"),
              onPressed: () {
                showDatePicker(
                  useRootNavigator: false,
                  context: context,
                  initialDate: DateTime(2021, 7, 25),
                  firstDate: DateTime(2021),
                  lastDate: DateTime(2022),
                );
              },
            ),
            ZoButton(
              child: Text("compare overlay"),
              onPressed: () {
                print("${Overlay.of(context)} ${zoOverlay.navigator.overlay!}");
                print(Overlay.of(context) == zoOverlay.navigator.overlay!);
              },
            ),
            ZoButton(
              child: Text("notice"),
              onPressed: () {
                final r = math.Random();

                // 随机选择一个 ZoNoticePosition
                final positions = ZoNoticePosition.values;
                final position = positions[r.nextInt(positions.length)];
                // final position = ZoNoticePosition.center;

                final statuses = ZoStatus.values;
                final status = statuses[r.nextInt(statuses.length)];

                zoNotice.notice(
                  ZoNoticeEntry(
                    title: r.nextDouble() > 0.5 ? Text("标题内容") : null,
                    closeButton: r.nextDouble() > 0.5,
                    barrier: r.nextDouble() > 0.9,
                    content: Text("Hello world"),
                    position: position,
                    status: status,
                    // builder: (context) => Text("HEllo"),
                  ),
                );
              },
            ),
            ZoButton(
              child: Text("notice.tip"),
              onPressed: () {
                zoNotice.tip("hello world");
              },
            ),
            ZoButton(
              child: Text("notice.loading"),
              onPressed: () {
                final entry = zoNotice.loading(message: "hello world");

                Timer(Duration(seconds: 2), () {
                  zoNotice.close(entry);
                });
              },
            ),
            ZoButton(
              child: Text("clear notice"),
              onPressed: () {
                zoNotice.disposeAll();
              },
            ),
            ZoButton(
              child: Text("ticker"),
              onPressed: () {
                final cancel = zoAnimationKit.animation(
                  tween: Tween(begin: 100.0, end: 200.0),
                  onAnimation: (value) {
                    print(value.value);
                  },
                );

                Timer(Duration(milliseconds: 100), () {
                  cancel();
                });
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

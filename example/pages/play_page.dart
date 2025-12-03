import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:zo/src/button/button.dart";
import "package:zo/src/dialog/dialog.dart";
import "package:zo/src/dnd/dnd.dart";
import "package:zo/src/trigger/trigger.dart";
import "package:zo/zo.dart";

import "play.dart";

class PlayPage extends StatefulWidget {
  const PlayPage({super.key});

  @override
  State<PlayPage> createState() => _PlayPageState();
}

class _PlayPageState extends State<PlayPage> {
  int acceptedData = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: NotificationListener<ZoDNDEventNotification>(
            onNotification: (notification) {
              final type = notification.dndEvent.type;

              if (type != ZoDNDEventType.accept &&
                  type != ZoDNDEventType.expand) {
                return false;
              }

              print(
                "${notification.dndEvent.type} ${notification.dndEvent.activePosition}",
              );
              return true;
            },
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ZoTrigger(
                  onTap: (event) {
                    print("onTap");
                  },
                  onActiveChanged: (event) {
                    print("onActiveChanged ${event.toggle}");
                  },
                  onContextAction: (event) {
                    print("onContextAction");
                  },
                  // onDrag: (event) {
                  //   print("drag");
                  // },
                  child: Container(
                    width: 200,
                    height: 200,
                    color: Colors.blue,
                    child: Text("12321321"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

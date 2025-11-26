import "package:flutter/material.dart";
import "package:flutter/rendering.dart";
import "package:zo/src/button/button.dart";
import "package:zo/src/dialog/dialog.dart";
import "package:zo/src/dnd/dnd.dart";
import "package:zo/src/trigger/trigger.dart";
import "package:zo/zo.dart";

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
                  onTap: (event) {},
                  onContextAction: (event) {},
                  onDrag: (event) {},
                  child: Text("trigger"),
                ),
                ZoDND(
                  draggable: true,
                  feedback: Text("选项1"),
                  child: Container(
                    height: 100.0,
                    width: 100.0,
                    color: Colors.lightGreenAccent,
                    child: const Center(child: Text("DND A")),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                  ),
                  height: 300,
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Container(
                          height: 100.0,
                          width: 100.0,
                          color: Colors.cyan,
                          child: Center(
                            child: Text(
                              "Value is updated to: $acceptedData",
                            ),
                          ),
                        ),
                        SizedBox.square(dimension: 500),
                        ZoDND(
                          child: Container(
                            height: 100.0,
                            width: 100.0,
                            color: Colors.lightGreenAccent,
                            child: const Center(child: Text("DND B")),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                ZoDND(
                  droppablePosition: const ZoDNDPosition.all(),
                  draggable: true,
                  customHandler: true,
                  child: Container(
                    height: 100.0,
                    width: 100.0,
                    color: Colors.lightGreenAccent,
                    child: Center(
                      child: Column(
                        children: [
                          Text("DND C"),
                          ZoDNDHandler(
                            child: ZoButton(
                              child: Text("拖动我"),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // onDragStart: (event) {
                  //   print("start: ${event.activeDND} ${event.activePosition}");
                  // },
                  // onDragMove: (event) {
                  //   print("move: ${event.activeDND} ${event.activePosition}");
                  // },
                  // onDragEnd: (event) {
                  //   print("end: ${event.activeDND} ${event.activePosition}");
                  // },
                  // onAccept: (event) {
                  //   print("accept: ${event.activeDND} ${event.activePosition}");
                  // },
                ),
                ZoDND(
                  droppablePosition: const ZoDNDPosition.all(),
                  child: Container(
                    height: 200.0,
                    width: 200.0,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.red),
                    ),
                    padding: EdgeInsets.all(40),
                    child: ZoDND(
                      droppablePosition: const ZoDNDPosition.all(),
                      child: Container(
                        color: Colors.lightGreenAccent,
                        child: const Center(child: Text("DND C")),
                      ),
                    ),
                  ),
                ),
                ZoDND(
                  droppablePosition: const ZoDNDPosition(
                    left: true,
                    right: true,
                  ),
                  child: Container(
                    height: 100.0,
                    width: 100.0,
                    color: Colors.lightGreenAccent,
                    child: const Center(child: Text("left right")),
                  ),
                ),
                ZoDND(
                  droppablePosition: const ZoDNDPosition(
                    top: true,
                    bottom: true,
                  ),
                  child: Container(
                    height: 100.0,
                    width: 100.0,
                    color: Colors.lightGreenAccent,
                    child: const Center(child: Text("top bottom")),
                  ),
                ),
                ZoDND(
                  droppablePosition: const ZoDNDPosition(
                    top: true,
                    center: true,
                  ),
                  child: Container(
                    height: 100.0,
                    width: 100.0,
                    color: Colors.lightGreenAccent,
                    child: const Center(child: Text("center top")),
                  ),
                ),
                ZoDND(
                  droppablePosition: const ZoDNDPosition(
                    top: true,
                    center: true,
                  ),
                  draggable: true,
                  data: "dnd 10",
                  builder: (context, dndContext) {
                    return Container(
                      height: 100.0,
                      width: 250.0,
                      color: Colors.lightGreenAccent,
                      child: Text(
                        "dragging: ${dndContext.dragging} dragDND: ${dndContext.dragDND?.data} draggable: ${dndContext.draggable} active ${dndContext.activePosition}",
                      ),
                    );
                  },
                ),
                ZoDND(
                  droppablePosition: const ZoDNDPosition.all(),
                  data: "dnd 11",
                  builder: (context, dndContext) {
                    return Container(
                      height: 100.0,
                      width: 250.0,
                      color: Colors.lightGreenAccent,
                      child: Text(
                        "dragging: ${dndContext.dragging} dragDND: ${dndContext.dragDND?.data} draggable: ${dndContext.draggable} active ${dndContext.activePosition}",
                      ),
                    );
                  },
                ),
                ZoDND(
                  draggable: true,
                  child: ZoButton(
                    child: Text("hello"),
                  ),
                ),
                SizedBox(
                  height: 1000,
                  width: double.infinity,
                  child: Container(
                    decoration: BoxDecoration(border: Border.all()),
                  ),
                ),
                ZoDND(
                  droppablePosition: const ZoDNDPosition.all(),
                  child: Container(
                    height: 100.0,
                    width: 100.0,
                    color: Colors.lightGreenAccent,
                    child: const Center(child: Text("DND D")),
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

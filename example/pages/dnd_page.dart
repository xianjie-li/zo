import "package:flutter/material.dart";
import "package:zo/src/trigger/gesture_recognizer/immediate_pan.dart";
import "package:zo/zo.dart";

class DNDPage extends StatefulWidget {
  const DNDPage({super.key});

  @override
  State<DNDPage> createState() => _DNDPageState();
}

class _DNDPageState extends State<DNDPage> {
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
                  width: 300,
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
                        SizedBox.square(dimension: 800),
                        ZoDND(
                          child: Container(
                            height: 100.0,
                            width: 100.0,
                            color: Colors.lightGreenAccent,
                            child: const Center(child: Text("DND B")),
                          ),
                        ),
                        _TestBuilder(
                          label: "A:",
                        ),
                      ],
                    ),
                  ),
                ),
                RawGestureDetector(
                  gestures: {
                    ImmediatePanGestureRecognizer:
                        GestureRecognizerFactoryWithHandlers<
                          ImmediatePanGestureRecognizer
                        >(
                          () => ImmediatePanGestureRecognizer(debugOwner: this),
                          (ImmediatePanGestureRecognizer instance) {
                            instance.onUpdate = (e) {
                              print("onUpdate");
                            };
                            instance.onStart = (e) {
                              print("onStart");
                            };
                            instance.onEnd = (e) {
                              print("onEnd");
                            };
                          },
                        ),
                  },
                  child: GestureDetector(
                    onTap: () {
                      print("tap");
                    },
                    child: Container(
                      height: 100.0,
                      width: 100.0,
                      color: Colors.lightGreenAccent,
                      child: const Center(child: Text("ImmediatePan")),
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black),
                  ),
                  height: 300,
                  width: 300,
                  child: ListView(
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
                      SizedBox.square(dimension: 800),
                      ZoDND(
                        child: Container(
                          height: 100.0,
                          width: 100.0,
                          color: Colors.lightGreenAccent,
                          child: const Center(child: Text("DND B")),
                        ),
                      ),
                      _TestBuilder(
                        label: "B:",
                      ),
                    ],
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

class _TestBuilder extends StatefulWidget {
  const _TestBuilder({
    super.key,
    required this.label,
  });

  final String label;

  @override
  State<_TestBuilder> createState() => __TestBuilderState();
}

class __TestBuilderState extends State<_TestBuilder> {
  @override
  void initState() {
    print("tinit");
  }

  @override
  Widget build(BuildContext context) {
    print("tbuild");

    return RenderTrigger(
      onPaintImmediately: (box) {
        print(box);
      },
      child: SizedBox.square(
        child: Text("${widget.label}"),
        dimension: 100,
      ),
    );
  }
}

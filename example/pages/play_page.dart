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

  ExpansibleController controller = ExpansibleController();

  @override
  void initState() {
    super.initState();
  }

  String? value = "hello";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Wrap(
            children: [
              Expansible(
                controller: controller,
                headerBuilder: (context, animation) => GestureDetector(
                  onTap: () => controller.isExpanded
                      ? controller.collapse()
                      : controller.expand(),
                  child: Text('Tap to Expand'),
                ),
                bodyBuilder: (context, animation) => SizeTransition(
                  sizeFactor: animation,
                  child: Text('Hidden content revealed!'),
                ),
                expansibleBuilder: (context, header, body, animation) => Column(
                  // mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [header, body],
                ),
              ),
              Container(
                height: 100,
                decoration: BoxDecoration(border: Border.all()),
              ),
              Text("value: $value"),
              ZoInput(
                value: value,
                onChanged: (newValue) {
                  setState(() {
                    value = newValue;
                  });
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

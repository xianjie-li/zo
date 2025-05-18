import "package:flutter/material.dart";
import "package:zo/src/overlay/overlay.dart";

class OverlayPage1 extends StatefulWidget {
  const OverlayPage1({super.key});

  @override
  State<OverlayPage1> createState() => _OverlayPage1State();
}

class _OverlayPage1State extends State<OverlayPage1> {
  var entry1 = ZoOverlayEntry(
    // offset: Offset(500, 500),
    rect: Rect.fromLTWH(-135, 500, 100, 50),
    // alignment: Alignment.bottomLeft,
    direction: ZoPopperDirection.topLeft,
    preventOverflow: true,
    builder: (context) {
      return SizedBox();
    },
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("OverlayPage1")),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(border: Border.all()),
        child: ZoOverlayPositioned(
          entry: entry1,
          child: GestureDetector(
            onTap: () {
              print("tap");
            },
            child: Container(
              width: 140,
              height: 80,
              decoration: BoxDecoration(border: Border.all(color: Colors.red)),
            ),
          ),
        ),
      ),
    );
  }
}

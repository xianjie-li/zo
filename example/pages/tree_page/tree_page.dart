import "dart:math";

import "package:flutter/material.dart";
import "package:zo/zo.dart";

import "custom_tree.dart";
import "simple_tree.dart";

class TreePage extends StatefulWidget {
  const TreePage({super.key});

  @override
  State<TreePage> createState() => _TreePageState();
}

class _TreePageState extends State<TreePage> {
  @override
  Widget build(BuildContext context) {
    final style = context.zoStyle;

    return Scaffold(
      body: SingleChildScrollView(
        clipBehavior: Clip.none,
        padding: EdgeInsets.all(24),
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            Text("Simple"),
            Container(
              height: 500,
              decoration: BoxDecoration(
                border: Border.all(
                  color: style.outlineColor,
                ),
              ),
              child: TreeExample(),
            ),
            Text("Custom Tree"),
            Container(
              height: 500,
              decoration: BoxDecoration(
                border: Border.all(
                  color: style.outlineColor,
                ),
              ),
              child: CustomTreeExample(),
            ),
          ],
        ),
      ),
    );
  }
}

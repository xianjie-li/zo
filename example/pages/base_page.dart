import "package:flutter/material.dart";
import "package:zo/zo.dart";
import "widgets/title.dart";

base class BasePage extends StatefulWidget {
  const BasePage({super.key});

  @override
  State<BasePage> createState() => _BasePageState();
}

class _BasePageState extends State<BasePage> {
  @override
  Widget build(BuildContext context) {
    final ZoStyle zoStyle = context.zoStyle;
    final locale = ZoLocalizations.of(context);

    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(locale.msg),
              PageTitle("Color"),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Text("info", style: TextStyle(color: zoStyle.infoColor)),
                  Text(
                    "success",
                    style: TextStyle(color: zoStyle.successColor),
                  ),
                  Text(
                    "warning",
                    style: TextStyle(color: zoStyle.warningColor),
                  ),
                  Text("error", style: TextStyle(color: zoStyle.errorColor)),
                  Text("hint", style: TextStyle(color: zoStyle.hintTextColor)),
                ],
              ),
              SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  Text("primary:"),
                  Container(width: 30, height: 30, color: zoStyle.primaryColor),
                  Text("secondary:"),
                  Container(
                    width: 30,
                    height: 30,
                    color: zoStyle.secondaryColor,
                  ),
                  Text("tertiary:"),
                  Container(
                    width: 30,
                    height: 30,
                    color: zoStyle.tertiaryColor,
                  ),
                  Text("surface:"),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: zoStyle.surfaceColor,
                      border: Border.all(color: zoStyle.outlineColor),
                    ),
                  ),
                  Text("surfaceContainer:"),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: zoStyle.surfaceContainerColor,
                      border: Border.all(color: zoStyle.outlineColor),
                    ),
                  ),
                  Text("focusColor:"),
                  Container(width: 30, height: 30, color: zoStyle.focusColor),
                  Text("hoverColor:"),
                  Container(width: 30, height: 30, color: zoStyle.hoverColor),
                  Text("highlightColor:"),
                  Container(
                    width: 30,
                    height: 30,
                    color: zoStyle.highlightColor,
                  ),
                  Text("disabledColor:"),
                  Container(
                    width: 30,
                    height: 30,
                    color: zoStyle.disabledColor,
                  ),
                  Text("outline:"),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border.all(color: zoStyle.outlineColor, width: 1),
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: zoStyle.outlineColorVariant,
                        width: 1,
                      ),
                    ),
                  ),
                ],
              ),

              PageTitle("Elevation"),
              Wrap(
                spacing: 30,
                runSpacing: 30,
                children: [
                  Material(
                    elevation: zoStyle.elevation,
                    color: zoStyle.surfaceContainerColor,
                    child: SizedBox.square(dimension: 60),
                  ),
                  Material(
                    elevation: zoStyle.elevationDrawer,
                    color: zoStyle.surfaceContainerColor,
                    child: SizedBox.square(dimension: 60),
                  ),
                  Material(
                    elevation: zoStyle.elevationModal,
                    color: zoStyle.surfaceContainerColor,
                    child: SizedBox.square(dimension: 60),
                  ),
                  Material(
                    elevation: zoStyle.elevationMessage,
                    color: zoStyle.surfaceContainerColor,
                    child: SizedBox.square(dimension: 60),
                  ),
                ],
              ),

              PageTitle("Size"),
              Wrap(
                spacing: 30,
                runSpacing: 30,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: zoStyle.outlineColor),
                    ),
                    child: SizedBox.square(dimension: zoStyle.smallSize),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: zoStyle.outlineColor),
                    ),
                    child: SizedBox.square(dimension: zoStyle.mediumSize),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: zoStyle.outlineColor),
                    ),
                    child: SizedBox.square(dimension: zoStyle.largeSize),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

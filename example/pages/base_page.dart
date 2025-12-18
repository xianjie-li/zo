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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(locale.msg),
              const PageTitle("Color"),
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
              const SizedBox(height: 12),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  const Text("primary:"),
                  Container(width: 60, height: 60, color: zoStyle.primaryColor),
                  const Text("secondary:"),
                  Container(
                    width: 60,
                    height: 60,
                    color: zoStyle.secondaryColor,
                  ),
                  const Text("tertiary:"),
                  Container(
                    width: 60,
                    height: 60,
                    color: zoStyle.tertiaryColor,
                  ),
                  const Text("surface:"),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: zoStyle.surfaceColor,
                    ),
                  ),
                  const Text("surfaceContainer:"),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: zoStyle.surfaceContainerColor,
                    ),
                  ),
                  const Text("focusColor:"),
                  Container(width: 60, height: 60, color: zoStyle.focusColor),
                  const Text("hoverColor:"),
                  Container(width: 60, height: 60, color: zoStyle.hoverColor),
                  const Text("highlightColor:"),
                  Container(
                    width: 60,
                    height: 60,
                    color: zoStyle.highlightColor,
                  ),
                  const Text("disabledColor:"),
                  Container(
                    width: 60,
                    height: 60,
                    color: zoStyle.disabledColor,
                  ),
                  const Text("outline:"),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(color: zoStyle.outlineColor, width: 1),
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: zoStyle.outlineColorVariant,
                        width: 1,
                      ),
                    ),
                  ),
                  Text(
                    "titleTextColor",
                    style: TextStyle(color: zoStyle.titleTextColor),
                  ),
                  Text(
                    "textColor",
                    style: TextStyle(color: zoStyle.textColor),
                  ),
                  Text(
                    "hintTextColor",
                    style: TextStyle(color: zoStyle.hintTextColor),
                  ),
                  Text(
                    "fontSizeSM",
                    style: TextStyle(fontSize: zoStyle.fontSizeSM),
                  ),
                  Text(
                    "fontSizeSM",
                    style: TextStyle(fontSize: zoStyle.fontSize),
                  ),
                  Text(
                    "fontSizeSM",
                    style: TextStyle(fontSize: zoStyle.fontSizeMD),
                  ),
                  Text(
                    "fontSizeSM",
                    style: TextStyle(fontSize: zoStyle.fontSizeLG),
                  ),
                  Text(
                    "fontSizeSM",
                    style: TextStyle(fontSize: zoStyle.fontSizeXL),
                  ),
                ],
              ),

              const PageTitle("Elevation"),
              Wrap(
                spacing: 80,
                runSpacing: 60,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: zoStyle.surfaceContainerColor,
                      boxShadow: [zoStyle.shadow],
                    ),
                    child: const SizedBox.square(dimension: 60),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: zoStyle.surfaceContainerColor,
                      boxShadow: [zoStyle.overlayShadow],
                    ),
                    child: const SizedBox.square(dimension: 60),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: zoStyle.surfaceContainerColor,
                      boxShadow: [zoStyle.modalShadow],
                    ),
                    child: const SizedBox.square(dimension: 60),
                  ),
                ],
              ),

              const PageTitle("Elevation2"),
              Wrap(
                spacing: 80,
                runSpacing: 60,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: zoStyle.surfaceContainerColor,
                      boxShadow: [zoStyle.shadowVariant],
                    ),
                    child: const SizedBox.square(dimension: 60),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: zoStyle.surfaceContainerColor,
                      boxShadow: [zoStyle.overlayShadowVariant],
                    ),
                    child: const SizedBox.square(dimension: 60),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: zoStyle.surfaceContainerColor,
                      boxShadow: [zoStyle.modalShadowVariant],
                    ),
                    child: const SizedBox.square(dimension: 60),
                  ),
                ],
              ),

              const PageTitle("Size"),
              Wrap(
                spacing: 60,
                runSpacing: 60,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: zoStyle.outlineColor),
                    ),
                    child: SizedBox.square(dimension: zoStyle.sizeSM),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: zoStyle.outlineColor),
                    ),
                    child: SizedBox.square(dimension: zoStyle.sizeMD),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: zoStyle.outlineColor),
                    ),
                    child: SizedBox.square(dimension: zoStyle.sizeLG),
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

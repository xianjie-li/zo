import "package:flutter/material.dart";
import "package:zo/src/button/button.dart";

import "base_page.dart";
import "button_page.dart";
import "fetcher_page.dart";
import "input_page.dart";
import "layout_page.dart";
import "overlay_page1.dart";
import "overlay_page2.dart";
import "progress_page.dart";
import "result_page.dart";
import "transition_page.dart";

class RouterLinks extends StatelessWidget {
  const RouterLinks({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  void toPage(BuildContext context, Widget page) {
    navigatorKey.currentState!.pushAndRemoveUntil(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => page,
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        spacing: 8,
        children: [
          ZoButton(
            text: true,
            child: Text("Base"),
            onPressed: () => toPage(context, BasePage()),
          ),
          ZoButton(
            text: true,
            child: Text("Button"),
            onPressed: () => toPage(context, ButtonPage()),
          ),
          ZoButton(
            text: true,
            child: Text("Fetcher"),
            onPressed: () => toPage(context, FetcherPage()),
          ),
          ZoButton(
            text: true,
            child: Text("Input"),
            onPressed: () => toPage(context, InputPage()),
          ),
          ZoButton(
            text: true,
            child: Text("Layout"),
            onPressed: () => toPage(context, LayoutPage()),
          ),
          ZoButton(
            text: true,
            child: Text("Progress"),
            onPressed: () => toPage(context, ProgressPage()),
          ),
          ZoButton(
            text: true,
            child: Text("Result"),
            onPressed: () => toPage(context, ResultPage()),
          ),
          ZoButton(
            text: true,
            child: Text("Transition"),
            onPressed: () => toPage(context, TransitionPage()),
          ),
          ZoButton(
            text: true,
            child: Text("Overlay1"),
            onPressed: () => toPage(context, OverlayPage1()),
          ),
          ZoButton(
            text: true,
            child: Text("Overlay1"),
            onPressed: () => toPage(context, OverlayPage2()),
          ),
        ],
      ),
    );
  }
}

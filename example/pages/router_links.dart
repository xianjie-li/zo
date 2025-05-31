import "package:flutter/material.dart";
import "package:zo/src/button/button.dart";

import "base_page.dart";
import "button_page.dart";
import "fetcher_page.dart";
import "input_page.dart";
import "input_page2.dart";
import "layout_page.dart";
import "overlay_page1.dart";
import "overlay_page2.dart";
import "play_page.dart";
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
            child: const Text("Play"),
            onPressed: () => toPage(context, const PlayPage()),
          ),
          ZoButton(
            text: true,
            child: const Text("Base"),
            onPressed: () => toPage(context, const BasePage()),
          ),
          ZoButton(
            text: true,
            child: const Text("Button"),
            onPressed: () => toPage(context, const ButtonPage()),
          ),
          ZoButton(
            text: true,
            child: const Text("Fetcher"),
            onPressed: () => toPage(context, const FetcherPage()),
          ),
          ZoButton(
            text: true,
            child: const Text("Input"),
            onPressed: () => toPage(context, const InputPage()),
          ),
          ZoButton(
            text: true,
            child: const Text("Input2"),
            onPressed: () => toPage(context, const InputPage2()),
          ),
          ZoButton(
            text: true,
            child: const Text("Layout"),
            onPressed: () => toPage(context, const LayoutPage()),
          ),
          ZoButton(
            text: true,
            child: const Text("Progress"),
            onPressed: () => toPage(context, const ProgressPage()),
          ),
          ZoButton(
            text: true,
            child: const Text("Result"),
            onPressed: () => toPage(context, const ResultPage()),
          ),
          ZoButton(
            text: true,
            child: const Text("Transition"),
            onPressed: () => toPage(context, const TransitionPage()),
          ),
          ZoButton(
            text: true,
            child: const Text("Overlay1"),
            onPressed: () => toPage(context, const OverlayPage1()),
          ),
          ZoButton(
            text: true,
            child: const Text("Overlay1"),
            onPressed: () => toPage(context, const OverlayPage2()),
          ),
        ],
      ),
    );
  }
}

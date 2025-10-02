import "package:flutter/material.dart";
import "package:zo/src/button/button.dart";

import "base_page.dart";
import "button_page.dart";
import "fetcher_page.dart";
import "input_page.dart";
import "input_page2.dart";
import "layout_page.dart";
import "menus_page.dart";
import "overlay_page1.dart";
import "overlay_page2.dart";
import "play_page.dart";
import "progress_page.dart";
import "result_page.dart";
import "select_page.dart";
import "transition_page.dart";
import "tree_page/tree_page.dart";

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
      child: DefaultTextStyle(
        style: TextStyle(),
        child: Column(
          spacing: 8,
          children: [
            ZoButton(
              plain: true,
              child: const Text("Play"),
              onTap: () => toPage(context, const PlayPage()),
            ),
            ZoButton(
              plain: true,
              child: const Text("Base"),
              onTap: () => toPage(context, const BasePage()),
            ),
            ZoButton(
              plain: true,
              child: const Text("Button"),
              onTap: () => toPage(context, const ButtonPage()),
            ),
            ZoButton(
              plain: true,
              child: const Text("Fetcher"),
              onTap: () => toPage(context, const FetcherPage()),
            ),
            ZoButton(
              plain: true,
              child: const Text("Input"),
              onTap: () => toPage(context, const InputPage()),
            ),
            ZoButton(
              plain: true,
              child: const Text("Input2"),
              onTap: () => toPage(context, const InputPage2()),
            ),
            ZoButton(
              plain: true,
              child: const Text("Layout"),
              onTap: () => toPage(context, const LayoutPage()),
            ),
            ZoButton(
              plain: true,
              child: const Text("Progress"),
              onTap: () => toPage(context, const ProgressPage()),
            ),
            ZoButton(
              plain: true,
              child: const Text("Result"),
              onTap: () => toPage(context, const ResultPage()),
            ),
            ZoButton(
              plain: true,
              child: const Text("Transition"),
              onTap: () => toPage(context, const TransitionPage()),
            ),
            ZoButton(
              plain: true,
              child: const Text("Overlay1"),
              onTap: () => toPage(context, const OverlayPage1()),
            ),
            ZoButton(
              plain: true,
              child: const Text("Overlay1"),
              onTap: () => toPage(context, const OverlayPage2()),
            ),
            ZoButton(
              plain: true,
              child: const Text("Menus"),
              onTap: () => toPage(context, const MenusPage()),
            ),
            ZoButton(
              plain: true,
              child: const Text("Select"),
              onTap: () => toPage(context, const SelectPage()),
            ),
            ZoButton(
              plain: true,
              child: const Text("Tree"),
              onTap: () => toPage(context, const TreePage()),
            ),
          ],
        ),
      ),
    );
  }
}

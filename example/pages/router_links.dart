import "package:flutter/material.dart";
import "package:zo/zo.dart";

import "badge_page.dart";
import "base_page.dart";
import "button_page.dart";
import "dnd_page.dart";
import "expansible_page.dart";
import "fetcher_page.dart";
import "input_page.dart";
import "layout_page.dart";
import "menus_page.dart";
import "overlay_page1.dart";
import "overlay_page2.dart";
import "play_page.dart";
import "progress_page.dart";
import "result_page.dart";
import "select_page.dart";
import "split_view_page.dart";
import "tag_page.dart";
import "tab_page.dart";
import "toggle_page.dart";
import "transition_page.dart";
import "tree_page/tree_page.dart";

class RouterLinks extends StatefulWidget {
  const RouterLinks({super.key, required this.navigatorKey});

  final GlobalKey<NavigatorState> navigatorKey;

  @override
  State<RouterLinks> createState() => _RouterLinksState();
}

class _RouterLinksState extends State<RouterLinks> {
  late final List<({ZoTabsEntry tab, Widget page})> _items = [
    (tab: ZoTabsEntry(label: "Play", value: "play"), page: const PlayPage()),
    (
      tab: ZoTabsEntry(label: "Badge", value: "badge"),
      page: const BadgePage(),
    ),
    (tab: ZoTabsEntry(label: "Base", value: "base"), page: const BasePage()),
    (
      tab: ZoTabsEntry(label: "Button", value: "button"),
      page: const ButtonPage(),
    ),
    (
      tab: ZoTabsEntry(label: "Fetcher", value: "fetcher"),
      page: const FetcherPage(),
    ),
    (tab: ZoTabsEntry(label: "Input", value: "input"), page: const InputPage()),
    (
      tab: ZoTabsEntry(label: "Layout", value: "layout"),
      page: const LayoutPage(),
    ),
    (
      tab: ZoTabsEntry(label: "Progress", value: "progress"),
      page: const ProgressPage(),
    ),
    (
      tab: ZoTabsEntry(label: "Result", value: "result"),
      page: const ResultPage(),
    ),
    (
      tab: ZoTabsEntry(label: "Transition", value: "transition"),
      page: const TransitionPage(),
    ),
    (
      tab: ZoTabsEntry(label: "Overlay1", value: "overlay1"),
      page: const OverlayPage1(),
    ),
    (
      tab: ZoTabsEntry(label: "Overlay2", value: "overlay2"),
      page: const OverlayPage2(),
    ),
    (tab: ZoTabsEntry(label: "Menus", value: "menus"), page: const MenusPage()),
    (
      tab: ZoTabsEntry(label: "Select", value: "select"),
      page: const SelectPage(),
    ),
    (tab: ZoTabsEntry(label: "Tree", value: "tree"), page: const TreePage()),
    (tab: ZoTabsEntry(label: "DND", value: "dnd"), page: const DNDPage()),
    (tab: ZoTabsEntry(label: "Tabs", value: "tabs"), page: const TabsPage()),
    (
      tab: ZoTabsEntry(label: "Expansible", value: "expansible"),
      page: const ExpansiblePage(),
    ),
    (
      tab: ZoTabsEntry(label: "Toggle", value: "toggle"),
      page: const TogglePage(),
    ),
    (
      tab: ZoTabsEntry(label: "SplitView", value: "split-view"),
      page: const SplitViewPage(),
    ),
    (tab: ZoTabsEntry(label: "Tag", value: "tag"), page: const TagPage()),
  ];

  late List<Object> _value = const ["tag"];

  void toPage(BuildContext context, Widget page) {
    widget.navigatorKey.currentState!.pushAndRemoveUntil(
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
    return DefaultTextStyle(
      style: context.zoStyle.textStyle,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ZoTabs(
          tabs: [for (final item in _items) item.tab],
          value: _value,
          direction: Axis.vertical,
          showBorder: true,
          showCloseButton: false,
          size: ZoSize.small,
          onChanged: (newValue) {
            final selectedValue = newValue?.firstOrNull;
            if (selectedValue == null || selectedValue == _value.firstOrNull) {
              return;
            }

            final target = _items.firstWhere(
              (item) => item.tab.value == selectedValue,
            );

            setState(() {
              _value = [selectedValue];
            });

            toPage(context, target.page);
          },
        ),
      ),
    );
  }
}

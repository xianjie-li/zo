import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:zo/src/overlay/overlay.dart";
import "package:zo/zo.dart";

import "pages/base_page.dart";
import "pages/button_page.dart";
import "pages/fetcher_page.dart";
import "pages/form_page.dart";
import "pages/input_page.dart";
import "pages/input_page2.dart";
import "pages/layout_page.dart";
import "pages/overlay_page1.dart";
import "pages/overlay_page2.dart";
import "pages/progress_page.dart";
import "pages/result_page.dart";
import "pages/router_links.dart";
import "pages/transition_page.dart";

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode mode = ThemeMode.light;

  Locale locale = const Locale("en");

  var style = ZoStyle(brightness: Brightness.light);

  late var theme = style.toThemeData();

  var darkStyle = ZoStyle(brightness: Brightness.dark);

  late var darkTheme = darkStyle.toThemeData();

  var supportedLocales = const [Locale("en"), Locale("zh")];

  late var localizationsDelegates = ZoLocalizations.createDelegate(
    resourceMap: {
      const Locale("en"): const ZoLocalizationsDefault(),
      const Locale("zh"): ZoLocalizationsZh(),
    },
    supportedLocales: supportedLocales,
  );

  final navigatorKey = GlobalKey<NavigatorState>();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    style.connectReverse(darkStyle);

    zoOverlay.connect(navigatorKey);

    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: "Flutter Demo",
      themeMode: mode,
      themeAnimationStyle: AnimationStyle.noAnimation,
      theme: theme,
      darkTheme: darkTheme,
      locale: locale,
      localizationsDelegates: [
        localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
      builder: (context, child) {
        return ZoConfig(
          message: "hello world",
          child: Row(
            children: [
              Builder(
                builder: (context) {
                  return Container(
                    width: 100,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: context.zoStyle.surfaceColor,
                      border: Border(
                        right: BorderSide(color: context.zoStyle.outlineColor),
                      ),
                    ),
                    child: Column(
                      spacing: 12,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon:
                                  locale == const Locale("en")
                                      ? const Text("ZH")
                                      : const Text("CN"),
                              onPressed: () {
                                setState(() {
                                  locale =
                                      locale == const Locale("en")
                                          ? const Locale("zh")
                                          : const Locale("en");
                                });
                              },
                            ),
                            IconButton(
                              icon: Icon(
                                mode == ThemeMode.light
                                    ? Icons.dark_mode
                                    : Icons.light_mode,
                              ),
                              color:
                                  mode == ThemeMode.light
                                      ? Colors.black
                                      : Colors.white,
                              onPressed: () {
                                setState(() {
                                  mode =
                                      mode == ThemeMode.light
                                          ? ThemeMode.dark
                                          : ThemeMode.light;
                                });
                              },
                            ),
                          ],
                        ),
                        Expanded(
                          child: RouterLinks(navigatorKey: navigatorKey),
                        ),
                      ],
                    ),
                  );
                },
              ),
              Expanded(child: child!),
            ],
          ),
        );
      },
      home: const OverlayPage2(),
      // home: OverlayPage1(),
    );
  }
}

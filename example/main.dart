import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:zo/zo.dart";

import "pages/base_page.dart";
import "pages/button_page.dart";
import "pages/fetcher_page.dart";
import "pages/form_page.dart";
import "pages/input_page.dart";
import "pages/input_page2.dart";
import "pages/layout_page.dart";
import "pages/progress_page.dart";
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

  Locale locale = Locale("en");

  var style = ZoStyle(brightness: Brightness.light);

  late var theme = style.toThemeData();

  var darkStyle = ZoStyle(brightness: Brightness.dark);

  late var darkTheme = darkStyle.toThemeData();

  var supportedLocales = const [Locale("en"), Locale("zh")];

  late var localizationsDelegates = ZoLocalizations.createDelegate(
    resourceMap: {
      Locale("en"): ZoLocalizationsDefault(),
      Locale("zh"): ZoLocalizationsZh(),
    },
    supportedLocales: supportedLocales,
  );

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    style.connectReverse(darkStyle);

    return MaterialApp(
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
      home: ZoConfig(
        message: "hello world",
        child: Scaffold(
          appBar: AppBar(
            title: Text("Zo"),
            actions: [
              IconButton(
                icon: locale == Locale("en") ? Text("ZH") : Text("CN"),
                onPressed: () {
                  setState(() {
                    locale =
                        locale == Locale("en") ? Locale("zh") : Locale("en");
                  });
                },
              ),
              IconButton(
                icon: Icon(
                  mode == ThemeMode.light ? Icons.dark_mode : Icons.light_mode,
                ),
                color: mode == ThemeMode.light ? Colors.black : Colors.white,
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
          // body: BasePage(),
          // body: LayoutPage(),
          // body: TransitionPage(),
          // body: ProgressPage(),
          // body: ButtonPage(),
          // body: InputPage(),
          // body: FormPage(),
          // body: InputPage2(),
          body: FetcherPage(),
        ),
      ),
    );
  }
}

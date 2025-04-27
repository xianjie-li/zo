import "package:flutter/material.dart";
import "package:flutter_localizations/flutter_localizations.dart";
import "package:zo/zo.dart";

import "pages/base_page.dart";

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

  var theme = ZoStyle(brightness: Brightness.light).toThemeData();

  var darkTheme = ZoStyle(brightness: Brightness.dark).toThemeData();

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Flutter Demo",
      themeMode: mode,
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
          body: BasePage(),
        ),
      ),
    );
  }
}

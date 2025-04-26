import "package:flutter/material.dart";
import "package:zo/base/config/config.dart";
import "package:zo/base/theme/zo_style.dart";
import "package:zo/pages/base_page.dart";

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

  var theme = ZoStyle(brightness: Brightness.light).toThemeData();

  var darkTheme = ZoStyle(brightness: Brightness.dark).toThemeData();

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Flutter Demo",
      themeMode: mode,
      theme: theme,
      darkTheme: darkTheme,
      home: ZoConfig(
        message: "hello world",
        child: Scaffold(
          appBar: AppBar(
            title: Text("Zo"),
            actions: [
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

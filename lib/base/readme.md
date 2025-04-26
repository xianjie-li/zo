## 基础模块

基础模块提供了其他模块必须的一些东西, 比如常量、类型、预设样式、本地化等.

### consts

通用常量



### theme

样式相关定制, 将所有常用样式配置维护到 `ZoStyle` 中, 大部分情况只需要操作此类, 它在内部也反向覆盖掉了 `ThemeData` 中有相同功能的配置, 使 UI 整体更加一致

1. 在 MaterialApp 根注册主题
```dart
class MyAppState extends State<MyApp> {
  // ZoStyle 构造函数支持很多用于不同场景的样式, 如果需要对 themeData 进行额外配置, 在 toThemeData(themeData) 处传入自定义主题即可
  var theme = ZoStyle(brightness: Brightness.light).toThemeData();
  var darkTheme = ZoStyle(brightness: Brightness.dark).toThemeData();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      themeMode: ThemeMode.dark,
      theme: theme,
      darkTheme: darkTheme,
      //...
    );  
  }
}
```

2. 在组件子树中通过 context 使用
```dart
final ZoStyle zoStyle = context.zoStyle;
// 如果需要获取 themeData 对象或 textTheme, 可通过以下方式, 当然, 直接使用 Theme.of(context) 获取也可以
final ThemeData theme = context.zoTheme;
final ThemeData textTheme = context.zoTextTheme;


zoStyle.primaryColor
```



### types

通用类型, 如 `ZoSize`, `ZoStatus`



### 配置

组件通用配置, 用于在组件树中尽可能深的位置对所有组件进行全局性配置, 配置不会响应变更, 需要在初始化阶段确定

```dart 
ZoConfig(
  someConfigField: ...,
  child: ...
)
```



### i18n

通过 flutter 自带的 `Localizations` 提供多语言支持

1. 在 `MaterialApp` 中添加多语言配置

```dart
import "package:flutter_localizations/flutter_localizations.dart";
import "package:zo/base/local/en.dart";
import "package:zo/base/local/zh.dart";
import "package:zo/base/local/zo_localizations.dart";

class MyAppState extends State<MyApp> {
  var supportedLocales = const [Locale("en"), Locale("zh")];

  late var localizationsDelegates = ZoLocalizations.createDelegate(
    resourceMap: {
      Locale("en"): ZoLocalizationsDefault(),
      Locale("zh"): ZoLocalizationsZh(),
    },
    supportedLocales: supportedLocales,
  );

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      localizationsDelegates: [
        localizationsDelegates,
        // 对于使用者, 仍然需要安装 flutter_localizations, 因为 flutter 内置组件需要它们
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: supportedLocales,
      //...
    );  
  }
}
```

2. 在代码中通过 `ZoLocalizations.of(context).myMsg` 或 `context.zoLocal.myMsg` 获取并使用


3. (可选)如果要添加新的语言包, 需要继承 `ZoLocalizations` 并实现 `ZoLocalizationsDefault`, 然后在 `resourceMap` 中添加它, 比如:

```dart
import "package:zo/base/local/en.dart";
import "package:zo/base/local/zo_localizations.dart";

class ZoLocalizationsZh extends ZoLocalizations
    implements ZoLocalizationsDefault {
  @override
  final msg = "你好, 世界";
}
```


> 扩展多语言字段?
> - 对于组件开发者, 在 `ZoLocalizationsDefault` 新增属性并同步新增所有子类接口接口即可;
> - 对于用户, 应该考虑自行实现 `LocalizationsDelegate` 而不是和组件库共用




4. (可选) 在用户侧复用组件库的本地化实现, 需要继承 `ZoLocalizations` 并自行提供 of / createDelegate 方法

```dart
class CustomZoLocalizations extends ZoLocalizations {
  static CustomLocalizationsDefault of(BuildContext context) {
    var local = Localizations.of<CustomLocalizationsDefault>(context, CustomLocalizationsDefault);
    return local!;
  }

  static LocalizationsDelegate<ZoLocalizations> createDelegate({
    required Map<Locale, ZoLocalizations> resourceMap,
    required List<Locale> supportedLocales,
  }) {
    return ZoLocalizations.createDelegate(
      resourceMap: resourceMap,
      supportedLocales: supportedLocales,
    );
  }
}

// 编写语言类, 选择一个语言作为默认语言
class CustomLocalizationsDefault extends CustomZoLocalizations {
  const CustomLocalizationsDefault();

  final msg = "hello world";
}

// 其他语言类实现默认类
class CustomLocalizationsZh extends CustomZoLocalizations
    implements CustomLocalizationsDefault {
  @override

  final msg = "你好, 世界";
}
```

然后, 用相同的方式在 `MaterialApp.localizationsDelegates` 注册, 之后就可以通过 `CustomZoLocalizations.of(context).msg` 在组件内使用了
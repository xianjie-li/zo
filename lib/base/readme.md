## 基础模块

基础模块提供了其他模块必须的一些东西, 比如常量、类型、预设样式、多语言等.

**consts**

通用常量

**theme**

样式相关定制

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

**types**

通用类型, 如 ZoSize, ZoStatus


**配置**

组件通用配置, 用于在组件树中尽可能深的位置对所有组件进行全局性配置, 配置不会响应变更, 需要在初始化阶段确定

```dart 
ZoConfig(
  someConfigField: ...,
  child: ...
)
```

**i18n**

国际化


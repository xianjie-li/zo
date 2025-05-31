import "package:flutter/widgets.dart";
import "package:zo/src/base/locale/en.dart";

/// 扩展 BuildContext, 用于更方便的获取 ZoLocalizations
extension ZoLocalizationsContext on BuildContext {
  ZoLocalizationsDefault get zoLocale => ZoLocalizations.of(this);
}

/// Zo 多语言支持, 它通过 静态的 Map\<Locale, ZoLocalizations> 来进行多语言配置, ZoLocalizations
/// 的子类通常由 Zo 库提供, 也可能由用户自定义, 这些子类必须实现 [ZoLocalizationsDefault]
///
/// 用法是将组织好的 resourceMap 和其能支持的 supportedLocales 传入 getDelegate() 来
/// 获取 delegate, 并传给 MaterialApp.localizationsDelegates 等 flutter 多语言 api 来进行配置
///
/// 然后, 在代码中通过 ZoLocalizations.of(context) 或 context.zoLocal 获取 ZoLocalizations 对象来使用
class ZoLocalizations {
  const ZoLocalizations();

  /// 从当前 context 获取 local 配置,
  static ZoLocalizationsDefault of(BuildContext context) {
    final locale = Localizations.of<ZoLocalizations>(context, ZoLocalizations);
    return locale == null
        ? const ZoLocalizationsDefault()
        : locale as ZoLocalizationsDefault;
  }

  static LocalizationsDelegate<ZoLocalizations> createDelegate({
    /// 以 Locale 为 key 存储的多语言 resources
    required Map<Locale, ZoLocalizations> resourceMap,

    /// resourceMap 支持的 Locale 列表
    required List<Locale> supportedLocales,
  }) {
    return _ZoLocalizationsDelegate(
      resourceMap: resourceMap,
      supportedLocales: supportedLocales,
    );
  }
}

/// Zo 多语言 Delegate 实现, 由用户提供支持的语言 resources 和支持列表
class _ZoLocalizationsDelegate extends LocalizationsDelegate<ZoLocalizations> {
  const _ZoLocalizationsDelegate({
    required this.resourceMap,
    required this.supportedLocales,
  });

  /// 以 Locale 为 key 存储的对应多语言资源
  final Map<Locale, ZoLocalizations> resourceMap;

  /// 支持的 Locale
  final List<Locale> supportedLocales;

  @override
  bool isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale == locale) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<ZoLocalizations> load(Locale locale) async {
    final res = resourceMap[locale];

    if (res != null) return res;

    throw FlutterError(
      'ZoLocalizations.delegate failed to load unsupported locale "$locale".',
    );
  }

  /// delegate 永远不需要重新加载 delegate
  @override
  bool shouldReload(_ZoLocalizationsDelegate old) => false;
}

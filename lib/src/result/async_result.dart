import "package:flutter/material.dart";
import "package:zo/zo.dart";

typedef ZoAsyncResultBuilder<Data> =
    Widget Function(BuildContext context, Data data);

/// 用于展示异步获取数据的结果
class ZoAsyncResult<Data> extends StatelessWidget {
  const ZoAsyncResult({
    super.key,
    this.data,
    this.error,
    this.loading = false,
    this.retry,
    required this.builder,
    this.parallelData = true,
    this.errorTitle,
    this.errorDesc,
    this.emptyText,
    this.loadingText,
    this.minHeight = 60,
    this.errorIcon,
    this.emptyIcon,
  });

  /// 异步数据
  final Data? data;

  /// 异步错误信息
  final Object? error;

  /// 是否处于加载状态
  final bool loading;

  /// 在加载和错误状态下, 如果存在数据, 是否显示数据, 此时 loading 会在 UI 的上方叠加显示,
  /// 错误/空状态会显示在数据前
  final bool parallelData;

  /// 错误提示标题
  final Widget? errorTitle;

  /// 错误明细, 默认从 error 中获取
  final Widget? errorDesc;

  /// 加载失败时显示的Icon
  final Widget? errorIcon;

  /// 空提示
  final Widget? emptyText;

  /// 空状态下显示的icon
  final Widget? emptyIcon;

  /// 加载时显示的提示文本
  final Widget? loadingText;

  /// 如果提供, 会在错误信息后显示加载信息
  final dynamic Function()? retry;

  /// 设置了 parallelData 时, 需要提供最小高度, 否则loading状态会无法显示
  final double minHeight;

  /// 当包含有效数据时, 用于根据数据构造界面
  final ZoAsyncResultBuilder<Data> builder;

  /// 通过 [Fetcher] 实例来构造结果
  ZoAsyncResult.fetcher({
    Key? key,
    required Fetcher<Data, dynamic> fetcher,
    required ZoAsyncResultBuilder<Data> builder,
    bool parallelData = true,
    Widget? errorTitle,
    Widget? errorDesc,
    Widget? emptyText,
    Widget? loadingText,
    double minHeight = 60,
    Widget? errorIcon,
    Widget? emptyIcon,
  }) : this(
         key: key,
         data: fetcher.data,
         error: fetcher.error,
         loading: fetcher.loading,
         builder: builder,
         retry: fetcher.fetch,
         parallelData: parallelData,
         errorTitle: errorTitle,
         errorDesc: errorDesc,
         emptyText: emptyText,
         loadingText: loadingText,
         minHeight: minHeight,
         errorIcon: errorIcon,
         emptyIcon: emptyIcon,
       );

  Widget buildParallel(BuildContext context) {
    var errorNode = buildError(context, true);

    Widget? emptyNode;

    if (!loading && data == null && errorNode == null) {
      emptyNode = buildEmpty(context)!;
    }

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: minHeight),
      child: ZoProgress(
        open: loading,
        text: loadingText,
        child: SizedBox(
          width: double.infinity,
          child: Column(
            // crossAxisAlignment: CrossAxisAlignment.start,
            spacing: context.zoStyle.space2,
            children: [
              if (errorNode != null) errorNode,
              if (emptyNode != null) emptyNode,
              if (data != null) builder(context, data as Data),
            ],
          ),
        ),
      ),
    );
  }

  Widget? buildError(BuildContext context, [bool isCompact = false]) {
    if (error == null) return null;

    return ZoResult(
      simpleResult: isCompact,
      icon:
          errorIcon ??
          Icon(Icons.cancel_rounded, color: context.zoStyle.errorColor),
      title: errorTitle ?? Text(context.zoLocal.loadFail),
      desc: errorDesc ?? Text(error.toString()),
      actions: buildActions(context, isCompact),
    );
  }

  Widget? buildEmpty(BuildContext context) {
    if (data != null) return null;

    return ZoResult(
      icon:
          emptyIcon ?? Icon(Icons.inbox, color: context.zoStyle.hintTextColor),
      title: emptyText ?? Text(context.zoLocal.noData),
      actions: buildActions(context),
    );
  }

  List<Widget> buildActions(BuildContext context, [bool isCompact = false]) {
    if (retry == null) return [];
    return [
      ZoButton(
        onPressed: retry,
        primary: true,
        text: isCompact,
        size: isCompact ? ZoSize.small : ZoSize.medium,
        child: Text(context.zoLocal.retry),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    if (parallelData) return buildParallel(context);

    var style = context.zoStyle;

    Widget? statusNode;

    if (loading) {
      statusNode = ZoProgress(text: loadingText);
    } else if (error != null) {
      statusNode = buildError(context)!;
    } else if (data == null) {
      statusNode = buildEmpty(context)!;
    }

    if (statusNode != null) {
      return Padding(
        padding: EdgeInsets.all(style.space3),
        child: Center(child: statusNode),
      );
    }

    return builder(context, data as Data);
  }
}

import "dart:math" as math;

import "package:animated_emoji/animated_emoji.dart";
import "package:flutter/material.dart";
import "package:zo/src/animation/transition.dart";
import "package:zo/src/animation/transition_base.dart";
import "package:zo/zo.dart";

class ResultPage extends StatefulWidget {
  const ResultPage({super.key});

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  @override
  Widget build(BuildContext context) {
    var style = context.zoStyle;

    late var data = List.generate(100, (index) {
      return "这是一段文本, 索引 $index";
    });

    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          child: Column(
            spacing: 40,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ZoResult(title: Text("没有数据")),
              ZoResult(title: Text("没有数据"), desc: Text("当时数据为空, 请稍后重试")),
              ZoResult(
                size: ZoSize.small,
                icon: Icon(Icons.folder_open),
                title: Text("没有数据"),
                desc: Text("当时数据为空, 请稍后重试"),
              ),
              ZoResult(
                icon: Icon(Icons.inbox),
                title: Text("没有数据"),
                desc: Text("当时数据为空, 请稍后重试"),
              ),
              ZoResult(
                size: ZoSize.large,
                icon: Icon(Icons.inbox),
                title: Text("没有数据"),
                desc: Text("当时数据为空, 请稍后重试"),
              ),
              ZoResult(
                icon: AnimatedEmoji(AnimatedEmojis.cryingCatFace, repeat: true),
                title: Text("没有数据"),
                desc: Text(
                  "当时数据为空, 请稍后重试请稍后重试请稍后重试请稍后重试请稍后重试请稍后重试请稍后重试请稍后重试请稍后重试请稍后重试请稍后重试请稍后重试请稍后重试请稍后重试",
                ),
              ),
              ZoResult(
                size: ZoSize.small,
                icon: Icon(Icons.inbox),
                title: Text("没有数据"),
                desc: Text("当时数据为空, 请稍后重试请稍后重试请稍后重试请稍后重试请稍后重试请稍"),
                actions: [
                  ZoButton(
                    size: ZoSize.small,
                    child: Text("取消"),
                    onPressed: () {},
                  ),
                  ZoButton(
                    size: ZoSize.small,
                    primary: true,
                    child: Text("重试"),
                    onPressed: () {},
                  ),
                ],
              ),
              ZoResult(
                icon: Icon(Icons.inbox),
                title: Text("没有数据"),
                desc: Text("当时数据为空, 请稍后重试请稍后重试请稍后重试请稍后重试请稍后重试请稍"),
                actions: [
                  ZoButton(child: Text("取消"), onPressed: () {}),
                  ZoButton(primary: true, child: Text("重试"), onPressed: () {}),
                ],
              ),
              ZoResult(
                size: ZoSize.large,
                icon: Icon(Icons.inbox),
                title: Text("没有数据"),
                desc: Text("当时数据为空, 请稍后重试请稍后重试请稍后重试请稍后重试请稍后重试请稍"),
                actions: [
                  ZoButton(
                    size: ZoSize.large,
                    child: Text("取消"),
                    onPressed: () {},
                  ),
                  ZoButton(
                    size: ZoSize.large,
                    primary: true,
                    child: Text("重试"),
                    onPressed: () {},
                  ),
                ],
              ),
              ZoResult(
                icon: Icon(Icons.inbox),
                title: Text("没有数据"),
                desc: Text("当时数据为空, 请稍后重试请稍后重试请稍后重试请稍后重试请稍后重试请稍"),
                actions: [
                  ZoButton(child: Text("取消"), onPressed: () {}),
                  ZoButton(primary: true, child: Text("重试"), onPressed: () {}),
                ],
                extra: Column(
                  spacing: style.space2,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("提示1: 请前往个人中心完善个人信息"),
                    Text("提示2: 上传头像后, 才能查看更多信息"),
                  ],
                ),
              ),
              ZoResult(
                icon: Icon(Icons.info, color: style.infoColor),
                title: Text("提示信息"),
                desc: Text("当时数据为空, 请稍后重试"),
              ),
              ZoResult(
                icon: Icon(Icons.warning_rounded, color: style.warningColor),
                title: Text("警告信息"),
                desc: Text("当时数据为空, 请稍后重试"),
              ),
              ZoResult(
                icon: Icon(Icons.cancel_rounded, color: style.errorColor),
                title: Text("错误信息"),
                desc: Text("当时数据为空, 请稍后重试"),
              ),
              ZoResult(
                icon: Icon(
                  Icons.check_circle_rounded,
                  color: style.successColor,
                ),
                title: Text("成功信息"),
                desc: Text("当时数据为空, 请稍后重试"),
              ),

              ZoResult(
                simpleResult: true,
                icon: Icon(
                  Icons.check_circle_rounded,
                  color: style.successColor,
                ),
                title: Text("成功信息"),
                desc: Text("当时数据为空, 请稍后重试"),
                actions: [
                  ZoButton(
                    onPressed: () {},
                    text: true,
                    size: ZoSize.small,
                    child: Text("重试"),
                  ),
                ],
              ),

              Container(
                decoration: BoxDecoration(border: Border.all()),
                width: double.infinity,
                child: ZoAsyncResult<List<String>>(
                  data: data,
                  parallelData: false,
                  builder: (context, data) {
                    return SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          return Text(data[index]);
                        },
                      ),
                    );
                  },
                ),
              ),

              Container(
                decoration: BoxDecoration(border: Border.all()),
                width: double.infinity,
                child: ZoAsyncResult<List<String>>(
                  data: null,
                  retry: () {},
                  parallelData: false,
                  builder: (context, data) {
                    return SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          return Text(data[index]);
                        },
                      ),
                    );
                  },
                ),
              ),

              Container(
                decoration: BoxDecoration(border: Border.all()),
                width: double.infinity,
                child: ZoAsyncResult<List<String>>(
                  data: null,
                  parallelData: false,
                  error: ZoException("数据加载失败, 请稍后重试"),
                  retry: () {},
                  builder: (context, data) {
                    return SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          return Text(data[index]);
                        },
                      ),
                    );
                  },
                ),
              ),

              Container(
                decoration: BoxDecoration(border: Border.all()),
                // width: double.infinity,
                child: ZoAsyncResult<List<String>>(
                  data: null,
                  loading: true,
                  builder: (context, data) {
                    return SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          return Text(data[index]);
                        },
                      ),
                    );
                  },
                ),
              ),

              Container(
                decoration: BoxDecoration(border: Border.all()),
                // width: double.infinity,
                child: ZoAsyncResult<List<String>>(
                  data: data,
                  loading: true,
                  builder: (context, data) {
                    return SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          return Text(data[index]);
                        },
                      ),
                    );
                  },
                ),
              ),

              Container(
                decoration: BoxDecoration(border: Border.all()),
                // width: double.infinity,
                child: ZoAsyncResult<List<String>>(
                  // data: data,
                  loading: true,
                  builder: (context, data) {
                    return SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          return Text(data[index]);
                        },
                      ),
                    );
                  },
                ),
              ),

              Container(
                // decoration: BoxDecoration(border: Border.all()),
                // width: double.infinity,
                child: ZoAsyncResult<List<String>>(
                  // data: data,
                  loading: true,
                  error: ZoException("发生了一些错误"),
                  retry: () {},
                  builder: (context, data) {
                    return SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          return Text(data[index]);
                        },
                      ),
                    );
                  },
                ),
              ),

              Container(
                // decoration: BoxDecoration(border: Border.all()),
                // width: double.infinity,
                child: ZoAsyncResult<List<String>>(
                  data: data,
                  loading: false,
                  error: ZoException("发生了一些错误"),
                  retry: () {},
                  builder: (context, data) {
                    return SizedBox(
                      height: 300,
                      child: ListView.builder(
                        itemCount: data.length,
                        itemBuilder: (context, index) {
                          return Text(data[index]);
                        },
                      ),
                    );
                  },
                ),
              ),

              _FetchResult(),
            ],
          ),
        ),
      ),
    );
  }
}

class _FetchResult extends StatefulWidget {
  const _FetchResult({super.key});

  @override
  State<_FetchResult> createState() => _FetchResultState();
}

class _FetchResultState extends State<_FetchResult> with FetcherHelper {
  var fetcher = Fetcher(fetchFn: _getData);

  @override
  List<Fetcher> get fetchers => [fetcher];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ZoButton(child: Text("fetch"), onPressed: fetcher.fetch),
        ZoAsyncResult.fetcher(
          fetcher: fetcher,
          builder: (context, data) {
            return Text(data!);
          },
        ),
      ],
    );
  }
}

Future<String?> _getData(int? a) async {
  await Future.delayed(const Duration(seconds: 2));

  // print("getData: end");

  var rand = math.Random().nextInt(100);

  if (rand > 60) {
    return null;
  } else if (rand > 30) {
    throw ZoException("error");
  }

  return "Hello World: ${a}";
}

import "dart:math" as math;

import "package:flutter/material.dart";
import "package:zo/src/fetcher/fetcher.dart";
import "package:zo/zo.dart";

// 全局fetcher会延迟加载
var globalFetcher = Fetcher(
  payload: 5,
  fetchFn: (int a) async {
    await Future.delayed(Duration(seconds: 1));
    return "Hello World $a";
  },
  onSuccess: (fh) {
    print("global success");
  },
  onError: (fh) {
    print("global error");
  },
  onComplete: (fh) {
    print("global complete");
  },
);

class FetcherPage extends StatefulWidget {
  const FetcherPage({super.key});

  @override
  State<FetcherPage> createState() => _FetcherPageState();
}

class _FetcherPageState extends State<FetcherPage> {
  var show = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          if (show) _RequestTest(),
          // if (show) _RequestTest(),
          if (show) _PageFetchTest(),
          ZoButton(
            child: Text("切换"),
            onTap: () {
              setState(() {
                show = !show;
              });
            },
          ),
        ],
      ),
    );
  }
}

class _RequestTest extends StatefulWidget {
  const _RequestTest();

  @override
  State<_RequestTest> createState() => _RequestTestState();
}

class _RequestTestState extends State<_RequestTest> with FetcherHelper {
  @override
  void initState() {
    super.initState();
    print("initState1");
  }

  late var fetcher1 = Fetcher(
    fetchFn: _getData,
    // refetchInterval: Duration(seconds: 4),
    // retry: 3,
    onSuccess: (fh) {
      // print("success");
    },
    onError: (fh) {
      // print("error");
    },
    onComplete: (fh) {
      // print("complete");
    },
  );

  var fetcher2 = Fetcher(fetchFn: _getData, action: true);

  @override
  // TODO: implement fetchers
  List<Fetcher> get fetchers => [fetcher1, fetcher2];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(border: Border.all()),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Column(
            spacing: 4,
            children: [
              Text("data: ${fetcher1.data}"),
              Text("loading: ${fetcher1.loading}"),
              Text("error: ${fetcher1.error}"),
              Text("payload: ${fetcher1.payload}"),
              Text("fetchAt: ${fetcher1.fetchAt}"),
              Text("retryCount: ${fetcher1.retryCount}"),
              ZoButton(
                child: Text("set Data"),
                onTap: () {
                  fetcher1.data = "Hello World custom";
                },
              ),
              ZoButton(
                child: Text("set Error"),
                onTap: () {
                  fetcher1.error = ZoException("fetch error");
                },
              ),
              ZoButton(
                child: Text("set Loading"),
                onTap: () {
                  fetcher1.loading = !fetcher1.loading;
                },
              ),
              ZoButton(child: Text("refresh"), onTap: fetcher1.fetch),
              ZoButton(
                child: Text("fetch"),
                onTap: () {
                  var n = math.Random().nextInt(100);
                  return fetcher1
                      .fetch(n)
                      .then((d) {
                        // print("fetch success $d");
                      })
                      .catchError((e) {
                        // print("fetch error $e");
                      });
                },
              ),
              ZoButton(
                child: Text("global fetch"),
                onTap: globalFetcher.fetch,
              ),
            ],
          ),

          Divider(),

          Column(
            children: [
              Text("data: ${fetcher2.data}"),
              Text("loading: ${fetcher2.loading}"),
              Text("error: ${fetcher2.error}"),
              Text("payload: ${fetcher2.payload}"),
              Text("fetchAt: ${fetcher2.fetchAt}"),
            ],
          ),
        ],
      ),
    );
  }
}

class _PageFetchTest extends StatefulWidget {
  const _PageFetchTest({super.key});

  @override
  State<_PageFetchTest> createState() => __PageFetchTestState();
}

class __PageFetchTestState extends State<_PageFetchTest> with FetcherHelper {
  late var fetcher = Fetcher(
    fetchFn: _getPageData,
    payload: 0,
    data: [],
    dataBuild: (newData, fh) => [...?fh.data, ...?newData],
    cachePayload: true,
    staleTime: Duration.zero,
    onSuccess: (fh) {},
  );

  @override
  List<Fetcher> get fetchers => [fetcher];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text("loading: ${fetcher.loading}"),
        Text("error: ${fetcher.error}"),
        Text("payload: ${fetcher.payload}"),
        Text("fetchAt: ${fetcher.fetchAt}"),
        ZoButton(
          child: Text("load"),
          onTap: () {
            fetcher.payload = fetcher.payload! + 1;
          },
        ),
        Container(
          height: 300,
          width: 300,
          decoration: BoxDecoration(border: Border.all()),
          child: ListView.builder(
            itemCount: fetcher.data!.length,

            itemBuilder: (context, index) {
              return Text(fetcher.data![index]);
            },
          ),
        ),
      ],
    );
  }
}

int count = 0;

Future<String> _getData(int? a) async {
  print("getData: start");
  await Future.delayed(const Duration(seconds: 2));

  // print("getData: end");

  var rand = math.Random().nextInt(100);

  if (rand > 30) {
    print("getData: error");
    throw ZoException("error");
  }

  return "Hello World: ${a} :${count++}";
}

Future<String> _getData2(int? a) async {
  print("getData2: start");
  await Future.delayed(const Duration(seconds: 2));
  print("getData2: end");
  return "Hello World2 ${count++}";
}

Future<List<String>> _getPageData(int page) async {
  await Future.delayed(const Duration(seconds: 1));
  return List.generate(10, (ind) {
    var startInd = page * 10;
    return "page: $page, index: ${startInd + ind}";
  });
}

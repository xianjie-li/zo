import "dart:async";

import "package:collection/collection.dart";
import "package:flutter_test/flutter_test.dart";
import "package:zo/src/tree_data/tree_data.dart";
import "package:zo/zo.dart";

void main() {
  test("play1", () {
    var num1 = 1;
    var num2 = 1;

    // 相同
    print("num: ${num1.hashCode} ${num2.hashCode}");

    var list1 = [num1, num2];
    var list2 = [num1, num2];

    // 不相同
    print("num: ${list1.hashCode} ${list2.hashCode}");

    var map1 = {"num": num1, "num2": num2};
    var map2 = {"num": num1, "num2": num2};

    // 不相同
    print("num: ${map1.hashCode} ${map2.hashCode}");

    var set1 = {num1, num2};
    var set2 = {num1, num2};

    // 不相同
    print("num: ${set1.hashCode} ${set2.hashCode}");

    var record1 = (num1, num2);
    var record2 = (num2, num2);

    // 相同
    print("num: ${record1.hashCode} ${record2.hashCode}");

    print("obj: ${Object.hashAll([])} ${Object.hashAll([])}");
    print("obj: ${Object.hashAll({})} ${Object.hashAll({})}");
    print("obj: ${Object.hashAll(({}))} ${Object.hashAll(({}))}");

    expect(true, true);
  });

  test("paly2", () async {
    var f = Future.value(123);

    await f.then((v) {
      print(v);
    });

    await f.then((v) {
      print(v);
    });

    await f.then((v) {
      print(v);
    });
  });

  test("paly3", () {
    assert(Symbol.empty == Symbol.empty);
    assert(Symbol("abc") == Symbol("abc"));
  });

  test("paly4", () {
    var set1 = {1, 2, 3};
    var set2 = set1.toSet();

    set2.add(4);

    print(set1);
    print(set2);
  });

  test("play5", () {
    final list = [1, 2, 3, 4, 5];
    print(list.slice(0, 2));
  });

  test("play6", () {
    final rawPaths = [
      [0, 1, 0], // 子孙
      [0, 2], // 独立
      [0], // 祖先
      [0, 1], // 中间层 (0 的子, 0,1,0 的父)
      [0], // 重复
      [1, 0], // 另一个分支
    ];

    final cleanPaths = ZoIndexPathHelper.removeOverlaps(rawPaths);
    print(cleanPaths.map(ZoIndexPathHelper.stringify).toList());

    // 测试数据
    final paths = [
      [0, 1],
      [0, 3], // 与 [0, 1] 不连续
      [0, 2], // 补上中间的 [0, 2]
      [0, 5], // 再次断层
      [1, 0],
      [1, 1], // 与 [1, 0] 连续
    ];
  });
}

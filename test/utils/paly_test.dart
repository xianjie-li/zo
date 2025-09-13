import "dart:async";

import "package:flutter_test/flutter_test.dart";

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
    final String str = "Abc";
    expect(str.contains("Abc"), true);
  });
}

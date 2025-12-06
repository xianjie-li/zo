import "package:flutter/foundation.dart";
import "package:flutter_test/flutter_test.dart";
import "package:zo/zo.dart";

void main() {
  test("createUniqueId", () {
    expect(createTempId(), 1);
    expect(createTempId(), 2);
    expect(createTempId(), 3);
    expect(createTempId(), 4);
  });

  test("displayNumber", () {
    expect(displayNumber(123), "123");
    expect(displayNumber(0), "0");
    expect(displayNumber(1252.05), "1252.05");
    expect(displayNumber(1252.123, 2), "1252.12");
  });

  test("EventTrigger", () {
    final event = EventTrigger<int>();

    int n = 0;

    event.on((int num) {
      n += num;
    });

    handler2(int num) {
      n += num;
    }

    event.on(handler2);

    event.emit(2);

    expect(n, 4);

    event.off(handler2);

    event.emit(2);

    expect(n, 6);
    expect(event.length, 1);

    event.clear();

    expect(n, 6);
    expect(event.length, 0);
  });

  test("isNil", () {
    const val1 = "";
    int? val2;
    const val3 = 0;
    const val4 = 0.0;
    const val5 = false;
    final val6 = [];
    final val7 = {};
    final val8 = <int>{};
    const val9 = "1252";

    expect(isNil(val1), true);
    expect(isNil(val2), true);
    expect(isNil(val3), true);
    expect(isNil(val4), true);
    expect(isNil(val5), true);
    expect(isNil(val6), true);
    expect(isNil(val7), true);
    expect(isNil(val8), true);
    expect(isNil(val9), false);
  });

  test("deepHash", () {
    const num1 = 1;
    const str1 = "hello";
    const bool1 = true;
    int? null1;

    expect(deepHash(num1), deepHash(num1));
    expect(deepHash(str1), deepHash(str1));
    expect(deepHash(bool1), deepHash(bool1));
    expect(deepHash(null1), deepHash(null1));

    final list1 = [num1, str1, bool1, null1];
    final list2 = [num1, str1, bool1, null1];
    final map1 = {num1: num1, str1: str1, bool1: bool1, null1: null1};
    final map2 = {num1: num1, str1: str1, bool1: bool1, null1: null1};
    final set1 = {num1, str1, bool1, null1};
    final set2 = {num1, str1, bool1, null1};
    final record1 = (num1, str1, bool1, null1);
    final record2 = (num1, str1, bool1, null1);

    // 抽样
    expect(
      deepHash(list1) != deepHash(map1) &&
          deepHash(set1) != deepHash(record1) &&
          deepHash(list1) != deepHash(record1),
      true,
    );

    expect(deepHash(list1), deepHash(list2));
    expect(deepHash(map1), deepHash(map2));
    expect(deepHash(set1), deepHash(set2));
    expect(deepHash(record1), deepHash(record2));

    expect(deepHash(null), deepHash(null));
  });

  test("Selector", () {
    final options1 = [1, 2, 3];

    final ZoSelector<int, int> selector = ZoSelector();

    expect(selector.hasSelected(), false);
    expect(selector.isPartialSelected(options1), false);

    selector.select(1);
    selector.select(2);

    expect(selector.hasSelected(), true);
    expect(selector.isPartialSelected(options1), true);
    expect(selector.isAllSelected(options1), false);
    expect(selector.isSelected(1), true);
    expect(selector.isSelected(3), false);
    expect(selector.getSelected(), {1, 2});

    selector.select(3);

    expect(selector.isPartialSelected(options1), false);
    expect(selector.isAllSelected(options1), true);

    selector.unselect(2);

    expect(selector.isSelected(2), false);

    selector.unselectList([1, 2, 3]);

    expect(selector.getSelected().isEmpty, true);

    selector.selectList([1, 2]);

    expect(selector.getSelected(), {1, 2});

    selector.unselectAll();

    expect(selector.getSelected().isEmpty, true);

    selector.selectAll(options1);

    expect(selector.getSelected(), {1, 2, 3});

    selector.toggle(2);

    expect(selector.getSelected(), {1, 3});

    selector.toggle(2);

    expect(selector.getSelected(), {1, 2, 3});

    selector.toggle(2);
    selector.toggleAll(options1);

    expect(selector.getSelected(), {2});

    selector.setSelected([1, 3]);

    expect(selector.getSelected(), {1, 3});
  });

  test("ZoMutator", () {
    final list = [1, 2, 3, 4, 5, 6];

    const addOperation = "add";

    // 交互首尾元素
    const moveOperation = "move";

    const removeOperation = "remove";

    var num = 7;

    final List<List<ZoMutatorRecord<String>>> records = [];
    final List<ZoMutatorSource> sources = [];

    final mutator = ZoMutator<String>(
      operationHandle: (operation, command) {
        sources.add(command.source);

        if (operation == addOperation) {
          list.add(num);
          num++;
          return [removeOperation];
        }

        if (operation == removeOperation) {
          list.removeLast();
          num--;
          return [addOperation];
        }

        if (operation == moveOperation) {
          final last = list.removeLast();
          list.add(list.removeAt(0));
          list.insert(0, last);
          return [moveOperation];
        }

        return null;
      },
      onMutation: (details) {
        records.add(details.operation);
      },
    );

    final details = mutator.mutation(
      ZoMutatorCommand(
        operation: [
          addOperation,
          moveOperation,
        ],
      ),
    );

    expect(list, [7, 2, 3, 4, 5, 6, 1]);

    expect(details, isNotNull);
    expect(details!.operation.length, 2);

    final details2 = mutator.mutation(
      ZoMutatorCommand(
        operation: mutator.reverseOperations(details.operation),
        source: ZoMutatorSource.history,
      ),
    );

    expect(list, [1, 2, 3, 4, 5, 6]);

    final details3 = mutator.mutation(
      ZoMutatorCommand(
        operation: mutator.reverseOperations(details2!.operation),
        source: ZoMutatorSource.history,
      ),
    );

    expect(list, [7, 2, 3, 4, 5, 6, 1]);

    final future = mutator
        .batchMutation(() async {
          await Future.delayed(const Duration(seconds: 1), () {});
          expect(sources, [
            ZoMutatorSource.local,
            ZoMutatorSource.local,
            ZoMutatorSource.history,
            ZoMutatorSource.history,
            ZoMutatorSource.history,
            ZoMutatorSource.history,
          ]);
        })
        .whenComplete(() {
          expect(sources, [
            ZoMutatorSource.local,
            ZoMutatorSource.local,
            ZoMutatorSource.history,
            ZoMutatorSource.history,
            ZoMutatorSource.history,
            ZoMutatorSource.history,
            ZoMutatorSource.local,
            ZoMutatorSource.local,
            ZoMutatorSource.local,
          ]);

          expect(list, [9, 2, 3, 4, 5, 6, 1, 8, 7]);
        });

    mutator.mutation(
      ZoMutatorCommand(
        operation: [addOperation],
      ),
    );

    mutator.mutation(
      ZoMutatorCommand(
        operation: [addOperation, moveOperation],
      ),
    );

    expect(sources, [
      ZoMutatorSource.local,
      ZoMutatorSource.local,
      ZoMutatorSource.history,
      ZoMutatorSource.history,
      ZoMutatorSource.history,
      ZoMutatorSource.history,
    ]);

    expect(list, [7, 2, 3, 4, 5, 6, 1]);

    return future;
  });

  test("MemoCallback", () {
    final m1 = MemoCallback((int a) {
      print(a);
    });

    final m2 = MemoCallback((int b) {
      print(b);
    });

    m1(1);
    m1(2);

    expect(m1.hashCode == m2.hashCode, true);

    expect(m1 == m2, true);
    expect(m1.call == m2.call, false);
  });
}

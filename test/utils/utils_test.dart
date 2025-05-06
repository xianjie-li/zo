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
    var event = ZoEventTrigger<int>();

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
    var val1 = "";
    int? val2;
    var val3 = 0;
    var val4 = 0.0;
    var val5 = false;
    var val6 = [];
    var val7 = {};
    var val8 = <int>{};
    var val9 = "1252";

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
}

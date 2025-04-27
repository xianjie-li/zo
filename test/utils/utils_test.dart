import "package:flutter_test/flutter_test.dart";
import "package:zo/src/utils/utils.dart";

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
    expect(displayNumber(1252.05), "1252.0");
    expect(displayNumber(1252.123, 2), "1252.12");
  });

  test("EventTrigger", () {
    var event = EventTrigger<int>();

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
}

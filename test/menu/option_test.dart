import "package:flutter/widgets.dart";
import "package:flutter_test/flutter_test.dart";
import "package:zo/zo.dart";

void main() {
  Future<List<ZoOption>> loadOptions(ZoOption option) async {
    final List<ZoOption> list = [];

    // await Future.delayed(Duration(seconds: 1));

    // if (Random().nextDouble() > 0.7) {
    //   return list;
    // }

    for (int i = 0; i < 8; i++) {
      list.add(
        ZoOption(
          value: "${option.value}-$i",
          title: Text("选项-$i"),
        ),
      );
    }

    return list;
  }

  test("ZoOptionController", () {
    List<ZoOption> options = [
      ZoOption(
        value: "Option 1",
        title: const Text("Option 1"),
      ),
      ZoOption(
        value: "Option 2",
        title: const Text("Option 2"),
        children: [
          ZoOption(
            value: "Option 2-1",
            title: const Text("Option 2-1"),
          ),
          ZoOption(
            value: "Option 2-2",
            title: const Text("Option 2-2"),
            children: [
              ZoOption(
                value: "Option 2-2-1",
                title: const Text("Option 2-2-1"),
              ),
              ZoOption(
                value: "Option 2-2-2",
                title: const Text("Option 2-2-2"),
              ),
            ],
          ),
        ],
      ),
      ZoOption(
        value: "Option 3",
        title: const Text("Option 3"),
        children: [
          ZoOption(
            value: "Option 3-1",
            title: const Text("Option 3-1"),
          ),
          ZoOption(
            value: "Option 3-2",
            title: const Text("Option 3-2"),
          ),
        ],
      ),
    ];

    final c = ZoOptionController(data: options, expandAll: true);

    expect(c.processedData.length, 3);
    expect(c.flatList.length, 9);
    expect(c.filteredFlatList.length, 9);

    c.matchString = "Option 2-2-1";

    expect(c.processedData.length, 3);
    expect(c.flatList.length, 9);
    expect(c.filteredFlatList.length, 3);
    expect(
      c.isVisible("Option 2-2-1"),
      true,
    );
    expect(
      c.isMatch("Option 2-2"),
      false,
    );

    c.matchString = "Option 2-2";

    expect(
      c.isMatch("Option 2-2"),
      true,
    );

    c.selector.select("Option 2-2");
    expect(c.hasSelectedChild("Option 2"), true);
    expect(c.hasSelectedChild("Option 1"), false);

    expect(c.processedData.length, 3);
    expect(c.flatList.length, 9);
    expect(c.filteredFlatList.length, 4);
    expect(
      c.hasSelectedChild("Option 2-2"),
      false,
    );
    expect(
      [
        c.filteredFlatList[0].value,
        c.filteredFlatList[1].value,
        c.filteredFlatList[2].value,
        c.filteredFlatList[3].value,
      ],
      [
        "Option 2",
        "Option 2-2",
        "Option 2-2-1",
        "Option 2-2-2",
      ],
    );

    expect(c.getChildren().length, 1);

    expect(
      c.getNode("Option 2-2")!.path,
      [1, 1],
    );

    expect(
      c
          .getChildren(
            value: "Option 2-2",
          )
          .length,
      2,
    );

    expect(c.getChildren(filtered: false).length, 3);

    final c2 = ZoOptionController(data: options);

    expect(c2.filteredFlatList.length, 3);

    c2.expander.select("Option 3");

    expect(c2.filteredFlatList.length, 5);

    c2.expander.select("Option 2");

    expect(c2.filteredFlatList.length, 7);
  });

  test("ZoOptionController Async", () async {
    final List<ZoOption> options = [
      ZoOption(
        value: "Option 1",
        title: const Text("Option 1"),
      ),
      ZoOption(
        value: "Option 3",
        title: const Text("Option 3"),
        children: [
          ZoOption(
            value: "Option 3-1",
            title: const Text("Option 3-1"),
            loader: loadOptions,
          ),
          ZoOption(
            value: "Option 3-2",
            title: const Text("Option 3-2"),
            loader: loadOptions,
          ),
        ],
      ),
    ];

    final c = ZoOptionController(data: options, expandAll: true);

    expect(c.flatList.length, 4);

    await c.loadChildren("Option 3-1");

    expect(c.flatList.length, 12);

    final asyncOptions = c.getChildren(value: "Option 3-1");

    expect(asyncOptions.length, 8);
    expect(asyncOptions[0].value, "Option 3-1-0");
    expect(asyncOptions[7].value, "Option 3-1-7");
  });

  test("ZoOptionController Update", () async {
    final List<ZoOption> options = [
      ZoOption(
        value: "Option 1",
        title: const Text("Option 1"),
      ),
      ZoOption(value: "Option 3", title: const Text("Option 3"), children: []),
    ];

    final c = ZoOptionController(data: options, expandAll: true);

    final node = c.getNode("Option 3")!;

    node.data.children = [
      ZoOption(
        value: "Option 3-1",
        title: const Text("Option 3-1"),
      ),
      ZoOption(
        value: "Option 3-2",
        title: const Text("Option 3-2"),
      ),
    ];

    c.refresh();

    expect(c.processedData.length, 2);
    expect(c.flatList.length, 4);

    final opt = c.getChildren(value: "Option 3");
    expect(opt[0].value, "Option 3-1");
    expect(opt[1].value, "Option 3-2");

    c.data = [
      ZoOption(
        value: "Option x1",
        title: const Text("Option x1"),
      ),
      ZoOption(
        value: "Option x2",
        title: const Text("Option x3"),
        children: [
          ZoOption(
            value: "Option x2-1",
            title: const Text("Option x2-1"),
          ),
          ZoOption(
            value: "Option x2-2",
            title: const Text("Option x2-2"),
          ),
        ],
      ),
      ZoOption(
        value: "Option x3",
        title: const Text("Option x3"),
      ),
    ];

    expect(c.processedData.length, 3);
    expect(c.flatList.length, 5);

    final opt2 = c.getChildren(value: "Option x2");
    expect(opt2[0].value, "Option x2-1");
    expect(opt2[1].value, "Option x2-2");

    c.matchString = "Option x2-1";

    expect(c.processedData.length, 3);
    expect(c.flatList.length, 5);
    expect(c.filteredFlatList.length, 2);
  });
}

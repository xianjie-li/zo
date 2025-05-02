import "package:flutter/material.dart";
import "package:flutter/widgets.dart";
import "package:zo/src/base/theme/style.dart";
import "package:zo/src/button/button.dart";
import "package:zo/src/progress/progress.dart";
import "package:zo/zo.dart";

class ButtonPage extends StatefulWidget {
  const ButtonPage({super.key});

  @override
  State<ButtonPage> createState() => _ButtonPageState();
}

class _ButtonPageState extends State<ButtonPage> {
  bool open = true;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      clipBehavior: Clip.none,
      padding: EdgeInsets.all(24),
      child: Column(
        children: [
          Wrap(
            spacing: 4,
            children: [
              ZoButton(size: ZoSize.small, child: Text("常规")),
              ZoButton(size: ZoSize.small, icon: Icon(Icons.access_alarm)),
              ZoButton(
                size: ZoSize.small,
                icon: Icon(Icons.access_alarm),
                child: Text("常规"),
              ),
              ZoButton(size: ZoSize.small, child: Text("常规"), onPressed: () {}),
              ZoButton(
                size: ZoSize.small,
                icon: Icon(Icons.account_circle_rounded),
                onPressed: () {},
              ),
              ZoButton(
                size: ZoSize.small,
                icon: Icon(Icons.cable_sharp),
                onPressed: () {},
              ),
              ZoButton(
                loading: true,
                size: ZoSize.small,
                icon: Icon(Icons.access_alarm),
                onPressed: () {},
              ),
              ZoButton(
                primary: true,
                size: ZoSize.small,
                icon: Icon(Icons.table_restaurant_outlined),
                onPressed: () {},
              ),
              ZoButton(
                size: ZoSize.small,
                text: true,
                onPressed: () {},
                child: Text("常规常规"),
              ),
              ZoButton(
                size: ZoSize.small,
                text: true,
                onPressed: () {},
                child: Text("常规常规常规"),
              ),
              ZoButton(
                size: ZoSize.small,
                text: true,
                onPressed: null,
                child: Text("常规"),
              ),
              ZoButton(
                size: ZoSize.small,
                icon: Icon(Icons.cable_sharp),
                square: true,
                onPressed: () {},
              ),
              ZoButton(
                size: ZoSize.small,
                icon: Icon(Icons.access_alarm),
                square: true,
                onPressed: () {},
              ),
              ZoButton(
                size: ZoSize.small,
                primary: true,
                icon: Icon(Icons.access_alarm),
                child: Text("常规"),
                onPressed: () {},
              ),
              ZoButton(
                size: ZoSize.small,
                icon: Icon(Icons.access_alarm),
                child: Text("常规"),
                onPressed: () {},
              ),
              ZoButton(
                size: ZoSize.small,
                icon: Icon(Icons.access_alarm),
                child: Text("常规常规常规常规常规"),
                onPressed: () {},
              ),
            ],
          ),
          SizedBox(height: 24),
          Wrap(
            spacing: 4,
            children: [
              ZoButton(child: Text("常规")),
              ZoButton(icon: Icon(Icons.access_alarm)),
              ZoButton(icon: Icon(Icons.access_alarm), child: Text("常规")),
              ZoButton(child: Text("常规"), onPressed: () {}),
              ZoButton(
                icon: Icon(Icons.account_circle_rounded),
                onPressed: () {},
              ),
              ZoButton(icon: Icon(Icons.cable_sharp), onPressed: () {}),
              ZoButton(icon: Icon(Icons.access_alarm), onPressed: () {}),
              ZoButton(
                primary: true,
                icon: Icon(Icons.table_restaurant_outlined),
                onPressed: () {},
              ),
              ZoButton(text: true, onPressed: () {}, child: Text("常规常规")),
              ZoButton(text: true, onPressed: () {}, child: Text("常规常规常规")),
              ZoButton(text: true, onPressed: null, child: Text("常规")),
              ZoButton(
                icon: Icon(Icons.cable_sharp),
                square: true,
                onPressed: () {},
              ),
              ZoButton(
                loading: true,

                icon: Icon(Icons.access_alarm),
                square: true,
                onPressed: () {},
              ),
              ZoButton(
                primary: true,
                icon: Icon(Icons.access_alarm),
                child: Text("常规"),
                onPressed: () {},
              ),
              ZoButton(
                icon: Icon(Icons.access_alarm),
                child: Text("常规"),
                onPressed: () {},
              ),
              ZoButton(
                icon: Icon(Icons.access_alarm),
                child: Text("常规常规常规常规常规"),
                onPressed: () {},
              ),
            ],
          ),
          SizedBox(height: 24),
          Wrap(
            spacing: 4,
            children: [
              ZoButton(size: ZoSize.large, child: Text("常规")),
              ZoButton(size: ZoSize.large, icon: Icon(Icons.access_alarm)),
              ZoButton(
                size: ZoSize.large,
                icon: Icon(Icons.access_alarm),
                child: Text("常规"),
              ),
              ZoButton(size: ZoSize.large, child: Text("常规"), onPressed: () {}),
              ZoButton(
                size: ZoSize.large,
                icon: Icon(Icons.account_circle_rounded),
                onPressed: () {},
              ),
              ZoButton(
                loading: true,
                size: ZoSize.large,
                icon: Icon(Icons.cable_sharp),
                onPressed: () {},
              ),
              ZoButton(
                size: ZoSize.large,
                icon: Icon(Icons.access_alarm),
                onPressed: () {},
              ),
              ZoButton(
                primary: true,
                size: ZoSize.large,
                icon: Icon(Icons.table_restaurant_outlined),
                onPressed: () {},
              ),
              ZoButton(
                size: ZoSize.large,
                text: true,
                onPressed: () {},
                child: Text("常规常规"),
              ),
              ZoButton(
                size: ZoSize.large,
                text: true,
                onPressed: () {},
                child: Text("常规常规常规"),
              ),
              ZoButton(
                size: ZoSize.large,
                text: true,
                onPressed: null,
                child: Text("常规"),
              ),
              ZoButton(
                size: ZoSize.large,
                icon: Icon(Icons.cable_sharp),
                square: true,
                onPressed: () {},
              ),
              ZoButton(
                size: ZoSize.large,
                icon: Icon(Icons.access_alarm),
                square: true,
                onPressed: () {},
              ),
              ZoButton(
                size: ZoSize.large,
                primary: true,
                icon: Icon(Icons.access_alarm),
                child: Text("常规"),
                onPressed: () {},
              ),
              ZoButton(
                size: ZoSize.large,
                icon: Icon(Icons.access_alarm),
                child: Text("常规"),
                onPressed: () {},
              ),
              ZoButton(
                size: ZoSize.large,
                icon: Icon(Icons.access_alarm),
                child: Text("常规常规常规常规常规"),
                onPressed: () {},
              ),
            ],
          ),
          SizedBox(height: 24),
          Wrap(
            spacing: 4,
            children: [
              ZoButton(
                loading: true,
                size: ZoSize.small,
                icon: Icon(Icons.cable_sharp),
                child: Text("点击我"),
                onPressed: () {},
              ),
              ZoButton(
                loading: true,
                icon: Icon(Icons.cable_sharp),
                child: Text("点击我"),
                onPressed: () {},
              ),
              ZoButton(
                loading: true,
                size: ZoSize.large,
                icon: Icon(Icons.cable_sharp),
                child: Text("点击我"),
                onPressed: () {},
              ),
            ],
          ),
          SizedBox(height: 24),
          Wrap(
            spacing: 4,
            children: [
              ZoButton(
                icon: Icon(Icons.account_circle_rounded),
                onPressed: () {},
                color: Colors.red,
              ),
              ZoButton(
                icon: Icon(Icons.account_circle_rounded),
                onPressed: () {},
                color: Colors.green,
              ),
              ZoButton(
                icon: Icon(Icons.account_circle_rounded),
                onPressed: () {},
                color: Colors.purple,
              ),
              ZoButton(
                icon: Icon(Icons.account_circle_rounded),
                onPressed: () {},
                color: Colors.purple.shade100,
              ),
              ZoButton(
                icon: Icon(Icons.account_circle_rounded),
                onPressed: null,
                color: Colors.purple,
              ),
            ],
          ),
          SizedBox(height: 24),
          Wrap(
            spacing: 4,
            children: [
              ZoButton(
                color: Colors.red,
                text: true,
                onPressed: () {},
                child: Text("常规常规"),
              ),
              ZoButton(
                color: Colors.green,
                text: true,
                onPressed: () {},
                child: Text("常规常规"),
              ),
              ZoButton(
                color: Colors.purple,
                text: true,
                onPressed: () {},
                child: Text("常规常规"),
              ),
              ZoButton(
                color: Colors.purple.shade100,
                text: true,
                onPressed: () {},
                child: Text("常规常规"),
              ),
              ZoButton(
                color: Colors.purple,
                text: true,
                onPressed: null,
                child: Text("常规常规"),
              ),
            ],
          ),
          SizedBox(height: 24),
          Wrap(
            spacing: 4,
            children: [
              ZoButton(
                color: Colors.red,
                onPressed: () {},
                child: Text("常规常规"),
              ),
              ZoButton(
                color: Colors.green,
                onPressed: () {},
                child: Text("常规常规"),
              ),
              ZoButton(
                color: Colors.purple,
                onPressed: null,
                child: Text("常规常规"),
              ),
              ZoButton(
                color: Colors.purple.shade100,
                onPressed: null,
                child: Text("常规常规"),
              ),
              ZoButton(
                // color: Colors.red,
                icon: Icon(Icons.add),
                onPressed: () {
                  return Future.delayed(Duration(seconds: 3));
                },
                child: Text("常规常规"),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

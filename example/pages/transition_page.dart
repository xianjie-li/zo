import "package:flutter/material.dart";
import "package:flutter/widgets.dart";
import "package:zo/src/transition/transition.dart";
import "package:zo/src/transition/transition_base.dart";

class TransitionPage extends StatefulWidget {
  const TransitionPage({super.key});

  @override
  State<TransitionPage> createState() => _TransitionPageState();
}

class _TransitionPageState extends State<TransitionPage> {
  var open = true;

  Duration duration = Duration(milliseconds: 500);

  Curve curve = Curves.easeInOut;

  Tween<Offset> tween = Tween(begin: Offset(1, 1), end: Offset(0, 0));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        clipBehavior: Clip.none,
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            FilledButton(
              onPressed: () {
                setState(() {
                  open = !open;
                });
              },
              child: Text("toggle: $open"),
            ),
            FilledButton(
              onPressed: () {
                setState(() {
                  duration =
                      duration == Duration(milliseconds: 500)
                          ? Duration(milliseconds: 1000)
                          : Duration(milliseconds: 500);
                  // curve =
                  //     curve == Curves.easeInOut
                  //         ? Curves.easeInOutCubicEmphasized
                  //         : Curves.easeInOut;
                  tween =
                      duration == Duration(milliseconds: 500)
                          ? Tween(begin: Offset(0.2, 0.2), end: Offset(0, 0))
                          : Tween(begin: Offset(1, 1), end: Offset(0, 0));
                });
              },
              child: Text("toggle Config"),
            ),
            Container(
              width: double.infinity,
              height: 800,
              decoration: BoxDecoration(border: Border.all()),
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 32,
                    children: [
                      ZoTransitionBase<double>(
                        open: open,
                        child: Counter(),
                        changeVisible: false,
                        autoAlpha: false,
                        tween: Tween(begin: 0, end: 10000000),
                        animationBuilder: (args) {
                          return Container(
                            width: 100,
                            height: 60,
                            child: Text("${args.animation.value.toInt()}"),
                          );
                        },
                      ),
                      ZoTransitionBase<Offset>(
                        open: open,
                        child: Counter(),
                        duration: duration,
                        curve: curve,
                        tween: tween,
                        builder: (args) {
                          return SlideTransition(
                            position: args.animation,
                            child: args.child,
                          );
                        },
                      ),
                      ZoTransitionBase<double>(
                        open: open,
                        child: Counter(),
                        builder: (args) {
                          return FadeTransition(
                            opacity: args.animation,
                            child: args.child,
                          );
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: 100),
                  Wrap(
                    spacing: 32,
                    runSpacing: 32,
                    children: [
                      ZoTransition(
                        open: open,
                        type: ZoTransitionType.fade,
                        child: Counter(),
                      ),
                      ZoTransition(
                        open: open,
                        type: ZoTransitionType.zoom,
                        child: Counter(),
                      ),
                      ZoTransition(
                        open: open,
                        type: ZoTransitionType.punch,
                        child: Counter(),
                      ),
                      ZoTransition(
                        open: open,
                        type: ZoTransitionType.slideLeft,
                        child: Counter(),
                      ),
                      ZoTransition(
                        open: open,
                        type: ZoTransitionType.slideTop,
                        child: Counter(),
                      ),
                      ZoTransition(
                        open: open,
                        type: ZoTransitionType.slideRight,
                        child: Counter(),
                      ),
                      ZoTransition(
                        open: open,
                        type: ZoTransitionType.slideBottom,
                        child: Counter(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Counter extends StatefulWidget {
  const Counter({super.key});

  @override
  State<Counter> createState() => _CounterState();
}

class _CounterState extends State<Counter> {
  var count = 0;

  @override
  void initState() {
    super.initState();
    print("counter init");
  }

  @override
  Widget build(BuildContext context) {
    print("counter build");

    return GestureDetector(
      onTap: () {
        setState(() {
          count++;
        });
      },
      child: Container(
        width: 100,
        height: 100,
        color: Colors.red,
        child: Text("$count"),
      ),
    );
  }
}

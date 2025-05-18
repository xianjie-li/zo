import "package:animated_emoji/emoji.dart";
import "package:animated_emoji/emojis.g.dart";
import "package:flutter/material.dart";
import "package:flutter/widgets.dart";
import "package:zo/src/base/theme/style.dart";
import "package:zo/src/progress/progress.dart";
import "package:zo/zo.dart";

class ProgressPage extends StatefulWidget {
  const ProgressPage({super.key});

  @override
  State<ProgressPage> createState() => _ProgressPageState();
}

class _ProgressPageState extends State<ProgressPage> {
  bool open = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        clipBehavior: Clip.none,
        padding: EdgeInsets.all(24),
        child: Column(
          children: [
            ZoProgress(value: 0.6),
            SizedBox(height: 24),
            ZoProgress(text: Text("加载中..."), size: ZoSize.small),
            ZoProgress(text: Text("加载中...")),
            ZoProgress(
              text: Text("加载中..."),
              indicator: AnimatedEmoji(
                AnimatedEmojis.robot,
                size: 80,
                repeat: true,
              ),
            ),

            ZoProgress(text: Text("加载中..."), size: ZoSize.large),
            ZoProgress(text: Text("加载中..."), inline: true),
            SizedBox(height: 24),
            ZoProgress(value: 0.6, type: ZoProgressType.linear),
            SizedBox(height: 24),
            ZoProgress(type: ZoProgressType.linear, size: ZoSize.small),
            SizedBox(height: 24),
            ZoProgress(type: ZoProgressType.linear),
            SizedBox(height: 24),
            ZoProgress(type: ZoProgressType.linear, size: ZoSize.large),
            SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                setState(() {
                  open = !open;
                });
              },
              child: ZoProgress(
                open: open,
                text: Text("加载中..."),
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(border: Border.all()),
                  child: Text(
                    "术，没有您我们也能干，但在这人类文明的危难时刻，您这样一位科学家居然抽手旁观。” “我在干更有意义的事情。我们这次在空间站开展的项目，就是对宇宙射线中的高能粒子进行研究，换句话说，用宇宙代替高能加速器",
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            ZoProgress(
              open: open,
              type: ZoProgressType.linear,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(border: Border.all()),
                child: Text(
                  "本很低，可以在太空中建立大量的检测点。这次投入了原计划用于建造地面加速器的资金，设置了上百个检测点，我们这次实验进行了一年，本来也没希望得到什么有价值的东西，只是想查明是否还有更多的智子到达太阳系。”",
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

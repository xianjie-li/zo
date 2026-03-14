import "package:flutter/material.dart";
import "package:zo/zo.dart";

class TagPage extends StatefulWidget {
  const TagPage({super.key});

  @override
  State<TagPage> createState() => _TagPageState();
}

class _TagPageState extends State<TagPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        clipBehavior: Clip.none,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              title: "类型",
              child: const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ZoTag(child: Text("默认标签")),
                  ZoTag(type: ZoTagType.solid, child: Text("实心标签")),
                  ZoTag(type: ZoTagType.outline, child: Text("描边标签")),
                  ZoTag(type: ZoTagType.plain, child: Text("浅色标签")),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "尺寸",
              child: const Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ZoTag(size: ZoSize.small, child: Text("Small")),
                  ZoTag(size: ZoSize.medium, child: Text("Medium")),
                  ZoTag(size: ZoSize.large, child: Text("Large")),
                  ZoTag(
                    type: ZoTagType.solid,
                    size: ZoSize.small,
                    child: Text("小号"),
                  ),
                  ZoTag(
                    type: ZoTagType.solid,
                    size: ZoSize.large,
                    child: Text("大号"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "颜色",
              child: const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ZoTag(color: Colors.blue, child: Text("Blue")),
                  ZoTag(color: Colors.green, child: Text("Green")),
                  ZoTag(color: Colors.orange, child: Text("Orange")),
                  ZoTag(
                    type: ZoTagType.solid,
                    color: Colors.purple,
                    child: Text("Purple"),
                  ),
                  ZoTag(
                    type: ZoTagType.outline,
                    color: Colors.red,
                    child: Text("Red"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "内容",
              child: const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ZoTag(child: Text("文本内容")),
                  ZoTag(
                    type: ZoTagType.solid,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        Icon(Icons.check_circle, size: 14),
                        Text("已完成"),
                      ],
                    ),
                  ),
                  ZoTag(
                    type: ZoTagType.outline,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      spacing: 4,
                      children: [
                        Icon(Icons.schedule, size: 14),
                        Text("处理中"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

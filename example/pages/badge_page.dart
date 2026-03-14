import "package:flutter/material.dart";
import "package:zo/zo.dart";

class BadgePage extends StatefulWidget {
  const BadgePage({super.key});

  @override
  State<BadgePage> createState() => _BadgePageState();
}

class _BadgePageState extends State<BadgePage> {
  double _count = 3;

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
              title: "基础用法",
              child: const Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ZoBadge(),
                  ZoBadge(content: Text("NEW")),
                  ZoBadge(count: 8),
                  ZoBadge(count: 0),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "挂载到子组件",
              child: Wrap(
                spacing: 24,
                runSpacing: 24,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ZoBadge(
                    count: _count,
                    child: _demoSquare(),
                  ),
                  ZoBadge(
                    content: const Text("NEW"),
                    color: Colors.lightGreen,
                    child: _demoSquare(),
                  ),
                  ZoBadge(
                    child: _demoSquare(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "count",
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ZoBadge(count: _count),
                  ZoBadge(count: _count, maxCount: 9),
                  ZoBadge(count: _count, maxCount: 99),
                  ZoBadge(
                    count: _count,
                    size: ZoSize.small,
                    child: _demoSquare(size: 24),
                  ),
                  ZoButton(
                    child: const Text("+1"),
                    onTap: () {
                      setState(() {
                        _count += 1;
                      });
                    },
                  ),
                  ZoButton(
                    child: const Text("-1"),
                    onTap: () {
                      setState(() {
                        _count = (_count - 1).clamp(0, 9999);
                      });
                    },
                  ),
                  ZoButton(
                    child: const Text("随机"),
                    onTap: () {
                      setState(() {
                        _count = (DateTime.now().millisecond % 120).toDouble();
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "最大值限制",
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const ZoBadge(count: 120, maxCount: 99),
                  const ZoBadge(count: 120, maxCount: 9),
                  ZoBadge(
                    count: _count,
                    maxCount: 20,
                    child: _demoSquare(),
                  ),
                  ZoButton(
                    child: const Text("+20"),
                    onTap: () {
                      setState(() {
                        _count += 20;
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "右上角模式尺寸示例",
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ZoBadge(
                    size: ZoSize.small,
                    count: 2,
                    child: _demoSquare(),
                  ),
                  ZoBadge(
                    size: ZoSize.medium,
                    count: 24,
                    child: _demoSquare(),
                  ),
                  ZoBadge(
                    size: ZoSize.large,
                    count: 108,
                    child: _demoSquare(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "组件模式尺寸示例",
              child: const Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ZoBadge(size: ZoSize.small),
                  ZoBadge(size: ZoSize.medium),
                  ZoBadge(size: ZoSize.large),
                  ZoBadge(
                    count: 3,
                    size: ZoSize.small,
                  ),
                  ZoBadge(count: 2),
                  ZoBadge(count: 3),
                  ZoBadge(count: 24, size: ZoSize.medium),
                  ZoBadge(count: 108, size: ZoSize.large),
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

  Widget _demoSquare({double size = 28, double borderRadius = 6}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.grey.shade300,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

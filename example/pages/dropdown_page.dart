import "package:flutter/material.dart";
import "package:zo/zo.dart";

class DropdownPage extends StatefulWidget {
  const DropdownPage({super.key});

  @override
  State<DropdownPage> createState() => _DropdownPageState();
}

class _DropdownPageState extends State<DropdownPage> {
  late final List<ZoOption> _options = [
    ZoOption(value: "apple", title: const Text("Apple")),
    ZoOption(value: "banana", title: const Text("Banana")),
    ZoOption(value: "orange", title: const Text("Orange")),
    ZoOption(value: "grape", title: const Text("Grape")),
  ];

  Iterable<Object> _single = const [];
  Iterable<Object> _multiple = const ["banana"];

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
              title: "单选",
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ZoDropdown(
                    options: _options,
                    value: _single,
                    onChanged: (value) {
                      setState(() {
                        _single = value ?? const [];
                      });
                    },
                    child: const Text("请选择水果"),
                  ),
                  Text("当前值: ${_single.join(", ")}"),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "多选",
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ZoDropdown(
                    options: _options,
                    value: _multiple,
                    maxSelectedShowNumber: 3,
                    selectionType: ZoSelectionType.multiple,
                    onChanged: (value) {
                      setState(() {
                        _multiple = value ?? const [];
                      });
                    },
                    child: const Text("请选择多个水果"),
                  ),
                  Text("当前值: ${_multiple.join(", ")}"),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "尺寸与菜单宽度",
              child: Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  ZoDropdown(
                    options: _options,
                    value: _single,
                    buttonMinWidth: 120,
                    buttonMaxWidth: 160,
                    onChanged: (value) {
                      setState(() {
                        _single = value ?? const [];
                      });
                    },
                    child: const Text("按钮最小/最大宽度"),
                  ),
                  ZoDropdown(
                    options: _options,
                    value: _multiple,
                    selectionType: ZoSelectionType.multiple,
                    buttonMaxWidth: 180,
                    menuWidth: 280,
                    onChanged: (value) {
                      setState(() {
                        _multiple = value ?? const [];
                      });
                    },
                    child: const Text("菜单固定宽度 280"),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "隐藏指示器",
              child: ZoDropdown(
                options: _options,
                value: _single,
                showOpenIndicator: false,
                onChanged: (value) {
                  setState(() {
                    _single = value ?? const [];
                  });
                },
                child: const Text("不显示上下箭头"),
              ),
            ),
            const SizedBox(height: 24),
            _buildSection(
              title: "隐藏指示器",
              child: ZoDropdown(
                options: _options,
                value: _single,
                selectionType: ZoSelectionType.none,
                onChanged: (value) {
                  setState(() {
                    _single = value ?? const [];
                  });
                },
                child: const Text("不显示上下箭头"),
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

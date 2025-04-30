## Layout 布局

核心:
- 基于可用空间的媒体查询 / 栅格
- 通用交互容器: 边框 / 阴影 / 背景色 / 透明度 / scale / 文本色交互
  - 支持直接作为 Container, 也支持通过 builder 接收属性使用


### AdaptiveLayout

响应式布局工具, 用于简化响应式布局的实现

```dart
ZoAdaptiveLayout<Color>(
  // 推荐用法, 为不同断点提供不同的值, 并在builder中通过 meta.value 使用
  values: {
    ZoAdaptiveLayoutPointType.xs: Colors.red.shade300,
    ZoAdaptiveLayoutPointType.md: Colors.blue.shade300,
    ZoAdaptiveLayoutPointType.xl: Colors.green.shade300,
  },
  builder: (context, meta, child) {
    var text = "";

    // 另一种用法是根据当前屏幕大小动态显示不同UI
    if (meta.isSmall) {
      text = "小屏";
    } else if (meta.isMedium) {
      text = "中屏";
    } else if (meta.isLarge) {
      text = "大屏";
    }

    return Container(
      padding: EdgeInsets.all(16),
      width: double.infinity,
      color: meta.value,
      child: Text(text, style: TextStyle(color: Colors.white)),
    );
  },
)
```

### Cells

使用栅格系统进行布局, 栅格宽度为 12, 可结合 `ZoAdaptiveLayout` 实现响应式栅格

```dart
ZoAdaptiveLayout<double>(
  values: {
    ZoAdaptiveLayoutPointType.xs: 12,
    ZoAdaptiveLayoutPointType.md: 6,
    ZoAdaptiveLayoutPointType.xl: 4,
    ZoAdaptiveLayoutPointType.xxl: 3,
  },
  builder: (context, meta, child) {
    return ZoCells(
      runSpacing: 12,
      spacing: 12,
      children: [
        ZoCell(
          span: meta.value,
          child: Container(color: Colors.grey.shade300, height: 30),
        ),
        ZoCell(
          span: meta.value,
          child: Container(color: Colors.grey.shade300, height: 30),
        ),
        ZoCell(
          span: meta.value,
          child: Container(color: Colors.grey.shade300, height: 30),
        ),
        ZoCell(
          span: meta.value,
          child: Container(color: Colors.grey.shade300, height: 30),
        ),
        ZoCell(
          span: meta.value,
          child: Container(color: Colors.grey.shade300, height: 30),
        ),
      ],
    );
  },
)

```
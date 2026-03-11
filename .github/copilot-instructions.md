# Zo — Copilot Instructions

Zo 是 Flutter 组件库 + 工具库，主线是“统一交互层 + 统一弹层 + 统一主题 token”。

## 先看哪里（高价值入口）

- `lib/zo.dart`：公共 API 总出口；新增模块时必须补 export。
- `example/main.dart`：完整集成模板（主题、多语言、`ZoConfig`、`ZoOverlayProvider`）。
- `example/pages/*_page.dart`：每个组件的真实用法，优先按这里的模式实现。
- `lib/src/base/readme.md`：主题/配置/本地化约定。
- `lib/src/overlay/overlay.dart`：弹层体系设计原因与边界（为何要统一到 `zoOverlay`）。

## 架构与边界

- `base/` 提供全局能力：`ZoStyle`、`ZoConfig`、类型与本地化。
- `trigger/` 是底层事件系统；`interactive_box/` 在其上封装交互状态。
- `overlay/` 是弹层引擎；`dialog/`、`popper/`、`notice/`、`menus/` 都应基于它。
- `fetcher/` 负责异步数据（请求收缩、缓存、stale-fresh、分页）。
- `tree_data/`、`dnd/`、`form/` 等是可独立复用的状态/交互模块。

## 必须遵守的初始化顺序

参考 `example/main.dart`，顺序不可乱：

1. 创建明暗 `ZoStyle`，并调用 `style.connectReverse(darkStyle)`。
2. `MaterialApp` 配置 `theme` / `darkTheme` 与 `navigatorKey`。
3. 在 `MaterialApp.builder` 挂 `ZoConfig`。
4. 在 `ZoConfig` 内挂 `ZoOverlayProvider(navigatorKey: ...)`。

## 项目特有实现模式

- 交互组件优先使用 `ZoInteractiveBox` + `ZoTrigger`，不要直接从 `GestureDetector` 起步。
  - 示例：`lib/src/split_view/split_view.dart` 用 `ZoInteractiveBox(onDrag: ...)` 做分割条拖拽。
- 样式从 `context.zoStyle` 取 token（如 `primaryColor`/`outlineColor`/`space*`），避免硬编码主题值。
- 弹层统一走全局 `zoOverlay`；不要混用 `showDialog` 等原生弹层 API（层级与关闭行为会冲突）。
- `Fetcher` 做全局数据源时，优先 `cacheTime = Duration.zero`（避免“全局状态 + 缓存”重复语义）。

## Split View 用法

- `ZoSplitView` 使用 `initialConfig + builder` 驱动；`builder` 收到的是运行时 `ZoSplitViewPanelInfo`，适合根据当前尺寸、折叠状态决定内容渲染。
- 面板配置使用 `ZoSplitViewPanelConfig`：`size` 表示 fixed 像素尺寸，`flex` 表示剩余空间权重；两者只能二选一。
- `initialConfig` 允许传空数组或单个面板：空数组渲染为空白，单面板渲染为无分割线容器；实现时不要额外假设“至少两个面板”。
- 如果需要从外部控制布局，优先通过 `ref` 拿到 `ZoSplitViewState`，再使用 `state.config = ...` 重建布局；不要直接修改 `panels`，除非明确知道自己在处理运行时状态。
- 持久化当前布局时优先使用 `state.getCurrentConfig()`：fixed 面板会导出当前 `size`，flex 面板会按当前占比导出 `flex`，适合做“保存/恢复布局”。
- `resizable = false` 表示只读 split view：仍然显示分栏和分割线，但分割线不允许拖动调整尺寸，鼠标也不会进入可调整状态。

## 开发与验证工作流

- 运行示例应用：`flutter run -t example/main.dart`
- 静态检查：`flutter analyze`
- 测试：`flutter test`
- 目标测试可先跑：`flutter test test/menu/option_test.dart`

## 代码风格（以仓库配置为准）

- `analysis_options.yaml` 要求：双引号、尾随逗号、优先 `final` / `const`。
- 命名约定：组件、类型通常以 `Zo` 前缀（如 `ZoSplitView`、`ZoOptionController`）。
- 新增组件后同步更新：`lib/zo.dart` 导出 + `example/pages/` 示例页（便于回归验证）。

## 本地化集成

- 使用 `ZoLocalizations.createDelegate(...)` 注册语言映射。
- 同时保留 Flutter 官方 delegates（`GlobalMaterialLocalizations` 等），见 `example/main.dart`。

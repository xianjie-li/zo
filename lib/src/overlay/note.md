## 笔记

# 核心类：
- ZoOverlay - 层的总控制中心，也是用户操作的主要api，它在内部维护原生的 Overlay 来渲染覆盖层
- ZoOverlayEntry - 层配置，每一项对应一个显示的层组件，它提供了若干可读写的配置，层会由 ZoOverlay 渲染为 ZoOverlayView 组件，
 并根据其配置进行层的渲染，监听层配置变更进行更新等，它提供了很多扩展接口，使用者可以继承此类来实现自己高度定制化的层
- ZoOverlayView - 一个widget，负责根据 entry 配置对其进行渲染，管理聚焦、响应事件等，每个 view 对应一个 entry
- ZoOverlayPositioned - 对层进行定位的 renderObject，在渲染对象中定位是为了更好的布局性能，
如果使用传统组合 + 状态更新的方式容易导致布局闪烁、低效（布局 -> 检测位置/尺寸 -> 更新状态 -> 布局）
- ZoOverlayRoute - 一个不渲染任何内容的路由，它是层路由的基础，会在设置 route 为 true 的层打开或关闭时同步打开和关闭，但不渲染任何东西，作用是向层提供 onPop 等路由关闭操作，从而使层能够通过原生的路由 api 使用
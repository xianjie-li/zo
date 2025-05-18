
## Overlay 浮层

提供最基础的浮层系统

实现要点:
- Navigator.overlay + navigatorKey
- 层级: 根据推入顺序决定显示层级, 不考虑与内置dialog组件兼容
- 特定时机关闭:
  - 路由变更时, 关闭所有非, 路由返回时恢复路由overlay
- 获取widget尺寸来执行定位/动画: ? 通过 FractionalTranslation 这样的方式在 renderObject 层实现
- 路由: 推送一个空路由来与 routeOverlay 绑定, 路由显示时显示overlay, 隐藏是关闭 overlay
- 更新位置的时机: 滚动?
- 定位方式: 通过 renderObject 层实现组件定位, 动画由组件层再单独通过 Transition 实现

层管理: closeAll  openAll  disposeAll  getInstances - 所有实例
entry: close  open  dispose moveTop / moveBottom
builder

TODO: 通过后续api实现
mountOnEnter / unmountOnExit
支持绑定到多个 Trigger 事件源
canPop - 是否通过 PopScope 等组件能直接实现

- [x] route
- [x] api 简化
- [x] entry 添加各种场景的事件通知
- [] popper
- [] modal
- [] drawer
- [] draggable
- [] notice

路由层实现:
- ZoOverlay 每次open为true开启时, 推送其路由对象到路由栈中
- 监听路由事件: 当路由正常关闭时, 关闭对应的层
- 监听层事件: 当层关闭时, 从路由栈移除对应的路由并将其清理, 如果当前路由为 isCurrent, 使用pop移除, 否则使用 remove
- 批量关闭时: 倒序调用每一项的pop

alignment / xy 显示位置控制 / target - 一个rect

mask / clickAwayClosable - 只影响最后一个entry实例 / escapeClosable 

draggable - 设置拖动位置

路由: routeOverlay - 导航返回值获取 / canPop - 路由可关闭, 支持配置提示文本
通过推送一个无ui路由实现

requestFocus / 

popper相关: offset - 定位偏移 /  direction - 显示方向 / arrow / arrowSize 显示气泡箭头 / preventOverflow

transitionType + 进阶动画配置

## Trigger

通用事件触发器, 比如 hover, 点击, 按下

click / active - 鼠标hover或手指按住一段时间 / hover / focus / contextMenu / move - 持续派发位置

## Popper 气泡提示

overlay: 每个实例都是一个 entry, 不绑定路由

支持 tooltip / confirm 等便捷用法, 支持设置状态

title, text, status, icon,  confirmText, cancelText, onConfirm

```dart
Popper(
  content: Text("hello world"),
  child: Text("hello world"),
)
```

## Dialog 对话框

overlay: 每个实例都是一个 entry, 绑定路由

支持 alter / confirm / prompt 等便捷用法

loading / status / icon / maxWidth / onClose - 任意途径关闭时调用, 可返回future
cancel / confirm / closeButton / draggable / header / content / footer

## Drawer + BottomSheet 抽屉

支持手势和手柄关闭

overlay: 每个实例都是一个 entry, 绑定路由

position / header / footer / draggable

## Notice 轻提示

支持 loading

overlay: 通过单个 entry 实现

export enum NotifyPosition {
  top = "top",
  bottom = "bottom",
  center = "center",
  leftTop = "leftTop",
  leftBottom = "leftBottom",
  rightTop = "rightTop",
  rightBottom = "rightBottom",
}

notify.loading("加载中");
notify.quicker("普通文本提示");
notify.info("稍微重要的信息");
notify.success("成功提示");
notify.error("失败提示");
notify.warning("警告信息");

notify.info("设置位置", NotifyPosition.top);

title / content / status / position / duration / actions / closeable / mask
interactive / loading

## Window 悬浮窗口

可以收起并拖动到任意位置, 可配置收起样式

## Menu
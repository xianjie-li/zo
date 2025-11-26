## Manager

统一管理所有 dnd 的行为，减少 dnd 负责的工作

## 实现

- [ZoDND] - 拖动与放置，会将位置、可见性、可拖放等信息通过 [_ZoDNDNode] 同步到 [_ZoDNDManager]
- [_ZoDNDManager] - 核心逻辑实现区域，管理所有dnd节点
- [ZoDNDPosition] - 控制或表示dnd不同位置的启用状态
- [ZoDNDBuildContext] - dnd的自定义构造器参数，包含了当前拖动状态，用来根据状态构造不同的子级作为反馈
- [ZoDNDEvent] - 核心事件
- [ZoDNDEventNotification] - 通过树向上冒泡 [ZoDNDEvent]

## DND

拖动项，应用中可以存在复数个 DND，通过 groupId 进行分组，同组别的可以互相拖放，并且只响应当前组的事件, 包含一个默认组，尽量将操作外放到 Manager 处理

- x DNDNotification
- x feedback
- x 光标变更
- x accept 触发时需要满足放置条件
- x 嵌套 dnd & groupId测试
- x DNDHandler: 自定义拖动把手
- x DNDFeedback: 简化放置目标的反馈实现
  - x 提供 dnd context 给用于自定义放置到中间的样式（高亮）、拖动中（禁用）样式
  - x 提供 dnd.directionIndicator / dnd.directionIndicator 显示对应方向上的放置标识
  - x 提供 dnd.draggingOpacity 添加拖动中透明度显示
- x accept 触发条件
- x escape 取消拖动
- x 自动滚动: 
  - x 开始拖动时，通知所有dnd上报滚动父级的信息，因为滚动容器在拖动过程动态变更的可能性较小，这能满足大部分场景且性能较好
  - x 拖动时，检测所有rect，如果滚动在任一rect边缘， 获取其对应的滚动父级，执行自动滚动，记录当前距离边缘的距离，越近滚动越快
  - x 拖动结束、滚动父级变更、不可滚动时（atEdge），停止自动滚动
- x 在视口外放置时组件未更新
- x 悬停打开事件: 命中center并持续一段时间未移出时，触发打开事件

## 难点

如何检测可见？
即是否被遮挡、部分遮挡、由于滚动被遮挡，以及可见的部分

visibility_detector

自动滚动实现？
拖动并在一个滚动容器边缘移动时，自动进行滚动

通过 Scrollable.of(context) 查找父级 ScrollableState，可以检测滚动容器、控制位置等

文件放置检测？
如何实现兼容文件拖放

通过第三方库，目前不予实现，因为此类常见与dnd组件并不强关联，并且一个应用只有少数地方会使用，单独实现即可

嵌套处理？
放置节点内部包含其他放置节点，应该仅顶部的生效，然后判断哪个dnd在另一个的上方？

选项1：通过 InheritedWidget 注册父子关系
选项2：通过 WidgetsBinding.instance.hitTestInView, 需要先测试下可行性

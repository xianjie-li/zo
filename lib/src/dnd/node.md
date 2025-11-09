## Manager

统一管理所有 dnd 的行为，减少 dnd 负责的工作

## DND

拖动项，应用中可以存在复数个 DND，通过 groupId 进行分组，同组别的可以互相拖放，并且只响应当前组的事件, 包含一个默认组
尽量将操作外放到 Manager 处理

- x DNDNotification
- x feedback
- x 光标变更
- x accept 触发时需要满足放置条件
- 嵌套 dnd & groupId测试
- DNDHandler: 作为拖动把手, 通过 Notification 发送事件
- DNDFeedback: 简化放置目标的反馈实现
- esc取消拖动
- 自动滚动
- 悬停打开事件


## 难点

如何检测可见？
即是否被遮挡、部分遮挡、由于滚动被遮挡，以及可见的部分

visibility_detector

自动滚动实现？
拖动并在一个滚动容器边缘移动时，如果自动进行滚动

通过 Scrollable.of(context) 查找父级 ScrollableState，可以检测滚动容器、控制位置等

文件放置检测？
如何实现兼容文件拖放

通过第三方库，目前不予实现，因为此类常见与dnd组件并不强关联，并且一个应用只有少数地方会使用，单独实现即可

嵌套处理？
放置节点内部包含其他放置节点，应该仅顶部的生效，然后判断哪个dnd在另一个的上方？

选项1：通过 InheritedWidget 注册父子关系
选项2：通过 WidgetsBinding.instance.hitTestInView, 需要先测试下可行性

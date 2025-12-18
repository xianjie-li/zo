## 笔记

分为级联菜单和树形菜单两种实现，两者的通用逻辑抽象到 ZoMenuEntry，它集成 ZoOverlayEntry 来实现层渲染，并提供了通用的事件、尺寸、渲染行为控制

ZoMenuEntry 中接入了 ZoOptionController 来管理树数据，方便子类使用

**ZoMenu**

级联菜单实现，传统的列表型菜单，每一级菜单都是一个 ZoMenu 实例，所以涉及父子通讯、关闭等操作也需要同时处理不同层，实现上会更难一些

键盘操作全局改为内部实现，不依赖层键盘操作，因为我们要更好的管理焦点等在不同层实例之间的移动

每个菜单实例都由一个 ZoOptionViewList 组件来渲染其列表

**ZoTreeMenu**

复杂逻辑都已在 ZoTree、ZoOptionController、ZoMenuEntry 中实现，该类主要是桥接作用，没有特别的东西

## 待办
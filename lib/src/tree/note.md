## 笔记

由于组件功能有一定复杂性，文件通过 mixin 拆为到多个文件按功能管理

- base.dart: 组件通用成员变量，通用的工具方法等
- drag_sort.dart: 拖拽排序功能
- shortcuts.dart: 快捷键功能, 目前通过单个 SingleActivator 手动绑定，后续会改为通用按键实现
- tree_actions.dart: 一些树操作，如跳转、聚效选项等，通常会暴露给用户侧使用
- tree.dart: 主类，通过事件、生命周期桥接各部分代码
- view: 各种渲染内容

核心功能点的实现方式：

- 树形数据和选项管理：通过 ZoOptionController 类，其父类ZoTreeDataController 后续计划用于 ZoTable
- 控制选中项：ZoOptionController.selector, 对应 ZoSelector 类
- 树形展开：ZoOptionController.expander, 对应 ZoSelector 类
- 拖拽实现：ZoDND
- 选项渲染：ZoTile
- 列表：使用 SliverVariedExtentList 组件

简易流程：通过 ZoOptionController 管理选项数据，组件主要作为视图层与其交互，获取渲染列表等，需要处理好两者间数据的同步，事件通知等


## 待办
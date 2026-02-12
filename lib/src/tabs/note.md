## 实现

该组件在实现时对标了 vscode 选项卡，所以复杂度高于常规的选项卡组件

新增
- ZoTabs - 主组件
- ZoTabsEntry - 单个tab项的配置对象

现有组件
- 单行tab：ListView
- 多行tab：Wrap
- tab项渲染/事件：ZoInteractiveBox
- 选中项管理：Selector
- 拖动实现：ZoDND
- 表单通用接口：ZoCustomFormWidget

## 待办
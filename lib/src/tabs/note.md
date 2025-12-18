## 笔记

- UI：
  - x 图标、文本、关闭图标（支持悬浮显示、始终显示）
  - x 高度、最小宽度
  - x 前置、后置额外内容，比如新增图标、配置按钮等、右侧固定面板
  - x 风格：capsule、flat
  - x 背景色
  - x 边框
  - x 尺寸
  - x 强化/弱化显示激活和非激活tab
  - x 固定tab：只显示图标
- x 活动tab及相关事件：作为表单事件提供
- x 控制：直接使用传入选项列表同步渲染
- x 事件
- x 换行显示： 只支持横向
- 拖动排序
  - 基于dnd组件，支持上下左右拆分、拖动到窗口
  - 支持拖动到其他 Tabs
  - 支持拖动到 TabsDropArea
  - 与 SplitView 联动，支持拖动到其不同方位拆分窗口，可暴露为单独一个 area 组件
- 暴露的api
  - jumpTo - 聚焦并跳转
  - close
  - closeRight
  - closeAll
  - closeOthers
  - pin / unpin
- 上下文菜单自定义
  - 关闭菜单：关闭、关闭其他、关闭右侧、关闭全部
  - 固定
  - 支持自定义额外菜单或移除现有菜单
  - 支持自定义的菜单触发方式
- x 纵向tab
- x 关闭确认
- 可滚动指示器
- 显示被截断的文本
- x 设置文本最大宽度

todo:
- x fixedTrailing
- x markers、buildMarker
- x buildText
- sortable / groupId
- x onActiveChanged / onFocusChanged
- onContextAction

## 实现

新增
- ZoTabs - 主组件
- ZoTabsEntry - 单个tab项的配置对象
- ZoTabsDropArea - 支持放置位置反馈的组件

现有组件
- 单行tab：ListView
- 多行tab：Wrap
- tab项渲染/事件：ZoInteractiveBox
- Selector: 选中项管理
- 拖动实现：ZoDND

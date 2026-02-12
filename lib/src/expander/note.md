## 实现

实现目标：能够像 blender 等软件中的折叠面板一样，在大量配置/表单子级的场景中使用并支持嵌套，且具有类似的交互。

UI风格：需要清洗的区分面板的不同区域，比如顶部、内容，并通过缩进和参考线来强化视觉识别度，以便用户在嵌套场景中更快的识别所属区域

嵌套识别：通过 _ExpansibleLinker 实现，它是一个 InheritedWidget

动画和挂载状态：使用 ZoTransitionBase，基本上开箱即用

头面板： ZoInteractiveBox + ZoTile

组操作：活动面板的实例会按组存储在一个全局 HashMap 中，进行组操作时获取组的活跃面板，然后进行对应操作

accordion: 面板展开时会发送广播，其他面板会检测子级的父级 element，如果和展开的面板一致则关闭自身

拖放？ 用户通过 ZoDND 自行嵌套实现，可结合 ZoTreeDataController 管理相关数据

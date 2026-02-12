## 设计

- 作为一个booleanInput，提供 CheckBox、Radio、Switch 需要的基础能力
- 支持value/onChanged
- 各种颜色选项和前后置文本定制
- ToggleGroup, 提供多选能力，支持单选、多选，自定义每一项的样式+选中样式，比如颜色、图片卡片
- indeterminate：checkbox支持，强制当前样式为不确定状态，不影响值

## 实现

- ZoToggle: 提供基础 boolean input 能力, 并支持渲染为不同开关控件, 和对应的定制样式
- ZoToggleGroup: 提供组选中能力, 通过 InheritedWidget 建立父子关系绑定
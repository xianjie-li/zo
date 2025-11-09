
tree控制器提供一个遍历工具

尺寸：使用父级允许的最大尺寸

API设计：
options
onOptionsMutation - 传入新选项、变更的节点和变更类型，参考react表格
- 新增的选项、相对位置：前、后、子级
- 移除的选项 values
- 移动的项：fromValues 、to, 父子级需要进行排除防止重复操作
- 最新的数据选项，不可更改的副本
selectionType
branchSelectable
implicitMultipleSelection 常规点击交互时表现得像单选，但是仍然可通过快捷键选中多个节点
onTapRow
onToggle
trailingBuilder - 动态配置右槽操作栏
leadingBuilder
togglerBuilder - 自定义展开按钮
toggleIcon - 自定义展开图标

expandAll
expands
enable 设置为false时不可选中节点，但仍然可进行查看

indicatorLine - 显示展开指示线
draggable - 是否可拖动排序，通过独立的拖动库实现

emptyNode

## 交互
参考vscode交互

点击： 聚焦 + 展开 + 选中

键盘：
ctrl + a 全选当前层级，每次按下会向外额外选中一层
上下：移动焦点，使用焦点系统预置行为
空格：选中当前节点，如果是多选，则切换选中状态，使用焦点系统预置行为
左右：展开、关闭， 一直按左键可以将焦点向上层移动
shift + 点击： 区域选中
ctrl + 点击：切换toggle

## 实例
暴露State并提供常用API
matchRegexp/String/filter?
expandAll()
collapseAll()
expandLevel()
isExpanded
toggle(option)
expand(option)
collapse(option)
selector
scrollController
remove(values)
add(options, value?, insertAfter?)
move(from 批量, to, insertAfter?)
初始化时处理 expandAll 、expandTopLevel (需要同步)、expands
controller 支持根据value获取索引 path

## 缩进处理

根据depth显示倍数缩进，叶子节点也需要预留展开图标位置来保证对齐

## 扩展组件
TreeSelect
State/SelectState添加of

- x 空处理
- x expand 自动展开父级
- x 滚动跳转到指定项，支持偏移
- x 聚焦指定项
- x 添加context事件
- x 自适应高度
- x 异步加载
- x 筛选
- x empty
- x 键盘交互
- x 固定当前展开项
- 拖动排序
- onOptionsMutation

x 包括固定区域高度的第一个完整可见节点，如果它有父节点，全部放到顶部显示
- x 进行 _updateOptionOffsetCache 后更新固定项
- x 点击和折叠时，跳转滚动位置到该选项, 点击选项不能进行折叠操作
- x jump防折叠遮挡
- x 设置是否启用、最大固定层级
- x 键盘上移后更新滚动选项，防止固定选项遮挡聚焦

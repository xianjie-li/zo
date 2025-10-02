
tree控制器提供一个遍历工具

尺寸：使用父级允许的最大尺寸

API设计：
options
onOptionsChanged - 传入新选项、变更的节点和变更类型，参考react表格
selectionType
branchSelectable
implicitMultipleSelection 常规点击交互时表现得像单选，但是仍然可通过快捷键选中多个节点
onTapRow
onToggle
rowBuilder - 自定义行
nodeBuilder - 传入未拼装的前中后节点
trailingBuilder - 动态配置右槽操作栏
leadingBuilder
togglerBuilder - 自定义展开按钮
toggleIcon - 自定义展开图标
toggleAnimation true

expandAll
expandLevel
expands
accordion - 手风琴模式，同级只会有一个节点被展开
enable 设置为false时不可选中节点，但仍然可进行查看
matchRegexp/String/filter?
indicatorLine - 显示展开指示线
rainbowIndicatorLine - 以不同颜色显示展开指示线
rainbowIndicatorColors - 自定义指示线颜色，颜色会在列表中循环

draggable - 是否可拖动排序，通过独立的拖动库实现

## 交互
参考vscode交互

点击： 聚焦 + 展开 + 选中

键盘：
ctrl + a 全选当前层级，每次按下会向外额外选中一层
上下：移动焦点
左右：展开、关闭
空格：选中当前节点，如果是多选，则切换选中状态
shift + 点击： 区域选中
ctrl + 点击：批量toggle

## 实例
暴露State并提供常用API
expandAll()
collapseAll()
expandLevel()
isExpanded
toggle(option)
expand(option)
collapse(option)
selector
controller
scrollController

## 扩展组件
TreeSelect
State/SelectState添加of
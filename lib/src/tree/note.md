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
- x 优化代码
- onOptionsMutation
  - move提醒：通过回调添加自定义移动提醒，如果未确认并触发了新的变更，中断操作，可配置行为：兄弟节点不提醒
- 拖动排序
- 尺寸定制：option.size改为非必传，字体缩小
- 层级缩进线
- 复盘代码，整理table实现中可能会复用的部分

x 包括固定区域高度的第一个完整可见节点，如果它有父节点，全部放到顶部显示
- x 进行 _updateOptionOffsetCache 后更新固定项
- x 点击和折叠时，跳转滚动位置到该选项, 点击选项不能进行折叠操作
- x jump防折叠遮挡
- x 设置是否启用、最大固定层级
- x 键盘上移后更新滚动选项，防止固定选项遮挡聚焦

## Mutation

把 ZoOption 更改为更通用的 ZoDataRow
option 结构优化

note:
- 不需要回退操作，应交给上层实现，因为组件内的回退是不健壮的，应由外部通过 add / remove 操作使用成熟的方案如 ot, crdt 等生成回退
- 移动、删除提醒
- api添加到controller
- 删除、移动时，需要将选项按顺序排序，若父级也被操作，只处理父级

### add(list[], toKey, insertAfter) 

描述：新增选项到指定位置，to选项后移

### remove(keys[]);

描述：移除给定的选项，返回移除的公共父级列表

注意事项：
合并公共父级：父节点的删除操作等效于子级，只需要取所有叶子节点的公共父级进行删除

### move(keys[], toKey, insertAfter)

描述：移动选项, 通过 remove + add 实现，但合并为一个变更

注意事项：
移动时，如果包含不同层级的节点，全部对其到同一级
toKey不能是被移动节点及其子级

### syncOperations(actions)

在其内部执行的变异操作不进行通知

### onMutation(operation)

  x 拖动过程中的异常 updateWidget 触发
  x 拖动过程中dnd和trigger被销毁
  x 重写dnd机制
  x 位置未实时更新
  x 添加左缩进边距指示线 + 中间放置状态 + 不可放置状态
  x 可拖动 + 可放置配置参数
  x 自动不可放置配置，拖动中节点及其子级均不可放置，开始拖动时根据选中项存储一个map，判断放置节点所有父级，如果有被选中的就禁用放置
  x 多选拖动时，子级状态更新不及时
  x 多选拖动时，更新feedback
  x esc 取消时，feedback会出现问题：dispose 重复调用时避免报错，直接忽略
  x esc 取消拖动不应该影响下方事件
  自动展开：不可放置节点不会展开
  批量拖动: 推动节点已选中，且选中总数大于2，feedback变为具体数字，批量拖动可禁用
  拖动统一触发一个方法
  触摸设备拖动: 是否需要更改trigger实现
  x drag太容易触发

  
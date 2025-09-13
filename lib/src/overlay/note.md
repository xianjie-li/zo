
## Overlay 浮层

子菜单交互行为:
- x a. active true 时打开子菜单
- x 触发 a 时, 关闭所有其他同级或更下级的子菜单
- ？ 点击任意菜单之外关闭所有菜单，点击 esc 关闭所有菜单
- x 点击时选中项

菜单实现:
- x 通过 ZoOptionBase > ZoOption 渲染 list
- x 菜单可限制最大高度, 默认与窗口等高
- x 支持级联
  - 父子菜单通过 child parent 关联
  - 每个层级只需创建一个overlay实例并复用
- x 支持异步级联
  - 复用管理子项异步加载的数据
- x 如果菜单方向被flip, 后续都以该方向显示
- x 每个子菜单单独设置尺寸

TODO:
- 选中标记，树形数据建模
- 点击esc关闭所有相关菜单
- 按键交互
- Select
- Tree
- 小屏兼容处理？

小屏兼容:
- 可选启用
- 小屏设备转为使用 tree 展示, 通过兼容组件实现, 或者改为非方向布局展示, 添加遮罩和路由, 调整为更大易于点击的样式
- 从左到右堆叠的选项卡片, 点击时置顶

上层组件:
- Menu:  核心, 通过 OverlayEntry 实现
- Select: 上层组件, 组合了 MenuEntry 和  Input, 支持多选 / 单选 / chip / 筛选等 

按键交互:
active状态, 此状态高亮并显示子菜单
- cmd + a 如果启用了多选, 进行全选 / 反选
- 上下健 + tap 使用内置的焦点移动逻辑
- 分支节点获得焦点时, 打开层
- 左右键移动焦点到相邻的层
  - 如果层未打开将其打开
  - 如果是移动到更小的层, 将其后的层关闭, 子菜单需要获取实时方向来判断顺序

ZoOption:
- x 通用的 ZoOption 类, 表示 select menu tree 等组件的选项,  支持 disabled  active  title  desc  leading trailing  children  divider builder 等, 这能更好的做到限制高度来实现滚动优化

杂项:
- x 异步加载选项: optionsLoader / optionsLoaderFinished
- x 所选选中/高亮等状态存储在顶层 overlay
- x 筛选
- x 预置工具条, 包括筛选框

性能优化:
- x 滚动中不触发子项展开
- x 快速移动时不触发子项展开

选择支持:
- x 选中回调通知: onSelected
- x 单选 / 多选支持
- x 选中后自动关闭: 单选且命中叶子节点时启用, 也可以强制开启
- x 叶子节点是否可选中 = false
- x ~~父子级关联选中~~ 这应该在逻辑上成立而不是视觉上, 子项选中就应视为父项也被选中, 反之亦然
- 包含被选中项的分支节点显示选中数量
- 标记包含选中子级项的父级: 通过某种缓存建立机制实现, 可快速根据一个项获取其所有父级?
  - 快速获取节点的父级 / 层级 / 索引 / 扁平化列表 / 节点本身的引用 / 前后一个节点 / 后代数量 / 是否是兄弟节点的第一个/最后一个
  - TreeHelper
  - 对整个树建模
  - 对有变更的节点及其子级建模? 可能比较难
  - 按需处理信息

需要的信息:
- 知道某一节点的值， 能快速获取其父子关系：只标记父级

list和menu中必要逻辑脱离抽离到option中实现，方便复用, menu中避免一切渲染无关逻辑

helper: 管理选中项，节点关联信息查询，选项数据管理，异步数据加载，筛选，entry中只负责渲染
选项变更时：递归一次计算
谁的子项是什么

tree：哪些能复用，哪些不能


参考
```ts
export interface TreeBaseNode<Node = TreeNode, DS = TreeDataSourceItem> {
  /** 该节点对应的值, 需要对value取值时优先使用此值 */
  value: TreeValueType;
  /** 该节点对应的label, 需要对label取值时优先使用此值 */
  label: string;
  /** 子项列表，此值代理至origin中获取到的children, 操作children时应首选此值 */
  children?: DS[];
  /** 当前层级 */
  zIndex: number;
  /** 所有父级节点 */
  parents?: Node[];
  /** 所有父级节点的value */
  parentsValues?: TreeValueType[];
  /** 所有兄弟节点(包含本身) */
  siblings: Node[];
  /** 所有兄弟节点的value */
  siblingsValues: TreeValueType[];
  /** 所有子孙节点 */
  descendants?: Node[];
  /** 所有子孙节点的value */
  descendantsValues?: TreeValueType[];
  /** 所有除树枝节点外的子孙节点 */
  descendantsWithoutTwig?: Node[];
  /** 所有除树枝节点外的子孙节点的value */
  descendantsWithoutTwigValues?: TreeValueType[];
  /** 从第一级到当前级的value */
  values: (string | number)[];
  /** 从第一级到当前级的索引 */
  indexes: number[];
  /** 以该项关联的所有选项的关键词拼接字符 */
  fullSearchKey: string;
  /** 该项子级的所有禁用项 */
  disabledChildren: Node[];
  /** 该项子级的所有禁用项的value */
  disabledChildrenValues: TreeValueType[];
  /** 未更改的原DataSource对象 */
  origin: DS;
  /** 子节点列表 */
  child?: Node[];
}
```
# ADR：可扩展组合根与共享 UI

- **状态**：Accepted。
- **日期**：2026-08-23。
- **适用版本**：v0.1.0 及后续模块。
- **决策所有者**：项目经理。

## 背景

Pocketools 首版包含塔罗、六爻、D20、硬币和扑克牌，后续仍会增加新的随机工具。若每个页面自行创建存储、随机源、分享服务和按钮样式，首版虽然可以运行，但新增模块会迫使应用壳层持续增加工具分支，全局视觉调整也会退化成逐页修改。

本决策把“可扩展”和“可复用”转换为代码边界及自动化门禁。它约束生产组合方式，不妨碍测试为单个模块注入轻量替身。

## 决策

### 应用只有一个组合根

`PocketoolsApp` 及其 composition root 负责创建应用生命周期内唯一的一组平台服务：安全随机源、共享会话仓库、会话 ID 源、设置仓库、分享服务和反馈服务。生产模块不得在构造器默认值或页面状态中创建这些服务。

依赖必须显式向下传递。允许 app-scoped 对象，不引入可被任意位置修改的全局 service locator。这样可以在测试中替换单项能力，也能避免多个工具各自拥有互不相通的历史。

会话 ID 的熵与工具结果随机消费分离。生成 ID 不得改变固定随机向量，也不得使用会与重启冲突的页面级递增计数器。

### 注册表是工具发现的唯一来源

`ToolRegistry` 是首页、工具目录、历史、分享、配置复用和预设管理发现模块能力的唯一入口。共享消费者只依赖 descriptor、codec 和声明式 capability，不解析工具私有 Map，也不根据 `toolId` 编写 `if` 或 `switch`。

新增普通模块的生产改动预算是：

- 新增 `lib/features/<tool>/` 下的领域、codec、页面和必要的专属 visual primitive。
- 在默认注册表增加一条模块声明。
- 新增模块自己的测试、需求映射和内容许可记录。

正常情况下不得修改应用导航、历史页、分享服务、设置页、会话仓库、随机核心或现有工具页面。若确需扩展公共能力，应先以工具无关接口扩展 core 或 design system，并提供至少两个模块或一个模块加 fake 模块的契约测试。

### 模块能力通过小接口组合

基础 `ToolModule` 只负责 descriptor、codec 和配置入口。可选能力使用独立的小接口声明，例如配置复用、专用分享渲染或内容说明；不把所有模块强迫进一个不断膨胀的基类。

历史中的“复用配置”通过工具无关的 replay capability 调用模块，由模块把已解码输入转换为自己的初始配置。共享历史页只负责选择会话和导航，不包含五个工具的构造分支。

模块上下文只暴露用例级能力，不暴露 `SharedPreferences`、浏览器 API 或 Android API。工具页面可以请求保存冻结会话、执行反馈或分享，但不能知道平台实现。

预设使用独立的 `ToolPresetProvider` 能力。provider 提供系统预设定义和 typed configuration codec；`ToolRegistry` 聚合 provider 并把任意系统或用户预设转换为统一 `ToolLaunchRequest`。预设管理页按 provider 和 descriptor 渲染，不含首发工具 ID 分支。

- 系统预设的 `PresetType.system`／`PresetSource.bundled` 记录是只读的。
- 用户副本使用新的稳定 ID、`PresetType.user`／`PresetSource.local` 和独立的不可变规则 map；系统升级只替换内置定义，不回写用户快照。
- provider 编码配置时必须排除问题、意图、备注、结果和会话标识；塔罗意图固定为空。
- 预设快照与 session 快照使用不同的 allowlist key 和原子 active／pending 写入。存储失败时只降级预设管理到内存，不阻塞工具执行或历史读取。
- v0.1 用户副本在冻结复制时固定当时的规则配置；预设管理页只负责重命名和删除，不提供保存当前工具草稿的入口。
- 工具页对本次草稿的调整不会回写预设；未来如需保存，应通过一个共享 save capability 接入，不能在三个工具页面复制实现。

### 会话是共享功能的事实来源

每次有效随机操作先生成不可变 outcome，再以统一 envelope 保存，最后让动画、反馈、历史和分享消费同一个 outcome。D20 与其他工具遵循完全相同的会话管线。

持久化仓库保存完成会话和必要草稿；历史默认只显示完成会话。私人备注和收藏是独立 annotation，不能改写结果。关闭历史保存后，新结果进入当前应用生命周期内的临时仓库，既有持久历史不被删除。

平台存储失败时，应用切换到临时会话并显示全局可理解提示；已成功生成的结果不因历史写入失败而被重新随机。安全随机源失败则阻止生成，不能降级到时间戳或普通伪随机。

### UI 由 token、主题和基础组件三级复用

公共 UI 的单点修改路径固定为：

```text
design tokens -> AppTheme / ToolTheme -> shared components -> feature composition
```

- 尺寸、间距、圆角、颜色语义和动效时长只在 tokens 定义。
- `AppButton` 统一实现主要、次要、危险、loading、disabled、focus、pressed 和减少动态状态。
- 表单、步进器、页面 scaffold、结果 surface、生成状态、会话操作区、空状态和确认对话框使用共享组件。
- 工具页面只组合共享组件，并提供领域文案、字段和专属 visual primitive。
- 专属 primitive 只承担塔罗牌面、爻线、骰子、硬币和扑克牌等不可通用的结果视觉，不重新定义公共按钮、卡片容器或导航。

因此，全局调整按钮高度、圆角、颜色或按压反馈时，只修改 token、主题映射或 `AppButton`；不逐个页面打补丁。

预设管理是设置下的次级界面，当前保留首页、历史、设置三项一级导航，工具入口归入首页。系统／用户状态、应用、复制、重命名和删除都使用 `AppToolScaffold`、`AppSectionCard` 与 `AppButton`；管理页不能为每个工具复制一套按钮或字段布局。

### 平台差异停留在适配器

Android 和 Web 共享领域规则、会话 schema、设置语义和页面组合。浏览器 vibration、系统分享、剪贴板和本地存储只能出现在 app/platform 适配器；不支持、未激活或不可见时安全 no-op 或回退，不渗透进 feature。

离线 PWA 的 service worker 和缓存策略属于 Web 包装层，不改变任何工具规则。缓存只包含同源发布产物，并通过版本化 cache name 清理 Pocketools 自己的旧缓存。

## 自动化门禁

架构测试必须持续证明：

- fake 模块只注册一次即可被首页、目录、历史摘要、分享和配置复用发现。
- 应用 shell、历史和分享源码中不存在首发五工具 ID 的条件分支。
- 生产模块不创建 `InMemorySessionRepository`、安全随机实现、平台反馈实现或页面级会话 ID 源。
- 五个模块从组合根获得同一个仓库与会话 ID 服务；D20 不再走旁路。
- feature 不导入 `lib/app/`、`shared_preferences`、`share_plus` 或浏览器绑定。
- 公共按钮和 surface 没有 feature-local 样式副本；改变一个共享 token 的测试值能影响至少两个工具和 fake 模块。
- 动画、减少动态、页面恢复和分享不会再次消费随机源。
- 新增 fake 模块的架构验收不要求修改 shell、历史页、分享页或设置页。
- 新增 fake preset provider 的架构验收不要求修改预设管理页；provider 通过 registry 聚合即可提供系统定义、应用和用户副本流程。
- D20 快速表达式使用纯 Dart 专用 parser 映射到既有 `DicePoolConfig`，不允许 eval、脚本、变量、函数、嵌套或爆骰语义。

静态扫描用于快速发现越层依赖，widget 与领域测试负责证明实际行为。两者都必须通过。

## 后果

正面结果是新增工具的影响范围可预测，历史、分享、设置和视觉风格自动继承；存储与平台能力可以独立替换和测试。代价是首版需要完成组合根和共享 capability 的基础设施，模块实现也必须遵守 codec 与会话协议，不能用页面内捷径绕过。

任何偏离本 ADR 的实现都需要项目经理书面记录原因、影响范围、迁移计划和对应测试；“只在这个页面先写一份”不构成例外理由。

## 相关文档

- [架构与扩展指南](../architecture.md)
- [本地平台服务](0001-local-platform-services.md)
- [离线 Web 打包](0002-offline-web-packaging.md)
- [需求文档](../requirements.md)
- [设计系统](../design/design-system.md)

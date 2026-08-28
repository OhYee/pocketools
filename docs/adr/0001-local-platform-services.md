# 本地持久化、分享与 Web 反馈适配

- **状态**：已接受并实现；Stage 2C 独立 QA 与最终系统门禁通过，平台边界见发布报告。
- **日期**：2026-08-23。
- **决策人**：项目经理。
- **关联需求**：FR-031～FR-044、FR-052、NFR-006、NFR-009、NFR-012、NFR-018、NFR-019、NFR-022～NFR-024、REL-004、REL-009、REL-013。

## 背景

Pocketools 的五个工具必须共享同一份本地历史、分享和设置能力。当前阶段实现仍允许工具模块自行创建 `InMemorySessionRepository`，因此不同模块的记录不能由公共历史页统一读取，浏览器刷新或 Android 进程结束后也会丢失。

平台能力同时存在差异：Android 可以提供系统触觉和分享面板；Web 的 vibration 与 Web Share API 取决于浏览器能力、页面可见性和用户激活，不能假定始终存在。

该决策只处理本地、离线优先的 v0.1.0。它不引入账号、远程同步、分析 SDK、服务端数据库或用户画像。

## 决策

### 应用根部拥有唯一仓库

`PocketoolsApp` composition root 创建唯一的会话仓库实例，并把同一实例注入默认 `ToolRegistry`、公共历史页和所有工具模块。

- 工具模块不得在生产注册路径中创建私有仓库。
- 测试仍可显式注入 `InMemorySessionRepository`、故障仓库或 commit gate。
- 首页、历史和分享只依赖 registry、`ToolSessionAdapter` 与公共仓库协议，不按工具 ID 编写分支。
- 新增工具只注册 module/codec/adapter，即自动获得公共历史摘要和默认脱敏分享。

### 使用版本化 JSON envelope

会话以稳定 JSON 字段持久化，顶层存储 schema 与工具会话 schema 分开版本化。读取时先校验顶层结构，再由 registry 定位对应 codec。

- 未知顶层版本或损坏条目进入隔离结果，不静默删除原始字符串。
- 单条写入先构造完整新快照，再替换活动键；写入失败保留旧快照。
- 完成结果、原始随机序列、规则版本和算法版本不可修改。
- 收藏、私人备注等可编辑信息使用独立 annotation，不回写 outcome。
- 时间只用于历史排序和用户主动分享，不参与规则或随机计算。

### 采用 `SharedPreferencesAsync`

v0.1.0 使用 `shared_preferences` 的新异步 API，而不是将被逐步淘汰的 legacy `SharedPreferences` API。

- Android 使用插件默认的 DataStore Preferences 后端。
- Web 使用 LocalStorage。
- 数据量保持有界，并提供按工具、单条和全部删除；不把它当作无限容量数据库。
- 本地历史属于可恢复的便利数据，不属于支付、身份或其他关键业务数据。设置页明确说明浏览器清理、无痕模式、操作系统回收和插件持久化限制。
- 存储不可用时允许当前结果以临时会话完成，并给出可理解提示；不得降级随机源或伪造“已保存”。

依赖版本以 `pubspec.lock` 为发布事实源。决策时官方发布页当前版本为 `shared_preferences 2.5.5`，支持 Android SDK 24+ 和 Web，并建议新项目使用 `SharedPreferencesAsync` 或 `SharedPreferencesWithCache`。

### 分享先预览，平台失败时复制

公共分享页先由 `ToolSessionAdapter` 生成结构化、默认脱敏的预览，再由平台服务执行。

- 默认仅包含工具名、规则摘要、结果、规则版本和算法版本。
- 问题、备注和时间均默认关闭，只有用户逐项开启后才进入最终文本。
- 本地 ID、父会话 ID、设备、日志与分析字段没有公开开关，始终禁止导出。
- 使用 `share_plus` 调用 Android 系统分享面板与 Web Share API；不可用、拒绝或失败时保留结果并提供 Flutter `Clipboard` 文本复制。
- v0.1.0 不生成或分享图片文件，避免额外缓存文件、图像许可和平台兼容问题。

决策时官方发布页当前版本为 `share_plus 13.3.0`，其 Flutter、Dart、Java、Gradle 与 Android Gradle Plugin 要求均由当前项目工具链满足。实际锁定版本和传递许可证仍须通过发布 SBOM 门禁。

### Web vibration 使用隔离适配器

平台无关 `FeedbackService` 保持不变。Web 实现放在条件导入的 app/platform 适配器中，使用 Dart 官方 `package:web` 浏览器绑定，不把浏览器 API 暴露给 feature。

只有以下条件同时满足时才尝试短振动：

- 用户设置已开启振动；
- `navigator.vibrate` 能力存在；
- 页面可见；
- 调用发生在当前用户激活允许的阶段。

任何不支持、拒绝或异常都静默 no-op，不能阻断保存、结果展示或无障碍播报。工具仍只调用 `FeedbackService.emit()`，不得导入 `package:web`。

## 被否决方案

### 每个工具保留独立仓库

该方案会复制存储、历史和迁移逻辑，公共历史页需要按工具分支，直接违反 NFR-022～NFR-024。

### 继续只使用进程内存

该方案适合测试和临时降级，不满足跨刷新、跨进程的本地历史与设置要求。

### 直接使用 `dart:html`

`dart:html` 不适合作为新的长期 Web 互操作边界，也不兼容 Flutter Web 的 Wasm 演进方向。Web 适配使用 `package:web`，并通过条件导入与非 Web 构建隔离。

### 首版引入云同步或数据库服务

该方案扩大隐私、账号、网络、迁移和运营范围，不属于离线优先 v0.1.0，也会让核心随机流程依赖远程服务。

## 结果与约束

正向结果：

- 五工具和未来模块共享一个可测试、可替换的存储与分享管线。
- Android 与 Web 继续使用同一结构化会话语义，平台差异被限制在 app/platform。
- 历史、分享和设置不要求 shell 了解具体工具。
- 关闭振动、减少动态、平台拒绝和存储失败都不会改变冻结结果。

代价与风险：

- `shared_preferences` 适用于有限的本地数据，不保证关键数据级持久性；UI 和发布说明必须如实披露。
- JSON 快照需要容量上限、损坏隔离和迁移测试。
- `share_plus` 与 `package:web` 增加运行时和传递依赖，必须更新 `docs/licensing.md`、NOTICE 和最终 SBOM。
- Web vibration 支持受浏览器策略影响，发布报告只能声明“能力满足时支持”，不能声明所有浏览器都有震动。

## 验证要求

- 两个工具保存结果后，公共历史页能在同一仓库中按时间倒序显示。
- 重新创建应用实例后仍能读取 Web/Android 本地会话和设置测试夹具。
- 未知 schema、部分损坏、写入失败和存储不可用不会删除仍可读取的旧数据。
- 收藏、备注和删除不会改写 outcome、规则版本或算法版本。
- fake module 不修改历史页或分享页即可显示摘要、详情和默认预览。
- 默认分享中不存在问题、备注、时间、本地 ID、父 ID 或设备字段；用户只可显式加入允许字段。
- Web 能力不存在、页面隐藏或无用户激活时不调用 vibration；Android 与 Web 异常均不影响结果。
- `make verify`、Web 构建与最终 Android 构建全部通过，依赖版本和许可证进入发布报告。

## 参考

- [Flutter key-value persistence cookbook](https://docs.flutter.dev/cookbook/persistence/key-value)
- [`shared_preferences` 官方发布页](https://pub.dev/packages/shared_preferences)
- [`share_plus` 官方发布页](https://pub.dev/packages/share_plus)
- [`package:web` 官方发布页](https://pub.dev/packages/web)

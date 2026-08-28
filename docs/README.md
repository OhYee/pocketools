# Pocketools 文档索引

- **文档状态**：v0.1.1+2 源码基线已收口；六个玩法工具、图鉴、可扩展架构、交互基线、实体动效、体感入口、实现、独立 QA、平台验收和发布裁决均已归档。多重占卜与图鉴作为当前增量单独记录。
- **更新日期**：2026-08-24。
- **阅读顺序**：先读产品设计和需求，再读项目计划；实现、测试和发布阶段按索引补充对应文档。

## 文档入口

| 文档 | 用途 | 状态 |
| :--- | :--- | :--- |
| [产品设计](product-design.md) | 产品定位、范围、规则、架构方向、隐私与风险基线 | 【已归档】 |
| [需求文档](requirements.md) | v0.1.0 的 52 条 FR、24 条 NFR、13 条 REL，共 89 条稳定需求 | 【已冻结】 |
| [项目计划](project-plan.md) | 角色边界、gpt-image-2 设计门禁、ToolModule/共享 UI/Makefile 交接、风险和 Definition of Done | 【首版已收口】 |
| [架构与扩展指南](architecture.md) | 依赖方向、工具接入、会话/随机/反馈边界、共享 UI 与可执行架构门禁 | 【已建立】 |
| [ADR：本地平台服务](adr/0001-local-platform-services.md) | 唯一仓库、版本化持久化、分享回退与 Web 反馈的技术决策 | 【已实现；最终边界见发布报告】 |
| [ADR：Web/PWA 离线打包](adr/0002-offline-web-packaging.md) | 自有 service worker、本地 Web 引擎、干净构建与缓存升级边界 | 【已实现；最终边界见发布报告】 |
| [许可边界](licensing.md) | 项目、第三方代码、内容和视觉资产的许可与归属规则 | 【已建立】 |
| [多重占卜设计与实现说明](multi-divination-design.md) | 塔罗／周易融合规则、A/B/C 牌组、交互、恢复、解释和验收边界 | 【已实现；本地验证】 |
| [平台与系统工具链验收](test-results-platform.md) | Homebrew Flutter、Makefile symlink、真实 Edge、离线 PWA、Android debug、universal release 和 split-per-ABI 构建证据 | 【本地通过；商店签名未通过】 |
| [Android 构建与设备适配](android-builds.md) | Universal、ABI 分包、设备覆盖边界、体积优化和型号适配原则 | 【已建立；真实设备矩阵待执行】 |
| [第一版交付报告](release-report.md) | 全部 89 条需求、构建产物、限制、回退和公共发布裁决 | 【本地交付通过；公共发布未通过】 |

## 阶段文档

以下状态以当前 89 条需求、G1 结论和分阶段测试报告为准：

- [交互设计](interaction-design.md)：已覆盖现有工具、扑克、解释、历史分享、平台反馈、恢复、响应式与无障碍状态；当前玩法级舞台以 `AppEntityStateView` 为准，`AppGenerationStateView` 仅作为内部状态提示，G1【PASS】。
- [多重占卜设计与实现说明](multi-divination-design.md)：定义六组 A/B/C 抽取、一次洗牌持久化、6/7/8/9 映射、A1～A6 标准解释和顶部实体交互；多重占卜专属测试 26/26 通过。
- [设计系统](design/design-system.md) 与 [design tokens](design/tokens.json)：是精确行为与数值基线，公共组件、语义 token、专属 primitive 和单点样式边界已冻结。
- [参考图视觉审计](design/reference-effect-audit.md)：记录用户参考图与运行时实现的差距、已落地的共享视觉增量和独立 QA 门禁。
- [设计稿索引](design/mockups/README.md)：十一张活动证据已 accepted；旧 built-in 稿只保留审计证据，不得作为实现依据。生成图均为 `runtimeAsset=false` 的内部参考。
- [测试计划](test-plan.md)：覆盖冻结需求及本轮交互增量；阶段测试报告按快照保留原始失败、修复与复测证据；当前全量门禁以 `make verify` 为准，参考图视觉 QA 为 22/22。
- [交互收口合同](interaction-closure-2026-08-24.md)：当前首页合并、共享牌堆、D20 aDb、实体命中区、动画和返回行为的权威实现合同；`RandomSource` 注入与冻结 `SessionRecord` 组成共享随机/会话协议，塔罗与扑克共用 `AppPhysicalDeck`/`AppDeckResultFlow` 并逐次追加一张，D20/硬币/六爻共用 `AppEntityStateView`/`AppPhysicalAction`，一级导航仅首页、历史、设置。【已验证】
- **实现状态**：六个玩法工具、塔罗牌与周易图鉴、统一随机与会话、持久化历史、预设、分享、设置、PWA 离线、共享设计系统和 Makefile 已接入。
- [发布报告](release-report.md)：记录最终需求状态、验证矩阵、产物校验、已知限制和不具备的外部发布条件。

## 文档约定

- 产品和项目文档统一放在 docs 目录；根目录 README 仅作为开源项目入口，并链接到本索引。
- 文档使用唯一一级标题，标题不编号，不使用独立水平分隔线。
- 需求 ID 使用 FR-后三位数字、NFR-后三位数字、REL-后三位数字；需求 ID 不因实现方式变化而复用。
- 事实、计划、风险和待确认事项分别标注，不把未执行的测试写成已验证结果。
- 设计稿、生成式图像和第三方资产必须附带来源、用途、版本和许可状态。
- 旧 built-in 图像生成稿全部【已否决】，不得作为实现依据。
- 图像稿表达视觉与静态分镜，交互文档和设计 tokens 才是精确行为与数值基线。
- 对应模块开发前必须满足 project-plan.md 的设计和需求门禁；已通过 G1 不替代代码、许可或发布测试。

## 变更入口

需求范围、规则默认值、隐私默认值和发布范围由项目经理维护。贡献者应先阅读 [CONTRIBUTING.md](../CONTRIBUTING.md)，并在变更说明中引用受影响的需求 ID。

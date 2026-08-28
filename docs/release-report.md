# Pocketools v0.1.0 第一版交付报告

- **版本**：0.1.0+1。
- **日期**：2026-08-23。
- **交付结论**：【本地源码与本地构建产物候选通过；公共发布门禁未通过】。
- **需求基线**：52 条 FR、24 条 NFR、13 条 REL，共 89 条稳定需求。
- **工具链**：Homebrew Flutter 3.47.1 stable、Dart 3.13.1、JDK 17。
- **源码身份**：当前目录没有 Git 元数据，无法绑定 branch、commit SHA 或 dirty 状态；使用测试报告、文件集合哈希和产物 SHA-256 作为本地证据。

## 交付摘要

首版已提供 Android 与 Web/PWA 共用的五个离线优先随机工具：

- 塔罗：78 张完整牌组、今日一牌、单牌问答、过去／现在／未来三牌阵、逆位、无放回抽取、逐牌解释和组合提示。
- 六爻：三枚硬币自动起卦、手工录入、撤销未完成爻、6/7/8/9 固定映射、本卦／动爻／变卦追溯和 64 卦基础解释。
- D20／骰池：普通、优势、劣势，1～20 枚骰子、2～1000 面、sum／keepHighest／keepLowest、modifier、DC 和安全表达式子集。
- 硬币：单次、1～100 次批量、自定义正反面标签和率先达到 N 次。
- 扑克：标准 52 张或加入大小王的 54 张牌组，抽取 n 张、无放回、顺序和剩余牌数可追溯。

统一能力包括安全随机源、会话冻结、幂等恢复、本地历史、收藏／筛选／删除、系统与用户预设、脱敏分享预览、设置、动效／触觉降级、PWA 离线和内容许可入口。工具通过 `ToolModule`、共享会话、随机、历史、分享和 design system 扩展，没有为五个页面复制独立 shell。

项目经理、交互设计、开发和独立 QA 的阶段门禁、失败—修复—复测链与最终裁决已记录在本报告及对应阶段文档中。

## 需求最终状态

状态含义：

- 【通过】：冻结范围内已有实现与自动化或人工证据。
- 【条件通过】：生产契约和本地证据通过，但指定平台运行证据仍缺失；不阻塞本地源码交付，阻塞公共发布宣称。
- 【部分完成】：需求的一部分已交付，剩余部分必须在公共发布前完成。
- 【延期】：P1 已书面延期，不把目标描述为已达到。

### 功能需求

52 条 FR 在冻结 v0.1.0 产品范围内全部通过。

| 需求 ID | 状态 | 实现与证据 |
| :--- | :--- | :--- |
| FR-001～FR-005 | 【通过】 | [应用组合与 shell](../lib/app/app_composition.dart)、[统一会话动作](../lib/core/tools/session_actions.dart)、[Stage 2C QA](test-results-stage2c.md)；真实浏览器覆盖五工具入口、结果、历史和分享 |
| FR-006～FR-012、FR-050 | 【通过】 | [塔罗功能](../lib/features/tarot)、[塔罗阶段 QA](test-results-stage2b2.md)、[内容发布 QA](test-results-content-release.md)；78 张、单／三牌、逆位、解释和克制文案均有测试 |
| FR-013～FR-019、FR-051 | 【通过】 | [六爻功能](../lib/features/liuyao)、[六爻阶段 QA](test-results-stage2b3.md)、[内容发布 QA](test-results-content-release.md)；自动／手工、撤销、本卦／变卦、64 卦解释均有测试 |
| FR-020～FR-026、FR-047 | 【通过】 | [骰池功能](../lib/features/dice)、[表达式与预设最终 QA](test-results-presets-expression.md)；1～20、2～1000、三种聚合、K、modifier、DC 和解析失败原子性均通过 |
| FR-027～FR-030 | 【通过】 | [硬币功能](../lib/features/coin)、[Stage 2B1 QA](test-results-stage2b1.md)；单次、批量、自定义标签和竞速模式通过 |
| FR-031～FR-039 | 【通过】 | [持久化会话](../lib/core/session)、[历史页面](../lib/app/presentation/history_page.dart)、[分享服务](../lib/app/platform/platform_share_service.dart)、[Stage 2C QA](test-results-stage2c.md)；FR-039 使用系统分享或文本复制回退，不宣称已实现图片分享卡生成 |
| FR-040～FR-046、FR-052 | 【通过】 | [设置与平台反馈](../lib/app/platform)、[共享生成状态](../lib/design_system/components/app_generation_state_view.dart)、[Stage 2C QA](test-results-stage2c.md)；真实 Web 离线和降级路径见[平台验收](test-results-platform.md) |
| FR-048～FR-049 | 【通过】 | [扑克功能](../lib/features/cards)、[Stage 2A QA](test-results-stage2a.md)；52/54、n 张、无放回、顺序、历史和分享语义通过 |

### 非功能需求

| 需求 ID | 状态 | 实现与证据 |
| :--- | :--- | :--- |
| NFR-001～NFR-004 | 【通过】 | [统一随机核心](../lib/core/random)、各工具固定向量和规则测试；Android 与 Web 编译消费同一 Dart 领域实现 |
| NFR-005 | 【延期】 | 没有冻结的 Android／浏览器设备性能矩阵，因此不宣称随机计算 P95 小于 100 ms；规则计算无网络和动画依赖，但这不替代测量 |
| NFR-006～NFR-012 | 【通过】 | 恢复、360 px／200% 字体、离线、本地隐私、专用解析器和 schema／quarantine 均有自动化；360/1024 真实浏览器证据见[平台验收](test-results-platform.md) |
| NFR-013 | 【部分完成】 | 牌、卦、工具和规则使用稳定 ID，v0.1.0 首发语言冻结为 zh-Hans；界面字符串尚未全面资源键化，英文未同期交付 |
| NFR-014～NFR-017 | 【通过】 | 无远程分析管线；内容 metadata 与构建合同、层级依赖、正常／边界／异常／恢复／无障碍测试均通过 |
| NFR-018 | 【条件通过】 | Android／Web 反馈适配、能力检测、关闭振动和阶段顺序有测试；没有 Android 实体设备或模拟器上的实际 haptics 证据 |
| NFR-019 | 【通过】 | 动画与反馈在结果持久化之后触发，减少动态、隐藏／恢复和键盘／语义路径有测试与浏览器证据 |
| NFR-020 | 【条件通过】 | 扑克统一牌 ID、固定向量、52/54、无放回和 Web 离线通过，Android debug APK 构建通过；缺少 Android 设备运行同一流程的证据 |
| NFR-021～NFR-024 | 【通过】 | 扑克使用抽象标准花色；`ToolModule` fake 模块、统一会话／历史／分享和共享 `AppButton`／tokens 架构门禁通过 |

非功能需求汇总为 20 条通过、2 条条件通过、1 条部分完成、1 条延期。

### 发布与治理需求

| 需求 ID | 状态 | 实现与证据 |
| :--- | :--- | :--- |
| REL-001～REL-002 | 【通过】 | 产品、需求、计划、交互、设计系统和 gpt-image-2 生成记录均在 docs；G1 十一张活动稿 accepted，运行时资产仍为 `runtimeAsset=false` |
| REL-003 | 【通过】 | 本报告逐组列出全部 89 个 ID，并链接实现、阶段 QA、平台报告和产物证据 |
| REL-004 | 【通过】 | 根 README 可访问 Apache-2.0 LICENSE、NOTICE、CONTRIBUTING、CODE_OF_CONDUCT、SECURITY 和[许可清单](licensing.md) |
| REL-005 | 【条件通过】 | 规则、固定向量、统计、离线、恢复、隐私、自动化无障碍与 Web 兼容证据通过；Android 设备运行和更广浏览器矩阵仍缺失，阻塞公共发布宣称 |
| REL-006 | 【通过】 | 当前支持范围冻结为 Android API 24+ 的 debug 构建合同，以及 Edge 151 的实际 Web/PWA 验收；Chrome 151 仅工具发现。首版没有冻结任何公共商店或托管渠道 |
| REL-007 | 【部分完成】 | 版本、算法、规则、内容包和产物哈希可追溯；由于没有 Git 元数据，无法反查 commit SHA，阻塞不可变源码发布身份 |
| REL-008 | 【通过】 | 构建命令、debug 签名归属、产物校验、无公共分发和回退边界均已记录；没有把 debug 签名描述为 release 签名 |
| REL-009 | 【部分完成】 | Web 刷新、离线缓存、旧 session schema 与 quarantine 有证据；Android 灰度、真实升级和版本回退未执行 |
| REL-010～REL-013 | 【通过】 | 本报告、Makefile、本轮 G1 扩展稿、模块扩展与共享架构门禁均完成 |

发布治理需求汇总为 10 条通过、1 条条件通过、2 条部分完成。

## 测试与缺陷结论

### 自动化

- 独立 QA 最终快照：402/402 PASS、0 FAIL、0 skip；31/31 Web precache 通过。
- 安装系统 Flutter 后增加 Homebrew symlink Makefile 回归测试，最终系统门禁：403/403 PASS、0 FAIL、0 skip。
- `check-format`：192 文件、0 改动。
- `flutter analyze`：0 issue。
- Web production build：40 文件、41M；有序集合 SHA-256 `36c9cb4b3004ded9294f0b7e5cfa46e6aa289e99b3809db53309a518e35fbb08`。
- `main.dart.js` SHA-256：`f868ddcad91fee8147afc1bf3bd6fd84ce7c52cbcedb787fef9da7829a7e67f0`。

### 已关闭缺陷

- 分享预览扩展模块可注入私有 ID：中央 allowlist 修复并由独立 QA 复测关闭。
- QA-PRE-001～QA-PRE-004：敏感预设字段、拼接别名、provider decode、损坏／未知快照保留均已关闭，完整失败—修复—复测链见[预设与表达式 QA](test-results-presets-expression.md)。
- 360 px Web 被渲染为 720 px：增加 viewport 声明和回归测试，真实 360／1024 浏览器复测关闭。
- Homebrew symlink 无法发现 Dart：TDD 增加伪造 symlink 契约，红灯 4/1、修复后 5/5，最终系统 `make verify` 通过。

当前没有未关闭的 P0/P1 产品逻辑缺陷。未完成项是平台、追溯和发布证据，不能被表述为生产缺陷已覆盖。

## 构建产物

构建产物只保留在本地验收目录 `output/`，该目录不随源码提交；需要复现时执行根目录 Makefile 中对应的构建命令。

| 产物 | 大小 | SHA-256 | 用途 |
| :--- | ---: | :--- | :--- |
| `output/builds/v0.1.0/pocketools-v0.1.0-web.tar.gz` | 14M | `dbfdd3adccffa20d9a60d7b9fdba8969dbac015d11a881047503e5ee1ca4c620` | 本地静态托管与离线验收 |
| `output/builds/v0.1.0/pocketools-v0.1.0-debug.apk` | 182M | `689dd1cff5f9af74a874b39e8891b26396944a5e4353d94f1a98a8c63bf44e4f` | 本地 Android 安装验收，非商店包 |
| `output/builds/v0.1.0/SHA256SUMS` | 构建后生成 | 见本地文件 | 交付物完整性校验 |
| `output/builds/v0.1.0/SOURCE-SHA256SUMS` | 文档收口后生成 | 见本地文件 | 无 Git 时的源码文件集合身份 |

Android APK 元数据：

- applicationId：`dev.pocketools.pocketools`。
- versionName／versionCode：`0.1.0`／`1`。
- minSdk：24；targetSdk／compileSdk：36／36。
- 签名：Android Debug，APK Signature Scheme v2 验证通过；不是 release signing。

## 设计与内容资产

- 交互基线：[交互设计](interaction-design.md)、[设计系统](design/design-system.md)、[tokens](design/tokens.json)。
- 图像生成记录：[gpt-image-2 generation](design/gpt-image-2-generation.md)、[设计稿索引](design/mockups/README.md)、[设计稿验收](design/mockup-review.md)。
- 十一张活动图像证据全部 accepted，但只作设计评审，均为 `runtimeAsset=false`，未打入应用运行时。
- 平台没有暴露底层精确模型版本或原生 4K 生成元数据；4K 文件是确定性评审副本，不宣称为原生 4K 输出。
- 塔罗和六爻内容 metadata 已按 ADR 0004 冻结为项目原创／整理内容，license `Apache-2.0`，状态 `approved for v0.1.0 project release`。
- 已提供 NOTICE 和依赖归属清单；没有生成 CycloneDX／SPDX 标准 SBOM。

## 兼容与发布边界

| 范围 | 当前可声明 | 不可声明 |
| :--- | :--- | :--- |
| Web | Edge 151 的五工具、历史、分享、预设、360／1024 和已安装 PWA 离线恢复通过 | Chrome／Firefox／Safari 全矩阵、首次断网安装、长期缓存升级全部通过 |
| Android | API 24+ 构建合同；debug APK 在 compile/target 36 下成功生成并通过签名校验 | 实体设备／模拟器运行、真实振动、升级、回退、release 签名、商店审核通过 |
| CI | GitHub workflow YAML 和 Makefile 契约存在 | hosted CI 已运行或存在 run ID |
| 源码 | 当前工作区可构建，文件集合可哈希 | 已绑定 branch／commit SHA、已提交或已推送 |
| 安全报告 | SECURITY 记录安全问题处理原则和报告信息要求 | 源码不声明具体运营渠道 |

## 回退与恢复

### Web

- 未执行公共部署，因此没有线上流量或 CDN 可回退。
- 本地托管时保留上一版完整目录；新包异常时切回上一目录，而不是修改当前包内文件。
- service worker 只清理 `pocketools-` 前缀且只删除非当前版本缓存，不触碰其他站点缓存。
- 会话与预设使用版本化 schema；未知版本保留原始数据或 quarantine，不静默重算旧结果。

### Android

- 当前只有 debug APK，没有灰度发布或商店版本。
- 保留上一 debug APK 和本地数据备份；Android 降级安装、应用数据兼容和卸载恢复没有设备证据，不提供“可安全降级”的承诺。
- 公共发布前必须建立 release keystore 责任人、签名备份、versionCode 策略、升级／回退设备用例和数据恢复说明。

## 已知限制与下一门禁

- 建立 Git 仓库和不可变 commit SHA，并让产物、报告、源码清单绑定同一提交。
- 在 Android API 24、目标常见版本和最新版本的模拟器／实体机完成安装、五工具、haptics、后台恢复、升级和回退。
- 建立 Chrome、Firefox、Safari、Edge 浏览器矩阵及首次离线／升级缓存验证。
- 建立随机计算 P95 设备矩阵，关闭 NFR-005。
- 将界面文案迁移到资源键并明确英文计划，关闭 NFR-013。
- 建立 hosted CI run、release signing 和发布流程。
- 生成标准 SBOM，并在每次依赖升级后复核 NOTICE 与许可。
- 用户预设当前支持复制、重命名、删除和应用；工具页草稿不会回写为新的持久化规则版本。

## 项目经理裁决

Pocketools v0.1.0 的产品设计、交互稿、共享架构、五工具实现、自动化、真实 Web/PWA 验收、系统 Flutter 构建和 Android debug 构建已经形成完整第一版交付物。允许将当前目录和本地构建包作为首版开发交付候选交接。

由于缺少 Git 提交身份、Android 设备运行、完整浏览器矩阵、hosted CI、release 签名和真实升级／回退证据，G3 公共发布门禁保持【未通过】。任何文档、README 或后续沟通都不得把本结论扩大为“已上架”“已公开发布”“所有 Android/Web 平台均验证通过”。

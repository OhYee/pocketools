# Pocketools v0.1.0 预设与表达式独立 QA 结果

- **执行日期**：2026-08-23。
- **执行角色**：独立 QA；开发报告的 375/375 与 31 项 precache 只作为背景，不替代本轮证据。
- **验收范围**：FR-026、FR-036、FR-042、NFR-011、NFR-012、NFR-022～NFR-024、REL-003、REL-011、REL-013，以及 preset/expression 生产实现和 `.github` YAML 配置。
- **写入边界**：只新增独立 QA 测试与本文档；未修改 `lib/**`、开发测试、架构/需求文档、`.github/**` 或既有报告。
- **最终结论**：【FAIL；fake preset provider 可绕过私人字段排除边界，命中 P1 发布阻断】。

## TL;DR

- 最小 fake extension 攻击把 `sessionId`、`parentSessionId` 和 `privateNote` 放入系统预设 configuration；期望 registry fail-closed，实际成功构造 `ToolRegistry`。【失败】
- 缺陷要求一个错误或恶意模块 provider 才能触发，当前没有证明五个内置模块正在泄漏，也没有证明数据已离开本机；但私人字段可进入系统预设并在复制时原样进入用户快照，违反统一扩展与预设隐私合同。【P1】
- 按任务停止条件，QA 在首次 P1 后没有继续补 expression/persistence/widget 对抗测试，也没有运行本轮完整 `make verify` 或生成新的 Web 哈希。【未执行】
- `.github` 下 5 个 YAML 文件均由 Ruby YAML parser 成功解析；CI workflow 的两个 `run:` 步骤仅调用 `make bootstrap` 和 `make verify`，并声明只读 contents 权限、并发取消、30 分钟超时、Java 17 和 Flutter 3.47.1。【静态已验证】
- 配置存在与本地解析成功不等于 GitHub hosted CI 已运行或通过；本轮没有远端 job、run ID、commit SHA 或 hosted 日志证据。【未验证】

## 开发自测与独立 QA 边界

- 开发报告 375/375、Web build 与 31 项 precache 通过，本文只将其记录为测试前背景。【背景】
- QA 没有先运行开发测试来复述绿色结论，而是优先攻击公开 `ToolPresetProvider` 的私人字段边界。【已执行】
- 最小攻击测试为 0 PASS、1 FAIL、0 skip，失败发生在 registry 构造边界。【失败】
- 发现 P1 后，QA 依照任务要求停止扩展测试和全量门禁；因此不能把开发计数写成本轮独立计数。【边界】

## 缺陷 QA-PRE-001

### fake provider 可把私人字段注册为预设规则配置

- **严重度**：P1 / High；发布阻断。
- **状态**：【失败；等待开发修复】。
- **关联需求**：FR-036、NFR-011、NFR-022、REL-003、REL-013。
- **最小复现文件**：`test/architecture/preset_private_field_boundary_qa_test.dart`。
- **最小复现命令**：`flutter test test/architecture/preset_private_field_boundary_qa_test.dart`。
- **实际退出码**：1。
- **测试计数**：0 PASS、1 FAIL、0 skip。

复现步骤如下：

1. 声明一个只依赖公开协议的 fake `ToolModule` 与 `ToolPresetProvider`。
2. provider 返回一个类型为 system、来源为 bundled、基础 metadata 合法的系统预设。
3. configuration 同时声明普通规则字段和 `sessionId`、`parentSessionId`、`privateNote`。
4. fake decoder 接受该 configuration，然后构造 `ToolRegistry`。

预期与实际结果：

| 项目 | 结果 |
| :--- | :--- |
| 预期 | registry 在注册阶段抛出 `ArgumentError`，私人提示、备注、结果或会话标识不能成为预设规则字段 |
| 实际 | `ToolRegistry` 正常返回；测试报告 `Expected throws ArgumentError`，实际为 `returned ToolRegistry` |
| 直接影响 | 错误或恶意模块可把私人字段放入系统预设；`copyAsUser()` 会深冻结但原样复制 configuration，随后用户快照可持久保存这些字段 |
| 已确认未扩大范围 | 本轮没有发现五个内置 provider 已包含上述字段，也没有证明分享、网络或日志外传 |

### 根因定位

- `ToolPreset` 文档明确禁止 private prompts、notes、results 和 session identifiers，但 `validate()` 只校验 metadata、system/user 来源关系和 configuration 非空，没有共享私人字段 policy。【已核对】
- `ToolRegistry` 对系统预设调用 `preset.validate()` 后，只要求 provider 自己能够 decode；恶意或错误 provider 可以接受自己的污染字段。【已核对】
- `PresetController.copyAsUser()` 调用 `source.asUserCopy()`；该方法复制整个不可变 configuration，不会剔除私人字段。【已核对】
- 当前边界把“不得包含私人字段”留成 provider 约定，没有形成 NFR-011/NFR-022 所需的中央 fail-closed 门禁。【根因】

### 修复验收条件

- 共享 preset 边界必须拒绝私人提示、备注、结果、session/parent/device/analytics 标识及其常见命名变体，不能只给三个内置 provider 打补丁。
- registry 注册系统预设、加载用户预设、复制用户副本和 provider encode 输出应复用同一 policy。
- 原最小测试必须保持不变并从 0/1 变为 1/1；另需证明合法 fake provider、三个内置 provider 和旧合法用户快照不回归。
- 修复后再继续本轮尚未执行的 expression、snapshot、widget、完整 `make verify` 与 Web 哈希验收。

## 预设修改边界

v0.1 的冻结边界已在 ADR 0003 和 architecture 文档中明确：

- 系统预设是只读 bundled 记录。
- “保存为用户副本”生成新 ID、user/local 类型和复制时冻结的独立规则 map。
- 管理页只提供应用、复制、重命名和删除，不提供保存当前工具草稿的入口。
- 工具页后续对本次草稿的调整不会回写系统预设或用户副本。

该实现边界与冻结架构说明一致，因此“工具页草稿不回写”本身不判为缺陷；但当前版本不能宣称支持编辑并保存用户预设配置，只能宣称冻结复制、重命名和删除。【静态边界已核对；行为对抗测试因 P1 停止而未完成】

## 表达式与存储覆盖边界

- 已读取 `DiceExpressionParser`、D20 页面与统一会话路径；parser 使用长度上限、专用正则和有界整数解析，没有 eval 或脚本执行入口。【静态已核对】
- 超长整数、Unicode/空白/控制字符、modifier 溢出、kh/kl 歧义、解析失败零随机、成功后控件/模式/session 一致性尚未由本轮独立测试执行。【未执行】
- system/user 来源、复制/重命名/删除、历史独立、malformed provider、unknown/corrupt/pending snapshot、存储 fallback、系统升级 ID collision、codec validation、四项导航和共享 `AppButton` 尚未完成本轮全套对抗执行。【未完成】
- 尤其不能把开发测试或静态阅读替代 unknown/corrupt 原始快照保留、pending 两阶段恢复和写入失败行为证据。【未验证】

## 开源与 CI 配置静态检查

| 检查项 | 独立证据 | 状态 |
| :--- | :--- | :--- |
| YAML 语法 | Ruby `YAML.load_file` 解析 `.github` 下 5 个 `yml/yaml` 文件 | 【通过】 |
| Makefile 单一入口 | workflow 的 `run:` 值仅为 `make bootstrap`、`make verify` | 【通过】 |
| 最小权限 | 顶层 `permissions: contents: read` | 【通过】 |
| 并发 | workflow/ref 分组，`cancel-in-progress: true` | 【通过】 |
| 超时 | verify job 为 30 分钟 | 【通过】 |
| 固定工具链 | Java 17、Flutter 3.47.1 stable | 【通过】 |
| hosted CI | 未访问或执行 GitHub Actions，没有远端 run 证据 | 【未验证】 |

Actions 使用 `actions/checkout@v4`、`actions/setup-java@v4`、`actions/cache@v4` 和 `subosito/flutter-action@v2` 的版本化主版本标签，不是不可变 commit SHA。本轮需求只验证固定 Java/Flutter 工具链与 Makefile 入口；该事实不被写成 supply-chain 完整签名或 hosted CI 通过证明。【边界】

## 命令执行结果

| 命令 | 退出码 | 实际结果 | 状态 |
| :--- | :----: | :--- | :--- |
| `dart format test/architecture/preset_private_field_boundary_qa_test.dart` | 0 | 1 个 QA 文件无需格式改动 | 【通过】 |
| `flutter test test/architecture/preset_private_field_boundary_qa_test.dart` | 1 | 0 PASS、1 FAIL、0 skip；registry 接受私人字段 | 【失败】 |
| `ruby -ryaml -e '… YAML.load_file …'` | 0 | `.github` 下 5 个 YAML 文件全部可解析 | 【通过】 |
| `awk` 校验 workflow `run:` 值 | 0 | 仅 `make bootstrap` 与 `make verify` | 【通过】 |
| `FLUTTER_BIN=flutter make verify` | 未执行 | 命中 P1 后按停止条件未运行 | 【阻塞】 |
| Web 产物 SHA-256 | 未生成 | 没有本轮完整门禁产物，不复用既有报告哈希 | 【未执行】 |

一次过宽的负向正则曾把合法 `make` 行误判；QA 随后改用逐行提取 `run:` 值的 `awk` 校验并退出 0。该检查命令问题不计生产缺陷，也不改变 preset P1 结论。

## 需求覆盖结论

| 需求 | 本轮状态 | 证据与边界 |
| :--- | :--- | :--- |
| FR-026 | 【未完成】 | 已静态审查专用 parser 和页面映射；对抗输入与统一 session 动态证据因 P1 停止 |
| FR-036 | 【失败】 | 冻结副本产品边界清楚，但 fake provider 私人字段可被复制进 user/local snapshot |
| FR-042 | 【未完成】 | 预设代码无网络依赖的静态事实已见；真实断网复用未执行 |
| NFR-011 | 【失败】 | 共享 preset configuration 没有私人字段白名单/fail-closed policy |
| NFR-012 | 【未完成】 | schema、unknown/corrupt/pending 与原始数据保留尚未完成独立攻击 |
| NFR-022 | 【失败】 | fake provider 可仅凭自身宽松 decoder 绕过共享预设合同 |
| NFR-023 | 【部分静态核对】 | 预设应用进入统一 `ToolLaunchRequest`；完整会话一致性未执行 |
| NFR-024 | 【部分静态核对】 | 管理页使用共享 scaffold、surface、`AppButton`；widget 对抗未执行 |
| REL-003 | 【通过】 | 本报告提供需求、复现、实现根因和发布结论反查 |
| REL-011 | 【阻塞】 | workflow 只调用 Makefile 已静态验证；本轮完整本地门禁因 P1 未运行 |
| REL-013 | 【失败】 | fake provider 扩展门禁未能阻止私人配置字段 |

## 审计链与最终结论

- 开发自测：375/375 与 31 precache，仅作为背景。【未独立采用】
- QA 最小攻击：新增 1 项 fake provider 私人字段测试，0 PASS、1 FAIL。【失败】
- QA 根因确认：模型只写明约定，registry 信任 provider decoder，复制路径原样保留 configuration。【已核对】
- 开源配置：5 个 YAML 可解析，workflow 命令只经过 Makefile；没有 hosted CI 运行证据。【静态通过；远端未验证】
- 修复与复测：尚未发生。【等待开发】
- 全量门禁与 Web 哈希：按 P1 停止条件未执行。【阻塞】

本轮预设与表达式独立 QA 当前为 **FAIL**。主 PM 应将 `QA-PRE-001` 退回开发，要求共享层最小修复；在原失败测试、剩余定向矩阵和完整 `make verify` 全部取得独立退出码 0 前，不准入发布。

## 修复后独立复测

- **复测日期**：2026-08-23。
- **复测环境**：Flutter 3.47.1 stable、framework revision `6655482ec0`、Dart 3.13.1、macOS arm64。
- **原始用例保护**：未修改 `test/architecture/preset_private_field_boundary_qa_test.dart`；复测快照 SHA-256 为 `3956660cc1374bf20f57f5b26a11b08a51a30b813ba76c3759d5536cc956d5e3`。
- **本次结论**：【FAIL；QA-PRE-001 已关闭，但扩展攻击发现 3 类新的 P1 发布阻断，完整门禁退出 2】。

### QA-PRE-001 修复复测

只读审查确认中央 `ToolPresetConfigurationPolicy` 已接入 registry 系统预设注册和 launch、controller 用户预设加载与复制来源检查、repository 直接保存，不是五个内置模块的局部补丁。保持原攻击用例不变后，精确复测由首次 0/1 FAIL 变为 1/1 PASS、0 skip。【修复后通过】

这只关闭原用例声明的 camelCase、分隔符和常见敏感命名攻击，不抹去本报告前文首次 FAIL 的历史，也不自动证明全部命名变体、provider codec 和损坏快照边界安全。

### 补充对抗测试

本次新增并执行以下独立 QA 测试，不修改开发测试或生产实现：

- `test/features/dice/dice_expression_adversarial_qa_test.dart`：接受语法与结构化模式映射、超长整数、Unicode 数字和空白、控制与双向字符、`kh`/`kl` 歧义及 modifier 溢出。
- `test/widget/dice_expression_session_qa_test.dart`：解析失败零随机、零 session ID、零保存、零反馈；解析成功映射控件并只保存一个冻结会话；工具页草稿调整不回写冻结用户预设。
- `test/core/presets/preset_adversarial_qa_test.dart`：名称 Unicode scalar 边界、敏感字段别名、malformed provider、corrupt/unknown/pending snapshot、写失败 fallback、D20 codec 和冻结副本生命周期。

新增定向集共 15 项，11 PASS、4 FAIL、0 skip。表达式相关 5/5 PASS；预设相关 6 PASS、4 FAIL。另行复跑原始攻击 1/1 PASS，以及既有 parser、widget、policy、repository、registry、预设管理、导航和 Makefile 契约 34/34 PASS；本轮聚焦证据合计 50 项，46 PASS、4 FAIL、0 skip。【存在发布阻断】

### 新发现缺陷

| 缺陷 | 严重度 | 最小复现 | 实际结果 | 关联需求 |
| :--- | :--- | :--- | :--- | :--- |
| QA-PRE-002：小写拼接敏感字段绕过中央 policy | P1 / High | `lowercase concatenated private field aliases are rejected` | `sessionid`、`parentsessionid`、`privatenote`、`deviceid`、`analyticsid`、`historyid`、`questiontext`、`intentiontext`、`resultvalue` 9 个键全部被接受 | FR-036、NFR-011、NFR-022、REL-013 |
| QA-PRE-003：复制外部预设未执行 provider decode | P1 / High | `copy rejects a safe-key configuration the provider cannot decode` | `diceCount=2`、`keepHighest`、`keepCount=3` 的非法 D20 配置被接受；返回 `qa-preset-1`、持久化同 ID，并消费 1 个 preset ID | FR-036、NFR-012、NFR-022、REL-013 |
| QA-PRE-004：损坏或未知版本原始快照在合法复制后丢失 | P1 / High | `corrupt snapshot survives a later legal copy` 与 `unknown-version snapshot survives a later legal copy` | load 发出隔离状态后，合法复制用 schema-v1 活跃快照覆盖原始 corrupt/schema-99 文本；owned storage 中不再可恢复原文 | FR-036、NFR-012、REL-003、REL-013 |

QA-PRE-002 的根因边界是 token 化只识别大小写或分隔符边界，小写拼接词仍作为 `sessionid` 等单一 token。QA-PRE-003 的根因边界是用户预设 load 与 registry launch 会调用 `decodePresetConfiguration()`，但 `PresetController._requireSource()` 在复制前只执行通用 model 校验、provider 存在性和中央字段 policy，没有执行同一 provider codec。QA-PRE-004 的根因边界是顶层 corrupt/unknown snapshot 只形成 load issue，没有作为 raw quarantine 记录参与后续 `saveAll()`，因此第一次合法写入覆盖唯一原始文本。

### 已完成矩阵

| 范围 | 独立结果 | 结论 |
| :--- | :--- | :--- |
| 表达式恶意输入 | 超长十进制、全角与阿拉伯数字、空格与换行、NUL、零宽和双向字符、双 `kh`/`kl`、缺少 K、modifier 溢出均拒绝 | 【通过】 |
| 失败原子性 | 非法表达式保持 0 RNG、0 session ID、0 保存、0 feedback，原控件状态不变 | 【通过】 |
| 成功映射 | `4D6KL2-0003` 归一化到 custom、4D6、keepLowest 2、modifier -3，并保留既有 DC 5；固定向量只消费 4 次随机并保存一个冻结 session | 【通过】 |
| 名称边界 | trim 后空名称和控制字符拒绝，Unicode 名称允许，80 个 emoji 接受、81 个拒绝 | 【通过】 |
| system/user 生命周期 | system/bundled 保持只读；复制生成 user/local 新 ID；重命名和删除只作用于副本；历史独立 | 【通过】 |
| 冻结配置边界 | 应用预设后工具页把骰数从 1 改为 2，只改变本次 draft；repository 中冻结副本仍为 1D20 | 【通过】 |
| pending 与写失败 | pending 不替代 active；持久写失败回退 transient 并只发一个 warning | 【通过】 |
| provider/registry | 原 fake 私人字段攻击已拒绝，合法 fake 与三内置 provider、unknown tool、系统 ID collision 既有定向用例通过；safe-key malformed copy 仍可绕过 decode | 【部分失败】 |
| snapshot 与 codec | 合法 schema、单记录隔离、pending 和 D20 launch codec 既有用例通过；顶层 corrupt/unknown 原文后续写入丢失 | 【部分失败】 |
| Widget 与架构 | 表达式控件、四项导航、显式 apply 回调、共享 `AppButton`、管理页复制/重命名/删除定向用例通过 | 【通过】 |
| YAML 与本地 CI 契约 | `.github` 5 个 YAML 全部可解析；workflow 的 `run:` 仅为 `make bootstrap`、`make verify`；只读权限、并发取消、30 分钟超时、Java 17、Flutter 3.47.1 stable 均存在 | 【静态通过】 |
| Makefile | 默认 help 展示 12 个命令入口；不存在的 `FLUTTER_BIN` 给出可操作错误并原始退出 2；既有 Makefile 契约 4/4 PASS | 【通过】 |

“修改系统预设”在冻结 v0.1 边界下仍表示复制一份独立规则快照，再重命名或删除用户副本；工具页后续草稿修改不回写副本。本轮已补动态证据证明该行为。当前版本仍没有“编辑并保存用户预设规则配置”能力，因此不得扩大宣称为已实现可持久编辑；按冻结 FR-036 边界，这一点本身不另记缺陷。

### 精确命令与结果

| 命令 | 退出码 | 测试或检查结果 |
| :--- | :----: | :--- |
| `flutter test test/architecture/preset_private_field_boundary_qa_test.dart` | 0 | 原始 QA-PRE-001 攻击 1 PASS、0 FAIL、0 skip |
| `flutter test test/features/dice/dice_expression_adversarial_qa_test.dart test/widget/dice_expression_session_qa_test.dart test/core/presets/preset_adversarial_qa_test.dart` | 1 | 15 项：11 PASS、4 FAIL、0 skip；4 个失败均在独立 preset 对抗文件 |
| `flutter test test/features/dice/dice_expression_parser_test.dart test/widget/dice_expression_widget_test.dart test/core/presets/preset_configuration_policy_test.dart test/core/presets/preset_repository_test.dart test/architecture/preset_registry_test.dart test/widget/preset_management_page_test.dart test/architecture/makefile_contract_test.dart test/widget/navigation_accessibility_test.dart` | 0 | 既有相关定向集 34 PASS、0 FAIL、0 skip |
| Ruby `YAML.load_file` 逐个解析 `.github/**/*.{yml,yaml}` | 0 | 5/5 YAML 可解析 |
| `awk` 提取 `.github/workflows/ci.yml` 的 `run:` | 0 | 仅 `make bootstrap`、`make verify` |
| `FLUTTER_BIN=flutter make help` | 0 | help 与 bootstrap、format、check-format、analyze、test、test-unit、test-widget、build-web、build-android、verify、clean 共 12 个入口可见 |
| `FLUTTER_BIN=./.tooling/missing-flutter/bin/flutter make analyze` | 2 | 明确提示设置绝对 `FLUTTER_BIN` 或安装到项目工具路径 |
| `FLUTTER_BIN=flutter make verify` | 2 | format 检查 192 文件、0 改动；analyze 0 issue；全仓 398 项为 394 PASS、4 FAIL、0 skip，随后 `make: *** [test] Error 1` |

任务明确禁止安装或下载，因此本轮没有执行 `make bootstrap`；对它的验收限于 workflow 只通过 Makefile 调用和静态契约。配置文件存在、本地 YAML 可解析也不等于 GitHub hosted CI 已执行通过，本轮没有远端 run ID、commit SHA 或 hosted 日志。

### Web 与剩余边界

`make verify` 在全仓测试阶段真实失败，未进入 `build-web`，所以本轮没有合格的新 Web 产物、31 precache 计数或 Web SHA-256。工作区已有 `build/web` 不绑定本次失败门禁，未将其哈希作为本轮证据。【未生成】

剩余发布边界如下：

- 开发需在共享层修复 QA-PRE-002，复跑全部 9 个小写拼接别名，不能只增加 `sessionid` 单点特判。
- 复制任何 system/user 或 fake extension 来源前，需复用 provider codec 并在生成 ID、持久化之前 fail-closed，关闭 QA-PRE-003。
- corrupt 与未知顶层 schema 的原始字符串需进入可恢复 quarantine，后续合法写入不得覆盖唯一副本，关闭 QA-PRE-004。
- 4 个失败用例、完整 `make verify` 和其后 Web build 必须由 QA 在同一稳定快照上重新取得退出码 0，才能生成可信 Web 哈希并解除发布阻断。
- hosted CI、真实浏览器和 Android 不在本轮本地验收证据内；不得由 YAML 静态检查推断其通过。

本次修复后独立复测的最终结论仍为 **FAIL**。QA-PRE-001 已有独立关闭证据，但 QA-PRE-002、QA-PRE-003、QA-PRE-004 均为 P1；在这 3 类缺陷修复并取得完整绿色门禁前，预设/表达式功能不准入发布。

## 最终独立复测

- **复测日期**：2026-08-23。
- **当前有效结论**：【PASS；QA-PRE-001～QA-PRE-004 全部关闭，预设/表达式范围准入】。
- **环境**：Flutter 3.47.1 stable、framework revision `6655482ec0`、Dart 3.13.1、macOS arm64。
- **测试保护**：本轮未修改任何 `test/**` 文件及其预期，只追加本文档；原始 `preset_private_field_boundary_qa_test.dart` SHA-256 仍为 `3956660cc1374bf20f57f5b26a11b08a51a30b813ba76c3759d5536cc956d5e3`。

### 缺陷关闭审计链

| 审计节点 | 独立证据 | 结论 |
| :--- | :--- | :--- |
| 首次攻击 | QA-PRE-001 原 fake provider 用例 0/1，证明私人字段可进入 configuration | 【历史 FAIL；保留】 |
| 中央 policy 首次修复 | 原 QA-PRE-001 变为 1/1，但扩展集发现 QA-PRE-002、QA-PRE-003、QA-PRE-004；当时全仓 394 PASS、4 FAIL | 【历史 FAIL；保留】 |
| QA-PRE-002 最终修复 | compact ASCII key 只在完整 token 序列可解析时判定；此前 9 个小写拼接敏感键攻击全部拒绝 | 【关闭】 |
| QA-PRE-003 最终修复 | `PresetController._requireSource()` 在生成 ID 和保存前复用中央 policy 与对应 provider `decodePresetConfiguration()` | 【关闭】 |
| QA-PRE-004 最终修复 | 独立 quarantine storage key 保留 corrupt/unknown active 原文；首次合法写入先保存 quarantine，再提交 pending/active | 【关闭】 |
| 最终精确复测 | 此前 4 个失败用例逐个 1/1 PASS，合计 4/4、0 FAIL、0 skip | 【通过】 |
| 最终独立对抗集 | QA 新增 15 项全部通过 | 【通过】 |
| 最终既有相关集 | 8 个 preset/expression 相关既有测试文件共 32/32 PASS | 【通过】 |
| 最终全仓门禁 | format、analyze、402 项测试、Web build 与 31 项 precache 全链退出 0 | 【通过】 |

此前两轮 FAIL 是各自生产快照上的真实结果，不因本次全绿而删除或改写。本节是开发最终修复落盘后的独立复测结果，按时间顺序覆盖当前准入判断。

### 原失败用例精确复测

以下命令均使用原始测试和原始期望，单条退出码均为 0、1/1 PASS：

```text
flutter test test/core/presets/preset_adversarial_qa_test.dart --plain-name "lowercase concatenated private field aliases are rejected"
flutter test test/core/presets/preset_adversarial_qa_test.dart --plain-name "copy rejects a safe-key configuration the provider cannot decode"
flutter test test/core/presets/preset_adversarial_qa_test.dart --plain-name "corrupt snapshot survives a later legal copy"
flutter test test/core/presets/preset_adversarial_qa_test.dart --plain-name "unknown-version snapshot survives a later legal copy"
```

精确结果如下：

- QA-PRE-002：9 个小写拼接敏感字段全部 fail-closed，不再接受 configuration。【通过】
- QA-PRE-003：malformed D20 source 在生成 preset ID 和保存前被拒绝，保持零 ID 消费、零持久化。【通过】
- QA-PRE-004：corrupt 与 schema-99 原始 active 文本在合法复制后仍可从 owned quarantine 恢复。【通过】

### 定向与全仓命令

| 命令 | 退出码 | 精确结果 |
| :--- | :----: | :--- |
| `flutter test test/features/dice/dice_expression_adversarial_qa_test.dart test/widget/dice_expression_session_qa_test.dart test/core/presets/preset_adversarial_qa_test.dart` | 0 | 独立对抗集 15 PASS、0 FAIL、0 skip |
| `flutter test test/app/platform/shared_preferences_async_store_test.dart test/architecture/preset_private_field_boundary_qa_test.dart test/architecture/preset_registry_test.dart test/core/presets/preset_configuration_policy_test.dart test/core/presets/preset_repository_test.dart test/features/dice/dice_expression_parser_test.dart test/widget/dice_expression_widget_test.dart test/widget/preset_management_page_test.dart` | 0 | 既有相关集 32 PASS、0 FAIL、0 skip |
| `FLUTTER_BIN=flutter make verify` | 0 | format 检查 192 文件、0 改动；analyze 0 issue；全仓 402 PASS、0 FAIL、0 skip；Web 构建和 31 项 precache 完成 |
| `dart tool/verify_web_precache.dart build/web` | 0 | 独立复核 31 项 Pocketools precache 资源 |
| `find build/web -type f -print0 \| sort -z \| xargs -0 shasum -a 256 \| shasum -a 256` | 0 | 40 文件有序集合 SHA-256 已记录 |

聚焦命令之间有意重叠，用于分别证明原失败点、完整独立攻击集和既有回归集；不把重叠执行相加冒充唯一测试数。当前仓库的完整唯一测试总数以 `make verify` 为准，为 402 项。

### Web 与 precache 证据

| 产物 | SHA-256 | 状态 |
| :--- | :--- | :--- |
| `build/web/main.dart.js` | `f868ddcad91fee8147afc1bf3bd6fd84ce7c52cbcedb787fef9da7829a7e67f0` | 【通过】 |
| `build/web/flutter_bootstrap.js` | `f3dd0fb55e94c6ea2a77b6acc884c6e3d880cc988670f2c700547b5fbaeaf2cf` | 【通过】 |
| `build/web/pocketools_service_worker.js` | `14b412ce89d26a06420e0f91cb4262b8bdce8425818fcd95710dec1dd05a27f9` | 【通过】 |
| `build/web/manifest.json` | `eaf7f12910dfaec68514fc530a95830c8a42418815185be19c95186fab1a51bd` | 【通过】 |
| 40 文件有序集合 | `36c9cb4b3004ded9294f0b7e5cfa46e6aa289e99b3809db53309a518e35fbb08` | 【通过】 |

- `build/web` 共 40 个文件、41M。【已验证】
- `make verify` 与独立 verifier 均确认 31 项 precache。【已验证】
- 旧 `build/web/flutter_service_worker.js` 不存在，自有 `pocketools_service_worker.js` 存在。【已验证】

### 剩余证据边界

- 当前工作区没有 `.git` 元数据，无法把本地源码、测试报告和 Web 哈希绑定到 branch、commit SHA 或 dirty 状态；发布负责人仍需在可追溯仓库中完成版本绑定。【阻塞发布追溯，不是本次生产契约失败】
- 本轮没有执行 GitHub hosted CI、Android 构建或真实浏览器 service worker 升级与离线交互；本地 YAML 和 Web 静态门禁不替代这些平台证据。【未覆盖】
- 聚焦预设/表达式范围未发现残余 P0/P1；冻结副本仍只支持复制、重命名、删除，工具页草稿不回写，该产品边界没有扩大为可持久编辑规则。【已验证】

最终独立复测为 **PASS**：QA-PRE-001、QA-PRE-002、QA-PRE-003、QA-PRE-004 均有原断言转绿证据，15 项对抗、32 项既有相关测试和全仓 402 项全部通过。预设/表达式功能解除此前 P1 发布阻断，可按本范围准入；仓库版本追溯和未执行的平台验证仍由发布总门禁承接。

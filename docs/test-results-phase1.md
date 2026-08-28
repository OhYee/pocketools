# Pocketools v0.1.0 阶段一独立 QA 结果

- **执行日期**：2026-08-23。
- **执行角色**：独立 QA。
- **阶段结论**：【有条件通过：Android阻塞且67未覆盖仍在后续】。
- **需求基线**：52 条 FR、24 条 NFR、13 条 REL，共 89 条。
- **测试结果**：88 项测试全部通过；原 QA 72 项全部保留且通过。
- **平台结论**：Web 构建通过；Android 因缺少 Android SDK 阻塞。
- **修改边界**：仅修改或新增 `test/**` 与本文档，未修改 `lib/**`、Makefile、pubspec 或 PM/UX 文档。

## TL;DR

- **原缺陷复测**：QA-P1-001～QA-P1-004 均通过定向用例和完整回归；深冻结、重复牌拒绝、剩余牌数校验、默认与自定义 session adapter 已获得实际证据。【通过】
- **QA-P1-005 复测**：修复前 schema-v1 payload 缺少 `deckSize` 时，52/54 牌组均按已验证的 `includeJokers` 恢复；显式错误字段仍严格拒绝。【通过】
- **攻击性覆盖**：循环引用、map/list/set 深层组合、非法 map key、非法 Joker、错误 `deckSize`、错误 `remainingCount`、重复牌、默认与自定义 adapter、adapter 错配均通过。【通过】
- **平台阻塞**：`ANDROID_HOME` 与 `ANDROID_SDK_ROOT` 均未设置，`make build-android` 返回 “No Android SDK found”。【阻塞】
- **覆盖边界**：塔罗、六爻、硬币、扑克 UI、解释内容、持久化历史、分享、迁移、完整恢复、五工具反馈和真实跨端一致性均未实现或未执行，不计为通过。【未覆盖】
- **阶段判断**：阶段一已实现生产契约没有剩余自动化失败；Android 与 67 条后续范围不在本次通过结论内。【有条件通过：Android阻塞且67未覆盖仍在后续】

## 环境与证据身份

| 项目 | 实际值 | 状态 |
| :--- | :----- | :--- |
| 工作区 | `.` | 【通过】 |
| 操作系统 | macOS 26.5.2，Build 25F84，arm64 | 【通过】 |
| Flutter | Flutter 3.47.1 stable，revision `6655482ec0` | 【通过】 |
| Dart | Dart 3.13.1 stable，macos_arm64 | 【通过】 |
| Android SDK | `ANDROID_HOME` 与 `ANDROID_SDK_ROOT` 均未设置 | 【阻塞】 |
| 源码版本身份 | 工作区没有 `.git` 元数据，无法绑定 commit SHA | 【阻塞】 |
| Web 产物 | `build/web`，40 MB，文件集合 SHA-256 `07c87ca066903d77796ee5e7db7b1e8ad63ccd9c4d25583339ec817b6881a149`；`main.dart.js` SHA-256 `c66a928cbc1b2978406593398086d5f3d91682b53ea0fefeda08b07c5940454e` | 【通过】 |

源码版本身份阻塞不会抹去本次本地证据，但在形成发布报告前必须由主 PM 提供可追溯的仓库、分支或提交身份。【阻塞】

## 命令执行结果

| 命令 | 退出码 | 实际结果 | 状态 |
| :--- | :----: | :------- | :--- |
| `flutter --version` | 0 | Flutter 3.47.1、Dart 3.13.1 | 【通过】 |
| 原失败精确用例 `--plain-name "card codec reads the phase-one schema-v1 payload without deckSize"` | 0 | 1 项通过，52 张 legacy 输入恢复成功 | 【通过】 |
| `flutter test test/features/cards/card_session_codec_legacy_compatibility_test.dart` | 0 | 52 张与 54 张两个 legacy compatibility 用例通过 | 【通过】 |
| 显式错误 `deckSize` 精确用例 | 0 | 显式 54 与 `includeJokers=false` 不一致时仍抛 `FormatException` | 【通过】 |
| 错误 `remainingCount` 精确用例 | 0 | 两张牌配错误剩余数仍被拒绝 | 【通过】 |
| 重复牌精确用例 | 0 | 重复 `clubs-two` 仍被拒绝 | 【通过】 |
| `FLUTTER_BIN=… make verify` | 0 | 格式检查 54 个文件无改动、analyze 无问题、88 项测试全部通过并生成 Web 产物 | 【通过】 |
| `FLUTTER_BIN=… make build-android`，阶段一初测 | 2 | 返回 `No Android SDK found`；本轮环境变量检查仍确认 SDK 缺失，未重复执行已知阻塞命令 | 【阻塞】 |

表中的 `…` 均指本文『环境与证据身份』记录的绝对 Flutter 路径，不代表未验证占位命令。

## 新增与强化的测试

### 随机核心

- 覆盖 `limit - 1` 接受、`limit` 拒绝、`0xffffffff` 拒绝、可整除边界、`maxExclusive=1`、完整 uint32 上界、非法 bound 和非法 entropy。【通过】
- 覆盖拒绝后熵源失败，不产生返回值且异常向上传递。【通过】
- 覆盖 Fisher–Yates 的空集合、单元素、递减 bound、首尾交换、固定排列、输入不变和中途随机失败。【通过】

### D20

- 保留固定向量 `[7, 15, 3, 11]`，得到原始骰 `[8, 16, 4, 12]`、保留索引 1/2/4 和总值 41。【通过】
- 覆盖 1/20 枚、2/1000 面、sum、keepHighest、keepLowest、K=1、K=count、非法 count/sides/K 和无效输入零随机调用。【通过】
- 覆盖最高与最低聚合的同值稳定顺序、20D1000、modifier、DC、预设识别、结果列表不可修改，以及自然 1/20 只按 `total >= DC` 判断。【通过】
- widget 覆盖步进器、键盘输入上界、非法输入、48 px 控件、数量/面数/聚合语义、360 px、200% 字体、减少动态、反馈关闭和随机失败无伪结果。【通过】

### 扑克牌

- 覆盖默认 52 张、显式 54 张与两个不同 Joker、draw 1、完整牌组、非法 n 零随机调用、无重复、固定明确顺序和随机失败无部分结果。【通过】
- codec 正常 round-trip 保留配置与抽牌顺序；重复 ID、错误 `remainingCount`、牌数不符、52/54 `deckSize` 不符、非法牌 ID、非法 Joker 和重复 Joker 均被拒绝。【通过】
- 修复前 schema-v1 输入没有 `deckSize`；当前 codec 可按 `includeJokers` 恢复 52/54，同时不放宽显式错误 `deckSize`、错误剩余数或重复牌。【通过】

### 架构、共享 UI 与反馈

- `ToolRegistry` 覆盖重复 ID、重复 route、codec ID 不匹配、模块列表不可修改、fake 模块发现与导航。【通过】
- 默认 adapter 覆盖统一 session 创建、解码、父会话、历史摘要和分享；自定义 adapter 覆盖自定义分享及错配拒绝。【通过】
- 深冻结覆盖外部别名修改、map/list/set 任意嵌套、直接与间接循环、非法非字符串 key、读取后修改和不支持值。【通过】
- 静态架构测试确认领域目录不依赖 Flutter/presentation，app shell 不导入具体 feature，D20 页面使用共享 `AppButton`、`AppStepper`、分段控件和结果卡。【通过】
- 静态样式测试确认 D20 页面没有本地颜色、时长、圆角或数字间距，并由共享 `AppButton` 持有 48 px 与语义契约。【通过】
- Android feedback method channel 覆盖 light/medium、非 Android no-op 和平台异常 no-op；D20 覆盖结果先冻结再反馈、关闭反馈和减少动态。【通过】

### Makefile

- 新增静态契约测试，验证默认 help、11 个必需目标、`FLUTTER_BIN` 可操作错误、verify 聚合关系和 clean 仅薄封装 `flutter clean`。【通过】
- 本地命令获得实际执行证据；仓库内没有可核对的 CI 配置或 CI 子命令轨迹，本地与 CI 一致性尚未证明。【未覆盖】

## 生产缺陷

### QA-P1-001：统一会话结果不是深层不可变

- **严重度**：高，P0 发布阻断。
- **关联需求**：FR-003、NFR-023、REL-013。
- **根因修复审查**：[SessionRecord](../lib/core/session/session.dart) 现在递归复制 map/list/set，使用 identity 活跃集合检测环，并拒绝非字符串 key 和不支持值。
- **复测命令**：`flutter test test/core/session/session_test.dart --plain-name "session outcome is deeply immutable"`。
- **独立增量**：增加 map/list/set 组合、别名修改、直接与间接循环、非法 key 和不支持值测试。
- **复测结果**：原用例和独立增量均通过，外部引用及读取到的嵌套集合不能修改冻结结果。【通过】

### QA-P1-002：扑克 codec 接受重复牌 ID

- **严重度**：高，P0 发布阻断。
- **关联需求**：FR-049、NFR-020、NFR-023、REL-013。
- **根因修复审查**：[CardSessionCodec](../lib/features/cards/presentation/card_session_codec.dart) 现在核对抽牌数、牌 ID、Joker 开关和 `seenIds`。
- **复测命令**：`flutter test test/features/cards/card_session_codec_test.dart --plain-name "card session codec rejects duplicate card ids"`。
- **独立增量**：增加未知 Joker、重复 Joker、关闭 Joker 时出现 Joker，以及合法大小王顺序测试。
- **复测结果**：重复牌和非法 Joker 均被拒绝，合法 54 张牌组语义保持不变。【通过】

### QA-P1-003：扑克 codec 忽略剩余牌数不一致

- **严重度**：高，P0 发布阻断。
- **关联需求**：FR-049、NFR-020、NFR-023、REL-013。
- **根因修复审查**：[CardSessionCodec](../lib/features/cards/presentation/card_session_codec.dart) 现在以 `deckSize - cards.length` 核对 `remainingCount`，并校验输入的 52/54 `deckSize`。
- **复测命令**：`flutter test test/features/cards/card_session_codec_test.dart --plain-name "card session codec rejects an inconsistent remaining count"`。
- **独立增量**：增加牌数不符、错误 deck size、字段类型错误和合法 52/54 配置测试。
- **复测结果**：错误剩余牌数与不一致牌组大小均被拒绝。【通过】

### QA-P1-004：`ToolModule` 公开协议不足以完成 fake 会话

- **严重度**：高，P0 架构门禁阻断。
- **关联需求**：NFR-022、NFR-023、REL-013。
- **根因修复审查**：[ToolSessionAdapter](../lib/core/tools/tool_session_adapter.dart) 提供统一创建、解码、历史摘要和分享载荷；[ToolRegistry](../lib/core/tools/tool_registry.dart) 成为按 tool ID 路由这些入口的公共边界。
- **复测命令**：`flutter test test/architecture/tool_session_adapter_test.dart --plain-name "a codec-only fake module gets session, history, and share flows"`。
- **独立增量**：默认 adapter 覆盖父会话和冻结载荷；自定义 adapter 覆盖自定义分享；错配 adapter 必须在注册时拒绝。
- **复测结果**：fake 模块无需改 shell 即可使用 Registry 的统一 session/history/share 入口。【通过】

### QA-P1-005：同版本扑克旧 payload 无法解码

- **严重度**：高，P0 阶段门禁阻断。
- **关联需求**：FR-049、NFR-012、REL-005、REL-007。
- **根因修复审查**：[CardSessionCodec](../lib/features/cards/presentation/card_session_codec.dart) 仅在输入没有 `deckSize` 时使用已验证 `includeJokers` 对应的 `config.deckSize`；显式字段仍执行整数和 52/54 一致性校验。
- **复测命令**：`flutter test test/features/cards/card_session_codec_validation_test.dart --plain-name "card codec reads the phase-one schema-v1 payload without deckSize"`。
- **复现数据**：输入为 `{"drawCount":2,"includeJokers":false}`，结果为两张不同标准牌与 `remainingCount=50`；这是修复前阶段一 codec 的 schema-v1 字段集合。
- **独立复测**：原 52 张失败夹具、开发新增 52/54 夹具、显式错误 `deckSize`、错误 `remainingCount` 和重复牌均通过预期断言。
- **复测结果**：旧输入恢复为正确结构化配置；严格拒绝路径没有回退；`make verify` 88 项全部通过并完成 Web 构建。【通过】
- **缺陷状态**：QA-P1-005 已关闭。【通过】

## 治理与环境阻塞

- `docs/project-plan.md`、根 README 仍写明 G1 阻塞、仓库没有业务源码或 Makefile 证据，与当前阶段一代码和用户提供的“开发阶段一已关闭”状态不一致；QA 无权修改 PM 文档，需主 PM 明确阶段一授权基线。【阻塞】
- 工作区没有 Git 元数据，无法生成开发提交 diff 或绑定 commit SHA；本轮改用原缺陷定位、当前实现和新增测试逐项对照，发布前仍必须补充不可变源码身份。【阻塞】
- Android SDK 缺失，无法生成 APK、安装、运行或验证 Android haptics、生命周期和固定向量跨端一致性。【阻塞】
- 仓库内没有 CI 配置或远端流水线证据，无法证明 `make verify` 与 CI 使用相同入口。【未覆盖】

## 89 条需求的阶段一覆盖边界

本矩阵按完整需求验收，不因某个子断言通过而把整条未实现需求标为通过。

### 功能需求

| ID | 状态 | 阶段一边界 |
| :-- | :--- | :--------- |
| FR-001 | 【通过】 | 四个稳定导航入口、四个当前工具入口与移动/桌面导航获得 widget 证据 |
| FR-002 | 【未覆盖】 | 可选问题/备注及五工具完整配置未实现 |
| FR-003 | 【通过】 | 输入与结果深冻结、循环拒绝、版本字段及父会话关联获得阶段一契约证据 |
| FR-004 | 【未覆盖】 | D20 防重入有局部实现，刷新、返回和恢复未执行 |
| FR-005 | 【未覆盖】 | 备注、复制、分享和统一完成会话操作未实现 |
| FR-006 | 【未覆盖】 | 塔罗未实现 |
| FR-007 | 【未覆盖】 | 塔罗未实现 |
| FR-008 | 【未覆盖】 | 塔罗未实现 |
| FR-009 | 【未覆盖】 | 塔罗未实现 |
| FR-010 | 【未覆盖】 | 塔罗未实现 |
| FR-011 | 【未覆盖】 | 塔罗内容未实现 |
| FR-012 | 【未覆盖】 | 塔罗内容边界未执行 |
| FR-013 | 【未覆盖】 | 六爻未实现 |
| FR-014 | 【未覆盖】 | 六爻未实现 |
| FR-015 | 【未覆盖】 | 六爻未实现 |
| FR-016 | 【未覆盖】 | 六爻未实现 |
| FR-017 | 【未覆盖】 | 六爻未实现 |
| FR-018 | 【未覆盖】 | 六爻内容未实现 |
| FR-019 | 【未覆盖】 | 六爻未实现 |
| FR-020 | 【通过】 | 普通、优势、劣势结构化预设映射与模式识别通过 |
| FR-021 | 【通过】 | 三种聚合、modifier、稳定 K 选择与 total 通过 |
| FR-022 | 【通过】 | 可选 DC 和 `total >= DC` 通过 |
| FR-023 | 【未覆盖】 | D20 结果页可追溯，但历史与分享语义未实现 |
| FR-024 | 【通过】 | 自然 1/20 无自动成败的正反向用例通过 |
| FR-025 | 【未覆盖】 | 2/1000 与快捷输入通过，配置复用未实现 |
| FR-026 | 【未覆盖】 | `NdS/kh/kl` 解析器未实现 |
| FR-027 | 【未覆盖】 | 硬币未实现 |
| FR-028 | 【未覆盖】 | 硬币未实现 |
| FR-029 | 【未覆盖】 | 硬币未实现 |
| FR-030 | 【未覆盖】 | 硬币未实现 |
| FR-031 | 【未覆盖】 | 历史持久化未实现 |
| FR-032 | 【未覆盖】 | 统一会话深层不可变通过，历史详情与备注仍未实现 |
| FR-033 | 【未覆盖】 | 历史筛选与搜索未实现 |
| FR-034 | 【未覆盖】 | 历史删除未实现 |
| FR-035 | 【未覆盖】 | 配置复用与父会话未实现 |
| FR-036 | 【未覆盖】 | 预设持久化未实现 |
| FR-037 | 【未覆盖】 | 复制与分享预览未实现 |
| FR-038 | 【未覆盖】 | 分享字段选择未实现 |
| FR-039 | 【未覆盖】 | 平台分享与回退未实现 |
| FR-040 | 【未覆盖】 | 仅减少动态与振动设置存在，完整设置范围未实现 |
| FR-041 | 【未覆盖】 | D20 减少动态通过，其他工具未实现 |
| FR-042 | 【未覆盖】 | 未执行真实断网五工具流程 |
| FR-043 | 【未覆盖】 | 历史关闭与临时会话未实现 |
| FR-044 | 【未覆盖】 | 本地删除和说明入口未实现 |
| FR-045 | 【未覆盖】 | 高风险主题处理未实现 |
| FR-046 | 【未覆盖】 | D20 随机失败通过，存储/内容/分享降级未实现 |
| FR-047 | 【通过】 | 数量、面数、聚合、K、modifier、DC、固定 41、同值顺序、键盘、步进器、不可变列表和 360 px/200% 字体通过 |
| FR-048 | 【未覆盖】 | 扑克纯规则通过，但应用入口和配置 UI 未实现 |
| FR-049 | 【通过】 | 冻结配置、顺序、剩余数、重复牌拒绝和 schema-v1 52/54 恢复获得阶段一 codec 与统一 adapter 证据 |
| FR-050 | 【未覆盖】 | 塔罗解释未实现 |
| FR-051 | 【未覆盖】 | 六爻解释未实现 |
| FR-052 | 【未覆盖】 | 仅 D20 反馈顺序获得证据，其他四工具未实现 |

### 非功能需求

| ID | 状态 | 阶段一边界 |
| :-- | :--- | :--------- |
| NFR-001 | 【未覆盖】 | 纯 Dart 固定结果通过，Android/Web 运行时结构化对比未执行 |
| NFR-002 | 【通过】 | 默认安全随机源、统一注入和失败不降级获得代码与测试证据 |
| NFR-003 | 【未覆盖】 | 拒绝采样与洗牌边界通过，预注册统计检验未执行 |
| NFR-004 | 【未覆盖】 | D20/cards 固定序列通过，旧会话版本解释未实现 |
| NFR-005 | 【未覆盖】 | 未建立设备矩阵或 P95 测量 |
| NFR-006 | 【未覆盖】 | 刷新、进程恢复和原会话定位未实现 |
| NFR-007 | 【未覆盖】 | D20 语义、键盘、48 px、360 px/200% 通过，五工具无障碍未覆盖 |
| NFR-008 | 【未覆盖】 | D20 360 px、200% 与桌面壳层通过，平板及五工具未覆盖 |
| NFR-009 | 【未覆盖】 | 未执行断网启动和网络观测 |
| NFR-010 | 【未覆盖】 | 未执行存储、日志、分析与抓包验证 |
| NFR-011 | 【未覆盖】 | D20 参数白名单通过，表达式、导入和分享载荷未实现 |
| NFR-012 | 【未覆盖】 | 扑克 schema-v1 缺 `deckSize` 的 52/54 兼容边界通过；完整逐级迁移、未知版本隔离和原始数据导出仍未实现 |
| NFR-013 | 【未覆盖】 | 资源键、语言与内容稳定 ID 范围未验证 |
| NFR-014 | 【未覆盖】 | 无日志/事件 schema 与运行证据 |
| NFR-015 | 【未覆盖】 | 内容包与构建许可校验未实现 |
| NFR-016 | 【通过】 | domain 不依赖 Flutter/presentation，展示与反馈不创建随机源的静态测试通过 |
| NFR-017 | 【未覆盖】 | 阶段一 D20 边界充分，五工具、恢复、兼容性和统计范围未覆盖 |
| NFR-018 | 【未覆盖】 | Android method channel 和非 Android no-op 通过，Web 真实能力与五工具阶段未覆盖 |
| NFR-019 | 【未覆盖】 | D20 结果先冻结、减少动态和关闭反馈通过，后台/页面恢复与五工具未覆盖 |
| NFR-020 | 【未覆盖】 | 扑克纯规则通过，Android/Web、离线、UI 重抽新会话未覆盖 |
| NFR-021 | 【未覆盖】 | 扑克牌面和发布素材尚未实现或审查 |
| NFR-022 | 【通过】 | fake 模块无需改 shell 即可通过 Registry 创建、解码并取得历史摘要与分享载荷 |
| NFR-023 | 【通过】 | 默认和自定义 adapter 复用统一不可变 envelope、历史摘要与分享入口 |
| NFR-024 | 【未覆盖】 | D20 共享组件与静态样式通过，五工具加 fake 的 token 单点变化未验证 |

### 发布与治理需求

| ID | 状态 | 阶段一边界 |
| :-- | :--- | :--------- |
| REL-001 | 【通过】 | 三份冻结基线文档存在且可引用 |
| REL-002 | 【阻塞】 | PM 文档仍记录 G1 阻塞，QA 未形成设计放行结论 |
| REL-003 | 【未覆盖】 | 89 条最终实现位置、证据和发布结论尚未齐全 |
| REL-004 | 【通过】 | README 可定位 LICENSE、NOTICE、贡献、行为准则、安全与许可文档 |
| REL-005 | 【通过】 | 阶段一 `make verify` 的 88 项已实现范围测试全部通过；完整发布统计、离线、恢复和隐私验收仍属于后续边界 |
| REL-006 | 【阻塞】 | Android SDK、最低版本、浏览器与渠道矩阵未冻结 |
| REL-007 | 【阻塞】 | 工作区没有 commit 身份，内容/规则/历史版本链不完整 |
| REL-008 | 【阻塞】 | Web 构建通过，Android、签名、分发与回退证据缺失 |
| REL-009 | 【未覆盖】 | Web 缓存、Android 灰度和版本回退未执行 |
| REL-010 | 【未覆盖】 | 当前为阶段一报告，不是发布后 release-report |
| REL-011 | 【阻塞】 | 本地入口、负路径与 clean 通过；Android 目标和 CI 一致性无证据 |
| REL-012 | 【阻塞】 | 扩展 G1 仍由 PM 文档记录为阻塞，QA 未验收 UX 资产 |
| REL-013 | 【通过】 | fake 默认/自定义 adapter、统一 session/history/share 入口、深冻结与依赖边界测试通过 |

阶段一矩阵汇总为 16 条通过、0 条失败、6 条阻塞、67 条未覆盖，共 89 条。

## 阶段一结论与复测入口

- D20 规则、random_core 边界、扑克 CardDrawer、共享控件、基础 feedback、Makefile 本地行为和 Web 构建可以作为后续回归基线。【通过】
- QA-P1-001～QA-P1-005 均已关闭；原 QA 72 项、此前开发 4 项、独立增量 10 项和本轮开发新增 2 项，共 88 项全部通过。【通过】
- `make verify` 完整通过格式、分析、测试与 Web 构建，QA-P1-005 严格负向断言没有被删除或放宽。【通过】
- Android、源码身份、G1 状态和 CI 一致性需要主 PM 分别协调开发、UX/PM 和发布环境解除。【阻塞】
- 阶段一 QA 结论为【有条件通过：Android阻塞且67未覆盖仍在后续】；QA-P1-005 不再阻止阶段二，实际阶段准入仍需主 PM 处理 G1 与治理阻塞。Android SDK 可用后仍需执行 `make build-android` 与设备验证。

## 参考资料

- [Pocketools v0.1.0 需求文档](requirements.md)
- [Pocketools v0.1.0 测试计划](test-plan.md)
- [Pocketools 项目计划](project-plan.md)
- [Pocketools 许可与内容边界](licensing.md)

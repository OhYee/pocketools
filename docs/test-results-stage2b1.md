# Pocketools v0.1.0 Stage 2B1 独立 QA 结果

- **执行日期**：2026-08-23。
- **执行角色**：独立 QA。
- **验收范围**：硬币单次、批量、率先达到、自定义标签、codec、会话动画恢复、历史/分享 adapter、共享 UI 与 Web 构建。
- **阶段结论**：【有条件通过 Stage 2B1；准入后续阶段】。
- **测试结果**：154 项测试全部通过；开发自报的 143 项之外，QA 新增 11 项对抗性测试。
- **平台结论**：Web 构建通过；Android 由主 PM 并行验证，本轮未执行且不等待。
- **修改边界**：仅新增 `test/features/coin/coin_stage2b1_qa_test.dart` 与本文档，未修改 `lib/**`、Makefile、pubspec、PM/UX 文档或设计资产。

## TL;DR

- 单次与批量 `1/3/5/10/100`、非法 `0/101`、固定顺序、计数和比例均获得实际证据；非法次数及非法标签在随机调用前失败。【通过】
- 自定义标签先 `trim`，空白或归一化后相同均拒绝；标签只改变展示，codec 和会话仍保存稳定的 `heads/tails` 原始序列。【通过】
- 率先达到覆盖正面/反面获胜、最短 N 次、最长 `2N-1` 次、`N=1/3/100`；达到目标后不再取熵，普通批量始终完成配置次数。【通过】
- codec 严格核对非空有序序列、正反计数、配置次数、`winner`、`stopReason` 和输入 `raceTarget`；比例不作为独立可信 payload 字段，而是从已校验序列重算。【通过】
- 存储提交完成前不播放动画、不发反馈；保存中隐藏、已保存后隐藏、路由离开、跳过、减少动态效果均保持同一冻结 session 且不增加随机调用；重抛生成带正确 `parentSessionId` 的新 session。【通过】
- 历史摘要和分享文本通过 `ToolRegistry → ToolSessionAdapter`，保留原始序列、自定义标签、计数、停止原因和版本，同时排除问题、备注、精确时间、本地/父 session ID、设备和分析标识。【通过】
- 100 次批量在 360 px、200% 字体下完成且第 100 次原始面值语义可定位；硬币页面复用共享组件，展示层无私有 RNG、平台 haptic/channel 或受限制 magic style。【通过】
- `make verify` 实际完成格式、分析、154 项测试和 Web 构建；随后独立再次执行 Web 构建并记录产物哈希。【通过】

## 环境与证据身份

| 项目 | 实际值 | 状态 |
| :--- | :----- | :--- |
| 工作区 | `.` | 【通过】 |
| Flutter | Flutter 3.47.1 stable，revision `6655482ec0` | 【通过】 |
| Dart | Dart 3.13.1 | 【通过】 |
| 完整测试 | 154 项，全部通过 | 【通过】 |
| Web 主产物 | `build/web/main.dart.js`，SHA-256 `f8af6e0718d884ea79b58e56bb69533da20feeeffc60a72720d735e0a86e5d07` | 【通过】 |
| Web 文件集合 | 39 个文件，40 MB；有序文件哈希集合 SHA-256 `d709caa987ebb10cecb057f2390e37c3b1359dec9332b2e1bd48ad1eb6fc73d5` | 【通过】 |
| 源码版本身份 | 工作区没有 `.git` 元数据，无法把证据绑定到 commit SHA | 【阻塞】 |
| Android | 由主 PM 并行构建，本轮不执行、不等待 | 【未执行】 |
| 真实 Web 浏览器 | 本轮验证生产构建，未执行浏览器运行时矩阵 | 【未覆盖】 |

源码身份阻塞不否定本地测试结果，但发布前必须把报告、产物和可追溯源码版本绑定。

## 命令执行结果

| 命令 | 退出码 | 实际结果 | 状态 |
| :--- | :----: | :------- | :--- |
| `FLUTTER_BIN=flutter make check-format` | 0 | 变更前 86 个、QA 增量后 87 个 Dart 文件均无格式变化 | 【通过】 |
| `flutter test test/features/coin test/widget/shared_selection_control_test.dart test/widget/system_feedback_service_test.dart test/architecture/tool_registry_test.dart test/architecture/tool_session_adapter_test.dart` | 0 | 开发既有硬币及相关基线 45 项全部通过 | 【通过】 |
| `flutter test test/features/coin/coin_stage2b1_qa_test.dart` | 0 | QA 新增 11 项全部通过 | 【通过】 |
| `flutter test test/features/coin test/features/home test/architecture/tool_registry_test.dart test/architecture/tool_session_adapter_test.dart test/architecture/source_contract_test.dart test/widget/app_button_test.dart test/widget/app_button_token_test.dart test/widget/shared_selection_control_test.dart test/widget/system_feedback_service_test.dart` | 0 | 67 项全部通过 | 【通过】 |
| `FLUTTER_BIN=flutter make verify` | 0 | 格式检查通过、analyze 无问题、154 项测试通过并生成 Web 产物 | 【通过】 |
| `flutter --version` | 0 | Flutter 3.47.1、Dart 3.13.1 | 【通过】 |
| `FLUTTER_BIN=flutter make build-web` | 0 | Wasm dry run 成功，独立再次生成 `build/web` | 【通过】 |
| `shasum -a 256 build/web/main.dart.js` | 0 | 得到本文记录的主产物哈希 | 【通过】 |
| `find build/web … \| shasum -a 256` | 0 | 得到本文记录的 39 文件有序集合哈希 | 【通过】 |

`make verify` 已包含一次 Web 构建；独立 `make build-web` 是第二次构建证据。表中的 `flutter` 均指『环境与证据身份』记录的绝对 Flutter 路径。

## 独立增量测试

QA 使用 `apply_patch` 新增 `test/features/coin/coin_stage2b1_qa_test.dart`，包含 11 项测试：

- 普通批量 `1/3/5/10/100` 表驱动验证。
- `0/101`、两面空白及 trim 后相同标签的零熵拒绝。
- 正面/反面获胜、最短/最长路径、`N=1/3/100` 和熵停止边界。
- 普通批量与 race 提前停止逻辑隔离。
- codec 对序列、计数、winner、stopReason、raceTarget 的攻击性反例和比例重算。
- 缺少 nullable `raceTarget`、`winner` 的兼容样本及不放宽错误计数的反例。
- history/share 的 race 语义保留和七类敏感标记排除。
- 真实 commit gate：仓库尚未提交时无动画、无反馈、无结果揭示。
- 保存中页面隐藏后，只在提交完成时显示同一结果且无陈旧反馈。
- 动画中离开路由并重新进入，恢复同一冻结 session 且不重抛。
- 100 次批量在 360 px、200% 字体下的布局与第 100 次原始语义。

开发原有 143 项测试全部保留；154 项总数等于原基线加 11 项 QA 增量，没有删除或放宽既有断言。

## 规则验收

| 场景 | 独立断言 | 结果 |
| :--- | :------- | :--- |
| 单次正面 | 固定二值 0 映射 `heads/正面`，停止原因为完成单次 | 【通过】 |
| 单次反面 | 固定二值 1 映射 `tails/反面` | 【通过】 |
| 普通批量 | `1/3/5/10/100` 均完整生成指定次数，保持原始顺序 | 【通过】 |
| 非法次数 | `0/101` 在调用随机源前抛出校验错误 | 【通过】 |
| 计数与比例 | `headsCount + tailsCount = tossCount`；两面比例由序列重算且和为 1 | 【通过】 |
| 标签归一化 | `" 甲 " / " 乙 "` 保存为 `甲/乙`，原始结果仍为 `heads/tails` | 【通过】 |
| 标签拒绝 | 正面空白、反面空白、trim 后相同均零熵拒绝 | 【通过】 |
| race 正面获胜 | 连续与交替路径均在正面首次达到 N 时停止 | 【通过】 |
| race 反面获胜 | 连续与交替路径均在反面首次达到 N 时停止 | 【通过】 |
| race 最短 | 同一面连续出现时恰好抛 N 次 | 【通过】 |
| race 最长 | 交替序列恰好抛 `2N-1` 次；覆盖 `N=3` 和 `N=100` | 【通过】 |
| 熵停止 | 夹具在目标达到后仍提供 sentinel，实际消费量等于结果长度 | 【通过】 |
| 普通/race 隔离 | 普通批量即使前缀连续同面，也完整抛完配置次数且无 winner | 【通过】 |
| 结果不可变 | sequence 复制输入并以不可修改列表暴露 | 【通过】 |

## Codec 与兼容验收

- 输入 codec 拒绝未知 mode、非法 count、空白/相同标签、非法 `raceTarget` 类型与范围，以及缺失必需字段。【通过】
- outcome codec 拒绝空序列、未知原始面、序列长度不符、heads/tails 计数不符、普通模式伪造 winner/race stopReason、race 未达到目标、winner 不符、提前达到后继续抛和输入 `raceTarget` 不符。【通过】
- 当前 schema 不持久化独立 ratio 字段；`headsRatio/tailsRatio` 只从已验证 sequence 及计数产生，因此 decoded result 内不存在可独立篡改的比例真值。【通过】
- 兼容样本允许普通批量旧 payload 省略 nullable `raceTarget` 和 `winner`；同一样本显式错误计数仍被拒绝。【通过】
- 规则版本 `coin/1.0.0`、算法版本 `random-unbiased-binary/1.0.0` 和原始 sequence 均保留在 session/摘要证据中。【通过】

若后续 schema 新增显式 ratio 字段，必须升级 schemaVersion 并增加“字段存在时与序列严格一致、字段缺失时按版本迁移”的独立测试，不能静默信任冗余比例。

## 冻结、动画与恢复验收

| 场景 | 证据 | 结果 |
| :--- | :--- | :--- |
| commit 前 | 随机已执行但仓库 `saved` 仍为空，页面只显示设置已冻结；无动画、反馈或跳过按钮 | 【通过】 |
| commit 后 | 仓库写入完成后才触发 medium feedback，再进入抛起/翻转/落定 | 【通过】 |
| 保存中隐藏 | 隐藏时仓库仍为空；提交后直接显示同一冻结结果，无陈旧反馈 | 【通过】 |
| 已保存后隐藏 | 立即完成同一 session，等待两秒无后续反馈，随机调用不增加 | 【通过】 |
| 跳过动画 | 直接展示已保存结果，取消后续揭示反馈，不产生新序列 | 【通过】 |
| 减少动态效果 | 使用同一冻结结果进入 reduced 状态，不执行旋转/翻面，不增加随机调用 | 【通过】 |
| 路由离开 | 动画中离开并重新进入硬币页，恢复同一原始面值，随机调用保持一次 | 【通过】 |
| 重新抛掷 | 第二条 session 使用独立 ID，`parentSessionId` 指向第一条，第一条结果不变 | 【通过】 |
| 浏览器刷新/进程重启 | 当前 session repository 为内存实现，本轮未执行刷新、浏览器关闭或应用进程重启 | 【未覆盖】 |

## 历史、分享与隐私验收

- `CoinToolModule` 通过自定义 `ToolSessionAdapter` 统一创建、解码、历史摘要和分享 payload；测试实际调用 `ToolRegistry.historySummary` 与 `ToolRegistry.sharePayload`。【通过】
- 普通与 race 结果均保留标签、原始 `heads/tails` 序列、计数、停止原因、winner 语义、规则版本和算法版本。【通过】
- 对抗 session 额外注入问题、备注、设备、精确时间、本地 session ID、父 session ID 和分析 ID；历史摘要和分享文本均未出现这些唯一标记。【通过】
- 当前 `HistoryPage` 和分享预览仍未接入真实持久化及平台 UI；本轮只关闭 adapter 与 renderer 契约，不把完整历史/分享体验判为通过。【未覆盖】

## UI、无障碍与架构验收

- 单次/批量、3/5/10 快捷项、1～100 步进器、race 开关、自定义标签字段和操作按钮均使用共享组件或 Flutter 标准输入控件。【通过】
- 100 次批量在 360 × 800、200% 字体下完成，无 Flutter overflow；结果语义可定位到“第100次”和原始面值 `heads`。【通过】
- `CoinPrimitive` 明确表达抛起、翻转和落定，但面值来自冻结 outcome；动画 widgets 不导入或调用 `RandomSource`、`nextInt` 或 `CoinTosser`。【通过】
- 硬币 domain 不依赖 Flutter/presentation；页面复用 `AppToolScaffold`、`AppButton`、`AppStepper`、`AppSegmentedControl`、`AppGenerationStateView`、`AppSectionCard` 和 `AppToolTheme`。【通过】
- 展示层未直接导入 `flutter/services.dart`，未调用 `HapticFeedback`、`MethodChannel`、`SystemChannels` 或创建安全随机实现。【通过】
- 静态扫描未发现直接 `Color`、`Duration`、数字圆角、数字 EdgeInsets 或数字 SizedBox 尺寸等受限制公共 magic style。【通过】
- Android 真实 haptics、Web vibration capability/no-op、键盘全流程和真实屏幕阅读器仍需平台阶段执行。【未覆盖】

## 生产缺陷与覆盖缺口

本轮最终证据未发现 Stage 2B1 硬币规则、codec、冻结恢复、adapter、共享组件或 Web 构建范围内的生产缺陷。【通过】

以下缺口不伪装为通过：

- Android 构建与运行由主 PM 并行执行；本报告不引用其未来结果。【未执行】
- 真实浏览器刷新、页面关闭、站点恢复、离线和 vibration capability/no-op 未执行。【未覆盖】
- 真实历史列表、持久化详情、复制/分享预览、字段选择和平台分享失败降级未实现或未执行。【未覆盖】
- 自定义标签长度上限、抓包、运行日志和分析事件白名单未在 Stage 2B1 关闭；NFR-010/NFR-011 仍需后续证据。【未覆盖】
- 工作区没有 Git 元数据，Web 哈希无法绑定源码 commit、签名、分发和回退责任。【阻塞】

这些缺口不阻止 Stage 2B1 进入后续实现阶段，但任何 P0 在发布前仍无实际证据时必须阻止发布。

## 需求覆盖矩阵

本矩阵按完整需求判断；“部分通过”表示 Stage 2B1 子契约已有实际证据，但不足以关闭整条跨工具或跨平台需求。

| 需求 ID | 本轮状态 | Stage 2B1 证据与边界 |
| :------ | :------- | :------------------ |
| FR-003 | 【通过】 | 硬币输入、版本与结果冻结；重抛独立 ID 并关联父 session |
| FR-004 | 【部分通过】 | commit 后动画、隐藏、跳过、路由恢复不重抛；刷新与进程恢复未覆盖 |
| FR-005 | 【部分通过】 | 摘要、过程、版本和重抛存在；备注、复制和分享 UI 未实现 |
| FR-027 | 【通过】 | 单次 heads/tails、当前标签和原始面值均通过 |
| FR-028 | 【通过】 | `1/3/5/10/100`、`0/101`、序列、计数、比例和 UI 边界通过 |
| FR-029 | 【通过】 | trim、空白/相同拒绝、自定义标签及稳定 `heads/tails` 通过 |
| FR-030 | 【通过】 | 双面 winner、最短/最长停止、停止原因和普通批量隔离通过 |
| FR-031、FR-037 | 【部分通过】 | adapter 历史摘要与分享文本语义/脱敏通过；真实 UI 未接入 |
| FR-041 | 【部分通过】 | 硬币减少动态效果保持同一结果；五工具完整范围未关闭 |
| FR-052 | 【部分通过】 | 硬币按压、冻结生成、抛起翻转落定、完成、减少动态通过；五工具范围未关闭 |
| NFR-001 | 【部分通过】 | 纯规则固定二值序列与 Web 构建通过；Android/Web 运行时对比未执行 |
| NFR-002 | 【通过】 | 硬币只通过统一随机接口取值；失败不使用普通随机回退 |
| NFR-003 | 【部分通过】 | 二值值经统一无偏 `nextInt(2)`；硬币统计检验未在本轮执行 |
| NFR-004 | 【通过】 | 固定序列、规则版本、算法版本与 codec 可复查 |
| NFR-006 | 【部分通过】 | 隐藏、保存中隐藏和路由恢复通过；刷新/进程恢复未覆盖 |
| NFR-007、NFR-008 | 【部分通过】 | 共享语义、360 px、200% 字体和 100 次最坏 UI 路径通过；真实设备矩阵未执行 |
| NFR-010、NFR-011 | 【部分通过】 | 分享脱敏及 count/label/race 输入校验通过；日志、抓包与标签长度上限未覆盖 |
| NFR-012 | 【部分通过】 | nullable 字段缺失兼容且显式错误严格拒绝；完整 schema 迁移/隔离未覆盖 |
| NFR-016 | 【通过】 | domain/presentation 分层，动画无随机和平台旁路 |
| NFR-017 | 【部分通过】 | Stage 2B1 正常、边界、异常、恢复、无障碍和架构证据齐全；跨端矩阵未完成 |
| NFR-018 | 【部分通过】 | 平台 feedback adapter 单测与页面开关路径通过；Android/Web 真实能力未执行 |
| NFR-019 | 【部分通过】 | 结果先冻结，保存中隐藏、隐藏、跳过、减少动态和路由恢复幂等 |
| NFR-022 | 【通过】 | 硬币作为真实模块从 registry 接入，无 shell 工具 ID 分支 |
| NFR-023 | 【部分通过】 | 统一 envelope、随机、adapter 历史/分享通过；真实历史/分享页面未接入 |
| NFR-024 | 【通过】 | 共享组件/token、专属 CoinPrimitive 与重复样式静态门禁通过 |
| REL-003 | 【部分通过】 | 本报告建立需求 ID 到测试证据映射；缺少 commit 身份 |
| REL-005 | 【部分通过】 | 规则、固定向量、恢复和局部无障碍通过；统计、离线、真实跨端和兼容未收口 |
| REL-007、REL-008 | 【部分通过】 | 版本与 Web 哈希可查；源码身份、签名、分发和回退未覆盖 |
| REL-011 | 【部分通过】 | `make verify` 与独立 Web 构建实际通过；Android/CI 同入口证据由主 PM 和后续流水线补充 |
| REL-013 | 【通过】 | registry、统一 session adapter、随机边界、共享 UI/token 和静态依赖门禁通过 |

## 阶段准入结论

Stage 2B1 的硬币规则、标签、race 终止、codec、冻结动画、局部恢复、adapter、共享架构和 Web 构建没有剩余自动化失败，允许进入后续开发阶段。【有条件通过 Stage 2B1；准入后续阶段】

该结论不等于 v0.1.0 发布准入。后续阶段仍须执行：

- 主 PM 的 Android 构建、安装、haptics 开关与前后台/进程恢复。
- 真实 Web 浏览器刷新、页面隐藏、vibration capability/no-op、离线启动与站点恢复。
- 持久化历史、详情、复制、分享预览、字段选择、失败回退和隐私抓包/日志扫描。
- 跨 Android/Web 的同固定随机向量结构化结果对比。
- 源码 commit、Web/Android 产物、签名、分发和回退证据绑定。

任一 P0 出现规则错误、随机多取、冻结结果改变、隐私泄露、恢复丢失或缺少实际证据时，必须由主 PM 退回开发并阻止发布。

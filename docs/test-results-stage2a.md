# Pocketools v0.1.0 Stage 2A 独立 QA 结果

- **执行日期**：2026-08-23。
- **执行角色**：独立 QA。
- **验收范围**：扑克牌纵向切片、五工具首页、统一会话适配器、共享按钮与相关架构门禁。
- **阶段结论**：【有条件通过 Stage 2A；准入后续阶段】。
- **测试结果**：112 项测试全部通过；开发自报的 103 项之外，QA 新增 9 项对抗性测试。
- **构建结果**：Web 构建通过；本轮未执行真实浏览器、Android 设备或 Android 构建。
- **修改边界**：仅新增或修改 `test/**` 与本文档，未修改 `lib/**`、Makefile、pubspec、PM/UX 文档或设计资产。

## TL;DR

- 扑克默认 52 张且不含大小王，显式开启后为 54 张；抽取上下界、非法值零随机调用、无放回、顺序、剩余数、固定向量和完整牌组均获得自动化证据。【通过】
- 结果在存储提交完成后才进入动画；跳过、减少动态效果、页面隐藏和路由离开均恢复同一冻结会话，不增加随机调用；重新抽取创建独立 ID 并正确写入 `parentSessionId`。【通过】
- 扑克历史摘要和分享文本通过 `ToolRegistry → ToolSessionAdapter` 消费同一结构化会话；默认文本未泄露问题、备注、精确时间、本地/父会话 ID、设备或分析标识。【通过】
- 首页严格按 `ToolRegistry` 的塔罗、六爻、D20、硬币、扑克牌顺序渲染五个模块，首页和 shell 没有按工具 ID 分支。【通过】
- 扑克展示层未直接调用平台振动、安全随机实现或系统 channel，且未发现本地颜色、时长、圆角、间距等受限公共样式；`AppButton` 的共享 motion token 覆盖可单点改变按钮行为并保持 48 px 最小目标。【通过】
- `make verify` 实际完成格式、分析、112 项测试和 Web 构建；随后独立再次执行 `make build-web` 并记录产物哈希。【通过】
- 当前历史页仍是占位页，结果页也没有复制/分享预览入口；本轮只证明 adapter 契约和脱敏 renderer，不把真实历史/分享 UI、持久化、离线、浏览器刷新、进程恢复或 Android 运行时判为通过。【未覆盖】

## 环境与证据身份

| 项目 | 实际值 | 状态 |
| :--- | :----- | :--- |
| 工作区 | `.` | 【通过】 |
| Flutter | Flutter 3.47.1 stable，revision `6655482ec0` | 【通过】 |
| Dart | Dart 3.13.1 | 【通过】 |
| 完整测试 | 112 项，全部通过 | 【通过】 |
| Web 主产物 | `build/web/main.dart.js`，SHA-256 `abd50c7165e5b1b08651740504184d3b82a6bf56f38fc82b39e8ff2cd380fc6c` | 【通过】 |
| Web 文件集合 | `build/web` 有序文件哈希集合 SHA-256 `0359003c0e09ba37a5985a35fcd70d7efd28cef79ffe8e04e0a99fc6744795b2` | 【通过】 |
| 源码版本身份 | 工作区没有 `.git` 元数据，无法把本地证据绑定到 commit SHA | 【阻塞】 |
| Android 与真实浏览器 | 本轮未执行 | 【未覆盖】 |

源码身份阻塞不否定本次本地测试结果，但发布前必须由主 PM 把报告绑定到可追溯的仓库、分支或提交。

## 命令执行结果

| 命令 | 退出码 | 实际结果 | 状态 |
| :--- | :----: | :------- | :--- |
| `FLUTTER_BIN=… make check-format` | 0 | 70 个文件无格式变化 | 【通过】 |
| `flutter test test/features/cards/card_stage2a_qa_test.dart test/architecture/stage2a_source_contract_test.dart test/widget/app_button_token_test.dart` | 0 | QA 新增 9 项全部通过 | 【通过】 |
| `flutter test test/features/cards test/features/home test/architecture/tool_registry_test.dart test/architecture/tool_session_adapter_test.dart test/architecture/stage2a_source_contract_test.dart test/widget/app_button_test.dart test/widget/app_button_token_test.dart test/widget/system_feedback_service_test.dart` | 0 | 扑克、首页、adapter、共享按钮和反馈的 59 项定向回归全部通过 | 【通过】 |
| `FLUTTER_BIN=… make verify` | 0 | 格式检查通过、analyze 无问题、112 项测试通过、Web 构建完成 | 【通过】 |
| `flutter --version` | 0 | Flutter 3.47.1、Dart 3.13.1 | 【通过】 |
| `FLUTTER_BIN=… make build-web` | 0 | Wasm dry run 成功并生成 `build/web` | 【通过】 |
| `shasum -a 256 build/web/main.dart.js` | 0 | 得到本文记录的主产物哈希 | 【通过】 |
| `find … build/web … \| shasum -a 256` | 0 | 得到本文记录的有序文件集合哈希 | 【通过】 |

表中的 `…` 均指『环境与证据身份』记录的 Flutter 绝对路径，不代表命令未经确认。`make verify` 已包含一次 Web 构建；独立的 `make build-web` 是第二次构建证据。

## 独立增量测试

QA 新增以下 9 项测试，未删除或放宽开发已有用例：

- `test/features/cards/card_stage2a_qa_test.dart` 新增 6 项：52/54 边界与顺序、非法 n 零随机调用、adapter 脱敏、保存提交门禁、跳过与页面隐藏恢复、动画中路由离开恢复。
- `test/architecture/stage2a_source_contract_test.dart` 新增 2 项：首页仅从 registry 顺序渲染五工具且无 ID 分支；扑克展示层禁止直接平台振动/随机 API 及受限制 magic style。
- `test/widget/app_button_token_test.dart` 新增 1 项：覆盖共享 motion token 后，`AppButton` 的按压轨迹统一变化且最小目标仍不小于 48 px。

开发已有的固定向量、codec、减少动态效果、父会话、360 px/200% 字体、共享语义主题、fake module 和平台 feedback 用例均参与完整回归，没有被替换为较弱断言。

## 扑克规则验收

| 场景 | 独立断言 | 结果 |
| :--- | :------- | :--- |
| 默认牌组 | `includeJokers=false`、52 张、无 Joker | 【通过】 |
| 显式 Joker | `includeJokers=true`、54 张、同时包含小王和大王 | 【通过】 |
| n 下界 | 52/54 牌组均覆盖 `n=1` | 【通过】 |
| n 上界 | 覆盖 52 张与 54 张完整牌组，剩余数为 0 | 【通过】 |
| 非法 n | `-1`、`0`、52 牌组的 `53`、54 牌组的 `55` 均拒绝，随机调用计数保持 0 | 【通过】 |
| 无放回 | 抽取 ID 集合大小等于抽取数，完整牌组无重复 | 【通过】 |
| 顺序 | 固定随机向量得到明确稳定顺序，codec、历史摘要和分享不重新排序 | 【通过】 |
| remaining | 始终等于当前牌组大小减抽取数；错误 payload 由既有 codec 测试拒绝 | 【通过】 |
| 不可变 | 抽取结果列表不可修改；重抽保留原记录 | 【通过】 |
| 随机失败 | 规则层失败不暴露部分牌组，页面不使用普通随机回退 | 【通过】 |

## 冻结、动画与恢复验收

| 场景 | 证据 | 结果 |
| :--- | :--- | :--- |
| 保存提交门禁 | 存储 Future 未提交时只显示输入已冻结，不进入洗牌/揭示；提交后才开始动画与反馈 | 【通过】 |
| 跳过动画 | 直接展示同一已保存 session，仓库记录对象不变，随机调用不增加 | 【通过】 |
| 减少动态效果 | 使用同一冻结结果进入 reduced 状态，重抽前不再次调用随机 | 【通过】 |
| 页面隐藏 | 合法 lifecycle 序列进入 hidden 后直接完成同一 session；恢复后结果与随机计数不变 | 【通过】 |
| 路由离开 | 动画中离开到首页再进入扑克，恢复相同三张牌且随机调用保持 51 次 | 【通过】 |
| 重新抽取 | 第二条 session 使用独立 ID，`parentSessionId` 指向第一条，第一条记录不变 | 【通过】 |
| 浏览器刷新/进程重启 | 当前为内存仓库，未执行刷新、浏览器关闭或应用进程重启 | 【未覆盖】 |

## 会话、历史与分享验收

- `CardToolModule` 通过自定义 `ToolSessionAdapter` 提供 codec、历史摘要和有序分享 renderer；`ToolRegistry.historySummary` 与 `ToolRegistry.sharePayload` 是本轮实际调用入口。【通过】
- 历史摘要只输出工具与抽取数量；分享文本输出牌组摘要、有序牌、剩余数、规则版本和算法版本。【通过】
- 对抗 payload 额外放入问题、备注、设备、精确时间、本地 ID、父 ID 和分析 ID，历史摘要及分享文本均未出现这些值。【通过】
- `HistoryPage` 当前明确显示持久化将在后续阶段接入，扑克结果页没有复制或分享预览按钮；真实列表、详情、字段勾选、平台分享、取消与失败降级没有执行。【未覆盖】

## 首页与共享架构验收

- 默认 registry 恰好包含五个模块，稳定顺序为 `tarot`、`liuyao`、`d20`、`coin`、`cards`；首页实际渲染五张 `AppToolCard`。【通过】
- 首页通过 `for (final module in registry.modules)` 渲染；首页和 shell 没有按工具 ID 的 `if` 或 `switch`，也没有五个工具 ID 字面量分支。【通过】
- fake module 仍能在不修改 shell 的情况下被发现、导航并使用默认或自定义 session adapter；重复 ID、重复 route 和 adapter/codec 错配仍被拒绝。【通过】
- 扑克页面组合 `AppToolScaffold`、`AppButton`、`AppStepper`、`AppGenerationStateView` 和共享 surfaces；展示层未直接导入 `flutter/services.dart`、调用 haptics/method channel 或创建安全随机实现。【通过】
- 扑克展示层没有直接 `Color`、`Duration`、数字圆角、数字 EdgeInsets 或数字 SizedBox 尺寸；按钮行为由共享 token 控制。【通过】
- 塔罗、六爻与硬币当前仍是明确的未实现模块，不因首页出现五张卡而算核心流程通过。【未覆盖】

## 生产缺陷与覆盖缺口

本轮最终证据未发现 Stage 2A 扑克规则、冻结恢复、首页 registry 或共享组件范围内的生产缺陷。【通过】

以下是后续阶段和发布门禁缺口，不是本轮伪装为通过的能力：

- 真实历史列表、历史详情、持久化仓库、复制与分享预览尚未接入；FR-031、FR-037～FR-039 与 FR-049 的完整 UI 验收不能关闭。【未覆盖】
- Android SDK、设备安装、真实 haptics、Web 浏览器 vibration capability/no-op、真实页面刷新、进程重启与跨端固定向量对比未执行；NFR-001、NFR-006、NFR-018～NFR-020 不能完整关闭。【未覆盖】
- 断网启动、请求观测、日志扫描、牌面/字体/商店与分享资产许可审查未执行；NFR-009、NFR-010、NFR-014、NFR-021 不能关闭。【未覆盖】
- 工作区没有 Git 身份；本地 Web 哈希不能替代源码 commit、签名、分发与回退证据。【阻塞】

任一上述 P0 在发布前仍无实际证据时，独立 QA 将阻止发布；它们不阻止当前 Stage 2A 代码进入后续实现阶段。

## 需求覆盖矩阵

本矩阵按完整需求判断；“部分通过”表示本轮子契约有实际证据，但不足以关闭整条需求。

| 需求 ID | 本轮状态 | Stage 2A 证据与边界 |
| :------ | :------- | :----------------- |
| FR-001 | 【部分通过】 | 首页从 registry 按稳定顺序展示五模块且扑克可进入；三项未实现工具不计为可完成核心流程 |
| FR-003 | 【通过】 | 扑克配置、规则/算法版本与结果冻结；重抽独立 ID 并关联父会话 |
| FR-004 | 【部分通过】 | 保存后动画、跳过、隐藏和路由恢复不重抽；浏览器刷新与进程恢复未覆盖 |
| FR-005 | 【部分通过】 | 扑克摘要、过程、规则版本与重抽存在；备注、复制和分享 UI 未实现 |
| FR-031 | 【部分通过】 | adapter 历史摘要脱敏通过；真实本地历史列表未实现 |
| FR-037 | 【部分通过】 | adapter 默认分享文本脱敏通过；复制和分享预览未实现 |
| FR-038、FR-039 | 【未覆盖】 | 私人字段选择、平台分享和失败回退未实现 |
| FR-041 | 【部分通过】 | 扑克减少动态效果结果不变；五工具完整范围未覆盖 |
| FR-048 | 【通过】 | 入口、默认 52、显式 54、n 边界、非法零随机、无放回、有序且唯一 |
| FR-049 | 【部分通过】 | 冻结牌组/牌序/剩余数、父会话、adapter 历史/分享语义通过；真实历史/分享 UI 与双端运行未覆盖 |
| FR-052 | 【部分通过】 | 扑克按压/洗牌/抽牌/完成/减少动态及冻结顺序通过；其余工具和真实平台反馈未覆盖 |
| NFR-001 | 【部分通过】 | 纯规则固定向量与 Web 构建通过；Android/Web 运行时对比未执行 |
| NFR-002 | 【通过】 | 扑克通过注入随机接口；随机失败不返回部分结果，展示层无随机旁路 |
| NFR-003 | 【部分通过】 | 无偏整数与 Fisher–Yates 边界、固定序通过；扑克统计检验未执行 |
| NFR-004 | 【通过】 | 固定随机序列、规则版本、算法版本与 codec 顺序可复查 |
| NFR-006 | 【部分通过】 | 跳过、隐藏、路由离开恢复通过；刷新、应用被杀和浏览器恢复未覆盖 |
| NFR-007、NFR-008 | 【部分通过】 | 扑克语义、共享 48 px 控件、360 px 和 200% 字体通过；完整设备/键盘/读屏矩阵未执行 |
| NFR-010、NFR-011 | 【部分通过】 | 分享 renderer 字段脱敏及 n 白名单通过；抓包、日志、完整载荷和表达式范围未覆盖 |
| NFR-012 | 【部分通过】 | 扑克 schema-v1 52/54 兼容与严格 codec 校验继续通过；完整迁移/隔离未覆盖 |
| NFR-016 | 【通过】 | domain 与 presentation 分层；扑克动画/展示不直接访问随机源或平台 channel |
| NFR-017 | 【部分通过】 | Stage 2A 正常、边界、异常、恢复、无障碍和架构测试有 ID 证据；跨端与兼容矩阵未完成 |
| NFR-018 | 【部分通过】 | 系统反馈 Android 映射、非支持平台 no-op 与关闭反馈测试通过；真实平台未执行 |
| NFR-019 | 【部分通过】 | 结果先冻结，减少动态、关闭反馈、页面隐藏和路由恢复不重抽；真实后台/读屏未执行 |
| NFR-020 | 【部分通过】 | 52/54、固定序、全牌组、无重复、remaining 和重抽新会话通过；Android/Web 运行时与离线未执行 |
| NFR-021 | 【部分通过】 | 当前扑克 UI 使用抽象标准花色与共享图标，未发现直接赌场 API/文案；发布资产与许可清单未审查 |
| NFR-022 | 【通过】 | 首页和 shell 仅消费 registry/module 协议；fake module 无需 shell 分支 |
| NFR-023 | 【部分通过】 | 统一 envelope、codec、registry adapter、历史摘要与分享 renderer 通过；真实历史/分享页面未接入 |
| NFR-024 | 【通过】 | 扑克使用共享组件/token；单点 motion token 改变 `AppButton`，静态扫描阻止散落公共样式 |
| REL-003 | 【部分通过】 | 本报告建立 Stage 2A ID 到测试证据映射；没有 commit 身份 |
| REL-005 | 【部分通过】 | 规则、固定向量、恢复和局部无障碍通过；统计、离线、真实跨端、隐私和兼容未收口 |
| REL-007、REL-008 | 【部分通过】 | 规则/算法版本与 Web 哈希可查；源码身份、签名、分发和回退未覆盖 |
| REL-011 | 【部分通过】 | 当前 `make verify` 与 `make build-web` 实际通过，Makefile 契约测试通过；CI 同入口证据不在本轮范围 |
| REL-013 | 【通过】 | registry、fake module、统一 session adapter、随机边界、共享 UI/token 与静态依赖门禁通过 |

## 阶段准入结论

Stage 2A 的扑克规则、冻结动画、局部恢复、adapter 契约、五工具首页和共享架构没有剩余自动化失败，允许进入后续开发阶段。【有条件通过 Stage 2A；准入后续阶段】

该结论不等于 v0.1.0 发布准入，也不关闭真实历史/分享、持久化、离线、Android、浏览器运行时、全五工具反馈与恢复。后续实现完成后，QA 必须至少实际执行：

- Android 与 Web 的同输入、同固定随机向量结构化结果对比。
- Android 构建、安装、前后台/进程恢复与 haptics 开关测试。
- Web 浏览器刷新、页面隐藏、vibration capability/no-op 与断网流程。
- 持久化历史、详情、复制、分享预览、字段选择、平台失败回退和隐私抓包/日志扫描。
- `make verify`、Web/Android 发布构建、产物哈希、源码 commit 与签名/回退证据绑定。

上述任一 P0 出现失败、隐私泄露、随机重抽、冻结结果改变、历史丢失或缺少实际证据时，必须由主 PM 退回开发并阻止发布。

# Pocketools v0.1.0 Stage 2B2 塔罗独立 QA 结果

- **执行日期**：2026-08-23。
- **执行角色**：独立 QA；开发自测和主 PM 复跑只作为交叉信息，不替代本文的独立命令证据。
- **验收范围**：塔罗 78 张牌、牌阵与逆位规则、内容和许可边界、codec、冻结与恢复、历史/分享 adapter、共享架构、响应式、无障碍、Web 构建。
- **Stage 2B2 结论**：【PASS；塔罗范围准入后续阶段】。
- **仓库全门禁结论**：【PASS；稳定快照 `make verify` 退出码 0】。
- **审计链**：初跑 46/47，发现 1 缺陷；修复后 48/48。缺陷为减少动态完成态仍残留牌背。并行六爻写入中间态曾使全门禁失败，稳定快照最终为 235/235 并完成 Web 构建。
- **平台边界**：Web 构建通过；Android 按任务约定不在本阶段重建。
- **修改边界**：QA 仅新增两个塔罗测试文件、一个必要架构测试和本文档；未修改 `lib/**`、Makefile、pubspec 或 PM/UX 文档。

## TL;DR

- 完整 78 张牌的稳定 ID/index 快照、22 张大牌、四花色各 14 张、无重复/漏牌和全部解释字段获得独立自动化证据。【通过】
- 今日一牌、单牌问答和过去/现在/未来三牌阵在 192 组性质样本中保持固定位置、无放回和稳定随机调用边界；关闭逆位恰好消费 77 次洗牌熵，开启时每张牌再独立消费一次 `nextInt(2)`。【通过】
- codec 对未知牌、重复牌、非法顺序/位置/方向/contentVersion、非字符串键和标量类型污染严格拒绝；缺少 nullable `intention` 的 schema-v1 样本可恢复同一 session。【通过】
- 内容元数据声明 `Pocketools original`，未引用外部现代释义或运行时牌图；静态禁语检查未发现确定性预测、准确率承诺或医疗/法律/财务结论，高风险通用提示在结果中可见。【通过】
- 保存提交前无揭示和反馈；随机/存储失败不伪造结果；逐张、一次揭示、跳过、页面隐藏、路由离开和计时器销毁均不增加随机调用。【通过】
- 初跑发现减少动态完成态仍残留一张 `TarotCardBack`。第一次修正只加 `!reducedMotion` 仍因 phase 切换失败；第二次把页面参数绑定到持久的 `moduleContext.reduceMotion` 后，原用例和完整定向回归均通过。【通过】
- 历史摘要和分享文本经 `ToolRegistry → ToolSessionAdapter`，保留牌序、位置、方向和版本，排除问题/备注文本、本地 session ID 和 parentSessionId；关联重抽不复制私人文本。【通过】
- 360 × 800、200% 字体、48 px 按钮、三牌语义和键盘有序揭示通过；真实屏幕阅读器、真实浏览器焦点和 Android 设备仍不在本轮证据内。【部分通过】
- 并行六爻写入中间态的 `make verify` 曾在 223 项通过后被旧导航断言阻断；旧断言迁移到真实六爻页后，独立重跑格式、analyze、235 项测试和目标内 Web build 全部完成。【通过】

## 环境与证据身份

| 项目 | 实际值 | 状态 |
| :--- | :----- | :--- |
| 工作区 | `.` | 【通过】 |
| Flutter | Flutter 3.47.1 stable，revision `6655482ec0` | 【通过】 |
| Dart | Dart 3.13.1 | 【通过】 |
| 初始塔罗目录 | 46/47；1 项减少动态对抗测试失败 | 【失败】 |
| 修复后塔罗目录 | 48/48 | 【通过】 |
| 修复后塔罗与架构定向集 | 51/51 | 【通过】 |
| QA 新增测试 | 20 项：规则/codec/隐私 10 项、widget 7 项、架构 3 项 | 【通过】 |
| 全仓 `make verify` | 稳定快照格式、analyze、235/235 测试和 Web 构建全部完成，退出码 0 | 【通过】 |
| Web 主产物 | `build/web/main.dart.js`，SHA-256 `50cb1b0c661e78b1c02b4ab1346e75f8cd6d1b48c0ddae7ceb3eebd6effcd46b` | 【通过】 |
| Web 文件集合 | 39 个文件、40 MB；有序文件哈希集合 SHA-256 `0515aeffb713a1b2c91521eb816a86558e5d804e0985c9b59479be5c53a0a06c` | 【通过】 |
| 源码版本身份 | 工作区没有 `.git` 元数据，无法将证据绑定到 commit SHA | 【阻塞】 |
| Android | 本阶段不重建，由主 PM 的平台流程另行验证 | 【未执行】 |
| 真实 Web 浏览器 | 本轮验证生产构建，未执行浏览器运行时、刷新、离线和读屏矩阵 | 【未覆盖】 |

源码身份阻塞不否定本次本地规则和 UI 结果，但发布前必须把源码、报告、Web/Android 产物、签名与回退证据绑定到同一可追溯版本。

## 开发自测与独立 QA 边界

- 主 PM 同步的修复后结果为 `flutter test test/features/tarot` 48/48；本文不把该结果当作 QA 命令证据。【交叉信息】
- 独立 QA 实际复跑原失败精确用例 1/1，并复跑塔罗目录和独立架构门禁 51/51。【通过】
- 独立 QA 保留并行六爻中间态旧导航断言导致非零退出的记录，并在稳定快照重新取得 `make verify` 退出码 0。【通过】
- 独立 QA 未修改任何生产代码；本文对修复的判断来自修复前后同一失败用例、生产源码只读审查和完整定向回归。【通过】

## 命令执行结果

| 命令 | 退出码 | 实际结果 | 状态 |
| :--- | :----: | :------- | :--- |
| `flutter test test/features/tarot/tarot_stage2b2_widget_qa_test.dart --plain-name 'reduced motion never leaves a card in the flip animation'`，修复前 | 1 | 完成态仍找到 1 个 `TarotCardBack` | 【失败】 |
| 同一精确命令，第一次开发修正后 | 1 | `!reducedMotion` 因 phase 从 reduced 切到 completed 后失效，仍找到 1 个 `TarotCardBack` | 【失败】 |
| 同一精确命令，第二次开发修正后 | 0 | 1/1 通过，完成态不再残留牌背或卡牌翻转 | 【通过】 |
| `flutter test test/features/tarot test/architecture/tarot_stage2b2_contract_test.dart`，修复前 | 1 | 50 项通过、1 项减少动态失败 | 【失败】 |
| 同一定向命令，修复后 | 0 | 51/51 全部通过 | 【通过】 |
| `dart format --output=none --set-exit-if-changed test/features/tarot test/architecture/tarot_stage2b2_contract_test.dart` | 0 | 10 个目标 Dart 文件无格式变化 | 【通过】 |
| `flutter analyze test/features/tarot test/architecture/tarot_stage2b2_contract_test.dart` | 0 | 0 issue | 【通过】 |
| `FLUTTER_BIN=… make verify`，并行中间态 | 2 | 124 个 Dart 文件格式通过，analyze 无问题；223 项通过后，`navigation_accessibility_test.dart` 的六爻旧占位断言失败，目标未进入 Web build | 【失败】 |
| `FLUTTER_BIN=flutter make verify`，稳定快照 | 0 | 126 个 Dart 文件格式无变化，analyze 无问题，235/235 测试通过，目标内 Web build 成功 | 【通过】 |
| `FLUTTER_BIN=… make build-web` | 0 | Wasm dry run 成功，生成 `build/web` | 【通过】 |
| `shasum -a 256 build/web/main.dart.js` | 0 | 得到本文记录的主产物哈希 | 【通过】 |
| `find build/web … \| shasum -a 256` | 0 | 得到 39 文件有序集合哈希 | 【通过】 |
| `flutter --version` | 0 | Flutter 3.47.1、Dart 3.13.1 | 【通过】 |

表中的 `flutter` 均指『环境与证据身份』记录的绝对路径；`…` 只缩写相同的 `FLUTTER_BIN` 绝对值。Android 命令未执行。

## 独立增量测试

QA 新增 20 项测试，没有删除或放宽开发已有 31 项塔罗测试：

- `tarot_stage2b2_qa_test.dart` 共 10 项，覆盖完整 78 张稳定身份快照、内容不可变、192 组规则性质样本、单牌预设、随机失败、codec 污染、legacy nullable 字段、adapter 脱敏和内容禁语。
- `tarot_stage2b2_widget_qa_test.dart` 共 7 项，覆盖真实 commit gate、存储失败、随机失败、错峰 timer 销毁、减少动态最小缺陷、360 px/200% 和键盘有序揭示。
- `tarot_stage2b2_contract_test.dart` 共 3 项，覆盖 Registry/Module/Adapter、共享组件与 token、随机/触觉/运行时牌图旁路，以及 domain/content 依赖方向。

开发已有 31 项塔罗测试在修复后全部保留并通过；48 项塔罗目录结果等于 31 项既有测试加 17 项 QA 塔罗测试，另有 3 项 QA 架构测试组成 51 项定向集。

## 牌组、内容与规则验收

| 场景 | 独立断言 | 结果 |
| :--- | :------- | :--- |
| 完整牌组 | 78 张，22 张大牌，权杖/圣杯/宝剑/星币各 14 张 | 【通过】 |
| 稳定身份 | 78 个 ID 使用完整字面快照；index 连续为 0～77；`byId` 指向同一不可变实例 | 【通过】 |
| 无重复漏牌 | ID、名称、index 唯一；四花色十四 rank 完整 | 【通过】 |
| 内容字段 | 每张正逆位关键词至少 3 个，传统象征、正逆位解释和 1～3 个反思问题均非空 | 【通过】 |
| 位置解释 | 全 78 张 × 5 位置 × 2 方向均有非空位置解释，长度不超过 120 字 | 【通过】 |
| 今日一牌 | 固定向量只抽 1 张并绑定 `dailyGuidance` | 【通过】 |
| 单牌问答 | 固定向量只抽 1 张并绑定 `coreMessage` | 【通过】 |
| 三牌阵 | 恰好 3 张不同牌，位置严格为 past/present/future | 【通过】 |
| 无放回性质 | 三个牌阵、逆位开/关、32 个种子共 192 组样本均无重复且位置不漂移 | 【通过】 |
| 默认逆位 | `TarotReadingConfig` 默认开启逆位 | 【通过】 |
| 关闭逆位 | Fisher–Yates 恰好请求 `78…2` 共 77 次，不请求任何方向值，全部 upright | 【通过】 |
| 开启逆位 | 洗牌后每张牌独立追加一次 `nextInt(2)`；单牌 78 次、三牌 80 次 | 【通过】 |
| 固定向量 | 全零洗牌后按魔术师、女祭司、女皇的稳定顺序和给定方向返回 | 【通过】 |
| 随机失败 | 在洗牌首、中、末和方向阶段注入失败均抛错，不返回部分或伪造结果 | 【通过】 |
| 不可变 | 牌组、内容 map/list 和结果 cards 均不能原地修改 | 【通过】 |

## Codec、恢复与版本验收

- 输入 codec 严格校验 spread、useReversals、revealMode、intention、drawCount 和 positions 的键集合、类型、长度与内部一致性。【通过】
- outcome codec 拒绝未知牌 ID、重复牌、错误 sequence、错误/未知 position、未知 orientation、关闭逆位时伪造 reversed、额外键、缺失键和非字符串 map key。【通过】
- contentVersion 拒绝 null、数字、空串、含空格和超过 64 字符的样本；合法 `1.0.0` 保留。【通过】
- 缺少 nullable `intention` 的 schema-v1 输入按 null 恢复；两次 decode 不改变 session ID、parentSessionId、牌 ID 或 envelope。【通过】
- 规则版本 `tarot-reading/1.0.0`、算法版本 `random-unbiased-fisher-yates-binary/1.0.0` 和内容版本 `1.0.0` 在 session、摘要和过程详情中可追溯。【通过】
- 未知 schemaVersion 的迁移/隔离和多内容版本并存不在当前 codec 实现范围，本轮不伪装为已通过。【未覆盖】

## 内容来源、许可与安全边界

- 内容包元数据为 `pocketools.tarot.zh-Hans.original`、作者 `Pocketools`、来源 `Pocketools original`、schema 1、locale `zh-Hans`、版本 `1.0.0`。【通过】
- 全量内容扫描未发现 URL、外部牌系名、逐字翻译/摘录声明、准确率、保证结果、必然事件承诺、医疗诊断、法律结论或买卖建议。【通过】
- 三牌组合提示明确是观察线索，不表示必然事件或确定预测；位置解释不把未来写成已注定事实。【通过】
- 结果持续展示文化娱乐/自我反思免责声明，以及医疗、法律、财务、人身安全的通用提示和“不上传问题文本”说明。【通过】
- 【v0.1.0 历史快照】presentation 使用代码绘制的抽象牌面；该结论已由 v0.1.1 运行时资产增量 supersede。当前牌面走共享 `RuntimeAssetSlot` 和本地 RWS manifest，旧“无活动 runtime assets”断言不再适用。
- 当前许可证字段仍为 `Apache-2.0 candidate`，licenseStatus 明示发布前需最终许可复核；这满足候选边界透明性，但不等于最终发布许可已经关闭。【阻塞】
- `docs/licensing.md` 仍将塔罗释义实际来源与授权范围列为待确认；发布负责人必须在 release gate 前闭环，Stage 2B2 通过不能覆盖该治理阻塞。【阻塞】

## 冻结、动画、反馈与恢复验收

| 场景 | 证据 | 结果 |
| :--- | :--- | :--- |
| 真实 commit gate | repository 已收到但 Future 未提交时，无牌面、跳过按钮或反馈；提交后才进入动画 | 【通过】 |
| 存储失败 | 已消费的随机结果不展示、不动画、不发反馈，错误明确，等待两秒无陈旧事件 | 【通过】 |
| 随机失败 | 不创建 session，不展示占位牌或重抽按钮 | 【通过】 |
| 逐张揭示 | 只允许 past → present → future；键盘焦点保留在共享揭示按钮，80 次随机调用不增加 | 【通过】 |
| 一次揭示 | 按冻结结果错峰展示，销毁页面后 child timers 全部取消 | 【通过】 |
| 跳过 | 直接显示同一已保存结果，取消后续动画/反馈，不增加随机调用 | 【通过】 |
| 页面隐藏 | 保存中隐藏和已保存后隐藏均恢复同一结果，不补发反馈 | 【通过】 |
| 路由离开 | 动画中离开再进入恢复同一 shell session，不重新洗牌或取方向值 | 【通过】 |
| 关联重抽 | 创建新 ID，parentSessionId 指向原 session，原记录不变，新 session 的 intention 为 null | 【通过】 |
| 减少动态初跑 | 状态已完成后仍残留 1 个牌背并继续 480 ms 卡牌翻转 | 【失败】 |
| 减少动态复测 | `moduleContext.reduceMotion` 在 completed phase 仍传入结果组件；无 `TarotCardBack`，同一结果立即可读 | 【通过】 |
| 浏览器刷新/进程重启 | 当前 repository 为内存实现，本轮未执行真实刷新、浏览器关闭或应用进程恢复 | 【未覆盖】 |

## 缺陷审计链

### QA-S2B2-001 减少动态完成态仍播放最后一张翻牌

- **严重度**：P0 发布阻断；对应 FR-041、FR-052、NFR-019 和 REL-005 的核心可访问性合同。
- **初始结果**：`flutter test test/features/tarot` 为 46/47；最小用例期望 0 个 `TarotCardBack`，实际找到 1 个。
- **最小复现**：启用减少动态，选择三牌逐张模式并生成；等待 80 ms reduced 淡入完成；页面已显示“牌阵与原创解释已完成”，但最后一张仍为牌背并继续 480 ms 翻牌。
- **数据影响**：牌、方向和 80 次随机调用均未变化；缺陷影响减少动态、即时可读语义和完成态一致性，不是随机规则错误。
- **根因**：结果卡的 sequential `animate` 条件未排除减少动态；第一次修正加入 `!reducedMotion` 后，页面又在 phase 从 reduced 切到 completed 时把 reducedMotion 传回 false。
- **最终修正审查**：结果卡动画条件包含 `!reducedMotion`；页面传入 `widget.moduleContext.reduceMotion || phase == reduced`，使用户设置在 completed phase 仍持续生效。
- **复测结果**：原用例 1/1、塔罗目录 48/48、塔罗加架构定向集 51/51 均通过。【关闭】

## 历史、分享与隐私验收

- `TarotToolModule` 实现 `ToolModule` 与 `ToolSessionAdapterProvider`，会话创建、decode、历史摘要和分享 payload 均走统一 adapter。【通过】
- 历史和分享保留牌阵、牌面顺序、位置、方向、关键词、解释、内容来源、规则版本与算法版本。【通过】
- 使用唯一标记验证问题/备注文本、本地 session ID 和 parentSessionId 默认不进入 history summary、share summary 或 share plainText。【通过】
- 关联重抽继承牌阵、逆位和揭示方式，但显式删除 intention，不复制私人问题/备注。【通过】
- 真实 HistoryPage、持久化详情、分享预览、平台分享取消/失败和字段勾选仍未在 Stage 2B2 接入或执行；adapter 通过不能替代完整 UI 验收。【未覆盖】
- 本轮未发现网络依赖或远程牌图调用，但未执行抓包、运行日志和分析事件白名单检查。【未覆盖】

## UI、无障碍与共享架构验收

- 360 × 800、200% 字体下完成三牌结果，免责声明、安全提示和重抽按钮均可纵向滚动到达，无 Flutter overflow。【通过】
- 抽牌和重抽的实际控件高度不小于 48 px；三张牌分别提供位置、牌名、方向和经典 Rider–Waite–Smith 牌面语义。【v0.1.1 更新】
- 未揭示牌不提前读出牌名；键盘可按顺序揭示三张牌，焦点在前两次揭示后保持于共享操作按钮，随机调用不增加。【通过】
- 页面复用 `AppToolScaffold`、`AppButton`、choice/segmented control、generation state、section card、tool theme 和共享 token。【通过】
- 塔罗 domain/content 不依赖 Flutter 或 presentation；展示层无私有 `Random`、安全随机实例、直接 `HapticFeedback`、method channel 或系统 channel。【通过】
- 首页通过默认 registry 注册一个 TarotToolModule；shell 不包含 Tarot 工具 ID 分支，模块通过统一 session adapter 创建 envelope。【通过】
- 真实 TalkBack/VoiceOver、浏览器屏幕阅读器、完整 Tab/Shift+Tab 顺序、路由标题焦点和 Android haptics 未执行。【未覆盖】

## Makefile 与 Web 构建验收

- 并行六爻写入中间态的全量测试实际运行到 223 项通过后，旧 `navigation_accessibility_test.dart` 仍期待未开放占位页，导致 `make verify` 非零且没有进入目标内 Web build。【历史失败】
- 六爻开发稳定后，旧断言已迁移为真实六爻页断言；QA 从头独立重跑同一命令，check-format 检查 126 个 Dart 文件且 0 个变化，analyze 为 0 issue，测试 235/235 通过。【通过】
- 稳定快照的 `verify` 随后执行了目标内 Web build，Wasm dry run 和标准 Web 编译成功，命令总退出码为 0。【通过】
- 最终 `build/web/main.dart.js` SHA-256 为 `50cb1b0c661e78b1c02b4ab1346e75f8cd6d1b48c0ddae7ceb3eebd6effcd46b`；39 个文件按路径排序后逐文件哈希再汇总的 SHA-256 为 `0515aeffb713a1b2c91521eb816a86558e5d804e0985c9b59479be5c53a0a06c`。【通过】
- 中间态失败作为并行开发审计证据保留，但不再代表当前稳定快照的仓库门禁状态。【通过】

## 需求覆盖矩阵

“部分通过”表示 Stage 2B2 子合同已有实际证据，但整条跨工具、跨端或发布需求尚未关闭。

| 需求 ID | 本轮状态 | Stage 2B2 证据与边界 |
| :------ | :------- | :------------------ |
| FR-003 | 【通过】 | 塔罗配置、规则/算法/内容版本和结果冻结；重抽独立 ID 并关联父 session |
| FR-004 | 【部分通过】 | 保存门禁、重复操作、隐藏、跳过和路由恢复不重抽；刷新/进程恢复未覆盖 |
| FR-005 | 【部分通过】 | 结果摘要、过程、规则和重抽存在；保存备注、复制和分享 UI 未接入 |
| FR-006 | 【通过】 | 78 张、22 大牌、四花色 × 14、稳定 ID/index 和不可变牌组 |
| FR-007 | 【通过】 | 今日一牌与单牌问答均恰好 1 张且位置语义不同 |
| FR-008 | 【通过】 | 三牌无重复，严格 past/present/future |
| FR-009 | 【通过】 | 默认开启；关闭时 77 次洗牌且零方向熵，开启时逐牌独立二值熵 |
| FR-010 | 【通过】 | Fisher–Yates 无放回、逐张/一次/跳过和冻结结果一致 |
| FR-011 | 【部分通过】 | 全 78 张内容字段与来源完整；损坏内容包替身/降级未注入 |
| FR-012 | 【部分通过】 | 禁语扫描、免责声明和高风险提示通过；真实网络/日志未观测 |
| FR-031、FR-037 | 【部分通过】 | adapter 历史/分享语义与脱敏通过；真实 UI 未接入 |
| FR-041 | 【通过】 | 初始缺陷已修复；减少动态完成态无翻牌且结果不变 |
| FR-045 | 【部分通过】 | 通用高风险提示可见且内容不解释原文；抓包未执行 |
| FR-046 | 【部分通过】 | 随机/存储失败不伪结果；内容损坏和平台分享失败未完整执行 |
| FR-050 | 【通过】 | 关键词、传统象征、方向差异、位置解释、反思、组合提示、来源和边界齐全 |
| FR-052 | 【部分通过】 | 塔罗按压/冻结/揭示/完成/减少动态通过；五工具完整范围不由本报告关闭 |
| NFR-001 | 【部分通过】 | 纯规则固定向量和 Web 构建通过；Android/Web 运行时对比未执行 |
| NFR-002 | 【通过】 | 塔罗只消费注入的统一 RandomSource；失败不使用普通随机降级 |
| NFR-003 | 【部分通过】 | Fisher–Yates 调用边界和 192 组性质样本通过；独立统计频数检验未执行 |
| NFR-004 | 【通过】 | 固定向量及规则、算法、内容版本可复查 |
| NFR-006 | 【部分通过】 | 隐藏、跳过和路由恢复通过；刷新、浏览器/进程恢复未覆盖 |
| NFR-007、NFR-008 | 【部分通过】 | 48 px、语义、键盘、360 px 和 200% 通过；真实设备/读屏矩阵未执行 |
| NFR-009 | 【部分通过】 | 规则、内容和牌面无网络依赖；真实断网启动未执行 |
| NFR-010、NFR-014 | 【部分通过】 | 分享字段脱敏通过；抓包、日志和分析事件未执行 |
| NFR-011 | 【通过】 | codec 键集合、长度和类型白名单攻击测试通过 |
| NFR-012 | 【部分通过】 | schema-v1 nullable 字段兼容通过；未知 schema 隔离/迁移未覆盖 |
| NFR-015 | 【部分通过】 | 作者/版本/来源/许可/schema 元数据存在；最终许可仍为 candidate |
| NFR-016 | 【通过】 | domain/content/presentation 边界与动画随机旁路静态门禁通过 |
| NFR-017 | 【部分通过】 | 正常、边界、异常、恢复、无障碍和架构证据齐全；跨端矩阵未完成 |
| NFR-018 | 【部分通过】 | 共享 feedback 注入、关闭反馈和页面可见性路径通过；真实平台未执行 |
| NFR-019 | 【通过】 | 原 reduced-motion 缺陷已关闭；动画、隐藏、路由和 timer 不改结果 |
| NFR-022、NFR-023、NFR-024 | 【通过】 | Module/Registry/Adapter、统一 session/random/share 和共享 UI/token 门禁通过 |
| REL-003 | 【部分通过】 | 本报告建立 ID 到测试/构建证据映射；缺少 commit 身份 |
| REL-005 | 【部分通过】 | 塔罗规则、固定向量、恢复和局部无障碍通过；发布全矩阵未关闭 |
| REL-007、REL-008 | 【部分通过】 | 版本和 Web 哈希可查；源码身份、签名、分发和回退未覆盖 |
| REL-011 | 【通过】 | 稳定快照 `make verify` 退出码 0，235/235 测试与目标内 Web 构建完成；并行中间态失败已保留审计 |
| REL-013 | 【通过】 | Registry、统一 adapter、随机边界、共享 UI/token 和依赖方向门禁通过 |

## 阶段准入结论

Stage 2B2 塔罗范围的牌组、规则、内容、codec、冻结、恢复、adapter、共享架构、响应式和 Web 构建在生产修复后没有剩余定向失败；原 P0 减少动态缺陷已由同一最小用例关闭。【PASS；塔罗范围准入后续阶段】

并行 Stage 2C 写入中间态曾因旧导航测试仍期待占位页而使 `make verify` 非零；该历史失败不被删除。六爻稳定且断言迁移后，独立 QA 已从头取得格式、analyze、235/235 测试和 Web build 全部成功的退出码 0。【PASS；当前仓库全门禁通过】

此外，以下发布前证据仍不可缺失：

- 塔罗内容许可证从 candidate 和待确认状态闭环为可发布，并与 NOTICE、设置入口和发布包一致。
- Android 构建、安装、haptics 开关、前后台和进程恢复由主 PM 平台流程验证。
- Web 真实浏览器刷新、离线、页面隐藏、读屏和 vibration capability/no-op 验证。
- 持久化历史、详情、复制、分享预览、失败回退及隐私抓包/日志扫描。
- 源码 commit、Web/Android 产物、签名、分发和回退证据绑定。

任一 P0 再出现随机重抽、冻结结果改变、牌组/方向错误、隐私泄露、不可关闭动画、许可不明或无实际证据时，必须由主 PM 退回开发并阻止发布。

# Pocketools v0.1.0 Stage 2B3 六爻独立 QA 结果

- **执行日期**：2026-08-23。
- **执行角色**：独立 QA；开发已有测试和其他角色命令只作为背景，不替代本文的独立执行证据。
- **验收范围**：八卦与六十四卦、三枚硬币与手工爻规则、codec、内容边界、会话恢复、历史/分享、五态反馈、响应式、无障碍、共享架构和 Web 构建。
- **Stage 2B3 功能复测结论**：【PASS；原键盘焦点缺陷已由开发修复，精确用例与完整六爻目录独立复测通过】。
- **Stage 2B3 严格门禁结论**：【PASS；最终 `make verify` 完整退出 0，全量测试与 Web 后置合同通过】。
- **Android 边界**：按任务约定不在本阶段重建。
- **修改边界**：QA 仅新增两个六爻测试文件、一个必要架构测试和本文档；未修改 `lib/**`、Makefile、pubspec 或 PM/UX 文档。

## TL;DR

- 八卦按 bottom-up 二进制完整锁定为乾 111、兑 110、离 101、震 100、巽 011、坎 010、艮 001、坤 000，稳定 ID、名称和解析均通过。【通过】
- QA 独立硬编码 King Wen 1～64 的卦号、卦名、上卦和下卦，逐项对比 `byNumber`、`byId`、`fromTrigrams` 和六爻 `resolve`；没有从生产表派生预期。【通过】
- 6/7/8/9、本卦/变卦、三枚硬币八种组合、每爻 3 次二值熵、六爻 18 次熵、随机失败原子性、手工零熵和不可变边界通过。【通过】
- codec 对未知 mode/source/kind、非法 value/sequence/coin、模式来源不一致、完成状态、卦 ID、extra/missing/type pollution 和未知 contentVersion 的攻击均拒绝；合法草稿与完成态保持原 session 身份。【通过】
- 64 个原创结构内容、来源元数据、免责声明、安全提示和能力边界通过；未发现 URL、摘录/翻译声明、确定性吉凶或高风险专业结论。【通过】
- commit-before-animation/feedback、随机/存储失败、跳过、保存中隐藏、路由离开、timer dispose 和同一冻结爻恢复通过；未出现补投或额外随机调用。【通过】
- 360 px、200% 字体、48 px 操作、爻语义、键盘触发和上下/生成顺序通过；初跑发现自动完成一爻后焦点没有回到“投下一爻”，开发最小修复后原精确用例 1/1、完整六爻目录 57/57。【修复后通过】
- QA 新增 30 项：规则/codec/内容 17 项、widget 10 项、架构 3 项。初跑定向集 29 通过、1 失败，修复后完整六爻目录 57/57。【修复后通过】
- 中间复测的 `make verify` 曾在 analyze 因 `persistent_session_repository_test.dart` 的 1 个 `unnecessary_import` 失败；修正后最终门禁格式 148/148、analyze 0 issue、300 项通过、1 项 skip、Web 和 31 项 precache 全部完成。【失败链保留，最终通过】
- 唯一 skip 是 Stage 2C-B 组合根尚未移除四个已知生产默认值的前置合同；它不是 Stage 2B3 功能失败，也没有被计为通过。【已核对】
- Web 旧 `flutter_service_worker.js` 不存在；自有 worker 名称、版本、注册、本地 CanvasKit 和 31 项 precache 合同均通过。【通过】

## 环境与证据身份

| 项目 | 实际值 | 状态 |
| :--- | :----- | :--- |
| 工作区 | `.` | 【通过】 |
| Flutter | Flutter 3.47.1 stable，revision `6655482ec0` | 【通过】 |
| Dart | Dart 3.13.1，DevTools 2.60.0 | 【通过】 |
| 新增测试前六爻基线 | 独立执行现有六爻目录 30/30 | 【通过】 |
| QA 新增测试 | 30 项：规则/codec/内容 17 项、widget 10 项、架构 3 项 | 【已验证】 |
| 原精确失败用例复测 | 1/1；焦点进入重建后的“投下一爻”按钮 | 【通过】 |
| 完整六爻目录复测 | 57/57 | 【通过】 |
| 修复前全仓测试快照 | 299 项通过、1 项跳过、1 项焦点失败；仅保留初始缺陷审计 | 【历史失败】 |
| 最终全仓测试 | 300 项通过、1 项 skip，共 301 项；0 失败 | 【通过】 |
| skip | `stage2c_composition_contract_test.dart`：Stage 2C-B 组合集成完成后移除四个已知生产默认值 | 【已核对】 |
| Web `main.dart.js` | SHA-256 `228cec5e3c01791cd83536ededb7bdea007bc80273ccbf869a05e18c1769d60f` | 【通过】 |
| Web `flutter_bootstrap.js` | SHA-256 `f3dd0fb55e94c6ea2a77b6acc884c6e3d880cc988670f2c700547b5fbaeaf2cf` | 【通过】 |
| Web `pocketools_service_worker.js` | SHA-256 `14b412ce89d26a06420e0f91cb4262b8bdce8425818fcd95710dec1dd05a27f9` | 【通过】 |
| Web `manifest.json` | SHA-256 `eaf7f12910dfaec68514fc530a95830c8a42418815185be19c95186fab1a51bd` | 【通过】 |
| Web 文件集合 | 40 个文件、40 MB；有序逐文件哈希集合 SHA-256 `340355130a475069b7136aa700db5bf7bc5aabd2fdb968648d90c7038f99dc59` | 【通过】 |
| 源码版本身份 | 工作区没有 `.git` 元数据，无法将证据绑定到 commit SHA | 【阻塞】 |
| Android | 本阶段不重建 | 【未覆盖】 |

没有 commit 身份不会改变本地规则结论，但发布负责人必须将源码、报告、Web/Android 产物、签名和回退材料绑定到同一可追溯版本。

## 开发测试与独立 QA 边界

- 本轮没有收到可由 QA 复查的 Stage 2B3 开发命令日志或测试计数；本文不推定开发自测结果。【未覆盖】
- QA 在新增测试前独立执行既有 `test/features/liuyao`，结果为 30/30；该结果只代表开发已有测试在当时通过。【通过】
- QA 新增独立映射、攻击输入和真实 widget 中断用例后，六爻目录变为 56/57；不能继续引用新增测试前的绿色结果作为 Stage 2B3 结论。【失败】
- 开发随后只对 `AppButton` FocusNode 透传和六爻页稳定 FocusNode/post-frame/dispose 边界实施最小修复；QA 没有采用开发自测结论替代复测。【已审查】
- QA 修复后先复跑原精确失败用例，再复跑完整六爻目录，分别得到 1/1 和 57/57；该证据关闭 `QA-S2B3-001` 的功能回归。【修复后通过】
- QA 没有修改生产代码；根因判断来自最小失败测试和只读源码审查。【已验证】

## 命令执行结果

| 命令 | 退出码 | 实际结果 | 状态 |
| :--- | :----: | :------- | :--- |
| `flutter --version` | 0 | Flutter 3.47.1、Dart 3.13.1 | 【通过】 |
| `flutter test test/features/liuyao`，新增 QA 测试前 | 0 | 30/30 | 【通过】 |
| `dart format --output=none --set-exit-if-changed`，三个 QA Dart 文件 | 0 | 3 个文件无格式变化 | 【通过】 |
| `flutter analyze`，三个 QA Dart 文件 | 0 | 0 issue | 【通过】 |
| `flutter test liuyao_stage2b3_qa_test.dart liuyao_stage2b3_contract_test.dart` | 0 | 20/20 | 【通过】 |
| `flutter test liuyao_stage2b3_widget_qa_test.dart` | 1 | 9 项通过，1 项“完成一爻后焦点返回”失败 | 【失败】 |
| 原焦点失败精确用例 | 1 | 结果已保存且显示，3 次随机调用不变，但当前焦点不在“投下一爻” | 【失败】 |
| `flutter test test/features/liuyao`，新增 QA 测试后 | 1 | 56 项通过、1 项相同焦点失败 | 【失败】 |
| 修复前 `FLUTTER_BIN=… make test` | 2 | 共享快照变化后为 299 项通过、1 项跳过、1 项相同焦点失败 | 【历史失败】 |
| 修复前 `FLUTTER_BIN=… make build-web` | 2 | 编译生成 40 个文件，但 bootstrap 后置契约失败；该产物不属于修复后证据 | 【历史失败】 |
| 修复后原精确用例：`flutter test … --plain-name 'completed automatic line returns keyboard focus to cast next line'` | 0 | 1/1；结果冻结、随机 3 次、焦点位于新按钮 | 【通过】 |
| 修复后 `flutter test test/features/liuyao` | 0 | 57/57 | 【通过】 |
| 中间复测 `FLUTTER_BIN=flutter make verify` | 2 | format 148/148；analyze 在 `persistent_session_repository_test.dart:1:8` 的 1 个 `unnecessary_import` 停止 | 【历史失败】 |
| 最终 `FLUTTER_BIN=flutter make verify` | 0 | format 148/148、analyze 0 issue、300 PASS、1 skip、Web 构建与 31 项 precache 完成 | 【通过】 |
| skip 原因 | 不适用 | `stage2c_composition_contract_test.dart` 的 `production modules require composition-root repository and id source`：`Stage 2C-B composition integration removes the four known production defaults.` | 【已核对】 |
| `shasum -a 256`，四个关键 Web 文件 | 0 | 得到『环境与证据身份』中的四项文件哈希 | 【通过】 |
| `find build/web -type f -print0 … \| shasum -a 256` | 0 | 40 个文件的有序逐文件哈希集合为 `340355130a475069b7136aa700db5bf7bc5aabd2fdb968648d90c7038f99dc59` | 【通过】 |
| `test ! -e build/web/flutter_service_worker.js` | 0 | 旧 Flutter worker 不存在 | 【通过】 |
| `dart tool/verify_web_precache.dart build/web` | 0 | 独立复核 31 项 Pocketools precache 资源 | 【通过】 |

表中的 `flutter` 指当前环境提供的 Flutter 命令；`…` 仅缩写相同的 `FLUTTER_BIN`。Android 命令未执行。

## 独立增量测试

QA 新增 30 项测试，没有删除或放宽既有六爻测试：

- `liuyao_stage2b3_qa_test.dart` 共 17 项，覆盖八卦、六十四卦独立快照、6/7/8/9、熵调用、失败原子性、不可变、codec、恢复、内容、历史、分享和隐私。
- `liuyao_stage2b3_widget_qa_test.dart` 共 10 项，覆盖真实 commit gate、随机/存储失败、跳过、保存中隐藏、timer dispose、路由恢复、上下显示顺序、焦点和 360 px/200%。
- `liuyao_stage2b3_contract_test.dart` 共 3 项，覆盖 Module/Registry/Adapter、共享组件与 tokens、私有随机/平台 channel/资产/魔法样式旁路，以及 domain/content 依赖方向。

新增测试的初始调试曾把 QA 自己的第 5、6 组三枚硬币手算预期写反；根据独立原始位向量修正为 `[9,8,8,7,8,7]` 后规则用例通过。该事件属于测试数据修正，不是生产缺陷，也没有改变产品规则。

## 八卦与六十四卦验收

### 八卦独立快照

| ID | 名称 | bottom-up 二进制 | 结果 |
| :-- | :--: | :---------------: | :--- |
| `trigram.qian` | 乾 | 111 | 【通过】 |
| `trigram.dui` | 兑 | 110 | 【通过】 |
| `trigram.li` | 离 | 101 | 【通过】 |
| `trigram.zhen` | 震 | 100 | 【通过】 |
| `trigram.xun` | 巽 | 011 | 【通过】 |
| `trigram.kan` | 坎 | 010 | 【通过】 |
| `trigram.gen` | 艮 | 001 | 【通过】 |
| `trigram.kun` | 坤 | 000 | 【通过】 |

### King Wen 独立映射

- 测试文件独立声明 64 个四元组：King Wen 编号、卦名、上卦 ID、下卦 ID。【已验证】
- 每项检查稳定 `hexagram.01`～`hexagram.64`、名称、上下卦，以及 `byNumber`、`byId` 和 `fromTrigrams` 的同一结果。【通过】
- 每项再由独立八卦 bit 组成索引 0～5 的静爻，调用 `resolve` 对比；没有用生产 `all` 或生产矩阵生成预期。【通过】
- 64 个编号连续、名称和上下卦组合逐项匹配，没有只以 count 或唯一性替代内容校验。【通过】

## 爻规则与随机边界

| 场景 | 独立断言 | 结果 |
| :--- | :------- | :--- |
| 和值 6 | 老阴、本卦阴、动爻、变阳 | 【通过】 |
| 和值 7 | 少阳、本卦阳、静爻、仍为阳 | 【通过】 |
| 和值 8 | 少阴、本卦阴、静爻、仍为阴 | 【通过】 |
| 和值 9 | 老阳、本卦阳、动爻、变阴 | 【通过】 |
| 变卦 | 混合向量逐位确认只有 6/9 翻转 | 【通过】 |
| 硬币点数 | `heads=3`、`tails=2`，八种三位组合全部检查 | 【通过】 |
| 单爻自动 | `nextInt` bounds 恰为 `[2,2,2]` | 【通过】 |
| 六爻自动 | 18 次二值调用，索引按 0～5 自初爻到上爻保存 | 【通过】 |
| 随机失败 | 第 1、2、3 次取熵分别失败时均不返回或追加部分爻 | 【通过】 |
| 手工模式 | 6/7/8/9 均零随机；`-1/0/5/10/999` 均拒绝且原草稿不变 | 【通过】 |
| 撤销 | 未完成草稿 copy-on-write 撤销，原对象不变 | 【通过】 |
| 完成态 | `append`、`undo` 和原地修改 lines/coins 均拒绝 | 【通过】 |
| 显示顺序 | 卦图 widget 顺序为上爻到初爻，过程语义为初爻到上爻 | 【通过】 |

没有执行大样本六爻和值频数或卡方检验；固定向量和调用边界通过不能替代 NFR-003 的统计证据。【未覆盖】

## Codec、恢复与版本验收

- 输入 codec 拒绝未知 mode、错误类型、错误 lineCapacity、extra、missing 和 intention 类型污染。【通过】
- outcome codec 拒绝错误 lineCount/lines/complete/contentVersion、extra/missing 和非字符串嵌套键。【通过】
- line codec 拒绝非连续 sequence、5 等非法 value、coin/value 不一致、未知 source、额外 kind、coin 数量不为 3、未知 coin、coin 标量和模式来源不一致。【通过】
- 完成态拒绝错误 complete、lineCount、本卦 ID、变卦 ID，以及静卦伪造 changedHexagramId 或草稿伪造卦 ID。【通过】
- 合法两爻草稿和六爻完成态经 `ToolSessionAdapter` 保存、读取和 decode 后保持同一 session ID、parentSessionId、规则版本和爻序。【通过】
- 未知 schemaVersion 的隔离、旧 schema 迁移与可导出回退没有在当前六爻 codec 中得到本轮证据。【未覆盖】

## 内容来源、许可与安全边界

- 64 个内容条目与独立卦 ID 一一对应，title、structureSummary 和 reflectionPrompt 均非空。【通过】
- 元数据完整：ID、`zh-Hans`、schema、版本 `1.0.0`、`Pocketools original`、作者、Apache-2.0 和 licenseStatus 均存在。【通过】
- `traditionalTextIncluded=false`、`modernTranslationIncluded=false`；运行时不包含古典原文或第三方现代译文声明。【通过】
- 全量字符串扫描未发现 URL、摘录/逐字翻译声明、必然预测、大吉大凶、准确率、医疗诊断、法律结论或买卖建议。【通过】
- 免责声明、安全提示和不扩纳甲、六亲、世应、旬空、神煞、用神、自动吉凶判断的边界在完成结果中可见。【通过】
- 代码中的 licenseStatus 仍为 `candidate pending release review`，`docs/licensing.md` 也把六爻内容方案列为待确认；Stage 2B3 规则通过不等于发布许可闭环。【阻塞】

## 冻结、动画、反馈与恢复验收

| 场景 | 证据 | 结果 |
| :--- | :--- | :--- |
| commit gate | repository 已收到但 Future 未提交时不展示爻、不动画、不反馈 | 【通过】 |
| 存储失败 | 取熵后保存失败，不展示未提交爻、不播放动画或反馈 | 【通过】 |
| 随机失败 | 第三枚硬币前失败，不保存、不展示部分爻 | 【通过】 |
| 逐爻 | 每次只提交一个新爻，每爻最多 3 次二值熵 | 【通过】 |
| 跳过 | 立即显示同一已保存爻，取消后续动画/反馈且不增熵 | 【通过】 |
| 减少动态 | 同一已保存爻在 80 ms 收束，不依赖长动画得到结果 | 【通过】 |
| 保存中隐藏 | 隐藏期间保存完成不补反馈，恢复后显示同一爻 | 【通过】 |
| 路由离开 | 动画中离开再进入恢复同一一爻 session，不补投 | 【通过】 |
| timer dispose | 页面销毁后 timer 不抛异常、不取新熵、不补反馈 | 【通过】 |
| 重起一卦 | 既有测试和 adapter 证据确认新 ID、parentSessionId，intention 不复制 | 【通过】 |
| 浏览器刷新/进程重启 | 本轮未执行真实浏览器刷新、标签关闭或应用进程恢复 | 【未覆盖】 |

## 历史、分享与隐私验收

- `LiuyaoToolModule` 实现 `ToolModule` 与 `ToolSessionAdapterProvider`，会话、decode、历史摘要和分享均通过 registry/adapter 入口。【通过】
- 动卦会话 envelope 保留本卦 ID、变卦 ID、动爻、规则版本和算法版本；分享文本显示本卦、变卦、动爻和版本。【通过】
- 历史摘要保留本卦和动爻语义；结构化 session 继续保存变卦和规则版本，未建立私有历史格式。【通过】
- 使用唯一标记验证 intention、本地 session ID 和 parentSessionId 均不进入 history summary、share summary 或 share plainText。【通过】
- 无动爻时 outcome 的 changedHexagramId 为 null，历史与分享明确“无动爻，本卦不变”，分享不出现“变卦：”。【通过】
- 真实 HistoryPage 详情、分享预览、平台分享失败和日志/抓包字段没有在本轮执行。【未覆盖】

## UI、无障碍与共享架构验收

- 360 × 800、200% 字体下可由键盘开始并完成手工六爻，免责声明、安全提示和重起按钮可滚动到达，没有 Flutter overflow。【通过】
- 确认与重起按钮实测高度不小于 48 px；操作按钮有方式、爻位和冻结动作的语义名称。【通过】
- 卦图语义明确爻位、和值、老少阴阳、动静和变爻；动爻不只靠图形或颜色表达。【通过】
- 页面复用 `AppToolScaffold`、`AppButton`、共享选择控件、generation state、section card、tool theme 和 tokens。【通过】
- 六爻 feature 无私有 Random、安全随机实例、直接 HapticFeedback、MethodChannel、SystemChannels、运行时图片或直接魔法颜色/尺寸；唯一专属 `Primitive` 和 `CustomPainter` 为爻线。【通过】
- domain/content 不依赖 Flutter、presentation 或反馈层；应用 shell 不包含六爻 ID switch，默认 registry 只注册一次模块。【通过】
- 初跑时完成自动一爻后焦点未返回“投下一爻”；开发最小修复后，原精确用例确认焦点进入重建后的同一操作按钮。【修复后通过】
- 真实 TalkBack/VoiceOver、浏览器屏幕阅读器、平板/桌面重排和 Android haptics 未执行。【未覆盖】

## 缺陷审计链

### QA-S2B3-001 完成自动一爻后焦点未返回下一操作

- **严重度**：High；NFR-007 为 P0，当前缺陷阻止 Stage 2B3 与发布无障碍门禁标绿。
- **状态**：【已修复并独立复测通过】。
- **关联需求**：FR-019、NFR-007、NFR-019、REL-005。
- **最小复现**：进入自动投币；用 Tab 聚焦“开始起卦”；按 Enter；在减少动态模式等待 80 ms 和一个 post-frame；确认“投下一爻”已显示；检查 primary focus。
- **期望结果**：焦点位于新的“投下一爻”操作按钮，键盘用户可以连续按 Enter 生成下一爻。
- **实际结果**：结果已冻结保存并正确显示，随机调用仍为 3 次，但 primary focus 不在“投下一爻”按钮。
- **根因判断**：只读审查显示 `_returnToReady` 找到按钮 context 后调用 `FocusScope.of(buttonContext).requestFocus()`，未把重建后的按钮 FocusNode 作为目标；这是从实现和复现得出的推断，仍应由开发确认。
- **开发最小修复**：`AppButton` 接收并向 primary、secondary、quiet 三种按钮透传可选 FocusNode；六爻页创建并复用 `_nextLineFocusNode`，ready 状态重建后在 post-frame 定向请求焦点，回调检查 `mounted`，页面 dispose 释放节点。【只读已审查】
- **精确回归**：保留原 `completed automatic line returns keyboard focus to cast next line`，修复后独立复跑 1/1，退出码 0；结果仍先冻结，随机调用仍为 3 次。【通过】
- **目录回归**：完整 `test/features/liuyao` 修复后 57/57，退出码 0。【通过】
- **中间门禁失败**：首次修复后 `make verify` 的 format 通过，但 analyze 被范围外测试文件的无用 import 阻断；该失败保留为审计链。【历史失败】
- **最终门禁复测**：开发最小修正门禁误判并暂停后，QA 从头执行同一 `make verify`，得到 300 PASS、1 skip、0 FAIL，Web 与 precache 后置合同通过，退出码 0。【通过】

## Makefile 与 Web 构建验收

- 门禁失败链包括初始焦点失败、一次范围外 analyze 告警和旧 Web bootstrap 误判；这些失败没有从报告中删除。【历史证据】
- 最终 `make verify` 的 check-format 检查 148 个 Dart 文件且 0 变化，analyze 为 0 issue。【通过】
- 全量 Flutter 测试为 300 PASS、1 skip、0 FAIL；skip 仅标记 Stage 2C-B 组合根后续合同，不属于 Stage 2B3 失败。【通过】
- Makefile 在 Web 构建后删除并断言旧 `flutter_service_worker.js` 不存在，检查自有 `pocketools_service_worker.js`、`pocketools-pwa-v1` 和 `.register(`。【通过】
- bootstrap 指向本地 `canvasKitBaseUrl: "canvaskit/"`；独立脚本解析、去重、安全路径检查并确认 31 项 precache 产物存在。【通过】
- Wasm dry run 与标准 Web 构建完成；四个关键文件和 40 文件有序集合哈希见『环境与证据身份』。【通过】
- `QA-S2B3-001`、REL-011 与 Stage 2B3 本地严格门禁全部关闭。【通过】

## 需求覆盖矩阵

“部分通过”表示 Stage 2B3 子合同已有自动化证据，但整条跨端、发布或持久化需求尚未关闭。

| 需求 ID | 本轮状态 | Stage 2B3 证据与边界 |
| :------ | :------- | :------------------ |
| FR-003 | 【通过】 | 输入、规则、爻和版本冻结；重起新 ID 并关联 parentSessionId |
| FR-004 | 【部分通过】 | 防重复、跳过、隐藏和路由恢复同一爻；真实刷新/进程恢复未覆盖 |
| FR-005 | 【部分通过】 | 结果、过程、版本和重起存在；完整历史详情/复制/分享 UI 未执行 |
| FR-013 | 【通过】 | heads 3/tails 2、每爻三次、六次 bottom-up 和原始硬币可追溯 |
| FR-014 | 【通过】 | 手工 6/7/8/9 零熵；非法值拒绝，草稿不变 |
| FR-015 | 【通过】 | 6/7/8/9 原爻、动静和变爻固定向量 |
| FR-016 | 【通过】 | 64 卦逐项映射；有动爻只翻对应位置，无动爻不制造变卦 |
| FR-017 | 【通过】 | 生成顺序初爻到上爻，图形上爻到初爻，过程语义可追溯 |
| FR-018 | 【通过】 | 原创结构解释和范围禁语扫描，不实现高级排盘/自动断卦 |
| FR-019 | 【通过】 | 单爻一次生成、草稿撤销、完成态不可改和修复后焦点返回均通过 |
| FR-031、FR-037 | 【部分通过】 | adapter 历史/分享结构与脱敏通过；真实 UI 未执行 |
| FR-041 | 【通过】 | 减少动态保持同一冻结爻，不增加熵 |
| FR-045 | 【部分通过】 | 安全提示和禁语通过；未执行真实日志/网络观测 |
| FR-046 | 【部分通过】 | 随机与存储失败不伪结果；内容损坏/平台分享失败未注入 |
| FR-051 | 【通过】 | 卦名、上下卦、结构、动爻/变卦、来源和免责声明完整 |
| FR-052 | 【部分通过】 | 六爻提交/生成/揭示/完成/减少动态和反馈边界通过；真实平台未执行 |
| NFR-001 | 【部分通过】 | 独立纯规则固定向量和 Web 构建通过；Android 对比未执行 |
| NFR-002、NFR-004 | 【通过】 | 只消费注入 RandomSource，失败不降级；规则/算法/内容版本可查 |
| NFR-003 | 【部分通过】 | 三枚硬币全部固定组合和调用 bounds 通过；统计频数检验未执行 |
| NFR-006 | 【部分通过】 | 隐藏、跳过和路由恢复通过；刷新/进程恢复未覆盖 |
| NFR-007 | 【部分通过】 | 360 px、200%、48 px、语义、键盘触发和修复后焦点返回通过；真实读屏与跨端仍未覆盖 |
| NFR-008、NFR-009 | 【部分通过】 | 360 px 与无网络依赖静态审查通过；平板/桌面/真实离线未执行 |
| NFR-010、NFR-014 | 【部分通过】 | adapter 脱敏通过；抓包、日志和事件白名单未执行 |
| NFR-011 | 【通过】 | codec exact-key、范围、枚举和类型污染攻击通过 |
| NFR-012 | 【部分通过】 | 合法草稿/完成态恢复和未知 contentVersion 拒绝通过；schema 迁移未覆盖 |
| NFR-013、NFR-015 | 【部分通过】 | 稳定 ID、名称、locale 和内容元数据通过；最终许可仍未闭环 |
| NFR-016 | 【通过】 | domain/content 纯度、共享随机/反馈和平台旁路门禁通过 |
| NFR-017 | 【部分通过】 | 正常、边界、异常、恢复、架构和焦点回归通过；全门禁与跨端矩阵未通过 |
| NFR-018、NFR-019 | 【部分通过】 | 注入反馈、隐藏、减少动态、timer、冻结和焦点返回通过；真实平台未覆盖 |
| NFR-022、NFR-023、NFR-024 | 【通过】 | Module/Registry/Adapter、统一 session/random/share 和共享 UI/token 门禁通过 |
| REL-003 | 【通过】 | 本报告提供需求 ID 到命令、测试和边界的映射 |
| REL-004、REL-007 | 【部分通过】 | 内容/规则/算法版本存在；最终许可与源码 commit 身份未闭环 |
| REL-005 | 【部分通过】 | 原焦点缺陷已关闭；统计、跨端和真实读屏仍无证据 |
| REL-008 | 【部分通过】 | Web 构建与哈希存在；Android、签名、分发和回退未覆盖 |
| REL-011 | 【通过】 | 最终 `make verify` 退出 0；格式、分析、全量测试、Web 与 31 项 precache 后置合同完整执行 |
| REL-013 | 【通过】 | Registry、统一 adapter、依赖方向、共享 UI/token 和旁路扫描通过 |

## 阶段准入结论

Stage 2B3 的六爻映射、规则、随机调用、codec、内容、冻结、恢复、历史/分享、响应式和架构主体已获得独立证据。`QA-S2B3-001` 的原精确失败用例修复后 1/1，完整六爻目录 57/57，焦点缺陷功能回归关闭。【功能 PASS】

最终独立 `make verify` 完整退出 0：148/148 格式、0 analyze issue、300 PASS、1 skip、0 FAIL、Web 构建和 31 项 precache 均通过。初始 56/57 焦点失败、中间 analyze 阻断和 Web 误判仍保留在审计链中。【Stage 2B3 最终 PASS；准入后续阶段】

以下边界仍未覆盖：

- Android 构建、安装、前后台、真实 haptics 和 TalkBack。
- Web 真实浏览器刷新、离线、标签恢复、读屏和 vibration capability/no-op。
- 六爻和值大样本统计检验和确定设备上的性能测量。
- 持久化数据库迁移、进程被杀、历史详情、分享预览及失败回退。
- 隐私抓包、运行日志、事件白名单和最终内容许可。
- 平板、桌面连续重排以及源码 commit、签名、分发和回退绑定。

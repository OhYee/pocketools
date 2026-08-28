# Pocketools v0.1.0 内容发布契约独立 QA 结果

- **执行日期**：2026-08-23。
- **执行角色**：独立 QA；开发提供的元数据变更说明只作为背景，本文结论来自独立源码审查和实际命令。
- **验收范围**：ADR 0004 与 Tarot/Liuyao 运行时内容元数据一致性、候选状态清除、外部运行时内容依赖边界、完整仓库门禁和 Web 构建。
- **写入边界**：只修改独立 QA 测试并新增本文档；未修改 `lib/**`、Makefile、pubspec、PM/UX 文档或既有 Stage2B 报告。
- **最终结论**：【PASS；Stage2B 记录的运行时内容候选状态已由 Accepted ADR、最终生产元数据和独立回归证据关闭】。

## TL;DR

- Tarot 与 Liuyao 的运行时 source metadata 均精确为 `Apache-2.0` 和 `approved for v0.1.0 project release`，两者均不再包含 `candidate`。【通过】
- QA 将旧 Tarot 独立断言迁移到 Accepted ADR 的最终值，并新增 3 项跨工具发布契约；原历史失败用例复测 1/1，新增契约最终 3/3。【通过】
- 两个内容目录未导入外部 package 或 `dart:io`；两个 feature 的运行时代码未发现网络内容、运行时图片/资源包加载、设计稿路径或 URL；`pubspec.yaml` 没有激活 assets/fonts，也没有注册 `docs/design` 或 `output/imagegen`。【通过】
- 完整 `make verify` 检查 174 个 Dart 文件、analyze 0 issue、355/355 测试通过、0 skip，随后完成 Web 构建和 31 项 precache 校验，退出码 0。【通过】
- Stage2B2 与 Stage2B3 报告中的 candidate 阻塞是各自旧生产快照的真实证据，本文不回写或抹除历史；本次 Accepted ADR 与当前运行时值构成后续关闭证据。【通过】

## 环境与证据身份

| 项目 | 实际值 | 状态 |
| :--- | :----- | :--- |
| Flutter | `flutter`；Flutter 3.47.1 stable，revision `6655482ec0` | 【通过】 |
| Dart | Dart 3.13.1；DevTools 2.60.0 | 【通过】 |
| 原精确回归 | `all cards and directions expose complete immutable content`，1/1 PASS | 【通过】 |
| 新增内容发布契约 | 3/3 PASS、0 skip | 【通过】 |
| 最终全仓测试 | 355 PASS、0 FAIL、0 skip | 【通过】 |
| Web 构建 | `build/web`，40 个文件、41M；31 项 precache 验证成功 | 【通过】 |
| Web 文件集合 | 按路径排序后逐文件 SHA-256 再汇总为 `af21098e01c2f29c3a3cb04151efe655597a8bc292116b048a8727344c049263` | 【通过】 |

## 最终元数据与 ADR 对齐

| 内容目录 | license | licenseStatus | 候选标记 | 状态 |
| :------- | :------ | :------------ | :------- | :--- |
| Tarot | `Apache-2.0` | `approved for v0.1.0 project release` | 无 | 【通过】 |
| Liuyao | `Apache-2.0` | `approved for v0.1.0 project release` | 无 | 【通过】 |

独立契约先确认 ADR 0004 状态为 Accepted，再以同一精确值校验两个公开 catalog。该测试不是分别复制开发内容完整性测试，而是把决策文档、两套运行时 metadata 和禁止 candidate 的发布条件绑定为一个跨工具门禁。

## 外部运行时内容依赖边界

- 内容目录的 Dart import 只允许仓库内相对源码和不具备外部内容访问能力的 SDK 库；外部 package 与 `dart:io` 导入会失败。【通过】
- Tarot/Liuyao 全部 feature 源码扫描 `package:http`、`HttpClient`、网络图片、资源图片、bundle 文本加载、HTTP URL、`docs/design` 和 `output/imagegen`，未发现命中。【通过】
- 去除注释后的 `pubspec.yaml` 没有激活 `assets:` 或 `fonts:`，也没有设计稿目录注册。【通过】
- 该静态契约证明当前仓库运行时没有外部内容加载入口或设计评审资产注册；它不替代未来新增文本、字体、音效、图片或依赖时的来源与法律审查。【边界】

## 命令执行结果

| 命令 | 退出码 | 实际结果 | 状态 |
| :--- | :----: | :------- | :--- |
| `dart format test/features/tarot/tarot_stage2b2_qa_test.dart test/architecture/content_release_contract_test.dart` | 0 | 两个 QA 文件格式化完成 | 【通过】 |
| `flutter test test/features/tarot/tarot_stage2b2_qa_test.dart --plain-name 'all cards and directions expose complete immutable content'` | 0 | 原精确回归 1/1 PASS | 【通过】 |
| 首次 `flutter test test/architecture/content_release_contract_test.dart` | 1 | 2 PASS、1 测试夹具失败；`dart:collection` 被过宽规则误判为外部内容依赖 | 【测试夹具修正】 |
| 修正后 `flutter test test/architecture/content_release_contract_test.dart` | 0 | 3/3 PASS、0 skip | 【通过】 |
| `FLUTTER_BIN=flutter make verify` | 0 | format 174 files、analyze 0 issue、355/355 PASS、0 skip、Web build 与 31 项 precache 完成 | 【通过】 |
| `test ! -e build/web/flutter_service_worker.js` | 0 | 旧 Flutter worker 不存在 | 【通过】 |
| `shasum -a 256`，四个关键 Web 文件 | 0 | 产物哈希见『Web 产物证据』 | 【通过】 |
| `find build/web -type f -print0 \| sort -z \| xargs -0 shasum -a 256 \| shasum -a 256` | 0 | 40 文件有序集合哈希已记录 | 【通过】 |

首次新增契约失败属于 QA 规则分类错误：`dart:collection` 只提供集合能力，不是外部内容或 I/O 来源。QA 将规则收敛为禁止外部 package 与 `dart:io`，同时保留更广的 feature 网络、bundle、资产和 URL 扫描；没有修改生产代码，也没有放宽“无外部运行时内容依赖”的要求。

## Web 产物证据

| 文件 | SHA-256 | 状态 |
| :--- | :------ | :--- |
| `build/web/main.dart.js` | `6cca419c9983b4d159eea5ead21299c762fbc903e8b96e3ca42248542d62dfe4` | 【通过】 |
| `build/web/flutter_bootstrap.js` | `f3dd0fb55e94c6ea2a77b6acc884c6e3d880cc988670f2c700547b5fbaeaf2cf` | 【通过】 |
| `build/web/pocketools_service_worker.js` | `14b412ce89d26a06420e0f91cb4262b8bdce8425818fcd95710dec1dd05a27f9` | 【通过】 |
| `build/web/manifest.json` | `eaf7f12910dfaec68514fc530a95830c8a42418815185be19c95186fab1a51bd` | 【通过】 |

`make verify` 生成 Web 产物后验证了 31 项 Pocketools precache 资源；旧 `flutter_service_worker.js` 不存在。本文哈希来自该次完整门禁生成的当前产物。

## 历史阻塞关闭审计链

- Stage2B2 执行时，Tarot 生产值仍为 `Apache-2.0 candidate`；原报告据此明确“候选边界透明但不等于最终许可闭环”。该结论对当时快照真实有效。【历史证据保留】
- Stage2B3 执行时，Liuyao 的 licenseStatus 仍为 `candidate pending release review`；原报告将最终许可列为发布阻塞。该结论对当时快照真实有效。【历史证据保留】
- ADR 0004 于 2026-08-23 接受 v0.1.0 内容发布边界，规定两个运行时目录统一使用 Apache-2.0 与精确 approved 状态，并禁止 candidate。【决策已核对】
- 当前生产目录已落实该决策；QA 更新长期回归断言并新增跨工具 fail-closed 契约，相关精确测试与完整门禁均退出 0。【关闭证据】
- 既有 Stage2B 报告未被修改；历史失败、修复时序和当时未闭环项继续保留，本文作为后续状态变更证据追加。【审计链完整】

## 最终结论与剩余边界

Tarot 与 Liuyao 的 v0.1.0 运行时内容 metadata 已从 candidate 收口为精确的 Apache-2.0 approved 状态；当前源码、测试和 Web 构建中未发现外部运行时内容依赖。原 Stage2B 内容 metadata 发布阻塞已关闭。【PASS】

本结论只覆盖本次内容发布契约，不等于法律意见，也不替代最终 SBOM、商店素材、真实浏览器、Android、签名产物或未来新增外部内容的独立许可审查。任何后续外部文本、牌面、字体、音效或生成资产进入运行时，都必须重新触发 ADR 0004 规定的来源、版本、再分发许可、归属与 QA 门禁。

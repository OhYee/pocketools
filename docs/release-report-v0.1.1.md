# Pocketools v0.1.1 视觉真实性增量交付报告

- **版本**：0.1.1+2。
- **日期**：2026-08-24。
- **基线**：在 [v0.1.0 第一版报告](release-report.md) 的五个玩法工具、会话、随机、历史、分享、Makefile 和平台构建基线上增量交付。
- **交付结论**：本地源码、自动化测试、Web/PWA 生产构建、Android debug 构建、universal release 和三 ABI split-per-ABI release 构建候选通过；当前 `make test` 实测 573/573，新增动画时序、D20 固定舞台、骰子数立即 reset、图鉴和多副牌回归；既有 Edge 151 基线已通过，本轮交互增量未重复执行完整浏览器矩阵；公共发布许可、真实 Android 设备和商店 release 签名门禁仍未通过。
- **源码身份**：本报告记录于 Git 初始化前；公开仓库中的提交身份以 Git 历史为准。本地验收同时使用源文件集合哈希、资源 manifest 和产物 SHA-256。

## 本轮交付

- 硬币：接入生成式实体正反面、独立侧边资源、绕水平线的 `rotateX` 面切换、抛起/翻转/落桌/阻尼稳定和程序化落地阴影。动画只消费已冻结的 `CoinSide`。
- DND：接入无固定数字的实体 D20 素材、X/Y/Z 组合透视滚动、落地/回弹和冻结点数叠加；就绪态仅显示中性 `D20` 标签，2～1000 面的非标准骰子继续使用明确的实体数字块 fallback，配置能力不回退。
- 塔罗：接入牌背、抽牌和 Y 轴翻牌流程，78 张 Rider–Waite–Smith 扫描候选按稳定 card ID 映射；逆位使用完成后的 180° 旋转和独立语义标签；默认单张一次点击完成抽取与翻牌，高级牌阵仍可逐张揭示。
- 页面结构：六个玩法统一为“核心实体 → 主操作与按玩法显示重置 → 默认折叠的高级选项 → 结果/解析”；塔罗 `includeMinorArcana` 可在 78 张完整牌组与 22 张大阿尔卡那之间切换，图鉴作为独立只读模块展示。
- Web shell 布局增量：桌面宽度采用左侧 `NavigationRail` 侧栏，右侧主体通过 `Expanded` 占满剩余空间；`AppToolScaffold` 的共享内容使用 `Alignment.topCenter` 从顶部对齐，窄屏保留底部 `NavigationBar`。以上由 `test/widget/app_layout_shell_test.dart` 的 3 个 widget contract 用例验证，不等于本轮真实浏览器视觉验收。
- 交互收口：结果、状态和动画合并到顶部 `AppEntityStateView`；点击实体与主按钮共享动作；移除独立“查看过程”；塔罗/扑克完成后继续抽取，硬币/D20 完成后 reset + reroll。
- 共享牌堆：塔罗与扑克共用 `AppPhysicalDeck`/`AppDeckResultFlow`；牌堆固定在左侧，牌面按顺序向右追加并换行，只有本次新增牌播放进入动画，塔罗牌面释义通过弹层展示。
- D20/六爻细节：D20 顶部 `aDb` 使用两个数字加减框并实时同步实体骰子；高面数复用同一实体骰图并叠加实际点数；六爻页面只让铜钱投下一爻，卦象只打开信息，页面不显示内容边界/来源/许可卡片。
- 体感抛硬币：Android 通过系统加速度计 channel 触发现有抛币链路，Dart 侧使用 `18.0 m/s²` 阈值和 `900 ms` 冷却；Web、非 Android 和传感器不可用时保留手动入口。
- 资源治理：`assets/runtime/asset-manifest.json` 登记 84 项资源、逐项尺寸、来源、处理策略、source/runtime SHA-256、归属和 `candidate` 状态；新增生成式扑克牌牌背并由 `PlayingCardView` 通过 manifest 加载；`docs/design/runtime-asset-attributions.md` 记录交接边界。
- 架构治理：共享 `AppPhysicsMotion` 和 `RuntimeAssetSlot`，特性只持有专属 primitive；结果仍遵循“先随机、先持久化、再播放”，动画不会重新取熵。
- PWA 治理：自有 Service Worker 缓存版本升级为 v3，导航与静态资源采用 network-first，避免新资源继续命中旧版本的 cache-first 静态缓存。
- 参考图视觉增量：采用共享日／夜 surface tokens、实体舞台和 raised 结果卡；D20 core 使用 `176/208 px` 响应式尺寸，塔罗完成态显示真实牌面，扑克结果使用 `2:3` 响应式网格和轻量抽牌旋转；不把设计板图片复制进运行时。

## 角色交付与门禁

| 身份 | 交付 | 结论 |
| :--- | :--- | :--- |
| 项目经理 | 本报告、资源许可边界、版本和发布裁决 | 完成 |
| 交互设计 | [运行时视觉与动效合同](design/runtime-visual-asset-motion-contract.md)、需求/交互增量 | 完成；明确真实物体、减少动态、触觉和恢复合同 |
| 开发 | 共享动效、资源 manifest、硬币/D20/塔罗真实运行时组件 | 完成；本地候选 |
| 测试 | [独立动画与资源 QA](../test/architecture/independent_animation_tarot_asset_qa_test.dart)、widget QA、全量回归 | 完成；见下方实际命令 |

本轮参考图增量另由 [参考图视觉审计](design/reference-effect-audit.md)、`test/architecture/reference_effect_visual_qa_test.dart` 和 `test/widget/reference_effect_visual_qa_test.dart` 形成可复查证据。

## 自动化验证

最终收口命令与结果以本节为准；历史 v0.1.0 测试报告不覆盖本轮资源增量。

```text
make check-format                                           PASS (237 Dart files, 0 changed)
make analyze                                                PASS (0 issue)
make test                                                    573/573 PASS (含动画时序、D20 舞台、骰子数立即 reset、图鉴与多副牌回归)
reference-effect visual QA                                  22/22 PASS
flutter test simplified-layout and tarot-minor-arcana QA     25/25 PASS
make build-web                                               PASS (31/31 precache resources)
make build-android                                           PASS (assembleDebug)
make build-android-release                                   PASS (assembleRelease, 63.9 MB optimized candidate)
make build-android-release-split-per-abi                     PASS (arm64-v8a, armeabi-v7a, x86_64; 3 APKs verified)
```

QA 特别覆盖：

- 硬币抛起、翻转、边缘显示、落定和减少动态；
- D20 多轴滚动、无固定底图数字、任意骰子数/面数和结果冻结；
- 塔罗 78 张资源、牌背、正逆位、逐张揭示、来源 metadata 和缺失资源 fallback；
- 资源 manifest 的 84 条路径都存在且含 runtime SHA-256 和许可状态；
- 三类工具均先持久化再播放，动画/反馈不增加随机调用。
- Web shell 的桌面侧栏、右侧展开主体、主体顶部对齐和窄屏底部导航由 widget contract 覆盖；本轮未据此宣称真实浏览器视觉结果。
- 既有真实 Edge 151 clean-origin 验收覆盖首页、六个玩法、默认折叠高级选项、塔罗 78/22 张切换、D20 骰子数/面数、扑克大小王/抽取张数、硬币落地和六爻逐爻起卦；控制台无错误。本轮交互收口未重复执行完整浏览器矩阵，当前增量由 Flutter widget/架构测试和生产构建覆盖。
- 旧 origin 首次复用时复现了 v1 Service Worker 缓存旧静态脚本的问题；升级到 v3 后完成一次标准 reload，单张塔罗一次点击可完成，说明缓存升级路径已修复。该结果不等同于长期跨版本浏览器矩阵。

## 交付产物

- 上述 Web/Android 构建产物仅保留在被忽略的 `output/` 目录，不随源码提交；源码清单和校验文件也只作为本地验收证据。
- 本地 Android 构建产物保留在被忽略的 `output/` 目录，不随源码提交。
- Web、Universal release 和 ABI split 构建可通过根目录 Makefile 重新生成；本报告不嵌入本地二进制下载链接。
- split-per-ABI 产物按 `arm64-v8a`、`armeabi-v7a` 和 `x86_64` 输出；详细校验仅在本地验收目录中保留。
- 本地 APK 签名和完整性校验结果不作为源码仓库内容发布。

universal release、三 split release 和 debug 共 5 个 APK 均由 `apksigner verify --verbose --print-certs` 验证通过，均通过 APK Signature Scheme v2；五者均使用 Android Debug 证书，release APK 仍不能作为商店发布包。校验值以 `SHA256SUMS` 为准。

split-per-ABI 是 CPU ABI 级适配：三个 APK 分别面向 `arm64-v8a`、`armeabi-v7a` 和 `x86_64`，同一 ABI 可覆盖多个 OEM 厂商和设备型号。它不是 OEM 型号级适配，也不表示对某个品牌、型号或 SoC 特性的专属兼容性；真实设备矩阵仍需单独执行。

## 资源和许可边界

生成式硬币、D20 和牌背是本地候选资产，不能在服务条款复核前宣称公共再分发许可。Rider–Waite–Smith 牌面源文件和归属已记录，但“Public Domain candidate”不是跨司法辖区结论；每张牌仍保持 `candidate`，目标地区和具体扫描版本复核完成后才能将内容包状态改为 `approved`。

运行时不从网络下载图片，不用网络响应决定点数或牌面；设计稿仍标记 `runtimeAsset=false`，没有被复制为牌面源文件。

## 发布边界

当前允许交付为：

- 本地开发/QA 的 Web、Android debug 和 Android release 优化构建候选；
- 离线资源读取、动画和结果冻结的自动化验收；
- 供后续许可复核的完整资源来源和 hash 证据。

当前不允许宣称：

- 已完成 Rider–Waite–Smith 或生成式资产的公共发布授权；
- Android 实体设备振动、安装、升级/回退尚未验证；
- hosted CI、商店 release signing、商店审核或公共 Web 部署仍未完成。

## 后续门禁

- 由许可责任人逐项复核 `assets/runtime/asset-manifest.json`，批准或移除 candidate 资源。
- 在 Android API 24、目标版本和最新版本设备/模拟器上验证安装、六个玩法工具、图鉴、后台恢复和真实振动。
- 在 Chrome、Firefox、Safari、Edge 上补齐首装离线、缓存升级和屏幕阅读器矩阵。
- 将构建产物、资源 manifest、源文件集合和 Git commit SHA 绑定到同一发布身份。

# Pocketools

Pocketools 是一个面向 Android 与 Web/PWA 的离线优先随机工具箱，覆盖塔罗牌、六爻、D20 检定、抛硬币、抽扑克牌和塔罗／周易多重占卜，并提供塔罗牌与周易图鉴。

## 项目状态

- **当前版本**：v0.1.3+4。
- **当前阶段**：首版本地源码基线之上的真实运行时视觉增量已交付；硬币、六爻、D20、扑克和塔罗均接入可识别实体、统一状态舞台和物理感动画，资源候选许可仍待复核。
- **验证状态**：当前源码已通过 `make check-format`、`make analyze`、全量回归、Web 生产构建和 Android debug／release／split-per-ABI 构建；普通本地/CI release APK 是 debug 签名候选，版本标签流水线仅在配置正式签名 Secrets 后发布签名 APK。Android 实体设备、真实传感器/振动、完整浏览器矩阵和公共渠道仍需独立验收，详见 [GitHub Actions 与发布](docs/github-actions.md)、[多重占卜设计与实现说明](docs/multi-divination-design.md) 与 [平台验收](docs/test-results-platform.md)。
- **许可证**：Apache-2.0 适用于项目代码和原创文档；运行时视觉资源按各自清单状态处理，详见 [LICENSE](LICENSE) 和 [NOTICE](NOTICE)。

## v0.1.1 范围

| 工具或能力 | 首版范围 |
| :--------- | :------- |
| 塔罗牌 | 默认单张一次点击抽取/翻牌、三牌阵、正逆位、22/78 张牌组、经典 RWS 牌面、传统象征、位置/组合提示和反思问题 |
| 六爻 | 三枚硬币自动起卦、手工录入、本卦、动爻、变卦和结构解释 |
| D20 检定 | 普通/优势/劣势快捷预设、1～20 枚骰子、2～1000 面、sum/keepHighest/keepLowest、modifier 和可选 DC |
| 抛硬币 | 单次、批量、自定义次数和可选自定义标签 |
| 抽扑克牌 | 标准 52 张牌、可选 2 张大小王、无放回按顺序抽取 n 张（每次点击一张，n 为本轮目标）、历史和分享 |
| 多重占卜 | 78 张塔罗牌六组 A/B/C、正逆位计数映射 6/7/8/9、本卦／动爻／变卦与 A1～A6 融合解释、可恢复逐组抽取 |
| 塔罗牌／周易图鉴 | 多行多列塔罗卡面与点击释义、八卦交叉表和卦象名称；图鉴只读，不改变随机会话 |
| 公共能力 | 六个玩法工具与图鉴共用的历史、预设、脱敏分享、设置、离线和无障碍能力；玩法实体支持语义动画与可关闭触觉 |

## 文档

项目文档统一位于 [docs/](docs/README.md)：

- [产品设计](docs/product-design.md)：定位、用户场景、规则、架构方向和风险基线。
- [v0.1.0 需求](docs/requirements.md)：稳定需求 ID、优先级和验收条件。
- [项目计划](docs/project-plan.md)：角色边界、阶段门禁、交付物和 Definition of Done。
- [架构与扩展指南](docs/architecture.md)：新增工具的最小改动面、依赖方向、共享 UI 和架构测试契约。
- [交互设计](docs/interaction-design.md)：现有工具、动效、反馈、恢复、响应式和无障碍的精确交互基线，G1 已通过。
- [多重占卜设计与实现说明](docs/multi-divination-design.md)：塔罗与周易融合规则、解释边界、交互、会话恢复、测试和发布限制。
- [许可与内容边界](docs/licensing.md)：第三方代码、内容和视觉资产的审查规则。
- [运行时视觉资源归属](docs/design/runtime-asset-attributions.md)：硬币、D20、塔罗牌背和 78 张牌面候选的来源、处理和发布边界。
- [平台与系统工具链验收](docs/test-results-platform.md)：Homebrew Flutter、Makefile、真实浏览器、离线 PWA 和 Android 构建证据。
- [Android 构建与设备适配](docs/android-builds.md)：Universal、ABI 分包、设备覆盖边界、体积优化和型号适配原则。
- [GitHub Actions 与发布](docs/github-actions.md)：CI 触发条件、构建产物、Android 签名 Secrets、版本标签和 GitHub Release 流程。
- [v0.1.1 视觉增量交付报告](docs/release-report-v0.1.1.md)：项目经理、交互、开发和独立 QA 的本轮资源与真实动画收口。
- [参考图视觉审计](docs/design/reference-effect-audit.md)：用户参考图对应的主题、实体、结果层级、动画和剩余差距。

测试计划已追踪全部 89 条需求；阶段报告保留每个开发快照的原始结论，最终状态以 [发布报告](docs/release-report.md) 为准。

## 构建与运行

根目录 [Makefile](Makefile) 已提供本地与 CI 共用的薄封装。可通过 `brew install --cask flutter` 安装 Flutter stable，或用 `FLUTTER_BIN=flutter` 指定工具链，然后执行：

```bash
make help
make bootstrap
make verify
make build-web
make build-android
make build-android-release
make build-android-release-split-per-abi
```

`verify` 执行格式检查、静态分析、全量测试和 Web 构建；`build-android` 构建 debug APK，`build-android-release` 保留 universal release APK，`build-android-release-split-per-abi` 使用 `--split-per-abi` 并校验以下三个 APK：`app-arm64-v8a-release.apk`、`app-armeabi-v7a-release.apk` 和 `app-x86_64-release.apk`。split 目标会先移除这三个已知旧文件，构建成功后再由 `tool/verify_android_apks.dart` 检查产物存在且非空；输出目录固定为 `build/app/outputs/flutter-apk/`，缺失产物时会打印期望目录和文件名。

这里的 split 是 ABI 级适配：它按 Android CPU ABI 生成包，不是 OEM 型号级适配。一个 ABI APK 可以覆盖多个厂商和型号；该命令不会按品牌、机型、SoC 特性或设备销售渠道生成不同包。两个 Android release 目标都需要 JDK 17，以及能提供 compile/target 36、Platform 35、NDK 和 CMake 的 Android SDK；未配置签名环境变量时构建沿用 debug signing config，只能作为候选包。版本标签流水线要求正式签名 Secrets，细节见 [GitHub Actions 与发布](docs/github-actions.md)。`clean` 只调用 Flutter 对当前项目的清理。完整语义见 [需求文档的 Makefile 命令契约](docs/requirements.md#makefile-命令契约)、[平台验收](docs/test-results-platform.md) 和 [项目计划](docs/project-plan.md)。

## 本地交付物

本地构建产物写入 `output/`，该目录已被 `.gitignore` 排除，不随源码提交。需要本地验收时执行 `make build-web`、`make build-android`、`make build-android-release` 或 `make build-android-release-split-per-abi` 重新生成。

## 架构方向

六个玩法工具通过统一 `ToolModule` 注册并复用随机核心、会话、历史、预设和分享协议；图鉴作为只读模块接入同一工具目录。共享 UI 组件与 design tokens 控制全局按钮等公共样式，工具差异只通过语义 token 和少量专属 primitive 表达；自动化架构测试覆盖“新增 fake 模块不修改应用 shell”和公共组件单点样式边界。

- `AppEntityStateView` 是唯一实体舞台，内部仅以 `AppGenerationStateView` 作为状态胶囊；D20/DND、硬币和六爻的实体动作统一经过 `AppPhysicalAction`，塔罗、扑克和多重占卜统一经过 `AppPhysicalDeck` + `AppDeckResultFlow`。
- 首页已合并工具目录，不再保留独立的工具一级导航；牌类每次点击只追加一张，`n` 只表示本轮目标数量，不表示一次性批量动作。

## 贡献与治理

- 贡献流程见 [CONTRIBUTING.md](CONTRIBUTING.md)。
- 社区互动边界见 [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md)。
- 漏洞和隐私问题报告见 [SECURITY.md](SECURITY.md)。
- 变更记录见 [CHANGELOG.md](CHANGELOG.md)。
- 项目采用 [Apache-2.0](LICENSE)；新增第三方内容必须遵守 [docs/licensing.md](docs/licensing.md)。

贡献前请先阅读需求和项目计划。G1 已通过，但每项变更仍必须满足需求追踪、独立测试、许可和双平台交付门禁。

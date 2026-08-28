# Pocketools v0.1.1 平台与系统工具链验收

- **日期**：2026-08-24。
- **验收角色**：主 agent／项目经理，承接独立 QA 之后的系统工具链、真实浏览器与 Android 构建门禁。
- **当前结论**：【本地源码与本地产物通过；当前全量复验为 573/573；不等同于商店发布通过】。
- **源码身份边界**：本报告记录于 Git 初始化前；公开仓库的 branch、commit SHA 和 dirty 状态以 Git 历史与本地工作树为准。本报告使用文件哈希和构建产物哈希绑定当时证据。

## 多重占卜增量复验

- **状态**：【源码、自动化测试和本地产物已通过；公共发布仍未通过】。
- `flutter test test/features/multi_divination`：26/26 通过，覆盖一次洗牌牌序、18 张无重复牌、正逆位计数、六爻映射、codec 严格校验、实体点击、逐组抽取、A 牌释义、返回和恢复。
- `flutter test`：573/573 通过，包含多重占卜注册表、布局、会话 ID 和隐藏区域审计。
- 静态审计：多重占卜页面没有第二个全高舞台、`Offstage` 隐藏结果、透明占位区域或零高度 hack；动画只使用共享实体舞台和局部命名槽位。
- `make build-web`：通过，31 项自有 precache 资源通过校验。
- 使用当前环境配置的 Android SDK 执行 `make build-android`、`make build-android-release`、`make build-android-release-split-per-abi`：均通过；split 产物由 Makefile 校验脚本确认存在且非空。当前 Java 运行时为 OpenJDK 25，Gradle 仅输出 restricted native access 与 SDK XML v4 兼容性提示，未影响构建。
- 五个 APK 版本化副本均通过 Android Build Tools 36.0.0 `apksigner verify --verbose`；签名仍为 Android Debug 证书，因此只作为本地 QA 候选。
- Edge 151 fresh-origin 人工路径：确认首页出现第六个“多重占卜”入口和第七个“塔罗/周易图鉴”入口；进入后右侧主体从顶部对齐，牌堆点击新增 A/B/C 组，已有组保持静止，点击 A 牌打开塔罗释义弹层，连续完成 6/6 组后顶部显示本卦／动爻／变卦和 A1～A6 摘要，返回回到工具目录。旧端口的 Service Worker 曾提供缓存的旧工具页面，切换到新 origin 后确认当前构建，不能把旧缓存截图作为证据。
- 本地产物校验清单已更新，源码校验清单包含 466 个文件；其他完整浏览器矩阵、Android 真实设备触觉和签名发布仍未写成通过。

## 动画时序与 D20 舞台修复复验

- `make check-format`：通过，237 个 Dart 文件，0 改动。
- `make analyze`：通过，0 issue。
- `flutter test`：573/573 通过；新增覆盖 D20 固定舞台高度、骰子数变化立即 reset、新结果延后到揭示完成、塔罗一次揭示模式只动画追加牌、图鉴交互和多副牌配置。
- 共享交互结论：生成阶段只展示冻结实体或牌背，揭示阶段只播放当前实体动画；最终数字、牌名／方向、硬币面值、最新爻信息和组合解释在完成阶段出现，减少动态直接进入完成结果。

本轮产物摘要：

| 产物 | 大小 | SHA-256 |
| :--- | ---: | :--- |
| `pocketools-v0.1.1-web.tar.gz` | 23,334,676 bytes | `86ed6ec0115933dd4512b6b584e4ced00fbb28f8f6a8513e3bdf051258c06f1b` |
| `pocketools-v0.1.1-debug.apk` | 192,165,910 bytes | `ffc8374db745565d094ef449976108fb8fae938838d2c36492152f7ea3153d7c` |
| `pocketools-v0.1.1-release.apk` | 63,887,510 bytes | `a0af9837d030e1fe67c1818672deebfb141fbdb0bb52901672fcdd5a56ae22b6` |
| `pocketools-v0.1.1-arm64-v8a-release.apk` | 28,275,296 bytes | `614e23cfa9c1a7ccf1e15c038f729f3e9ea548f543d65f3d19603b5e53e87852` |
| `pocketools-v0.1.1-armeabi-v7a-release.apk` | 25,749,448 bytes | `b40743e43f0c6183ff1588e7e703196d45ad33f26efb0d706e5571e939d10f73` |
| `pocketools-v0.1.1-x86_64-release.apk` | 29,824,556 bytes | `08a6e1e7e66b6718ee49bc45a1bc2935c495ed59d2a0d42799abf1ad087d6799` |

## v0.1.1+2 历史复验快照

- `make check-format`：通过，221 个 Dart 文件，0 改动。
- `make analyze`：通过，0 issue。
- `make test`：519/519 通过；其中既有 516/516 回归口径，并新增 3 个 Web shell widget contract 用例，覆盖桌面侧栏、右侧主体展开、主体顶部对齐和窄屏底部导航。
- 当前交互协议：唯一实体舞台为 `AppEntityStateView`，`AppGenerationStateView` 仅为其状态胶囊；D20/DND、硬币和六爻通过 `AppPhysicalAction`，塔罗和扑克通过 `AppPhysicalDeck` + `AppDeckResultFlow`，牌类每次点击只抽一张，`n` 为本轮目标。【已验证】
- Web shell 布局源码与 widget contract 已验证：桌面使用左侧 `NavigationRail` 侧栏，右侧主体 `Expanded` 占满剩余空间；`AppToolScaffold` 使用 `Alignment.topCenter` 对齐共享内容。该证据不等于本轮真实浏览器视觉验收。
- `make build-web`：通过，Web/PWA 产物生成，31 项自有 precache 资源通过校验；自有 Service Worker 缓存版本已升级为 v3。
- `make build-android`：通过，`assembleDebug` 成功；Flutter 3.47.1、JDK 17、Android compile/target 36、minSdk 24；APK `versionName=0.1.1`、`versionCode=2`，包名 `dev.pocketools.pocketools`。
- `make build-android-release`：通过，`assembleRelease` 成功；生成 63,641,750 bytes（约 63.6 MB）release 优化 APK 候选，`apksigner` v2 校验通过；证书为 Android Debug，未完成商店 release signing。
- `make build-android-release-split-per-abi`：通过，实际执行 `flutter build apk --release --split-per-abi` 并校验 3 个非空产物；固定输出目录为 `build/app/outputs/flutter-apk/`。arm64-v8a 为 28,209,760 bytes、armeabi-v7a 为 25,634,760 bytes、x86_64 为 29,759,020 bytes；universal、三 split 和 debug 共 5 个 APK 均由 `apksigner` 验证通过并通过 v2 签名校验。该命令是 ABI 级适配，不是 OEM 型号级适配。
- 真实 Edge 151 clean-origin：既有 v0.1.1 基线通过六个玩法工具核心页面验收；本轮增量未重复执行完整浏览器矩阵，当前交互收口以 widget/架构测试和生产构建为证据。
- 产物和源码证据保留在本地验收目录 `output/` 中；该目录不随源码提交。

本次发布目录中的实际 payload：

| 产物 | 大小 | SHA-256 |
| :--- | ---: | :--- |
| `pocketools-v0.1.1-web.tar.gz` | 23,314,270 bytes | `87d48a1512d0a84907a8bd1f5e49fc710f663388cc527c1854229cd56622fbe6` |
| `pocketools-v0.1.1-debug.apk` | 192,082,193 bytes | `4b2903fc1c024549740b3486cabd8899c1cebebb01cc5a9b88564359c4ccfbb3` |
| `pocketools-v0.1.1-release.apk` | 63,641,750 bytes | `44bfebc722b765397312243969b8276e047dbf5edf454ce7fdb9dedf40b0e8a0` |
| `pocketools-v0.1.1-arm64-v8a-release.apk` | 28,209,760 bytes | `71430e55ee281fcac41aff580d03b05e13036df7a4342f2aac20cca9d77671d5` |
| `pocketools-v0.1.1-armeabi-v7a-release.apk` | 25,634,760 bytes | `e17c0d142780af4d4fa037963c536856d3bd910edee00d93b88fad3c0680c72d` |
| `pocketools-v0.1.1-x86_64-release.apk` | 29,759,020 bytes | `0d6de4039f98f1ab1c4698a68cfd15e3f94ef55083d0d559dcc30858c5a5ac` |

`SOURCE-SHA256SUMS` 当前包含 466 个文件，源校验排除 `.dart_tool/`、`build/`、`output/`、`.git/`。

上述是 v0.1.1 本地交付门禁，不替代 Android 实体设备安装/振动、完整浏览器矩阵、release signing、hosted CI 或公共部署验收。

## 系统 Flutter 安装

用户授权后执行 `brew install --cask flutter`，Homebrew 成功安装并链接：

- Flutter：通过当前环境的 PATH 或 `FLUTTER_BIN` 提供。
- Dart：与 Flutter SDK 配套提供。
- Flutter 版本：3.47.1 stable，framework revision `6655482ec0`。
- Dart 版本：3.13.1 stable，macOS arm64。
- DevTools：2.60.0。

首次启动时 macOS 对 Homebrew Cask 下载的 `dart` 展示正常 Gatekeeper 提示。只读签名检查确认签名链为 `Developer ID Application: FLUTTER.IO LLC (S8QB4VV633)`，Apple 提示已检查且未发现恶意软件；随后通过系统“打开”动作完成首次批准。没有关闭 Gatekeeper、没有添加全局放行规则。

`flutter doctor -v` 的实际结果：

| 范围 | 结果 | 边界 |
| :--- | :--- | :--- |
| Flutter | 【通过】 | 3.47.1 stable，macOS 26.5.2 arm64 |
| Web | 【通过】 | Chrome 151.0.7922.172 可发现；实际交互验收使用 Edge 151.0.4129.101 |
| Android 全局发现 | 【未配置】 | 未把临时 Android SDK 写入全局 Flutter 配置；构建命令显式提供项目级 SDK 环境 |
| Xcode／CocoaPods | 【不在范围】 | Xcode 不完整且无 CocoaPods；v0.1.0 不交付 iOS/macOS 应用 |
| 设备 | 【部分】 | 可发现 macOS 与 Chrome；没有 Android 模拟器或实体设备 |

## Makefile Homebrew 兼容性修复

首次不带 `FLUTTER_BIN` 执行 `make verify` 时，Makefile 从 Flutter 符号链接的词法目录拼接 Dart 路径，错误查找链接目录下不存在的 SDK 缓存路径，因此 `check-dart` 退出 2。

按 TDD 流程补充 `Dart discovery follows a symlinked Flutter installation`：

| 节点 | 命令与结果 |
| :--- | :--- |
| 红灯 | `flutter test test/architecture/makefile_contract_test.dart`：4 PASS、1 FAIL；伪造的 symlink Flutter 无法发现同 SDK Dart |
| 最小修复 | Makefile 解析 Flutter 实际路径，优先选择同一 SDK 的 `cache/dart-sdk/bin/dart`，不存在时再回退 PATH |
| 绿灯 | 同一测试文件 5/5 PASS |
| 全量回归 | `env -u FLUTTER_BIN -u DART_BIN make verify` 退出 0 |

最终系统 Flutter 门禁：

- `check-format`：192 个 Dart 文件，0 改动。
- `analyze`：0 issue。
- 全仓自动化：403 PASS、0 FAIL、0 skip。
- Web production build：成功。
- 自有 PWA precache：31/31 资源通过。

独立 QA 在该回归测试加入前取得 402/402 PASS；403 是主项目经理随后增加 Homebrew symlink 回归用例后的最终唯一测试总数，不把重复聚焦执行累加到总数。

## 真实 Web 浏览器验收

实际环境为 Microsoft Edge 151.0.4129.101，使用本地 HTTP 服务加载 production `build/web`。浏览器验收构建与最终系统 Flutter 构建的 40 文件有序集合 SHA-256 完全相同：`36c9cb4b3004ded9294f0b7e5cfa46e6aa289e99b3809db53309a518e35fbb08`。

### 功能路径

- 首页展示六个玩法工具和一个图鉴入口。
- 塔罗完成单牌抽取并显示牌名、方向、关键词、简释和反思问题。
- 六爻完成六次自动投币，展示六次原始硬币、本卦、动爻、变卦和解释。
- D20 表达式 `3d12kh2+4` 正确映射到 3D12、keepHighest 2、modifier +4，并显示原始／保留／舍弃骰和总值。
- 硬币单次模式保留原始 heads／tails 语义。
- 扑克开启大小王、抽取 5 张后使用 54 张牌组，结果无重复、顺序可追溯、剩余 49 张。
- 历史显示上述玩法记录，刷新后仍恢复；详情可通过键盘进入。
- 分享预览默认包含工具、规则、结果和算法版本，默认排除 ID、父 ID、设备信息和精确时间。
- 系统预设复制、重命名为 `D20 优势桌`、刷新恢复和应用均通过；应用后为 2D20 keepHighest 1。
- 设置页展示主题、动画、减少动态、声音、振动、历史和本地数据选项；不展示来源、许可或内容边界入口。

### 响应式与控制台

首次验收发现缺少 viewport 声明，360 px 视口被渲染为 720 px；修复后在相同 production build 复测：

| 视口 | `innerWidth` | `body.scrollWidth` | `flutter-view` | 控制台 |
| :--- | :---: | :---: | :---: | :--- |
| 360 × 800 | 360 | 360 | 360 | 0 error、0 warning |
| 1024 × 800 | 1024 | 1024 | 1024 | 0 error、0 warning |

证据截图：

- 360 px、1024 px、修复前失败证据、扑克结果和脱敏分享预览均为本地 QA 截图，保存在被忽略的 `output/qa/`，不随源码提交。

### 离线 PWA

production 页面首次在线加载并安装自有 service worker 后，关闭本地 HTTP 服务，再对同一 URL 执行完整重载：

- 页面 `readyState=complete`，标题仍为 Pocketools。
- 首页六个玩法工具和图鉴入口全部可见。
- 1024 px 视口无横向溢出。
- 控制台 0 error、0 warning。
- `flutter_service_worker.js` 不存在，实际使用 `pocketools_service_worker.js`。

该证据证明已缓存构建可离线启动，不等同于覆盖所有浏览器的首次断网安装、长期缓存清理或跨版本 service worker 迁移。

## Android 构建验收

### Release APK 模式

`make build-android-release` 保持 Flutter 的 universal release 构建，产物为 `build/app/outputs/flutter-apk/app-release.apk`。需要按 CPU ABI 分发时使用：

```text
make build-android-release-split-per-abi
```

该目标执行 `flutter build apk --release --split-per-abi`，并由 `tool/verify_android_apks.dart` 校验：

| ABI | 产物 |
| :--- | :--- |
| `arm64-v8a` | `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` |
| `armeabi-v7a` | `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` |
| `x86_64` | `build/app/outputs/flutter-apk/app-x86_64-release.apk` |

这是 Android ABI 级适配：包按 CPU 指令集划分，适用于多个 OEM 厂商和设备型号；它不提供 OEM 型号级适配，也不声称针对某个品牌、型号或 SoC 的专属兼容性。真实设备安装、启动、传感器和振动仍需单独验证。

本次实际 split 产物及 SHA-256：

| 产物 | 大小 | SHA-256 |
| :--- | ---: | :--- |
| `app-arm64-v8a-release.apk` | 28,275,296 bytes | `614e23cfa9c1a7ccf1e15c038f729f3e9ea548f543d65f3d19603b5e53e87852` |
| `app-armeabi-v7a-release.apk` | 25,749,448 bytes | `b40743e43f0c6183ff1588e7e703196d45ad33f26efb0d706e5571e939d10f73` |
| `app-x86_64-release.apk` | 29,824,556 bytes | `08a6e1e7e66b6718ee49bc45a1bc2935c495ed59d2a0d42799abf1ad087d6799` |

universal release APK 为 63,887,510 bytes，SHA-256 为 `a0af9837d030e1fe67c1818672deebfb141fbdb0bb52901672fcdd5a56ae22b6`；本次发布目录已同步最新 universal 与 split 产物。

实际命令使用系统 Flutter，不提供临时 Flutter 路径：

```text
make build-android
```

本次最终复核的自动化测试为 573/573；最新 `assembleDebug`、`assembleRelease` 和 split-per-ABI 构建均已退出 0。Java 25 restricted native access 与 SDK XML v4／旧处理器兼容提示没有导致编译失败。

| 属性 | 实际值 |
| :--- | :--- |
| 应用 ID | `dev.pocketools.pocketools` |
| 应用名 | Pocketools |
| versionName／versionCode | `0.1.1`／`2` |
| minSdk | 24 |
| targetSdk／compileSdk | 36／36 |
| APK 签名 | Android Debug，APK Signature Scheme v2 验证通过 |
| APK 大小 | 192,165,910 bytes |
| APK SHA-256 | `ffc8374db745565d094ef449976108fb8fae938838d2c36492152f7ea3153d7c` |

APK 是供本地验收的 debug 包，不是 release 签名包，也没有在 Android 模拟器或实体设备上执行安装、启动、振动、返回栈、升级与卸载验证。

## 平台结论

- 系统 Flutter、Dart、Makefile、自动化测试、Web production build、真实 Edge 响应式与离线 PWA、Android debug build 和 release 优化 build 均有实际退出码或运行证据。【通过】
- Android 设备运行、发布签名、应用商店政策、真实灰度／升级／回退、Chrome／Firefox／Safari 浏览器矩阵和 hosted CI 没有执行。【未验证】
- 因此当前可交付结论是“v0.1.1 本地源码与本地产物候选”，不是“已公开发布”或“已通过应用商店验收”。

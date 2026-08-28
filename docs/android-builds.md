# Android 构建与设备适配

本文定义 Pocketools 第一版 Android APK 的构建入口、ABI 覆盖范围、产物选择和设备适配边界。它把“支持各种设备”和“为每个型号生成 APK”拆成可验证的工程概念，避免把一个 APK 错误地宣传成覆盖所有 OEM 型号。

## 产物类型

| 产物 | 命令 | 适配方式 | 适用场景 |
| :--- | :--- | :--- | :--- |
| Universal release APK | `make build-android-release` | 一个包内包含当前 Flutter 配置的全部 native ABI | 内部分发、未知设备、快速安装；文件较大 |
| `arm64-v8a` release APK | `make build-android-release-split-per-abi` | 64 位 ARM ABI | 绝大多数新款 Android 手机、平板和 ARM 设备 |
| `armeabi-v7a` release APK | `make build-android-release-split-per-abi` | 32 位 ARM ABI | 仍支持 32 位 ARM 的旧设备 |
| `x86_64` release APK | `make build-android-release-split-per-abi` | x86_64 ABI | x86_64 Android 模拟器、部分 ChromeOS/Intel 设备 |

split 命令一次生成后三个 ABI APK，输出到 `build/app/outputs/flutter-apk/`，文件名分别为：

```text
app-arm64-v8a-release.apk
app-armeabi-v7a-release.apk
app-x86_64-release.apk
```

本次 v0.1.1+2 本地构建的实际产物如下；APK 均通过 Android APK Signature Scheme v2 校验：

| 产物 | 大小 | SHA-256 |
| :--- | ---: | :--- |
| `pocketools-v0.1.1-release.apk` | 63,887,510 bytes | `a0af9837d030e1fe67c1818672deebfb141fbdb0bb52901672fcdd5a56ae22b6` |
| `pocketools-v0.1.1-arm64-v8a-release.apk` | 28,275,296 bytes | `614e23cfa9c1a7ccf1e15c038f729f3e9ea548f543d65f3d19603b5e53e87852` |
| `pocketools-v0.1.1-armeabi-v7a-release.apk` | 25,749,448 bytes | `b40743e43f0c6183ff1588e7e703196d45ad33f26efb0d706e5571e939d10f73` |
| `pocketools-v0.1.1-x86_64-release.apk` | 29,824,556 bytes | `08a6e1e7e66b6718ee49bc45a1bc2935c495ed59d2a0d42799abf1ad087d6799` |

上述产物仅用于本地验收，版本化副本位于被忽略的 `output/` 目录，不随源码提交；需要时重新执行对应的 Makefile 命令即可生成。

每个 APK 都经过 `tool/verify_android_apks.dart` 的存在性、非空和 Android 签名校验；需要查看签名细节时可以执行：

```bash
apksigner verify --verbose build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

## “每个型号”适配的实际边界

Android 的可分发 APK 通常按 CPU ABI、minSdk、屏幕/方向和系统能力分包，而不是按“华为某型号”“小米某型号”逐台编译。当前工程的 split-per-ABI 已经是针对设备 CPU 运行时的正确分包方式：同一个 ABI APK 可以覆盖多个 OEM 与型号，不需要为每个品牌复制一份 Dart 业务代码或资源。

当前版本不能也不应该自动生成每个 OEM 型号的专属 APK，原因是：

- OEM 型号不是稳定的 Flutter 编译维度；按型号复制 APK 会造成版本、签名、回滚和测试矩阵爆炸。
- 屏幕尺寸、Android API、传感器和振动能力应在运行时通过能力检测和降级处理，而不是伪造型号包。
- Google Play 等渠道可以根据 ABI、Android 版本、设备能力和渠道规则做设备定向；这与本地构建多个型号包是两个不同的步骤。

只有出现明确的型号差异，例如专用硬件、厂商 SDK、渠道资源或合规配置，才新增 Android product flavor。届时 flavor 只承载真正不同的配置，并继续复用 `lib/` 的工具模块和共享设计系统；不能为了“看起来针对型号”复制页面实现。

## 构建前提与版本边界

- Android `minSdk` 由 Flutter 配置为 24；`compileSdk`、`targetSdk` 和 NDK 使用当前 Flutter/Android 工具链配置。
- release 构建需要 JDK 17，以及可用的 Android SDK Platform、Build Tools、NDK 和 CMake。
- 当前 release 使用 Android debug signing config，只能作为本地 QA 候选，不能直接上传应用商店。
- 商店分发应进一步增加受保护的 release keystore、签名配置、AAB、Play App Bundle 的 ABI split 和真实设备安装矩阵。

## 体积与优化结论

Universal APK 同时携带多个 native ABI，因此会明显大于单 ABI APK。当前 universal release 为 63.9 MB；split-per-ABI 为 25.7–29.8 MB。体积差异的主要来源是 Flutter/native runtime，而不是页面代码；经典塔罗 78 张牌面是第二类可见资源开销。

优先级如下：

- 对直接下载或侧载：按设备 ABI 分发 split APK。
- 对应用商店：使用 AAB，让渠道在安装时按 ABI 和设备条件生成优化包。
- 不删除经典牌面、动效或必要语义资源来换取表面体积；若未来需要继续优化，应先对资源格式、重复 native 库和构建产物做可复查的体积分析。

## 当前未覆盖的验证

本地构建成功不等于真实设备兼容性已经完成。第一版仍需要在 API 24、当前目标 API、最新 Android 版本的 ARM 设备、32 位 ARM 设备和 x86_64 模拟器上分别验证安装、五种玩法、后台恢复、动画降级、振动降级和返回链路；没有这些设备证据时，不宣称“所有型号均已验证”。

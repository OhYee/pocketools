# GitHub Actions 与发布

仓库包含两条自动化流水线：

- `CI`：`master` 推送、Pull Request 和手工触发时运行。执行格式检查、静态分析、全量测试、Web 生产构建和 Android 分 ABI 构建，并保留 Web/APK 构建产物 7 天。
- `Release`：推送形如 `v0.1.3` 的版本标签时运行。标签必须与 `pubspec.yaml` 的版本名一致；流水线重复执行完整验证，构建签名 APK 与 Web 压缩包，生成 SHA-256 清单并创建 GitHub Release。

## Android 发布签名

在 GitHub 仓库的 `release` Environment 中配置以下 Actions Secrets：

- `ANDROID_KEYSTORE_BASE64`：Android keystore 文件的 Base64 内容。
- `ANDROID_KEY_ALIAS`：签名 key alias。
- `ANDROID_KEY_PASSWORD`：签名 key 密码。
- `ANDROID_STORE_PASSWORD`：keystore 密码。

macOS 可用以下命令生成 keystore 的单行 Base64 内容：

```bash
base64 -i /absolute/path/to/release.keystore | tr -d '\n'
```

发布流水线缺少任一签名 Secret 都会失败，不会将 debug 签名候选上传为正式 Release。普通 CI 和本地未配置签名环境变量时仍使用 debug key 构建可安装候选包。

## 发布步骤

先更新 `pubspec.yaml` 中的版本并合入 `master`，例如 `version: 0.1.3+4`，然后创建并推送与版本名一致的标签：

```bash
git tag -a v0.1.3 -m "万象匣 v0.1.3"
git push origin v0.1.3
```

Release 包含三个 ABI APK、Web 构建压缩包和 `SHA256SUMS.txt`。如需人工批准，可在 GitHub 的 `release` Environment 中启用 required reviewers。

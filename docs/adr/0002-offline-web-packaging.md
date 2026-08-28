# Web/PWA 离线打包与缓存策略

- **状态**：已接受并实现；31 项 precache、真实 Edge 在线／离线与 360／1024 响应式验收通过。
- **日期**：2026-08-23。
- **决策人**：项目经理。
- **关联需求**：FR-001、FR-042、FR-046、NFR-006、NFR-008、NFR-009、REL-005、REL-006、REL-008、REL-009、REL-011。

## 背景

Pocketools 的五个核心工具、历史、预设复用和文本复制必须在首次安装缓存完成后离线可用。只取得 `flutter build web` 成功不能证明这一点。

Flutter 当前官方文档明确说明，Flutter 不再默认生成或管理可用于离线应用缓存的 service worker。Flutter 3.47 构建目录中的 `flutter_service_worker.js` 可能只是用于注销旧 worker 的迁移占位；把该文件存在当作 PWA 离线证据会得到错误结论。

默认 Web 构建还可以从 CDN 加载 CanvasKit 等引擎资源。即使先前构建目录残留本地 `canvaskit/` 文件，运行时仍可能选择远程 URL，因此必须同时控制构建参数、bootstrap 和浏览器网络证据。

## 决策

### 使用自有 service worker

仓库维护 `web/pocketools_service_worker.js`，由 `web/flutter_bootstrap.js` 注册。bootstrap 不再向 Flutter loader 传入已弃用的 `serviceWorkerSettings`。

- 注册失败只影响离线能力，不能阻断当前在线页面启动。
- worker 名称、cache 前缀和 scope 使用 Pocketools 命名空间。
- install 阶段预缓存启动和核心运行资源，缓存成功后才声明离线候选就绪。
- activate 阶段只删除旧 Pocketools cache，不调用全局 `caches.keys()` 后无差别删除其他应用数据。
- navigation 请求在线优先并以缓存的 `index.html` 回退；同源静态 GET 使用受控缓存。
- 非 GET、跨源请求、浏览器扩展和未知 scheme 不进入应用缓存。

### 本地打包 Web 引擎资源

`make build-web` 使用 Flutter 的 `--no-web-resources-cdn` 参数。生产 bootstrap 明确使用构建目录中的 CanvasKit 路径，不把 gstatic 或其他远程引擎 CDN 当作离线依赖。

service worker 的预缓存清单至少覆盖：

- `index.html`、`flutter_bootstrap.js`、`flutter.js` 和 `main.dart.js`；
- manifest、version、favicon 和四个 PWA icon；
- Flutter asset manifest、字体 manifest、聚合 NOTICE、Material/Cupertino 字体和运行时 shader；
- 当前 JavaScript 构建在支持浏览器中可能选择的本地 CanvasKit 变体及对应 Wasm。

清单必须与实际干净构建对照。任一必需文件缺失应让离线门禁失败，不能吞错后宣称已缓存。

### 每次构建先清理明确输出目录

`make build-web` 只删除项目拥有且可重建的绝对目标 `$(CURDIR)/build/web`，随后重新构建。这样旧 service worker、旧 CanvasKit、旧 hash 或已删除资源不会混入候选包。

该删除不扩展到工作区根目录、用户历史、浏览器数据、凭据或工作区外路径。

### 缓存版本与升级

cache 名称包含应用版本或构建版本。新 worker 激活后删除旧 Pocketools cache，并让后续导航获取新 `index.html`。

- 已完成会话的数据位于 LocalStorage/DataStore 适配器，不写入 Cache Storage。
- worker 升级不得修改、迁移或删除本地会话。
- 发布回退必须同时回退 Web bundle 与兼容的存储 schema；旧应用读取未知会话版本时按存储 ADR 隔离，不静默丢弃。

### PWA 响应式边界

manifest 使用 `display: standalone` 与不锁定方向的 `orientation: any`。安装后的移动端和桌面端继续使用同一响应式导航与共享组件，不创建独立 PWA 页面风格。

## 被否决方案

### 依赖 Flutter 自动生成的 worker

该路径已被 Flutter 官方弃用，当前生成文件可能主动注销自身，不能满足离线 PWA。

### 只保留构建目录里的旧 CanvasKit

文件存在不代表 loader 会读取本地路径，而且脏输出会把旧文件伪装成当前构建资产。

### 运行时首次访问再被动缓存全部请求

这种方案无法保证用户只完成一次在线加载后就拥有完整核心资源，也容易把跨源或失败响应写入缓存。

### 缓存网络 API 或用户结果

v0.1.0 没有业务网络 API；用户会话使用版本化本地存储。把结果写入 Cache Storage 会形成第二份数据协议和删除旁路。

## 验证要求

- 从干净的 `build/web` 执行一次 `make build-web`，确认自有 worker、bootstrap 和所有预缓存资源存在。
- 构建命令实际包含 `--no-web-resources-cdn`；bootstrap 不传 deprecated `serviceWorkerSettings`。
- worker 源码和构建产物的 cache 清理只匹配 Pocketools 前缀。
- 用 HTTP server 首次在线打开，等待 worker activated 和核心 cache 完整；记录浏览器 Application/Network 证据。
- 切换浏览器 offline 后执行硬重载，首页、五个工具、设置、历史和文本复制仍可打开并完成核心操作。
- 离线运行期间没有 gstatic、远程字体、远程图片、远程内容或业务 API 请求。
- 更新 cache 版本后在线重载取得新 shell；旧会话仍可读取。回退时未知 schema 被隔离而非删除。
- Chrome 为首个实际运行矩阵；Safari、Edge、Firefox 只在实际执行后标记通过。未执行的平台保持未覆盖。

## 参考

- [Flutter Web FAQ](https://docs.flutter.dev/platform-integration/web/faq)
- [Flutter Web 构建与发布](https://docs.flutter.dev/deployment/web)
- [Flutter 支持平台矩阵](https://docs.flutter.dev/reference/supported-platforms)

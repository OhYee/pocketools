# Pocketools 活动设计稿索引

- **状态日期**：2026-08-23。
- **当前结论**：十一张活动设计证据已通过；根目录为 `02`、`03`、`04`、`05`，Round-4 为 `01`、`07`、`08`、`09`、`10c`、`10d` 与 assembled。旧 `01-mobile-core-experience` 的 Round-2 accepted 历史保留，但已从五工具完整首页活动基线退出并移入 `audit-only/`。G1 交互与视觉设计验收为【PASS】。
- **文件规格**：历史 Round-2 源图均为 `1672 × 941`；revision-2 `07` 源图为 `1693 × 929`，`08` 为 `1536 × 1024`，`10c/10d` Web 源图均为 `1586 × 992`。4K review、`1600 × 1000` tiles 与 assembled 均为确定性后处理产物，不是模型原生 4K 或固定源尺寸证明。
- **模型边界**：`model=gpt-image-2`、`quality=high` 是任务请求值；本轮视觉验收没有取得新增的可机器核验 model metadata。
- **运行时状态**：`runtimeAsset=false`，图片只用于内部设计评审，不作为 Flutter、Web、分享卡或发布资产。
- **许可状态**：内部设计参考，待 PM 最终 G1 许可结论。

## 第二轮候选

| 资产 | 源图 SHA-256 | 4K 候选 SHA-256 | 结论 | 活动目录 |
| :--- | :----------- | :--------------- | :--- | :------- |
| `01-mobile-core-experience.png` | `ec1739c521baa1ef00473d31b6d24dd88aff793e20e9634e8103fe67e66a85ca` | `d4847939824ac086dff7be937d705f304022e6398f8fb5da8a7f6f0e3a4f96c0` | `accepted` | 已复制 |
| `02-motion-tarot.png` | `a1c84e267d16648c1df7c4c4775755a30ebf54a1f12ff371f5632e87831a0254` | `d53c3788d62e8357c8ed6cf20d9ae83151f2c0254aa3fc3bd78e9160fe49e6ea` | `needs_revision` | 未复制 |
| `03-motion-liuyao.png` | `4fc5c832f51085e406811675ec4593c910ba9e2ffc11740ad502fe21b7f2ec5d` | `f30731e26cd764329c889860acf00c524beec52c45fefd60650a10ee1ee378ba` | `needs_revision` | 未复制 |
| `04-motion-dice.png` | `193052b9a59de1683e54a7fe58aec03e5cee83d53ad3881157e31428fda929e1` | `8f573ff6783cfb31401649e6d00cf3a7e812996983286e25b7e5106099ec33e1` | `accepted` | 已复制 |
| `05-motion-coin.png` | `6f4594c4b0be8712e3a28095a55b7d9e0f57b7136add4ae5ecc648d2f7220343` | `54be468405aa1ae7d4c66640b2b3761fdbfab8044bcce29f81e9270f18daa2bb` | `needs_revision` | 未复制 |
| `06-responsive-web.png` | `c7de5afd60accb8983781493f7fe1835f8dd474c749eff71f82daefd0a0ae2ed` | `47f0f32b37655b72d31b0d7ef3b718993f64f98c48f8cb55acee178fe7a5b121` | `needs_revision` | 未复制 |

源图位于 `output/imagegen/round-2/source/`，候选位于 `output/imagegen/round-2/`。首轮同名文件仍分别位于 `output/imagegen/source/` 与 `output/imagegen/` 根目录，不得与第二轮混用。

## 活动设计稿

| 文件 | 用途 | 活动文件 SHA-256 |
| :--- | :--- | :---------------- |
| `02-motion-tarot.png` | 塔罗三牌导航、关键词与五态限定范围视觉基线 | `e00af6e88a982d7c432abaddd6fddc2756df4b213fd4a519310640863a4e5734` |
| `03-motion-liuyao.png` | 六爻第三爻中性占位、规则一致性与五态限定范围视觉基线 | `589ba68b9e165d34f5b9e104a165fd0d0fcc9304e47d0d20c6803ae3744e6f06` |
| `04-motion-dice.png` | DND/D20 按压、生成、揭示、完成和减少动态五态视觉基线 | `8f573ff6783cfb31401649e6d00cf3a7e812996983286e25b7e5106099ec33e1` |
| `05-motion-coin.png` | 批量硬币序列、统计、导航与五态限定范围视觉基线 | `6cd09ee78ece2cae005bd0a2dc263da79402c2c432576cd3623e084467538502` |
| `round-4/01-mobile-poker-core.png` | 五工具移动首页、扑克默认配置与不可变有序结果视觉基线 | `e78640c8ed8d52c804dcfac2496b9a5105632cb602378fbef2466966a1752431` |
| `round-4/07-motion-poker.png` | 扑克五态、无放回、冻结恢复同结果、新会话重抽、朱红／黑／暖白与减少动态视觉基线 | `5400f88aeed0ae16cf8f112b26cb241f112169629206441cf2b7d51bb4f352bc` |
| `round-4/08-explanations.png` | 塔罗／六爻解释结构、来源、免责声明与许可边界视觉基线 | `f0b075bb3f7681683fed3901c066db9c1c7be03c5195cfe99fd8f304962c4803` |
| `round-4/09-shared-components-feedback.png` | 七个共享组件、按钮样式单点调整、响应式、反馈矩阵与架构边界视觉基线 | `cd9d857a8b31bd4c1a81e75643451a0cd5563e4acba2ef9b4b62aea06bb07f73` |
| `round-4/10c-tarot-liuyao-explanations.png` | 桌面塔罗／六爻解释、来源状态和 `runtimeAsset=false` 边界视觉基线 | `3f212800de97cb371780e0f7ae33352088b4ba0793f9903b499f8ae3fa32ed51` |
| `round-4/10d-history-share-settings.png` | 恰好五工具历史筛选、脱敏分享与独立反馈设置视觉基线 | `c44fae16e8d7f578e81757f11d72221ca68f5726da05da4b310cbd2d24544718` |
| `round-4/10-responsive-expanded-assembled.png` | 四张 Web 独立页面的完整无裁切确定性组装基线 | `749b1017a21e244538091b3cc7780c32b357562d1289475ef48aab932da0549e` |

十一张活动文件与对应 accepted 评审候选字节一致。`05` 不证明新增单枚硬币真实感抛起／翻转／落定或触觉实现；`07` 的注释不证明平台 haptic/vibration 已实现；`09` 不替代组件 API、可访问性与平台能力测试。所有活动图片只证明所列范围，不替代精确交互、tokens 或实现测试。

## Expanded Round-4 第一批

| 资产 | 源图尺寸与 SHA-256 | 4K 评审副本 SHA-256 | 后处理 | 结论 |
| :--- | :----------------- | :-------------------- | :----- | :--- |
| `01-mobile-poker-core.png` | `1536 × 1024`；`84bcab4a3e69b65df7ff77092215c7c005398e347a3c1e8b40befa043087b03f` | `e78640c8ed8d52c804dcfac2496b9a5105632cb602378fbef2466966a1752431` | fit `3240 × 2160`，左右各补 `300 px` | `accepted`，已复制 |
| `07-motion-poker.png` | `1690 × 931`；`9f72f13e9b75bfae283b4a71ed21aeeb1eed8b1151034dc4028cd112c1b3` | `7c0e3cea2040f0006d8b8750a1df0b76a9f696cce15d5a1033d30d95f18ff621` | fit `3840 × 2115`，上补 `22 px`、下补 `23 px` | 首版 `needs_revision` 历史证据，未复制 |

两张评审副本均使用完整源图 aspect-fit 与 `#F7F7F5` padding，未裁剪 UI、未非均匀缩放；4K 是后处理评审规格。`07` 的修订 prompt 已要求每帧显式“无放回”，完成／减少动态态显式“重新抽取会创建新会话”，生成／揭示／中断恢复显式“继续同一已冻结结果，不重抽”，并要求扑克主按钮、工具选中态和牌背统一使用 `playingCards` 朱红 `#B4232A` 与墨黑／暖白；蓝色只允许作为 token 许可的系统 focus ring。

## Expanded Round-4 第二批移动与组件证据

| 资产 | 源图尺寸与 SHA-256 | 4K 评审副本 SHA-256 | 确定性后处理 | 结论 |
| :--- | :----------------- | :-------------------- | :------------- | :--- |
| `08-explanations.png` | `1536 × 1024`；`da6c9f5ea3e8002feebb6abdec07be80e3f1972bbf62b35ae321175065d46f0e` | `c0beea094abd38598dbc9bf21a4d7ed0fda459286e051ac2268587f1afd4632d` | fit `3240 × 2160`，左右各补 `300 px`，RMSE `0` | `needs_revision`；错误宣称原创简释已获 app 使用许可并已进入内容包，未复制 |
| `09-shared-components-feedback.png` | `1536 × 1024`；`81d5311920113d9fc7f87bdd273d87f8c4f7204d2d69a1b592606155db6a7c8f` | `cd9d857a8b31bd4c1a81e75643451a0cd5563e4acba2ef9b4b62aea06bb07f73` | fit `3240 × 2160`，左右各补 `300 px`，RMSE `0` | `accepted`，已复制 |

两张源图均完整 aspect-fit 到 `3840 × 2160` 暖白 `#F7F7F5` 画布，不裁切、不拉伸。`08` 首版失败边界已由 revision-2 修正并通过，见后文最终验收。

## Expanded Round-4 Web 首版滚动验收

| 页面 | 源图 SHA-256 | `1600 × 1000` tile SHA-256 | 结论 |
| :--- | :----------- | :------------------------- | :--- |
| `10a-five-tools-home.png` | `1f9147c9c57bd4a352e787413119c23ec4b1319785e04580cf166795fe4d9592` | `f173451a1e64140753aa12ae08938942ef0fd0ae7c779443d29315009858ac8b` | `accepted_tile`；五工具首页与响应式桌面信息架构通过 |
| `10b-poker-config-result.png` | `64f83b5f94b3241d399ede4edb535c592ff9b298d79f411f8aac4fa066d229cf` | `3b8d2e684365d1438aa78e205f2556ad7c3f696617e127cb30aabbb239d150f7` | `accepted_tile`；默认 52 张、大小王关闭、抽 3／剩 49 与固定原序通过 |
| `10c-tarot-liuyao-explanations.png` | `938b1e5acee12b9cec5ebc63fa82a4c8b3b6712c484d2b6d0dd52ef49ecacea0` | `13cc6b01c62b3c1dffc693d4ca93d60e5ccde905e96bdace00fd55eed2a464ff` | `needs_revision_tile`；只修塔罗来源区“可发布”误判 |
| `10d-history-share-settings.png` | `4bf9c1924030a724f06b54fc1c0c958dac3366180ac784fb6da54a844dcfe6d1` | `eeac2a8c24d56968d1ac57bc08398e08e5e6bf1dfde48efcea67c5511baef76d` | `needs_revision_tile`；只修历史筛选器为当前五工具 |

四张首版 Web 源图实际均为 `1586 × 992`。每张机器后处理均为完整 aspect-fit 到 `1599 × 1000`，左补 `0 px`、右补 `1 px`、上下补 `0 px`，背景 `#F7F7F5`，不裁切、不拉伸，像素复核 RMSE 均为 `0`。首版 assembled 文件为 `3840 × 2160`，SHA-256 `fd2c38aaeb98e689dd7dee5845a2734ecb9ae6b9462e55510e392c7190c1af40`；因 `10c/10d` 未通过，历史状态保留为 `needs_revision`。`10a/10b` 没有重生成。

## Expanded Round-4 revision-2 最终验收

| 资产 | 实际源图尺寸与 SHA-256 | 最终评审文件与 SHA-256 | 后处理与结论 |
| :--- | :---------------------- | :---------------------- | :------------- |
| `07-motion-poker.png` | `1693 × 929`；`5a48ccccf29e5abca84175925d79f92d185da935b8aaf557c38e97f356d2a8fd` | `3840 × 2160`；`5400f88aeed0ae16cf8f112b26cb241f112169629206441cf2b7d51bb4f352bc` | fit `3840 × 2107`，上 `26 px`、下 `27 px`，RMSE `0`；`accepted`，已复制 |
| `08-explanations.png` | `1536 × 1024`；`eef36b7d819ee0794e10171dfed103a88d4550d1d343a9bfade4b247aeee1d48` | `3840 × 2160`；`f0b075bb3f7681683fed3901c066db9c1c7be03c5195cfe99fd8f304962c4803` | fit `3240 × 2160`，左右各 `300 px`，RMSE `0`；`accepted`，已复制 |
| `10c-tarot-liuyao-explanations.png` | `1586 × 992`；`5369aa38d77ea9bed68837d56aa617eaa1bcb6c9fd70ce06690cd57ea2ef05f7` | `1600 × 1000`；`3f212800de97cb371780e0f7ae33352088b4ba0793f9903b499f8ae3fa32ed51` | fit `1599 × 1000`，右补 `1 px`，RMSE `0`；`accepted_tile`，已复制 |
| `10d-history-share-settings.png` | `1586 × 992`；`b06dd5aa8619de9bdfe3bdba307f2a4878f460c99682b95b28f7e610161f07d7` | `1600 × 1000`；`c44fae16e8d7f578e81757f11d72221ca68f5726da05da4b310cbd2d24544718` | fit `1599 × 1000`，右补 `1 px`，RMSE `0`；`accepted_tile`，已复制 |
| `10-responsive-expanded-assembled.png` | 复用 accepted `10a/10b` 与 revision-2 `10c/10d` tiles | `3840 × 2160`；`749b1017a21e244538091b3cc7780c32b357562d1289475ef48aab932da0549e` | 坐标 `(160,40)`、`(2080,40)`、`(160,1120)`、`(2080,1120)`，RMSE `0`；`accepted`，已复制 |

视觉硬门禁结果：`07` 五帧均含无放回、冻结恢复同结果、新会话重抽、扑克朱红／黑／暖白与减少动态；`08/10c` 均明确内部参考、待 PM 许可、复核前不发布且没有已授权暗示；`10d` 恰好五工具、分享私人字段默认关闭、振动与减少动态独立且无公开链接；assembled 四页完整无裁切。

## Superseded 与 audit-only

| 文件 | 状态 | 保留价值 | SHA-256 |
| :--- | :--- | :------- | :------- |
| `audit-only/01-mobile-core-experience.png` | `superseded/audit-only` | Round-2 D20 自定义配置与结果细节；四工具首页不得继续作为完整首页基线 | `d4847939824ac086dff7be937d705f304022e6398f8fb5da8a7f6f0e3a4f96c0` |
| `output/imagegen/round-3/web-source/06a-home.png` | `scope-invalidated/audit-only` | 扩围前桌面首页层级；缺扑克且尺寸为 `1568 × 1003` | `6678c75c0c135baa825a06a700e47fd7d0002b97beff5c262744e2299b5d4413` |
| `output/imagegen/round-3/web-source/06b-d20-config.png` | `scope-invalidated/audit-only` | 扩围前 D20 桌面配置层级；尺寸为 `1586 × 992` | `b9ebc31c241e79f216072d6d24912d9681aa569ba2763ab2c1d81f93c2cd942d` |

## 当前状态

- Expanded Round-4 没有 pending 或 needs_revision 资产；八个独立资产均已通过。
- `10a/10b` 保持 `accepted_tile` 并作为新 assembled 的组成证据，不单独复制到活动目录。
- 首版 `07/08/10c/10d` 和首版 assembled 的失败文件与 SHA 保留，不进入活动目录。
- Round-3 Web `06a/06b` 不参与任何组装；`06c/06d` 不存在。

Round-3 定向建议和完整逐图证据见 [设计稿视觉验收](../mockup-review.md)。

## 使用边界

- 交互、规则、中文关键文案、状态、键盘、焦点、屏幕阅读器和 200% 字体以 [交互设计](../../interaction-design.md) 为准。
- 色彩、排版、间距、圆角、材料、触觉、动效数值和断点以 [设计系统](../design-system.md) 与 [设计令牌](../tokens.json) 为准。
- accepted 图片中的说明性注释不能自动变成产品控件；D20 画板底部“跳过／中断／恢复”是 app frame 外的规格说明，产品内仍只允许揭示态“跳过动画”。
- `needs_revision`、`needs_revision_tile`、`pending_revision`、`superseded`、`scope-invalidated`、`audit-only` 和 `pending` 图片不得作为布局、视觉或资产实现依据；`accepted_tile` 只有在 manifest 指明用途时可作为单页或 assembled 组成证据。
- needs_revision 候选不得用于布局测量、组件实现、规则推导、运行时资源、商店截图、分享卡或宣传材料。
- 图片不能证明键盘、读屏、200% 字体、错误、离线、中断恢复、平板连续重排或精确 motion token 已实现；这些覆盖由精确文档、组件测试和端到端测试承担。
- 当前 G1 交互与视觉设计验收为【PASS】；该结论不改变 `runtimeAsset=false`、内部设计参考、待 PM 最终许可复核的发布与法律边界。

## 历史证据

- 三张旧 built-in PNG 仍位于 [拒绝归档](../archive/rejected-built-in/README.md)，状态为【已否决、不可实现依据】。
- 首轮六张 gpt-image-2 源图和候选仍在原路径，全部为 `needs_revision` 证据；首轮哈希未改变。

# Pocketools gpt-image-2 设计稿生成与验收记录

- **状态日期**：2026-08-23。
- **当前状态**：Expanded Round-4 八个独立资产已完成滚动复核并全部通过；revision-2 的 `07/08/10c/10d` 与复用 accepted `10a/10b` 的新 assembled 均已通过视觉硬门禁和确定性后处理复核。交互与视觉设计 G1 为【PASS】；Round-1/2/3 历史结论与 SHA-256 保持不变。
- **活动设计稿**：共十一张：根目录 `02`、`03`、`04`、`05`，Round-4 `01`、`07`、`08`、`09`、`10c`、`10d` 与 assembled。`10a/10b` 作为 assembled 的 accepted tile 证据保留，不单独计入活动文件；所有图片均为 `runtimeAsset=false`。
- **首轮状态**：六张原始稿和六张后处理候选均继续保留为 `needs_revision` 证据，路径与 SHA-256 未改变。
- **精确基线**：[交互设计](../interaction-design.md)、[设计系统](design-system.md) 与 [设计令牌](tokens.json)。
- **资产用途**：`runtimeAsset=false`，只用于内部设计评审。
- **许可状态**：内部设计参考，待 PM 最终 G1 许可结论。

## 首轮生成与证据边界

- 用户请求参数为 `model=gpt-image-2`、`quality=high`、`size=3840x2160`、PNG、不透明背景。
- 实际图片通过平台 imagegen 通道按任务要求生成；工具没有返回可机器核验的模型或质量 metadata，因此证据表述固定为“平台 imagegen 通道按任务要求生成，CLI metadata 未验证”。manifest 中的 `model` 与 `quality` 是任务请求值，不是从图片文件或工具响应反查出的 metadata。
- 原始模型输出保存在 `output/imagegen/source/`，六张均为 `1672 × 941` 不透明 PNG。
- `output/imagegen/` 下的同名候选均经后处理规格化为 `3840 × 2160` 不透明 PNG。这里的 4K 只描述评审归档像素规格，不代表模型原生 4K 输出。
- 显式 CLI 尝试因执行环境中的 `OPENAI_API_KEY` 认证失败返回 HTTP 401，且没有产生任何 CLI 图片。记录只保留失败类型和“无产物”事实，不记录密钥值。
- 首轮生成日期为 2026-08-23；源图与归档候选的身份分别由尺寸、不透明状态和 SHA-256 固定。
- 首轮证据路径 `output/imagegen/source/` 与 `output/imagegen/*.png` 为只读评审证据。第二轮不得覆盖、替换、移动或复用这些文件，也不得改写下表或 manifest 中的首轮 SHA-256。

## 首轮文件证据

| 资产 | 原始输出 `1672 × 941` SHA-256 | 归档候选 `3840 × 2160` SHA-256 | 验收 |
| :--- | :--------------------------- | :-------------------------------- | :--- |
| `01-mobile-core-experience.png` | `37e0f8b68b429211282211b286860820f42dbba549b9a73d25b553253283bb44` | `bc4772bee038aba30837dd159b1c215eecca1a64acaac3dd03b0523b8caba1c6` | `needs_revision` |
| `02-motion-tarot.png` | `c6c8a5ea906bced9e3e4a9d889db16c569bf87600f6ab957dce962e3495b6569` | `b40b5807a75edc28298f13bcd62a5ef5652ce2b84eccb8bc537d0035d4c3a972` | `needs_revision` |
| `03-motion-liuyao.png` | `f0e19ee09a59be3becdcda317d5bca2628363da8079494650ed9f52e01409efa` | `fee40a6e479b5d08757bcdf5fe0c4a0571822409d5a84ef89cf5db2f2a3746b0` | `needs_revision` |
| `04-motion-dice.png` | `241d8c6c7bd195785c0f099a35e0a851b5a8c926553b8dd7db6fcd5c947cc3c3` | `d3e4e0bade8199ee2dc02d4bfe3f9fb58ead7c5c85a224eb6f3d0193035d816c` | `needs_revision` |
| `05-motion-coin.png` | `88e3365ad5f8d6dc430f9dbe8e4fa7df19eb509fbddc35da28b5e6ef76a77b17` | `acc9aeda35a976dca785fcf4298878999477c82ece46b93a87023c6bfc1b48ab` | `needs_revision` |
| `06-responsive-web.png` | `43ef6be298646e85c047cc43871b8876f01ec87fbda4fca312d9d8a14a89cd7a` | `1c4dfde500a6fc2b0afcfdf49250623f53e5d0a26fb1756c7ad0382c006b453a` | `needs_revision` |

归档候选和原始输出一一同名。视觉验收使用原始分辨率逐张完整查看，不能把后处理规格化当成模型能力或视觉通过证据。

## 验收结论

| 资产 | 符合项 | 阻塞问题 |
| :--- | :----- | :------- |
| 移动核心体验 | 首页工具齐全；FR-047 的 `4d20 keepHighest 3 + 5`、`DC 35`、原始顺序 `8、16、4、12`、保留／舍弃与总值 `41` 正确 | 配置页和结果页错误选中底栏“首页”，工具路由应选中“工具” |
| 塔罗五态 | 五态、时长、easing 和抽象牌面方向成立；没有传统或具体版权牌面 | 三牌按钮误写为“生成结果”；按压和生成态出现无规则来源的数字 `36` |
| 六爻五态 | 自动／手工选择、五态和时间线可辨；投掷物没有面额或货币标志 | 前两爻画为实线却标注“阴 · 静爻”；第 3 爻在按压态已经出现断线，违反先生成后揭示 |
| D20 五态 | FR-047 的四枚骰、保留规则、公式、总值与 DC 判断准确；五态时长清楚 | 完成态仍使用“掷骰”而非“再来一次”；移动导航错误；五态均混入未定义的“中断／继续”调试控制 |
| 硬币五态 | 五态时间线和十次批量意图清楚 | 范围误写为 `1～1000` 而非 FR-028 的 `1～100`；实际序列为正面 5、反面 5，却汇总为 6、4；生成态出现近似实体金属币堆 |
| 响应式 Web | 首页、D20 配置／结果、历史与分享层级清楚；D20 数值正确；没有实体货币、具体塔罗牌面或第三方标志 | 四个子 frame 约为 `1.85:1`，没有保持独立 `1440 × 900` 的 `16:10` 桌面比例 |

完整逐图证据与禁止照抄项见 [设计稿评审](mockup-review.md)。任一阻塞问题都可能让实现采用错误导航、错误随机规则、错误状态或错误响应式约束，因此六张候选均不复制到 `docs/design/mockups/`。

## 第二轮文件证据

- 本验收任务没有调用图像生成；只检查已存在的 round-2 文件、复制 accepted 候选并更新证据。
- 第二轮原始文件位于 `output/imagegen/round-2/source/`，六张均为 `1672 × 941` 不透明 PNG。
- 第二轮候选位于 `output/imagegen/round-2/`，六张均经后处理规格化为 `3840 × 2160` 不透明 PNG；4K 仍不是模型原生输出证明。
- 第二轮生成通道与 model metadata 没有在本验收任务中获得新的机器可验证证据；manifest 继续把 `gpt-image-2`、`high` 标为任务请求值，不能反推为文件 metadata。
- 六组候选下采样后与同名源图的归一化 RMSE 为 `0.0120～0.0165`，未发现首轮文件或不同资产错配。

| 资产 | 第二轮源图 SHA-256 | 第二轮 4K 候选 SHA-256 | 结论 | 活动目录 |
| :--- | :----------------- | :---------------------- | :--- | :------- |
| `01-mobile-core-experience.png` | `ec1739c521baa1ef00473d31b6d24dd88aff793e20e9634e8103fe67e66a85ca` | `d4847939824ac086dff7be937d705f304022e6398f8fb5da8a7f6f0e3a4f96c0` | `accepted` | 已复制 |
| `02-motion-tarot.png` | `a1c84e267d16648c1df7c4c4775755a30ebf54a1f12ff371f5632e87831a0254` | `d53c3788d62e8357c8ed6cf20d9ae83151f2c0254aa3fc3bd78e9160fe49e6ea` | `needs_revision` | 未复制 |
| `03-motion-liuyao.png` | `4fc5c832f51085e406811675ec4593c910ba9e2ffc11740ad502fe21b7f2ec5d` | `f30731e26cd764329c889860acf00c524beec52c45fefd60650a10ee1ee378ba` | `needs_revision` | 未复制 |
| `04-motion-dice.png` | `193052b9a59de1683e54a7fe58aec03e5cee83d53ad3881157e31428fda929e1` | `8f573ff6783cfb31401649e6d00cf3a7e812996983286e25b7e5106099ec33e1` | `accepted` | 已复制 |
| `05-motion-coin.png` | `6f4594c4b0be8712e3a28095a55b7d9e0f57b7136add4ae5ecc648d2f7220343` | `54be468405aa1ae7d4c66640b2b3761fdbfab8044bcce29f81e9270f18daa2bb` | `needs_revision` | 未复制 |
| `06-responsive-web.png` | `c7de5afd60accb8983781493f7fe1835f8dd474c749eff71f82daefd0a0ae2ed` | `47f0f32b37655b72d31b0d7ef3b718993f64f98c48f8cb55acee178fe7a5b121` | `needs_revision` | 未复制 |

## 第二轮视觉结论

| 资产 | 已通过项 | 阻塞问题 |
| :--- | :------- | :------- |
| 移动核心体验 | 三帧导航、FR-047 配置、原始骰序、舍弃、公式、总值和 DC 全部一致 | 无；`accepted` |
| 塔罗五态 | “抽取三张牌”、五态、逆位开启、无来源数字和抽象无版权牌面正确 | 五个 frame 使用错误的三项移动底栏；完成态缺少每张关键词行 |
| 六爻五态 | 前两爻实线阳静爻、完成态断线阴少阴静爻、和值 8 和自下而上顺序正确 | 生成态圆片分色提前泄露最终正反正；标题误写“刘耀”；缺少四项移动底栏 |
| D20 五态 | 工具导航、“再来一次”、原序、舍弃、公式、DC 与五态正确 | 无；`accepted`。app frame 外的跳过／中断／恢复仅为规格注释 |
| 硬币五态 | `1～100`、十项序列、`5 / 5`、`50% / 50%` 和抽象标记正确 | 五个完整移动 frame 缺少四项底栏 |
| 响应式 Web | 桌面层级、D20 数值、历史分享和禁止资产正确 | 四个子 frame 约 `805 × 443`、`1.82:1`，仍非独立 `16:10` |

详细逐图检查和 Round-3 建议见 [设计稿视觉验收](mockup-review.md)。

## Round-3 实际证据与结论

本轮没有调用图像生成，只读取磁盘上的 Round-3 文件并视觉复核。三张移动源图均为 `1672 × 941` 不透明 PNG，三张候选均为 `3840 × 2160` 不透明 PNG；4K 仍只表示后处理评审副本。

| 资产 | Round-3 源图 SHA-256 | Round-3 候选 SHA-256 | 结论 | 覆盖边界 |
| :--- | :-------------------- | :-------------------- | :--- | :------- |
| `02-motion-tarot.png` | `95b3dd8a21b05f9b09701ff209dfee1047365366cef37348d6952084234b00ff` | `e00af6e88a982d7c432abaddd6fddc2756df4b213fd4a519310640863a4e5734` | `accepted` | 四项导航、工具选中、三牌关键词、五态与抽象牌面 |
| `03-motion-liuyao.png` | `b4def4bdcd6e1562b1d8934aff10294d8edfb24bb83637390f6778d0866b5af0` | `589ba68b9e165d34f5b9e104a165fd0d0fcc9304e47d0d20c6803ae3744e6f06` | `accepted` | 标题、四项导航、中性第三爻占位、正／反／正、和值 8 与阴静爻 |
| `05-motion-coin.png` | `1ffa7e07ea284169307ae49965233b9b3b1077d4c59b19ed6cf7a0f5d3bf62cc` | `6cd09ee78ece2cae005bd0a2dc263da79402c2c432576cd3623e084467538502` | `accepted_scoped` | 批量 `1～100`、固定十项序列、`5/5`、`50%/50%`、四项导航与五态；不证明新增单枚真实感物理动效或 haptics |

Round-3 Web 只发现两张前置范围源图：`06a-home.png` 为 `1568 × 1003`、SHA-256 `6678c75c0c135baa825a06a700e47fd7d0002b97beff5c262744e2299b5d4413`；`06b-d20-config.png` 为 `1586 × 992`、SHA-256 `b9ebc31c241e79f216072d6d24912d9681aa569ba2763ab2c1d81f93c2cd942d`。两者实际尺寸不符合旧 manifest 假设，`06c/06d` 不存在，且首页缺少新增扑克，因此整体标记 `scope-invalidated/audit-only`，不裁剪、不补齐、不组装。

## Expanded Round-4 生成目标

Round-4 共八份独立 prompt。平台可能返回不同源尺寸；文档只记录请求值和实际文件证据，不宣称原生 4K、原生 `1600 × 1000` 或固定源像素。前四张横向 board 在获得实际源图后，以“完整源图 aspect-fit + 纯背景 padding”为默认方式生成 `3840 × 2160` 评审副本；只有视觉确认被裁区域全是纯背景时才允许裁剪，且必须记录裁剪坐标与新 hash。

| 目标 | Prompt | 计划源图 | 计划评审副本 |
| :--- | :----- | :------- | :----------- |
| 五工具首页＋扑克配置＋结果 | `round-4/01-mobile-poker-core.txt` | `output/imagegen/round-4/source/01-mobile-poker-core.png` | `output/imagegen/round-4/review/01-mobile-poker-core.png` |
| 扑克五态＋haptic 注释 | `round-4/07-motion-poker.txt` | `output/imagegen/round-4/source/07-motion-poker.png` | `output/imagegen/round-4/review/07-motion-poker.png` |
| 塔罗／六爻解释与来源边界 | `round-4/08-explanations.txt` | `output/imagegen/round-4/source/08-explanations.png` | `output/imagegen/round-4/review/08-explanations.png` |
| 共享组件／反馈／平台降级 | `round-4/09-shared-components-feedback.txt` | `output/imagegen/round-4/source/09-shared-components-feedback.png` | `output/imagegen/round-4/review/09-shared-components-feedback.png` |

## Expanded Round-4 第一批实际证据

本次只验收 `01-mobile-poker-core` 与 `07-motion-poker`，没有调用图像生成。两张源图均按完整画面等比缩放，并使用设计令牌背景 `#F7F7F5` 居中补边至不透明 `3840 × 2160`；像素比对确认评审副本与该确定性处理结果的 RMSE 均为 `0`。4K 仅表示后处理评审规格，不是平台原生输出能力。

| 资产 | 实际源图与 SHA-256 | Aspect-fit 与 padding | 4K 评审副本 SHA-256 | 判定与归档 |
| :--- | :------------------ | :-------------------- | :--------------------- | :----------- |
| `01-mobile-poker-core.png` | `1536 × 1024`；`84bcab4a3e69b65df7ff77092215c7c005398e347a3c1e8b40befa043087b03f` | fit `3240 × 2160`；左／右各 `300 px`，上／下 `0 px` | `e78640c8ed8d52c804dcfac2496b9a5105632cb602378fbef2466966a1752431` | `accepted`；已复制到 `docs/design/mockups/round-4/` |
| `07-motion-poker.png` | `1690 × 931`；`9f72f13e9b75b275bfae283b4a71ed21aeeb1eed8b1151034dc4028cd112c1b3` | fit `3840 × 2115`；上 `22 px`、下 `23 px`，左／右 `0 px` | `7c0e3cea2040f0006d8b8750a1df0b76a9f696cce15d5a1033d30d95f18ff621` | 首版 `needs_revision` 历史证据，未复制 |

`01` 的五工具首页、默认 52 张／大小王关闭、抽 3 张／剩余 49 张、黑桃 A／红桃 10／梅花 K 原序、无放回、新会话重抽、四项导航、中文与无博彩边界均一致。`07` 的五态、结果先冻结、四项导航、Android 阶段触觉与 Web 条件化 no-op 正确，但缺少可见“无放回”、新会话和中断恢复合同，且扑克强调色误用蓝色，未遵循 `playingCards` 的朱红、墨黑与中性纸面 token。

`07` 的首版失败源图和 4K SHA 保持不变。其四项返工门槛为：五帧逐帧显示“无放回”；完成／减少动态写明重新抽取创建新会话；生成／揭示／中断注释写明恢复同一冻结结果且不重抽；扑克主操作、工具选中态和牌背固定使用朱红 `#B4232A`、墨黑与暖白，蓝色只允许作为共享 focus ring。revision-2 已满足并通过，见后文最终证据。

## Expanded Round-4 第二批移动证据

本次只读取已存在的 `08/09` 源图和评审副本，没有调用图像生成。两张源图均为 `1536 × 1024`，完整 aspect-fit 为 `3240 × 2160`，使用 `#F7F7F5` 在左右各补 `300 px` 后得到不透明 `3840 × 2160`；与确定性重建结果的 RMSE 均为 `0`。

| 资产 | 源图 SHA-256 | 4K 评审副本 SHA-256 | 判定 | 归档 |
| :--- | :----------- | :-------------------- | :--- | :--- |
| `08-explanations.png` | `da6c9f5ea3e8002feebb6abdec07be80e3f1972bbf62b35ae321175065d46f0e` | `c0beea094abd38598dbc9bf21a4d7ed0fda459286e051ac2268587f1afd4632d` | 首版 `needs_revision` 历史证据；原创简释曾越过许可边界 | 未复制 |
| `09-shared-components-feedback.png` | `81d5311920113d9fc7f87bdd273d87f8c4f7204d2d69a1b592606155db6a7c8f` | `cd9d857a8b31bd4c1a81e75643451a0cd5563e4acba2ef9b4b62aea06bb07f73` | `accepted`：七共享组件、单点按钮样式、light/dark、响应式、反馈矩阵与架构边界完整 | 已复制到 `docs/design/mockups/round-4/` |

## Expanded Round-4 revision-2 最终证据

本次验收没有调用图像生成，只读取已存在的 revision-2 源图、标准化评审副本、Web tiles 和 assembled。旧失败文件不覆盖，原 SHA-256 与失败判定继续作为历史证据。

| 目标 | 实际源图与 SHA-256 | 派生文件与 SHA-256 | 确定性后处理 | 结论 |
| :--- | :------------------ | :------------------ | :------------- | :--- |
| `07-motion-poker` | `1693 × 929`；`5a48ccccf29e5abca84175925d79f92d185da935b8aaf557c38e97f356d2a8fd` | `3840 × 2160`；`5400f88aeed0ae16cf8f112b26cb241f112169629206441cf2b7d51bb4f352bc` | 完整 fit `3840 × 2107`，上 `26 px`、下 `27 px`，RMSE `0` | `accepted_revision2`，已复制 |
| `08-explanations` | `1536 × 1024`；`eef36b7d819ee0794e10171dfed103a88d4550d1d343a9bfade4b247aeee1d48` | `3840 × 2160`；`f0b075bb3f7681683fed3901c066db9c1c7be03c5195cfe99fd8f304962c4803` | 完整 fit `3240 × 2160`，左右各 `300 px`，RMSE `0` | `accepted_revision2`，已复制 |
| `10c-tarot-liuyao-explanations` | `1586 × 992`；`5369aa38d77ea9bed68837d56aa617eaa1bcb6c9fd70ce06690cd57ea2ef05f7` | `1600 × 1000`；`3f212800de97cb371780e0f7ae33352088b4ba0793f9903b499f8ae3fa32ed51` | 完整 fit `1599 × 1000`，右补 `1 px`，RMSE `0` | `accepted_revision2_tile`，已复制 |
| `10d-history-share-settings` | `1586 × 992`；`b06dd5aa8619de9bdfe3bdba307f2a4878f460c99682b95b28f7e610161f07d7` | `1600 × 1000`；`c44fae16e8d7f578e81757f11d72221ca68f5726da05da4b310cbd2d24544718` | 完整 fit `1599 × 1000`，右补 `1 px`，RMSE `0` | `accepted_revision2_tile`，已复制 |

- `07` 五帧均显示“无放回”；生成、揭示和中断说明固定同一已冻结结果且不重抽；完成与减少动态说明重新抽取创建新会话。主按钮、工具选中态和牌背均使用 `playingCards` 朱红、墨黑与暖白，减少动态为同一记录的静态收束。
- `08/10c` 均明确 `runtimeAsset=false`、内部设计参考、待 PM 最终许可复核和复核前不发布／不进入发布内容包；传统原文、现代改写与原创简释均没有已许可或可发布暗示。
- `10d` 的筛选器恰好包含塔罗、六爻起卦、D20 检定、硬币、扑克牌；分享私人字段默认关闭，不生成公开链接；振动与减少动态为独立设置。
- `10a/10b` 保持原 accepted tile，不重生成。新 assembled 复用其既有 tile，并使用 revision-2 的 `10c/10d`。

## Expanded Round-4 Web 后处理与组装

四份 Web prompt 各自只生成一张独立 `16:10` 页面构图，不硬编码平台源输出像素。实际源图位于 `output/imagegen/round-4/web-source/`。每张生成后先记录 `W × H`、不透明性和 SHA，再按下列确定性默认算法建立 `1600 × 1000` tile：

```text
scale = min(1600 / W, 1000 / H)
fitWidth = round(W * scale)
fitHeight = round(H * scale)
offsetX = floor((1600 - fitWidth) / 2)
offsetY = floor((1000 - fitHeight) / 2)
tile = opaque 1600x1000 theme background
paste resized whole source at (offsetX, offsetY)
```

默认不裁剪。若源图包含可机器和视觉确认的纯背景 gutter，可先裁纯背景；必须保证页面边框、文字、阴影、焦点与所有 UI 不损失，并把裁剪矩形写回 manifest。禁止非均匀缩放。

| 页面 | Prompt | 源图 | Tile | 组装坐标 |
| :--- | :----- | :--- | :--- | :------- |
| 五工具首页 | `round-4-web/10a-five-tools-home.txt` | `output/imagegen/round-4/web-source/10a-five-tools-home.png` | `output/imagegen/round-4/web-tiles/10a-five-tools-home.png` | `(160,40)` |
| 扑克配置＋结果 | `round-4-web/10b-poker-config-result.txt` | `output/imagegen/round-4/web-source/10b-poker-config-result.png` | `output/imagegen/round-4/web-tiles/10b-poker-config-result.png` | `(2080,40)` |
| 塔罗／六爻解释 | `round-4-web/10c-tarot-liuyao-explanations.txt` | `output/imagegen/round-4/web-source/10c-tarot-liuyao-explanations.png` | `output/imagegen/round-4/web-tiles/10c-tarot-liuyao-explanations.png` | `(160,1120)` |
| 历史＋分享＋设置 | `round-4-web/10d-history-share-settings.txt` | `output/imagegen/round-4/web-source/10d-history-share-settings.png` | `output/imagegen/round-4/web-tiles/10d-history-share-settings.png` | `(2080,1120)` |

最终画布为不透明 `3840 × 2160`，四个 tile 均为 `1600 × 1000`，横间隔 `320 px`、纵间隔 `80 px`，外边距为左右各 `160 px`、上下各 `40 px`。最终路径固定为 `output/imagegen/round-4/web/10-responsive-expanded-assembled.png`。四张源图与 tile 全部通过尺寸、内容和 hash 复核前不得组装；组装成功也不等于 accepted。

### Web 实际文件与视觉结论

四张源图实际均为 `1586 × 992`。每张完整源图等比 fit 为 `1599 × 1000`，以 `#F7F7F5` 在右侧补 `1 px` 后得到对应不透明 `1600 × 1000` tile；四组 tile 与确定性重建结果 RMSE 均为 `0`，没有裁切或非均匀缩放。

| Tile | 源图 SHA-256 | Tile SHA-256 | 视觉结论 |
| :--- | :----------- | :------------ | :------- |
| `10a-five-tools-home.png` | `1f9147c9c57bd4a352e787413119c23ec4b1319785e04580cf166795fe4d9592` | `f173451a1e64140753aa12ae08938942ef0fd0ae7c779443d29315009858ac8b` | `accepted_tile`：五工具首页、离线、两条非私人固定摘要、导航与焦点正确 |
| `10b-poker-config-result.png` | `64f83b5f94b3241d399ede4edb535c592ff9b298d79f411f8aac4fa066d229cf` | `3b8d2e684365d1438aa78e205f2556ad7c3f696617e127cb30aabbb239d150f7` | `accepted_tile`：默认 52 张、无放回、抽 3 剩 49、固定牌序／ID、新会话与朱红主题正确 |
| `10c-tarot-liuyao-explanations.png` | `938b1e5acee12b9cec5ebc63fa82a4c8b3b6712c484d2b6d0dd52ef49ecacea0` | `13cc6b01c62b3c1dffc693d4ca93d60e5ccde905e96bdace00fd55eed2a464ff` | 首版 `needs_revision_tile` 历史证据；塔罗来源错误写为“状态：可发布” |
| `10d-history-share-settings.png` | `4bf9c1924030a724f06b54fc1c0c958dac3366180ac784fb6da54a844dcfe6d1` | `eeac2a8c24d56968d1ac57bc08398e08e5e6bf1dfde48efcea67c5511baef76d` | 首版 `needs_revision_tile` 历史证据；筛选遗漏塔罗／六爻并混入未上线工具 |

该段首版 assembled 文件为 `3840 × 2160` 不透明 PNG，SHA-256 为 `fd2c38aaeb98e689dd7dee5845a2734ecb9ae6b9462e55510e392c7190c1af40`。它与四个首版 tile 在 `(160,40)`、`(2080,40)`、`(160,1120)`、`(2080,1120)` 的确定性组装结果 RMSE 为 `0`，几何通过；由于包含首版 `10c/10d` 内容错误，历史判定保持 `needs_revision`、未复制。

revision-2 assembled 位于 `output/imagegen/round-4/revision-2/web/10-responsive-expanded-assembled.png`，为 `3840 × 2160` 不透明 PNG，SHA-256 `749b1017a21e244538091b3cc7780c32b357562d1289475ef48aab932da0549e`。它复用 `10a` tile `f173451a1e64140753aa12ae08938942ef0fd0ae7c779443d29315009858ac8b`、`10b` tile `3b8d2e684365d1438aa78e205f2556ad7c3f696617e127cb30aabbb239d150f7`，并使用 revision-2 `10c` tile `3f212800de97cb371780e0f7ae33352088b4ba0793f9903b499f8ae3fa32ed51`、`10d` tile `c44fae16e8d7f578e81757f11d72221ca68f5726da05da4b310cbd2d24544718`。坐标、间隔和外边距不变，确定性重建 RMSE 为 `0`；视觉复核确认四页完整、无裁切、拉伸、错位或不可读区域，判定 `accepted` 并已复制到活动目录。

## 归档规则

- `output/imagegen/source/` 与 `output/imagegen/*.png` 保留首轮拒绝证据；`output/imagegen/round-2/source/` 与 `output/imagegen/round-2/*.png` 只承载第二轮新产物。两个轮次不得互相覆盖。
- Round-3 实际移动文件保留在 `output/imagegen/round-3/`；两张 Web 前置范围源图保留 audit-only，不裁剪、不组装。Expanded Round-4 必须使用 manifest 中独立的 `output/imagegen/round-4/` 路径，不覆盖任何历史文件。
- 只有当前 `accepted` 的最终候选允许进入 `docs/design/mockups/` 活动树。根目录为 `02`、`03`、`04`、`05` 四张；Round-4 子目录为 `01`、`07`、`08`、`09`、`10c`、`10d` 与 assembled 七张。`10a/10b` 为 assembled 的 accepted tile 证据，不单独进入活动目录；旧 `01-mobile-core-experience` 仍为 audit-only。
- Round-1/2 历史尺寸、透明性、SHA-256 和判定均保持不变；Round-3 新 hash 单独记录，不沿用或覆盖历史值。
- 图片不精确承担键盘、焦点、屏幕阅读器、200% 字体、错误、离线、中断恢复、平板连续重排或 motion token 的实现验收；这些仍以精确基线和实现测试为准。

## 验证命令

以下命令不读取或输出密钥：

```bash
jq empty docs/design/gpt-image-2-manifest.json
find output/imagegen/source -maxdepth 1 -type f -name '*.png' -print | sort
find output/imagegen -maxdepth 1 -type f -name '*.png' -print | sort
find output/imagegen/round-2/source -maxdepth 1 -type f -name '*.png' -print | sort
find output/imagegen/round-2 -maxdepth 1 -type f -name '*.png' -print | sort
find output/imagegen/round-3 -type f -name '*.png' -print | sort
find output/imagegen/round-4/source output/imagegen/round-4/review -maxdepth 1 -type f -name '*.png' -print | sort
find output/imagegen/round-4/web-source output/imagegen/round-4/web-tiles output/imagegen/round-4/web -type f -name '*.png' -print | sort
find output/imagegen/round-4/revision-2 -type f -name '*.png' -print | sort
find docs/design/mockups -type f -name '*.png' ! -path '*/audit-only/*' -print | sort
find docs/design/gpt-image-2-prompts/round-4 docs/design/gpt-image-2-prompts/round-4-web -type f -name '*.txt' -print | sort
identify -format '%i %wx%h opaque=%[opaque]\n' output/imagegen/source/*.png output/imagegen/*.png output/imagegen/round-2/source/*.png output/imagegen/round-2/*.png output/imagegen/round-3/source/*.png output/imagegen/round-3/*.png output/imagegen/round-3/web-source/*.png output/imagegen/round-4/source/*.png output/imagegen/round-4/review/*.png output/imagegen/round-4/web-source/*.png output/imagegen/round-4/web-tiles/*.png output/imagegen/round-4/web/*.png output/imagegen/round-4/revision-2/source/*.png output/imagegen/round-4/revision-2/review/*.png output/imagegen/round-4/revision-2/web-source/*.png output/imagegen/round-4/revision-2/web-tiles/*.png output/imagegen/round-4/revision-2/web/*.png
shasum -a 256 output/imagegen/source/*.png output/imagegen/*.png output/imagegen/round-2/source/*.png output/imagegen/round-2/*.png output/imagegen/round-3/source/*.png output/imagegen/round-3/*.png output/imagegen/round-3/web-source/*.png output/imagegen/round-4/source/*.png output/imagegen/round-4/review/*.png output/imagegen/round-4/web-source/*.png output/imagegen/round-4/web-tiles/*.png output/imagegen/round-4/web/*.png output/imagegen/round-4/revision-2/source/*.png output/imagegen/round-4/revision-2/review/*.png output/imagegen/round-4/revision-2/web-source/*.png output/imagegen/round-4/revision-2/web-tiles/*.png output/imagegen/round-4/revision-2/web/*.png
```

## G1 设计验收

- **结论**：【PASS】。Expanded Round-4 八个独立资产均已通过；十一张活动文件与 manifest 的 `activeMockupCount=11` 一致。revision-2 的 `07/08/10c/10d` 和新 assembled 提供本次缺口的明确视觉与机器证据。
- **准入范围**：PASS 仅表示交互与视觉设计基线具备实现依据。开发可结合 accepted 图片、交互设计、设计系统和 tokens 实现五工具首页、扑克流程、解释页、共享组件、反馈降级与 expanded Web 页面。
- **证据层级**：`10a/10b` 仍是 assembled 的 accepted tile 证据；revision-2 assembled 是完整 Web 基线。首轮、旧 Round-4 失败图、旧 assembled、superseded 和 audit-only 文件继续保留原判定，不能反向覆盖当前基线。
- **非图片覆盖**：键盘、焦点、屏幕阅读器、200% 字体、错误、离线、中断恢复、连续响应式重排和精确 motion token 仍由精确文档与实现测试验收。
- **许可边界**：全部图片仍为 `runtimeAsset=false`、内部设计参考、待 PM 最终许可复核；G1 设计 PASS 不等于运行时资产许可、内容发布批准、商店材料批准或法律结论。

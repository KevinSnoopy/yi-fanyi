# tokens · Design Token 全表（T-013）

> Round-5 产出。Token 唯一出口：`app/lib/ui/tokens/`（barrel [`tokens.dart`](tokens.dart)）。
> 口径：**以现行实现 + 原型 v7-spa styles.css 为准**；PRD v3.2 §5.2 是其子集。
> 旧位置 `app/lib/core/theme/tokens.dart` 已删除（2026-09-27 T-013 迁移）。

## 文件结构

| 文件 | 内容 | 消费方式 |
|---|---|---|
| `lf_scheme.dart` | 浅/深主题色彩（ThemeExtension，31 项） | `LfScheme.of(context).brand` |
| `lf_dimens.dart` | 字阶 / 圆角 / 尺寸 / 动效 / 链路节奏（与主题无关） | `LfDimens.fsBase` 等静态常量 |
| `lf_components.dart` | PRD §5.3 组件规格 ①–⑥ 聚合（`LfComponents.pill` 等） | `LfComponents.pill.minW` |
| `app_theme.dart`（留在 core/theme） | ThemeData 组装（TextTheme/Switch/Input 等 Material 层） | `AppTheme.light()/dark()` |

## 色彩 Token（LfScheme，浅 / 深）

| Token | 浅色 | 深色 | 用途 |
|---|---|---|---|
| `brand` | #4F7CFF | #5B8CFF | 品牌主色（PRD §5.2 ✓） |
| `brand2` | #7B5CFF | #8E74FF | 渐变副色 |
| `brandSoft` / `brandSoft2` | 8% / 13% 主色底 | 12% / 20% | 淡底 / hover |
| `accent` | #FF7A45 | #FF8A5C | 强调色 CTA（PRD §5.2 ✓） |
| `bgBar` | #FFFFFF @ 92% | #1E1F24 @ 92% | 录音条底（⚖️ T-A，深色 PRD 写 88%） |
| `bgSource` | #F7F8FA | #131519 | 页面底色 / 原文区底 |
| `bgWindow` | #FFFFFF | #1E1F24 | 窗口 / 卡片底 |
| `bgHover` | #F0F1F5 | #26282E | hover（⚖️ T-B，PRD 深色写 #26282F） |
| `text` / `text2` / `text3` | #1D2129 / #86909C / #C9CDD4 | #E8EAED / #9AA0A6 / #5F6368 | 正文/次要/辅助（PRD §5.2 ✓ 前两级） |
| `divider` / `dividerStrong` | #F0F1F5 / #E5E7EB | #2E3038 / #3A3D45 | 分割线（PRD §5.2 ✓） |
| `error` / `success` / `warning` | #F53F3F / #2BA471 / #FF7D00 | #F76965 / #3CCB91 / #FFA940 | 错误态（PRD §5.2 ✓） |
| `brandGrad` | 4F7CFF→7B5CFF | 5B8CFF→8E74FF | 品牌渐变（mic 圆钮等） |
| `shadowXs/Md/Popover/Window/Bar/Brand` | 6 档投影 | 同构加深 | xs 微浮 / md 卡片 / popover / 主窗 / 录音条 / 品牌钮 |
| `menubarBg/Text/Border` | #F8F8FA @ 88% 等 | #1C1C1E @ 92% 等 | 菜单栏（macOS 原生观感） |
| `macClose/Min/Max` | #FF5F57 / #FEBC2E / #28C840 | 同左 | macOS 红绿灯（主题无关） |

字体：PingFang SC / HarmonyOS Sans / Inter（`app_theme.dart` fontFamilyFallback，PRD §5.2 ✓）。

## 几何 Token（LfDimens）

| 组 | Token |
|---|---|
| 字阶 | fs2xs 10 / fsXs 11 / fsSm 12 / fsBase 13 / fsMd 15 / fsLg 17 / fsXl 20 |
| 圆角 | rBtn 8 / rInput 10 / rCard 10 / rPopover 14 / rPill 999 |
| 尺寸 | barH 36（pill 高）/ pillMinW 160 / pillMaxW 400 / popoverW 380 / selectionWinW 320 / windowW 960 / windowH 640 / sideNavW 190 / menubarH 26 |
| 动效 | tFast 120ms / tBase 180ms / tExit 220ms / ease Cubic(0.2,0.8,0.2,1) |
| 链路节奏 | previewWindow 1.2s（后悔窗口）/ doneFadeout 1.5s |

## 组件规格 ①–⑥（LfComponents，取值 = 现行实现实测）

| 规格 | 组 | 关键 token |
|---|---|---|
| ① 录音/状态条（ADR-008） | `LfComponents.pill` | 160×36 基准 / maxW 400 / bg 97% / 活跃描边 brand@55% 1.2px / 状态点 8 + 光晕 / 波形 10×3(maxH14) / 「译」开关 h22 thumb16 默认关 / 预览 ≤2 行 44px / mic 圆钮 52 |
| ② 迷你悬浮窗 | `LfComponents.floatWin` | 380×自适应(min120/max480) / r14 / 头部 pad(14,10,14,8) / 原文区 r10 / 进度条 h2 / 原文 12px 次要 / 译文 15px |
| ③ 划词小窗 | `LfComponents.selection` | 320×自适应 / r14 / pad12 / 图标钮 24 r7（复制/替换/朗读/收藏/进主窗）/ 原文 12 上、译文 15 下 |
| ④ 设置页主窗 | `LfComponents.settings` | 960×640（min 720×480）/ 左导航 190 / 卡片 r10 |
| ⑤ 移动端键盘 | `LfComponents.kb` | 工具条 h36 / 键盘底 #D1D4DA / 工具条底 #E4E6EB（iOS 皮肤固定色，不随主题） |
| ⑥ 首次引导 | `LfComponents.onboarding` | 三步（选平台→填 Key→设热键）/ 面板宽 560 / hero 图 56 / 权限徽标 28 |

## Token 层差异清单（⚖️ 待拍板，拍板前实现为准）

| # | 差异 | PRD §5.2 | 现行 Token | 建议 |
|---|---|---|---|---|
| T-A | 悬浮窗底深色 alpha | #1E1F24**E0**（88%） | `bgBar` 深 = 92%（#EB1E1F24，与浅色 92% 对称） | **实现为准**：两主题同 alpha 更一致，且原型 styles.css 实测 0xEB；建议改 PRD §5.2 |
| T-B | 原文区底深色 | **#26282F** | `bgHover` 深 = #26282E（原型值，尾位 -1） | **实现为准**：视觉无差（同色系尾位舍入），建议改 PRD §5.2 |
| T-C | PRD 未定义的补充 token | — | bgSource 深 #131519、text3、warning、menubar*、mac*、6 档 shadow 等 | 无需动作：PRD §5.2 为最小集，原型/实现自然扩展，已在本表登记 |

> 其余 PRD §5.2 六行（brand/accent/悬浮窗底浅色/正文/分割线/错误态/字体）全部一致 ✓。

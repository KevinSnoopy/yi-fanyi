# Competitor Research · 同类产品设计调研

> **背景**：译语 v1 原型（录音条 + 悬浮窗）被用户否决。
> 用户原话：「你借鉴的是有道翻译，他是上个世纪的产品」「该产品的目的应该是通过语音输入在任何输入框内输入文字，包括翻译等」。
> 调研目的：弄清「语音输入为主、翻译可选」这个赛道的产品范式，避免再次做出有道范式。
>
> **方法**：
> 1. curl 抓 4 个官网 HTML → Python 解析 CSS 变量 / 颜色 / 圆角 / 字体 / h2 顺序
> 2. images_search_and_download 搜官方 hero / app 截图 + terminal curl 落地 9 张
> 3. mcp_matrix_images_understand 逐张 vision 分析（**1 张/次，避免 timeout**）
>
> 调研用图：见本目录下 9 张产品截图（来源：官方 + 评测）

---

## 一句话赛道总结

**这个赛道的产品定位全是「Speak, don't type」类，翻译是 feature 之一，不是主角。**

| 产品 | slogan | 翻译位置 | 平台 |
|---|---|---|---|
| Typeless | Speak, don't type | 2nd feature (Dictate → Translate → Ask) | macOS (Win 路上) |
| Wispr Flow | Don't type, just speak | 末尾 feature | Mac/Win/iPhone/Android |
| Spokenly | Think out loud, Work 4x faster | 100+ 语言里提一句 | Mac/Win/Linux/iPhone |
| MacWhisper | （friendly redesign 叙事） | 支持，但定位是「任意音频转录」 | macOS only |

**所有产品的差异化锚都是「跨 App 工作」+「隐私优先」**。翻译从来不是核心叙事。

---

## 共性特征（4 家都遵循）

1. **翻译功能降级**：4 家都没把翻译当主卖点，普遍是 2nd / 3rd feature
2. **跨 App 叙事**：Typeless 展示 154 个 app logo；Wispr "every app"；Spokenly "in any app"——这是这一类产品的核心差异化
3. **隐私优先**：Typeless "Private by design" / Wispr "Your voice stays yours" / MacWhisper "locally on your Mac"
4. **暗色 UI 为主**：4 家都偏暗，#0A0A0A / #1A1A1A / rgba(29,26,26) 等深色背景
5. **大圆角**：16-24px 为主，少数 8-12px 小元素
6. **字体**：Inter / SF Pro Display / SF Pro Text 这类无衬线
7. **AI 润色是标配**：自动去「嗯啊」、自动改口、自我纠正（4 家都有）

---

## 范式对比：旧 PRD vs 真实赛道

| 维度 | 旧 PRD v2.0（被否决） | 真实同类产品 |
|---|---|---|
| 主角 | 翻译（语言切换） | 语音输入 |
| 翻译位置 | 第一卖点 | 第二或更后 |
| 输入范式 | 任意输入框 | 任意输入框 ✅（一致） |
| 触发 | 按住 Fn | 按住 Fn / 自定义键 ✅ |
| 产品命名 | "译语 / LinguaFlow" | （翻译不是名字的来源） |
| 隐私 | BYOK（差异化） | 4 家都强调，BYOK 是更彻底的姿态 |

---

## 对译语产品定位的启示

### 1. PRD §1 一句话定位建议重写

旧：「按住说话（或打一句话），译文自动落进你正在输入的地方——用你自己的模型 Key，离线也能用」
新方向：「按住说话，AI 把你的话润色成文，写到你正在输入的任何地方——翻译只是开关之一」

### 2. PRD §5.3 组件分类需要重排

旧版把"录音条 + 迷你悬浮窗"当两个并列组件，对应"录音 + 翻译"两个流程。
真实范式应该是：
- **核心组件 A：录音条（Typeless 式）** — 全场景常驻入口
- **核心组件 B：跟随光标浮条（Wispr Flow 式 Flow Bar）** — 在输入位置附近浮出，含"语言切换 / Profile 切换 / 翻译开关"
- **次要组件 C：设置面板** — 含模型选择 / 个人词库 / Profile 管理

### 3. 翻译功能的产品化路径

参考 Typeless 的"Translate as you speak"（100+ 语言，边说边译），
译语可以做成：
- **开关形式**：录音条右侧一个小开关，默认关闭
- **跟随 UI**：开启后，悬浮窗显示双语（原+译），关闭后只显示成稿
- **不要做主角**：翻译不应该是用户进来看到的第一个 UI 状态

### 4. 视觉语言建议

| 元素 | 4 家共识 | 译语建议 |
|---|---|---|
| 主题 | 暗色为主 | 深色 + 浅色双主题 |
| 主色 | 蓝/蓝紫 (Wispr #4D65FF) / 多彩 | 选一个克制主色（如 #4F7CFF 接近 Wispr），强调色做点缀 |
| 圆角 | 16-24px 大圆角 | 悬浮窗 16-20，按钮 8-12 |
| 字体 | Inter / SF Pro | Inter（跨平台一致） |
| 阴影 | 24% 黑，blur 24 | 沿用 PRD §5.2 |

### 5. 必避的错误（再次）

- ❌ 把翻译当主入口（v1 错的就是这个）
- ❌ "原文 + 译文"双语对比布局（这是有道范式）
- ❌ 顶部 🌐 语言切换器占据 C 位
- ❌ 输入框 + 发送按钮的悬浮窗（这是聊天产品范式）
- ❌ 「中→英」型翻译态文字（如「翻译中…」、「译文已生成」）

---

## 下一步

1. 跟用户对齐 PRD §1 / §5.3 改动方向（**等你拍**）
2. 改 PRD 后画 v2 原型

---

## 视觉层观察（vision 分析 9 张产品截图后总结）

### Typeless（最关键参考）

**Hero 区**（typeless-hero-voice.webp）：
- 上白下黑对比布局（高对比）
- 极简 / 黑白灰 / 无渐变
- 居中一个**黑色 pill-shape 胶囊形**录音指示条
- 胶囊内是**一排水平浅灰小圆点**（`.......`），暗示"正在等待/思考"
- 压在上白下黑的分界线上

**Platform 区块**（typeless-platform.webp）：
- 多平台展示：左侧 iOS（带状态栏和底部横条），右侧桌面/Web 卡片
- **移动端录音按钮**：大圆形黑色按钮，外有浅灰底色光晕，内是白色动态**波形**（Waveform）
- **桌面/Web 录音**：悬浮的黑色 pill-shape 按钮，内有白色波形
- 模拟内容：产品文档/项目需求工具
- 排版：左对齐 / Bullet points / 行距段距充足
- 配色：纯黑白色块高对比

### Wispr Flow

**What's New 截图**（wispr-whats-new-1.png）：
- macOS Insights 数据面板
- 浅灰白背景 + 纯白卡片 + **深青色（Teal）+ 浅薄荷绿**强调色
- 全面圆角设计（窗口/卡片/图标/进度条全部圆角）
- 没有显示 Flow bar 本体，是 dashboard 截图

**iOS 键盘**（wispr-interface.jpg）：
- iOS 第三方定制键盘
- **顶部 Flow bar 控制栏 + 下方类 iOS 原生符号键盘**
- 空格键被定制为专属 "Flow" 键
- **录音/启动按钮在 Flow bar 右上角**（白底"Start Flow"或圆形麦克风）
- 深色模式（黑/深灰背景）+ 高对比白色文字图标

### Spokenly（跟译语定位最贴）

**App Interface**（spokenly-app-interface.jpg）：
- macOS 设置/模型管理界面
- **左侧导航栏 + 右侧内容区**
- **深色模式**（深灰/黑 + 白/浅灰文字 + 蓝色选中/标签）
- 大圆角、轻微阴影

**Multilingual**（spokenly-multilingual.jpg）：
- 左侧特性说明 + 右侧 macOS 设置面板
- 模型通过分段选择器（All/Online）切换
- 主色：深灰/纯黑背景 + 高对比白文字
- **强调色：亮蓝**（大标题/选中项）+ 绿（图标/波形）+ 红（录音状态）
- **录音状态面板**：以**悬浮窗形式**位于画面中下方前景，红色指示点在左上角

**Shortcuts**（spokenly-shortcuts.jpg）：
- 自定义右侧 ⌘ / ⌥ / ⇧ / ⌃ 组合键
- 触发模式："按住或切换（Hold or Toggle）"
- 强调色：亮蓝色作为侧栏焦点、下拉菜单选中项、图标高亮
- 经典 macOS 风格、极简扁平化

### MacWhisper

**Launch Interface**（macwhisper-interface.png）：
- 经典 macOS 左右侧栏分栏布局
- 深色模式（深灰/炭黑 + 高对比纯白图文）
- 圆角统一平滑，**外框 + 内部卡片 + 输入框 + 下拉组件全部圆角**
- 柔和弥散投影营造层次

**Dashboard**（macwhisper-dashboard.jpg）：
- 左侧历史记录 + 右侧九宫格功能按钮
- **录音按钮："New Recording" + "Record App Audio"** 在主区
- **右上角语言选择器（English）+ 模型选择器（Distil Large v3）**
- 卡片式 UI，贴合 macOS 原生视觉规范

### 共性（4 家都遵循的视觉范式）

| 维度 | 共性 | 译语建议 |
|---|---|---|
| 主题 | 100% 深色模式 | 双主题（深色为主，浅色为辅） |
| 圆角 | 大圆角（12-20px） | 悬浮窗 16，按钮 8-12 |
| 录音按钮 | 圆形 + 波形动画，pill-shape 悬浮条 | 借鉴 Typeless pill + 波形 |
| 主色 | 蓝色系（Wispr #4D65FF, Spokenly 亮蓝, MacWhisper 蓝） | 译语主色建议 #4F7CFF（接近 Wispr）或更低饱和的蓝 |
| 强调色 | 黑/深灰高对比 + 单色 highlight | 录音态用纯黑高对比；其余用主色 |
| 字体 | Inter / SF Pro | Inter |
| 录音面板形态 | Typeless pill（带波形点）→ Wispr Flow bar（顶部条带）→ Spokenly 悬浮窗（中部前景） | 译语建议：默认 pill 录音条 + 可展开为悬浮窗 |

### 译语录音条形态推荐（基于视觉调研）

**方案 A：Typeless pill（极简首选）**
- 黑色 pill-shape，128-160 × 36px
- 内部白色动态波形（中心对称）
- 居中悬浮（macOS 顶部状态栏下方 / 移动端屏幕底部）
- 状态：闲置（点）/ 录音（波形）/ 处理（旋转点）/ 完成（勾）

**方案 B：Wispr Flow bar（iOS 键盘集成时）**
- 顶部 32-44px 横条
- 左：语言指示 + 切换
- 中：录音按钮（圆形 28px）
- 右：模式切换 / 设置
- 黑色背景 / 圆角 / 麦克风图标高亮

**方案 C：Spokenly 悬浮录音面板（macOS 桌面扩展时）**
- 中下方 280 × 80px 悬浮卡片
- 红色录音点 + 实时波形 + 计时
- 完成后缩回 pill

**推荐组合**：A 为主（屏幕中央 pill）+ C 为辅（macOS 二次确认 / 长录音时）

---

## 调研用图清单（`screenshots/` 目录）

来源混合：官方资源（Typeless / Spokenly）+ 评测站（9to5Mac / Podfeet / fltmag / thesweetbits）

| 文件 | 产品 | 内容 |
|---|---|---|
| `typeless-hero-voice.webp` | Typeless | 官网 hero 区（白底+黑底对比，pill 录音指示条） |
| `typeless-platform.webp` | Typeless | Platform 区块（多平台展示 + 圆形录音按钮 + 波形） |
| `wispr-interface.jpg` | Wispr Flow | iOS 键盘（顶部 Flow bar + 类 iOS 原生符号键盘） |
| `wispr-whats-new-1.png` | Wispr Flow | What's New 截图（macOS Insights 数据面板） |
| `spokenly-app-interface.jpg` | Spokenly | App Interface（左侧导航 + 右侧模型设置） |
| `spokenly-multilingual.jpg` | Spokenly | Multilingual（翻译 / 多语言 + 悬浮录音面板） |
| `spokenly-shortcuts.jpg` | Spokenly | Shortcuts（⌘⌥⇧⌃ 组合键设置） |
| `macwhisper-interface.png` | MacWhisper | 启动界面（左右分栏 + 深色模式） |
| `macwhisper-dashboard.jpg` | MacWhisper | Dashboard（九宫格功能 + 右上角语言/模型选择器） |
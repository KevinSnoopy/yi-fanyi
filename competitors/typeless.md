# 竞品分析 · Typeless

> 来源：Kimi PRD 头号竞品研究（PRD v2.0 §1.1）；T-014 官网视觉调研（`docs/competitor-research/`）；2026-09-26 联网补充调研
> 状态：🟡 初步调研 + 2026 情报更新（产品未实测）

## 基本信息

| 项 | 值 | 来源与口径 |
|---|---|---|
| **官网** | typeless.com | — |
| **slogan** | Speak, don't type | 官网 |
| **形态** | AI 语音听写键盘：按住说话 → 实时润色成稿 → 写进当前应用 | 官网 + 评测 |
| **平台** | macOS / Windows / **iOS / Android**（iOS App 2025-12-22 全球上线，版本 2.6.2 @2026-09） | 官网 + Sensor Tower |
| **速度宣称** | 6× 打字速度（iOS 商店页另称 10×；第三方评测称约 4×）——数字口径不一，仅作营销参考 | 多源 |
| **价格** | Free 8,000 词/周（一说 4,000，两来源不一致，待官网核实）/ Pro **$12/月（年付）**、$30/月（月付）/ Enterprise（HIPAA + SSO/SCIM + 审计日志） | 官网定价页（二手转述） |

## 功能序列（feature 顺序 = 产品定位的镜子）

1. **Dictate（主功能）**：语音 → 干净成稿——去填充词、去重复、**中途改口只保留最终意图**（mid-speech correction）、按当前 App 自适应语气（Slack 口语 / 邮件书面）、自动分段与标点
2. **Translate（第 2 feature）**：100+ 语言边说边译，自动检测，**支持句内混说多语言**
3. **Ask（第 3 feature）**：选中文字说指令（edit / rewrite / shorten / 网页搜索），全程不碰键盘

**翻译是第 2 位 feature，不是主角**——与 Wispr Flow / Spokenly / Chatterfly 同构（见 `docs/competitor-research/` 赛道总结）。

## 2026 关键更新（相对 v2.0 时期认知的修正）

| 维度 | v2.0 时期认知 | 2026-09 实况 |
|---|---|---|
| 隐私 | 采集输入框周边文本（争议点） | 官网宣称 **zero cloud data retention**、历史存本地、不用用户数据训练模型——宣传姿态已转向「privacy-first」（是否采集周边文本待实测验证） |
| 移动端 | 无 | iOS/Android 原生 App 已上线且增长中（月下载约 30k、月收入约 $50k，Sensor Tower 估算） |
| 免费版 | 8,000 词/周 | 仍为 8k 词/周（第三方评测称 4k，**两来源冲突待核实**），且**免费版已含翻译与 Ask** |
| 风格学习 | 未知 | **style learning 为评测公认的杀手锏**：越用越像用户本人的文风；个人词典（personal dictionary）支持专名与术语 |

## 商业模式

- **免费版**：8,000 词/周（约 3–4 封邮件 + 一篇短博），标准准确度，含翻译与 Ask
- **Pro**：$12/月（年付）/$30/月（月付）——无限词、增强准确度、高峰优先、团队管理
- **Enterprise**：HIPAA/BAA、SSO、SCIM、可配置留存审计日志
- 不支持 BYOK——全部走自家云端

## 关键漏洞（译语的可乘之机）

### 1. BYOK 不支持
用户没法用自己的 API Key：数据必然经 Typeless 云端、锁死模型选择、不可定制 prompt / 术语表。

**译语对策**：任意 OpenAI 兼容协议 + 自定义 BaseURL，控制权交还用户（ADR-001）。

### 2. 不支持 Linux / 无离线
纯云端 SaaS，无 Linux 客户端。

**译语对策**：Ollama / 端侧 LLM + 本地 Whisper——纯本地可用（ADR-003）。

### 3. 免费额度墙
以听写为主要输入方式的重度用户周中即触顶（评测原话：hit that ceiling by Wednesday）。

**译语对策**：BYOK 下额度=用户自己 API 的配额，无平台墙。

### 4. iOS 切换键盘摩擦
差评重灾区：系统不允许自动切换键盘、占用表情键。

**译语对策**：引导教程 + 显眼大切换键；不占用 emoji 键位；App 内语音兜底（PRD §2 流程 F）。

## 验证清单（待实测）

- [ ] 注册 Typeless 试用（referral 链接可能有 $5 信用）
- [ ] 实测上下文感知 / per-app 语气质量
- [ ] App Store 差评关键词聚类
- [ ] macOS 端权限引导流程体验
- [ ] 免费额度 8k vs 4k 官网核实；6 分钟会话限制是否仍存在
- [ ] 「采集周边文本」与「zero retention」的实际边界

## 对译语设计的具体启示（累计）

1. **按住 Fn 说话**交互已被市场验证，直接复用（PRD §4 已采纳）
2. **1.2s 后悔窗口**比「直接写入」更友好，保留为可选项
3. **预览期改口指令**（「不对，改成……」）对齐 self-correction——PRD §2.1 已采纳
4. **Typeless 同款两步权限引导**（macOS 辅助功能+输入监控）——PRD §5.3 ⑥ 已采纳
5. **「成稿默认 + 翻译开关」**（2026-09 新增）：Dictate→Translate→Ask 的 feature 序列证明语音成稿是入口、翻译是开关——译语流程 A 默认行为应对齐（T-015 口径，v3.2 落地）
6. **风格学习 + 个人词典**是留存杀手锏——译语术语表已 P0，风格学习标注后续版本

## 参考链接

- 官网：https://www.typeless.com
- PRD 推荐链接：https://www.typeless.com/refer?code=UVBMAAB
- iOS App：Simply CA LLC，App ID 6749257650（2025-12-22 全球上线）
- 第三方评测：makerstack.co（2026）、aigearbase / toolquestor（2026-06/08 收录）

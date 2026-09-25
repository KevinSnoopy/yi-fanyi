# 译语 / LinguaFlow · 产品线内部索引

> **AI 翻译输入助手** — 全平台、BYOK、隐私优先
> 本目录是视频生成业务线**之外**的第二条产品线。
> **本文件是内部索引**——GitHub 公开 README 见根目录的 `README.md`。

## 这是什么

按 Typeless 类语音键盘的形态，但：
- 不锁定任何 LLM 厂商（自带 Key）
- 五平台覆盖（含 Linux）
- 数据不出本机，可纯本地运行

## 文件结构

```
yi-fanyi/
├── README.md                ← GitHub 公开 README（对外部访客）
├── INTERNAL.md              ← 本文件（产品线内部索引）
├── PRD_v2.0.md              ← 产品需求（9 节，仅需求：流程/功能/交互/设计/异常/非功能）
├── roadmap.md               ← 实施路线图（按优先级展开）
├── next_steps.md            ← Kimi 提的三步选项决策记录
├── competitors/             ← 竞品分析
│   ├── typeless.md
│   ├── chatterfly.md
│   └── bob.md
├── decisions/               ← 关键产品决策（ADR 风格）
│   ├── 001-byok-not-managed.md
│   ├── 002-buyout-not-subscription.md
│   ├── 003-five-platform-incl-linux.md
│   └── 004-flutter-native-bridge.md
├── pages-specs/             ← 每个页面的字段级原型说明（Kimi 选项 ③ 落地）
└── assets/
    └── PRD_v2.0_source.docx ← 原始 PRD 备份
```

## 核心差异化（详见 README.md）

| 维度 | 主流方案（Typeless/Chatterfly） | 译语 |
|---|---|---|
| 模型 | 厂商锁定 | **BYOK** 任意平台 |
| 平台 | 4 端（不含 Linux） | **5 端**（含 Linux） |
| 离线 | 不支持 | **Whisper 本地 + Ollama** |
| 隐私 | 采集周边文本 | **零采集，直连模型方** |
| 定价 | $144/年订阅 | **¥98–168 买断** |

详细论证见 `decisions/` 下各 ADR。

## 优先级摘要（P0）

按 PRD §3：
- 桌面三端语音输入（A）+ 翻译四模式（B/C/D）+ BYOK + 全局热键
- 跨语言翻译 + 流式渲染 + 术语表
- 模型配置（灵魂页面）

P1：Whisper 本地、OCR、风格选择、Profile 路由、Skill 模板、历史用量、移动端、开机自启

## 状态

- [x] PRD v2.0 完整记录（2026-09-26）
- [ ] 竞品深度调研（typeless/chatterfly/bob/spokenly）
- [ ] 设计稿（Kimi 选项 ①）
- [ ] Provider 接口定义（Kimi 选项 ②）
- [ ] 页面字段级原型（Kimi 选项 ③）
- [ ] Flutter 工程脚手架
- [ ] macOS MVP 验证（先做一端跑通）

详见 `roadmap.md` 和 `next_steps.md`。

## 内部备注

- 本目录在 `/root/products/yi-fanyi/`，与视频项目 `/root/video-workflow/` 并列
- GitHub 仓库：KevinSnoopy/yi-fanyi（public，2026-09-26 建）
- 关联 memory 条目：产品线总览记录在长期 memory 中
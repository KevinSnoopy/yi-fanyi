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
├── AGENTS.md                ← Agent 协作入口（多会话接续，必读）
├── README.md                ← GitHub 公开 README（对外部访客）
├── INTERNAL.md              ← 本文件（产品线内部索引）
├── PRD_v3.0.md              ← 产品需求最新版（v3.1 内容修订；仅需求：流程/功能/交互/设计/页面/异常/非功能）
├── PRD_v2.0.md              ← v2.0 基线留档（不再更新）
├── roadmap.md               ← 实施路线图（按优先级展开）
├── next_steps.md            ← 三步选项决策记录
├── docs/                    ← 接续中枢（多 Agent / 多会话）
│   ├── CONTEXT.md           ← 进度唯一真相源（离开前必更新）
│   ├── TASKS.md             ← 任务池（状态/依赖/验收）
│   ├── CONVENTIONS.md       ← 文档、命名、commit、分支约定
│   ├── SESSIONS.md          ← 会话回执索引 + 模板
│   ├── sessions/            ← 每次会话的回执文件
│   └── competitor-research/ ← T-014 设计调研（Typeless / Wispr Flow / Spokenly / MacWhisper + 9 张截图）
├── competitors/             ← 竞品分析
│   ├── typeless.md
│   ├── chatterfly.md
│   └── bob.md
├── decisions/               ← 关键产品决策（ADR 风格，共 8 份）
│   ├── 001-byok-not-managed.md
│   ├── 002-buyout-not-subscription.md
│   ├── 003-five-platform-incl-linux.md
│   ├── 004-flutter-native-bridge.md
│   ├── 005-macos-menubar-pattern.md
│   ├── 006-prototype-spa-app.md
│   ├── 007-provider-interface.md
│   └── 008-recorder-bar-three-states.md
├── prototypes/              ← 设计原型（现行 v6-spa 13 页全量；v5-spa 留档；v1 作废）
├── pages-specs/             ← 每个页面的字段级原型说明（待建，T-012）
└── assets/                  ← PRD 部署版 HTML（PRD_v3.0_deploy.html）+ 原始 docx/源档备份
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

> 进度与任务的唯一真相源是 `docs/CONTEXT.md` 与 `docs/TASKS.md`，本文件不再重复维护状态清单。

- 进度快照：`docs/CONTEXT.md`
- 任务池：`docs/TASKS.md`
- 规划与下一步：`roadmap.md`、`next_steps.md`

## 内部备注

- 本目录在 `/root/products/yi-fanyi/`，与视频项目 `/root/video-workflow/` 并列
- GitHub 仓库：KevinSnoopy/yi-fanyi（public，2026-09-26 建）
- 关联 memory 条目：产品线总览记录在长期 memory 中
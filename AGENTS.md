# AGENTS.md · 协作入口

> 任何 Agent（Claude Code / Codex / Cursor / 自建 Agent）在进入本仓库时**先读本文件**，可在 2 分钟内接上上下文并继续工作。

## 0. 项目一句话

**译语 / LinguaFlow** —— 按住说话（或打一句话），译文自动落进正在输入的地方；BYOK（自带模型 Key）、五端覆盖（含 Linux）、隐私优先。当前处于 **Phase 0 · 决策与设计**，暂无产品代码。

## 1. 必读顺序（按此顺序读，不要跳）

| 顺序 | 文件 | 作用 |
|---|---|---|
| 1 | 本文件 `AGENTS.md` | 规则与工作流 |
| 2 | [`docs/CONTEXT.md`](./docs/CONTEXT.md) | **当前进度唯一真相源**：阶段、刚做完什么、下一步、阻塞点 |
| 3 | [`docs/TASKS.md`](./docs/TASKS.md) | 任务池：领任务、看状态与验收标准 |
| 4 | [`PRD_v3.0.md`](./PRD_v3.0.md) | 产品需求（仅需求，不含路线图/商业；v3.x 系列文件名沿用 `PRD_v3.0.md`） |
| 5 | [`decisions/`](./decisions/) | 8 个已决策 ADR（001–008），不可推翻 |
| 6 | [`docs/CONVENTIONS.md`](./docs/CONVENTIONS.md) | 文档格式、命名、commit、分支约定 |
| 7 | 按任务需要 | `roadmap.md`、`prototypes/`、`competitors/`、`docs/competitor-research/`、`next_steps.md`、`docs/sessions/` |

**不要**从 README 或 commit 历史推断当前进度——以 `docs/CONTEXT.md` 为准。

## 2. 仓库地图

```
yi-fanyi/
├── AGENTS.md              ← 本文件：Agent 入口
├── PRD_v3.0.md            ← **唯一 PRD**（v3.x 内容；文件名沿用。v2.0 与 assets 部署版已删除收敛）
├── roadmap.md             ← 实施路线图、工期、里程碑、项目风险
├── next_steps.md          ← 下一步三选项决策记录（未决策）
├── README.md              ← 对外公开介绍（不含内部进度）
├── INTERNAL.md            ← 产品线内部索引
├── docs/
│   ├── CONTEXT.md         ← 当前进度（每次会话结束必须更新）
│   ├── TASKS.md           ← 任务池（状态的权威列表）
│   ├── CONVENTIONS.md     ← 文档/代码/commit 约定
│   ├── SESSIONS.md        ← 会话日志索引
│   ├── sessions/          ← 每次会话的回执（YYYY-MM-DD-NN-主题.md）
│   └── competitor-research/ ← T-014 设计调研（4 家 + 截图）
├── decisions/             ← ADR：001 BYOK / 002 买断 / 003 五端 / 004 Flutter
│                            005 菜单栏范式 / 006 SPA原型 / 007 Provider接口 / 008 三态并列
├── competitors/           ← 竞品分析：typeless / chatterfly / bob
├── prototypes/            ← **唯一原型** v7-spa（13 页·成稿范式）；v1/v5/v6 已删除收敛，禁止重建旧版
├── pages-specs/           ← 页面字段级原型（选项 ③ 落地目录，待建 T-012）
└── assets/                ← （已清空删除；曾存放 PRD 部署版 HTML 与源档备份）
```

## 3. 会话工作流协议

### 开始（进入仓库后）

1. 读第 1 节的文件清单
2. 读 `docs/SESSIONS.md` 最近 1–2 条回执，了解上一轮做了什么、留了什么坑
3. 在 `docs/TASKS.md` 里挑一个**状态为 ⬜ 且依赖已满足**的任务，开始即为 🟡
4. 若发现 CONTEXT 与实际不符，以实际为准并修正 CONTEXT（在回执中说明）

### 进行中

- **一次只做一个任务**，完成并自验后再领下一个
- 遇到需要用户拍板的分歧（定价、License、选型变更）：**停下来标记 ⛔ 阻塞并写进 CONTEXT**，不要自行假设
- 改动已决策内容（ADR-001~008）必须新增 ADR 走 supersede，不得直接改写原文件结论

### 结束（离开前必做，缺一不可）

1. 更新 `docs/TASKS.md`：任务状态、完成日期、遗留项
2. 更新 `docs/CONTEXT.md`：阶段、本轮成果、下一步、阻塞点、`last_updated`
3. 写会话回执 `docs/sessions/YYYY-MM-DD-NN-主题.md`（模板见 `docs/SESSIONS.md`）
4. 在 `docs/SESSIONS.md` 索引表顶部追加一行
5. 提交（commit 规范见 `docs/CONVENTIONS.md`），push 到对应分支

**没有留痕的工作等于没做**——下一轮 Agent 只认 CONTEXT + 回执。

## 4. 硬规则（违反会被回滚）

| # | 规则 |
|---|---|
| R1 | `PRD_v3.0.md` **只写产品需求**；路线图进 `roadmap.md`，商业/定价进 `decisions/002`，下一步进 `next_steps.md` |
| R2 | ADR-001~008 为已决策结论；要改必须新建 ADR 并在原文标注 superseded by |
| R3 | 当前无产品代码；**不要**在用户确认 next_steps 选项前生成 Flutter 工程脚手架 |
| R4 | `docs/CONTEXT.md` 是进度唯一真相源；README/INTERNAL 只放指针，不复制状态清单 |
| R5 | Key/隐私底线：请求直连用户配置的 BaseURL，零遥测、不采集宿主应用上下文文本 |
| R6 | 涉及 LICENSE、定价、对外发布文案的改动，必须经用户确认 |

## 5. 产品决策速查（详见 ADR）

| 主题 | 结论 |
|---|---|
| 模型接入 | **BYOK**，官方中转仅作默认关闭的兜底（ADR-001） |
| 商业模式 | **买断 ¥98–168**，不做订阅（ADR-002） |
| 平台 | **五端**，含 Linux；先 macOS MVP（ADR-003） |
| 技术栈 | **Flutter + 原生桥** + Provider 适配层（ADR-004） |
| macOS 主交互 | **菜单栏 Popover 范式**，不做常驻主窗口（ADR-005） |
| 原型形态 | **SPA 三文件零依赖**（HTML+CSS+JS），无构建无 CDN（ADR-006） |
| Provider 接口 | 统一抽象 `TranslationProvider`（ADR-007） |
| 录音条设计 | **三态并列展示**为强制项（ADR-008）；形态已拍板 **Typeless pill**（160×36 基准，T-015 用户口径 2026-09-26） |
| 语音交互 | 按住 Fn 说话 → 松手**同语言成稿**（默认），pill 右侧「译」翻译开关默认关，1.2s 预览后悔窗口（PRD v3.2 §2.1） |
| 已知硬约束 | iOS 键盘内不能录音、不能自动切换键盘（PRD §2.6） |

## 6. 常见歧义与澄清

- **"五端"** = macOS / Windows / Linux / iOS / Android；**"端侧"** = 用户设备上的本地模型
- **流程 A–E** 的编号全局引用：A 语音成稿输入、B 悬浮窗、C 划词、D 静默替换、E 截图 OCR；原型已扩展到 **A–M** 共 13 页（H 主窗首页 / I 模型配置 / J 快捷键 / K 偏好·术语·Skills / L 首次引导 / M 移动 App），对照表见 [`prototypes/README.md`](./prototypes/README.md)
- **P0** = macOS MVP 必须交付；**P1** = MVP 之后补完
- 竞品价格/功能均为二手调研，**未实测**，不要当作事实引用（见 `competitors/` 待调研项）

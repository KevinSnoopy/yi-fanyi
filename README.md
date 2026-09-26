# 译语 / LinguaFlow

> **AI 翻译输入助手** — 全平台、BYOK、隐私优先

按住说话（或打一句话），译文自动落进你正在输入的地方——用你自己的模型 Key，离线也能用。

## 这是什么

| 维度 | 主流方案 | 译语 |
|---|---|---|
| 模型 | 厂商锁定 | **BYOK** 任意平台 |
| 平台 | 4 端（不含 Linux） | **5 端**（含 Linux） |
| 离线 | 不支持 | **Whisper 本地 + Ollama** |
| 隐私 | 采集周边文本 | **零采集，直连模型方** |
| 定价 | $144/年订阅 | **¥98–168 买断** |

## 文档结构

- [`PRD_v3.0.md`](./PRD_v3.0.md) — 产品需求文档（v3.1 内容修订；文件名沿用，仅 §1–§9 需求；商业/风险已下沉）
- [`roadmap.md`](./roadmap.md) — 5 阶段实施路线图
- [`next_steps.md`](./next_steps.md) — Kimi 三选项决策框架
- [`competitors/`](./competitors/) — 竞品分析（Typeless / Chatterfly / Bob）
- [`docs/competitor-research/`](./docs/competitor-research/) — Typeless / Wispr Flow / Spokenly / MacWhisper 设计调研（T-014）
- [`decisions/`](./decisions/) — 8 个关键产品决策 ADR（001–008）
- [`prototypes/`](./prototypes/) — 设计原型（现行 `v7-spa/` 13 页全量·成稿范式；`v6-spa/`、`v5-spa/` 留档；v1 作废）
- [`assets/`](./assets/) — PRD 部署版 HTML + 原始 docx 备份
- [`AGENTS.md`](./AGENTS.md) — 协作入口（参与开发的 Agent 必读）
- [`docs/`](./docs/) — 进度快照 `CONTEXT.md`、任务池 `TASKS.md`、约定与会话回执

## 状态

**Phase 0 · 决策与设计 → Phase 1 · 设计**（进行中，暂无产品代码）

- 当前进度：[`docs/CONTEXT.md`](./docs/CONTEXT.md)
- 任务池：[`docs/TASKS.md`](./docs/TASKS.md)
- 长期规划：[`roadmap.md`](./roadmap.md)

## License

TBD — 商业产品，暂未确定。

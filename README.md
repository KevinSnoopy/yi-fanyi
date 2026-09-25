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

- [`PRD_v2.0.md`](./PRD_v2.0.md) — 产品需求文档（9 节，仅需求；路线图与商业模式已拆分）
- [`roadmap.md`](./roadmap.md) — 5 阶段实施路线图
- [`next_steps.md`](./next_steps.md) — Kimi 三选项决策框架
- [`competitors/`](./competitors/) — 竞品分析（Typeless / Chatterfly / Bob）
- [`decisions/`](./decisions/) — 4 个关键产品决策 ADR
- [`assets/`](./assets/) — 原始 PRD docx 备份

## 状态

**Phase 0 · 决策与设计**（进行中）

- [x] PRD v2.0 完整记录
- [x] 4 个核心 ADR（BYOK / 买断 / 五端 / Flutter）
- [x] 竞品初步调研
- [ ] 设计稿（Kimi 选项 ①）
- [ ] Provider 接口实现（Kimi 选项 ②）
- [ ] 字段级页面原型（Kimi 选项 ③）
- [ ] macOS MVP

详见 [`roadmap.md`](./roadmap.md)。

## License

TBD — 商业产品，暂未确定。
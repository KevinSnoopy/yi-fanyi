# TASKS · 任务池

> 多 Agent 接续的调度中心。领取任务前先看依赖，完成后必须回写状态。
> 进度快照见 [`CONTEXT.md`](./CONTEXT.md)，优先级依据 [`PRD_v3.0.md §3`](../PRD_v3.0.md) 与 [`roadmap.md`](../roadmap.md)。

## 状态图例

| 符号 | 含义 | 说明 |
|---|---|---|
| ⬜ | 待开始 | 依赖已满足，可直接领取 |
| 🟡 | 进行中 / 部分完成 | 已被某会话认领或有半成品，接手前先读 `docs/sessions/` 相关回执 |
| ✅ | 完成 | 已验收并留痕 |
| ⛔ | 阻塞 | 需用户拍板或外部条件，Agent 不得自行假设 |

## 领取规则

1. 只领取 **⬜ 且依赖已满足** 的任务；领取后把状态改为 🟡
2. 一次一个；完成后改 ✅ 并填完成日期
3. 受阻改 ⛔，并在 `CONTEXT.md` 的阻塞点列表登记
4. 需要新增任务时按阶段编号追加（T-0xx），不要重排已有 ID——回执里引用过

## Phase 0 · 决策与设计（当前阶段）

| ID | 任务 | 状态 | 依赖 | 验收要点 | 关联 |
|---|---|---|---|---|---|
| T-001 | PRD v2.0 精简为纯产品需求文档 | ✅ 2026-09-26 | — | 仅含 §1–§9 需求；商业/风险/下一步已下沉 | [`PRD_v2.0.md`](../PRD_v2.0.md) |
| T-002 | 四个核心 ADR 归档 | ✅ 2026-09-26 | — | BYOK / 买断 / 五端 / Flutter 四份齐备 | [`decisions/`](../decisions/) |
| T-003 | 竞品初步调研 | 🟡 部分 | — | 三份竞品文档已建，待实测项未完成 | [`competitors/`](../competitors/) |
| T-004 | 建立多 Agent 接续协议 | ✅ 2026-09-26 | — | `AGENTS.md` + `docs/` 四件套 + 会话回执模板 | [`AGENTS.md`](../AGENTS.md) |
| T-005 | 拍板 next_steps 三选项 | ✅ 2026-09-26 | — | 选 ①「录音条三态 + 悬浮窗交互原型」 | [`next_steps.md`](../next_steps.md) |
| T-006 | 确定开源 License | ⛔ 需用户 | — | 更新 README 的 License 段 | [`README.md`](../README.md) |
| T-007 | 竞品实测（Typeless 试用 / Bob 版本 / Chatterfly 数据） | ⬜ | T-003 | 填完三份文档的"待调研项"复选框 | [`competitors/`](../competitors/) |

## Phase 1 · 设计（依赖 T-005）

| ID | 任务 | 状态 | 依赖 | 验收要点 | 关联 |
|---|---|---|---|---|---|
| T-010 | 录音条三态 + 悬浮窗交互原型（选项 ①） | ⛔ 2026-09-26 作废 | T-005 选 ① | 用户否决（错把"翻译"做成主角；应先做 Typeless/Chatterfly 官网调研，按"语音输入为主、翻译可选"重新定位后再画）。**复盘详见** [`2026-09-26-04-t010-retro.md`](./sessions/2026-09-26-04-t010-retro.md)：5 维度教训（参照错位 / 定位权重 / 组件关系 / 触发范式 / 视觉调研缺失） | PRD §5.3 |
| T-011 | Provider 适配层 Dart 接口定义（选项 ②） | ⬜ | T-005 选 ② | 接口 + OpenAI/Anthropic/Ollama 三实现 + 测试 | ADR-004 |
| T-012 | 13 个页面字段级原型说明（选项 ③） | ⬜ | T-005 选 ③ | `pages-specs/` 下每页一份字段表 | PRD §6 |
| T-013 | Design Token 落地（浅/深主题 + 组件规格） | ⬜ | T-014 | Token 表与新版口径一致，组件覆盖 ①–⑥ | PRD §5 |
| T-014 | Typeless + Wispr Flow + Spokenly + MacWhisper 官网设计调研 | ✅ 2026-09-26 | — | 覆盖 4 家（超出原 Typeless+Chatterfly 计划）；HTML+CSS 提取 + 9 张截图 + vision 分析。**回执** [`2026-09-26-05-t014-research.md`](./sessions/2026-09-26-05-t014-research.md)，**主文档** [`competitor-research/README.md`](./competitor-research/README.md) | docs/competitor-research/ |
| T-015 | 按用户新口径重做原型（语音为主 / 翻译可选） | ⬜ | T-014 + 用户口径 | 录音条形态 A/B/C、翻译开关位置、原型形态（HTML / Flutter）由用户决定 | — |
| T-016 | PRD v3.0 + ADR-005~008 + v5 SPA 原型 push 到 GitHub | ✅ 2026-09-26 | T-014 | PRD v3.0 拆分合规 + 4 个新 ADR + v5 SPA 落 `prototypes/v5-spa/` + 部署版 HTML 落 `assets/`。**回执** [`2026-09-26-06-prd-v3-push.md`](./sessions/2026-09-26-06-prd-v3-push.md) | `PRD_v3.0.md` + `decisions/005-008/` + `prototypes/v5-spa/` |
| T-017 | v6 完整 13 页原型（v5 基础上扩 6 个 tab） | ✅ 2026-09-26 | T-016 + 用户本轮指令 | 13/13 Tab 全落地（H 主窗首页 / I 模型配置 / J 快捷键 / K 偏好+术语+Skills / L 首次引导 / M 移动 App）+ Popover 最近译文（§6 #13）+ 走查面板；Chromium 无头冒烟通过。**回执** [`2026-09-26-07-prd-tidy-v6-prototype.md`](./sessions/2026-09-26-07-prd-tidy-v6-prototype.md) | `prototypes/v6-spa/` |

## Phase 2 · macOS MVP

| ID | 任务 | 状态 | 依赖 | 验收要点 | 关联 |
|---|---|---|---|---|---|
| T-020 | Flutter 工程脚手架 + macOS 原生桥 | ⬜ | T-011 | 空壳可运行，MethodChannel 打通 | ADR-004 |
| T-021 | 流程 A：按住 Fn 说话 → 转写 → 翻译 → 写回 | ⬜ | T-020 | 完成一次中译英写回 WhatsApp | PRD §2.1 |
| T-022 | 流程 B / C / D：悬浮窗、划词、静默替换 | ⬜ | T-020 | 三个热键可触发，含焦点变化终止 | PRD §2.2–2.4 |
| T-023 | 模型配置页（灵魂页面） | ⬜ | T-020 | OpenAI + 自定义 BaseURL + Ollama 三套跑通 | PRD §5.3 ④ |
| T-024 | 全局热键 + 冲突检测 | ⬜ | T-020 | 可重绑，冲突时红字提示占用方 | PRD §4 |
| T-025 | 首次引导三步 + 权限引导 | ⬜ | T-020 | 零 Key 可完成本地模型试用体验 | PRD §5.3 ⑥ |

## Phase 3+ · 多端与商业化

| ID | 任务 | 状态 | 依赖 | 验收要点 | 关联 |
|---|---|---|---|---|---|
| T-030 | Linux + Windows 平移 | ⬜ | T-022~T-025 | 桌面三端功能对齐 | roadmap Phase 2 |
| T-031 | Android 输入法 | ⬜ | T-030 | 键盘内可翻译，App 内可录音 | PRD §2.6 |
| T-032 | iOS 键盘扩展 | ⬜ | T-030 | 文本翻译可用，语音走 App 内兜底 | PRD §2.6 |
| T-040 | P1 功能补完（Whisper 本地 / OCR / Profile / Skill / 术语表 / 历史用量 / 隐私锁） | ⬜ | T-030 | 覆盖 PRD §3 全部 P1 | PRD §3 |
| T-050 | 商业化：官网 + 官方中转 + 上架 | ⬜ | T-040 | 官网含与 Typeless 的对比表 | ADR-002 |

## 变更记录

- 2026-09-26：建库，从 `roadmap.md` / `next_steps.md` / README 状态清单抽取为统一任务池
- 2026-09-26：T-017 v6 完整 13 页原型完成（会话 07）；表头优先级引用更新为 `PRD_v3.0.md §3`（v3.1 内容修订，文件名沿用）

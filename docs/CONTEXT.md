---
phase: "Phase 1 · 设计（v6 13 页全量原型已落地；T-015 重画口径并行收集中）"
stage: awaiting-t015-user-口径 + v6-原型-验收
last_updated: 2026-09-26
current_focus: "T-017：v6 完整 13 页原型已落地 prototypes/v6-spa/ 并随 PRD v3.1 整理修订一并 push。等用户：(a) 验收 v6 原型 (b) 拍板 T-015 录音条形态/翻译开关位置/原型形态"
next_action: "等用户验收 v6（prototypes/v6-spa/index.html 本地打开，右下角「❓ 走查」）+ PRD v3.1 部署版（assets/PRD_v3.0_deploy.html）；同时催 T-015 三选"
blockers:
  - "T-015 用户口径未定（录音条形态 / 翻译开关位置 / 原型形态）"
  - "License 未定（README 标 TBD）"
has_code: false
---

# CONTEXT · 当前进度

> **本文件是进度的唯一真相源**。任何 Agent 在会话结束前必须更新本文件；README / INTERNAL 只保留指针，不复制状态清单。

## 1. 当前阶段

**Phase 1 · 设计**（无产品代码，`has_code: false`）

已完成：PRD v3.1（内容修订随 `PRD_v3.0.md` 文件名沿用）+ 8 个 ADR（001-008）+ v5 SPA 原型（7/13 tab，留档）+ **v6 SPA 原型（13/13 tab 全量，T-017 ✅）** + 4 家竞品视觉调研（T-014）。
当前卡点：v6 验收与 T-015 录音条新口径等用户拍板。

## 2. 最近一轮做了什么

| 日期 | 会话 | 成果 |
|---|---|---|
| 2026-09-26 | [`2026-09-26-07-prd-tidy-v6-prototype`](./sessions/2026-09-26-07-prd-tidy-v6-prototype.md) | T-017 ✅：v6 13 页全量原型落地 `prototypes/v6-spa/`（Tab A–M + Popover 最近译文 + 走查面板；修复 v5 遗留 runA 引用错误与孤儿 timer 竞态；无头冒烟通过）；PRD v3.1 整理修订（验收清单计数 24→22 实测、断链修复、§6 页面表落 Tab 字母）；prototypes/README 重写；协议文档全量对齐 |
| 2026-09-26 | [`2026-09-26-06-prd-v3-push`](./sessions/2026-09-26-06-prd-v3-push.md) | T-016 ✅：PRD v3.0 拆分上线（仅 §1-9 需求；§10 商业→[ADR-002](./sessions/2026-09-26-06-prd-v3-push.md) 补充；§11 风险→`roadmap.md`）+ ADR-005~008 新增（菜单栏范式/SPA原型/Provider接口/三态并列）+ v5 SPA 原型 push 到 `prototypes/v5-spa/` + PRD 部署版 HTML push 到 `assets/`。待 v5 验收与 T-015 口径。 |
| 2026-09-26 | [`2026-09-26-05-t014-research`](./sessions/2026-09-26-05-t014-research.md) | T-014 ✅：竞品调研完成（4 家超出计划：Typeless / Wispr Flow / Spokenly / MacWhisper）。HTML+CSS 解析 + 9 张产品截图落地 + vision 视觉层观察全维度记录 |
| 2026-09-26 | [`2026-09-26-04-t010-retro`](./sessions/2026-09-26-04-t010-retro.md) | T-010 复盘：5 维度教训（参照错位 / 定位权重 / 组件关系 / 触发范式 / 视觉调研缺失），状态回退 ⛔ |
| 2026-09-26 | [`2026-09-26-03-t010-prototype`](./sessions/2026-09-26-03-t010-prototype.md) | T-005 拍板选 ①；T-010 启动：HTML/CSS/JS 录音条三态 + 悬浮窗四态原型 + 浅深主题切换（已被否决） |
| 2026-09-26 | [`2026-09-26-02-agent-handoff`](./sessions/2026-09-26-02-agent-handoff.md) | 建立多 Agent 接续协议：`AGENTS.md` + `docs/{CONTEXT,TASKS,CONVENTIONS,SESSIONS}.md` + `docs/sessions/`，并把 README/INTERNAL 的重复进度清单改为指针 |
| 2026-09-26 | [`2026-09-26-01-prd-reorg`](./sessions/2026-09-26-01-prd-reorg.md) | PRD v2.0 精简为纯产品需求（保留 §1–§9），商业模式下沉 `decisions/002`，风险并入 `roadmap.md`；同步 README/INTERNAL 与 ADR 引用 |

## 3. 进行中 / 待领任务

见 [`TASKS.md`](./TASKS.md)。当前无 🟡 进行中任务。下一可领取任务：

- **T-012**（13 页字段级规格）— v6 已提供 13 页交互参照，可直接开工；产出 `pages-specs/`
- **T-015**（按用户新口径重画原型）— 等用户从录音条形态 A/B/C 中选定 + 翻译开关位置 + 原型形态；**注意：T-015 未拍板前 Tab A 维持 v6 现行形态，不得擅改**

其他可平行动作（不需要用户口径）：
- T-007 竞品实测（试用 Typeless / Bob / Chatterfly）
- T-013 Design Token 落地（依赖 T-015 用户口径）
- T-011 Provider 适配层 Dart 接口实现（[ADR-007](../decisions/007-provider-interface.md) 已定义接口）

## 4. 阻塞点（需用户拍板，Agent 不得自行假设）

| 阻塞项 | 影响 | 位置 |
|---|---|---|
| T-015 用户口径 | 录音条形态 / 翻译开关位置 / 原型形态 | docs/competitor-research/README.md 推荐方案 A/B/C |
| v6 原型验收 | 决定是否冻结 13 页交互进入 T-012 字段级规格 | `prototypes/v6-spa/index.html`（本地打开，右下角「❓ 走查」） |
| License 未定 | 影响能否对外开源与 Issue/PR 开放策略 | `README.md` |
| 竞品数据未实测 | 官网对比表、定价论证不能定稿 | `competitors/*.md` 待调研项 |

## 5. 关键决策（已定，不可推翻）

见 [`decisions/`](../decisions/)：

**001-004（v2.0 时期）**：BYOK / 买断 / 五端含 Linux / Flutter+原生桥
**005-008（v3.0 时期，2026-09-26 新增）**：
- [ADR-005](../decisions/005-macos-menubar-pattern.md) macOS 菜单栏范式（Popover 而非主窗口）
- [ADR-006](../decisions/006-prototype-spa-app.md) 原型 SPA 化（单 HTML + JS + CSS）
- [ADR-007](../decisions/007-provider-interface.md) Provider 统一接口 `TranslationProvider`
- [ADR-008](../decisions/008-recorder-bar-three-states.md) 录音条三态并列展示

**本轮新增待定决策**（写入待用户拍板清单）：
- 录音条默认形态：Typeless pill / Wispr Flow bar / Spokenly 悬浮窗（详见 `competitor-research/README.md` §视觉层观察）
- 翻译功能产品化位置：录音条右侧小开关 / 设置面板独立页
- 原型形态：HTML/CSS 预览 / 直接 Flutter widget

## 6. 接续提示

- 仓库默认分支 `master`，公开仓库 `KevinSnoopy/yi-fanyi`
- 文档全部为中文，Markdown 格式约定见 [`CONVENTIONS.md`](./CONVENTIONS.md)
- 沙箱/容器内 `git push` 报 TLS 握手失败（`gnutls_handshake() failed`）时：先把 GitHub 真实 IP 写入 `/etc/hosts`（DNS 常被劫持到内网段）；仍失败则加 `-c http.version=HTTP/1.1` 再推，通常可绕过；若 github.com 完全被墙而 api.github.com 可通，可用 Git Data API 逐 commit 推送
- 不要在仓库中提交任何 Key、Token、个人凭据
- **vision 工具 1 张/次**（9 张/次必超时）
- **delegated subagent 写文件用沙盒隔离**，交付物必须由主 agent 重新落库
- **不要重复已有产品的截图到 README 正文**——独立存 `screenshots/` 子目录，正文引用路径
- **PRD 写作铁律**（[ADR-005..008](../decisions/) 期间总结）：PRD 仅含产品需求（§1-9）；商业模式→对应 ADR；风险→`roadmap.md` §风险；决策记录→`decisions/`
- **原型落地规范**：现行 v6 SPA 在 [`prototypes/v6-spa/`](../prototypes/v6-spa/)（3 文件 166KB，Tab A–M 13 页全量 + 走查面板）；v5 留档；PRD 部署版在 [`assets/PRD_v3.0_deploy.html`](../assets/PRD_v3.0_deploy.html)；13 页对照表见 [`prototypes/README.md`](../prototypes/README.md)
- **原型 JS 约定**：演示延时一律走 `schedule()`（playTimers 集合统一清理），禁止裸 `setTimeout` 存回单个变量——v5 的孤儿 timer 竞态就是这么来的（会话 07 修复）

## 7. 给下一个 Agent 的速读路径

1. 读 [`PRD_v3.0.md`](../PRD_v3.0.md)（产品需求最新版；v2.0 保留为基线）
2. 读 [`prototypes/README.md`](../prototypes/README.md)（v6 13 页对照表 + 走查路径 + Design Token）
3. 读 [`competitor-research/README.md`](./competitor-research/README.md)（T-014 调研结论）
4. 读 [`2026-09-26-04-t010-retro.md`](./sessions/2026-09-26-04-t010-retro.md)（T-010 复盘，避免重蹈覆辙）
5. 读 [`2026-09-26-05-t014-research.md`](./sessions/2026-09-26-05-t014-research.md)（T-014 调研回执 + 待用户决策点）
6. 读 [`2026-09-26-06-prd-v3-push.md`](./sessions/2026-09-26-06-prd-v3-push.md)（v3.0 拆分 + v5 SPA 落地说明）
7. 读 [`2026-09-26-07-prd-tidy-v6-prototype.md`](./sessions/2026-09-26-07-prd-tidy-v6-prototype.md)（v6 原型落地 + PRD v3.1 修订说明）
8. 领取 T-015 时必须先拿到用户口径才能开工

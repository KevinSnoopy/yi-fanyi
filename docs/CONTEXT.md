---
phase: "Phase 2 · 真实代码开发（T-021/T-022/T-024 真实链路已通，macOS 原生壳待实机编译）"
stage: flutter-real-links-done
last_updated: 2026-09-27
current_focus: "T-021 ✅ 真实 Provider 联调（Key→SecureStore/Keychain，Profile 只留 keyRef；真实 testConnection/fetchModels；真实 SSE 成稿 + 失败内联错误条 + 一键降级演示流式）；T-022 ✅ B/C/D 系统触发双落地（原生 system / 应用内 inApp）；T-024 ✅ 结构化热键 + 三平台冲突表 + 真实重绑 + macOS Carbon/AX/Keychain/NSPanel/StatusBar 原生壳；flutter analyze 0 issue、flutter test 44/44、web release ✓、冒烟 15/15 PASS 0 错误"
next_action: "macOS 实机编译验证（`flutter build macos` + 权限引导）；T-023 三套真连接（OpenAI / 自定义 BaseURL / Ollama）；T-025 权限引导接真实系统设置回执"
blockers:
  - "macOS 原生壳未实机编译（Linux 沙箱无 Xcode/macOS SDK，Swift 仅做语法与 API 正确性校验）"
  - "T-023 三套真连接需真实 Key 环境"
  - "License 未定（README 标 TBD）"
has_code: true
---

# CONTEXT · 当前进度

> **本文件是进度的唯一真相源**。任何 Agent 在会话结束前必须更新本文件；README / INTERNAL 只保留指针，不复制状态清单。

## 1. 当前阶段

**Phase 2 · 真实代码开发**（`has_code: true`，代码在 [`app/`](../app/)）

已完成：PRD v3.2 + 8 个 ADR + v7 SPA 原型（13/13）+ 竞品调研 + **Flutter 工程（T-020 ✅）：13 页 UI 全量、ADR-007 四 Provider 流式实现、ADR-008 四态状态机/pill/pipeline、analyze 0 issue、Web 冒烟 15/15 PASS**。
本轮（2026-09-27 会话 10）把 Mock 骨架换成**真实链路**：T-021 ✅ 真实 Provider 联调（Key 进 Keychain、真实 SSE 成稿、血缘明示）、T-022 ✅ B/C/D 系统触发双落地、T-024 ✅ 全局热键结构化 + 冲突检测 + macOS 原生壳六文件。**44 项单测 + widget 端到端全绿**。
当前卡点：macOS 实机编译（Swift 未编译验证）与真实 Key 环境下的三套连接验收（T-023）。

## 2. 最近一轮做了什么

| 日期 | 会话 | 成果 |
|---|---|---|
| 2026-09-27 | [`2026-09-27-01-t021-t022-t024-real-links`](./sessions/2026-09-27-01-t021-t022-t024-real-links.md) | T-021 ✅ / T-022 ✅ / T-024 ✅：真实 Provider 联调（SecureStore/Keychain + 真实 SSE + 失败错误条 + 一键降级）、B/C/D 系统触发双落地（悬浮窗/划词/静默替换 + 焦点变化终止）、结构化热键 + 三平台冲突表 + 真实重绑、macOS 原生壳六文件（Carbon 热键 / AX 注入 / Keychain / NSPanel / StatusBar / 两插件）+ 44 项测试全绿。遗留：Swift 未实机编译 |
| 2026-09-26 | [`2026-09-26-09-flutter-app-skeleton`](./sessions/2026-09-26-09-flutter-app-skeleton.md) | T-020 ✅：`app/` Flutter 3.47.5 工程落地（tokens/LfIcons/ADR-007 四 Provider + CancelToken/ADR-008 状态机 + DraftPipeline/13 页 UI + AppShell/main）。修复首编 85 error + CanvasKit 中文字体打包（Noto Sans CJK SC）+ Material 祖先缺失 + L 页溢出。`flutter analyze` 0 issue；`flutter build web --release` ✓；冒烟 15/15 PASS 0 JS 错误；核心链路（长按🎤→录音 pill→成稿→预览 1.2s→落框）实测通过 |
| 2026-09-26 | [`2026-09-26-08-t015-typeless-chatterfly`](./sessions/2026-09-26-08-t015-typeless-chatterfly.md) | T-015 ✅：用户拍板参考系 **Typeless + Chatterfly**（成稿为主、翻译是开关）。PRD v3.2 定位对齐（§1.1/§1.4/§2 流程 A/§3/§5.1/§5.3①/§6 + 部署版 8 处同步）+ 竞品情报全量重写（Chatterfly 2026-09 内测六场景 Skill / Typeless 2026 iOS 实况）+ v7 原型落地 `prototypes/v7-spa/`（Tab A 重写：同语言成稿默认 + pill 160×36 + 「译」开关默认关；Tab K Skills 六场景；修复 K→A hostThread 残留；无头冒烟 13 Tab 0 错误）+ 协议文档全量对齐 |
| 2026-09-26 | [`2026-09-26-07-prd-tidy-v6-prototype`](./sessions/2026-09-26-07-prd-tidy-v6-prototype.md) | T-017 ✅：v6 13 页全量原型落地 `prototypes/v6-spa/`（Tab A–M + Popover 最近译文 + 走查面板；修复 v5 遗留 runA 引用错误与孤儿 timer 竞态；无头冒烟通过）；PRD v3.1 整理修订（验收清单计数 24→22 实测、断链修复、§6 页面表落 Tab 字母）；prototypes/README 重写；协议文档全量对齐 |
| 2026-09-26 | [`2026-09-26-06-prd-v3-push`](./sessions/2026-09-26-06-prd-v3-push.md) | T-016 ✅：PRD v3.0 拆分上线（仅 §1-9 需求；§10 商业→[ADR-002](./sessions/2026-09-26-06-prd-v3-push.md) 补充；§11 风险→`roadmap.md`）+ ADR-005~008 新增（菜单栏范式/SPA原型/Provider接口/三态并列）+ v5 SPA 原型 push 到 `prototypes/v5-spa/` + PRD 部署版 HTML push 到 `assets/`。待 v5 验收与 T-015 口径。 |
| 2026-09-26 | [`2026-09-26-05-t014-research`](./sessions/2026-09-26-05-t014-research.md) | T-014 ✅：竞品调研完成（4 家超出计划：Typeless / Wispr Flow / Spokenly / MacWhisper）。HTML+CSS 解析 + 9 张产品截图落地 + vision 视觉层观察全维度记录 |
| 2026-09-26 | [`2026-09-26-04-t010-retro`](./sessions/2026-09-26-04-t010-retro.md) | T-010 复盘：5 维度教训（参照错位 / 定位权重 / 组件关系 / 触发范式 / 视觉调研缺失），状态回退 ⛔ |
| 2026-09-26 | [`2026-09-26-03-t010-prototype`](./sessions/2026-09-26-03-t010-prototype.md) | T-005 拍板选 ①；T-010 启动：HTML/CSS/JS 录音条三态 + 悬浮窗四态原型 + 浅深主题切换（已被否决） |
| 2026-09-26 | [`2026-09-26-02-agent-handoff`](./sessions/2026-09-26-02-agent-handoff.md) | 建立多 Agent 接续协议：`AGENTS.md` + `docs/{CONTEXT,TASKS,CONVENTIONS,SESSIONS}.md` + `docs/sessions/`，并把 README/INTERNAL 的重复进度清单改为指针 |
| 2026-09-26 | [`2026-09-26-01-prd-reorg`](./sessions/2026-09-26-01-prd-reorg.md) | PRD v2.0 精简为纯产品需求（保留 §1–§9），商业模式下沉 `decisions/002`，风险并入 `roadmap.md`；同步 README/INTERNAL 与 ADR 引用 |

## 3. 进行中 / 待领任务

见 [`TASKS.md`](./TASKS.md)。当前无 🟡 进行中任务。下一可领取任务：

- **T-012**（13 页字段级规格）— v7 已提供 13 页交互参照，可直接开工；产出 `pages-specs/`

其他可平行动作（不需要用户口径）：

- T-007 竞品实测（试用 Typeless / Bob / Chatterfly；本轮已完成 Chatterfly/Typeless 情报补全，剩实测项）
- T-013 Design Token 落地（口径已定：Typeless pill + 现行 Token）
- T-011 Provider 适配层 Dart 接口实现（[ADR-007](../decisions/007-provider-interface.md) 已定义接口）

## 4. 阻塞点（需用户拍板，Agent 不得自行假设）

| 阻塞项 | 影响 | 位置 |
|---|---|---|
| macOS 实机编译 | 决定桌面端能否真正可用（热键/注入/浮层） | `app/macos/Runner/*.swift`（需 macOS + Xcode） |
| v7 原型验收 | 决定成稿范式是否冻结，进入 T-012 字段级规格 | `prototypes/v7-spa/index.html`（本地打开，右下角「❓ 走查」） |
| License 未定 | 影响能否对外开源与 Issue/PR 开放策略 | `README.md` |
| 竞品数据未实测 | 官网对比表、定价论证不能定稿 | `competitors/*.md` 待实测项 |

## 5. 关键决策（已定，不可推翻）

见 [`decisions/`](../decisions/)：

**001-004（v2.0 时期）**：BYOK / 买断 / 五端含 Linux / Flutter+原生桥
**005-008（v3.0 时期，2026-09-26 新增）**：
- [ADR-005](../decisions/005-macos-menubar-pattern.md) macOS 菜单栏范式（Popover 而非主窗口）
- [ADR-006](../decisions/006-prototype-spa-app.md) 原型 SPA 化（单 HTML + JS + CSS）
- [ADR-007](../decisions/007-provider-interface.md) Provider 统一接口 `TranslationProvider`
- [ADR-008](../decisions/008-recorder-bar-three-states.md) 录音条三态并列展示

**本轮新增已拍板决策**（T-015 口径，2026-09-26 用户拍板）：
- 录音条默认形态：**Typeless pill**（160×36 基准，PRD v3.2 §5.1）
- 翻译功能产品化位置：**pill 右侧常驻「译」开关，默认关**（默认同语言成稿）
- 原型形态：延续 **HTML SPA**（v7 基座沿用 v6）
- 产品定位：**成稿为主，翻译是开关**（参考系 Typeless + Chatterfly，PRD v3.2 §1.1 口径）

## 6. 接续提示

- 仓库默认分支 `master`，公开仓库 `KevinSnoopy/yi-fanyi`
- 文档全部为中文，Markdown 格式约定见 [`CONVENTIONS.md`](./CONVENTIONS.md)
- 沙箱/容器内 `git push` 报 TLS 握手失败（`gnutls_handshake() failed`）时：先把 GitHub 真实 IP 写入 `/etc/hosts`（DNS 常被劫持到内网段）；仍失败则加 `-c http.version=HTTP/1.1` 再推，通常可绕过；若 github.com 完全被墙而 api.github.com 可通，可用 Git Data API 逐 commit 推送
- 不要在仓库中提交任何 Key、Token、个人凭据
- 沙箱内 Flutter 必须显式指定 SDK：`export PATH=/opt/flutter-3.47/flutter/bin:$PATH`（默认 `flutter` 是 3.0.0，pub 解不动）
- Web 构建前先 `bash app/tool/fetch_fonts.sh`，否则中文豆腐块
- 冒烟脚本坑：每 tab 独立 page + `service_workers='block'` + canvas 像素方差判活
- **vision 工具 1 张/次**（9 张/次必超时）
- **delegated subagent 写文件用沙盒隔离**，交付物必须由主 agent 重新落库
- **不要重复已有产品的截图到 README 正文**——独立存 `screenshots/` 子目录，正文引用路径
- **PRD 写作铁律**（[ADR-005..008](../decisions/) 期间总结）：PRD 仅含产品需求（§1-9）；商业模式→对应 ADR；风险→`roadmap.md` §风险；决策记录→`decisions/`
- **原型落地规范**：**唯一现行** v7 SPA 在 [`prototypes/v7-spa/`](../prototypes/v7-spa/)（3 文件，Tab A–M 13 页全量 + 成稿范式 + 走查面板）；**v1/v5/v6 原型与 v2.0 PRD、assets 部署版已按用户要求删除收敛，不得重建旧版副本**；13 页对照表见 [`prototypes/README.md`](../prototypes/README.md)
- **单一事实源铁律**：PRD 仅 `PRD_v3.0.md` 一份、原型仅 `prototypes/v7-spa/` 一套（2026-09-26 用户拍板）；历史回执与 ADR 中出现的旧路径（PRD_v2.0.md / v5-spa / v6-spa / assets/PRD_v3.0_deploy.html）均为历史引用，git 历史（`7442094` 之前）可溯
- **原型 JS 约定**：演示延时一律走 `schedule()`（playTimers 集合统一清理），禁止裸 `setTimeout` 存回单个变量——v5 的孤儿 timer 竞态就是这么来的（会话 07 修复）

## 7. 给下一个 Agent 的速读路径

1. 读 [`PRD_v3.0.md`](../PRD_v3.0.md)（**唯一 PRD**，最新 v3.2；v2.0 已删除收敛）
2. 读 [`prototypes/README.md`](../prototypes/README.md)（**唯一原型** v7 的 13 页对照表 + 成稿范式改动点 + 走查路径 + Design Token）
3. 读 [`competitor-research/README.md`](./competitor-research/README.md)（T-014 调研结论）与 [`competitors/chatterfly.md`](../competitors/chatterfly.md)、[`competitors/typeless.md`](../competitors/typeless.md)（2026 实况情报）
4. 读 [`2026-09-26-04-t010-retro.md`](./sessions/2026-09-26-04-t010-retro.md)（T-010 复盘，避免重蹈覆辙）
5. 读 [`2026-09-26-06-prd-v3-push.md`](./sessions/2026-09-26-06-prd-v3-push.md)（v3.0 拆分 + v5 SPA 落地说明）
6. 读 [`2026-09-26-07-prd-tidy-v6-prototype.md`](./sessions/2026-09-26-07-prd-tidy-v6-prototype.md)（v6 原型落地 + PRD v3.1 修订说明）
7. 读 [`2026-09-26-08-t015-typeless-chatterfly.md`](./sessions/2026-09-26-08-t015-typeless-chatterfly.md)（T-015 口径落地 + v7 成稿范式说明）
8. 下一任务默认 T-012（v7 已可作交互参照）；动 Tab A 前先读 T-015 口径与 PRD v3.2 §2.1

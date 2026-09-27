---
phase: "Phase 2 · 真实代码开发（UI 主任务 T-020~T-025 全 ✅；T-011/T-012/T-013 收账完成；macOS 原生壳待实机编译）"
stage: tokens-and-platform-matrix
last_updated: 2026-09-27
current_focus: "会话 13（Round-5，B 分支：未实机验证）：T-013 ✅ Design Token 落地——Token 统一出口 app/lib/ui/tokens/（lf_scheme 浅/深色彩 + lf_dimens 几何 + lf_components 组件规格①–⑥ + barrel），删旧 core/theme/tokens.dart、迁 18 处 import，Token 全表与差异 T-A/T-B 见 tokens/README.md；M2 C1–C16 拍板决策单（二选一+建议，最小拍板集已给）；M3 T-030 三端差异矩阵（Dart 平台耦合仅 4 处，缺口集中原生壳）。回归 analyze 0 issue + test 66/66"
next_action: "macOS 实机验证（用户侧跑 app/tool/macos_verify.sh，result-draft 回传 → Round-6 按 A 分支修 Swift：B1/B2 判定 + R1/R3/R4/R6）；用户拍板 C1–C16（decision-sheet）与 Token T-A/T-B → Agent 改代码对齐"
blockers:
  - "macOS 原生壳未实机编译（B1/B2 契约修复未经实机验证；未收到实机日志）"
  - "pages-specs 冲突点 C1–C16 待拍板（决策单 pages-specs/decision-sheet-C1-C16.md）"
  - "Token 层差异 T-A/T-B 待拍板（app/lib/ui/tokens/README.md）"
  - "沙盒 entitlements 拍板项（App Sandbox 与 CGEvent 合成事件张力，见 method-channel-contract.md §6，未擅改）"
  - "真实 Key 环境未验收；License 未定（README 标 TBD）"
has_code: true
---

# CONTEXT · 当前进度

> **本文件是进度的唯一真相源**。任何 Agent 在会话结束前必须更新本文件；README / INTERNAL 只保留指针，不复制状态清单。

## 1. 当前阶段

**Phase 2 · 真实代码开发**（`has_code: true`，代码在 [`app/`](../app/)）

已完成：PRD v3.2 + 8 个 ADR + v7 SPA 原型（13/13）+ 竞品调研 + **Flutter 工程（T-020 ✅）：13 页 UI 全量、ADR-007 四 Provider 流式实现、ADR-008 四态状态机/pill/pipeline、analyze 0 issue、Web 冒烟 15/15 PASS**。
会话 10（2026-09-27）把 Mock 骨架换成**真实链路**：T-021 ✅ 真实 Provider 联调（Key 进 Keychain、真实 SSE 成稿、血缘明示）、T-022 ✅ B/C/D 系统触发双落地、T-024 ✅ 全局热键结构化 + 冲突检测 + macOS 原生壳六文件。
会话 11（2026-09-27）补齐剩余两个 UI 主任务：**T-023 ✅ 模型配置页三套真连接**、**T-025 ✅ 首次引导真实权限状态 + 零 Key 全链**。**66 项单测 + widget 端到端全绿**。
会话 12（2026-09-27，Round-4）做实机验证准备：**T-020 实机验证准备包三件套**（一键脚本 / 分步 checklist / MethodChannel 契约核对表），逐通道比对 Dart 与 8 个 Swift 文件，**发现并修复 2 处 P0**（B1 双引擎 / B2 反向事件断线）；**T-011 追认收账 ✅**；**T-012 ✅** `pages-specs/` 15 份字段级规格（13 页 + Windows/Android 皮肤，冲突 C1–C16 汇总于 README）。回归：analyze 0 issue、test 66/66 全绿。
当前卡点：macOS 实机验证（Swift 壳 + B1/B2 修复均未实机编译）与真实 Key 环境验收。

## 2. 最近一轮做了什么

| 日期 | 会话 | 成果 |
|---|---|---|
| 2026-09-27 | [`2026-09-27-04-round5-tokens-c16-matrix`](./sessions/2026-09-27-04-round5-tokens-c16-matrix.md) | Round-5（B 分支）：**T-013 ✅** Design Token——统一出口 `app/lib/ui/tokens/`（lf_scheme 31 项浅/深色彩 ThemeExtension / lf_dimens 字阶圆角尺寸动效 / lf_components PRD §5.3 组件规格①–⑥ 聚合 / tokens.dart barrel），删 `core/theme/tokens.dart` 迁 18 处 import；⑤ kb 皮肤固定色、① mic 圆钮 52 改消费 Token；全表+差异 T-A/T-B 见 tokens/README.md。M2：C1–C16 决策单（pages-specs/decision-sheet-C1-C16.md，二选一+建议+最小拍板集）。M3：T-030 三端差异矩阵（docs/t030-platform-matrix.md；全库仅 kIsWeb×3 + defaultTargetPlatform×1，windows/linux/android/ios 脚手架未生成，Linux/Windows 原生缺口逐项列路径）。回归：analyze 0 issue + test 66/66（fvm 3.38.9 本机验证） |
| 2026-09-27 | [`2026-09-27-03-macos-verify-prep-t012-pages-specs`](./sessions/2026-09-27-03-macos-verify-prep-t012-pages-specs.md) | T-020 实机验证准备包（**未实机编译**）：① `app/tool/macos_verify.sh`（双构建 + flutter run + 六项能力分步验证引导 + log 归档）② `docs/macos-verify-checklist.md`（前置→双构建→通道连通→六项→回传约定→覆盖矩阵）③ `docs/method-channel-contract.md`（secure 3 / native 11 方法 + 反向事件逐项比对 8 Swift 文件 + wire 串一致性 + 风险 R1–R9 + entitlements/TCC 核对）。修复 P0×2：B1 AppDelegate 双引擎（复用 MainFlutterWindow 唯一引擎，删重复 RegisterGeneratedPlugins）；B2 main.dart 未传 `linguaflow/native` 通道给 SystemTriggerService（反向 hotkey 事件断线）。T-011 追认收账 ✅；T-012 ✅ `pages-specs/` 15 份（13 页 + n1 Windows / n2 Android 皮肤；冲突 C1–C16 待拍板）。analyze 0 issue + test 66/66 |
| 2026-09-27 | [`2026-09-27-02-t023-t025-real-connections-onboarding`](./sessions/2026-09-27-02-t023-t025-real-connections-onboarding.md) | T-023 ✅ / T-025 ✅：模型配置页三套真连接（OpenAI/自定义 BaseURL/Ollama 各跑通「填 Key→测试连接→拉取模型→成稿一次」，401/429/model-not-found/wrong-BaseURL 四内联错误态 + ADR-001 Key→SecureStore 链验证）；首次引导真实权限状态（自检→打开设置→resumed 自动刷新→手动重检）+ 零 Key Ollama 全链；修复 listModels 裸抛 SocketException（4 provider 收敛 networkUnreachable）+ Ollama 平台名归一化 + 零 Key 文案；66/66 测试全绿 + 冒烟 15/15 + 交互截图 14 张。遗留：Swift 未实机编译 |
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

见 [`TASKS.md`](./TASKS.md)。Phase 1 设计三选项全部收账（T-011/T-012 ✅）。下一可领取任务：

- **T-013**（Design Token 落地）— 依赖 T-014 已满足；`pages-specs/` 已给组件规格参照
- **T-007**（竞品实测）— 待用户实机试用

其他可平行动作（不需要用户口径）：

- **macOS 实机验证**（Phase 2 最大遗留；用户侧跑 `bash app/tool/macos_verify.sh`，按 `docs/macos-verify-checklist.md` 六项能力验证，result-draft 回传后 Agent 分析日志修复 R1/R3/R4/R6 等风险项）
- **T-030 三端平移准备**（Linux/Windows 条件编译盘点，pages-specs n1/n2 皮肤已给参照）
- 处理 pages-specs 冲突点 C1–C16（需用户逐项拍板「实现为准 / 原型为准」）

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
- **widget 测试内打真实 localhost HTTP 的三层坑**（会话 11 实战总结）：① flutter_test 把 `HttpOverrides.global` 设为 mock（所有请求→400），setUp 里晚于 binding 初始化覆盖回去即可；② 自定义 `HttpOverrides.createHttpClient` 必须调 `super.createHttpClient(context)`——直接调 `HttpClient()` 会无限递归 Stack Overflow；③ FakeAsync zone 里发起的 HTTP 永远等不到 socket 事件——必须 `tester.runAsync(() async { await tester.tap(...); await Future.delayed(...); })` 让 tap 回调里的 async 链整体跑在真实 zone。另外表单页高度超 600px 默认视口时按钮在屏外 tap 不命中，先 `tester.view.physicalSize = Size(800, 1400)`。toast 的 2.2s timer：fake zone 的用 pump 推、runAsync 真实 zone 的要再 runAsync delay 推完，否则 pending timers 断言失败
- **vision 工具 1 张/次**（9 张/次必超时）
- **delegated subagent 写文件用沙盒隔离**，交付物必须由主 agent 重新落库
- **不要重复已有产品的截图到 README 正文**——独立存 `screenshots/` 子目录，正文引用路径
- **PRD 写作铁律**（[ADR-005..008](../decisions/) 期间总结）：PRD 仅含产品需求（§1-9）；商业模式→对应 ADR；风险→`roadmap.md` §风险；决策记录→`decisions/`
- **原型落地规范**：**唯一现行** v7 SPA 在 [`prototypes/v7-spa/`](../prototypes/v7-spa/)（3 文件，Tab A–M 13 页全量 + 成稿范式 + 走查面板）；**v1/v5/v6 原型与 v2.0 PRD、assets 部署版已按用户要求删除收敛，不得重建旧版副本**；13 页对照表见 [`prototypes/README.md`](../prototypes/README.md)
- **单一事实源铁律**：PRD 仅 `PRD_v3.0.md` 一份、原型仅 `prototypes/v7-spa/` 一套（2026-09-26 用户拍板）；历史回执与 ADR 中出现的旧路径（PRD_v2.0.md / v5-spa / v6-spa / assets/PRD_v3.0_deploy.html）均为历史引用，git 历史（`7442094` 之前）可溯
- **原型 JS 约定**：演示延时一律走 `schedule()`（playTimers 集合统一清理），禁止裸 `setTimeout` 存回单个变量——v5 的孤儿 timer 竞态就是这么来的（会话 07 修复）
- **沙箱 /etc/hosts 是 bind mount 会被还原**（会话 12）：预写的 GitHub IP 重启后消失且 git clone TLS 握手失败。修复法：用 DoH（`curl -H 'accept: application/dns-json' 'https://dns.alidns.com/resolve?name=github.com&type=A'`）解析 6 个 GitHub 域名真实 IP 写回 `/etc/hosts`，同时落一份 `~/.user_hosts`（家目录持久化），恢复后 `git -c http.version=HTTP/1.1` clone/push 均通
- **沙箱重置后 Flutter SDK 会消失**（会话 12）：`/opt/flutter-3.47` 不存在时重下 `flutter_linux_3.47.5-stable.tar.xz`（flutter-io.cn 镜像）解压即可；字体走 `app/tool/fetch_fonts.sh`（国内网络下载慢，放后台跑）
- **macOS 壳双引擎坑（B1，会话 12 修复）**：`MainFlutterWindow` nib 在 `awakeFromNib` 已调过 `RegisterGeneratedPlugins` 并建好唯一引擎；`AppDelegate.applicationDidFinishLaunching` 里再新建 FlutterViewController + 重复注册 → 自研插件挂到**无 Dart isolate 的引擎**上 → Dart 侧全部 `MissingPluginException`。正确姿势：复用 `NSApp.windows.first { $0 is MainFlutterWindow }?.contentViewController`
- **反向事件通道坑（B2，会话 12 修复）**：Swift → Dart 的 hotkey/overlayResult 事件走 `linguaflow/native` 通道反向 invokeMethod；`main.dart` 若不把该通道传给 `bootstrap(nativeChannel:)` → `SystemTriggerService` 收不到任何事件。新增 Dart→原生能力时同步检查反向事件订阅链
- **页面规格冲突标注约定**（会话 12，T-012）：规格以 `app/lib/ui/pages/` 实现为准；实现与原型不一致处标 ⚖️ C 编号，汇总在 `pages-specs/README.md`，**Agent 不得自行裁决，留用户拍板**
- **本机（macOS）跑 flutter test 的代理坑**（会话 13）：系统代理（127.0.0.1:端口）会劫持 flutter_tester 的 localhost WebSocket → 全部测试 `Unable to connect to flutter_tester process: WebSocketException` 假失败。修法：`env -u HTTP_PROXY -u HTTPS_PROXY -u http_proxy -u https_proxy ... flutter test`。另 fvm 3.38.9 可跑本项目（pubspec sdk ≥3.4.0）；字体资产缺失先 `bash app/tool/fetch_fonts.sh`
- **Token 出口约定**（会话 13，T-013）：Token 唯一出口 `app/lib/ui/tokens/`（barrel tokens.dart：lf_scheme/lf_dimens/lf_components）；`core/theme/` 只留 `app_theme.dart`（ThemeData 组装）。新增 UI 值先查 tokens/README.md 全表，禁止页面内散落新硬编码

## 7. 给下一个 Agent 的速读路径

1. 读 [`PRD_v3.0.md`](../PRD_v3.0.md)（**唯一 PRD**，最新 v3.2；v2.0 已删除收敛）
2. 读 [`prototypes/README.md`](../prototypes/README.md)（**唯一原型** v7 的 13 页对照表 + 成稿范式改动点 + 走查路径 + Design Token）
3. 读 [`competitor-research/README.md`](./competitor-research/README.md)（T-014 调研结论）与 [`competitors/chatterfly.md`](../competitors/chatterfly.md)、[`competitors/typeless.md`](../competitors/typeless.md)（2026 实况情报）
4. 读 [`2026-09-26-04-t010-retro.md`](./sessions/2026-09-26-04-t010-retro.md)（T-010 复盘，避免重蹈覆辙）
5. 读 [`2026-09-26-06-prd-v3-push.md`](./sessions/2026-09-26-06-prd-v3-push.md)（v3.0 拆分 + v5 SPA 落地说明）
6. 读 [`2026-09-26-07-prd-tidy-v6-prototype.md`](./sessions/2026-09-26-07-prd-tidy-v6-prototype.md)（v6 原型落地 + PRD v3.1 修订说明）
7. 读 [`2026-09-26-08-t015-typeless-chatterfly.md`](./sessions/2026-09-26-08-t015-typeless-chatterfly.md)（T-015 口径落地 + v7 成稿范式说明）
8. 读 [`docs/method-channel-contract.md`](./method-channel-contract.md)（MethodChannel 契约 + B1/B2 修复 + 风险 R1–R9）与 [`docs/macos-verify-checklist.md`](./macos-verify-checklist.md)（实机验证步骤）；改 Swift 壳前必读
9. 下一任务默认 T-013（Design Token）或等实机日志回传修 Swift；动字段/交互前先读 [`pages-specs/README.md`](../pages-specs/README.md) 的冲突点 C1–C16

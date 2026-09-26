# 译语 · 实施路线图

> 基于 PRD v2.0 §3 优先级 + ADR 决策
> 最后更新：2026-09-26

## Phase 0 · 决策与设计（当前阶段）

| 任务 | 状态 | 备注 |
|---|---|---|
| PRD v2.0 完整记录 | ✅ done | `PRD_v2.0.md` |
| PRD v3.0 扩展（13 页字段级 + Design Token + 验收清单） | ✅ 2026-09-26 | `PRD_v3.0.md`（仅需求；商业模式/风险下沉） |
| 竞品初步调研（Typeless/Chatterfly/Bob） | 🟡 部分 | competitors/ 已建，待实测 |
| Typeless/Wispr Flow/Spokenly/MacWhisper 4 家设计调研 (T-014) | ✅ 2026-09-26 | docs/competitor-research/ + 9 张截图 |
| ADR 001–004 核心决策（BYOK/买断/五端/Flutter） | ✅ done | decisions/ |
| ADR 005–008（菜单栏范式/SPA原型/Provider接口/三态并列） | ✅ 2026-09-26 | decisions/005–008 |
| v5 SPA 原型落地 | ✅ 2026-09-26 | prototypes/v5-spa/，3 文件 105KB |
| v6 完整 13 页原型 (T-016) | ⬜ 待开始 | 等用户对 v5 验收 |
| Provider 接口草案 | 🟡 部分 | ADR-007 已定义，T-011 待实施 |
| 页面字段级规格 (pages-specs/) (T-012) | ⬜ 待开始 | 13 页每页一份 |

## Phase 1 · macOS MVP（建议下一阶段）

**目标**：用 macOS 验证完整 P0 流程，作为其他平台的基础。

### 范围（P0）

按 PRD §3：
- [ ] **流程 A**：按住 Fn 说话 → 转写 → 翻译 → 写回
- [ ] **流程 B**：⌥空格悬浮窗翻译
- [ ] **流程 C**：⌥D 划词翻译
- [ ] **流程 D**：⌥↩ 静默替换
- [ ] **模型配置**：OpenAI + 自定义 BaseURL + Ollama
- [ ] **全局热键**：含冲突检测
- [ ] **首次引导**：三步
- [ ] **设计 Token**：浅深主题 + 录音条三态 + 悬浮窗四态

### 范围（P1，先不做的）

- Whisper 本地、OCR、Profile 路由、Skill、术语表、历史用量、隐私锁

### 验收

- macOS 上能用 OpenAI Key 完成一次完整的"按住 Fn 说话 → 中译英 → 写回 WhatsApp"
- 模型配置页面能跑通三种 BaseURL
- 全局热键和 ChatGPT/Bob/Typeless 不冲突

### 工期估算

- Flutter 脚手架 + macOS 原生桥：1 周
- Provider 适配层（OpenAI/Anthropic/Gemini/Ollama）：1 周
- UI 设计 Token + 三个核心组件：1 周
- 五流程实现：2 周
- 模型配置 + 首次引导 + 异常处理：1 周

**总计**：6 周 MVP。

## Phase 2 · Linux + Windows

把 Phase 1 的 macOS 实现平移：

- Linux：GTK 注入 + PulseAudio + libsecret
- Windows：Hook + WASAPI + DPAPI

**预期**：每端 3 周（基于 macOS 已有基础）。

## Phase 3 · 移动端

- Android 输入法：完整功能（录音可用）
- iOS 键盘扩展：流程受限（PRD §2.6）

**预期**：Android 4 周、iOS 6 周（含审核反复）。

## Phase 4 · P1 功能补完

按 PRD §3 P1：
- 本地 Whisper（whisper.cpp + Dart FFI）
- 截图 OCR（macOS Vision / Win OCR / Tesseract）
- 多 Profile 路由
- Skill 市场
- 术语表
- 历史 + 用量统计
- 隐私锁
- 开机自启

## Phase 5 · 商业化

- 官方中转（可选）功能
- 官网 + 购买页
- macOS App Store 上架（可选）

## 资源依赖

- **设计**：Figma 模板 + 设计 Token 落实
- **后端**：无需（流量直连模型方）
- **运营**：用户社群（Discord/QQ 群）
- **法务**：隐私政策（强调零采集）、服务条款、用户 Key 免责

## 风险

| 风险 | 缓解 |
|---|---|
| Flutter 原生桥调试成本 | 先 macOS 一端验证 |
| 多 Provider 流式协议差异 | 抽象层 + 单元测试覆盖 |
| 移动端审核被拒 | 提前看 Apple/Google 政策 |
| 竞品跟进 BYOK | 我们已有先发 + 社区 |

## 里程碑

| 里程碑 | 目标日期 | 退出条件 |
|---|---|---|
| M0 决策归档 | 2026-09-26 | PRD + ADR + 路线图 |
| M1 macOS MVP | T+6 周 | 流程 A/B/C/D 跑通 |
| M2 Linux+Win | T+12 周 | 三桌面端完整 |
| M3 Android+iOS | T+22 周 | 五端覆盖 |
| M4 P1 全功能 | T+30 周 | PRD §3 全 done |
| M5 商业化 | T+34 周 | 官网 + 中转 + 上架 |
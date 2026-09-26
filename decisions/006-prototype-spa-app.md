# ADR-006 · 原型阶段采用 SPA App 化 (单 HTML + JS + CSS) 而非多页路由

- **状态**：✅ 已决策（2026-09-26，PRD v3.0 实施反馈）
- **影响 PRD**：§6 页面清单、原型交付形态
- **替代方案**：v1 早期的 13 个独立 HTML 文件（被否决：视觉割裂、跳转生硬、难演示状态流转）

## 1. 背景

PRD v2.0 §6 列了 13 个页面原型。早期 v1 原型尝试每个页面独立 HTML 文件（`prototypes/v1/01-recorder.html`、`02-floating.html` …），用户验收发现：

- 页面跳转生硬（白屏一闪）
- 视觉规范难统一（每页重复写 CSS）
- 难以演示跨页状态流转（如"主窗首页 → 模型配置 → 测试连接"的连续体验）
- 13 个独立部署 URL 验收成本高

## 2. 决策

**采用 SPA App 化**：单个 `index.html` + `app.js` + `_shared.css`（v5 实测文件名 `styles.css`），无路由目录，所有视图内嵌：

- 顶部 Tab 栏 ⌘1-6 / Ctrl+1-6 切换视图（演示用，**非真实产品热键**）
- 内部用 JS render 不同视图内容到同一个舞台（stageOverlay）
- 共享 Design Token、组件库、动画
- URL hash 同步视图（`#tab-A` / `#tab-B` ...），便于深链验收

## 3. 理由

| 维度 | 多页路由 | SPA App 化 ✅ |
|---|---|---|
| 视觉一致性 | 易漂移 | **强** — 共享 CSS |
| 状态流转演示 | 需多次跳转 | **流畅** — 同框切换 |
| 部署与验收 | 13 个 URL | **1 个 URL** |
| 维护成本 | 13 套 CSS/JS | **1 套** |
| 原型阶段框架负担 | Vue/React 工程化 | **零框架** — 纯 HTML/JS/CSS |

## 4. 影响

- **v5 落地**：[`prototypes/v5-spa/`](../../prototypes/v5-spa/)（index.html 18.8KB + app.js 40.8KB + styles.css 44.7KB）
  - *2026-09-26 注：v5/v6 已按用户要求删除收敛，路径为历史引用（git 历史 `7442094` 可溯）；SPA 形态由唯一现行 [`prototypes/v7-spa/`](../../prototypes/v7-spa/) 继承*
- **v6 扩展**：在 v5 基础上增加 6 个 tab（PRD §6 黄色项），不重建
- **真实产品**：Flutter 是路由化的，但 UI 设计 Token 与组件库共享一份（Flutter Material / 自研组件映射同一套 token）
- **PRD v3.0**：§6 页面清单表头标注「v5 实现」+ 「v6 待补」列

## 5. 与其他 ADR 关系

- 不冲突 ADR-001~005
- 与 [ADR-005 菜单栏范式](./005-macos-menubar-pattern.md) 配合：v5 SPA 内同框演示 Popover 形态与主窗口形态切换
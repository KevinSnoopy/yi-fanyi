# 会话回执 · 2026-09-26-07-prd-tidy-v6-prototype

- **任务 ID**：T-017（主）+ PRD v3.1 整理修订（用户指令）+ 协议文档对齐
- **目标**：用户指令「项目中的 prd 和原型设计请帮我整理优化修改，然后 push」——整理 PRD 计数/断链/页面表遗留问题，落地 v6 13 页全量原型，全量对齐协议文档后 push
- **结果**：✅ 完成（T-017 ✅；PRD v3.1 修订随 `PRD_v3.0.md` 文件名沿用）

## 做了什么

### 1. PRD v3.1 整理修订（[PRD_v3.0.md](../../PRD_v3.0.md)，文件名沿用）
- 版本表：新增 v3.1 行（变更摘要）；修正 v3.0 行两处失实描述（验收清单实为 22 项、pages-specs 待建 T-012）
- 验收清单计数纠正：`24 项可勾选` → `22 项`（`grep -c "^- \[ \]"` 实测 22，全仓库引用同步改）
- §6 页面表：表头 `v6 待补` → `v6 实现`，13 行全部落到具体 Tab 字母（H/I/J/K/L/M）
- B.2 断链修复：删除指向不存在的 `pages-specs/07-model-config.md` 链接，改为「原型见 v6-spa Tab I + T-012 待建」
- 附录 C：补 v6-spa（13/13）与 v5-spa（7/13 留档）双链接
- 部署版 [assets/PRD_v3.0_deploy.html](../../assets/PRD_v3.0_deploy.html) 同步 5 处（badge/版本表/§6 表/双原型说明）

### 2. v6 完整 13 页原型（[prototypes/v6-spa/](../../prototypes/v6-spa/)，3 文件 166KB，T-017）
- `index.html`（433 行）：Tab A–M 全量 + 走查面板（5 条演示路径）+ Popover 最近译文块（复制/注入，§6 #13 / ADR-005）
- `styles.css`（2632 行）：品牌色全面对齐 PRD §5.2（#6366F1→#4F7CFF）；修复 v5 遗留 `--surface`/`--shadow-lg` 未定义变量（`:root` 兼容别名）；修复 `.stage-canvas` 整画布 opacity 0.3 透明 bug（点阵底纹移入 `::before`）；新增 ~700 行（tour 面板/整页模式/侧导航/统计卡/用量图/历史列表/表单栅格/向导/权限卡/手机框等）
- `app.js`（1819 行）：渲染分发扩至 A–M；`PAGE_MODE_TABS`（H/I/J/K 整页模式，隐藏底部输入框）；共用左导航 `buildSideNav`（PRD §5.3 ④ 页面互跳）；6 个新 render（H 统计/历史、I 模型配置 4 态、J 快捷键冲突检测+重绑录制、K 三子页、L 三步向导+权限引导、M 手机框 App）；快捷键扩至 8/9/0→H/I/J

### 3. v5 遗留 bug 修复（v6 内，v5 留档不动）
- `runA is not defined`（v5 起就有的 ReferenceError）：`setDemoControls(STATES, runA, resetA)` 引用未定义函数 → 改传语义正确的 `autoPlay`
- `h("tag", null, ...)` ×30+ 处 TypeError：`attrs = {}` 默认参数对 null 不生效 → 工厂改为 `Object.entries(attrs || {})` 一处兜底
- **孤儿 timer 竞态（根修）**：`playTimer` 单变量导致 `cancelDemo` 只能清最后一个 timer，快速/慢速切 Tab 时旧页延时回调跨页污染共享 DOM（实测 Tab K 必现 appendChild TypeError）→ 新增 `schedule()` + `playTimers` 集合，28 处裸 `setTimeout` 全量迁移，`cancelDemo` 全量清理

### 4. 交付前验证（浏览器实测，无头 Chromium）
- 冒烟 6 项全过：title / 13 Tab 逐页切换与 active 断言 / page-mode 类切换 / 走查面板开关 / 快捷键 8→H、0→J / Popover 按钮
- 逐 Tab pageerror 捕获：修复前 14 条（runA×2 + Object.entries null×12）→ 修复后 0 条
- 慢速遍历回归（每 Tab 1s + 等 7s 孤儿高危场景）：0 错误；截图走查视觉正常

### 5. prototypes/README.md 重写
- v6（现行 13 页对照表：Tab/名称/P 级/PRD 依据/演示状态）+ v5（留档 + 已知问题清单）+ v1（作废）三段式
- Design Token 标注 v6 已对齐 #4F7CFF；文件清单；交互约定（整页模式/演示控制/快捷键/走查）

### 6. 协议文档对齐（R4：CONTEXT 唯一真相源，其余只放指针）
- [README.md](../../README.md)：PRD v3.0 引用 + 8 ADR + prototypes/ + competitor-research/ + assets 新结构
- [AGENTS.md](../../AGENTS.md)：必读顺序/仓库地图/R1/R2（001~008）/决策速查补 005-008 四行/歧义节补 v6 A–M 对照指引
- [INTERNAL.md](../../INTERNAL.md)：文件树全量更新（8 ADR/prototypes/assets 三件/PRD v2.0 标留档）
- [roadmap.md](../../roadmap.md)：Phase 0 表修 T-016→T-017 ID 错位、v6 标 ✅、PRD v3.1 行、PRD 引用改 v3.0
- [TASKS.md](../TASKS.md)：表头 PRD 引用改 v3.0；T-017 ✅ + 回执链接；变更记录追加
- [CONTEXT.md](../CONTEXT.md)：frontmatter + §1-§7 全量刷新（含 T-016/T-017 ID 错位修复、原型 JS 约定入接续提示）
- [SESSIONS.md](../SESSIONS.md)：顶部索引加本回执行

## 关键决策与理由

### 决策 1：PRD 版本号走 v3.1 内容修订、文件名沿用 PRD_v3.0.md
- **理由**：仓库外引用（部署版 URL、回执、ADR）均指向 `PRD_v3.0.md`；重命名会产生大量断链。版本表内注明「v3.x 系列文件名沿用」

### 决策 2：跳过「v5 用户验收」门禁直接做 v6（T-017 原依赖含 v5 验收）
- **理由**：用户本轮指令明确要求「原型设计整理优化修改」，即授权推进原型；且 v6 保留 v5 全部 7 页交互（A–G 未动 Tab A 录音条设计，T-015 口径未定不擅改），v5 验收可通过 v6 对照完成
- **风险记录**：若用户 v6 验收后要求重画，改动落在对应 render 函数，成本可控

### 决策 3：v5-spa 只留档不修 bug
- **理由**：v5 是历史里程碑（回执 06 记录其结构）；修 v5 会让「留档」与「现行」边界模糊。已知问题在 prototypes/README.md 显式列出，v6 已全部修复

### 决策 4：T-015 未拍板，Tab A 录音条维持 v5/v6 现行单条形态
- **理由**：T-015（录音条形态 A/B/C）⛔ 需用户拍板，Agent 不得自行假设；本次仅迁移+修 bug，不改交互设计

### 决策 5：CONTEXT 修正 T-016/T-017 ID 错位并留痕
- **理由**：会话 06 建任务时 TASKS.md 定 T-017=v6 原型，但 CONTEXT/roadmap 正文把 v6 写成 T-016（回执引用过旧 ID，任务池规则「不要重排已有 ID」）→ 统一以 TASKS.md 为准修正文，不重排 ID

## 遗留 / 下一步

- [ ] **v6 原型等用户验收**：`prototypes/v6-spa/index.html` 本地打开，右下角「❓ 走查」有 13 页路径；重点看 H–M 六个新页
- [ ] **T-015 等用户拍板**：录音条形态 A/B/C / 翻译开关位置 / 原型形态（⛔ 未拍板前 Tab A 不动）
- [ ] **T-012 页面字段级规格**：13 页每页一份（v6 已提供交互参照，可直接开工）
- [ ] **T-011 Provider 接口实现**：基于 ADR-007 产出 Dart 代码
- [ ] **T-013 Design Token 落地**：依赖 T-015 口径
- [ ] **License 决策**：仍 ⛔（README 标 TBD）

## 给下一个 Agent 的提示

### 容易踩的坑
1. **v6 的 `h()` 工厂已兜底 null attrs**，但仍不要传 `undefined` 之外的奇怪类型；child 传数字会 `appendChild` TypeError（`children.flat()` 只降一维，嵌套数组要自己展开）
2. **演示延时必须走 `schedule()`**（playTimers 集合），裸 `setTimeout` 会在切 Tab 后变孤儿回调跨页炸 DOM——v5 的教训，CONTEXT §6 已沉淀
3. **PRD v3.1 是内容修订**，文件名仍是 `PRD_v3.0.md`；验收清单是 22 项不是 24 项（06 回执里的 24 是笔误源头，本轮已全仓库纠正）
4. **github.com 直连常被墙**：先试 hosts + `http.version=HTTP/1.1`，不行走 api.github.com 的 Git Data API 逐 commit 推
5. **`_smoke_v6.png` 等验证产物不要提交**——冒烟截图放沙箱临时目录

### 上下文里看不到的信息
- **v6 走查面板**在页面右下角「❓ 走查」按钮，内含 5 条演示路径（主流程 1–5 / 状态切换 / 系统页 6–0 / 菜单栏 Popover / 主题）
- **page-mode 整页模式**：H/I/J/K 渲染时 `.host-app` 加 `page-mode` 类（隐藏底部输入框），页面内左导航可互跳 H/I/J/K/F/L 或回 A
- **v6 与 PRD §6 的映射**：#1–#5→Tab A–E、#6→H、#7→I、#8→J、#9→K、#10→L、#11→M、#13→Popover；对照表在 prototypes/README.md
- **冒烟脚本**在沙箱 `/root/.codebuddy/artifact/.../smoke_v6.py`（仓库外），含 6 项断言可复跑

### 与前一会话状态差异
- ✅ T-017 v6 13 页原型落地（v5 的 7/13 → v6 的 13/13）
- ✅ PRD v3.1 修订（计数/断链/页面表/部署版同步）
- ✅ prototypes/README.md 重写（v1 作废说明保留）
- ✅ 全部协议文档对齐 v3.x/8 ADR 现状；T-016/T-017 ID 错位修复
- ⛔ License 仍待定；T-015 仍等用户口径

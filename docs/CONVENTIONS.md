# CONVENTIONS · 文档与提交约定

> 多 Agent 并行时，格式与命名统一是接续成本的关键。新增内容请照此执行。

## 1. 语言与格式

- **正文语言**：简体中文；代码、标识符、技术专有名词（BYOK、Flutter、MethodChannel）保留英文
- **Markdown 规范**：
  - 标题层级不跳级（`#` → `##` → `###`）；表格用统一分隔符 `|---|---|`
  - 长文档（> 5 节）在开头加目录；跨文件引用一律用**相对链接**，不用绝对 URL
  - 章节内引用写作 `PRD §3`、`ADR-004`；跨文件引用写作 `[PRD §3](../PRD_v2.0.md)`
- **状态符号统一**（全仓库一致，勿自创）：⬜ 待开始 / 🟡 进行中·部分 / ✅ 完成 / ⛔ 阻塞

## 2. 命名

| 对象 | 规则 | 示例 |
|---|---|---|
| 会话回执 | `YYYY-MM-DD-NN-主题.md`，NN 为当日序号 | `2026-09-26-01-prd-reorg.md` |
| ADR | `NNN-kebab-case.md`，编号不复用 | `005-new-adrs-supersede.md` |
| 竞品文档 | 竞品名小写 | `competitors/typeless.md` |
| 页面规格 | 与 PRD §6 页面编号对应 | `pages-specs/07-model-config.md` |
| 分支 | `docs/`、`feature/`、`fix/` + kebab-case | `docs/reorg-prd`、`feature/flow-a` |

## 3. Commit 规范

采用 Conventional Commits，标题英文、正文中文：

```
<type>(<scope>): <英文简述>

<中文正文，说明改了什么、为什么>
```

- `type`：`docs` / `feat` / `fix` / `refactor` / `chore` / `adr`
- `scope`：`prd` / `adr` / `docs` / `roadmap` / `competitors` / `tasks` 等
- 一次提交只做一件事；文档整理与内容决策分开提交

示例：

```
docs(prd): 精简 PRD v2.0 为纯产品需求

- 保留 §1–§9 需求主体
- 商业模式下沉至 ADR-002
```

## 4. 分支与提交

- 默认分支 **`master`**；Phase 0（纯文档）允许直接 push `master`
- 进入代码阶段后：功能改动走 `feature/*` + PR，PR 描述需包含"改了什么 / 如何验证 / 关联任务 ID"
- **禁止提交**：API Key、Token、个人凭据、构建产物、`.env`

## 5. 状态一致性

- 进度只写在 `docs/CONTEXT.md` 与 `docs/TASKS.md`；README / INTERNAL / roadmap 只放指针或长期稳定的规划，不重复维护"当前状态"清单
- 修改 ADR 结论时：新建 ADR，原文头部加 `> 已被 ADR-0XX 取代（superseded）`，不直接改写历史结论

## 6. PRD 边界

- PRD **只描述产品需求**：用户价值、流程、功能与优先级、交互、设计规格、异常边界、非功能需求、技术约束
- 不属于 PRD：工期与里程碑（`roadmap.md`）、定价与商业模式（`decisions/002`）、下一步选项（`next_steps.md`）、项目风险（`roadmap.md`）

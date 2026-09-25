# 会话回执 · 2026-09-26-02-agent-handoff

- **任务 ID**：T-004
- **目标**：让任意 Agent 读取仓库后能在 2 分钟内接续开发，且结束前按统一协议留痕
- **结果**：✅ 完成

## 做了什么

- 新增 `AGENTS.md`（仓库根）：项目一句话、必读顺序、仓库地图、会话工作流协议（开始/进行/结束）、6 条硬规则、决策速查、常见歧义澄清
- 新增 `docs/CONTEXT.md`：进度唯一真相源，带 YAML front matter（phase / last_updated / next_action / blockers / has_code）便于机器解析
- 新增 `docs/TASKS.md`：任务池 T-001~T-050，含状态图例、领取规则、依赖、验收要点、关联文档
- 新增 `docs/CONVENTIONS.md`：语言与 Markdown 格式、命名规则、Conventional Commits、分支策略、状态一致性、PRD 边界
- 新增 `docs/SESSIONS.md`（索引 + 回执模板）与 `docs/sessions/`（本轮及上一轮回执）

## 关键决策与理由

- **用 `AGENTS.md` 而非自研文件名**：Claude Code / Codex / Cursor 等主流 Agent 会自动读取根目录 `AGENTS.md`，零配置生效；自研文件名需要每个 Agent 额外说明
- **CONTEXT.md 设为唯一真相源**：README / INTERNAL / roadmap 里原本各有一份"当前状态"清单，多 Agent 并行必然写冲突，收敛为指针 + 单一文件
- **任务带 ID 和依赖**：让 Agent 能自己判断"哪些任务现在可以领"，而不是每次都问用户
- **回执强制化**：没有留痕的工作对下一个 Agent 不可见，所以把"写回执"写进结束流程且标为缺一不可

## 遗留 / 下一步

- 进入代码阶段后需补充：代码目录结构、构建与测试命令、macOS 原生桥约定（写到 `AGENTS.md` 或新增 `docs/ENGINEERING.md`）
- T-005 / T-006 仍阻塞在用户决策

## 给下一个 Agent 的提示

- 顺序：先 `AGENTS.md` → `docs/CONTEXT.md` → `docs/TASKS.md`，不要从 commit 历史推断进度
- 下一轮若新增阶段（如开始写代码），记得回写 `CONTEXT.md` 的 `has_code` 与 `stage` 字段

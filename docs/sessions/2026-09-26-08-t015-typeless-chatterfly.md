# 会话回执 · 2026-09-26-08-t015-typeless-chatterfly

- **任务 ID**：T-015（顺带完成 T-003 的 Chatterfly/Typeless 情报部分）
- **目标**：按用户拍板的参考系 Typeless + Chatterfly，把「AI 翻译输入助手」重定位为「AI 语音成稿输入助手」，修订 PRD 与原型并 push
- **结果**：✅ 完成（待用户走查 v7 验收）

## 做了什么

### 1. 用户口径接收与解读（本轮最高输入）

用户原话：「参考腾讯的chatterfly和其他公司的Typeless这两个产品，这才是我想做的」。解读为四条产品准绳：

1. **成稿为主**：默认同语言成稿（口语进、书面语出），对应 Typeless 的 Dictate（第 1 feature）
2. **翻译是开关**：降级为可选能力，对应 Typeless 功能序列中 Translate（第 2 feature）
3. **六场景 Skill**：对齐 Chatterfly 内测六场景（会议纪要/工作汇报/项目进度/营销文案/邮件润色/Vibe-Coding 提示词）
4. **pill 录音条**：Typeless 式胶囊（160×36 基准），替代 v6 的 280×32 细条

### 2. 竞品情报全量重写（多源交叉验证）

- `competitors/chatterfly.md`（空壳→完整）：腾讯混元，2026-09-18 低调内测（macOS/Win，内测码），六场景 Skill，本地存储录音转写，免费；含与 Typeless 差异表、译语四条启示、待实测清单（「录音不上传≠文本不上传」疑点）
- `competitors/typeless.md`（全量重写）：iOS 2025-12 上线（v2.6.2），Dictate→Translate→Ask 序列，风格学习杀手锏，Free 8k 词/周（两来源冲突已标注待实测）+ Pro $12-30/月，zero cloud retention 姿态

### 3. PRD v3.2 定位对齐（`PRD_v3.0.md`，文件名沿用）

- 标题与定位：「AI 翻译输入助手」→「AI 语音成稿输入助手」；§1.1 加口径 blockquote（成稿为主，翻译是开关之一）
- §1.3 目标用户扩（高频职场人/创作者/Vibe-Coding）；§1.4 竞对表按新情报全量更新
- §2 流程 A 全量重写：默认同语言成稿；pill 右侧常驻「译」开关（默认关）；开关开→目标语言写入（可配双语）
- §3 功能清单：新增「翻译开关 P0」「按 App 语境自适应语气 P1」「风格学习 P2」；Skill 扩六场景
- §5.1 尺寸改 pill 160×36；§5.3① 三态图示改成稿范式；§6 页面清单加 v7 列
- 版本表新增 v3.2 行（T-015 拍板）
- `assets/PRD_v3.0_deploy.html` 部署版 8 处同步（python 批量 sub + assert 防漂移）

### 4. v7 原型落地（`prototypes/v7-spa/`，cp v6 后改造）

- `index.html`：标题改「译语 v7 · 13 页全量演示（成稿范式）」
- `app.js` renderA 整体重写：
  - 状态序列 录音中→成稿中（开关开=「翻译中」）→预览→已落框；场景改「微信 · 给李总的消息」
  - 新组件 `transSwitch()`：pill 右侧「译」开关，点击即时切换成稿/翻译双模式（stateIdx 1/2/3 内容随 `transOn` 切换，bar 带 `data-trans` 属性）
  - 成稿文案：口语「那个报价我确认没问题，下周三之前可以签合同」→ 书面化润色；开关开时英文写入
- `styles.css`：新增 `.bar-pill`（胶囊 999px 圆角、min-width 160px、预览态自适应加宽 max 400px）与 `.bar-trans-switch`/`.ts-label`/`.ts-track`/`.ts-thumb`（滑轨开关，`.on` 主色高亮）
- renderK Skills 子页：3 卡扩六场景 + 新建 Skill 全宽卡
- 顺手修复两处：
  - **ADR-008 回归**：v6 处理态有「Esc 取消」按钮，v7 重写时丢失，已补回（ADR-008 强制项：取消操作三态可见）
  - **K→A 切换残留**：`renderA` 不清 `hostThread`，从 K 切回 A 时设置页残留在聊天区（v6 遗留），加 `els.hostThread.innerHTML = ""`

### 5. 冒烟验证（Chromium 无头 + Playwright）

13 Tab 全遍历 + 翻译开关开/关（`data-trans` 属性断言）+ 处理态 Esc 取消按钮 + Skills 六卡片渲染 + pill 形态——**0 pageerror / 0 console.error，SMOKE PASS**。冒烟脚本与截图未入仓库（v6 教训）。

### 6. 协议文档对齐

- `prototypes/README.md`：现行改 v7-spa，v6 降留档；新增「v7-spa · 成稿范式」段落（改动点 5 条）；13 页总表 Tab A/K 行更新；尺寸段加 pill；下一步更新
- `docs/CONTEXT.md`：frontmatter（phase/stage/current_focus/next_action/blockers）；§1 阶段、§2 会话表、§3 待领任务（T-015 移除）、§4 阻塞点、§5 三项待定决策移入已拍板、§6/§7 指针与速读路径
- `docs/TASKS.md`：T-015 ⬜→✅（验收要点写实际落地）；T-021 验收要点同步成稿范式；变更记录加行
- `roadmap.md`：Phase 0 表加 PRD v3.2 与 v7 两行；头部更新
- `AGENTS.md`：「录音条设计」行补形态已拍板 Typeless pill；「语音交互」行改同语言成稿口径（PRD v3.2 §2.1）；目录树现行指针改 v7
- `README.md` / `INTERNAL.md`：现行原型指针 v6→v7

## 关键决策与理由

- **翻译开关默认关**：Typeless 范式的核心是「说话→成稿」零心智负担；翻译作为显式开关避免每次触发流程选择，与 Chatterfly「无翻译流程仍是表达助手」一致
- **pill 160×36 基准但预览态自适应加宽**：ADR-008 要求三态外形一致，但 160px 放不下预览整句；折中为胶囊形不变（999px 圆角）、宽度 min 160 / max 400 自适应，三态同组件同位置同动画
- **PRD 版本号 v3.2 而非 v4.0**：定位语句变化但流程 B-F、ADR 001-008、Tab B-G 交互均未推翻；v3.x 内演进，文件名沿用
- **v6 降留档而非删除**：翻译范式是 v7 的对照基线，走查对比有价值
- **改动范围控制**：Tab B-G 渲染函数不动（翻译场景本身合理），只重写 renderA + renderK Skills 子页 + 样式追加

## 遗留 / 下一步

- [ ] 用户走查 v7（重点 Tab A 成稿手感 + 开关切换；本地打开 `prototypes/v7-spa/index.html`）→ 验收后冻结
- [ ] T-012 字段级规格可直接开工（v7 已可作交互参照）
- [ ] T-007 竞品实测项仍未完成（Chatterfly 需内测码；Typeless 免费额度两来源冲突待实测确认）
- [ ] PRD §2 流程 A 的「双语写回可配」演示仅覆盖「仅译文」模式，双语模式待 T-012 细化

## 给下一个 Agent 的提示

- **T-015 口径是最高准绳**：一切涉及 Tab A / 录音条 / 翻译功能的改动，先读 PRD v3.2 §2.1——成稿为主、翻译是 pill 右侧开关（默认关），不得改回「录音即翻译」
- v7 的 `transOn` 状态在 renderA 闭包内，切换走 `barAt(currentStateIdx)` 全量重绘；演示延时已全部走 `schedule()`（playTimers 统一清理），新增延时必须沿用
- `.bar-pill` 在 `styles.css` 605 行区块（`.bar-preview` 之后）；`.bar-trans-switch` 系列紧随其后；改样式先看该区块注释
- 冒烟脚本要点：Tab 选择器是 `.stage-tab`（不是 `.tab-btn`），状态按钮在 `#demoStateRow` 容器内；冒烟临时文件不要提交进仓库
- `git push` 被墙时用 `-c http.version=HTTP/1.1 -c http.postBuffer=524288000` 绕过（本轮验证有效）
- bash 工作目录在本环境跨调用不保留，多文件操作一律用绝对路径（本轮 sed 连续 5 次因工作目录漂移失败，绝对路径一次通过）

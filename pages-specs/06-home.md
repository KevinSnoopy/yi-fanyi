# 06 · 主窗口-首页（Tab H）— PRD §6 #6

实现：`app/lib/ui/pages/settings_pages.dart`（HomePage，包在 `_SettingsLayout` 外框内，左导航 + 右内容）。
持久化：history 走 SharedPreferences（`store.load()` 恢复）；统计卡为演示初值（⚖️ C1/C2）。

## 字段表

| 字段 | 类型 | 默认值 | 校验 | 来源 | 交互 / 错误态 |
|---|---|---|---|---|---|
| `store.history` | List<HistoryRecord> | []（加载持久化） | — | **Profile**（SharedPreferences JSON） | HistoryRow 列表渲染（meta/time/dir/source/target/flow）；**onTap 空实现** ⚖️ C3 |
| `store.todayCalls` | int | 42 | — | Profile（内存演示初值） | addHistory 时 +1；其余流程未写 |
| `store.monthTokens` | double | 128.4（K tok） | — | 运行时（无写入方） | StatCard 展示 ⚖️ C1 |
| `store.monthCost` | double | 6.42（¥） | — | 运行时 | StatCard「¥6.42」⚖️ C1 |
| `store.avgFirstTokenMs` | int | 480 | — | 运行时 | StatCard「480ms」⚖️ C1 |
| 趋势图数据 | List<(String,int)> | 周一34…今日47 | — | 硬编码 | UsageChart 柱状 ⚖️ C2 |
| `_UsageToggleRow.active` | int | 0（天） | — | 运行时 | 天/周/月分段点选，**仅视觉切换**（数据不联动） |

## 空态 / 引导

- `history.isEmpty` → EmptyState：icon 'mic'，title「还没有任何记录」，副文案含**绝不白屏口径**（未配置模型先引导本地模型试用）
- 动作「先去完成首次引导」→ `onGoOnboarding`（app_shell 传 `onTab(11)` 跳 L 页）

## 历史行展示（HistoryRow）

字段：`record.time`（TimeOfDay 格式串）/ `record.dir`（'成稿' 或 '中→英'）/ `record.source` / `record.target` / `record.meta`（'{n} 字 · {x.x}s'）/ `record.flow`（A..D）。
写入方：FlowPage onFinal（flow='A'）；TranslateRunner（B/C/D 写入，见 02/03/04）。

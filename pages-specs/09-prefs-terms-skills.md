# 09 · 翻译偏好 / 术语表 / Skills（Tab K，三子页）— PRD §6 #9

实现：`app/lib/ui/pages/prefs_pages.dart`（PrefsPage）。子页状态机 `sub`：0 翻译偏好 / 1 术语表 / 2 Skills（_Subnav 分段）。

## 子页 0 · 翻译偏好

| 字段 | 类型 | 默认值 | 校验 | 来源 | 交互 / 错误态 |
|---|---|---|---|---|---|
| `store.sourceLang` / `store.targetLang` | String | '中文' / 'English' | — | **Profile**（JSON，load 恢复） | _LangBtn 只读展示；⇄ 交换按钮互换两者；注「悬浮窗/键盘内可临时互换」（未实装临时互换） |
| `store.translateStyle` | String | '商务' | 四选一 | **Profile** | _RadioCard：直译/意译/商务/口语；**消费方**：TranslateRunner/B/D 的 prompt tone |
| `store.autoDetectLang` | bool | true | — | **Profile** | LfSwitch；**未接入判定链** ⚖️ C8 |
| `store.previewMode` | String | '1.2 秒后自动写入' | 三选一 | **Profile** | _SelectBox（PopupMenu）：'1.2 秒后自动写入'/'总是预览'/'直接写入'；**未接入 DraftPipeline**（A 页恒 1.2s）⚖️ C7 |
| `store.bilingualWriteBack` | bool | false | — | **Profile** | LfSwitch；消费方：DraftPipeline.run(bilingual:) 双语写回 |

## 子页 1 · 术语表

| 字段 | 类型 | 默认值 | 校验 | 来源 | 交互 / 错误态 |
|---|---|---|---|---|---|
| `termTab` | String | '通用' | — | 运行时 | 四分表 chip：通用/跨境电商/法律合同/技术文档（带条数徽标） |
| `store.termsOf(tab)` | List<TermEntry> | 种子数据 | — | **Profile** | 列表 `take(8)` ⚖️ C6；空表占位「本分表暂无词条 · 点『添加词条』开始」 |
| 添加词条弹窗 | (source, target) | '' | **两侧 trim 非空才入库**；flag 固定 'both' | Profile | AlertDialog + 取消/添加；**无删除/编辑入口** ⚖️ C6 |
| 「CSV 导入」「应用范围」 | — | — | — | — | **无实现** ⚖️ C4 |
| 术语注入 | — | — | — | 运行时 | `store.glossaryJson()` 在 A/B/C/D 每次成稿/翻译时注入 prompt（P0 已通） |

## 子页 2 · Skills（对齐 Chatterfly 六场景）

| 字段 | 类型 | 默认值 | 校验 | 来源 | 交互 / 错误态 |
|---|---|---|---|---|---|
| `store.skills` | List<Skill> | 种子六场景（id/name/desc/icon/meta/custom=false） | — | **Profile** | SkillCard 网格（2-4 列自适应，高 150）；**onTap 空实现** ⚖️ C5 |
| 「新建 Skill」 | Skill | id:'new'，custom:true | — | — | 全宽卡 78 高；onTap 空 ⚖️ C5 |
| 分享口径文案 | — | — | — | 硬编码 | 「JSON 分享（含术语表引用），不上传任何内容（ADR-001）」——导入导出未实装 |

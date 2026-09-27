# 08 · 快捷键设置（Tab J）— PRD §6 #8 · §4

实现：`app/lib/ui/pages/settings_pages.dart`（HotkeysPage）+ `app/lib/services/hotkeys.dart`（HotkeyManager）。
三子态：0 已绑定 / 1 冲突检测 / 2 重绑录制中（顶部分段 chip 可切，实际状态由录制动作联动）。

## 字段表

| 字段 | 类型 | 默认值 | 校验 | 来源 | 交互 / 错误态 |
|---|---|---|---|---|---|
| `store.hotkeys` | List<HotkeyItem> | kDefaultHotkeys 4 条 | — | **Profile**（SharedPreferences） | hk-a 按住 Fn（holdToRecord）/ hk-b ⌥ Space / hk-c ⌥ D / hk-d ⌥ ↩；展示串 mac/win 双份 |
| `view` | int | 0 | — | 运行时 | 分段切换 |
| `recordingId` | String? | null | — | 运行时 | HotkeyRow「重绑」→ `_startRecord(id)` → view=2 + Focus 抢占 |
| `draftCombo` | HotkeyCombo? | null | — | 运行时 | 录制面板 chip 实时显示（'…' → 组合串） |
| `_onRecordKey` | KeyEvent 回调 | — | Esc=取消回 view=1；只按修饰键=继续等主键；主键落下=组合完成 | 运行时（Focus.onKeyEvent + HardwareKeyboard.logicalKeysPressed） | 键名归一 `hotkeyKeyNameOf`（space/enter/escape/tab/fn/单字符） |
| `conflicts`（实时） | Map<String,HotkeyConflict> | — | — | 运行时（`manager.detectConflicts()`） | view=1 空则绿卡「未检测到冲突 · {lastReport.summary}」；有则 InlineError 逐条「{label}：{owner}（{reason}）」 |
| `manager.paused` | bool | false | — | 运行时（进程内） | 「临时禁用/已禁用」按钮 → `setPaused`（原生 unregister + 进程内 paused 双停）；「恢复默认」→ `resetToDefaults(kDefaultHotkeys)` |
| `lastReport` | HotkeyRegisterReport? | null | — | 运行时 | summary：原生「原生全局热键 N/N 生效」/ 否则「进程内热键（Web 预览）」；底部提示行显示「当前生效范围：原生全局（含其他应用）/ 应用内」 |

## 重绑语义（T-024）

`_applyRebind(id, combo)` → `manager.rebind(id, combo)`：
1. 写回 store（展示串 mac/win 按当前平台更新，另一平台保留旧值；macCombo/winCombo 写结构体）
2. `detectConflicts()` 实时检测 → conflictWith 写回（有冲突标红但**允许保存**）
3. `registerAll()` 立即重注册原生
4. toast：无冲突「「{label}」已重绑为 {combo.format(platform)}」/ 有冲突「已保存，但冲突：{owner}」

## 冲突表口径

系统级 fatal（Spotlight ⌘Space / 输入法切换 ⌃Space / 截屏 ⌘⇧4 / ⌥⇧S / ⌘Tab / Win 系列表 / Linux 桌面）+ 第三方软冲突 fatal:false（⌥Space→Alfred/Raycast、微信截图 Ctrl Alt A、有道划词 Ctrl Alt D、QQ 截图 Ctrl Alt S、GNOME 终端 Ctrl Alt T）。内部重复（同一 wire 串绑两条）也判 fatal。

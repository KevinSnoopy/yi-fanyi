# pages-specs · 字段级规格索引（T-012）

> Round-4 产出。**口径：以 `app/lib/ui/pages/` 实际实现为准**（flow_page / flow_demos / settings_pages / prefs_pages / onboarding_page / mobile_pages / platform_skins + app_shell 布局），原型 `prototypes/v7-spa/` 仅作交互参照。
>
> 每页一张字段表：**字段名 / 类型 / 默认值 / 校验 / 来源 / 交互（含错误态）**。
> 「来源」三档：`Profile`（SharedPreferences 持久化，重启保留）、`SecureStore`（系统密钥串）、`运行时`（State 内易失，切页即重置）。

## 与 PRD §6 的映射（13 页 + 2 附页）

| PRD §6 # | 页面 | Flutter Tab | 实现文件 | 规格 |
|---|---|---|---|---|
| 1 | 录音条三态 | A 语音输入 | flow_page.dart + overlays/recorder_pill.dart + engine/recorder_state_machine.dart | [01-recorder-pill.md](01-recorder-pill.md) |
| 2 | 迷你悬浮窗 | B 悬浮窗 | flow_demos.dart + overlays/{floating_windows,live_overlays}.dart | [02-floating-window.md](02-floating-window.md) |
| 3 | 划词译文小窗 | C 划词翻译 | flow_demos.dart | [03-selection-popover.md](03-selection-popover.md) |
| 4 | 静默状态条 | D 静默替换 | flow_demos.dart | [04-silent-replace.md](04-silent-replace.md) |
| 5 | 截图 OCR 双栏窗 | E OCR 翻译 | flow_demos.dart + overlays/floating_windows.dart | [05-ocr-window.md](05-ocr-window.md) |
| 6 | 主窗-首页 | H 首页 | settings_pages.dart（HomePage） | [06-home.md](06-home.md) |
| 7 | 模型配置 | I 模型配置 | settings_pages.dart（ProvidersPage） | [07-providers.md](07-providers.md) |
| 8 | 快捷键设置 | J 快捷键 | settings_pages.dart（HotkeysPage） | [08-hotkeys.md](08-hotkeys.md) |
| 9 | 偏好/术语/Skills | K 偏好·术语 | prefs_pages.dart（三子页） | [09-prefs-terms-skills.md](09-prefs-terms-skills.md) |
| 10 | 首次引导 | L 首次引导 | onboarding_page.dart（OnboardingPage） | [10-onboarding.md](10-onboarding.md) |
| 11 | 移动 App 主页 + 隐私锁 | M iOS App + F 隐私锁 | mobile_pages.dart（IosAppDemoPage）+ onboarding_page.dart（PrivacyDemoPage） | [11-mobile-app-privacy.md](11-mobile-app-privacy.md) |
| 12 | 移动端键盘 | G iOS 键盘 | mobile_pages.dart（IosKbDemoPage） | [12-ios-keyboard.md](12-ios-keyboard.md) |
| 13 | 托盘/菜单栏 | （原生壳 + A..M 挂点） | macos/Runner/StatusBarController.swift | [13-menubar-popover.md](13-menubar-popover.md) |
| 附1 | Windows 端皮肤 | N | platform_skins.dart（WindowsDemoPage） | [n1-windows-skin.md](n1-windows-skin.md) |
| 附2 | Android 端皮肤 | O | platform_skins.dart（AndroidDemoPage） | [n2-android-skin.md](n2-android-skin.md) |

## 实现与 PRD/原型 冲突点汇总（⚖️ 待拍板 / 「实现为准」）

| # | 冲突点 | 现状 | 建议 | 出处 |
|---|---|---|---|---|
| C1 | H 页四个统计卡（今日调用/本月 token/本月花费/平均首字延迟）为**演示初值**，仅 `todayCalls` 随 addHistory 自增，其余恒定 | `todayCalls=42 / monthTokens=128.4 / monthCost=6.42 / avgFirstTokenMs=480` | 待拍板：P1 真实化（从 HistoryRecord 聚合）或保留演示值 | 06 |
| C2 | H 页 token 趋势图数据**硬编码**周一~今日 7 点 | 常量 `UsageChart(data: [...])` | 同上 | 06 |
| C3 | H 页历史行「点行回看」**未实现**（onTap 空动作） | `HistoryRow(onTap: () {})` | 待拍板：回看详情或去掉「点行可回看」文案 | 06 |
| C4 | K 页「CSV 导入」「应用范围：全部场景」按钮**无实现** | 静态 LfButton 无 onPressed | 待拍板：P1 或隐藏 | 09 |
| C5 | K 页 Skill 卡点击**无动作**（含「新建 Skill」） | `onTap: () {}` | 待拍板：Skill 编辑器范围 | 09 |
| C6 | K 页术语表仅渲染前 8 条 + 无删除/编辑入口 | `terms.take(8)` | 实现为准（MVP），编辑能力待拍板 | 09 |
| C7 | K 页「预览窗口」三选项（1.2s 自动/总是预览/直接写入）**未接入 DraftPipeline**——A 页恒为 1.2s 预览 | store.previewMode 已持久化但无消费者 | 待拍板：接入 or 降级为演示项 | 09 |
| C8 | K 页「语言自动检测」开关已持久化但**未接入判定链** | 同上 | 同上 | 09 |
| C9 | L 页平台目录（6 平台）与 I 页（8 平台，多 Ollama/自定义等）**不一致** | `kOnboardingCatalog` vs `kPlatformCatalog`，代码注释自知 | 待拍板：统一为一份目录 | 10 |
| C10 | A 页宿主标题/「已发送 2 条」/气泡文案为演示布景 | 硬编码 | 实现为准（演示页定位） | 01 |
| C11 | C 页 native 选区失败时回退**页面内预置词**（点选交互），不是真划词 | `readSelection() ?? _word` | 实现为准（无 AX 权限时的可用兜底） | 03 |
| C12 | F/M 页隐私锁、FaceID、零遥测徽章均为**演示序列**（定时器驱动），无真实 LocalAuthentication | 定时 1.5s/3.3s/6s 切态 | 实现为准（P1 平台能力） | 11 |
| C13 | E 页 OCR 为**演示序列**，无真实截图/识别链路 | 同上 | 实现为准（PRD §3 P1） | 05 |
| C14 | G 页键盘为**演示序列**（B.5 验收项的 UI 形制冻结） | 五态定时器 | 实现为准（T-031/T-032 实装） | 12 |
| C15 | I 页「跳过测试，直接保存（标记为未验证）」healthy=false，PRD §7 未定义此分支 | 已实现且展示「未测」徽标 | 实现为准（如实标记优于静默） | 07 |
| C16 | J 页临时禁用/恢复默认作用于全局热键，但**进程内 HardwareHotkeyListener 的 paused 判定**独立存在 | `manager.paused` 两处共享 ✓ 无冲突 | 无需动作（记录） | 08 |

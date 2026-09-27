# 附1 · Windows 端皮肤（Tab N）— T-030 参照

实现：`app/lib/ui/pages/platform_skins.dart`（WindowsDemoPage）。Win11 邮件窗口布景（Mica 风、8px 圆角、右侧 −□× 控制钮、居中任务栏 + 右下托盘）。
定位：三端视觉对齐参照（T-030 平移前冻结 Fluent 方角形制），**无真实 Win32 桥**。

## 演示序列（FlowDemoStateMixin，无 LiveFlowMixin）

| 态 | 定时 | 内容 |
|---|---|---|
| 0 | 0s | Win 邮件窗口 + 空输入框 |
| 1 | — | Win 语音成稿 pill 录音态（_WinPill：pill 形制 + Fluent 方角皮肤 + _MiniWave 10 根正弦波形条） |
| 2 | — | 流式成稿（_Cursor 光标闪烁条） |
| 3 | — | 右下角 _WinToast 通知 |
| 4 | — | 托盘上方 _WinQuickPanel（Acrylic 快速面板） |

## 字段表

| 字段 | 类型 | 默认值 | 来源 | 交互 |
|---|---|---|---|---|
| 布景文案 / 收件人 / 正文 | String | 硬编码 | — | 演示布景 |
| _MiniWave | 动画 | SingleTickerProviderStateMixin 正弦条 | 运行时 | 录音态波形（60fps 目标，PRD §8） |
| _WinQuickPanel 动作 | — | — | — | 演示占位（无绑定） |

## T-030 实装映射提示

- pill 复用 `overlays/recorder_pill.dart` 的 RecorderPill（皮肤参数化：圆角/阴影/材质）
- 托盘：Win32 Shell_NotifyIcon；快速面板：Win32 弹窗；toast：系统通知（对应 `NativeBridge.notify` 的 Windows 实装）
- 全局热键：RegisterHotKey（对应 `registerHotkeys` 的 Win 实现）；文本注入：SendInput / UIA（对应 TextInjector）

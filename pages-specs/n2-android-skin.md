# 附2 · Android 端皮肤（Tab O）— T-030/T-031 参照

实现：`app/lib/ui/pages/platform_skins.dart`（AndroidDemoPage）。Material You 风格 + 微信布景（灰绿气泡，与 G 页白绿区分）。

## 演示序列（FlowDemoStateMixin，无 LiveFlowMixin）

| 态 | 定时 | 内容 |
|---|---|---|
| 0 | 0s | Android 微信聊天布景（AndroidStatusBar 左时间右图标 + _AndroidInputRow） |
| 1..3 | — | 输入/翻译/成稿序列 |
| 4 | — | _M3AppHome：Material You App 主页（chip 按钮 _M3ChipBtn） |

## 字段表

| 字段 | 类型 | 默认值 | 来源 | 交互 |
|---|---|---|---|---|
| AndroidStatusBar | time | '9:41' 风格演示 | 硬编码 | 布景 |
| _AndroidInputRow | text | 演示布景 | 硬编码 | 布景 |
| _M3AppHome | 卡片/动作 | Material You 形制 | 硬编码 | 演示占位 |

## T-030/T-031 实装映射提示

- 输入法（IME）：`android:inputMethod` 服务 + InputConnection 注入（对应 TextInjector 的 Android 实装）
- 前台录音：RECORD_AUDIO 运行时权限（对应 `hasMicPermission` Android 桩的真实化）
- Key 存储：EncryptedSharedPreferences（对应 `ChannelSecureStore` Android 实现）

# 11 · 移动 App 主页 + 隐私锁（Tab M + Tab F）— PRD §6 #11

实现：`app/lib/ui/pages/mobile_pages.dart`（IosAppDemoPage）+ `app/lib/ui/pages/onboarding_page.dart`（PrivacyDemoPage，文件同页相邻）+ `overlays/floating_windows.dart`（LockScreen）。
⚖️ C12：两者均为**演示序列**（定时器驱动），FaceID/LocalAuthentication 平台能力留待移动端实装。

## Tab M · iOS App 主页（三态）

| 态 | 标签 | 内容 |
|---|---|---|
| 0 | App 主页 | PhoneFrame 内 _IosAppHome |
| 1 | 隐私锁 · FaceID | LockScreen(compact) 整屏覆盖（圆角 29 裁切） |
| 2 | 解锁成功 | _UnlockDoneBanner：「FaceID 验证通过 · 0.3s · 无遥测」 |

_IosAppHome 字段（全部演示布景，无绑定 store）：

| 卡片 | 行 | 值 |
|---|---|---|
| hero | 译语 logo + 「BYOK · 零采集 · 五端同步」 | 硬编码 |
| 当前配置 | 默认模型 / 语言方向 | 'Ollama · qwen2.5:7b' / '中文 → English'（硬编码，**不读 store**） |
| 键盘 | 引导开启译语键盘（未启用）/ 键盘术语表（通用 · 8 条） | 硬编码 |
| 隐私与安全 | 隐私锁 FaceID（LfSwitch value:true，onChanged 空）/ 零遥测（始终开启，不可关闭） | 静态 |

## Tab F · 隐私锁桌面演示（四态）

| 态 | 标签 | 定时 | 内容 |
|---|---|---|---|
| 0 | 已解锁 | 0s | 「隐私锁 · 已解锁」banner + 「立即锁定」按钮（→ 态 2） |
| 1 | 离开设备 | 1.5s | 警示 banner「Mac 合盖/屏保触发 · 倒计时 60s」 |
| 2 | 自动锁定 | 3.3s | LockScreen 整屏（直接落锁，无密码输入） |
| 3 | FaceID 解锁 | 6.0s | 成功 banner「解锁耗时 320ms · 未发送任何遥测」+「已解锁」徽标 |

宿主区介绍卡（_ShieldIntro）：隐私锁已激活 · 离开超 1 分钟锁定 · Badge（FaceID live/密码/TouchID）。

## 备注（待拍板口径）

- LockScreen 组件由 F/M 复用；`compact` 参数控制手机壳内尺寸。
- 「立即锁定」是唯一真实交互（setStateAt(2)）；解锁为定时器自动放行。
- 实装时字段预期：锁定触发源（合盖/屏保/手动）、倒计时时长（PRD 1 分钟）、生物识别 API（local_auth）、隐私锁开启态（应持久化到 Profile 并影响悬浮窗豁免——PRD §7「悬浮窗功能不受影响」）。

# ADR-004 · 技术栈选型 Flutter + 原生桥

> **状态**：已决策（PRD v2.0 §9）
> **决策日期**：2026-09-26

## 背景

PRD §9 一句话定了：**Flutter（UI+业务）+ 原生桥 + Provider 适配层 + SQLite + 系统密钥存储**。

## 决策

按 PRD 选择 Flutter + 原生桥。详细规划如下：

### 分层架构

```
┌──────────────────────────────────────────────────────────┐
│ Dart 业务层（Flutter）                                     │
│   · UI / 状态管理 / 业务流程                              │
│   · 不直接调原生 API，走 MethodChannel                     │
├──────────────────────────────────────────────────────────┤
│ Provider 适配层（Dart 端接口）                            │
│   · 统一 ChatRequest / ChatResponse 流式协议              │
│   · 实现：OpenAI / Anthropic / Gemini / 自定义 / Ollama  │
│   · 流式输出用 Stream<List<DeltaChunk>>                    │
├──────────────────────────────────────────────────────────┤
│ 原生桥（各平台 MethodChannel handler）                     │
│   · macOS:  Swift（全局热键、麦克风、焦点监测、键盘钩子）   │
│   · Win:    Kotlin/C++（Hook、热键、IME）                  │
│   · Linux:  C++ + GTK 注入                                │
│   · iOS:    Swift（键盘扩展、App Group）                   │
│   · Android: Kotlin（输入法服务、前台录音）                │
├──────────────────────────────────────────────────────────┤
│ 系统集成层                                                │
│   · 钥匙串：Keychain (macOS/iOS) / DPAPI (Win) /          │
│            libsecret (Linux) / EncryptedSharedPrefs (And)  │
│   · 数据库：SQLite + sqlcipher（可选加密）                │
│   · 麦克风：AVAudioSession / WASAPI / PulseAudio /       │
│            AudioRecord / AVAudioEngine                    │
│   · IME：自定义输入法服务（Android）/ 键盘扩展（iOS）       │
└──────────────────────────────────────────────────────────┘
```

### Provider 接口草案（Dart）

```dart
abstract class LLMProvider {
  String get id;
  Stream<ChatDelta> streamChat(ChatRequest req);
  Future<List<String>> listModels();
  Future<ProviderStatus> testConnection();
}

class ChatRequest {
  final String systemPrompt;
  final List<ChatMessage> messages;
  final Map<String, dynamic> params; // temperature, max_tokens 等
  final String? glossaryId;          // 术语表注入
}

class ChatDelta {
  final String text;                  // 增量文本
  final int inputTokens;
  final int outputTokens;
  final bool done;
}
```

### 流量路径（核心约束）

**用户的请求绝不经过我们的服务器**——直连用户配置的 BaseURL。

```
用户 → 译语进程 → HTTPS → OpenAI/Anthropic/DeepSeek/...
                （不经过任何中转）
```

这点必须做进隐私政策 + 技术审计。

## 论据（vs Electron / Tauri / 原生）

| 选项 | 优 | 劣 |
|---|---|---|
| **Flutter** ✓ | 五端覆盖、热键/IME 桥接成熟、Dart async 流式好 | 全局热键桥接需手写 |
| Electron | 生态大 | 体积大、性能差、IME/键盘扩展不友好 |
| Tauri | 体积小、Rust 性能好 | 移动端支持弱、生态比 Flutter 小 |
| 各端原生 | 体验最好 | 五端开发成本 ×3~5 |

Flutter 在跨平台 + 移动端体验上平衡最好，符合五端策略（ADR-003）。

## 风险与对策

| 风险 | 对策 |
|---|---|
| Flutter 全局热键桥接复杂 | 先 macOS 一端验证，再平移 |
| Provider 流式协议各家不一 | 抽象 ChatDelta，各 provider 自己实现 map |
| 钥匙串跨平台不一致 | 统一 `SecureKeyStorage` 接口 |

## 关联

- PRD §9 技术架构
- ADR-003 五端覆盖
- Kimi 选项 ②：Provider 适配层 Dart 接口定义（详见 `next_steps.md`）
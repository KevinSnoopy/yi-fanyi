# ADR-007 · Provider 适配层统一接口 (TranslationProvider)

- **状态**：✅ 已决策（2026-09-26，PRD v3.0 §9 落地）
- **影响 PRD**：§9 技术约束 / §3 P0 模型配置
- **依赖**：[ADR-004 Flutter+原生桥](./004-flutter-native-bridge.md)

## 1. 背景

译语 BYOK 设计 ([ADR-001](./001-byok-not-managed.md)) 需要支持多个模型平台：

- OpenAI 兼容（含 DeepSeek / 通义 / 火山 / 自定义 BaseURL）
- Anthropic Claude
- Google Gemini
- Ollama / 端侧 MLC
- 未来：Mistral、Llama 直连、Cohere

每个 Provider 的协议、流式格式、错误码、鉴权方式都不同。如果不在抽象层收敛，每个流程（A/B/C/D）都要写 N 套分支，复杂度爆炸。

## 2. 决策

**所有模型方实现统一 `TranslationProvider` Dart 接口**，业务层只调接口不感知 Provider。

### 接口草案（v0.1）

```dart
abstract class TranslationProvider {
  String get name;
  String get defaultBaseUrl;

  /// 流式翻译；cancelToken 用于静默替换中途焦点切换时终止
  Stream<String> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
    String? systemPrompt,
    String? glossaryJson,
    CancelToken? cancelToken,
  });

  /// 拉取模型列表（用于"模型下拉"自动填充）
  Future<List<String>> listModels();

  /// 用户填完 Key 后一键测试（健康检查 + 鉴权验证 + 模型可用性）
  Future<ConnectionTestResult> testConnection();

  /// 释放资源（如关闭长连接）
  void dispose();
}

class ConnectionTestResult {
  final bool success;
  final String? errorCode;     // 如 '401', '429', 'model_not_found'
  final String? errorMessage;  // 原始 API 返回
  final int? latencyMs;
}
```

### 错误码收敛

| Provider 原生 | 译语统一 |
|---|---|
| OpenAI `401 invalid_api_key` | `auth_invalid` |
| OpenAI `429 rate_limit` | `rate_limited` |
| OpenAI `model_not_found` | `model_unavailable` |
| Anthropic `credit_balance` | `quota_exhausted` |
| Ollama `connection refused` | `network_unreachable` |
| 流中断 / 超时 | `stream_aborted` |

### 实现列表（v0.1 范围）

- `OpenAICompatibleProvider` — OpenAI / DeepSeek / 通义 / 火山 / 自定义（共享一套，仅 baseUrl 差异）
- `AnthropicProvider` — Claude 全系列
- `GeminiProvider` — Google Gemini
- `OllamaProvider` — 本地 Ollama（流式 + HTTP）

## 3. 理由

| 维度 | 不抽象（每流程写 N 套） | TranslationProvider ✅ |
|---|---|---|
| 业务层复杂度 | O(N×流程数) | **O(流程数)** |
| 新增 Provider 成本 | 改 5 处 | **新增 1 个 Provider 类** |
| 测试覆盖 | 难单元测试 | **易** — Mock 接口即可 |
| 流中断处理 | 各 Provider 各自实现 | **统一 cancelToken** |
| 错误提示用户友好 | 各 Provider 错码不统一 | **统一错码映射** |

## 4. 影响

- **ADR-004 Flutter+原生桥**：Provider 适配层在 Dart 侧实现
- **PRD §9**：技术约束需注明此接口存在
- **PRD §6 页面 #7**：模型配置页"测试连接"按钮调用 `testConnection()`
- **PRD §3**：本地模型（Ollama）P1 走的也是同一接口
- **下一步**：T-011 Provider 适配层 Dart 接口定义（[TASKS.md](../docs/TASKS.md)）

## 5. 待定项（开放问题）

- 流中断恢复策略（自动重连 vs 立即失败？）
- 多 Profile 路由（按场景选不同 Provider）的接口扩展
- 翻译用量统计埋点位置（接口层 vs 业务层）
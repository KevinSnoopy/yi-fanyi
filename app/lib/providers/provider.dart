/// ADR-007 · Provider 适配层统一接口。
///
/// 所有模型方实现统一 [TranslationProvider] Dart 接口，业务层只调接口不感知
/// Provider。错误码收敛表见 [LfErrorCode]；流式中断统一走 [LfProviderException]。
///
/// 流量约束（ADR-001 §3）：请求直连用户配置的 BaseURL，无自有中转。
library;

/// 统一错误码（ADR-007 §2 错误码收敛表）。
enum LfErrorCode {
  authInvalid('401 invalid_api_key'),
  rateLimited('429 rate_limit'),
  modelUnavailable('model_not_found'),
  quotaExhausted('credit_balance'),
  networkUnreachable('connection refused'),
  streamAborted('stream_aborted'),
  unknown('unknown');

  const LfErrorCode(this.label);
  final String label;
}

class LfProviderException implements Exception {
  LfProviderException(this.code, this.detail, {this.httpStatus});
  final LfErrorCode code;
  final String detail; // 模型方原始返回（内联错误条展示用）
  final int? httpStatus;

  @override
  String toString() => 'LfProviderException(${code.name}: $detail)';
}

/// 连接测试结果（模型配置页「测试连接」）。
class ConnectionTestResult {
  const ConnectionTestResult({
    required this.success,
    this.errorCode,
    this.errorMessage,
    this.latencyMs,
  });

  final bool success;
  final String? errorCode; // 如 '401', '429', 'model_not_found'
  final String? errorMessage; // 原始 API 返回
  final int? latencyMs;
}

/// 统一翻译请求。
class TranslateRequest {
  const TranslateRequest({
    required this.text,
    required this.sourceLang,
    required this.targetLang,
    this.systemPrompt,
    this.glossaryJson,
    this.style,
  });

  final String text;
  final String sourceLang;
  final String targetLang;
  final String? systemPrompt;
  final String? glossaryJson; // 术语表注入（防专名错译，P0）
  final String? style; // 直译/意译/商务/口语（P1）
}

/// 统一成稿（润色）请求 —— 流程 A：口语进、书面语出（PRD v3.2 §2.1）。
class DraftRequest {
  const DraftRequest({
    required this.transcript,
    this.systemPrompt,
    this.glossaryJson,
    this.tone,
  });

  final String transcript; // STT 转写原话
  final String? systemPrompt;
  final String? glossaryJson;
  final String? tone; // im（口语）/ mail（书面）等 App 语境自适应
}

/// 取消令牌 —— 静默替换中途焦点切换、Esc 取消录音等场景统一终止。
class CancelToken {
  bool _cancelled = false;
  final List<void Function()> _listeners = [];

  bool get isCancelled => _cancelled;

  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    for (final l in _listeners) {
      l();
    }
    _listeners.clear();
  }

  void onCancel(void Function() cb) {
    if (_cancelled) {
      cb();
    } else {
      _listeners.add(cb);
    }
  }

  /// 未取消时抛出（流式循环里用于中断）。
  void throwIfCancelled() {
    if (_cancelled) throw LfProviderException(LfErrorCode.streamAborted, 'cancelled by user');
  }
}

/// ADR-007 §2 接口草案 v0.1。
abstract class TranslationProvider {
  String get name;
  String get defaultBaseUrl;

  /// 流式翻译；cancelToken 用于静默替换中途焦点切换时终止。
  Stream<String> translate(TranslateRequest req, {CancelToken? cancelToken});

  /// 流式成稿（口语 → 书面语；翻译开关打开时由调用方串联 translate）。
  Stream<String> draft(DraftRequest req, {CancelToken? cancelToken});

  /// 拉取模型列表（用于「模型下拉」自动填充）。
  Future<List<String>> listModels();

  /// 用户填完 Key 后一键测试（健康检查 + 鉴权验证 + 模型可用性）。
  Future<ConnectionTestResult> testConnection();

  /// 释放资源（如关闭长连接）。
  void dispose();
}

/// 把 HTTP 状态 + 响应体映射为统一错误码（ADR-007 收敛表）。
LfProviderException mapHttpError(int status, String body) {
  switch (status) {
    case 401:
    case 403:
      return LfProviderException(LfErrorCode.authInvalid, body, httpStatus: status);
    case 429:
      return LfProviderException(LfErrorCode.rateLimited, body, httpStatus: status);
    case 404:
      return LfProviderException(LfErrorCode.modelUnavailable, body, httpStatus: status);
    default:
      if (status >= 500) {
        return LfProviderException(LfErrorCode.networkUnreachable, body, httpStatus: status);
      }
      return LfProviderException(LfErrorCode.unknown, body, httpStatus: status);
  }
}

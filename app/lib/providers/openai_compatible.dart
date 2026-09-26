import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'provider.dart';

/// OpenAI 兼容 Provider —— OpenAI / DeepSeek / 通义 / 火山 / 自定义 BaseURL
/// 共享一套实现（ADR-007 §2 实现列表），仅 baseUrl 与默认模型不同。
///
/// 流式协议：`POST {base}/chat/completions` + `stream: true`，SSE `data:` 行，
/// 终止标记 `data: [DONE]`。
class OpenAICompatibleProvider implements TranslationProvider {
  OpenAICompatibleProvider({
    required this.name,
    required this.defaultBaseUrl,
    required this.apiKey,
    required this.model,
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = (baseUrl == null || baseUrl.isEmpty)
            ? defaultBaseUrl
            : baseUrl.replaceAll(RegExp(r'/+$'), ''),
        _client = client ?? http.Client();

  @override
  final String name;
  @override
  final String defaultBaseUrl;
  final String baseUrl;
  final String apiKey;
  final String model;
  final http.Client _client;

  /// 工厂：按平台名建对应实例（平台目录见 catalog.dart）。
  factory OpenAICompatibleProvider.forPlatform(
    String platform, {
    required String apiKey,
    required String model,
    String? baseUrl,
    http.Client? client,
  }) {
    final defaults = platformDefaults[platform] ??
        (name: '自定义', baseUrl: 'https://api.openai.com/v1', model: 'gpt-4o-mini');
    return OpenAICompatibleProvider(
      name: platform,
      defaultBaseUrl: defaults.baseUrl,
      apiKey: apiKey,
      model: model.isEmpty ? defaults.model : model,
      baseUrl: (baseUrl == null || baseUrl.isEmpty) ? defaults.baseUrl : baseUrl,
      client: client,
    );
  }

  /// 平台默认值（新增 Provider 表单预填用）。
  static const platformDefaults = <String, ({String name, String baseUrl, String model})>{
    'OpenAI': (name: 'OpenAI', baseUrl: 'https://api.openai.com/v1', model: 'gpt-4o-mini'),
    'DeepSeek': (name: 'DeepSeek', baseUrl: 'https://api.deepseek.com/v1', model: 'deepseek-chat'),
    '通义': (name: '通义', baseUrl: 'https://dashscope.aliyuncs.com/compatible-mode/v1', model: 'qwen-plus'),
    '火山方舟': (name: '火山方舟', baseUrl: 'https://ark.cn-beijing.volces.com/api/v3', model: 'doubao-pro-32k'),
  };

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      };

  Map<String, Object?> _payload(String system, String user) => {
        'model': model,
        'stream': true,
        'messages': [
          {'role': 'system', 'content': system},
          {'role': 'user', 'content': user},
        ],
      };

  @override
  Stream<String> translate(TranslateRequest req, {CancelToken? cancelToken}) {
    final system = req.systemPrompt ??
        _systemWith(
          'You are a professional translator. Translate the user text from '
              '${req.sourceLang} to ${req.targetLang}. Output ONLY the translation.',
          req.glossaryJson,
          req.style,
        );
    return _streamChat(system, req.text, cancelToken);
  }

  @override
  Stream<String> draft(DraftRequest req, {CancelToken? cancelToken}) {
    final tone = req.tone == 'mail' ? '正式书面语气' : '自然对话语气';
    final system = req.systemPrompt ??
        _systemWith(
          '你是专业的中文成稿助手。把用户的口语转写润色为书面文稿：去掉口头禅、'
              '补全标点、梳理逻辑，保持原意，语气为$tone。只输出润色后的文稿，不要解释。',
          req.glossaryJson,
          null,
        );
    return _streamChat(system, req.transcript, cancelToken);
  }

  String _systemWith(String base, String? glossaryJson, String? style) {
    var s = base;
    if (style != null) s += ' 翻译风格：$style。';
    if (glossaryJson != null && glossaryJson.isNotEmpty) {
      s += '\n术语表（专名必须按此翻译）：\n$glossaryJson';
    }
    return s;
  }

  /// 核心：SSE 流式调用 + CancelToken 中断。
  Stream<String> _streamChat(String system, String user, CancelToken? cancelToken) async* {
    cancelToken?.throwIfCancelled();
    final req = http.Request(
      'POST',
      Uri.parse('$baseUrl/chat/completions'),
    )..headers.addAll(_headers)..body = jsonEncode(_payload(system, user));

    final http.StreamedResponse resp;
    try {
      resp = await _client.send(req);
    } catch (e) {
      throw LfProviderException(LfErrorCode.networkUnreachable, e.toString());
    }
    if (resp.statusCode != 200) {
      final body = await resp.stream.bytesToString();
      throw mapHttpError(resp.statusCode, body);
    }

    final chain = resp.stream.transform(utf8.decoder).transform(const LineSplitter());
    await for (final line in chain) {
      cancelToken?.throwIfCancelled();
      if (!line.startsWith('data:')) continue;
      final data = line.substring(5).trim();
      if (data == '[DONE]') break;
      try {
        final json = jsonDecode(data) as Map<String, Object?>;
        final choices = json['choices'] as List<Object?>?;
        if (choices == null || choices.isEmpty) continue;
        final delta = (choices[0] as Map<String, Object?>)['delta'] as Map<String, Object?>?;
        final content = delta?['content'] as String?;
        if (content != null && content.isNotEmpty) yield content;
      } on FormatException {
        continue; // 忽略半包/心跳行
      }
    }
  }

  @override
  Future<List<String>> listModels() async {
    final resp = await _client.get(Uri.parse('$baseUrl/models'), headers: _headers);
    if (resp.statusCode != 200) throw mapHttpError(resp.statusCode, resp.body);
    final json = jsonDecode(resp.body) as Map<String, Object?>;
    final data = json['data'] as List<Object?>? ?? const [];
    return [
      for (final m in data)
        if (m is Map<String, Object?> && m['id'] is String) m['id']! as String,
    ];
  }

  @override
  Future<ConnectionTestResult> testConnection() async {
    final sw = Stopwatch()..start();
    try {
      final resp = await _client.get(Uri.parse('$baseUrl/models'), headers: _headers);
      sw.stop();
      if (resp.statusCode == 200) {
        return ConnectionTestResult(success: true, latencyMs: sw.elapsedMilliseconds);
      }
      final err = mapHttpError(resp.statusCode, resp.body);
      return ConnectionTestResult(
        success: false,
        errorCode: '${resp.statusCode}',
        errorMessage: err.detail,
        latencyMs: sw.elapsedMilliseconds,
      );
    } catch (e) {
      return ConnectionTestResult(
        success: false,
        errorCode: LfErrorCode.networkUnreachable.name,
        errorMessage: e.toString(),
        latencyMs: sw.elapsedMilliseconds,
      );
    }
  }

  @override
  void dispose() => _client.close();
}

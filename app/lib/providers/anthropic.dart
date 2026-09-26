import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'provider.dart';

/// Anthropic Claude Provider —— Messages API 流式协议。
///
/// SSE 事件：`content_block_delta` → `delta.text` 增量；
/// 鉴权：`x-api-key` + `anthropic-version` 头。
class AnthropicProvider implements TranslationProvider {
  AnthropicProvider({
    required this.apiKey,
    required this.model,
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = (baseUrl == null || baseUrl.isEmpty)
            ? kDefaultBaseUrl
            : baseUrl.replaceAll(RegExp(r'/+$'), ''),
        _client = client ?? http.Client();

  static const String _version = '2023-06-01';

  @override
  final String name = 'Anthropic';
  static const String kDefaultBaseUrl = 'https://api.anthropic.com/v1';

  @override
  final String defaultBaseUrl = kDefaultBaseUrl;
  final String baseUrl;
  final String apiKey;
  final String model;
  final http.Client _client;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-api-key': apiKey,
        'anthropic-version': _version,
      };

  Map<String, Object?> _payload(String system, String user) => {
        'model': model,
        'max_tokens': 2048,
        'stream': true,
        'system': system,
        'messages': [
          {'role': 'user', 'content': user},
        ],
      };

  @override
  Stream<String> translate(TranslateRequest req, {CancelToken? cancelToken}) {
    final system = req.systemPrompt ??
        'You are a professional translator. Translate from ${req.sourceLang} to '
            '${req.targetLang}. Output ONLY the translation.'
        '${req.glossaryJson != null ? '\nGlossary:\n${req.glossaryJson}' : ''}';
    return _streamChat(system, req.text, cancelToken);
  }

  @override
  Stream<String> draft(DraftRequest req, {CancelToken? cancelToken}) {
    final system = req.systemPrompt ??
        '把用户的口语转写润色为书面文稿：去口头禅、补标点、梳理逻辑，只输出润色结果。';
    return _streamChat(system, req.transcript, cancelToken);
  }

  Stream<String> _streamChat(String system, String user, CancelToken? cancelToken) async* {
    cancelToken?.throwIfCancelled();
    final req = http.Request(
      'POST',
      Uri.parse('$baseUrl/messages'),
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
    String? eventType;
    await for (final line in chain) {
      cancelToken?.throwIfCancelled();
      if (line.startsWith('event:')) {
        eventType = line.substring(6).trim();
        continue;
      }
      if (!line.startsWith('data:')) continue;
      final data = line.substring(5).trim();
      try {
        final json = jsonDecode(data) as Map<String, Object?>;
        // 余额耗尽：Anthropic 以 error 事件下发
        if (eventType == 'error' || json['type'] == 'error') {
          throw LfProviderException(LfErrorCode.quotaExhausted, data);
        }
        if (json['type'] == 'content_block_delta') {
          final delta = json['delta'] as Map<String, Object?>?;
          final text = delta?['text'] as String?;
          if (text != null && text.isNotEmpty) yield text;
        }
      } on FormatException {
        continue;
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
      // 最小 messages 调用验证鉴权（1 token 上限，成本可忽略）
      final resp = await _client.post(
        Uri.parse('$baseUrl/messages'),
        headers: _headers,
        body: jsonEncode({
          'model': model,
          'max_tokens': 1,
          'messages': [
            {'role': 'user', 'content': 'ping'}
          ],
        }),
      );
      sw.stop();
      if (resp.statusCode == 200) {
        return ConnectionTestResult(success: true, latencyMs: sw.elapsedMilliseconds);
      }
      return ConnectionTestResult(
        success: false,
        errorCode: '${resp.statusCode}',
        errorMessage: resp.body,
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

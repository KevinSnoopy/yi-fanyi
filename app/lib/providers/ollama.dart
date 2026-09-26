import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'provider.dart';

/// Ollama 本地模型 Provider —— `/api/chat` NDJSON 流式（ADR-007：流式 + HTTP）。
///
/// 无鉴权；连接拒绝 → [LfErrorCode.networkUnreachable]。
class OllamaProvider implements TranslationProvider {
  OllamaProvider({
    required this.model,
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = (baseUrl == null || baseUrl.isEmpty)
            ? kDefaultBaseUrl
            : baseUrl.replaceAll(RegExp(r'/+$'), ''),
        _client = client ?? http.Client();

  @override
  final String name = 'Ollama（本地）';
  static const String kDefaultBaseUrl = 'http://localhost:11434';

  @override
  final String defaultBaseUrl = kDefaultBaseUrl;
  final String baseUrl;
  final String model;
  final http.Client _client;

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
        'You are a professional translator. Translate from ${req.sourceLang} to '
            '${req.targetLang}. Output ONLY the translation.'
        '${req.glossaryJson != null ? '\nGlossary:\n${req.glossaryJson}' : ''}';
    return _streamChat(system, req.text, cancelToken);
  }

  @override
  Stream<String> draft(DraftRequest req, {CancelToken? cancelToken}) {
    final system = req.systemPrompt ??
        '把用户的口语转写润色为书面文稿：去掉口头禅、补全标点、梳理逻辑，只输出润色结果。';
    return _streamChat(system, req.transcript, cancelToken);
  }

  Stream<String> _streamChat(String system, String user, CancelToken? cancelToken) async* {
    cancelToken?.throwIfCancelled();
    final req = http.Request(
      'POST',
      Uri.parse('$baseUrl/api/chat'),
    )..headers['Content-Type'] = 'application/json'..body = jsonEncode(_payload(system, user));

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

    // NDJSON：每行一个 JSON 对象，message.content 为增量，done=true 结束
    final chain = resp.stream.transform(utf8.decoder).transform(const LineSplitter());
    await for (final line in chain) {
      cancelToken?.throwIfCancelled();
      if (line.trim().isEmpty) continue;
      try {
        final json = jsonDecode(line) as Map<String, Object?>;
        final message = json['message'] as Map<String, Object?>?;
        final content = message?['content'] as String?;
        if (content != null && content.isNotEmpty) yield content;
        if (json['done'] == true) break;
      } on FormatException {
        continue;
      }
    }
  }

  @override
  Future<List<String>> listModels() async {
    final resp = await _client.get(Uri.parse('$baseUrl/api/tags'));
    if (resp.statusCode != 200) throw mapHttpError(resp.statusCode, resp.body);
    final json = jsonDecode(resp.body) as Map<String, Object?>;
    final models = json['models'] as List<Object?>? ?? const [];
    return [
      for (final m in models)
        if (m is Map<String, Object?> && m['name'] is String) m['name']! as String,
    ];
  }

  @override
  Future<ConnectionTestResult> testConnection() async {
    final sw = Stopwatch()..start();
    try {
      final resp = await _client.get(Uri.parse('$baseUrl/api/tags'));
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
        errorMessage: '无法连接本地 Ollama（$baseUrl）——请确认已启动。$e',
        latencyMs: sw.elapsedMilliseconds,
      );
    }
  }

  @override
  void dispose() => _client.close();
}

import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'provider.dart';

/// Google Gemini Provider —— streamGenerateContent SSE 协议。
///
/// 鉴权：`x-goog-api-key` 头；增量位于
/// `candidates[0].content.parts[0].text`。
class GeminiProvider implements TranslationProvider {
  GeminiProvider({
    required this.apiKey,
    required this.model,
    String? baseUrl,
    http.Client? client,
  })  : baseUrl = (baseUrl == null || baseUrl.isEmpty)
            ? kDefaultBaseUrl
            : baseUrl.replaceAll(RegExp(r'/+$'), ''),
        _client = client ?? http.Client();

  @override
  final String name = 'Gemini';
  static const String kDefaultBaseUrl = 'https://generativelanguage.googleapis.com/v1beta';

  @override
  final String defaultBaseUrl = kDefaultBaseUrl;
  final String baseUrl;
  final String apiKey;
  final String model;
  final http.Client _client;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'x-goog-api-key': apiKey,
      };

  Map<String, Object?> _payload(String system, String user) => {
        'system_instruction': {'parts': [{'text': system}]},
        'contents': [
          {'role': 'user', 'parts': [{'text': user}]},
        ],
        'generationConfig': {'maxOutputTokens': 2048},
      };

  Uri _streamUri() => Uri.parse('$baseUrl/models/$model:streamGenerateContent?alt=sse');

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
    final system = req.systemPrompt ?? '把口语转写润色为书面文稿，只输出润色结果。';
    return _streamChat(system, req.transcript, cancelToken);
  }

  Stream<String> _streamChat(String system, String user, CancelToken? cancelToken) async* {
    cancelToken?.throwIfCancelled();
    final req = http.Request('POST', _streamUri())
      ..headers.addAll(_headers)
      ..body = jsonEncode(_payload(system, user));

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
      try {
        final json = jsonDecode(data) as Map<String, Object?>;
        final candidates = json['candidates'] as List<Object?>?;
        if (candidates == null || candidates.isEmpty) continue;
        final content =
            (candidates[0] as Map<String, Object?>)['content'] as Map<String, Object?>?;
        final parts = content?['parts'] as List<Object?>?;
        if (parts == null) continue;
        for (final p in parts) {
          final text = (p as Map<String, Object?>)['text'] as String?;
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
    final models = json['models'] as List<Object?>? ?? const [];
    return [
      for (final m in models)
        if (m is Map<String, Object?>)
          (m['name'] as String).replaceAll('models/', ''),
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

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// T-021 端到端验证用 · OpenAI 兼容 + Anthropic 协议的本地假服务端。
///
/// 目的：在没有真实 Key 的 CI/沙箱里，让 [OpenAICompatibleProvider] /
/// [AnthropicProvider] 走**真实的 HTTP + SSE 流式**链路（不是 MockProvider），
/// 从而验证：鉴权头、SSE 解析、增量拼接、CancelToken 中断、错误码映射。
///
/// 端口取 0（系统分配空闲端口），避免固定端口冲突。
class MockProviderServer {
  MockProviderServer._(this._server);

  final HttpServer _server;

  int get port => _server.port;

  String get baseUrl => 'http://127.0.0.1:$port/v1';

  /// 合法 Key（其它 Key 一律 401）。
  static const String validKey = 'sk-linguaflow-test';

  /// 限流演示 Key（429）。
  static const String rateLimitedKey = 'sk-linguaflow-429';

  static const String modelId = 'lf-mock-draft';

  static Future<MockProviderServer> start() async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final s = MockProviderServer._(server);
    server.listen(s._handle);
    return s;
  }

  Future<void> close() => _server.close(force: true);

  void _addCors(HttpResponse res) {
    res.headers.add('Access-Control-Allow-Origin', '*');
    res.headers.add('Access-Control-Allow-Headers', 'authorization,content-type');
    res.headers.add('Access-Control-Allow-Methods', 'GET,POST,OPTIONS');
  }

  String? _auth(HttpRequest req) {
    final h = req.headers.value('authorization');
    if (h != null && h.startsWith('Bearer ')) return h.substring(7);
    return req.headers.value('x-api-key'); // Anthropic 头
  }

  Future<void> _handle(HttpRequest req) async {
    final res = req.response;
    _addCors(res);
    if (req.method == 'OPTIONS') {
      res.statusCode = 204;
      await res.close();
      return;
    }

    final key = _auth(req);
    if (key == rateLimitedKey) {
      res.statusCode = 429;
      res.headers.contentType = ContentType.json;
      res.write(jsonEncode({'error': {'message': 'rate_limit_exceeded', 'type': 'rate_limit'}}));
      await res.close();
      return;
    }
    if (key != validKey) {
      res.statusCode = 401;
      res.headers.contentType = ContentType.json;
      res.write(jsonEncode({
        'error': {'message': 'Incorrect API key provided.', 'type': 'invalid_request_error'}
      }));
      await res.close();
      return;
    }

    final path = req.uri.path;
    if (path.endsWith('/models')) {
      res.headers.contentType = ContentType.json;
      res.write(jsonEncode({
        'data': [
          {'id': modelId},
          {'id': 'lf-mock-translate'},
        ]
      }));
      await res.close();
      return;
    }

    if (path.endsWith('/chat/completions')) {
      final body = await utf8.decoder.bind(req).join();
      final payload = jsonDecode(body) as Map<String, Object?>;
      final messages = payload['messages'] as List<Object?>? ?? const [];
      final user = messages.isEmpty ? '' : ((messages.last as Map<String, Object?>)['content'] as String? ?? '');
      await _streamOpenAi(res, draftOf(user));
      return;
    }

    if (path.endsWith('/messages')) {
      final body = await utf8.decoder.bind(req).join();
      final payload = jsonDecode(body) as Map<String, Object?>;
      final messages = payload['messages'] as List<Object?>? ?? const [];
      final user = messages.isEmpty ? '' : ((messages.last as Map<String, Object?>)['content'] as String? ?? '');
      await _streamAnthropic(res, draftOf(user));
      return;
    }

    res.statusCode = 404;
    await res.close();
  }

  /// 成稿结果：把输入切成「书面语」形态（确定性，便于断言）。
  static String draftOf(String input) {
    final cleaned = input.replaceAll(RegExp(r'[呃啊嗯，,]'), '').trim();
    return '${cleaned.isEmpty ? '（空）' : cleaned}。';
  }

  Future<void> _streamOpenAi(HttpResponse res, String text) async {
    res.statusCode = 200;
    res.headers.contentType = ContentType('text', 'event-stream', charset: 'utf-8');
    final chunks = _split(text);
    for (final c in chunks) {
      res.write('data: ${jsonEncode({
        'choices': [
          {'delta': {'content': c}, 'index': 0}
        ]
      })}\n\n');
      await res.flush();
      await Future<void>.delayed(const Duration(milliseconds: 12));
    }
    res.write('data: [DONE]\n\n');
    await res.close();
  }

  Future<void> _streamAnthropic(HttpResponse res, String text) async {
    res.statusCode = 200;
    res.headers.contentType = ContentType('text', 'event-stream', charset: 'utf-8');
    res.write('event: message_start\ndata: {"type":"message_start"}\n\n');
    for (final c in _split(text)) {
      res.write('event: content_block_delta\n');
      res.write('data: ${jsonEncode({
        'type': 'content_block_delta',
        'index': 0,
        'delta': {'type': 'text_delta', 'text': c}
      })}\n\n');
      await res.flush();
      await Future<void>.delayed(const Duration(milliseconds: 12));
    }
    res.write('event: message_stop\ndata: {"type":"message_stop"}\n\n');
    await res.close();
  }

  /// 按 2 字切分（模拟 token 粒度流式）。
  static List<String> _split(String s) {
    final out = <String>[];
    for (var i = 0; i < s.length; i += 2) {
      out.add(s.substring(i, (i + 2).clamp(0, s.length)));
    }
    return out;
  }
}

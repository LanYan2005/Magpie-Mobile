import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'gateway_upstream.dart';

enum ProviderProbeFailure {
  unsupported,
  invalidModel,
  network,
  timeout,
  http,
  invalidResponse,
}

class ProviderProbeException implements Exception {
  const ProviderProbeException(this.failure, {this.statusCode});

  final ProviderProbeFailure failure;
  final int? statusCode;

  @override
  String toString() => statusCode == null
      ? 'ProviderProbeException(${failure.name})'
      : 'ProviderProbeException(${failure.name}, HTTP $statusCode)';
}

/// Requests provider metadata and a small, non-streaming text generation probe.
class ProviderModelClient {
  const ProviderModelClient();

  static const _timeout = Duration(seconds: 10);
  static const _maxListBytes = 1024 * 1024;
  static const _maxProbeBytes = 64 * 1024;
  static const _maxOutputTokens = 64;
  static const _prompt = 'Reply with OK.';
  static final _trailingSlashes = RegExp(r'/+$');
  static final _jsonModelId = RegExp(r'^[A-Za-z0-9._:@+/-]{1,256}$');
  static const _unsupported = ProviderProbeException(
    ProviderProbeFailure.unsupported,
  );
  static const _invalidResponse = ProviderProbeException(
    ProviderProbeFailure.invalidResponse,
  );

  /// Returns the first page of distinct model IDs in the provider's order.
  Future<List<String>> fetchModels(
    GatewayProtocol protocol,
    GatewayUpstream upstream,
  ) async {
    _checkUpstream(protocol, upstream);
    final endpoint = upstream.endpoint;
    final path = endpoint.path.replaceFirst(_trailingSlashes, '');
    final suffix = switch (protocol) {
      GatewayProtocol.chat => '/chat/completions',
      GatewayProtocol.responses => '/responses',
      GatewayProtocol.anthropic => '/messages',
      GatewayProtocol.gemini => '',
      GatewayProtocol.systemOne => throw _unsupported,
    };
    // Uri.path already carries percent escapes. Keep the configured prefix
    // unchanged, including encoded slashes inside a path segment.
    final target = endpoint.replace(
      path: '${path.substring(0, path.length - suffix.length)}/models',
    );
    final response = await _request(protocol, upstream, target);
    final gemini = protocol == GatewayProtocol.gemini;
    final rows = response[gemini ? 'models' : 'data'];
    if (rows is! List) throw _invalidResponse;

    final ids = <String>{};
    var hasModelEntry = false;
    for (final row in rows) {
      if (row is! Map<String, dynamic>) continue;
      final value = row[gemini ? 'name' : 'id'];
      if (value is! String) continue;
      hasModelEntry = true;
      if (_containsKey(value, upstream.apiKey)) continue;
      if (gemini && !value.startsWith('models/')) continue;
      final id = gemini ? value.substring('models/'.length) : value;
      if (gemini ? _geminiRoute(id) != null : _isJsonModelId(id)) ids.add(id);
    }
    if (rows.isNotEmpty && !hasModelEntry) throw _invalidResponse;
    return ids.toList(growable: false);
  }

  Future<void> testModel(
    GatewayProtocol protocol,
    GatewayUpstream upstream,
    String model,
  ) async {
    _checkUpstream(protocol, upstream);
    const invalidModel = ProviderProbeException(
      ProviderProbeFailure.invalidModel,
    );
    if (_containsKey(model, upstream.apiKey)) throw invalidModel;

    var target = upstream.endpoint;
    if (protocol == GatewayProtocol.gemini) {
      final id = model.startsWith('models/')
          ? model.substring('models/'.length)
          : model;
      final route = _geminiRoute(id);
      if (route == null) throw invalidModel;
      target = route.target(target);
    } else if (!_isJsonModelId(model)) {
      throw invalidModel;
    }

    final body = switch (protocol) {
      GatewayProtocol.chat => {
        'model': model,
        'messages': _messages,
        'max_completion_tokens': _maxOutputTokens,
        'stream': false,
      },
      GatewayProtocol.responses => {
        'model': model,
        'input': _prompt,
        'max_output_tokens': _maxOutputTokens,
        'stream': false,
      },
      GatewayProtocol.anthropic => {
        'model': model,
        'messages': _messages,
        'max_tokens': _maxOutputTokens,
        'stream': false,
      },
      GatewayProtocol.gemini => {
        'contents': [
          {
            'parts': [
              {'text': _prompt},
            ],
          },
        ],
        'generationConfig': {'maxOutputTokens': _maxOutputTokens},
      },
      GatewayProtocol.systemOne => throw _unsupported,
    };
    final response = await _request(protocol, upstream, target, body: body);
    final generated = switch (protocol) {
      GatewayProtocol.chat => _objects(
        response['choices'],
      ).any((choice) => _hasText(_field(choice['message'], 'content'))),
      GatewayProtocol.responses =>
        (response['status'] == null ||
                response['status'] == 'completed' ||
                response['status'] == 'incomplete') &&
            _objects(response['output']).any(
              (item) =>
                  item['type'] == 'message' &&
                  _hasTextBlock(item['content'], 'output_text'),
            ),
      GatewayProtocol.anthropic => _hasTextBlock(response['content'], 'text'),
      GatewayProtocol.gemini => _objects(response['candidates']).any(
        (candidate) => _objects(
          _field(candidate['content'], 'parts'),
        ).any((part) => part['thought'] != true && _hasText(part['text'])),
      ),
      GatewayProtocol.systemOne => throw _unsupported,
    };
    if (!generated) throw _invalidResponse;
  }

  static const _messages = [
    {'role': 'user', 'content': _prompt},
  ];

  static bool _containsKey(String value, String key) =>
      key.isNotEmpty && value.contains(key);

  static bool _isJsonModelId(String id) => _jsonModelId.hasMatch(id);

  static GatewayRoute? _geminiRoute(String id) => GatewayRoute.match(
    '${GatewayProtocol.gemini.inboundPath}$id:generateContent',
  );

  static bool _hasText(Object? value) =>
      value is String && value.trim().isNotEmpty;

  static bool _hasTextBlock(Object? value, String type) => _objects(
    value,
  ).any((block) => block['type'] == type && _hasText(block['text']));

  static Object? _field(Object? object, String key) =>
      object is Map<String, dynamic> ? object[key] : null;

  static Iterable<Map<String, dynamic>> _objects(Object? value) => value is List
      ? value.whereType<Map<String, dynamic>>()
      : const <Map<String, dynamic>>[];

  static void _checkUpstream(
    GatewayProtocol protocol,
    GatewayUpstream upstream,
  ) {
    if (protocol == GatewayProtocol.systemOne ||
        !upstream.ready ||
        GatewayUpstream.parseEndpoint(upstream.endpoint.toString()) == null ||
        !protocol.acceptsEndpoint(upstream.endpoint)) {
      throw _unsupported;
    }
  }

  static Future<Map<String, dynamic>> _request(
    GatewayProtocol protocol,
    GatewayUpstream upstream,
    Uri target, {
    Map<String, Object>? body,
  }) async {
    // The computed URL can contain a key even when the saved endpoint does not.
    final key = upstream.apiKey;
    if (GatewayUpstream.parse(
          target.toString(),
          key,
          requiresKey: upstream.requiresKey,
        ) ==
        null) {
      throw _unsupported;
    }

    final client = HttpClient()
      ..autoUncompress = false
      ..findProxy = (_) => 'DIRECT';
    try {
      // One deadline covers the entire exchange, including a slow body stream.
      return await _exchange(
        client,
        protocol,
        target,
        key,
        body,
      ).timeout(_timeout);
    } on TimeoutException {
      throw const ProviderProbeException(ProviderProbeFailure.timeout);
    } on FormatException {
      throw _invalidResponse;
    } on ProviderProbeException {
      rethrow;
    } on Exception {
      throw const ProviderProbeException(ProviderProbeFailure.network);
    } finally {
      client.close(force: true);
    }
  }

  static Future<Map<String, dynamic>> _exchange(
    HttpClient client,
    GatewayProtocol protocol,
    Uri target,
    String key,
    Map<String, Object>? body,
  ) async {
    final request = await client.openUrl(body == null ? 'GET' : 'POST', target);
    request
      ..followRedirects = false
      ..persistentConnection = false;
    request.headers
      ..set(HttpHeaders.acceptHeader, 'application/json')
      ..set(HttpHeaders.acceptEncodingHeader, 'identity');
    if (protocol == GatewayProtocol.anthropic) {
      request.headers.set('anthropic-version', '2023-06-01');
    }
    if (key.isNotEmpty) {
      final (header, value) = switch (protocol) {
        GatewayProtocol.anthropic => ('x-api-key', key),
        GatewayProtocol.gemini => ('x-goog-api-key', key),
        _ => (HttpHeaders.authorizationHeader, 'Bearer $key'),
      };
      request.headers.set(header, value);
    }
    if (body != null) {
      final bytes = utf8.encode(jsonEncode(body));
      request.headers.contentType = ContentType.json;
      request.contentLength = bytes.length;
      request.add(bytes);
    }

    final response = await request.close();
    final status = response.statusCode;
    if (status < 200 || status >= 300) {
      throw ProviderProbeException(
        ProviderProbeFailure.http,
        statusCode: status,
      );
    }
    final mime = response.headers.contentType?.mimeType;
    final encodings = response.headers[HttpHeaders.contentEncodingHeader];
    final limit = body == null ? _maxListBytes : _maxProbeBytes;
    if (mime == null ||
        (mime != 'application/json' && !mime.endsWith('+json')) ||
        (encodings != null &&
            (encodings.length != 1 ||
                encodings.single.toLowerCase() != 'identity')) ||
        response.contentLength > limit) {
      throw _invalidResponse;
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in response) {
      if (chunk.length > limit - bytes.length) throw _invalidResponse;
      bytes.add(chunk);
    }
    final decoded = jsonDecode(utf8.decode(bytes.takeBytes()));
    if (decoded is! Map<String, dynamic> || decoded['error'] != null) {
      throw _invalidResponse;
    }
    return decoded;
  }
}

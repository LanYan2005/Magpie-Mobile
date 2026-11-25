import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'gateway_upstream.dart';

/// One manually started listener, with immutable routes and a session token.
class LoopbackGateway {
  LoopbackGateway._(this._server, this._routes, this.token);

  static const maxBodyBytes = 2 * 1024 * 1024;
  static const _maxInFlight = 8;
  static const _ioTimeout = Duration(seconds: 60);
  static const _bodyTimeout = Duration(seconds: 15);
  static final _anthropicVersion = RegExp(r'^\d{4}-\d{2}-\d{2}$');
  static final _anthropicBeta = RegExp(
    r'^[a-z0-9-]+(?: *, *[a-z0-9-]+)*$',
  );

  final HttpServer _server;
  final Map<GatewayProtocol, GatewayUpstream> _routes;
  static const _authHeaders = [
    HttpHeaders.authorizationHeader,
    'x-api-key',
    'x-goog-api-key',
  ];
  final String token;
  final _clients = <HttpClient>{};
  final _ended = Completer<void>();
  int _inFlight = 0;
  Future<void>? _closing;

  Future<void> get ended => _ended.future;
  int get port => _server.port;

  static Future<LoopbackGateway> start(
    Map<GatewayProtocol, GatewayUpstream> routes, {
    int port = GatewayUpstream.port,
  }) async {
    final snapshot = Map<GatewayProtocol, GatewayUpstream>.unmodifiable(routes);
    final random = Random.secure();
    String token;
    do {
      token = List.generate(
        32,
        (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
      ).join();
    } while (snapshot.values.any((route) => route.apiKey == token));
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    server.idleTimeout = const Duration(seconds: 15);
    final gateway = LoopbackGateway._(server, snapshot, token);
    server.listen(
      (request) => unawaited(gateway._serve(request)),
      onError: (Object _, StackTrace _) => unawaited(gateway.stop()),
      onDone: () => unawaited(gateway.stop()),
    );
    return gateway;
  }

  Future<void> stop() => _closing ??= _close();

  Future<void> _close() async {
    for (final client in _clients) {
      client.close(force: true);
    }
    _clients.clear();
    try {
      await _server.close(force: true);
    } finally {
      _ended.complete();
    }
  }

  bool _authorized(
    HttpRequest request, {
    required bool protocolRoute,
    required String? queryToken,
  }) {
    final candidates = <String>[];
    for (final name in _authHeaders) {
      final values = request.headers[name];
      if (values == null) continue;
      if (!protocolRoute && name != HttpHeaders.authorizationHeader) {
        return false;
      }
      for (var value in values) {
        if (name == HttpHeaders.authorizationHeader) {
          const prefix = 'bearer ';
          if (value.toLowerCase().startsWith(prefix)) {
            value = value.substring(prefix.length);
          } else if (!protocolRoute) {
            return false;
          }
        }
        if (value.isNotEmpty) candidates.add(value);
      }
    }
    if (queryToken != null) candidates.add(queryToken);
    var authorized = false;
    for (final value in candidates) {
      if (value.length != token.length) continue;
      var difference = 0;
      for (var i = 0; i < token.length; i++) {
        difference |= value.codeUnitAt(i) ^ token.codeUnitAt(i);
      }
      authorized = difference == 0 || authorized;
    }
    return authorized;
  }

  Future<void> _serve(HttpRequest request) async {
    final response = request.response;
    HttpClient? client;
    var disconnected = false;
    var forwarding = false;
    var counted = false;
    unawaited(
      response.done.then<void>(
        (_) {},
        onError: (Object _) {
          disconnected = true;
          client?.close(force: true);
        },
      ),
    );
    try {
      response.persistentConnection = false;
      response.headers
        ..set(HttpHeaders.cacheControlHeader, 'no-store')
        ..set('x-content-type-options', 'nosniff');
      final hosts = request.headers[HttpHeaders.hostHeader];
      final uri = request.uri;
      final route = GatewayRoute.match(uri.path);
      final query = uri.queryParametersAll;
      final geminiKeys = route?.protocol == GatewayProtocol.gemini
          ? query['key']
          : null;
      if (hosts == null ||
          hosts.length != 1 ||
          hosts.single != '${GatewayUpstream.host}:$port' ||
          request.headers['origin'] != null ||
          uri.hasAuthority ||
          uri.hasScheme ||
          uri.hasFragment ||
          (uri.hasQuery && !(route?.acceptsQuery(query) ?? false))) {
        return _error(response, 400, 'Invalid gateway request');
      }
      if (!_authorized(
        request,
        protocolRoute: route != null,
        queryToken: geminiKeys != null && geminiKeys.length == 1
            ? geminiKeys.single
            : null,
      )) {
        response.headers.set(HttpHeaders.wwwAuthenticateHeader, 'Bearer');
        return _error(response, 401, 'A valid local gateway token is required');
      }
      final health = uri.path == '/health';
      if (!health && route == null) {
        return _error(response, 404, 'Unknown route');
      }
      final method = health ? 'GET' : 'POST';
      if (request.method != method) {
        response.headers.set(HttpHeaders.allowHeader, method);
        return _error(response, 405, 'Method not allowed');
      }
      if (route == null) {
        response.headers.contentType = ContentType.json;
        response.write('{"status":"ok"}');
        return;
      }
      final upstream = _routes[route.protocol];
      if (upstream == null) {
        return _error(
          response,
          503,
          'No upstream configured for ${route.protocol.label}',
        );
      }
      if (!upstream.ready) {
        return _error(
          response,
          503,
          'Upstream API key missing for ${route.protocol.label}',
        );
      }
      final target = route.target(upstream.endpoint);
      if (target.host == GatewayUpstream.host && target.port == port) {
        return _error(response, 503, 'Upstream points to this listener');
      }
      if (request.contentLength > maxBodyBytes) {
        await _rejectOversized(response);
        return;
      }
      if (request.headers.contentType?.mimeType != 'application/json' ||
          request.headers[HttpHeaders.contentEncodingHeader] != null) {
        return _error(response, 415, 'Expected an uncompressed JSON body');
      }
      if (_inFlight >= _maxInFlight) {
        return _error(response, 429, 'Too many active gateway requests');
      }
      _inFlight++;
      counted = true;
      final body = await _readBody(request);
      if (body == null) {
        await _rejectOversized(response);
        return;
      }
      if (jsonDecode(utf8.decode(body)) is! Map<String, dynamic>) {
        return _error(response, 400, 'Expected a JSON object');
      }
      String? anthropicVersion;
      String? anthropicBeta;
      if (route.protocol == GatewayProtocol.anthropic) {
        final version = request.headers['anthropic-version'];
        if (version != null &&
            (version.length != 1 ||
                !_anthropicVersion.hasMatch(version.single))) {
          return _error(response, 400, 'Invalid anthropic-version');
        }
        final beta = request.headers['anthropic-beta'];
        if (beta != null &&
            (beta.length != 1 || !_anthropicBeta.hasMatch(beta.single))) {
          return _error(response, 400, 'Invalid anthropic-beta');
        }
        anthropicVersion = version?.single ?? '2023-06-01';
        anthropicBeta = beta?.single;
      }
      if (disconnected || _closing != null) return;
      final upstreamClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 10)
        ..findProxy = (_) => 'DIRECT';
      client = upstreamClient;
      _clients.add(upstreamClient);
      final outgoing = await upstreamClient.postUrl(target);
      outgoing.followRedirects = false;
      outgoing.headers
        ..contentType = ContentType.json
        ..set(HttpHeaders.acceptHeader, 'application/json, text/event-stream')
        ..set(HttpHeaders.acceptEncodingHeader, 'identity');
      if (anthropicVersion != null) {
        outgoing.headers.set('anthropic-version', anthropicVersion);
      }
      if (anthropicBeta != null) {
        outgoing.headers.set('anthropic-beta', anthropicBeta);
      }
      if (upstream.apiKey.isNotEmpty) {
        final (header, value) = switch (route.protocol) {
          GatewayProtocol.anthropic => ('x-api-key', upstream.apiKey),
          GatewayProtocol.gemini => ('x-goog-api-key', upstream.apiKey),
          _ => (HttpHeaders.authorizationHeader, 'Bearer ${upstream.apiKey}'),
        };
        outgoing.headers.set(header, value);
      }
      outgoing.contentLength = body.length;
      outgoing.add(body);
      final incoming = await outgoing.close().timeout(_ioTimeout);
      final status = incoming.statusCode;
      if (status >= 300 && status < 400) {
        return _error(response, 502, 'Upstream redirects are disabled');
      }
      if (status < 200 || status >= 300) {
        return _error(
          response,
          status >= 400 && status <= 599 ? status : 502,
          'Upstream request failed',
        );
      }
      final mime = incoming.headers.contentType?.mimeType;
      if (mime != 'application/json' && mime != 'text/event-stream') {
        return _error(response, 502, 'Unexpected upstream response format');
      }
      response.statusCode = status;
      response.headers
        ..contentType = ContentType.parse('$mime; charset=utf-8')
        ..set(HttpHeaders.cacheControlHeader, 'no-store')
        ..set('x-content-type-options', 'nosniff');
      response.bufferOutput = false;
      forwarding = true;
      final stream = incoming.timeout(_ioTimeout);
      await response.addStream(
        upstream.apiKey.isEmpty ? stream : _redact(stream, upstream.apiKey),
      );
    } on FormatException {
      if (!forwarding) _error(response, 400, 'Invalid request data');
    } on _BodyTimeout {
      _error(response, 408, 'Timed out reading request body');
    } on TimeoutException {
      if (!forwarding) _error(response, 504, 'Upstream timed out');
    } on Exception {
      if (!forwarding && !disconnected && _closing == null) {
        _error(response, 502, 'Upstream connection failed');
      }
    } finally {
      if (counted) _inFlight--;
      if (client != null) {
        _clients.remove(client);
        client.close(force: true);
      }
      try {
        await response.close();
      } on Exception {
        // Expected when the client disconnects or the gateway stops mid-stream.
      }
    }
  }

  static Future<void> _rejectOversized(HttpResponse response) async {
    response
      ..statusCode = 413
      ..headers.contentType = ContentType.json
      ..headers.contentLength = 0;
    // The request may still be streaming. Detaching prevents close() from waiting
    // for unread input; the empty 413 response is written before closing the socket.
    final socket = await response.detachSocket();
    await socket.flush();
    await socket.close();
  }

  static Future<Uint8List?> _readBody(HttpRequest request) async {
    final body = BytesBuilder(copy: false);
    final deadline = Stopwatch()..start();
    final chunks = StreamIterator(request);
    try {
      while (await chunks.moveNext().timeout(_bodyTimeout - deadline.elapsed)) {
        final chunk = chunks.current;
        if (body.length + chunk.length > maxBodyBytes) return null;
        body.add(chunk);
      }
      return body.takeBytes();
    } on TimeoutException {
      throw const _BodyTimeout();
    } finally {
      await chunks.cancel();
    }
  }

  // HTTP header values are never copied. Also remove literal key echoes from
  // successful response bodies, even if a key spans multiple network chunks.
  // Retain only a partial matching suffix so ordinary SSE events flush promptly.
  static Stream<List<int>> _redact(
    Stream<List<int>> stream,
    String key,
  ) async* {
    var pending = '';
    await for (final chunk in stream) {
      final text = pending + latin1.decode(chunk);
      final out = StringBuffer();
      var offset = 0;
      for (
        var match = text.indexOf(key);
        match != -1;
        match = text.indexOf(key, offset)
      ) {
        out
          ..write(text.substring(offset, match))
          ..write('[redacted]');
        offset = match + key.length;
      }
      var end = text.length;
      for (var n = min(key.length - 1, end - offset); n > 0; n--) {
        if (text.startsWith(key.substring(0, n), end - n)) {
          end -= n;
          break;
        }
      }
      out.write(text.substring(offset, end));
      pending = text.substring(end);
      if (out.isNotEmpty) yield latin1.encode(out.toString());
    }
    if (pending.isNotEmpty) yield latin1.encode(pending);
  }

  static void _error(HttpResponse response, int status, String message) {
    response.statusCode = status;
    response.headers.contentType = ContentType.json;
    response.write(
      jsonEncode({
        'error': {'message': message},
      }),
    );
  }
}

class _BodyTimeout implements Exception {
  const _BodyTimeout();
}

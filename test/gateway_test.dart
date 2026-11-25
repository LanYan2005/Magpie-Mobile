import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:magpie_mobile/gateway/gateway_controller.dart';
import 'package:magpie_mobile/gateway/gateway_presets.dart';
import 'package:magpie_mobile/gateway/gateway_settings.dart';
import 'package:magpie_mobile/gateway/gateway_upstream.dart';
import 'package:magpie_mobile/gateway/loopback_gateway.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _host = GatewayUpstream.host;
const _chat = '/v1/chat/completions';
const _key = 'fixture-key-024';

void main() {
  late HttpServer upstream;
  late HttpClient client;
  late int port;

  setUp(() async {
    upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => upstream.close(force: true));
    client = HttpClient()..findProxy = (_) => 'DIRECT';
    addTearDown(() => client.close(force: true));
  });

  String upstreamUrl([String path = '/test/v1/chat/completions']) =>
      'http://127.0.0.1:${upstream.port}$path';

  Future<LoopbackGateway> start([
    Map<GatewayProtocol, GatewayUpstream>? routes,
  ]) async {
    final gateway = await LoopbackGateway.start(
      routes ??
          {GatewayProtocol.chat: GatewayUpstream.parse(upstreamUrl(), _key)!},
      port: 0,
    );
    port = gateway.port;
    addTearDown(gateway.stop);
    return gateway;
  }

  Future<HttpClientResponse> send(
    String path, {
    String method = 'GET',
    String? token,
    String? body,
    Map<String, String> headers = const {},
  }) async {
    final request = await client.openUrl(
      method,
      Uri.parse('http://$_host:$port$path'),
    );
    request.followRedirects = false;
    if (token != null) request.headers.set('authorization', 'Bearer $token');
    headers.forEach(request.headers.set);
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(body);
    }
    return request.close();
  }

  Future<String> read(HttpClientResponse response) =>
      utf8.decoder.bind(response).join();

  Future<HttpClientResponse> sendLocal(
    LoopbackGateway gateway,
    String path, {
    Map<String, String> headers = const {},
    String body = '{}',
  }) async {
    final request = await client.postUrl(
      Uri.parse('http://$_host:${gateway.port}$path'),
    );
    request.headers.set(HttpHeaders.contentTypeHeader, 'application/json');
    if (!request.uri.queryParameters.containsKey('key') &&
        !headers.keys.any(
          (name) => const {
            HttpHeaders.authorizationHeader,
            'x-api-key',
            'x-goog-api-key',
          }.contains(name),
        )) {
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${gateway.token}',
      );
    }
    headers.forEach(request.headers.set);
    request.write(body);
    return request.close();
  }

  test(
    'requires a session bearer token and checks local request metadata',
    () async {
      var upstreamHits = 0;
      upstream.listen((request) async {
        upstreamHits++;
        await request.drain<void>();
        request.response
          ..headers.contentType = ContentType.json
          ..write('{}');
        await request.response.close();
      });
      final gateway = await start();
      expect(gateway.token, matches(RegExp(r'^[0-9a-f]{64}$')));
      expect((await send('/health')).statusCode, 401);
      expect(
        (await send(
          _chat,
          method: 'POST',
          token: 'wrong',
          body: '{}',
        )).statusCode,
        401,
      );
      final response = await send('/health', token: gateway.token);
      expect(response.statusCode, 200);
      expect(jsonDecode(await read(response)), {'status': 'ok'});
      final alternateHeader = await send(
        _chat,
        method: 'POST',
        headers: {'x-api-key': gateway.token},
        body: '{}',
      );
      expect(alternateHeader.statusCode, 200);
      expect(upstreamHits, 1); // accepted client token reached the fixture
      final staleAndValid = await send(
        _chat,
        method: 'POST',
        token: 'stale-placeholder',
        headers: {'x-api-key': gateway.token},
        body: '{}',
      );
      expect(staleAndValid.statusCode, 200);
      expect(upstreamHits, 2); // any matching auth candidate is sufficient
      expect(
        (await send(
          '/health',
          token: gateway.token,
          headers: {'host': 'localhost:3425'},
        )).statusCode,
        400,
      );
      expect(
        (await send(
          '/health',
          token: gateway.token,
          headers: {'origin': 'https://example.invalid'},
        )).statusCode,
        400,
      );
      expect(
        (await send(
          '$_chat?base_url=http://127.0.0.1:1',
          token: gateway.token,
        )).statusCode,
        400,
      );
      expect((await send('/other', token: gateway.token)).statusCode, 404);
      final wrongMethod = await send(_chat, token: gateway.token);
      expect(wrongMethod.statusCode, 405);
      expect(wrongMethod.headers.value('allow'), 'POST');
    },
  );

  test(
    'routes all five protocols to isolated, same-protocol upstreams',
    () async {
      final seen = <(String, String?, String?, String?, String)>[];
      upstream.listen((request) async {
        final body = await utf8.decoder.bind(request).join();
        seen.add((
          request.uri.path,
          request.headers.value('authorization'),
          request.headers.value('x-api-key'),
          request.headers.value('x-goog-api-key'),
          body,
        ));
        request.response
          ..headers.contentType = ContentType.json
          ..write('{"ok":true}');
        await request.response.close();
      });
      final routes = <GatewayProtocol, GatewayUpstream>{
        GatewayProtocol.chat: GatewayUpstream.parse(
          upstreamUrl('/test/chat'),
          'chat-secret',
        )!,
        GatewayProtocol.responses: GatewayUpstream.parse(
          upstreamUrl('/test/responses'),
          'response-secret',
        )!,
        GatewayProtocol.anthropic: GatewayUpstream.parse(
          upstreamUrl('/test/anthropic/messages'),
          'anthropic-secret',
        )!,
        GatewayProtocol.gemini: GatewayUpstream.parse(
          'http://127.0.0.1:${upstream.port}/test/gemini/v1beta',
          'gemini-secret',
        )!,
        GatewayProtocol.systemOne: GatewayUpstream.parse(
          upstreamUrl('/test/decide/systemone'),
          'decide-secret',
        )!,
      };
      final gateway = await start(routes);
      final token = gateway.token;
      final cases = <(String, Map<String, String>, String)>[
        (
          '/v1/chat/completions',
          {HttpHeaders.authorizationHeader: 'Bearer $token'},
          'chat-secret',
        ),
        ('/v1/responses', {'x-api-key': token}, 'response-secret'),
        (
          '/v1/messages',
          {HttpHeaders.authorizationHeader: token},
          'anthropic-secret',
        ),
        (
          '/v1beta/models/gemini-2.5-flash:generateContent?key=$token',
          {},
          'gemini-secret',
        ),
        (
          '/v1beta/models/gemini-2.5-flash:streamGenerateContent?alt=sse&key=$token',
          {},
          'gemini-secret',
        ),
        (
          '/v1beta/models/gemini-2.5-flash:countTokens?key=$token',
          {},
          'gemini-secret',
        ),
        (
          '/v1beta/models/gemini-2.5-flash:embedContent?key=$token',
          {},
          'gemini-secret',
        ),
        (
          '/v1beta/models/gemini-2.5-flash:batchEmbedContents?key=$token',
          {},
          'gemini-secret',
        ),
        ('/v1/messages/count_tokens', {'x-api-key': token}, 'anthropic-secret'),
        (
          '/v1/systemone',
          {HttpHeaders.authorizationHeader: 'Bearer $token'},
          'decide-secret',
        ),
      ];
      final paths = <String>[
        '/test/chat',
        '/test/responses',
        '/test/anthropic/messages',
        '/test/gemini/v1beta/models/gemini-2.5-flash:generateContent',
        '/test/gemini/v1beta/models/gemini-2.5-flash:streamGenerateContent',
        '/test/gemini/v1beta/models/gemini-2.5-flash:countTokens',
        '/test/gemini/v1beta/models/gemini-2.5-flash:embedContent',
        '/test/gemini/v1beta/models/gemini-2.5-flash:batchEmbedContents',
        '/test/anthropic/messages/count_tokens',
        '/test/decide/systemone',
      ];
      for (var i = 0; i < cases.length; i++) {
        final (path, headers, _) = cases[i];
        final response = await sendLocal(
          gateway,
          path,
          headers: headers,
          body: '{"model":"fixture","messages":[]}',
        );
        expect(response.statusCode, 200, reason: path);
      }
      expect(seen.map((row) => row.$1), paths);
      expect(seen.map((row) => row.$2), [
        'Bearer chat-secret',
        'Bearer response-secret',
        null,
        null,
        null,
        null,
        null,
        null,
        null,
        'Bearer decide-secret',
      ]);
      expect(seen.map((row) => row.$3), [
        null,
        null,
        'anthropic-secret',
        null,
        null,
        null,
        null,
        null,
        'anthropic-secret',
        null,
      ]);
      expect(seen.map((row) => row.$4), [
        null,
        null,
        null,
        'gemini-secret',
        'gemini-secret',
        'gemini-secret',
        'gemini-secret',
        'gemini-secret',
        null,
        null,
      ]);
      expect(
        seen.map((row) => row.$5),
        everyElement('{"model":"fixture","messages":[]}'),
      );
      expect(cases.map((row) => row.$3).toSet(), {
        'chat-secret',
        'response-secret',
        'anthropic-secret',
        'gemini-secret',
        'decide-secret',
      });
    },
  );

  test('Gemini SSE path emits alt=sse without leaking client key', () async {
    final seen = Completer<(String, String?, String?)>();
    upstream.listen((request) async {
      seen.complete((
        request.uri.toString(),
        request.headers.value('x-goog-api-key'),
        request.headers.value('authorization'),
      ));
      await request.drain<void>();
      request.response
        ..headers.contentType = ContentType('text', 'event-stream')
        ..write('data: {"ok":true}\n\n');
      await request.response.close();
    });
    final gateway = await start({
      GatewayProtocol.gemini: GatewayUpstream.parse(
        'http://127.0.0.1:${upstream.port}/v1beta',
        'provider-gemini',
      )!,
    });
    final response = await sendLocal(
      gateway,
      '/v1beta/models/gemini-2.5-flash:streamGenerateContent?alt=sse&key=${gateway.token}',
    );
    expect(response.statusCode, 200);
    expect(await read(response), contains('data:'));
    expect(await seen.future, (
      '/v1beta/models/gemini-2.5-flash:streamGenerateContent?alt=sse',
      'provider-gemini',
      null,
    ));
  });

  test(
    'rejects unsupported auth and reports missing route, key, or preset accurately',
    () async {
      final gateway = await start({
        GatewayProtocol.chat: GatewayUpstream.parse(
          upstreamUrl(),
          'chat-provider-key',
        )!,
        GatewayProtocol.responses: GatewayUpstream.parse(
          upstreamUrl('/responses'),
          '',
          requiresKey: false,
        )!,
        GatewayProtocol.anthropic: GatewayUpstream.parse(
          upstreamUrl('/messages'),
          '',
        )!,
        GatewayProtocol.gemini: GatewayUpstream.parse(
          'http://127.0.0.1:${upstream.port}/v1beta',
          'gemini-provider-key',
        )!,
        GatewayProtocol.systemOne: GatewayUpstream.parse(
          upstreamUrl('/systemone'),
          'decide-provider-key',
        )!,
      });
      final healthWithApiKey = await send(
        '/health',
        token: null,
        headers: {'x-api-key': gateway.token},
      );
      expect(healthWithApiKey.statusCode, 401);
      final invalidQuery = await sendLocal(
        gateway,
        '/v1/chat/completions?key=${gateway.token}',
      );
      expect(invalidQuery.statusCode, 400);
      final missingRoute = await sendLocal(gateway, '/v1/messages');
      expect(missingRoute.statusCode, 503);
      expect(await read(missingRoute), contains('API key missing'));
      expect(
        GatewayPreset.official.where(
          (item) => item.protocol == GatewayProtocol.systemOne,
        ),
        isEmpty,
      );
      expect(
        GatewayPreset.official.any((item) => item.provider == 'Qwen'),
        isFalse,
      );
    },
  );

  test(
    'forwards JSON to the saved path with only gateway-owned upstream headers',
    () async {
      final seen = Completer<(String, String?, String?, String?, String)>();
      upstream.listen((request) async {
        seen.complete((
          request.uri.path,
          request.headers.value('authorization'),
          request.headers.value('cookie'),
          request.headers.value('x-upstream-url'),
          await utf8.decoder.bind(request).join(),
        ));
        request.response.headers
          ..contentType = ContentType.json
          ..set('set-cookie', 'upstream=$_key')
          ..set('x-secret', _key);
        request.response.write(
          '{"choices":[{"message":{"content":"你好 $_key"}}]}',
        );
        await request.response.close();
      });
      final gateway = await start();
      const body = '{"model":"fixture","messages":[]}';
      final response = await send(
        _chat,
        method: 'POST',
        token: gateway.token,
        body: body,
        headers: {
          'cookie': 'local=fixture',
          'x-upstream-url': 'http://127.0.0.1:1',
        },
      );
      expect(response.statusCode, 200);
      expect(await seen.future, (
        '/test/v1/chat/completions',
        'Bearer $_key',
        null,
        null,
        body,
      ));
      expect(response.headers['set-cookie'], isNull);
      expect(response.headers['x-secret'], isNull);
      expect(await read(response), contains('你好 [redacted]'));
    },
  );

  test(
    'preserves fast and reasoning options, streams reasoning, and redacts keys',
    () async {
      const body =
          '{"model":"fixture","stream":true,'
          '"service_tier":"priority","reasoning_effort":"high"}';
      const firstEvent =
          'data: {"choices":[{"delta":{"reasoning_content":"fixture"}}]}';
      final received = Completer<String>();
      final releaseTail = Completer<void>();
      addTearDown(() {
        if (!releaseTail.isCompleted) releaseTail.complete();
      });
      upstream.listen((request) async {
        received.complete(await utf8.decoder.bind(request).join());
        final response = request.response
          ..bufferOutput = false
          ..headers.contentType = ContentType('text', 'event-stream');
        response.write('$firstEvent\n\n');
        await response.flush();
        await releaseTail.future;
        response.write('data: {"delta":"fixture-');
        await response.flush();
        response.write('key-024"}\n\ndata: [DONE]\n\n');
        await response.close();
      });
      final gateway = await start();
      final response = await send(
        _chat,
        method: 'POST',
        token: gateway.token,
        body: body,
      ).timeout(const Duration(seconds: 3));
      expect(await received.future.timeout(const Duration(seconds: 3)), body);
      expect(response.headers.contentType?.mimeType, 'text/event-stream');
      final lines = StreamIterator(
        response.transform(utf8.decoder).transform(const LineSplitter()),
      );
      addTearDown(lines.cancel);
      expect(
        await lines.moveNext().timeout(const Duration(seconds: 3)),
        isTrue,
      );
      expect(lines.current, firstEvent);
      releaseTail.complete();
      final remaining = <String>[];
      while (await lines.moveNext()) {
        remaining.add(lines.current);
      }
      expect(
        remaining,
        containsAllInOrder(['data: {"delta":"[redacted]"}', 'data: [DONE]']),
      );
    },
  );

  test(
    'blocks both redirect directions and suppresses upstream error details',
    () async {
      final other = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => other.close(force: true));
      var otherHits = 0;
      other.listen((request) {
        otherHits++;
        unawaited(request.response.close());
      });
      var hits = 0;
      upstream.listen((request) async {
        await request.drain<void>();
        final response = request.response;
        switch (++hits) {
          case 1:
            response.statusCode = 307;
            response.headers.set(
              'location',
              'http://127.0.0.1:${other.port}/other',
            );
          case 2:
            response.statusCode = 302;
            response.headers.set('location', '/other');
          default:
            response.statusCode = 429;
            response.write('upstream private error $_key');
        }
        await response.close();
      });
      final gateway = await start();
      for (final expected in [502, 502, 429]) {
        final response = await send(
          _chat,
          method: 'POST',
          token: gateway.token,
          body: '{}',
        );
        expect(response.statusCode, expected);
        expect(response.headers['location'], isNull);
        expect(await read(response), isNot(contains(_key)));
      }
      expect(hits, 3);
      expect(otherHits, 0);
    },
  );

  test(
    'rejects malformed, oversized and unsupported bodies before opening upstream',
    () async {
      var hits = 0;
      upstream.listen((request) {
        hits++;
        unawaited(request.response.close());
      });
      final gateway = await start();
      Future<int> post(String? body) async => (await send(
        _chat,
        method: 'POST',
        token: gateway.token,
        body: body,
      )).statusCode;
      expect(await post(null), 415);
      expect(await post('not json'), 400);
      expect(await post('[]'), 400);
      final socket = await Socket.connect(GatewayUpstream.host, port);
      addTearDown(socket.destroy);
      socket.write(
        'POST $_chat HTTP/1.1\r\n'
        'Host: $_host:$port\r\n'
        'Authorization: Bearer ${gateway.token}\r\n'
        'Content-Type: application/json\r\n'
        'Content-Length: ${LoopbackGateway.maxBodyBytes + 1}\r\n\r\n',
      );
      final status = await utf8.decoder
          .bind(socket)
          .transform(const LineSplitter())
          .first;
      expect(status, startsWith('HTTP/1.1 413 '));
      expect(hits, 0);
    },
  );

  test(
    'stops listening, rotates the token on restart, and reports occupied port',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final firstListener = await start();
      final controller = GatewayController.forTest(prefs, firstListener.port);
      addTearDown(controller.dispose);
      expect(await controller.start(), isFalse);
      expect(controller.issue, GatewayIssue.missingUpstream);
      expect(
        await controller.saveRoute(
          GatewayProtocol.chat,
          upstreamUrl(),
          _key,
          requiresKey: true,
        ),
        isTrue,
      );
      expect(prefs.getKeys(), {GatewaySettings.routeKey(GatewayProtocol.chat)});
      expect(await controller.start(), isFalse);
      expect(controller.state, GatewayState.stopped);
      expect(controller.issue, GatewayIssue.portInUse);
      await firstListener.stop();
      expect(await controller.start(), isTrue);
      final firstToken = controller.accessToken!;
      expect(
        await controller.saveRoute(
          GatewayProtocol.chat,
          'https://example.invalid/v1/chat/completions',
          '',
          requiresKey: false,
        ),
        isFalse,
      );
      await controller.stop();
      expect(controller.state, GatewayState.stopped);
      expect(controller.accessToken, isNull);
      await expectLater(
        send('/health', token: firstToken),
        throwsA(isA<SocketException>()),
      );
      expect(await controller.start(), isTrue);
      expect(controller.accessToken, isNot(firstToken));
      expect((await send('/health', token: firstToken)).statusCode, 401);
      await controller.stop();
    },
  );

  test(
    'restores independent routes without API keys, downgrade or autostart',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final original = GatewayController(preferences: prefs);
      expect(
        await original.saveRoute(
          GatewayProtocol.chat,
          upstreamUrl(),
          _key,
          requiresKey: true,
        ),
        isTrue,
      );
      final responsesUrl = upstreamUrl('/test/responses');
      expect(
        await original.saveRoute(
          GatewayProtocol.responses,
          responsesUrl,
          '',
          requiresKey: false,
        ),
        isTrue,
      );
      expect(
        prefs.getKeys().map((key) => prefs.get(key)),
        everyElement(isNot(contains(_key))),
      );
      original.dispose();
      final gateway = GatewayController.forTest(prefs, 0);
      addTearDown(gateway.dispose);
      expect(gateway.state, GatewayState.stopped);
      expect(gateway.endpointFor(GatewayProtocol.chat), upstreamUrl());
      expect(gateway.endpointFor(GatewayProtocol.responses), responsesUrl);
      expect(gateway.configuredCount, 2);
      expect(gateway.readyCount, 1);
      final auth = Completer<String?>();
      upstream.listen((request) async {
        auth.complete(request.headers.value('authorization'));
        await request.drain<void>();
        request.response.headers.contentType = ContentType.json;
        request.response.write('{}');
        await request.response.close();
      });
      expect(await gateway.start(), isTrue);
      port = int.parse(gateway.address.split(':').last);
      Future<HttpClientResponse> post(String path) =>
          send(path, method: 'POST', token: gateway.accessToken, body: '{}');
      final missingKey = await post(_chat);
      expect(missingKey.statusCode, 503);
      expect(await read(missingKey), contains('API key missing'));
      final missingRoute = await post('/v1/messages');
      expect(missingRoute.statusCode, 503);
      expect(await read(missingRoute), contains('No upstream configured'));
      expect((await post('/v1/responses')).statusCode, 200);
      expect(await auth.future, isNull);
      await gateway.stop();
    },
  );

  test('validates upstream URL and credential before saving', () {
    for (final url in [
      'http://example.invalid/v1',
      'http://user:pass@127.0.0.1:9999/v1',
      'http://127.0.0.1:3425/v1',
      'https://example.invalid/v1?url=elsewhere',
      'https://example.invalid/v1#fragment',
      'file:///tmp/a',
    ]) {
      expect(GatewayUpstream.parse(url, ''), isNull, reason: url);
    }
    expect(
      GatewayUpstream.parse('https://example.invalid/v1', 'bad\nheader'),
      isNull,
    );
    expect(
      GatewayUpstream.parse(
        'https://example.invalid/path/key-in-url',
        'key-in-url',
      ),
      isNull,
    );
    expect(
      GatewayUpstream.parse(
        'https://example.invalid/prefix/v1/chat/completions',
        '',
      )!.endpoint.path,
      '/prefix/v1/chat/completions',
    );
  });
}

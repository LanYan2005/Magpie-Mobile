import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:magpie_mobile/gateway/gateway_upstream.dart';
import 'package:magpie_mobile/gateway/provider_model_client.dart';

const _key = 'fixture-key-01';
const _prefix = '/tenant%2Fblue/%E6%A8%A1%E5%9E%8B';
const _version = 'v1beta2';
const _prompt = 'Reply with OK.';
const _messages = [
  {'role': 'user', 'content': _prompt},
];
const _vendorModel = 'Vendor/Model-1.2:free';
const _geminiModel = 'gemini-2.5-flash';
const _cases = {
  GatewayProtocol.chat: (
    endpoint: '$_prefix/v1/chat/completions',
    listPath: '$_prefix/v1/models',
    probePath: '$_prefix/v1/chat/completions',
    model: _vendorModel,
    auth: 'authorization',
    credential: 'Bearer $_key',
    body: {
      'model': _vendorModel,
      'messages': _messages,
      'max_completion_tokens': 64,
      'stream': false,
    },
    result: {
      'choices': [
        {
          'message': {'role': 'assistant', 'content': 'OK'},
        },
      ],
    },
    noText: {'choices': []},
  ),
  GatewayProtocol.responses: (
    endpoint: '$_prefix/v1/responses',
    listPath: '$_prefix/v1/models',
    probePath: '$_prefix/v1/responses',
    model: _vendorModel,
    auth: 'authorization',
    credential: 'Bearer $_key',
    body: {
      'model': _vendorModel,
      'input': _prompt,
      'max_output_tokens': 64,
      'stream': false,
    },
    result: {
      'status': 'completed',
      'output': [
        {
          'type': 'message',
          'content': [
            {'type': 'output_text', 'text': 'OK'},
          ],
        },
      ],
    },
    noText: {
      'status': 'completed',
      'output': [
        {'type': 'reasoning'},
      ],
    },
  ),
  GatewayProtocol.anthropic: (
    endpoint: '$_prefix/v1/messages',
    listPath: '$_prefix/v1/models',
    probePath: '$_prefix/v1/messages',
    model: _vendorModel,
    auth: 'x-api-key',
    credential: _key,
    body: {
      'model': _vendorModel,
      'messages': _messages,
      'max_tokens': 64,
      'stream': false,
    },
    result: {
      'content': [
        {'type': 'text', 'text': 'OK'},
      ],
    },
    noText: {
      'content': [
        {'type': 'thinking', 'thinking': 'OK'},
      ],
    },
  ),
  GatewayProtocol.gemini: (
    endpoint: '$_prefix/$_version///',
    listPath: '$_prefix/$_version/models',
    probePath: '$_prefix/$_version/models/$_geminiModel:generateContent',
    model: _geminiModel,
    auth: 'x-goog-api-key',
    credential: _key,
    body: {
      'contents': [
        {
          'parts': [
            {'text': _prompt},
          ],
        },
      ],
      'generationConfig': {'maxOutputTokens': 64},
    },
    result: {
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': 'OK'},
            ],
          },
        },
      ],
    },
    noText: {
      'candidates': [
        {
          'content': {
            'parts': [
              {'thought': true, 'text': 'OK'},
            ],
          },
        },
      ],
    },
  ),
};

Matcher _failure(ProviderProbeFailure failure, {int? status}) =>
    isA<ProviderProbeException>()
        .having((error) => error.failure, 'failure', failure)
        .having((error) => error.statusCode, 'statusCode', status);

Future<void> _json(HttpResponse response, Object body) {
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(body));
  return response.close();
}

void main() {
  const client = ProviderModelClient();
  late HttpServer server;
  late List<HttpRequest> requests;
  const chat = GatewayProtocol.chat;
  const gemini = GatewayProtocol.gemini;

  setUp(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    requests = [];
    addTearDown(() => server.close(force: true));
  });

  GatewayUpstream upstream(
    String endpoint, {
    String key = _key,
    bool auth = true,
  }) => GatewayUpstream.parse(
    'http://127.0.0.1:${server.port}$endpoint',
    key,
    requiresKey: auth,
  )!;

  void serve(Future<void> Function(HttpRequest) handler) {
    server.listen((request) async {
      requests.add(request);
      await handler(request);
    });
  }

  for (final entry in _cases.entries) {
    final protocol = entry.key;
    final spec = entry.value;

    test(
      '${protocol.name} lists models and probes with its wire format',
      () async {
        final isGemini = protocol == gemini;
        final account = upstream(spec.endpoint);
        Object? probeBody;
        serve((request) async {
          if (request.method == 'GET') {
            final rows = isGemini
                ? [
                    {'name': 'models/${spec.model}'},
                    {'name': 'models/${spec.model}'},
                    {'name': 'models/model-$_key'},
                    {'name': 'models/not/one-segment'},
                    {'name': 'not-models/ignore'},
                    {'name': 'models/gemini-2.0-flash-001'},
                  ]
                : [
                    {'id': spec.model},
                    {'id': spec.model},
                    {'id': 'model-$_key'},
                    {'id': 'stray\n'},
                    {'id': 'vendor/second@2025-01-01'},
                    {'id': 'a' * 257},
                  ];
            await _json(request.response, {isGemini ? 'models' : 'data': rows});
          } else {
            probeBody = jsonDecode(await utf8.decoder.bind(request).join());
            await _json(request.response, spec.result);
          }
        });

        final ids = await client.fetchModels(protocol, account);
        expect(ids, [
          spec.model,
          isGemini ? 'gemini-2.0-flash-001' : 'vendor/second@2025-01-01',
        ]);
        // The list yields the bare Gemini ID, and the probe also accepts the
        // official resource name returned by the provider.
        await client.testModel(
          protocol,
          account,
          isGemini ? 'models/${ids.first}' : ids.first,
        );

        expect(requests.map((request) => request.method), ['GET', 'POST']);
        expect(requests.map((request) => request.uri.toString()), [
          spec.listPath,
          spec.probePath,
        ]);
        for (final request in requests) {
          expect(request.headers.value('accept'), 'application/json');
          expect(request.headers.value('accept-encoding'), 'identity');
          expect(
            request.headers.value('anthropic-version'),
            protocol == GatewayProtocol.anthropic ? '2023-06-01' : null,
          );
          for (final header in [
            'authorization',
            'x-api-key',
            'x-goog-api-key',
          ]) {
            expect(
              request.headers.value(header),
              header == spec.auth ? spec.credential : null,
            );
          }
        }
        expect(requests.last.headers.contentType?.mimeType, 'application/json');
        expect(probeBody, spec.body);
      },
    );

    test('${protocol.name} requires actual generated text', () async {
      serve((request) async {
        await request.drain<void>();
        await _json(request.response, spec.noText);
      });
      await expectLater(
        client.testModel(protocol, upstream(spec.endpoint), spec.model),
        throwsA(_failure(ProviderProbeFailure.invalidResponse)),
      );
    });
  }

  test(
    'keyless routes send no authentication and accept an empty list',
    () async {
      serve((request) => _json(request.response, {'data': []}));
      expect(
        await client.fetchModels(
          chat,
          upstream('/v1/chat/completions///', key: '', auth: false),
        ),
        isEmpty,
      );
      final request = requests.single;
      expect(request.uri.toString(), '/v1/models');
      for (final header in ['authorization', 'x-api-key', 'x-goog-api-key']) {
        expect(request.headers.value(header), isNull);
      }
    },
  );

  test(
    'rejects unsupported routes, missing keys, and invalid model IDs locally',
    () async {
      serve((request) => request.response.close());
      final system = upstream('/v1/systemone');
      final notReady = upstream('/v1/chat/completions', key: '');
      final wrongPath = upstream('/v1/messages');
      for (final action in <Future<Object?> Function()>[
        () => client.fetchModels(GatewayProtocol.systemOne, system),
        () => client.testModel(GatewayProtocol.systemOne, system, _vendorModel),
        () => client.fetchModels(chat, notReady),
        () => client.testModel(chat, notReady, _vendorModel),
        () => client.fetchModels(chat, wrongPath),
        () => client.testModel(chat, wrongPath, _vendorModel),
        () => client.fetchModels(
          chat,
          upstream('/v1/chat/completions', key: 'models'),
        ),
        () => client.testModel(
          gemini,
          upstream('/v1beta', key: 'generateContent'),
          _geminiModel,
        ),
      ]) {
        await expectLater(
          action(),
          throwsA(_failure(ProviderProbeFailure.unsupported)),
        );
      }
      for (final model in [
        '',
        'bad\n',
        'model-$_key',
        'bad?key=x',
        'a' * 257,
      ]) {
        await expectLater(
          client.testModel(chat, upstream('/v1/chat/completions'), model),
          throwsA(_failure(ProviderProbeFailure.invalidModel)),
        );
      }
      for (final model in [
        'other/name',
        'models/../escape',
        'escape%2Fpath',
        'x:countTokens',
        '.foo',
        'a' * 129,
      ]) {
        await expectLater(
          client.testModel(gemini, upstream('/v1beta'), model),
          throwsA(_failure(ProviderProbeFailure.invalidModel)),
        );
      }
      expect(requests, isEmpty);
    },
  );

  test(
    'returns a typed HTTP error without following a redirect or echoing credentials',
    () async {
      serve((request) {
        final response = request.response;
        if (requests.length == 1) {
          response.statusCode = HttpStatus.temporaryRedirect;
          response.headers.set('location', '/redirected?echo=$_key');
        } else {
          response.statusCode = HttpStatus.unauthorized;
        }
        return _json(response, {'error': _key});
      });
      final account = upstream('/v1/chat/completions');
      for (final status in [307, 401]) {
        await expectLater(
          client.fetchModels(chat, account),
          throwsA(
            allOf(
              _failure(ProviderProbeFailure.http, status: status),
              predicate<Object>((error) => !error.toString().contains(_key)),
            ),
          ),
        );
      }
      expect(requests.map((request) => request.uri.toString()), [
        '/v1/models',
        '/v1/models',
      ]);
    },
  );

  test(
    'rejects malformed JSON, unexpected MIME, errors and wrong list schemas',
    () async {
      final replies = <(ContentType, String)>[
        (ContentType.json, '{$_key'),
        (ContentType.html, '{"data":[]}'),
        (ContentType.json, '{"error":"$_key","data":[]}'),
        (ContentType.json, '{"models":[]}'),
        (ContentType.json, '{"data":[{"name":"other"}]}'),
      ];
      serve((request) {
        final (mime, body) = replies[requests.length - 1];
        final response = request.response;
        response.headers.contentType = mime;
        response.write(body);
        return response.close();
      });
      final account = upstream('/v1/chat/completions');
      for (final _ in replies) {
        await expectLater(
          client.fetchModels(chat, account),
          throwsA(
            allOf(
              _failure(ProviderProbeFailure.invalidResponse),
              predicate<Object>((error) => !error.toString().contains(_key)),
            ),
          ),
        );
      }
    },
  );

  test('enforces the byte limit on chunked model lists', () async {
    final page = jsonEncode({
      'data': [
        {'id': _vendorModel},
      ],
      'padding': ' ' * (1024 * 1024),
    });
    serve((request) async {
      final response = request.response;
      response.headers.contentType = ContentType.json;
      response.write(page.substring(0, 512 * 1024));
      await response.flush();
      response.write(page.substring(512 * 1024));
      await response.close();
    });
    await expectLater(
      client.fetchModels(chat, upstream('/v1/chat/completions')),
      throwsA(_failure(ProviderProbeFailure.invalidResponse)),
    );
  });

  test('rejects oversized probe responses with a declared length', () async {
    final body = jsonEncode({
      'choices': [
        {
          'message': {'content': 'a' * (64 * 1024)},
        },
      ],
    });
    serve((request) async {
      await request.drain<void>();
      final response = request.response;
      response.contentLength = body.length;
      await _json(response, jsonDecode(body) as Object);
    });
    await expectLater(
      client.testModel(chat, upstream('/v1/chat/completions'), _vendorModel),
      throwsA(_failure(ProviderProbeFailure.invalidResponse)),
    );
  });

  test(
    'classifies a connection dropped before HTTP headers as network',
    () async {
      serve((request) async {
        final socket = await request.response.detachSocket(writeHeaders: false);
        socket.destroy();
      });
      await expectLater(
        client.fetchModels(chat, upstream('/v1/chat/completions')),
        throwsA(_failure(ProviderProbeFailure.network)),
      );
    },
  );

  test(
    'times out a response that sends headers but stalls its JSON body',
    () async {
      final flushed = Completer<void>();
      serve((request) async {
        final response = request.response;
        response.headers.contentType = ContentType.json;
        response.write('{');
        await response.flush();
        flushed.complete();
      });
      await expectLater(
        client.fetchModels(chat, upstream('/v1/chat/completions')),
        throwsA(_failure(ProviderProbeFailure.timeout)),
      );
      expect(flushed.isCompleted, isTrue);
    },
  );
}

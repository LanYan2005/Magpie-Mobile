enum GatewayProtocol {
  chat('Chat Completions', '/v1/chat/completions'),
  responses('Responses', '/v1/responses'),
  anthropic('Anthropic Messages', '/v1/messages'),
  gemini('Gemini', '/v1beta/models/'),
  systemOne('System One', '/v1/systemone');

  const GatewayProtocol(this.label, this.inboundPath);

  final String label;
  final String inboundPath;

  /// A versioned API root for Gemini; a complete operation path otherwise.
  bool acceptsEndpoint(Uri uri) {
    final path = uri.path.replaceFirst(RegExp(r'/+$'), '');
    if (path.isEmpty || uri.pathSegments.any(_unsafeSegment)) return false;
    final versionedPath = RegExp(r'(?:^|/)v[0-9]+(?:(?:alpha|beta)[0-9]*)?$');
    if (this == gemini) return versionedPath.hasMatch(path);
    return switch (this) {
      chat => path.endsWith('/chat/completions'),
      responses => path.endsWith('/responses'),
      anthropic => path.endsWith('/messages'),
      systemOne => path.endsWith('/systemone'),
      gemini => false,
    };
  }

  static bool _unsafeSegment(String segment) =>
      segment == '.' || segment == '..' || segment.contains('\\');
}

/// Only known methods and model identifiers can contribute to the upstream URL.
class GatewayRoute {
  const GatewayRoute._(this.protocol, {this.model, this.operation});

  final GatewayProtocol protocol;
  final String? model;
  final String? operation;

  static final _geminiPath = RegExp(
    r'^/v1beta/models/([A-Za-z0-9_-][A-Za-z0-9._-]{0,127}):(generateContent|streamGenerateContent|countTokens|embedContent|batchEmbedContents)$',
  );

  static GatewayRoute? match(String path) {
    for (final protocol in GatewayProtocol.values) {
      if (protocol != GatewayProtocol.gemini && path == protocol.inboundPath) {
        return GatewayRoute._(protocol);
      }
    }
    if (path == '/v1/messages/count_tokens') {
      return const GatewayRoute._(
        GatewayProtocol.anthropic,
        operation: 'count_tokens',
      );
    }
    final gemini = _geminiPath.firstMatch(path);
    if (gemini == null) return null;
    return GatewayRoute._(
      GatewayProtocol.gemini,
      model: gemini[1],
      operation: gemini[2],
    );
  }

  bool acceptsQuery(Map<String, List<String>> parameters) {
    if (protocol != GatewayProtocol.gemini) return false;
    for (final entry in parameters.entries) {
      if (entry.value.length != 1) return false;
      if (entry.key == 'key') continue;
      if (entry.key != 'alt' ||
          operation != 'streamGenerateContent' ||
          entry.value.single != 'sse') {
        return false;
      }
    }
    return parameters.containsKey('key') ||
        parameters.keys.every((key) => key == 'alt');
  }

  Uri target(Uri endpoint) {
    final path = endpoint.path.replaceFirst(RegExp(r'/+$'), '');
    return switch (protocol) {
      GatewayProtocol.anthropic when operation == 'count_tokens' =>
        endpoint.replace(path: '$path/count_tokens'),
      GatewayProtocol.gemini => endpoint.replace(
        path: '$path/models/$model:$operation',
        queryParameters: operation == 'streamGenerateContent'
            ? const {'alt': 'sse'}
            : null,
      ),
      _ => endpoint,
    };
  }
}

/// Endpoint is complete for fixed routes and a versioned API root for Gemini.
/// A stored route may require a credential that has not been loaded this run.
class GatewayUpstream {
  const GatewayUpstream._(this.endpoint, this.apiKey, this.requiresKey);

  static const host = '127.0.0.1';
  static const port = 3425;

  final Uri endpoint;
  final String apiKey;
  final bool requiresKey;

  bool get ready => !requiresKey || apiKey.isNotEmpty;

  static Uri? parseEndpoint(String url) {
    final endpoint = Uri.tryParse(url.trim());
    if (endpoint == null ||
        !endpoint.hasAuthority ||
        endpoint.host.isEmpty ||
        endpoint.authority.contains('@') ||
        endpoint.hasQuery ||
        endpoint.hasFragment ||
        !(endpoint.scheme == 'https' ||
            (endpoint.scheme == 'http' && endpoint.host == host)) ||
        endpoint.port < 1 ||
        endpoint.port > 65535 ||
        endpoint.host == host && endpoint.port == port) {
      return null;
    }
    return endpoint;
  }

  static bool validKey(String key) =>
      key.length <= 512 && RegExp(r'^[A-Za-z0-9._~+/=-]*$').hasMatch(key);

  static GatewayUpstream? parse(
    String url,
    String key, {
    bool requiresKey = true,
  }) {
    final endpoint = parseEndpoint(url);
    final apiKey = key.trim();
    if (endpoint == null ||
        !validKey(apiKey) ||
        (!requiresKey && apiKey.isNotEmpty) ||
        // A key belongs in an auth header, not embedded in a saved URL.
        (apiKey.isNotEmpty &&
            (endpoint.toString().contains(apiKey) ||
                endpoint.pathSegments.join('/').contains(apiKey)))) {
      return null;
    }
    return GatewayUpstream._(endpoint, apiKey, requiresKey);
  }
}

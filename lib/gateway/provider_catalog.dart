import 'gateway_upstream.dart';

/// Connection metadata only. Credentials are referenced by opaque IDs.
class ProviderAccount {
  ProviderAccount({
    required this.id,
    required this.name,
    required this.protocol,
    required this.endpoint,
    required this.requiresKey,
    Iterable<String> models = const [],
    this.credentialId,
  }) : models = List.unmodifiable(models);

  final String id;
  final String name;
  final GatewayProtocol protocol;
  final Uri endpoint;
  final bool requiresKey;
  final List<String> models;
  final String? credentialId;

  Map<String, Object> toJson({required bool includeReference}) => {
    'id': id,
    'name': name,
    'protocol': protocol.name,
    'endpoint': endpoint.toString(),
    'requiresKey': requiresKey,
    'models': models,
    if (includeReference && credentialId != null) 'credentialId': credentialId!,
  };
}

class UpstreamProvider {
  UpstreamProvider({
    required this.id,
    required this.name,
    this.enabled = true,
    Iterable<ProviderAccount> accounts = const [],
    Iterable<String> agentIds = const [],
  }) : accounts = List.unmodifiable(accounts),
       agentIds = Set.unmodifiable(agentIds);

  final String id;
  final String name;
  final bool enabled;
  final List<ProviderAccount> accounts;
  final Set<String> agentIds;

  Set<String> get hosts => accounts.map((account) => account.endpoint.host).toSet();
  int get modelCount => accounts.expand((account) => account.models).toSet().length;

  UpstreamProvider copyWith({
    String? name,
    bool? enabled,
    Iterable<ProviderAccount>? accounts,
    Iterable<String>? agentIds,
  }) => UpstreamProvider(
    id: id,
    name: name ?? this.name,
    enabled: enabled ?? this.enabled,
    accounts: accounts ?? this.accounts,
    agentIds: agentIds ?? this.agentIds,
  );

  Map<String, Object> toJson({required bool includeReference}) => {
    'id': id,
    'name': name,
    'enabled': enabled,
    'agentIds': agentIds.toList(),
    'accounts': [
      for (final account in accounts)
        account.toJson(includeReference: includeReference),
    ],
  };
}

class ProviderCatalog {
  ProviderCatalog({
    Iterable<UpstreamProvider> providers = const [],
    Map<GatewayProtocol, String> selected = const {},
  }) : providers = List.unmodifiable(providers),
       selected = Map.unmodifiable(selected);

  final List<UpstreamProvider> providers;
  final Map<GatewayProtocol, String> selected;

  Map<String, Object> toJson({bool includeReferences = false}) => {
    'version': 1,
    'providers': [
      for (final provider in providers)
        provider.toJson(includeReference: includeReferences),
    ],
    'selected': {for (final entry in selected.entries) entry.key.name: entry.value},
  };

  /// Reject the whole document if any entry is invalid or contains an unknown
  /// field. Imports have no access to existing local credential references.
  static ProviderCatalog decode(Object? raw, {bool allowReferences = false}) {
    final root = _object(raw, {'version', 'providers', 'selected'});
    if (root['version'] != 1) throw const FormatException();
    final providerIds = <String>{};
    final accountProtocols = <String, GatewayProtocol>{};
    final credentialIds = <String>{};
    final providers = <UpstreamProvider>[];
    for (final item in _list(root['providers'])) {
      final row = _object(item, {'id', 'name', 'enabled', 'agentIds', 'accounts'});
      final id = _id(row['id']);
      if (!providerIds.add(id)) throw const FormatException();
      final enabled = row['enabled'];
      if (enabled is! bool) throw const FormatException();
      final accounts = <ProviderAccount>[];
      for (final value in _list(row['accounts'])) {
        final entry = _object(value, {
          'id', 'name', 'protocol', 'endpoint', 'requiresKey', 'models',
          if (allowReferences) 'credentialId',
        });
        final accountId = _id(entry['id']);
        final protocol = _protocol(entry['protocol']);
        if (accountProtocols.containsKey(accountId)) throw const FormatException();
        accountProtocols[accountId] = protocol;
        final endpoint = GatewayUpstream.parseEndpoint(_text(entry['endpoint'], 2048));
        final requiresKey = entry['requiresKey'];
        if (endpoint == null || !protocol.acceptsEndpoint(endpoint) || requiresKey is! bool) {
          throw const FormatException();
        }
        final reference = entry.containsKey('credentialId') ? _id(entry['credentialId']) : null;
        if (reference != null && (!requiresKey || !credentialIds.add(reference))) {
          throw const FormatException();
        }
        accounts.add(ProviderAccount(
          id: accountId,
          name: _text(entry['name'], 100),
          protocol: protocol,
          endpoint: endpoint,
          requiresKey: requiresKey,
          models: _list(entry['models']).map((model) => _text(model, 256)).toSet(),
          credentialId: reference,
        ));
      }
      providers.add(UpstreamProvider(
        id: id,
        name: _text(row['name'], 100),
        enabled: enabled,
        agentIds: _list(row['agentIds']).map(_id),
        accounts: accounts,
      ));
    }
    final selected = <GatewayProtocol, String>{};
    for (final entry in _object(root['selected'], GatewayProtocol.values.map((p) => p.name).toSet()).entries) {
      final protocol = _protocol(entry.key);
      final id = _id(entry.value);
      if (accountProtocols[id] != protocol) throw const FormatException();
      selected[protocol] = id;
    }
    return ProviderCatalog(providers: providers, selected: selected);
  }

  static Map<String, dynamic> _object(Object? raw, Set<String> allowed) {
    if (raw is! Map<String, dynamic> || raw.keys.any((key) => !allowed.contains(key))) {
      throw const FormatException();
    }
    return raw;
  }

  static List<dynamic> _list(Object? raw) {
    if (raw is! List<dynamic>) throw const FormatException();
    return raw;
  }

  static String _text(Object? raw, int limit) {
    if (raw is! String || raw.trim().isEmpty || raw.length > limit ||
        raw.codeUnits.any((unit) => unit < 32 || unit == 127)) {
      throw const FormatException();
    }
    return raw.trim();
  }

  static String _id(Object? raw) {
    if (raw is! String || !RegExp(r'^[A-Za-z0-9_-]{1,100}$').hasMatch(raw)) {
      throw const FormatException();
    }
    return raw;
  }

  static GatewayProtocol _protocol(Object? raw) => GatewayProtocol.values.firstWhere(
    (protocol) => protocol.name == raw,
    orElse: () => throw const FormatException(),
  );
}

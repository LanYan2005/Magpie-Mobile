import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'gateway_settings.dart';
import 'gateway_upstream.dart';
import 'loopback_gateway.dart';
import 'provider_catalog.dart';
import 'provider_credentials.dart';
import 'provider_model_client.dart';

export 'provider_catalog.dart';

enum GatewayState { stopped, starting, running, stopping }

enum GatewayIssue {
  invalidUpstream,
  invalidApiKey,
  invalidProvider,
  invalidImport,
  catalogLoadFailed,
  migrationFailed,
  credentialFailed,
  saveFailed,
  missingUpstream,
  portInUse,
  startFailed,
  listenerEnded,
}

class GatewayController extends ChangeNotifier {
  GatewayController({required SharedPreferences? preferences})
    : this._(
        preferences,
        GatewayUpstream.port,
        const SecureProviderCredentials(),
      );

  @visibleForTesting
  GatewayController.forTest(
    SharedPreferences preferences,
    int port, {
    ProviderCredentials credentials = const SecureProviderCredentials(),
  }) : this._(preferences, port, credentials);

  GatewayController._(
    SharedPreferences? preferences,
    this._port,
    this._credentials,
  ) : _settings = GatewaySettings(preferences) {
    initialized = _load();
  }

  final GatewaySettings _settings;
  final ProviderCredentials _credentials;
  final int _port;
  late final Future<void> initialized;
  ProviderCatalog _catalog = ProviderCatalog();
  final _keys = <String, String>{};
  final _failedKeys = <String>{};
  LoopbackGateway? _gateway;
  GatewayState _state = GatewayState.stopped;
  GatewayIssue? _issue;
  GatewayIssue? _loadIssue;
  bool _loading = true;
  bool _saving = false;
  bool _disposed = false;

  GatewayState get state => _state;
  GatewayIssue? get issue => _issue;
  GatewayIssue? get loadIssue => _loadIssue;
  bool get loading => _loading;
  bool get saving => _saving;
  bool get canStart =>
      !_disposed && !_loading && !_saving && _state == GatewayState.stopped;
  bool get canConfigure => canStart && _loadIssue == null;
  List<UpstreamProvider> get providers => _catalog.providers;
  UpstreamProvider? provider(String id) =>
      providers.where((item) => item.id == id).firstOrNull;
  String? selectedAccountId(GatewayProtocol protocol) =>
      _catalog.selected[protocol];
  int get configuredCount => _routes.length;
  int get readyCount => _routes.values.where((route) => route.ready).length;
  String? get accessToken => _gateway?.token;
  String get address => '${GatewayUpstream.host}:${_gateway?.port ?? _port}';

  bool hasAccountKey(ProviderAccount account) =>
      _keys.containsKey(account.credentialId);
  bool accountKeyFailed(ProviderAccount account) =>
      _failedKeys.contains(account.credentialId);
  String? maskedAccountKey(
    ProviderAccount account, {
    required bool hideSuffix,
  }) {
    final key = _keys[account.credentialId];
    if (key == null) return null;
    return hideSuffix || key.length <= 4
        ? '••••'
        : '••••${key.substring(key.length - 4)}';
  }

  Map<GatewayProtocol, GatewayUpstream> get _routes => {
    for (final provider in providers)
      if (provider.enabled)
        for (final account in provider.accounts)
          if (selectedAccountId(account.protocol) == account.id)
            account.protocol: GatewayUpstream.parse(
              account.endpoint.toString(),
              _keys[account.credentialId] ?? '',
              requiresKey: account.requiresKey,
            )!,
  };

  String endpointFor(GatewayProtocol protocol) =>
      _routes[protocol]?.endpoint.toString() ?? '';

  Future<List<String>> fetchProviderModels({
    required GatewayProtocol protocol,
    required Uri endpoint,
    required String apiKey,
    required bool requiresKey,
    ProviderAccount? account,
  }) async {
    final upstream = _probeUpstream(protocol, endpoint, apiKey, requiresKey, account);
    final models = await const ProviderModelClient().fetchModels(protocol, upstream);
    return models.where((model) => !_containsKey(model, _keys.values)).toList();
  }

  Future<void> testProviderModel({
    required GatewayProtocol protocol,
    required Uri endpoint,
    required String apiKey,
    required bool requiresKey,
    required String model,
    ProviderAccount? account,
  }) async {
    final upstream = _probeUpstream(protocol, endpoint, apiKey, requiresKey, account);
    if (_containsKey(model, [..._keys.values, if (upstream.apiKey.isNotEmpty) upstream.apiKey])) {
      throw const ProviderProbeException(ProviderProbeFailure.invalidModel);
    }
    await const ProviderModelClient().testModel(protocol, upstream, model);
  }

  GatewayUpstream _probeUpstream(
    GatewayProtocol protocol,
    Uri endpoint,
    String apiKey,
    bool requiresKey,
    ProviderAccount? account,
  ) {
    if (!canConfigure || !protocol.acceptsEndpoint(endpoint)) {
      throw GatewayIssue.invalidUpstream;
    }
    var key = requiresKey ? apiKey.trim() : '';
    if (requiresKey && key.isEmpty && account != null &&
        account.protocol == protocol && account.endpoint == endpoint) {
      key = _keys[account.credentialId] ?? '';
    }
    if (_containsKey(endpoint.toString(), _keys.values) ||
        endpoint.pathSegments.any((segment) => _containsKey(segment, _keys.values))) {
      throw GatewayIssue.invalidApiKey;
    }
    final upstream = GatewayUpstream.parse(endpoint.toString(), key, requiresKey: requiresKey);
    if (upstream == null) throw GatewayIssue.invalidApiKey;
    if (!upstream.ready) throw GatewayIssue.credentialFailed;
    return upstream;
  }

  static bool _containsKey(String value, Iterable<String> keys) => keys.any(
    (key) => key.length >= 8 ? value.contains(key) : value == key,
  );

  Future<void> _load() async {
    final stored = _settings.storedCatalog;
    try {
      if (stored != null) {
        try {
          _catalog = ProviderCatalog.decode(
            stored is String ? jsonDecode(stored) : null,
            allowReferences: true,
          );
        } on FormatException {
          _loadIssue = GatewayIssue.catalogLoadFailed;
          return;
        }
        for (final account in _catalog.providers.expand(
          (provider) => provider.accounts,
        )) {
          final id = account.credentialId;
          if (id == null) continue;
          try {
            final key = await _credentials.read(id);
            if (_disposed) return;
            if (key == null ||
                key.isEmpty ||
                GatewayUpstream.parse(account.endpoint.toString(), key) ==
                    null) {
              _failedKeys.add(id);
            } else {
              _keys[id] = key;
            }
          } on Exception {
            if (_disposed) return;
            _failedKeys.add(id);
          }
        }
      } else {
        final legacy = _settings.readLegacy();
        _catalog = legacy.catalog;
        if (legacy.damaged ||
            (_catalog.providers.isNotEmpty &&
                !await _settings.save(_catalog))) {
          _loadIssue = GatewayIssue.migrationFailed;
        }
      }
    } finally {
      _loading = false;
      if (!_disposed) notifyListeners();
    }
  }

  static String _newId() {
    final rng = Random.secure();
    return List.generate(
      16,
      (_) => rng.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ).join();
  }

  bool _fail(GatewayIssue issue) {
    _issue = issue;
    if (!_disposed) notifyListeners();
    return false;
  }

  List<UpstreamProvider> _replacing(UpstreamProvider replacement) => [
    for (final item in providers)
      if (item.id == replacement.id) replacement else item,
    if (provider(replacement.id) == null) replacement,
  ];

  Future<bool> renameProvider(String id, String name) async {
    if (!canConfigure) return false;
    final current = provider(id);
    if (current == null) return false;
    return _commit(
      ProviderCatalog(
        providers: _replacing(current.copyWith(name: name.trim())),
        selected: _catalog.selected,
      ),
    );
  }

  /// Commits the provider, its first account and any route selection together.
  Future<String?> createProvider({
    required String providerName,
    required String accountName,
    required GatewayProtocol protocol,
    required String endpoint,
    required bool requiresKey,
    required String apiKey,
    required Iterable<String> models,
    required bool selected,
  }) async {
    if (!canConfigure) return null;
    final provider = UpstreamProvider(id: _newId(), name: providerName.trim());
    final saved = await _saveAccount(
      provider: provider,
      name: accountName,
      protocol: protocol,
      endpoint: endpoint,
      requiresKey: requiresKey,
      apiKey: apiKey,
      models: models,
      selected: selected,
    );
    return saved ? provider.id : null;
  }

  Future<bool> setProvidersEnabled(Set<String> ids, bool enabled) async {
    if (!canConfigure) return false;
    return _commit(
      ProviderCatalog(
        providers: providers.map(
          (provider) => ids.contains(provider.id)
              ? provider.copyWith(enabled: enabled)
              : provider,
        ),
        selected: _catalog.selected,
      ),
    );
  }

  Future<bool> saveAccount({
    required String providerId,
    String? accountId,
    required String name,
    required GatewayProtocol protocol,
    required String endpoint,
    required bool requiresKey,
    required String apiKey,
    required Iterable<String> models,
    required bool selected,
    bool clearKey = false,
  }) async {
    if (!canConfigure) return false;
    final provider = this.provider(providerId);
    if (provider == null) return false;
    final old = provider.accounts
        .where((item) => item.id == accountId)
        .firstOrNull;
    if (accountId != null && old == null) return false;
    return _saveAccount(
      provider: provider,
      old: old,
      name: name,
      protocol: protocol,
      endpoint: endpoint,
      requiresKey: requiresKey,
      apiKey: apiKey,
      models: models,
      selected: selected,
      clearKey: clearKey,
    );
  }

  Future<bool> _saveAccount({
    required UpstreamProvider provider,
    ProviderAccount? old,
    required String name,
    required GatewayProtocol protocol,
    required String endpoint,
    required bool requiresKey,
    required String apiKey,
    required Iterable<String> models,
    required bool selected,
    bool clearKey = false,
  }) async {
    final url = GatewayUpstream.parseEndpoint(endpoint);
    if (url == null || !protocol.acceptsEndpoint(url)) {
      return _fail(GatewayIssue.invalidUpstream);
    }
    final key = requiresKey ? apiKey.trim() : '';
    if (GatewayUpstream.parse(endpoint, key, requiresKey: requiresKey) ==
        null) {
      return _fail(GatewayIssue.invalidApiKey);
    }
    final previousRef = old?.credentialId;
    final reference = key.isNotEmpty
        ? _newId()
        : (requiresKey &&
                  !clearKey &&
                  old?.endpoint == url &&
                  old?.protocol == protocol
              ? previousRef
              : null);
    final account = ProviderAccount(
      id: old?.id ?? _newId(),
      name: name.trim(),
      protocol: protocol,
      endpoint: url,
      requiresKey: requiresKey,
      models: models
          .map((model) => model.trim())
          .where((model) => model.isNotEmpty)
          .toSet(),
      credentialId: reference,
    );
    final routes = Map<GatewayProtocol, String>.of(_catalog.selected);
    routes.removeWhere((_, id) => id == account.id);
    if (selected) routes[protocol] = account.id;
    return _commit(
      ProviderCatalog(
        providers: _replacing(
          provider.copyWith(
            accounts: [
              for (final item in provider.accounts)
                if (item.id == account.id) account else item,
              if (old == null) account,
            ],
          ),
        ),
        selected: routes,
      ),
      newKey: key.isEmpty ? null : (reference!, key),
      retiredKey: reference == previousRef ? null : previousRef,
    );
  }

  /// Creates or replaces a single-protocol provider and selects it.
  ///
  /// Kept for callers and tests that still work one protocol at a time; the
  /// provider catalog stores accounts, so this adds to a provider named after
  /// the endpoint's host.
  Future<bool> saveRoute(
    GatewayProtocol protocol,
    String endpoint,
    String apiKey, {
    bool requiresKey = true,
  }) async {
    if (!canConfigure) return false;
    final url = GatewayUpstream.parseEndpoint(endpoint);
    if (url == null || !protocol.acceptsEndpoint(url)) {
      return _fail(GatewayIssue.invalidUpstream);
    }
    final key = requiresKey ? apiKey.trim() : '';
    if (GatewayUpstream.parse(endpoint, key, requiresKey: requiresKey) ==
        null) {
      return _fail(GatewayIssue.invalidApiKey);
    }
    final existing = providers
        .where(
          (provider) => provider.accounts.any(
            (account) => account.id == 'legacy-account-${protocol.name}',
          ),
        )
        .firstOrNull;
    final providerId = existing?.id ?? _newId();
    final accountId = 'legacy-account-${protocol.name}';
    final account = ProviderAccount(
      id: accountId,
      name: protocol.label,
      protocol: protocol,
      endpoint: url,
      requiresKey: requiresKey,
      models: const [],
      credentialId: key.isEmpty ? null : _newId(),
    );
    final provider =
        existing ?? UpstreamProvider(id: providerId, name: url.host);
    final routes = Map<GatewayProtocol, String>.of(_catalog.selected)
      ..[protocol] = accountId;
    return _commit(
      ProviderCatalog(
        providers: _replacing(
          provider.copyWith(
            accounts: [
              for (final item in provider.accounts)
                if (item.id != accountId) item,
              account,
            ],
          ),
        ),
        selected: routes,
      ),
      newKey: key.isEmpty ? null : (account.credentialId!, key),
      retiredKey: existing?.accounts
          .where((item) => item.id == accountId)
          .firstOrNull
          ?.credentialId,
    );
  }

  Future<bool> removeAccount(String providerId, String accountId) async {
    if (!canConfigure) return false;
    final provider = this.provider(providerId);
    if (provider == null) return false;
    final account = provider.accounts
        .where((item) => item.id == accountId)
        .firstOrNull;
    if (account == null) return false;
    return _commit(
      ProviderCatalog(
        providers: _replacing(
          provider.copyWith(
            accounts: provider.accounts.where((item) => item.id != accountId),
          ),
        ),
        selected: Map.of(_catalog.selected)
          ..removeWhere((_, id) => id == accountId),
      ),
      retiredKey: account.credentialId,
    );
  }

  /// Append with new IDs so an imported file cannot replace active accounts,
  /// bind Agents, or override an already-selected route.
  Future<bool> importProviders(String source) async {
    if (!canConfigure) return false;
    try {
      final imported = ProviderCatalog.decode(jsonDecode(source));
      if (imported.providers.isEmpty) return _fail(GatewayIssue.invalidImport);
      final ids = <String, String>{};
      final rows = [
        for (final provider in imported.providers)
          UpstreamProvider(
            id: _newId(),
            name: provider.name,
            enabled: provider.enabled,
            accounts: [
              for (final account in provider.accounts)
                ProviderAccount(
                  id: ids[account.id] = _newId(),
                  name: account.name,
                  protocol: account.protocol,
                  endpoint: account.endpoint,
                  requiresKey: account.requiresKey,
                  models: account.models,
                ),
            ],
          ),
      ];
      return _commit(
        ProviderCatalog(
          providers: [...providers, ...rows],
          selected: {
            for (final entry in imported.selected.entries)
              entry.key: ids[entry.value]!,
            ..._catalog.selected,
          },
        ),
      );
    } on FormatException {
      return _fail(GatewayIssue.invalidImport);
    }
  }

  Future<bool> _commit(
    ProviderCatalog next, {
    (String, String)? newKey,
    String? retiredKey,
  }) async {
    try {
      next = ProviderCatalog.decode(
        next.toJson(includeReferences: true),
        allowReferences: true,
      );
    } on FormatException {
      return _fail(GatewayIssue.invalidProvider);
    }
    // Credentials must stay out of display metadata and its serialized form.
    final textFields = [
      for (final provider in next.providers) ...[
        provider.name,
        for (final account in provider.accounts) ...[
          account.name,
          account.endpoint.toString(),
          ...account.endpoint.pathSegments,
          ...account.models,
        ],
      ],
    ];
    if ([..._keys.values, if (newKey != null) newKey.$2].any(
      (key) => textFields.any(
        (value) => key.length >= 8 ? value.contains(key) : value == key,
      ),
    )) {
      return _fail(GatewayIssue.invalidApiKey);
    }
    _saving = true;
    _issue = null;
    notifyListeners();
    var committed = false;
    try {
      if (newKey != null) {
        try {
          await _credentials.write(newKey.$1, newKey.$2);
        } on Exception {
          _issue = GatewayIssue.credentialFailed;
          return false;
        }
      }
      if (!await _settings.save(next)) {
        _issue = GatewayIssue.saveFailed;
        return false;
      }
      committed = true;
      if (!_disposed) {
        _catalog = next;
        if (newKey != null) _keys[newKey.$1] = newKey.$2;
        _keys.remove(retiredKey);
        _failedKeys.remove(retiredKey);
      }
      return true;
    } finally {
      final discard = committed ? retiredKey : newKey?.$1;
      if (discard != null) {
        try {
          await _credentials.delete(discard);
        } on Exception {
          // An unreferenced key stays in the OS vault and is never used again.
        }
      }
      _saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> start() async {
    await initialized;
    if (!canStart || _loadIssue == GatewayIssue.catalogLoadFailed) return false;
    final routes = _routes;
    if (routes.isEmpty) return _fail(GatewayIssue.missingUpstream);
    _state = GatewayState.starting;
    _issue = null;
    notifyListeners();
    try {
      final gateway = await LoopbackGateway.start(routes, port: _port);
      if (_disposed) {
        await gateway.stop();
        return false;
      }
      _gateway = gateway;
      _state = GatewayState.running;
      unawaited(
        gateway.ended.then((_) {
          if (_state == GatewayState.running && identical(_gateway, gateway)) {
            _gateway = null;
            _state = GatewayState.stopped;
            _issue = GatewayIssue.listenerEnded;
            notifyListeners();
          }
        }),
      );
      return true;
    } on SocketException catch (error) {
      final osError = error.osError;
      final description = osError?.message.toLowerCase() ?? '';
      _issue =
          const {98, 48, 10048}.contains(osError?.errorCode) ||
              description.contains('address already in use') ||
              description.contains('only one usage of each socket address') ||
              description.contains('shared flag to bind() needs to be `true`')
          ? GatewayIssue.portInUse
          : GatewayIssue.startFailed;
      return false;
    } on Exception {
      _issue = GatewayIssue.startFailed;
      return false;
    } finally {
      if (_state == GatewayState.starting) _state = GatewayState.stopped;
      if (!_disposed) notifyListeners();
    }
  }

  Future<void> stop() async {
    final gateway = _gateway;
    if (_disposed || _state != GatewayState.running || gateway == null) return;
    _gateway = null;
    _state = GatewayState.stopping;
    notifyListeners();
    await gateway.stop();
    _state = GatewayState.stopped;
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    final gateway = _gateway;
    _gateway = null;
    _keys.clear();
    if (gateway != null) unawaited(gateway.stop());
    super.dispose();
  }
}

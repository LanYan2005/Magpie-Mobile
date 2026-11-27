import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'gateway_upstream.dart';
import 'provider_catalog.dart';

class GatewaySettings {
  const GatewaySettings(this._preferences);

  final SharedPreferences? _preferences;
  static const catalogKey = 'magpie.gateway.providers.v1';
  static String routeKey(GatewayProtocol protocol) =>
      'magpie.gateway.route.${protocol.name}';

  Object? get storedCatalog => _preferences?.get(catalogKey);

  /// The valid routes remain usable if any sibling route fails to migrate.
  ({ProviderCatalog catalog, bool damaged}) readLegacy() {
    final byOrigin = <String, UpstreamProvider>{};
    final selected = <GatewayProtocol, String>{};
    var damaged = false;
    for (final protocol in GatewayProtocol.values) {
      final raw = _preferences?.get(routeKey(protocol));
      if (raw == null || raw == 'null') continue; // Legacy deletion marker.
      try {
        final entry = raw is String ? jsonDecode(raw) : null;
        if (entry case {
          'endpoint': final String url,
          'requiresKey': final bool requiresKey,
        }) {
          final endpoint = GatewayUpstream.parseEndpoint(url);
          if (endpoint == null || !protocol.acceptsEndpoint(endpoint) || url.length > 2048) {
            throw const FormatException();
          }
          final origin = endpoint.origin;
          final provider = byOrigin[origin] ?? UpstreamProvider(
            id: 'legacy-provider-${protocol.name}',
            name: _legacyName(endpoint),
          );
          final account = ProviderAccount(
            id: 'legacy-account-${protocol.name}',
            name: protocol.label,
            protocol: protocol,
            endpoint: endpoint,
            requiresKey: requiresKey,
          );
          byOrigin[origin] = provider.copyWith(accounts: [...provider.accounts, account]);
          selected[protocol] = account.id;
        } else {
          damaged = true;
        }
      } on FormatException {
        damaged = true;
      }
    }
    return (catalog: ProviderCatalog(providers: byOrigin.values, selected: selected), damaged: damaged);
  }

  static String _legacyName(Uri endpoint) {
    final host = endpoint.host;
    return host.length <= 100 ? host : host.substring(0, 100);
  }

  /// Never changes legacy keys. Restore the preferences cache if a platform
  /// write fails (SharedPreferences updates its cache before awaiting disk).
  Future<bool> save(ProviderCatalog catalog) async {
    final preferences = _preferences;
    if (preferences == null) return false;
    final previous = preferences.getString(catalogKey);
    try {
      if (await preferences.setString(
        catalogKey, jsonEncode(catalog.toJson(includeReferences: true)),
      )) {
        return true;
      }
    } on Exception {
      // Report a generic failure and restore the last committed snapshot.
    }
    try {
      if (previous == null) {
        await preferences.remove(catalogKey);
      } else {
        await preferences.setString(catalogKey, previous);
      }
    } on Exception {
      // The running controller continues to use its last committed snapshot.
    }
    return false;
  }
}

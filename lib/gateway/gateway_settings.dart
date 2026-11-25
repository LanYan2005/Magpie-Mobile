import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'gateway_upstream.dart';

/// Persists route addresses/auth modes only, never the credentials themselves.
class GatewaySettings {
  const GatewaySettings(this._preferences);

  final SharedPreferences? _preferences;
  static String routeKey(GatewayProtocol protocol) =>
      'magpie.gateway.route.${protocol.name}';

  Map<GatewayProtocol, GatewayUpstream> load() {
    final routes = <GatewayProtocol, GatewayUpstream>{};
    for (final protocol in GatewayProtocol.values) {
      final raw = _preferences?.get(routeKey(protocol));
      if (raw is! String) continue;
      try {
        final entry = jsonDecode(raw);
        if (entry is! Map<String, dynamic>) continue;
        if (entry case {
          'endpoint': final String url,
          'requiresKey': final bool needsKey,
        }) {
          final route = GatewayUpstream.parse(url, '', requiresKey: needsKey);
          if (route != null && protocol.acceptsEndpoint(route.endpoint)) {
            routes[protocol] = route;
          }
        }
      } on FormatException {
        // A damaged preference must not configure another route or prevent startup.
      }
    }
    return routes;
  }

  Future<bool> save(GatewayProtocol protocol, GatewayUpstream? route) async {
    final preferences = _preferences;
    if (preferences == null) return false;
    final key = routeKey(protocol);
    final saved = await preferences.setString(
      key,
      jsonEncode(
        route == null
            ? null
            : {
                'endpoint': route.endpoint.toString(),
                'requiresKey': route.requiresKey,
              },
      ),
    );
    return saved;
  }
}

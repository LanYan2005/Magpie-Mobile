import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'gateway_settings.dart';
import 'gateway_upstream.dart';
import 'loopback_gateway.dart';

enum GatewayState { stopped, starting, running, stopping }

enum GatewayIssue {
  invalidUpstream,
  invalidApiKey,
  saveFailed,
  missingUpstream,
  portInUse,
  startFailed,
  listenerEnded,
}

class GatewayController extends ChangeNotifier {
  GatewayController({required SharedPreferences? preferences})
    : this._(preferences, GatewayUpstream.port);

  @visibleForTesting
  GatewayController.forTest(SharedPreferences preferences, int port)
    : this._(preferences, port);

  GatewayController._(SharedPreferences? preferences, this._port)
    : _settings = GatewaySettings(preferences) {
    _routes = _settings.load();
  }

  final GatewaySettings _settings;
  final int _port;
  late final Map<GatewayProtocol, GatewayUpstream> _routes;
  LoopbackGateway? _gateway;
  GatewayState _state = GatewayState.stopped;
  GatewayIssue? _issue;
  bool _saving = false;
  bool _disposed = false;

  GatewayState get state => _state;
  GatewayIssue? get issue => _issue;
  bool get saving => _saving;
  bool get canConfigure => !_saving && _state == GatewayState.stopped;
  int get configuredCount => _routes.length;
  int get readyCount => _routes.values.where((route) => route.ready).length;
  String endpointFor(GatewayProtocol protocol) =>
      _routes[protocol]?.endpoint.toString() ?? '';
  bool requiresKey(GatewayProtocol protocol) =>
      _routes[protocol]?.requiresKey ?? true;
  bool hasKey(GatewayProtocol protocol) =>
      _routes[protocol]?.apiKey.isNotEmpty ?? false;
  String? get accessToken => _gateway?.token;
  String get address => '${GatewayUpstream.host}:${_gateway?.port ?? _port}';

  Future<bool> saveRoute(
    GatewayProtocol protocol,
    String endpoint,
    String apiKey, {
    required bool requiresKey,
    bool clearKey = false,
  }) async {
    if (_disposed || !canConfigure) return false;
    GatewayUpstream? route;
    if (endpoint.trim().isNotEmpty) {
      final url = GatewayUpstream.parseEndpoint(endpoint);
      if (url == null || !protocol.acceptsEndpoint(url)) {
        _issue = GatewayIssue.invalidUpstream;
        notifyListeners();
        return false;
      }
      final previous = _routes[protocol];
      // A blank field on an unchanged endpoint keeps only that route's key.
      // Changing endpoints never silently transfers a credential.
      final key =
          requiresKey &&
              !clearKey &&
              apiKey.trim().isEmpty &&
              url == previous?.endpoint
          ? previous?.apiKey ?? ''
          : apiKey.trim();
      route = GatewayUpstream.parse(endpoint, key, requiresKey: requiresKey);
      if (route == null) {
        _issue = GatewayIssue.invalidApiKey;
        notifyListeners();
        return false;
      }
    }
    _saving = true;
    _issue = null;
    notifyListeners();
    try {
      if (!await _settings.save(protocol, route)) {
        _issue = GatewayIssue.saveFailed;
        return false;
      }
      if (_disposed) return false;
      if (route == null) {
        _routes.remove(protocol);
      } else {
        _routes[protocol] = route;
      }
      return true;
    } on Exception {
      _issue = GatewayIssue.saveFailed;
      return false;
    } finally {
      _saving = false;
      if (!_disposed) notifyListeners();
    }
  }

  Future<bool> start() async {
    if (_disposed || !canConfigure) return false;
    if (_routes.isEmpty) {
      _issue = GatewayIssue.missingUpstream;
      notifyListeners();
      return false;
    }
    _state = GatewayState.starting;
    _issue = null;
    notifyListeners();
    try {
      final gateway = await LoopbackGateway.start(_routes, port: _port);
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
      // EADDRINUSE on Linux/Android, Darwin and Windows respectively.
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
    _routes.clear();
    if (gateway != null) unawaited(gateway.stop());
    super.dispose();
  }
}

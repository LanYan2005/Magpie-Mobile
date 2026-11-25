import 'package:flutter/material.dart';

import '../core/magpie_l10n.dart';
import '../core/magpie_motion.dart';
import '../core/magpie_theme.dart';
import '../gateway/gateway_controller.dart';
import '../gateway/gateway_presets.dart';
import '../gateway/gateway_scope.dart';
import '../gateway/gateway_upstream.dart';
import '../widgets/app_canvas.dart';
import '../widgets/primitives.dart';

class GatewayRouteList extends StatelessWidget {
  const GatewayRouteList({super.key});

  @override
  Widget build(BuildContext context) {
    final gateway = GatewayScope.of(context);
    return Column(
      children: [
        for (final protocol in GatewayProtocol.values)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _RouteRow(gateway: gateway, protocol: protocol),
          ),
      ],
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.gateway, required this.protocol});

  final GatewayController gateway;
  final GatewayProtocol protocol;

  @override
  Widget build(BuildContext context) {
    final endpoint = gateway.endpointFor(protocol);
    final configured = endpoint.isNotEmpty;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      child: ListTile(
        key: ValueKey('gateway-route-${protocol.name}'),
        title: Text(protocol.label),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_status(context, configured)),
            if (configured)
              Text(endpoint, maxLines: 2, overflow: TextOverflow.ellipsis),
          ],
        ),
        isThreeLine: configured,
        trailing: const Icon(Icons.chevron_right_rounded),
        enabled: gateway.canConfigure,
        onTap: gateway.canConfigure
            ? () => Navigator.of(context).push<void>(
                MagpiePageRoute<void>(
                  context,
                  builder: (_) => _RouteEditor(protocol),
                ),
              )
            : null,
      ),
    );
  }

  String _status(BuildContext context, bool configured) {
    if (!configured) {
      return context.tr('未配置', 'Not configured');
    }
    if (!gateway.requiresKey(protocol)) {
      return context.tr(
        '已配置 · 无供应商认证',
        'Configured · no provider authentication',
      );
    }
    return gateway.hasKey(protocol)
        ? context.tr('已配置 · 已载入密钥', 'Configured · key loaded')
        : context.tr('已配置 · 待输入密钥', 'Configured · key required');
  }
}

class _RouteEditor extends StatefulWidget {
  const _RouteEditor(this.protocol);

  final GatewayProtocol protocol;

  @override
  State<_RouteEditor> createState() => _RouteEditorState();
}

class _RouteEditorState extends State<_RouteEditor> {
  TextEditingController? _endpoint;
  final _key = TextEditingController();
  late bool _requiresKey;
  GatewayIssue? _saveIssue;
  bool _clearKey = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_endpoint != null) return;
    final gateway = GatewayScope.of(context);
    _endpoint = TextEditingController(
      text: gateway.endpointFor(widget.protocol),
    );
    _requiresKey = gateway.requiresKey(widget.protocol);
  }

  @override
  void dispose() {
    _endpoint?.dispose();
    _key.dispose();
    super.dispose();
  }

  Future<void> _save(GatewayController gateway, {bool remove = false}) async {
    FocusScope.of(context).unfocus();
    final ok = await gateway.saveRoute(
      widget.protocol,
      remove ? '' : _endpoint!.text,
      _requiresKey ? _key.text : '',
      requiresKey: _requiresKey,
      clearKey: _clearKey,
    );
    if (!mounted) return;
    if (ok) {
      _key.clear();
      Navigator.of(context).pop();
    } else {
      setState(() => _saveIssue = gateway.issue);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gateway = GatewayScope.of(context);
    final protocol = widget.protocol;
    final presets = GatewayPreset.official.where((item) => item.protocol == protocol);
    final endpointHint = switch (protocol) {
      GatewayProtocol.gemini => '/v1beta',
      _ => protocol.inboundPath,
    };
    final issue = switch (_saveIssue) {
      GatewayIssue.invalidUpstream => context.tr(
        '填写 HTTPS 地址，或其他端口的 HTTP 127.0.0.1。不带凭据、查询参数或片段。',
        'Use HTTPS, or HTTP 127.0.0.1 on another port. Omit URL credentials, queries and fragments.',
      ),
      GatewayIssue.invalidApiKey => context.tr(
        '供应商密钥格式无效，或它出现在地址中。',
        'The provider key is invalid or included in the URL.',
      ),
      GatewayIssue.saveFailed => context.tr(
        '保存路由失败。',
        'Could not save the route.',
      ),
      _ => null,
    };
    return AppCanvas(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: pagePadding,
            children: [
              PageTopBar(
                title: protocol.label,
                onBack: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 16),
              TextField(
                key: const ValueKey('gateway-route-endpoint'),
                controller: _endpoint,
                enabled: gateway.canConfigure,
                keyboardType: TextInputType.url,
                autocorrect: false,
                enableSuggestions: false,
                decoration: InputDecoration(
                  labelText: protocol == GatewayProtocol.gemini
                      ? context.tr(
                          '上游带版本的 API 根地址',
                          'Versioned upstream API root',
                        )
                      : context.tr('上游完整端点', 'Full upstream endpoint'),
                  hintText: 'https://api.example.com$endpointHint',
                ),
              ),
              for (final preset in presets) ...[
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: !gateway.canConfigure
                        ? null
                        : () {
                            _endpoint!.text = preset.endpoint;
                            _key.clear();
                            setState(() {
                              _requiresKey = true;
                              _clearKey = true;
                            });
                          },
                    child: Text(
                      context.tr(
                        '填入 ${preset.provider} 端点',
                        'Use ${preset.provider} endpoint',
                      ),
                    ),
                  ),
                ),
                SelectableText(
                  preset.source,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (presets.isEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    '此协议暂无已核实的预设。请填写服务方给出的完整地址；不推断兼容端点或专有行为。',
                    'No verified preset for this protocol. Enter the endpoint supplied by your provider; compatibility routes and proprietary behavior are not inferred.',
                  ),
                ),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _requiresKey,
                title: Text(
                  context.tr(
                    '上游需要供应商 API 密钥',
                    'Upstream requires a provider API key',
                  ),
                ),
                onChanged: gateway.canConfigure
                    ? (value) => setState(() => _requiresKey = value)
                    : null,
              ),
              if (_requiresKey) ...[
                TextField(
                  key: const ValueKey('gateway-route-key'),
                  controller: _key,
                  enabled: gateway.canConfigure,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: context.tr('供应商 API 密钥', 'Provider API key'),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    '密钥仅保留在本次应用进程。已有密钥在地址不变时留空即可保留；切换地址后请重新输入。',
                    'Keys stay in this app process. Leave blank to retain a loaded key for the same address; re-enter it after changing the address.',
                  ),
                ),
                if (gateway.hasKey(protocol))
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      context.tr(
                        '留空时清除已有密钥',
                        'Clear existing key when left blank',
                      ),
                    ),
                    value: _clearKey,
                    onChanged: gateway.canConfigure
                        ? (value) => setState(() => _clearKey = value ?? false)
                        : null,
                  ),
              ],
              if (issue != null) ...[
                const SizedBox(height: 8),
                Semantics(
                  liveRegion: true,
                  child: Text(
                    issue,
                    style: TextStyle(color: context.magpie.amber),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                children: [
                  FilledButton(
                    key: const ValueKey('gateway-route-save'),
                    onPressed: gateway.canConfigure
                        ? () => _save(gateway)
                        : null,
                    child: Text(context.tr('保存路由', 'Save route')),
                  ),
                  if (gateway.endpointFor(protocol).isNotEmpty)
                    OutlinedButton(
                      onPressed: gateway.canConfigure
                          ? () => _save(gateway, remove: true)
                          : null,
                      child: Text(context.tr('移除路由', 'Remove route')),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

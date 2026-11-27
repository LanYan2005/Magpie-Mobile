import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/magpie_l10n.dart';
import '../core/magpie_tokens.dart';
import '../gateway/gateway_controller.dart';
import '../gateway/gateway_scope.dart';
import '../gateway/gateway_upstream.dart';
import '../widgets/primitives.dart';

class GatewayPage extends StatelessWidget {
  const GatewayPage({super.key});

  @override
  Widget build(BuildContext context) => SafeArea(
    bottom: false,
    child: SingleChildScrollView(
      key: const PageStorageKey('gateway-page-scroll'),
      padding: pagePadding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  context.l10n.navigationLabel(MagpieSection.gateway),
                  style: TextStyle(
                    color: context.tokens.fg,
                    fontSize: MagpieType.base,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.l10n.gatewayDescription,
                style: TextStyle(
                  color: context.tokens.fg2,
                  fontSize: MagpieType.rowSub,
                ),
              ),
              const SizedBox(height: 8),
              const _GatewayCard(),
            ],
          ),
        ),
      ),
    ),
  );
}

class _GatewayCard extends StatelessWidget {
  const _GatewayCard();

  @override
  Widget build(BuildContext context) {
    final gateway = GatewayScope.of(context);
    final tokens = context.tokens;
    final t = context.tr;
    final running = gateway.state == GatewayState.running;
    final (status, color) = switch (gateway.state) {
      GatewayState.stopped when gateway.loading => (
        t('正在加载网关配置…', 'Loading gateway settings…'),
        tokens.fg2,
      ),
      GatewayState.stopped when gateway.saving => (
        t('正在保存网关配置…', 'Saving gateway settings…'),
        tokens.fg2,
      ),
      GatewayState.stopped => (
        t('本机网关已停止', 'Local gateway is stopped'),
        tokens.amber,
      ),
      GatewayState.starting => (
        t('正在启动本机网关…', 'Starting local gateway…'),
        tokens.fg2,
      ),
      GatewayState.running => (
        t('本机网关正在运行', 'Local gateway is running'),
        tokens.green,
      ),
      GatewayState.stopping => (
        t('正在停止本机网关…', 'Stopping local gateway…'),
        tokens.fg2,
      ),
    };
    final address = 'http://${gateway.address}';
    final routeCount = GatewayProtocol.values.length;
    final issue = gateway.loadIssue ?? gateway.issue;
    final divider = Divider(height: 1, thickness: 1, color: tokens.line2);
    return MagpieList(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MagpieMetrics.rowPadH,
            vertical: MagpieMetrics.rowPadV,
          ),
          child: OverflowBar(
            spacing: 11,
            overflowSpacing: 4,
            overflowAlignment: OverflowBarAlignment.end,
            alignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconTile(
                    icon: Icons.hub_outlined,
                    size: 28,
                    iconSize: 16,
                    background: tokens.pill,
                    foreground: tokens.fg2,
                    radius: 7,
                  ),
                  const SizedBox(width: MagpieMetrics.rowGap),
                  Flexible(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.gatewayListener,
                          style: TextStyle(
                            color: tokens.fg,
                            fontSize: MagpieType.rowName,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            status,
                            style: TextStyle(
                              color: color,
                              fontSize: MagpieType.rowSub,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              TextButton(
                key: const ValueKey('gateway-toggle-button'),
                onPressed: running
                    ? gateway.stop
                    : gateway.canStart &&
                          gateway.loadIssue != GatewayIssue.catalogLoadFailed
                    ? gateway.start
                    : null,
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 44),
                  foregroundColor: running ? tokens.fg : tokens.accent,
                  backgroundColor: running ? tokens.pill : tokens.accentSoft,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      MagpieMetrics.fieldRadius,
                    ),
                  ),
                  textStyle: const TextStyle(
                    fontSize: MagpieType.field,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: Text(
                  running
                      ? t('停止本机网关', 'Stop local gateway')
                      : t('启动本机网关', 'Start local gateway'),
                ),
              ),
            ],
          ),
        ),
        divider,
        _GatewayValueRow(
          label: t('监听地址（仅本机）', 'Listener address (loopback only)'),
          value: Text(
            address,
            style: TextStyle(color: tokens.fg, fontSize: MagpieType.field),
          ),
          copy: running
              ? (address, t('复制监听地址', 'Copy listener address'))
              : null,
        ),
        if (gateway.accessToken case final token?) ...[
          divider,
          _GatewayValueRow(
            label: t(
              '本机客户端密钥（仅此次网关启动有效）',
              'Local client key (this gateway run only)',
            ),
            value: SelectableText(
              token,
              key: const ValueKey('gateway-access-token'),
              style: TextStyle(color: tokens.fg, fontSize: MagpieType.field),
            ),
            copy: (token, t('复制本机密钥', 'Copy local client key')),
            copyKey: const ValueKey('copy-gateway-access-token'),
          ),
        ],
        divider,
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: MagpieMetrics.rowPadH,
            vertical: 8,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              t(
                '${gateway.configuredCount}/$routeCount 种协议路由已配置 · ${gateway.readyCount} 条就绪',
                '${gateway.configuredCount}/$routeCount protocol routes configured · ${gateway.readyCount} ready',
              ),
              style: TextStyle(color: tokens.fg2, fontSize: MagpieType.rowSub),
            ),
          ),
        ),
        if (issue != null) ...[
          divider,
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MagpieMetrics.rowPadH,
              vertical: 8,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Semantics(
                liveRegion: true,
                child: Text(
                  context.l10n.gatewayIssue(issue),
                  style: TextStyle(
                    color: tokens.amber,
                    fontSize: MagpieType.rowSub,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _GatewayValueRow extends StatelessWidget {
  const _GatewayValueRow({
    required this.label,
    required this.value,
    this.copy,
    this.copyKey,
  });

  final String label;
  final Widget value;
  final (String, String)? copy;
  final Key? copyKey;

  @override
  Widget build(BuildContext context) {
    final copyData = copy;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MagpieMetrics.rowPadH,
        vertical: MagpieMetrics.rowPadV,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.tokens.fg2,
                    fontSize: MagpieType.rowSub,
                  ),
                ),
                const SizedBox(height: 2),
                value,
              ],
            ),
          ),
          if (copyData != null)
            IconButton(
              key: copyKey,
              tooltip: copyData.$2,
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: copyData.$1));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(context.tr('已复制', 'Copied'))),
                  );
                }
              },
              icon: Icon(
                Icons.copy_rounded,
                size: 15,
                color: context.tokens.ctlFg,
              ),
              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            ),
        ],
      ),
    );
  }
}

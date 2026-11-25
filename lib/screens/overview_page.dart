import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/magpie_l10n.dart';
import '../core/magpie_theme.dart';
import '../data/demo_data.dart';
import '../gateway/gateway_controller.dart';
import '../gateway/gateway_scope.dart';
import '../models/magpie_models.dart';
import '../state/magpie_store.dart';
import '../widgets/app_canvas.dart';
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';

class OverviewPage extends StatelessWidget {
  const OverviewPage({
    required this.onNavigate,
    required this.onOpenSettings,
    super.key,
  });

  final ValueChanged<int> onNavigate;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final store = MagpieScope.of(context);

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: dockPagePadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _OverviewTopBar(onOpenSettings: onOpenSettings),
                const SizedBox(height: 24),
                Semantics(
                  header: true,
                  child: Text(
                    context.tr('概览', 'Overview'),
                    style: Theme.of(context).textTheme.displayLarge,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.tr(
                    '管理本机网关，预览 Providers、Agents、Skills 和 MCP。',
                    'Manage the local gateway and preview Providers, Agents, Skills, and MCP.',
                  ),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 22),
                const _GatewayCard(),
                const SizedBox(height: 14),
                _InventoryStrip(store: store, onNavigate: onNavigate),
                const SizedBox(height: 28),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: SectionHeader(
                        title: context.tr('近期信息', 'Recent activity'),
                        subtitle: context.tr(
                          '本地演示事件，不会同步到服务端',
                          'Local demo events; never synced to a server',
                        ),
                      ),
                    ),
                    DemoBadge(label: context.tr('本地', 'Local')),
                  ],
                ),
                const SizedBox(height: 12),
                const _ActivityCard(),
                const SizedBox(height: 18),
                _PrototypeNote(onOpenBoundary: () => showSandboxSheet(context)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OverviewTopBar extends StatelessWidget {
  const _OverviewTopBar({required this.onOpenSettings});

  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: BrandLockup()),
        DemoBadge(label: context.tr('演示工作区', 'Demo workspace')),
        const SizedBox(width: 8),
        RoundIconButton(
          key: const ValueKey('open-settings-button'),
          icon: Icons.tune_rounded,
          tooltip: context.tr('设置', 'Settings'),
          onPressed: onOpenSettings,
        ),
      ],
    );
  }
}

class _GatewayCard extends StatelessWidget {
  const _GatewayCard();

  @override
  Widget build(BuildContext context) {
    final gateway = GatewayScope.of(context);
    final running = gateway.state == GatewayState.running;
    final status = switch (gateway.state) {
      GatewayState.stopped => context.tr('本机网关已停止', 'Local gateway is stopped'),
      GatewayState.starting => context.tr(
        '正在启动本机网关…',
        'Starting local gateway…',
      ),
      GatewayState.running => context.tr(
        '本机网关正在运行',
        'Local gateway is running',
      ),
      GatewayState.stopping => context.tr(
        '正在停止本机网关…',
        'Stopping local gateway…',
      ),
    };
    final issue = switch (gateway.issue) {
      GatewayIssue.invalidUpstream => context.tr(
        '使用 HTTPS 或其他端口上的 HTTP 127.0.0.1。地址里不要包含凭据、查询参数或片段。',
        'Use HTTPS or HTTP 127.0.0.1 on a different port. Remove URL credentials, query parameters, and fragments.',
      ),
      GatewayIssue.invalidApiKey => context.tr(
        'API 密钥格式无效。',
        'Invalid API key format.',
      ),
      GatewayIssue.saveFailed => context.tr(
        '保存上游配置失败，请重试。',
        'Could not save the upstream. Try again.',
      ),
      GatewayIssue.missingUpstream => context.tr(
        '请先保存上游配置。',
        'Save an upstream first.',
      ),
      GatewayIssue.portInUse => context.tr(
        '端口 3425 已被占用。',
        'Port 3425 is already in use.',
      ),
      GatewayIssue.startFailed => context.tr(
        '监听 127.0.0.1:3425 失败。',
        'Could not listen on 127.0.0.1:3425.',
      ),
      GatewayIssue.listenerEnded => context.tr(
        '本机监听已意外结束。',
        'The local listener ended unexpectedly.',
      ),
      null => null,
    };
    final colors = context.magpie;
    final type = Theme.of(context).textTheme;
    return SurfaceCard(
      color: colors.gatewaySurface,
      radius: MagpieShape.panel,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconTile(
                icon: Icons.hub_outlined,
                size: 34,
                iconSize: 17,
                background: colors.mint,
                foreground: colors.jadeDeep,
                radius: 11,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Gateway',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: type.titleMedium,
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: DemoBadge(
                  compact: true,
                  label: context.tr('仅本机', 'Loopback only'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 19),
          Text(status, style: type.headlineMedium),
          const SizedBox(height: 4),
          Text('http://${gateway.address}', style: type.bodyMedium),
          const SizedBox(height: 12),
          Text(
            context.tr(
              '${gateway.configuredCount}/5 种协议路由已配置 · ${gateway.readyCount} 条就绪；不做跨协议转换或账号路由',
              '${gateway.configuredCount}/5 protocol routes configured · ${gateway.readyCount} ready; no cross-protocol translation or account-based routing',
            ),
            style: type.bodyMedium,
          ),
          if (gateway.accessToken case final token?) ...[
            const SizedBox(height: 8),
            Text(
              context.tr(
                '本机客户端密钥（仅此次网关启动有效）',
                'Local client key (this gateway run only)',
              ),
            ),
            Row(
              children: [
                Expanded(
                  child: SelectableText(
                    token,
                    key: const ValueKey('gateway-access-token'),
                    style: type.bodySmall,
                  ),
                ),
                IconButton(
                  key: const ValueKey('copy-gateway-access-token'),
                  tooltip: context.tr('复制本机密钥', 'Copy local client key'),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: token));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(context.tr('已复制', 'Copied')),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded),
                ),
              ],
            ),
          ],
          if (issue != null) ...[
            const SizedBox(height: 8),
            Semantics(
              liveRegion: true,
              child: Text(issue, style: TextStyle(color: context.magpie.amber)),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                key: const ValueKey('gateway-toggle-button'),
                onPressed: running
                    ? gateway.stop
                    : gateway.canConfigure
                    ? gateway.start
                    : null,
                icon: Icon(
                  running ? Icons.stop_rounded : Icons.play_arrow_rounded,
                ),
                label: Text(
                  running
                      ? context.tr('停止本机网关', 'Stop local gateway')
                      : context.tr('启动本机网关', 'Start local gateway'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InventoryStrip extends StatelessWidget {
  const _InventoryStrip({required this.store, required this.onNavigate});

  final MagpieStore store;
  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        value: '${store.providers.length}',
        label: 'Providers',
        icon: Icons.layers_outlined,
        target: 1,
      ),
      (
        value: '${store.agents.length}',
        label: 'Agents',
        icon: Icons.auto_awesome_outlined,
        target: 2,
      ),
      (
        value: '${store.skills.length}',
        label: 'Skills',
        icon: Icons.extension_outlined,
        target: 3,
      ),
      (
        value: '${store.mcpServers.length}',
        label: 'MCP',
        icon: Icons.hub_outlined,
        target: 3,
      ),
    ];

    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            Expanded(
              child: PressableSurface(
                borderRadius: BorderRadius.circular(18),
                onTap: () => onNavigate(items[i].target),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Column(
                    children: [
                      Icon(
                        items[i].icon,
                        size: 17,
                        color: context.magpie.jade.withValues(alpha: 0.8),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        items[i].value,
                        style: TextStyle(
                          color: context.magpie.ink,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        items[i].label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: context.magpie.muted,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (i != items.length - 1)
              Container(width: 1, height: 38, color: context.magpie.line),
          ],
        ],
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard();

  @override
  Widget build(BuildContext context) {
    final activities = DemoData.localizedActivity(context.l10n);

    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < activities.length; i++) ...[
            _ActivityRow(activity: activities[i]),
            if (i != activities.length - 1)
              const Padding(
                padding: EdgeInsets.only(left: 50),
                child: Divider(height: 1),
              ),
          ],
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});

  final ActivityEvent activity;

  @override
  Widget build(BuildContext context) {
    final (icon, color, background) = switch (activity.tone) {
      ActivityTone.gateway => (
        Icons.hub_outlined,
        context.magpie.jade,
        context.magpie.mintSoft,
      ),
      ActivityTone.provider => (
        Icons.cloud_done_outlined,
        context.magpie.cobalt,
        context.magpie.cobaltSoft,
      ),
      ActivityTone.agent => (
        Icons.auto_awesome_outlined,
        context.magpie.amber,
        context.magpie.amberSoft,
      ),
      ActivityTone.resource => (
        Icons.extension_outlined,
        context.magpie.jade,
        context.magpie.mintSoft,
      ),
    };

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconTile(
            icon: icon,
            size: 36,
            iconSize: 16,
            radius: 12,
            background: background,
            foreground: color,
            borderColor: color.withValues(alpha: 0.08),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: TextStyle(
                    color: context.magpie.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  activity.detail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            activity.time,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 9.5,
              color: context.magpie.faint,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrototypeNote extends StatelessWidget {
  const _PrototypeNote({required this.onOpenBoundary});

  final VoidCallback onOpenBoundary;

  @override
  Widget build(BuildContext context) {
    return InfoBanner(
      icon: Icons.science_outlined,
      title: context.tr('其他功能仍是原型', 'Other features are prototypes'),
      body: context.tr(
        '网关运行在当前应用进程中。Agent、Skills 和 MCP 页面仍使用演示数据。',
        'The gateway runs in the app process. Agents, Skills, and MCP still use demo data.'
      ),
      onTap: onOpenBoundary,
      actionLabel: context.tr(
        '查看沙箱与权限边界',
        'View sandbox & permission boundary',
      ),
      tint: context.magpie.paper,
      accent: context.magpie.inkSoft,
    );
  }
}

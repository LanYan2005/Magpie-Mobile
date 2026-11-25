import 'package:flutter/material.dart';

import '../core/magpie_l10n.dart';
import '../core/magpie_theme.dart';
import '../data/demo_data.dart';
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
                    '在本地预览 Gateway、Providers、Agents、Skills 和 MCP。',
                    'Preview Gateway, Providers, Agents, Skills, and MCP locally.',
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
              Expanded(child: Text('Gateway', style: type.titleMedium)),
              const DemoBadge(),
            ],
          ),
          const SizedBox(height: 19),
          Text(
            context.tr('未连接 Magpie 服务', 'Not connected to Magpie service'),
            style: type.headlineMedium,
          ),
          const SizedBox(height: 4),
          Text(
            context.tr('演示状态：Gateway 运行正常', 'Demo status: Gateway is healthy'),
            style: type.bodyMedium,
          ),
          const SizedBox(height: 16),
          SurfaceCard(
            color: colors.paper,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
            radius: 19,
            shadow: false,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final columns =
                    constraints.maxWidth >=
                        MediaQuery.textScalerOf(context).scale(166)
                    ? 3
                    : 2;
                return Wrap(
                  runSpacing: 10,
                  children: [
                    for (final (value, label) in [
                      ('42 ms', context.tr('模拟延迟', 'Simulated latency')),
                      ('3d 14h', context.tr('示例运行时长', 'Sample uptime')),
                      (
                        context.tr('2 分钟前', '2 min ago'),
                        context.tr('示例更新时间', 'Sample updated'),
                      ),
                    ])
                      SizedBox(
                        width: constraints.maxWidth / columns - 0.01,
                        child: MetricBlock(
                          value: value,
                          label: label,
                          align: CrossAxisAlignment.center,
                          valueSize: 15,
                        ),
                      ),
                  ],
                );
              },
            ),
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
      title: context.tr('这是一个 UI 原型', 'This is a UI prototype'),
      body: context.tr(
        '所有服务状态、指标与操作均为本地演示；不会连接 Magpie 服务、'
        '保存凭据或访问文件系统。',
        'All service states, metrics, and actions are local demos; '
            'nothing connects to the Magpie service, stores credentials, '
            'or touches the filesystem.',
      ),
      onTap: onOpenBoundary,
      actionLabel: context.tr('查看沙箱与权限边界', 'View sandbox & permission boundary'),
      tint: context.magpie.paper,
      accent: context.magpie.inkSoft,
    );
  }
}

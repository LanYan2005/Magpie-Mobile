import 'package:flutter/material.dart';

import '../core/domain_style.dart';
import '../core/magpie_l10n.dart';
import '../core/magpie_motion.dart';
import '../core/magpie_theme.dart';
import '../data/demo_data.dart';
import '../models/magpie_models.dart';
import '../state/magpie_store.dart';
import '../widgets/primitives.dart';
import 'provider_detail_page.dart';
import 'provider_editor_page.dart';

class ProvidersPage extends StatefulWidget {
  const ProvidersPage({super.key});

  @override
  State<ProvidersPage> createState() => _ProvidersPageState();
}

class _ProvidersPageState extends State<ProvidersPage>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  int _filter = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProviderConfig> _filtered(List<ProviderConfig> providers) {
    final query = _query.trim().toLowerCase();
    return providers.where((provider) {
      final matchesQuery =
          query.isEmpty ||
          provider.name.toLowerCase().contains(query) ||
          provider.localizedName(context.l10n).toLowerCase().contains(query) ||
          provider.endpoint.toLowerCase().contains(query) ||
          provider.kind.label.toLowerCase().contains(query) ||
          context.l10n
              .providerKind(provider.kind)
              .toLowerCase()
              .contains(query);
      final matchesFilter = switch (_filter) {
        1 => provider.health == ProviderHealth.online,
        2 => provider.health != ProviderHealth.online,
        _ => true,
      };
      return matchesQuery && matchesFilter;
    }).toList();
  }

  Future<void> _openEditor() async {
    await Navigator.of(context).push(
      MagpiePageRoute<void>(
        context,
        builder: (_) => const ProviderEditorPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final store = MagpieScope.of(context);
    final providers = store.providers;
    final filtered = _filtered(providers);

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
                PageHeader(
                  title: context.tr('供应商', 'Providers'),
                  subtitle: context.tr(
                    '统一管理模型服务、路由与可用模型。所有连接状态均为界面演示。',
                    'Manage model services, routes, and available models. All connection statuses are for display only.',
                  ),
                  action: RoundIconButton(
                    key: const ValueKey('add-provider-button'),
                    icon: Icons.add_rounded,
                    tooltip: context.tr('添加供应商', 'Add provider'),
                    onPressed: _openEditor,
                    filled: true,
                    size: 46,
                  ),
                ),
                const SizedBox(height: 22),
                _ProviderSummary(store: store),
                const SizedBox(height: 16),
                _SearchField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _query = value),
                  onClear: () {
                    _searchController.clear();
                    setState(() => _query = '');
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoicePill(
                        label: context.tr('全部', 'All'),
                        count: providers.length,
                        selected: _filter == 0,
                        onTap: () => setState(() => _filter = 0),
                      ),
                      const SizedBox(width: 7),
                      ChoicePill(
                        label: context.tr('在线', 'Online'),
                        count: store.onlineProviderCount,
                        selected: _filter == 1,
                        onTap: () => setState(() => _filter = 1),
                      ),
                      const SizedBox(width: 7),
                      ChoicePill(
                        label: context.tr('需处理', 'Needs attention'),
                        count: store.providersNeedingSetup,
                        selected: _filter == 2,
                        onTap: () => setState(() => _filter = 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                if (filtered.isEmpty)
                  SurfaceCard(
                    padding: EdgeInsets.zero,
                    child: EmptyState(
                      icon: Icons.search_off_rounded,
                      title: context.tr('没有匹配的供应商', 'No matching providers'),
                      body: context.tr(
                        '尝试更换关键词，或添加一个新的演示供应商。',
                        'Try another search term, or add a demo provider.',
                      ),
                      action: OutlinedButton.icon(
                        onPressed: _openEditor,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: Text(context.tr('添加供应商', 'Add provider')),
                      ),
                    ),
                  )
                else
                  for (var i = 0; i < filtered.length; i++) ...[
                    ProviderCard(
                      provider: filtered[i],
                      onTap: () {
                        Navigator.of(context).push(
                          MagpiePageRoute<void>(
                            context,
                            builder: (_) =>
                                ProviderDetailPage(providerId: filtered[i].id),
                          ),
                        );
                      },
                    ),
                    if (i != filtered.length - 1) const SizedBox(height: 10),
                  ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _openEditor,
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(context.tr('添加供应商', 'Add provider')),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr(
                    '演示数据保存在当前会话；应用重启后将恢复初始示例。',
                    'Demo data is kept for this session and resets to the initial examples on restart.',
                  ),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10.5,
                    color: context.magpie.faint,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProviderSummary extends StatelessWidget {
  const _ProviderSummary({required this.store});

  final MagpieStore store;

  @override
  Widget build(BuildContext context) {
    final totalModels = store.providers.fold<int>(
      0,
      (sum, provider) => sum + provider.models.length,
    );

    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: MetricBlock(
              value: '${store.providers.length}',
              label: context.tr('全部供应商', 'Providers'),
              align: CrossAxisAlignment.center,
              valueSize: 22,
            ),
          ),
          const _SummaryDivider(),
          Expanded(
            child: MetricBlock(
              value: '${store.onlineProviderCount}',
              label: context.tr('演示在线', 'Online (demo)'),
              color: context.magpie.jade,
              align: CrossAxisAlignment.center,
              valueSize: 22,
            ),
          ),
          const _SummaryDivider(),
          Expanded(
            child: MetricBlock(
              value: '$totalModels',
              label: context.tr('可用模型', 'Available models'),
              align: CrossAxisAlignment.center,
              valueSize: 22,
            ),
          ),
          const _SummaryDivider(),
          Expanded(
            child: MetricBlock(
              value: '${store.providersNeedingSetup}',
              label: context.tr('需处理', 'Needs attention'),
              color: context.magpie.amber,
              align: CrossAxisAlignment.center,
              valueSize: 22,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryDivider extends StatelessWidget {
  const _SummaryDivider();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 34, color: context.magpie.line);
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: context.tr('搜索名称、类型或端点', 'Search name, type, or endpoint'),
        prefixIcon: Icon(
          Icons.search_rounded,
          size: 19,
          color: context.magpie.faint,
        ),
        suffixIcon: controller.text.isEmpty
            ? null
            : IconButton(
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, size: 17),
                color: context.magpie.faint,
                tooltip: context.tr('清除', 'Clear'),
              ),
        contentPadding: const EdgeInsets.symmetric(vertical: 13),
      ),
    );
  }
}

class ProviderCard extends StatelessWidget {
  const ProviderCard({required this.provider, required this.onTap, super.key});

  final ProviderConfig provider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = providerAccent(context, provider.kind);
    final soft = providerSoft(context, provider.kind);
    final statusColor = healthColor(context, provider.health);

    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'provider-icon-${provider.id}',
                child: Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: soft,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: accent.withValues(alpha: 0.1)),
                  ),
                  child: Icon(
                    providerIcon(provider.kind),
                    size: 21,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            provider.localizedName(context.l10n),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(
                              context,
                            ).textTheme.titleMedium?.copyWith(fontSize: 14.5),
                          ),
                        ),
                        if (provider.isDefaultRoute) ...[
                          const SizedBox(width: 6),
                          TagChip(
                            label: context.tr('默认', 'Default'),
                            color: context.magpie.jade,
                            background: context.magpie.mintSoft,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.l10n.providerKind(provider.kind),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 10.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              StatusPill(
                label: context.l10n.providerHealth(provider.health),
                color: statusColor,
                background: healthBackground(context, provider.health),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.link_rounded, size: 13, color: context.magpie.faint),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  provider.endpoint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: context.magpie.muted,
                    fontSize: 10.5,
                    height: 1.3,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                provider.latencyMs == null
                    ? context.tr('无演示延迟', 'No demo latency')
                    : '${provider.latencyMs} ms',
                style: TextStyle(
                  color: provider.latencyMs == null
                      ? context.magpie.faint
                      : context.magpie.inkSoft,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    for (final model in provider.models.take(2))
                      TagChip(
                        label: model,
                        color: context.magpie.muted,
                        background: context.magpie.canvas,
                        borderColor: context.magpie.line,
                      ),
                    if (provider.models.length > 2)
                      TagChip(
                        label: '+${provider.models.length - 2}',
                        color: context.magpie.muted,
                        background: context.magpie.canvas,
                        borderColor: context.magpie.line,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: context.magpie.faint,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

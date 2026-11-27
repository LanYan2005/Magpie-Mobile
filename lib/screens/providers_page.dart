import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../core/magpie_l10n.dart';
import '../core/magpie_tokens.dart';
import '../gateway/gateway_controller.dart';
import '../gateway/gateway_scope.dart';
import '../widgets/magpie_icon.dart';
import '../widgets/primitives.dart';
import '../widgets/provider_icon.dart';
import 'provider_detail_page.dart';
import 'provider_directory_page.dart';

class ProvidersPage extends StatefulWidget {
  const ProvidersPage({super.key});

  @override
  State<ProvidersPage> createState() => _ProvidersPageState();
}

class _ProvidersPageState extends State<ProvidersPage> {
  final _search = TextEditingController();
  String _query = '';
  final _selected = <String>{};
  bool _selecting = false;
  bool _showDisabled = false;
  bool _hideAccounts = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _open(Widget page) async {
    await Navigator.of(
      context,
    ).push<dynamic>(MaterialPageRoute<dynamic>(builder: (_) => page));
  }

  void _showIssue(GatewayIssue issue) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.gatewayIssue(issue))));
  }

  Future<void> _import(GatewayController gateway) async {
    try {
      final file = await openFile(
        acceptedTypeGroups: const [
          XTypeGroup(
            label: 'JSON',
            extensions: ['json'],
            uniformTypeIdentifiers: ['public.json'],
          ),
        ],
      );
      if (file == null || !mounted) return;
      if (await file.length() > 1024 * 1024) {
        if (mounted) _showIssue(GatewayIssue.invalidImport);
        return;
      }
      final json = await file.readAsString();
      if (!mounted) return;
      final ok = await gateway.importProviders(json);
      if (mounted && !ok) {
        _showIssue(gateway.issue ?? GatewayIssue.invalidImport);
      }
    } on Exception {
      if (mounted) _showIssue(GatewayIssue.invalidImport);
    }
  }

  Future<void> _apply(
    GatewayController gateway,
    Set<String> ids,
    bool enabled,
  ) async {
    final ok = await gateway.setProvidersEnabled(ids, enabled);
    if (!mounted) return;
    if (!ok) {
      _showIssue(gateway.issue ?? GatewayIssue.saveFailed);
    } else if (_selecting) {
      setState(_selected.clear);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gateway = GatewayScope.of(context);
    final providers = gateway.providers.where((provider) {
      final q = _query.trim().toLowerCase();
      return q.isEmpty ||
          provider.name.toLowerCase().contains(q) ||
          provider.hosts.any((host) => host.toLowerCase().contains(q)) ||
          provider.accounts.any(
            (account) =>
                account.models.any(
                  (model) => model.toLowerCase().contains(q),
                ) ||
                account.protocol.label.toLowerCase().contains(q),
          );
    }).toList();
    final canEdit = gateway.canConfigure;
    final disabled = providers.where((provider) => !provider.enabled).toList();
    final enabled = providers.where((provider) => provider.enabled).toList();
    final visible = [
      ...enabled,
      if (_showDisabled || _query.trim().isNotEmpty) ...disabled,
    ];

    return SafeArea(
      bottom: false,
      child: ListView(
        key: const PageStorageKey('providers-scroll'),
        padding: dockPagePadding(context),
        children: [
          PageHeader(
            title: context.tr('供应商', 'Providers'),
            subtitle: context.tr(
              '从目录添加供应商，或连接自己的 API。',
              'Add a provider from the directory or connect your own API.',
            ),
            action: FilledButton.icon(
              key: const ValueKey('provider-add'),
              onPressed: canEdit
                  ? () => _open(const ProviderDirectoryPage())
                  : null,
              icon: const MagpieIcon(MagpieGlyph.plus, size: 18),
              label: Text(context.tr('添加', 'Add')),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _search,
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              prefixIcon: const MagpieIcon(MagpieGlyph.search),
              hintText: context.tr(
                '搜索供应商、端点、协议或模型',
                'Search providers, endpoints, protocols or models',
              ),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: context.tr('清除搜索', 'Clear search'),
                      onPressed: () {
                        _search.clear();
                        setState(() => _query = '');
                      },
                      icon: const MagpieIcon(MagpieGlyph.cross),
                    ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: canEdit
                    ? () => setState(() {
                        _selecting = !_selecting;
                        _selected.clear();
                      })
                    : null,
                icon: _selecting
                    ? const MagpieIcon(MagpieGlyph.cross)
                    : const Icon(Icons.checklist),
                label: Text(
                  _selecting
                      ? context.tr('完成选择', 'Done selecting')
                      : context.tr('选择', 'Select'),
                ),
              ),
              TextButton.icon(
                onPressed: () => setState(() => _hideAccounts = !_hideAccounts),
                icon: MagpieIcon(
                  _hideAccounts ? MagpieGlyph.eye : MagpieGlyph.eyeOff,
                ),
                label: Text(
                  _hideAccounts
                      ? context.tr('显示账号', 'Show accounts')
                      : context.tr('隐藏账号', 'Hide accounts'),
                ),
              ),
              TextButton.icon(
                onPressed: canEdit ? () => _import(gateway) : null,
                icon: const Icon(Icons.file_open_outlined),
                label: Text(context.tr('导入', 'Import')),
              ),
              if (_selecting) ...[
                TextButton(
                  onPressed: canEdit && _selected.isNotEmpty
                      ? () => _apply(gateway, Set.of(_selected), true)
                      : null,
                  child: Text(context.tr('启用所选', 'Enable selected')),
                ),
                TextButton(
                  onPressed: canEdit && _selected.isNotEmpty
                      ? () => _apply(gateway, Set.of(_selected), false)
                      : null,
                  child: Text(context.tr('停用所选', 'Disable selected')),
                ),
              ],
            ],
          ),
          if (gateway.loadIssue case final issue?)
            Text(context.l10n.gatewayIssue(issue)),
          if (gateway.loading)
            const LinearProgressIndicator()
          else if (providers.isEmpty)
            MagpieList(
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: EmptyState(
                    icon: _query.isEmpty ? null : Icons.search_off_rounded,
                    iconWidget: _query.isEmpty
                        ? const MagpieIcon(MagpieGlyph.provider)
                        : null,
                    title: _query.isEmpty
                        ? context.tr('还没有供应商', 'No providers yet')
                        : context.tr('没有匹配项', 'No matches'),
                    body: _query.isEmpty
                        ? context.tr(
                            '添加供应商时一起配置首个网关账号。',
                            'Configure the first gateway account when adding a provider.',
                          )
                        : context.tr(
                            '尝试其他名称、端点、协议或模型 ID。',
                            'Try another name, endpoint, protocol or model ID.',
                          ),
                  ),
                ),
              ],
            )
          else ...[
            if (disabled.isNotEmpty)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: TextButton.icon(
                  onPressed: _query.trim().isNotEmpty
                      ? null
                      : () => setState(() => _showDisabled = !_showDisabled),
                  icon: RotatedBox(
                    quarterTurns: _showDisabled ? 1 : 0,
                    child: const MagpieIcon(MagpieGlyph.chevronRight),
                  ),
                  label: Text(
                    context.tr(
                      '已停用 (${disabled.length})',
                      'Disabled (${disabled.length})',
                    ),
                  ),
                ),
              ),
            if (visible.isNotEmpty)
              MagpieList(
                children: [
                  for (var i = 0; i < visible.length; i++) ...[
                    if (i > 0) const SoftDivider(),
                    _ProviderRow(
                      provider: visible[i],
                      selecting: _selecting,
                      selected: _selected.contains(visible[i].id),
                      onToggle: canEdit
                          ? (value) => _apply(gateway, {visible[i].id}, value)
                          : null,
                      onTap: () {
                        final id = visible[i].id;
                        if (_selecting) {
                          setState(() {
                            if (!_selected.remove(id)) _selected.add(id);
                          });
                        } else {
                          _open(
                            ProviderDetailPage(
                              providerId: id,
                              hideAccounts: _hideAccounts,
                            ),
                          );
                        }
                      },
                    ),
                  ],
                ],
              ),
          ],
          if (!gateway.canConfigure &&
              !gateway.loading &&
              gateway.loadIssue == null) ...[
            const SizedBox(height: 10),
            Text(
              context.tr(
                '编辑供应商前请停止本机网关。',
                'Stop the local gateway before editing providers.',
              ),
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _ProviderRow extends StatelessWidget {
  const _ProviderRow({
    required this.provider,
    required this.onTap,
    required this.selecting,
    required this.selected,
    required this.onToggle,
  });

  final UpstreamProvider provider;
  final VoidCallback onTap;
  final bool selecting;
  final bool selected;
  final ValueChanged<bool>? onToggle;

  @override
  Widget build(BuildContext context) {
    final protocols = provider.accounts
        .map((account) => account.protocol.label)
        .toSet();
    final models = provider.modelCount;
    final hosts = provider.hosts.join(', ');
    final subtitle = [
      if (hosts.isNotEmpty) hosts,
      context.tr('$models 个模型', '$models models'),
      if (protocols.isNotEmpty) protocols.join(' · '),
      if (provider.agentIds.isNotEmpty)
        context.tr(
          '${provider.agentIds.length} 个关联 Agent',
          '${provider.agentIds.length} linked Agents',
        ),
    ].join('  ·  ');
    return MagpieRow(
      key: ValueKey('provider-${provider.id}'),
      title: provider.name,
      subtitle: subtitle.isEmpty
          ? context.tr('尚未配置账号', 'No accounts configured')
          : subtitle,
      leading: selecting
          ? Checkbox(value: selected, onChanged: (_) => onTap())
          : ProviderIcon(
              hosts: provider.hosts,
              size: 19,
              color: provider.enabled
                  ? context.tokens.accent
                  : context.tokens.muted,
            ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!selecting)
            Semantics(
              label: context.tr(
                '启用 ${provider.name}',
                'Enable ${provider.name}',
              ),
              child: Switch.adaptive(
                value: provider.enabled,
                onChanged: onToggle,
              ),
            ),
          const SizedBox(width: 6),
          MagpieIcon(
            MagpieGlyph.chevronRight,
            color: context.tokens.faint,
            matchTextDirection: true,
          ),
        ],
      ),
      onTap: onTap,
      dense: false,
    );
  }
}

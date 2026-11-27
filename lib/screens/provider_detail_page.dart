import 'package:flutter/material.dart';

import '../core/magpie_l10n.dart';
import '../core/magpie_tokens.dart';
import '../gateway/gateway_controller.dart';
import '../gateway/gateway_scope.dart';
import '../widgets/app_canvas.dart';
import '../widgets/magpie_icon.dart';
import '../widgets/primitives.dart';
import '../widgets/provider_icon.dart';
import 'gateway_routes_page.dart';
import 'provider_editor_page.dart';

class ProviderDetailPage extends StatefulWidget {
  const ProviderDetailPage({
    required this.providerId,
    this.hideAccounts = false,
    super.key,
  });

  final String providerId;
  final bool hideAccounts;

  @override
  State<ProviderDetailPage> createState() => _ProviderDetailPageState();
}

class _ProviderDetailPageState extends State<ProviderDetailPage> {
  Future<void> _open(Widget page) async {
    await Navigator.of(
      context,
    ).push<dynamic>(MaterialPageRoute<dynamic>(builder: (_) => page));
  }

  Future<void> _editName(UpstreamProvider provider) async {
    final id = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(
        builder: (_) => ProviderEditorPage(provider: provider),
      ),
    );
    if (id != null && mounted) setState(() {});
  }

  Future<void> _remove(
    GatewayController gateway,
    ProviderAccount account,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialog) => AlertDialog(
        title: Text(context.tr('移除账号？', 'Remove account?')),
        content: Text(
          context.tr(
            '此操作会一并清除保存在系统凭据存储中的对应密钥。',
            'This also removes the associated key from system credential storage.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialog, false),
            child: Text(context.tr('取消', 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialog, true),
            child: Text(context.tr('移除', 'Remove')),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final ok = await gateway.removeAccount(widget.providerId, account.id);
      if (mounted && !ok) _showIssue(gateway);
    }
  }

  void _showIssue(GatewayController gateway) {
    final issue = gateway.issue ?? GatewayIssue.saveFailed;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(context.l10n.gatewayIssue(issue))));
  }

  @override
  Widget build(BuildContext context) {
    final gateway = GatewayScope.of(context);
    final provider = gateway.provider(widget.providerId);
    final canEdit = gateway.canConfigure;
    return AppCanvas(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: provider == null
              ? Padding(
                  padding: pagePadding,
                  child: Column(
                    children: [
                      PageTopBar(
                        title: context.tr('供应商详情', 'Provider details'),
                        onBack: () => Navigator.of(context).pop(),
                        backIcon: MagpieGlyph.back,
                      ),
                      Expanded(
                        child: EmptyState(
                          iconWidget: const MagpieIcon(MagpieGlyph.provider),
                          title: context.tr(
                            '供应商已不存在',
                            'Provider no longer exists',
                          ),
                          body: context.tr(
                            '返回列表查看其他供应商。',
                            'Return to the list to view other providers.',
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: pagePadding,
                  children: [
                    PageTopBar(
                      title: provider.name,
                      onBack: () => Navigator.of(context).pop(),
                      backIcon: MagpieGlyph.back,
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: context.tr('编辑名称', 'Edit name'),
                            onPressed: canEdit
                                ? () => _editName(provider)
                                : null,
                            icon: const MagpieIcon(MagpieGlyph.pencil),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    MagpieList(
                      children: [
                        MagpieRow(
                          title: context.tr('供应商状态', 'Provider status'),
                          subtitle: context.tr(
                            '${provider.accounts.length} 个账号 · ${provider.hosts.length} 个端点域名',
                            '${provider.accounts.length} accounts · ${provider.hosts.length} endpoint hosts',
                          ),
                          leading: ProviderIcon(
                            hosts: provider.hosts,
                            color: provider.enabled
                                ? context.tokens.accent
                                : context.tokens.muted,
                          ),
                          trailing: Switch.adaptive(
                            key: const ValueKey('provider-enabled-switch'),
                            value: provider.enabled,
                            onChanged: canEdit
                                ? (value) async {
                                    final ok = await gateway
                                        .setProvidersEnabled({
                                          provider.id,
                                        }, value);
                                    if (mounted && !ok) _showIssue(gateway);
                                  }
                                : null,
                          ),
                          dense: false,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SectionHeader(
                      title: context.tr('账号与协议', 'Accounts & protocols'),
                      subtitle: context.tr(
                        '每个账号配置一个受支持的协议；网关逐协议使用已选账号，不执行跨协议转换。',
                        'Each account configures one supported protocol. The gateway uses the selected account per protocol and does not translate between protocols.',
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (provider.accounts.isEmpty)
                      MagpieList(
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              context.tr(
                                '尚无账号。添加账号以配置协议、上游端点和模型。',
                                'No accounts yet. Add one to configure a protocol, upstream endpoint and models.',
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      )
                    else
                      MagpieList(
                        children: [
                          for (
                            var i = 0;
                            i < provider.accounts.length;
                            i++
                          ) ...[
                            if (i > 0) const SoftDivider(),
                            _AccountRow(
                              account: provider.accounts[i],
                              hideName: widget.hideAccounts,
                              selected:
                                  gateway.selectedAccountId(
                                    provider.accounts[i].protocol,
                                  ) ==
                                  provider.accounts[i].id,
                              hasKey: gateway.hasAccountKey(
                                provider.accounts[i],
                              ),
                              failedKey: gateway.accountKeyFailed(
                                provider.accounts[i],
                              ),
                              onTap: () => _open(
                                ProviderAccountEditor(
                                  providerId: provider.id,
                                  account: provider.accounts[i],
                                ),
                              ),
                              onRemove: canEdit
                                  ? () => _remove(gateway, provider.accounts[i])
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      key: const ValueKey('provider-add-account'),
                      onPressed: canEdit
                          ? () => _open(
                              ProviderAccountEditor(providerId: provider.id),
                            )
                          : null,
                      icon: const MagpieIcon(MagpieGlyph.plus, size: 18),
                      label: Text(context.tr('添加账号', 'Add account')),
                    ),
                    if (!canEdit && !gateway.loading) ...[
                      const SizedBox(height: 8),
                      Text(
                        context.tr(
                          '停止本机网关后可编辑供应商和账号。',
                          'Stop the local gateway to edit providers and accounts.',
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
        ),
      ),
    );
  }
}

class _AccountRow extends StatelessWidget {
  const _AccountRow({
    required this.account,
    required this.hideName,
    required this.selected,
    required this.hasKey,
    required this.failedKey,
    required this.onTap,
    required this.onRemove,
  });

  final ProviderAccount account;
  final bool hideName;
  final bool selected;
  final bool hasKey;
  final bool failedKey;
  final VoidCallback onTap;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final state = !account.requiresKey
        ? context.tr('无需密钥', 'No key required')
        : failedKey
        ? context.tr('密钥读取失败', 'Key unavailable')
        : hasKey
        ? context.tr('密钥已载入', 'Key loaded')
        : account.credentialId != null
        ? context.tr('需要重新输入密钥', 'Key needs re-entry')
        : context.tr('未设置密钥', 'No key set');
    return MagpieRow(
      key: ValueKey('gateway-account-${account.id}'),
      title: hideName ? context.tr('账号已隐藏', 'Account hidden') : account.name,
      subtitle:
          '${account.protocol.label}  ·  ${account.endpoint.host}  ·  ${account.models.length} ${context.tr('个模型', 'models')}  ·  $state',
      leading: ProviderIcon(
        hosts: [account.endpoint.host],
        size: 18,
        color: selected ? context.tokens.accent : context.tokens.muted,
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selected)
            MagpieBadge(
              label: context.tr('网关使用中', 'Selected'),
              tone: MagpieBadgeTone.accent,
            ),
          IconButton(
            tooltip: context.tr('移除账号', 'Remove account'),
            onPressed: onRemove,
            icon: const Icon(Icons.remove_circle_outline_rounded, size: 19),
          ),
          MagpieIcon(
            MagpieGlyph.chevronRight,
            color: context.tokens.faint,
            size: 19,
            matchTextDirection: true,
          ),
        ],
      ),
      onTap: onTap,
      dense: false,
    );
  }
}

import 'package:flutter/material.dart';

import '../core/domain_style.dart';
import '../core/magpie_l10n.dart';
import '../core/magpie_motion.dart';
import '../core/magpie_theme.dart';
import '../data/demo_data.dart';
import '../models/magpie_models.dart';
import '../state/magpie_store.dart';
import '../widgets/app_canvas.dart';
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';
import 'provider_editor_page.dart';

class ProviderDetailPage extends StatefulWidget {
  const ProviderDetailPage({required this.providerId, super.key});

  final String providerId;

  @override
  State<ProviderDetailPage> createState() => _ProviderDetailPageState();
}

class _ProviderDetailPageState extends State<ProviderDetailPage> {
  ProviderConfig? _providerFrom(MagpieStore store) {
    for (final provider in store.providers) {
      if (provider.id == widget.providerId) {
        return provider;
      }
    }
    return null;
  }

  Future<void> _edit(ProviderConfig provider) async {
    await Navigator.of(context).push<ProviderConfig>(
      MagpiePageRoute<ProviderConfig>(
        context,
        builder: (_) => ProviderEditorPage(provider: provider),
      ),
    );
  }

  Future<void> _delete(ProviderConfig provider) async {
    final confirmed = await showDialog<bool>(
      context: context,
      animationStyle: MagpieMotion.overlays(context),
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(context.tr('删除供应商？', 'Delete provider?')),
          content: Text(
            context.tr(
              '将从当前演示会话中移除「${provider.localizedName(context.l10n)}」。这不会影响任何真实服务或配置。',
              'Remove “${provider.localizedName(context.l10n)}” from this demo session. No real services or settings will be affected.',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(context.tr('取消', 'Cancel')),
            ),
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: context.magpie.coral,
              ),
              child: Text(context.tr('删除', 'Delete')),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !mounted) {
      return;
    }
    final store = MagpieScope.of(context);
    store.removeProvider(provider.id);
    showDemoToast(
      context,
      context.tr(
        '已从演示会话中移除 ${provider.localizedName(context.l10n)}',
        'Removed ${provider.localizedName(context.l10n)} from the demo session',
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final store = MagpieScope.of(context);
    final provider = _providerFrom(store);

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
                      ),
                      Expanded(
                        child: EmptyState(
                          icon: Icons.cloud_off_outlined,
                          title: context.tr(
                            '供应商已不存在',
                            'Provider no longer exists',
                          ),
                          body: context.tr(
                            '它可能已被删除。返回列表查看其他演示配置。',
                            'It may have been deleted. Return to the list to view other demo configurations.',
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: pagePadding,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          PageTopBar(
                            title: context.tr('供应商详情', 'Provider details'),
                            onBack: () => Navigator.of(context).pop(),
                            trailing: RoundIconButton(
                              icon: Icons.delete_outline_rounded,
                              tooltip: context.tr('删除供应商', 'Delete provider'),
                              onPressed: () => _delete(provider),
                              size: 42,
                            ),
                          ),
                          const SizedBox(height: 18),
                          _ProviderHero(provider: provider),
                          const SizedBox(height: 12),
                          InfoBanner(
                            icon: Icons.science_outlined,
                            title: context.tr('演示配置', 'Demo configuration'),
                            body: context.tr(
                              '端点、密钥引用与延迟均为静态示例。此页面不会发起网络请求，也不会读取真实环境变量。',
                              'Endpoints, key references, and latency are static examples. This page makes no network requests and does not read real environment variables.',
                            ),
                            tint: context.magpie.amberSoft,
                            accent: context.magpie.amber,
                          ),
                          const SizedBox(height: 20),
                          _ProviderMetrics(provider: provider),
                          const SizedBox(height: 22),
                          SectionHeader(
                            title: context.tr('可用模型', 'Available models'),
                            subtitle: context.tr(
                              '用于界面展示的示例模型标识',
                              'Example model identifiers for display',
                            ),
                          ),
                          const SizedBox(height: 10),
                          SurfaceCard(
                            child: Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                for (final model in provider.models)
                                  TagChip(
                                    label: model,
                                    icon: Icons.memory_rounded,
                                    color: context.magpie.inkSoft,
                                    background: context.magpie.canvas,
                                    borderColor: context.magpie.line,
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          SectionHeader(
                            title: context.tr('连接配置', 'Connection settings'),
                          ),
                          const SizedBox(height: 10),
                          SurfaceCard(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 17,
                              vertical: 4,
                            ),
                            child: Column(
                              children: [
                                KeyValueRow(
                                  label: context.tr('接入地址', 'Endpoint'),
                                  value: provider.endpoint,
                                  monospace: true,
                                ),
                                const SoftDivider(),
                                KeyValueRow(
                                  label: context.tr('密钥引用', 'Key reference'),
                                  value: context.l10n.reference(
                                    provider.keyReference,
                                  ),
                                  monospace: true,
                                ),
                                const SoftDivider(),
                                KeyValueRow(
                                  label: context.tr('认证方式', 'Authentication'),
                                  value: context.tr(
                                    'Bearer · 演示占位',
                                    'Bearer · demo placeholder',
                                  ),
                                ),
                                const SoftDivider(),
                                KeyValueRow(
                                  label: context.tr('协议类型', 'Protocol type'),
                                  value: context.l10n.providerKind(
                                    provider.kind,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          SectionHeader(
                            title: context.tr('路由策略', 'Routing policy'),
                            subtitle: context.tr(
                              '仅修改当前会话中的界面状态',
                              'Changes only the current session’s UI state',
                            ),
                          ),
                          const SizedBox(height: 10),
                          SurfaceCard(
                            padding: const EdgeInsets.fromLTRB(16, 6, 10, 6),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            context.tr('默认路由', 'Default route'),
                                            style: TextStyle(
                                              color: context.magpie.ink,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            provider.isDefaultRoute
                                                ? context.tr(
                                                    '新会话优先使用此供应商',
                                                    'New sessions prefer this provider',
                                                  )
                                                : context.tr(
                                                    '当前未作为默认路由',
                                                    'Not currently the default route',
                                                  ),
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(fontSize: 10.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      key: const ValueKey(
                                        'default-provider-switch',
                                      ),
                                      value: provider.isDefaultRoute,
                                      onChanged: (value) {
                                        store.setDefaultProvider(
                                          provider.id,
                                          value,
                                        );
                                        showDemoToast(
                                          context,
                                          value
                                              ? context.tr(
                                                  '已将 ${provider.localizedName(context.l10n)} 设为演示默认路由',
                                                  'Set ${provider.localizedName(context.l10n)} as the demo default route',
                                                )
                                              : context.tr(
                                                  '已取消演示默认路由',
                                                  'Demo default route cleared',
                                                ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                const SoftDivider(),
                                KeyValueRow(
                                  label: context.tr('回退策略', 'Fallback policy'),
                                  value: provider.kind == ProviderKind.ollama
                                      ? context.tr('不启用', 'Disabled')
                                      : context.tr(
                                          '下一个在线供应商',
                                          'Next available provider',
                                        ),
                                ),
                                const SoftDivider(),
                                KeyValueRow(
                                  label: context.tr('失败重试', 'Retries'),
                                  value: context.tr(
                                    '2 次 · 指数退避（示意）',
                                    '2 · exponential backoff (example)',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _edit(provider),
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    size: 17,
                                  ),
                                  label: Text(
                                    context.tr('编辑配置', 'Edit settings'),
                                  ),
                                  style: OutlinedButton.styleFrom(
                                    minimumSize: const Size(0, 50),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => showConnectionTestSheet(
                                    context,
                                    provider,
                                  ),
                                  icon: const Icon(
                                    Icons.speed_rounded,
                                    size: 18,
                                  ),
                                  label: Text(
                                    context.tr('测试连接', 'Test connection'),
                                  ),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 50),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton.icon(
                              onPressed: () => showSandboxSheet(context),
                              icon: const Icon(Icons.shield_outlined, size: 15),
                              label: Text(
                                context.tr(
                                  '查看凭据与沙箱边界',
                                  'View credential and sandbox boundaries',
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _ProviderHero extends StatelessWidget {
  const _ProviderHero({required this.provider});

  final ProviderConfig provider;

  @override
  Widget build(BuildContext context) {
    final accent = providerAccent(context, provider.kind);
    final soft = providerSoft(context, provider.kind);

    return SurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'provider-icon-${provider.id}',
                child: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: soft,
                    borderRadius: BorderRadius.circular(19),
                    border: Border.all(color: accent.withValues(alpha: 0.12)),
                  ),
                  child: Icon(
                    providerIcon(provider.kind),
                    size: 26,
                    color: accent,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            provider.localizedName(context.l10n),
                            style: Theme.of(
                              context,
                            ).textTheme.headlineMedium?.copyWith(fontSize: 22),
                          ),
                        ),
                        StatusPill(
                          label: context.l10n.providerHealth(provider.health),
                          color: healthColor(context, provider.health),
                          background: healthBackground(
                            context,
                            provider.health,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.providerKind(provider.kind),
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 11.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: context.magpie.canvas,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: context.magpie.line),
            ),
            child: Row(
              children: [
                Icon(Icons.link_rounded, size: 14, color: context.magpie.faint),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    provider.endpoint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.magpie.muted,
                      fontSize: 11,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 11),
          Text(
            provider.localizedNote(context.l10n),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ProviderMetrics extends StatelessWidget {
  const _ProviderMetrics({required this.provider});

  final ProviderConfig provider;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 6),
      child: Row(
        children: [
          Expanded(
            child: MetricBlock(
              value: provider.latencyMs == null
                  ? '—'
                  : '${provider.latencyMs} ms',
              label: context.tr('演示延迟', 'Demo latency'),
              align: CrossAxisAlignment.center,
            ),
          ),
          Container(width: 1, height: 32, color: context.magpie.line),
          Expanded(
            child: MetricBlock(
              value: '${provider.models.length}',
              label: context.tr('可用模型', 'Available models'),
              align: CrossAxisAlignment.center,
            ),
          ),
          Container(width: 1, height: 32, color: context.magpie.line),
          Expanded(
            child: MetricBlock(
              value: provider.isDefaultRoute
                  ? context.tr('主路由', 'Primary')
                  : context.tr('备用', 'Fallback'),
              label: context.tr('路由角色', 'Route role'),
              align: CrossAxisAlignment.center,
            ),
          ),
        ],
      ),
    );
  }
}

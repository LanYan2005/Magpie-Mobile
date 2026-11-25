import 'package:flutter/material.dart';

import '../core/domain_style.dart';
import '../core/magpie_l10n.dart';
import '../core/magpie_motion.dart';
import '../core/magpie_theme.dart';
import '../data/demo_data.dart';
import '../models/magpie_models.dart';
import '../state/magpie_store.dart';
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';

class ResourcesPage extends StatefulWidget {
  const ResourcesPage({super.key});

  @override
  State<ResourcesPage> createState() => _ResourcesPageState();
}

class _ResourcesPageState extends State<ResourcesPage>
    with AutomaticKeepAliveClientMixin {
  int _tab = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
                PageHeader(
                  title: context.tr('资源', 'Resources'),
                  subtitle: context.tr(
                    '在 Magpie 内管理 Skills 与 MCP 配置，并导出演示清单。'
                        '不启动 Termux 桥接，不读取或写入其他 App 的私有目录。',
                    'Manage Skills and MCP configurations in Magpie, and export demo manifests. '
                        'Does not start the Termux bridge or access other apps’ private directories.',
                  ),
                ),
                const SizedBox(height: 22),
                InfoBanner(
                  icon: Icons.admin_panel_settings_outlined,
                  title: context.tr('只做管理与导出', 'Management and export only'),
                  body: context.tr(
                    'Skills 可查看、编辑演示内容并导出清单；MCP 只管理配置，'
                        '远程 HTTP(S) 可导出。stdio 本地服务不会在 Android/iOS 上启动。',
                    'View, edit, and export demo Skill content; manage MCP settings only. '
                        'Remote HTTP(S) settings can be exported. Local stdio services do not start on Android/iOS.',
                  ),
                  onTap: () => showSandboxSheet(context),
                  actionLabel: context.tr('查看平台边界', 'Platform details'),
                  tint: context.magpie.amberSoft,
                  accent: context.magpie.amber,
                ),
                const SizedBox(height: 16),
                _ResourceTabs(
                  selected: _tab,
                  skillCount: store.skills.length,
                  mcpCount: store.mcpServers.length,
                  onChanged: (value) => setState(() => _tab = value),
                ),
                const SizedBox(height: 18),
                if (_tab == 0)
                  _SkillsSection(store: store)
                else
                  _McpSection(store: store),
                const SizedBox(height: 20),
                Center(
                  child: Text(
                    context.tr(
                      '资源状态仅保存在当前演示会话',
                      'Resource state is saved only for this demo session',
                    ),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10.5,
                      color: context.magpie.faint,
                    ),
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

class _ResourceTabs extends StatelessWidget {
  const _ResourceTabs({
    required this.selected,
    required this.skillCount,
    required this.mcpCount,
    required this.onChanged,
  });

  final int selected;
  final int skillCount;
  final int mcpCount;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: context.magpie.canvasDeep,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.magpie.line),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              key: const ValueKey('resource-tab-skills'),
              label: context.tr('Skills', 'Skills'),
              count: skillCount,
              icon: Icons.extension_outlined,
              selected: selected == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _TabButton(
              key: const ValueKey('resource-tab-mcp'),
              label: 'MCP',
              count: mcpCount,
              icon: Icons.hub_outlined,
              selected: selected == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.count,
    required this.icon,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final int count;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.magpie;
    return Semantics(
      button: true,
      selected: selected,
      label: '$label $count',
      onTap: onTap,
      child: AnimatedContainer(
        duration: MagpieMotion.duration(context, MagpieMotion.selection),
        height: 44,
        decoration: ShapeDecoration(
          color: selected ? colors.paper : Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: selected ? colors.line : Colors.transparent,
            ),
          ),
          shadows: selected && !context.reduceMotion
              ? [
                  BoxShadow(
                    color: colors.shadow.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : const [],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            excludeFromSemantics: true,
            borderRadius: BorderRadius.circular(14),
            splashFactory: NoSplash.splashFactory,
            child: ExcludeSemantics(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: selected ? colors.ink : colors.muted,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? colors.ink : colors.muted,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: selected ? colors.mint : colors.canvasDeep,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '$count',
                      style: TextStyle(
                        color: selected ? colors.jadeDeep : colors.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SkillsSection extends StatelessWidget {
  const _SkillsSection({required this.store});

  final MagpieStore store;

  @override
  Widget build(BuildContext context) {
    final enabled = store.enabledSkillCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: SectionHeader(
                title: context.tr('Skills', 'Skills'),
                subtitle: context.tr(
                  '$enabled / ${store.skills.length} 已启用 · 可在 Magpie 内编辑',
                  '$enabled / ${store.skills.length} enabled · editable in Magpie',
                ),
              ),
            ),
            DemoBadge(label: context.tr('本地管理', 'Locally managed')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('add-skill-button'),
                onPressed: () => showSkillEditorSheet(context, store),
                icon: const Icon(Icons.add_rounded, size: 17),
                label: Text(context.tr('新增 Skill', 'Add Skill')),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('export-skill-button'),
                onPressed: () => showExportSkillSheet(context, store),
                icon: const Icon(Icons.ios_share_rounded, size: 17),
                label: Text(context.tr('导出清单', 'Export manifest')),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  backgroundColor: context.magpie.jadeDeep,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (store.skills.isEmpty)
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: EmptyState(
              icon: Icons.extension_off_outlined,
              title: context.tr('还没有 Skill', 'No Skills yet'),
              body: context.tr(
                '点击新增，在 Magpie 内创建一条演示配置。',
                'Tap Add to create a demo configuration in Magpie.',
              ),
            ),
          )
        else
          for (var i = 0; i < store.skills.length; i++) ...[
            SkillCard(
              key: ValueKey('skill-card-${store.skills[i].id}'),
              skill: store.skills[i],
              onToggle: (value) {
                store.toggleSkill(store.skills[i].id, value);
              },
              onTap: () =>
                  showSkillDetailSheet(context, store, store.skills[i]),
            ),
            if (i != store.skills.length - 1) const SizedBox(height: 10),
          ],
        const SizedBox(height: 12),
        InfoBanner(
          icon: Icons.folder_off_outlined,
          title: context.tr(
            'Skills 只保存在本机演示会话',
            'Skills are saved only in this local demo session',
          ),
          body: context.tr(
            '不会读取或写入任何目录，也不会执行 Skill。'
                '导出按钮只展示内存中的清单预览，并明确标注为演示。',
            'No directories are accessed and Skills are not executed. '
                'Export shows an in-memory manifest preview, clearly marked as a demo.',
          ),
        ),
      ],
    );
  }
}

class SkillCard extends StatelessWidget {
  const SkillCard({
    required this.skill,
    required this.onToggle,
    required this.onTap,
    super.key,
  });

  final SkillResource skill;
  final ValueChanged<bool> onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = originColor(context, skill.origin);
    final soft = originBackground(context, skill.origin);

    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(15, 14, 10, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: accent.withValues(alpha: 0.12)),
                ),
                child: Icon(Icons.extension_outlined, size: 19, color: accent),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            skill.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontSize: 13.5,
                                  fontFamily: 'monospace',
                                ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        TagChip(
                          label: context.l10n.resourceOrigin(skill.origin),
                          color: accent,
                          background: soft,
                          borderColor: accent.withValues(alpha: 0.12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      skill.localizedDescription(context.l10n),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Switch(
                key: ValueKey('skill-switch-${skill.id}'),
                value: skill.enabled,
                onChanged: onToggle,
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    TagChip(
                      label: skill.version,
                      icon: Icons.tag_rounded,
                      color: context.magpie.muted,
                      background: context.magpie.canvas,
                      borderColor: context.magpie.line,
                    ),
                    for (final permission in context.l10n.permissions(
                      skill.permissions,
                    ))
                      TagChip(
                        label: permission,
                        icon: Icons.key_outlined,
                        color: context.magpie.muted,
                        background: context.magpie.paper,
                        borderColor: context.magpie.line,
                      ),
                    TagChip(
                      label: context.tr(
                        '${skill.toolCount} 个工具',
                        '${skill.toolCount} tools',
                      ),
                      color: context.magpie.faint,
                      background: context.magpie.paper,
                      borderColor: context.magpie.line,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                Icons.chevron_right_rounded,
                size: 17,
                color: context.magpie.faint,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _McpSection extends StatelessWidget {
  const _McpSection({required this.store});

  final MagpieStore store;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: SectionHeader(
                title: context.tr('MCP 服务', 'MCP Servers'),
                subtitle: context.tr(
                  '${store.connectedMcpCount} 个配置启用 · '
                      '${store.remoteMcpCount} 个远程可导出',
                  '${store.connectedMcpCount} configurations enabled · '
                      '${store.remoteMcpCount} remote configurations exportable',
                ),
              ),
            ),
            DemoBadge(label: context.tr('仅配置', 'Configuration only')),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                key: const ValueKey('add-mcp-button'),
                onPressed: () => showMcpEditorSheet(context, store),
                icon: const Icon(Icons.add_link_rounded, size: 17),
                label: Text(context.tr('新增 MCP', 'Add MCP')),
                style: FilledButton.styleFrom(minimumSize: const Size(0, 44)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('export-mcp-button'),
                onPressed: () => showMcpExportSheet(context, store),
                icon: const Icon(Icons.ios_share_rounded, size: 17),
                label: Text(context.tr('导出远程配置', 'Export remote settings')),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 44)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (store.mcpServers.isEmpty)
          SurfaceCard(
            padding: EdgeInsets.zero,
            child: EmptyState(
              icon: Icons.hub_outlined,
              title: context.tr('还没有 MCP 服务', 'No MCP servers yet'),
              body: context.tr(
                '新增一条配置，stdio 与远程 HTTP(S) 都只保存参数。',
                'Add a configuration; stdio and remote HTTP(S) settings are stored only.',
              ),
            ),
          )
        else
          for (var i = 0; i < store.mcpServers.length; i++) ...[
            McpCard(
              key: ValueKey('mcp-card-${store.mcpServers[i].id}'),
              server: store.mcpServers[i],
              onToggle: (value) {
                store.toggleMcp(store.mcpServers[i].id, value);
              },
              onTap: () => showMcpEditorSheet(
                context,
                store,
                server: store.mcpServers[i],
              ),
            ),
            if (i != store.mcpServers.length - 1) const SizedBox(height: 10),
          ],
        const SizedBox(height: 12),
        InfoBanner(
          icon: Icons.terminal_rounded,
          title: context.tr(
            'stdio 只管理配置，不在 Android/iOS 启动',
            'stdio settings only; does not start on Android/iOS',
          ),
          body: context.tr(
            '本地 stdio 服务不会运行进程，也不会读写其他 App 的私有目录；'
                '远程 HTTP(S) 配置只保存参数并可导出演示清单，不会发起握手。',
            'Local stdio services do not run processes or access other apps’ private directories. '
                'Remote HTTP(S) settings are stored and can be exported as a demo manifest; no handshake is made.',
          ),
        ),
      ],
    );
  }
}

class McpCard extends StatelessWidget {
  const McpCard({
    required this.server,
    required this.onToggle,
    this.onTap,
    super.key,
  });

  final McpServerConfig server;
  final ValueChanged<bool> onToggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final statusColor = mcpStatusColor(context, server.status);
    final isStdio = server.transport.isStdio;
    final remoteColor = isStdio ? context.magpie.cobalt : context.magpie.amber;
    final remoteBackground = isStdio
        ? context.magpie.cobaltSoft
        : context.magpie.amberSoft;

    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(15, 14, 10, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: remoteBackground,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: remoteColor.withValues(alpha: 0.12),
                  ),
                ),
                child: Icon(
                  isStdio ? Icons.terminal_rounded : Icons.cloud_outlined,
                  size: 19,
                  color: remoteColor,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            server.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  fontSize: 13.5,
                                  fontFamily: 'monospace',
                                ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        TagChip(
                          label: isStdio
                              ? context.tr('本地 · 仅配置', 'Local · settings only')
                              : context.tr('远程', 'Remote'),
                          color: remoteColor,
                          background: remoteBackground,
                          borderColor: remoteColor.withValues(alpha: 0.12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      server.localizedDescription(context.l10n),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 10.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Switch(
                key: ValueKey('mcp-switch-${server.id}'),
                value: server.enabled,
                onChanged: onToggle,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            decoration: BoxDecoration(
              color: context.magpie.canvas,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: context.magpie.line),
            ),
            child: Row(
              children: [
                Icon(
                  isStdio ? Icons.cable_rounded : Icons.link_rounded,
                  size: 13,
                  color: context.magpie.faint,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    server.endpoint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.magpie.muted,
                      fontSize: 10.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 7),
                Text(
                  server.transport.isStdio
                      ? context.tr('本地进程', 'Local process')
                      : server.transport.label,
                  style: TextStyle(
                    color: context.magpie.faint,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    StatusPill(
                      label: context.l10n.mcpStatus(server.status),
                      color: statusColor,
                      background: mcpStatusBackground(context, server.status),
                    ),
                    if (isStdio)
                      TagChip(
                        label: context.tr(
                          '不在 Android/iOS 启动',
                          'Not started on Android/iOS',
                        ),
                        icon: Icons.block_rounded,
                        color: context.magpie.cobalt,
                        background: context.magpie.cobaltSoft,
                        borderColor: context.magpie.cobaltSoft,
                      ),
                    TagChip(
                      label: context.tr(
                        '${server.toolCount} 个工具',
                        '${server.toolCount} tools',
                      ),
                      color: context.magpie.muted,
                      background: context.magpie.canvas,
                      borderColor: context.magpie.line,
                    ),
                    for (final permission in context.l10n.permissions(
                      server.permissions,
                    ))
                      TagChip(
                        label: permission,
                        icon: Icons.key_outlined,
                        color: context.magpie.muted,
                        background: context.magpie.paper,
                        borderColor: context.magpie.line,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Text(
                context.l10n.reference(server.authReference),
                style: TextStyle(
                  color: context.magpie.faint,
                  fontSize: 8.5,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.edit_outlined, size: 13, color: context.magpie.faint),
            ],
          ),
        ],
      ),
    );
  }
}

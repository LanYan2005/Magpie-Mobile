import 'package:flutter/material.dart';

import '../core/magpie_l10n.dart';
import '../core/magpie_theme.dart';
import '../core/magpie_tokens.dart';
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        context.l10n.navigationLabel(MagpieSection.resources),
                        style: TextStyle(
                          color: context.tokens.fg,
                          fontSize: MagpieType.base,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    IconButton(
                      key: const ValueKey('resource-boundary-button'),
                      tooltip: context.tr('平台边界', 'Platform boundaries'),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => showSandboxSheet(context),
                      icon: Icon(
                        Icons.shield_outlined,
                        size: 18,
                        color: context.magpie.muted,
                      ),
                    ),
                  ],
                ),
                Text(
                  context.tr('只做管理与导出', 'Management and export only'),
                  style: TextStyle(color: context.magpie.muted, fontSize: 11.5),
                ),
                const SizedBox(height: 10),
                _ResourceTabs(
                  selected: _tab,
                  skillCount: store.skills.length,
                  mcpCount: store.mcpServers.length,
                  onChanged: (value) => setState(() => _tab = value),
                ),
                const SizedBox(height: 10),
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
    return Row(
      children: [
        Expanded(
          child: MagpieSegmented(
            key: const ValueKey('resource-tab-skills'),
            labels: ['${context.tr('技能', 'Skills')} · $skillCount'],
            index: selected == 0 ? 0 : -1,
            onChanged: (_) => onChanged(0),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: MagpieSegmented(
            key: const ValueKey('resource-tab-mcp'),
            labels: ['${context.tr('MCP 服务器', 'MCP servers')} · $mcpCount'],
            index: selected == 1 ? 0 : -1,
            onChanged: (_) => onChanged(1),
          ),
        ),
      ],
    );
  }
}

class _ResourceToolbar extends StatelessWidget {
  const _ResourceToolbar({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 5,
    runSpacing: 4,
    crossAxisAlignment: WrapCrossAlignment.center,
    children: children,
  );
}

class _ResourceAction extends StatelessWidget {
  const _ResourceAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.prominent = true,
    super.key,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool prominent;

  @override
  Widget build(BuildContext context) => Tooltip(
    message: label,
    child: Material(
      color: prominent ? context.tokens.accentSoft : context.tokens.pill,
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 36, minWidth: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 15, color: context.tokens.accent),
                const SizedBox(width: 5),
                Text(
                  label,
                  style: TextStyle(
                    color: context.tokens.accent,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
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
          children: [
            Text(
              context.tr('Skills', 'Skills'),
              style: TextStyle(
                color: context.tokens.fg,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            MagpieBadge(
              label: '$enabled / ${store.skills.length}',
              tone: MagpieBadgeTone.neutral,
            ),
            const Spacer(),
            DemoBadge(label: context.tr('本地管理', 'Local')),
          ],
        ),
        const SizedBox(height: 7),
        _ResourceToolbar(
          children: [
            _ResourceAction(
              key: const ValueKey('add-skill-button'),
              icon: Icons.add_rounded,
              label: context.tr('新增 Skill', 'Add Skill'),
              onTap: () => showSkillEditorSheet(context, store),
            ),
            _ResourceAction(
              key: const ValueKey('export-skill-button'),
              icon: Icons.ios_share_rounded,
              label: context.tr('导出清单', 'Export manifest'),
              onTap: () => showExportSkillSheet(context, store),
              prominent: false,
            ),
            IconButton(
              key: const ValueKey('skills-boundary-button'),
              tooltip: context.tr('Skills 管理边界', 'Skill management boundaries'),
              visualDensity: VisualDensity.compact,
              onPressed: () => showSandboxSheet(context),
              icon: Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: context.magpie.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
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
          MagpieList(
            children: [
              for (var i = 0; i < store.skills.length; i++) ...[
                _SkillRow(
                  key: ValueKey('skill-card-${store.skills[i].id}'),
                  skill: store.skills[i],
                  onToggle: (value) {
                    store.toggleSkill(store.skills[i].id, value);
                  },
                  onTap: () =>
                      showSkillDetailSheet(context, store, store.skills[i]),
                ),
                if (i != store.skills.length - 1)
                  Divider(height: 1, indent: 42, color: context.tokens.line2),
              ],
            ],
          ),
        const SizedBox(height: 10),
        InfoBanner(
          icon: Icons.folder_off_outlined,
          title: context.tr(
            'Skills 只保存在本机演示会话',
            'Skills are saved only in this local demo session',
          ),
          body: context.tr(
            '不读取或写入其他 App 的私有目录，也不会执行 Skill。'
                '导出按钮只展示内存中的清单预览，并明确标注为演示。',
            'No other apps’ private directories are accessed, and Skills are not executed. '
                'Export shows an in-memory manifest preview, clearly marked as a demo.',
          ),
        ),
      ],
    );
  }
}

class _SkillRow extends StatelessWidget {
  const _SkillRow({
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
    return MagpieRow(
      title: skill.name,
      subtitle:
          '${skill.localizedDescription(context.l10n)} · ${skill.version}',
      leading: Icon(
        Icons.extension_outlined,
        size: 18,
        color: context.tokens.accent,
      ),
      onTap: onTap,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: context.tr(
              '资源来源：${context.l10n.resourceOrigin(skill.origin)}',
              'Origin: ${context.l10n.resourceOrigin(skill.origin)}',
            ),
            child: Icon(
              switch (skill.origin) {
                ResourceOrigin.local => Icons.edit_outlined,
                ResourceOrigin.bundled => Icons.inventory_2_outlined,
                ResourceOrigin.remote => Icons.cloud_outlined,
              },
              size: 15,
              color: context.tokens.muted,
            ),
          ),
          Switch(
            key: ValueKey('skill-switch-${skill.id}'),
            value: skill.enabled,
            onChanged: onToggle,
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 16,
            color: context.tokens.faint,
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
          children: [
            Text(
              context.tr('MCP 服务', 'MCP servers'),
              style: TextStyle(
                color: context.tokens.fg,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 8),
            MagpieBadge(
              label: '${store.connectedMcpCount} / ${store.mcpServers.length}',
              tone: MagpieBadgeTone.neutral,
            ),
            const Spacer(),
            MagpieBadge(
              label: context.tr('仅配置', 'Settings only'),
              tone: MagpieBadgeTone.warning,
            ),
          ],
        ),
        const SizedBox(height: 7),
        _ResourceToolbar(
          children: [
            _ResourceAction(
              key: const ValueKey('add-mcp-button'),
              icon: Icons.add_rounded,
              label: context.tr('新增 MCP', 'Add MCP'),
              onTap: () => showMcpEditorSheet(context, store),
            ),
            _ResourceAction(
              key: const ValueKey('export-mcp-button'),
              icon: Icons.ios_share_rounded,
              label: context.tr('导出预览', 'Export preview'),
              onTap: () => showMcpExportSheet(context, store),
              prominent: false,
            ),
            IconButton(
              key: const ValueKey('mcp-boundary-button'),
              tooltip: context.tr('stdio 与远程配置说明', 'stdio and remote settings'),
              visualDensity: VisualDensity.compact,
              onPressed: () => showSandboxSheet(context),
              icon: Icon(
                Icons.info_outline_rounded,
                size: 18,
                color: context.magpie.muted,
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
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
          MagpieList(
            children: [
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
                if (i != store.mcpServers.length - 1)
                  Divider(height: 1, indent: 34, color: context.tokens.line2),
              ],
            ],
          ),
        const SizedBox(height: 12),
        InfoBanner(
          icon: Icons.terminal_rounded,
          title: context.tr('不在 Android/iOS 启动', 'Not launched on Android/iOS'),
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
    final isStdio = server.transport.isStdio;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        MagpieRow(
          title: server.name,
          subtitle: server.endpoint,
          leading: Icon(
            isStdio ? Icons.terminal_rounded : Icons.cloud_outlined,
            size: 18,
            color: isStdio ? context.tokens.muted : context.tokens.accent,
          ),
          onTap: onTap,
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Tooltip(
                message: isStdio
                    ? context.tr(
                        'stdio 仅保存配置，不在 Android/iOS 启动',
                        'stdio settings are stored only; not launched on Android/iOS',
                      )
                    : context.l10n.mcpStatus(server.status),
                child: MagpieBadge(
                  label: isStdio
                      ? context.tr('本地 · 仅配置', 'Local · settings only')
                      : context.tr('远程', 'Remote'),
                  tone: isStdio
                      ? MagpieBadgeTone.neutral
                      : MagpieBadgeTone.accent,
                ),
              ),
              if (!isStdio) ...[
                const SizedBox(width: 4),
                MagpieBadge(
                  label: context.l10n.mcpStatus(server.status),
                  tone: switch (server.status) {
                    McpStatus.connected => MagpieBadgeTone.success,
                    McpStatus.offline => MagpieBadgeTone.neutral,
                    McpStatus.needsSetup => MagpieBadgeTone.warning,
                  },
                ),
              ],
              Switch(
                key: ValueKey('mcp-switch-${server.id}'),
                value: server.enabled,
                onChanged: onToggle,
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 16,
                color: context.tokens.faint,
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(38, 0, 12, 7),
          child: Row(
            children: [
              Icon(Icons.build_outlined, size: 12, color: context.tokens.muted),
              const SizedBox(width: 5),
              Text(
                context.tr(
                  '${server.toolCount} 个工具',
                  '${server.toolCount} tools',
                ),
                style: TextStyle(color: context.tokens.muted, fontSize: 10.5),
              ),
              const SizedBox(width: 8),
              if (isStdio)
                Text(
                  context.tr('未启动', 'Not started'),
                  style: TextStyle(color: context.tokens.muted, fontSize: 10),
                ),
              Expanded(
                child: Text(
                  context.l10n.permissions(server.permissions).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.tokens.faint, fontSize: 10.5),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                context.l10n.reference(server.authReference),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.tokens.faint,
                  fontSize: 9.5,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

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
import 'agent_editor_page.dart';

class AgentsPage extends StatelessWidget {
  const AgentsPage({super.key});

  Future<void> _openEditor(BuildContext context, {AgentConfig? agent}) async {
    await Navigator.of(context).push(
      MagpiePageRoute<void>(
        context,
        builder: (_) => AgentEditorPage(agent: agent),
      ),
    );
  }

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
                PageHeader(
                  title: context.tr('Agents', 'Agents'),
                  subtitle: context.tr(
                    '为 Claude Code、Codex、Gemini CLI 与自定义兼容端点保存不同的接入方式。',
                    'Save different connection methods for Claude Code, Codex, Gemini CLI, and custom compatible endpoints.',
                  ),
                  action: RoundIconButton(
                    key: const ValueKey('add-agent-button'),
                    icon: Icons.add_rounded,
                    tooltip: context.tr('新建 Agent', 'New Agent'),
                    onPressed: () => _openEditor(context),
                    filled: true,
                    size: 46,
                  ),
                ),
                const SizedBox(height: 22),
                _AgentSummary(store: store),
                const SizedBox(height: 14),
                InfoBanner(
                  icon: Icons.terminal_outlined,
                  title: context.tr(
                    '只配置，不启动',
                    'Configuration only; not launched',
                  ),
                  body: context.tr(
                    '本原型不会启动 CLI、建立 SSH、打开本地端口或执行命令。Termux 在 Android 上也只是用户空间环境。',
                    'This prototype does not launch a CLI, connect over SSH, open local ports, or run commands. Termux is also a user-space environment on Android.',
                  ),
                  onTap: () => showSandboxSheet(context),
                  actionLabel: context.tr('查看平台边界', 'Platform details'),
                ),
                const SizedBox(height: 22),
                SectionHeader(
                  title: context.tr('运行时', 'Runtimes'),
                  subtitle: context.tr(
                    '配置类型与接入方式会同时展示',
                    'Configuration type and connection method are shown together',
                  ),
                ),
                const SizedBox(height: 10),
                if (store.agents.isEmpty)
                  SurfaceCard(
                    padding: EdgeInsets.zero,
                    child: EmptyState(
                      icon: Icons.auto_awesome_outlined,
                      title: context.tr('还没有 Agent', 'No Agents yet'),
                      body: context.tr(
                        '添加一个演示配置，查看不同运行时与接入方式。',
                        'Add a demo configuration to see different runtimes and connection methods.',
                      ),
                      action: OutlinedButton(
                        onPressed: () => _openEditor(context),
                        child: Text(context.tr('新建 Agent', 'New Agent')),
                      ),
                    ),
                  )
                else
                  for (var i = 0; i < store.agents.length; i++) ...[
                    AgentCard(
                      agent: store.agents[i],
                      onTap: () => _openEditor(context, agent: store.agents[i]),
                    ),
                    if (i != store.agents.length - 1)
                      const SizedBox(height: 10),
                  ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _openEditor(context),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: Text(context.tr('新建 Agent', 'New Agent')),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 50),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.tr(
                    '配置只保留在当前演示会话；重启应用后恢复初始示例。',
                    'Configurations stay in this demo session and reset to the initial examples when the app restarts.',
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

class _AgentSummary extends StatelessWidget {
  const _AgentSummary({required this.store});

  final MagpieStore store;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: MetricBlock(
              value: '${store.agents.length}',
              label: context.tr('全部 Agent', 'All Agents'),
              align: CrossAxisAlignment.center,
              valueSize: 22,
            ),
          ),
          Container(width: 1, height: 32, color: context.magpie.line),
          Expanded(
            child: MetricBlock(
              value: '${store.onlineAgentCount}',
              label: context.tr('演示在线', 'Online (demo)'),
              color: context.magpie.jade,
              align: CrossAxisAlignment.center,
              valueSize: 22,
            ),
          ),
          Container(width: 1, height: 32, color: context.magpie.line),
          Expanded(
            child: MetricBlock(
              value: '4',
              label: context.tr('运行时', 'Runtimes'),
              align: CrossAxisAlignment.center,
              valueSize: 22,
            ),
          ),
          Container(width: 1, height: 32, color: context.magpie.line),
          Expanded(
            child: MetricBlock(
              value:
                  '${store.agents.where((a) => a.access == AgentAccess.termux).length}',
              label: 'Termux',
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

class AgentCard extends StatelessWidget {
  const AgentCard({required this.agent, required this.onTap, super.key});

  final AgentConfig agent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = agentAccent(context, agent.runtime);
    final soft = agentSoft(context, agent.runtime);

    return SurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(15, 15, 15, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: soft,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: accent.withValues(alpha: 0.1)),
                ),
                child: Icon(agentIcon(agent.runtime), size: 21, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      agent.localizedName(context.l10n),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(
                        context,
                      ).textTheme.titleMedium?.copyWith(fontSize: 14.5),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      context.l10n.agentRuntimeSubtitle(agent.runtime),
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
              StatusPill(
                label: context.l10n.agentStatus(agent.status),
                color: agentStatusColor(context, agent.status),
                background: agentStatusBackground(context, agent.status),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              TagChip(
                label: context.tr(
                  '配置 · ${agent.runtime.label}',
                  'Runtime · ${agent.runtime.label}',
                ),
                icon: Icons.tune_rounded,
                color: accent,
                background: soft,
                borderColor: accent.withValues(alpha: 0.12),
              ),
              TagChip(
                label: context.tr(
                  '接入 · ${agent.access.label}',
                  'Access · ${context.l10n.agentAccess(agent.access)}',
                ),
                icon: Icons.cable_rounded,
                color: context.magpie.inkSoft,
                background: context.magpie.canvas,
                borderColor: context.magpie.line,
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
                  Icons.north_east_rounded,
                  size: 13,
                  color: context.magpie.faint,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    agent.endpoint,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: context.magpie.muted,
                      fontSize: 10.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  agent.model.isEmpty
                      ? context.tr('未指定', 'Unspecified')
                      : agent.model,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.magpie.faint, fontSize: 9.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            agent.localizedNote(context.l10n),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontSize: 10.5),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Wrap(
                  spacing: 5,
                  runSpacing: 5,
                  children: [
                    for (final permission in context.l10n.permissions(
                      agent.permissions,
                    ))
                      TagChip(
                        label: permission,
                        color: context.magpie.muted,
                        background: context.magpie.paper,
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

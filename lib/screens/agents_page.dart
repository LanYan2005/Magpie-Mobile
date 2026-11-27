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

// Agent rows and disclosure adapted from yetone/magpie's MIT GUI.
// See THIRD_PARTY_NOTICES.md for the source and copyright notice.
class AgentsPage extends StatefulWidget {
  const AgentsPage({super.key});

  @override
  State<AgentsPage> createState() => _AgentsPageState();
}

class _AgentsPageState extends State<AgentsPage> {
  final _newAgentRow = GlobalKey();
  String? _newAgentId;
  String? _expandedAgentId;
  bool _showMore = false;
  final Map<String, bool> _agentEnabled = {};

  Future<void> _openEditor({
    AgentConfig? agent,
    AgentEditorSection? section,
  }) async {
    final saved = await Navigator.of(context).push<AgentConfig>(
      MagpiePageRoute<AgentConfig>(
        context,
        builder: (_) => AgentEditorPage(agent: agent, section: section),
      ),
    );
    if (!mounted || saved == null || agent != null) return;
    setState(() {
      _newAgentId = saved.id;
      _showMore = true;
      _expandedAgentId = saved.id;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final row = _newAgentRow.currentContext;
      if (row == null || _newAgentId != saved.id) return;
      Scrollable.ensureVisible(row, alignment: 0.15);
    });
  }

  @override
  Widget build(BuildContext context) {
    final agents = MagpieScope.of(context).agents;
    final configured = agents
        .where((agent) => agent.status != AgentStatus.needsSetup)
        .toList();
    final pending = agents
        .where((agent) => agent.status == AgentStatus.needsSetup)
        .toList();
    final colors = context.magpie;

    Widget row(AgentConfig agent) {
      return KeyedSubtree(
        key: agent.id == _newAgentId ? _newAgentRow : ValueKey(agent.id),
        child: _AgentRow(
          key: ValueKey('agent-row-${agent.id}'),
          agent: agent,
          expanded: _expandedAgentId == agent.id,
          enabled:
              _agentEnabled[agent.id] ?? agent.status != AgentStatus.paused,
          onEnabledChanged: (value) => setState(() {
            _agentEnabled[agent.id] = value;
          }),
          onOpen: (section) => _openEditor(agent: agent, section: section),
          onToggle: () => setState(() {
            _expandedAgentId = _expandedAgentId == agent.id ? null : agent.id;
          }),
        ),
      );
    }

    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        key: const PageStorageKey('agents-scroll'),
        padding: dockPagePadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Semantics(
                        header: true,
                        child: Text(
                          'Agents',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ),
                    ),
                    Flexible(
                      child: TextButton.icon(
                        key: const ValueKey('add-agent-button'),
                        onPressed: _openEditor,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: Text(context.tr('新建 Agent', 'New Agent')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Material(
                  color: colors.paper,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (agents.isEmpty)
                        EmptyState(
                          icon: Icons.terminal_rounded,
                          title: context.tr('还没有 Agent', 'No agents yet'),
                          body: context.tr(
                            '新建一个本地配置即可加入列表。',
                            'Create a local configuration to add it to the list.',
                          ),
                        ),
                      for (var i = 0; i < configured.length; i++) ...[
                        if (i > 0) const SoftDivider(),
                        row(configured[i]),
                      ],
                      if (pending.isNotEmpty) ...[
                        AnimatedSize(
                          duration: MagpieMotion.duration(
                            context,
                            MagpieMotion.tab,
                          ),
                          curve: MagpieMotion.curveFor(context),
                          alignment: Alignment.topCenter,
                          child: _showMore
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    if (configured.isNotEmpty)
                                      const SoftDivider(),
                                    Padding(
                                      padding: const EdgeInsetsDirectional.only(
                                        start: 14,
                                        top: 8,
                                        bottom: 2,
                                      ),
                                      child: Semantics(
                                        header: true,
                                        child: Text(
                                          context.tr('待配置', 'Not set up'),
                                          style: TextStyle(
                                            color: colors.muted,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ),
                                    ),
                                    for (
                                      var i = 0;
                                      i < pending.length;
                                      i++
                                    ) ...[
                                      if (i > 0) const SoftDivider(),
                                      row(pending[i]),
                                    ],
                                  ],
                                )
                              : const SizedBox.shrink(),
                        ),
                        if (configured.isNotEmpty || _showMore)
                          const SoftDivider(),
                        Semantics(
                          expanded: _showMore,
                          child: TextButton.icon(
                            key: const ValueKey('agents-show-more'),
                            onPressed: () => setState(() {
                              _showMore = !_showMore;
                              if (!_showMore &&
                                  pending.any(
                                    (agent) => agent.id == _expandedAgentId,
                                  )) {
                                _expandedAgentId = null;
                              }
                            }),
                            iconAlignment: IconAlignment.end,
                            icon: AnimatedRotation(
                              turns: _showMore ? 0.5 : 0,
                              duration: MagpieMotion.duration(
                                context,
                                MagpieMotion.selection,
                              ),
                              child: const Icon(Icons.expand_more, size: 15),
                            ),
                            label: Text(
                              _showMore
                                  ? context.tr('收起', 'Show less')
                                  : configured.isEmpty
                                  ? context.tr(
                                      '显示全部 ${pending.length} 个 Agent',
                                      'Show all ${pending.length} agents',
                                    )
                                  : context.tr(
                                      '显示另外 ${pending.length} 个',
                                      'Show ${pending.length} more',
                                    ),
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: colors.muted,
                              textStyle: const TextStyle(fontSize: 12),
                              minimumSize: const Size(0, 44),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  context.tr(
                    'Agent 配置仅保留在本次会话中。开关仅记录当前页面的演示状态，运行时与系统接入尚未实现。',
                    'Agent configurations last for this session. Switches are demo state for this page; runtime and system integration are unavailable.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton(
                    onPressed: () => showSandboxSheet(context),
                    child: Text(context.tr('查看平台边界', 'Platform details')),
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

class _AgentRow extends StatelessWidget {
  const _AgentRow({
    required this.agent,
    required this.expanded,
    required this.enabled,
    required this.onEnabledChanged,
    required this.onOpen,
    required this.onToggle,
    super.key,
  });

  final AgentConfig agent;
  final bool expanded;
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final ValueChanged<AgentEditorSection?> onOpen;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final colors = context.magpie;
    final name = agent.localizedName(context.l10n);
    final note = agent.localizedNote(context.l10n);
    void openDetails() => onOpen(null);
    final summary = Semantics(
      button: true,
      expanded: expanded,
      child: InkWell(
        key: ValueKey('agent-name-${agent.id}'),
        onTap: onToggle,
        borderRadius: BorderRadius.circular(6),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48),
          child: Row(
            children: [
              Icon(
                agentIcon(agent.runtime),
                size: 22,
                color: agentAccent(context, agent.runtime),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: colors.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        context.l10n.agentStatus(agent.status),
                        style: TextStyle(color: colors.muted, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
              ),
              Semantics(
                label: context.tr('$name 演示开关', '$name demo toggle'),
                child: Switch(
                  key: ValueKey('agent-switch-${agent.id}'),
                  value: enabled,
                  onChanged: onEnabledChanged,
                ),
              ),
              AnimatedRotation(
                turns: expanded ? 0.5 : 0,
                duration: MagpieMotion.duration(
                  context,
                  MagpieMotion.selection,
                ),
                child: Icon(Icons.expand_more, size: 15, color: colors.muted),
              ),
            ],
          ),
        ),
      ),
    );
    final model = _AgentField(
      key: ValueKey('agent-model-${agent.id}'),
      label: context.tr('$name 模型', '$name model'),
      value: agent.model.isEmpty
          ? context.tr('默认模型', 'Default model')
          : agent.model,
      onTap: () => onOpen(AgentEditorSection.model),
    );
    final access = _AgentField(
      key: ValueKey('agent-access-${agent.id}'),
      label: context.tr('$name 接入方式', '$name connection method'),
      value: context.l10n.agentAccess(agent.access),
      onTap: () => onOpen(AgentEditorSection.access),
    );
    final detailsLabel = context.tr('详情', 'Details');
    final details = Semantics(
      key: ValueKey('agent-details-${agent.id}'),
      button: true,
      label: '$name · $detailsLabel',
      onTap: openDetails,
      excludeSemantics: true,
      child: TextButton.icon(
        onPressed: openDetails,
        iconAlignment: IconAlignment.end,
        icon: const Icon(Icons.chevron_right_rounded, size: 14),
        label: Text(detailsLabel),
        style: TextButton.styleFrom(
          textStyle: const TextStyle(fontSize: 12),
          minimumSize: const Size(0, 44),
          padding: const EdgeInsets.symmetric(horizontal: 6),
        ),
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 5, 12, 5),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final wide =
              constraints.maxWidth >= 600 &&
              MediaQuery.textScalerOf(context).scale(12.5) <= 15;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (wide)
                Row(
                  children: [
                    Expanded(child: summary),
                    const SizedBox(width: 12),
                    SizedBox(width: 196, child: model),
                    const SizedBox(width: 5),
                    SizedBox(width: 126, child: access),
                    const SizedBox(width: 5),
                    SizedBox(width: 76, child: details),
                  ],
                )
              else ...[
                summary,
                Wrap(
                  spacing: 5,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [model, access, details],
                ),
              ],
              AnimatedSize(
                duration: MagpieMotion.duration(context, MagpieMotion.tab),
                curve: MagpieMotion.curveFor(context),
                alignment: Alignment.topCenter,
                child: expanded
                    ? Padding(
                        key: ValueKey('agent-summary-${agent.id}'),
                        padding: const EdgeInsets.fromLTRB(34, 6, 0, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              agent.endpoint,
                              style: TextStyle(
                                color: colors.muted,
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                            if (note.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                note,
                                style: TextStyle(
                                  color: colors.muted,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AgentField extends StatelessWidget {
  const _AgentField({
    required this.label,
    required this.value,
    required this.onTap,
    super.key,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.magpie;
    final shape = BorderRadius.circular(6);
    return Semantics(
      button: true,
      label: label,
      value: value,
      excludeSemantics: true,
      onTap: onTap,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: shape,
          onTap: onTap,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Center(
              widthFactor: 1,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                decoration: BoxDecoration(
                  color: colors.canvasDeep,
                  borderRadius: shape,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        style: TextStyle(
                          color: colors.ink,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    Icon(
                      Icons.expand_more_rounded,
                      size: 16,
                      color: colors.muted,
                    ),
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

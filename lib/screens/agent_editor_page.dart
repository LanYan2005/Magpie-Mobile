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

enum AgentEditorSection { model, access }

class AgentEditorPage extends StatefulWidget {
  const AgentEditorPage({this.agent, this.section, super.key});

  final AgentConfig? agent;
  final AgentEditorSection? section;

  @override
  State<AgentEditorPage> createState() => _AgentEditorPageState();
}

class _AgentEditorPageState extends State<AgentEditorPage> {
  final _formKey = GlobalKey<FormState>();
  final _accessSection = GlobalKey();
  final _modelSection = GlobalKey();
  late final TextEditingController _nameController;
  late final TextEditingController _endpointController;
  late final TextEditingController _modelController;
  late final TextEditingController _noteController;
  late AgentRuntime _runtime;
  late AgentAccess _access;
  late bool _workspaceAccess;
  late bool _commandAccess;
  late bool _networkAccess;
  String? _displayedName;
  String? _displayedNote;
  late bool _nameEdited;
  late bool _noteEdited;

  static const _workspacePermission = '工作区读写';
  static const _commandPermission = '命令执行';
  static const _networkPermission = '网络访问';

  bool get _isEditing => widget.agent != null;

  @override
  void initState() {
    super.initState();
    final agent = widget.agent;
    _runtime = agent?.runtime ?? AgentRuntime.claudeCode;
    _access = agent?.access ?? AgentAccess.localCli;
    final initialName = agent?.name ?? _runtime.label;
    _displayedName = initialName;
    _nameEdited = false;
    _nameController = TextEditingController(text: initialName)
      ..addListener(_onNameChanged);
    _endpointController = TextEditingController(
      text: agent?.endpoint ?? _defaultEndpoint(_access),
    );
    _modelController = TextEditingController(
      text: agent?.model ?? _defaultModel(_runtime),
    );
    final initialNote = agent?.note ?? '';
    _displayedNote = initialNote;
    _noteEdited = false;
    _noteController = TextEditingController(text: initialNote)
      ..addListener(_onNoteChanged);
    _workspaceAccess =
        agent?.permissions.contains(_workspacePermission) ?? true;
    _commandAccess = agent?.permissions.contains(_commandPermission) ?? false;
    _networkAccess = agent?.permissions.contains(_networkPermission) ?? false;
    final section = widget.section;
    if (section == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final target = switch (section) {
        AgentEditorSection.model => _modelSection.currentContext,
        AgentEditorSection.access => _accessSection.currentContext,
      };
      if (target == null) return;
      Scrollable.ensureVisible(
        target,
        alignment: 0.05,
        duration: MagpieMotion.duration(target, MagpieMotion.tab),
        curve: MagpieMotion.curveFor(target),
      );
    });
  }

  void _onNameChanged() {
    if (_nameController.text != _displayedName) _nameEdited = true;
  }

  void _onNoteChanged() {
    if (_noteController.text != _displayedNote) _noteEdited = true;
  }

  String _runtimeDefaultName(AgentRuntime runtime) =>
      context.tr(runtime.label, switch (runtime) {
        AgentRuntime.claudeCode => 'Claude Code',
        AgentRuntime.codex => 'Codex',
        AgentRuntime.geminiCli => 'Gemini CLI',
        AgentRuntime.openAiCompatible => 'OpenAI-compatible',
      });

  String _defaultNote(AgentConfig? agent) => agent == null
      ? context.tr(
          '演示 Agent 配置，不会启动真实进程。',
          'Demo Agent configuration; no real process is launched.',
        )
      : agent.localizedNote(context.l10n);

  void _syncLocalizedFields() {
    if (!_nameEdited) {
      final name =
          widget.agent?.localizedName(context.l10n) ??
          _runtimeDefaultName(_runtime);
      if (_displayedName != name) {
        _displayedName = name;
        _nameController.value = TextEditingValue(
          text: name,
          selection: TextSelection.collapsed(offset: name.length),
        );
      }
    }
    if (!_noteEdited) {
      final note = _noteController.text.trim().isEmpty
          ? _defaultNote(widget.agent)
          : widget.agent?.localizedNote(context.l10n) ?? _noteController.text;
      if (_displayedNote != note) {
        _displayedNote = note;
        _noteController.value = TextEditingValue(
          text: note,
          selection: TextSelection.collapsed(offset: note.length),
        );
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLocalizedFields();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _endpointController.dispose();
    _modelController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  static String _defaultEndpoint(AgentAccess access) {
    return switch (access) {
      AgentAccess.localCli => '~/work/magpie',
      AgentAccess.ssh => 'builder@build.example.com:22',
      AgentAccess.termux => '127.0.0.1:8787',
      AgentAccess.httpBridge => 'http://127.0.0.1:8090',
    };
  }

  static String _defaultModel(AgentRuntime runtime) {
    return switch (runtime) {
      AgentRuntime.claudeCode => 'claude-sonnet-5',
      AgentRuntime.codex => 'gpt-5-codex',
      AgentRuntime.geminiCli => 'gemini-2.5-pro',
      AgentRuntime.openAiCompatible => 'local-model',
    };
  }

  void _selectRuntime(AgentRuntime runtime) {
    final previousModel = _defaultModel(_runtime);
    setState(() {
      _runtime = runtime;
      if (!_isEditing && !_nameEdited) _syncLocalizedFields();
      if (_modelController.text.trim().isEmpty ||
          _modelController.text.trim() == previousModel) {
        _modelController.text = _defaultModel(runtime);
      }
    });
  }

  void _selectAccess(AgentAccess access) {
    final previousDefault = _defaultEndpoint(_access);
    setState(() {
      _access = access;
      if (_endpointController.text.trim().isEmpty ||
          _endpointController.text.trim() == previousDefault) {
        _endpointController.text = _defaultEndpoint(access);
      }
    });
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final store = MagpieScope.of(context);
    final permissions = <String>[
      if (_workspaceAccess) _workspacePermission,
      if (_commandAccess) _commandPermission,
      if (_networkAccess) _networkPermission,
    ];
    final agent = AgentConfig(
      id: widget.agent?.id ?? store.newId('agent'),
      name: !_nameEdited && widget.agent != null
          ? widget.agent!.name
          : _nameController.text.trim(),
      runtime: _runtime,
      access: _access,
      endpoint: _endpointController.text.trim(),
      model: _modelController.text.trim().isEmpty
          ? ''
          : _modelController.text.trim(),
      status: widget.agent?.status ?? AgentStatus.needsSetup,
      permissions: permissions,
      note: !_noteEdited && widget.agent != null
          ? widget.agent!.note
          : _noteController.text.trim(),
    );
    store.upsertAgent(agent);
    showDemoToast(
      context,
      _isEditing
          ? context.tr('已更新演示 Agent', 'Demo Agent updated')
          : context.tr(
              '已创建演示 Agent（未接入）',
              'Demo Agent created (not connected)',
            ),
    );
    Navigator.of(context).pop(agent);
  }

  @override
  Widget build(BuildContext context) {
    return AppCanvas(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: pagePadding.copyWith(bottom: 0),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: PageTopBar(
                      title: _isEditing
                          ? context.tr('编辑 Agent', 'Edit Agent')
                          : context.tr('新建 Agent', 'New Agent'),
                      onBack: () => Navigator.of(context).pop(),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: pagePadding,
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 720),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DemoBadge(
                              label: context.tr(
                                '本地演示配置',
                                'Local demo configuration',
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              context.tr(
                                '运行时与接入方式',
                                'Runtime and connection method',
                              ),
                              style: Theme.of(
                                context,
                              ).textTheme.titleMedium?.copyWith(fontSize: 16),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              context.tr(
                                '同一套界面覆盖 Android 与 iOS；实际进程、'
                                    '端口和文件权限尚未接入。',
                                'The same interface supports Android and iOS; actual processes, ports, and file permissions are not connected.',
                              ),
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(fontSize: 13),
                            ),
                            const SizedBox(height: 22),
                            _FormLabel(context.tr('配置类型', 'Runtime')),
                            const SizedBox(height: 8),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final width = (constraints.maxWidth - 8) / 2;
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final runtime in AgentRuntime.values)
                                      SizedBox(
                                        width: width,
                                        child: _RuntimeOption(
                                          runtime: runtime,
                                          selected: _runtime == runtime,
                                          onTap: () => _selectRuntime(runtime),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            _FormLabel(
                              context.tr('接入方式', 'Connection method'),
                              key: _accessSection,
                            ),
                            const SizedBox(height: 8),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final width = (constraints.maxWidth - 8) / 2;
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final access in AgentAccess.values)
                                      SizedBox(
                                        width: width,
                                        child: _AccessOption(
                                          access: access,
                                          selected: _access == access,
                                          onTap: () => _selectAccess(access),
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            if (_access == AgentAccess.termux) ...[
                              const SizedBox(height: 10),
                              InfoBanner(
                                icon: Icons.shield_outlined,
                                title: context.tr(
                                  'Termux 不是系统级沙箱',
                                  'Termux is not a system-level sandbox',
                                ),
                                body: context.tr(
                                  '它是 Android 上的用户空间终端。iOS 不提供对等能力；'
                                      '真实产品需要独立目录、SAF 授权与受控桥接。',
                                  'It is a user-space terminal on Android. iOS has no equivalent; production apps need a dedicated directory, SAF authorization, and a controlled bridge.',
                                ),
                                tint: context.magpie.amberSoft,
                                accent: context.magpie.amber,
                                onTap: () => showSandboxSheet(context),
                                actionLabel: context.tr(
                                  '查看沙箱边界',
                                  'View sandbox details',
                                ),
                              ),
                            ],
                            const SizedBox(height: 20),
                            _FormLabel(context.tr('名称', 'Name')),
                            const SizedBox(height: 7),
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: context.tr(
                                  '例如 移动端 Claude',
                                  'e.g. Mobile Claude',
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return context.tr(
                                    '请输入 Agent 名称',
                                    'Enter an Agent name',
                                  );
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            _FormLabel(
                              context.l10n.agentAccessFieldLabel(_access),
                            ),
                            const SizedBox(height: 7),
                            TextFormField(
                              controller: _endpointController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: context.l10n.agentAccessFieldHint(
                                  _access,
                                ),
                                helperText: context.tr(
                                  '仅作为界面占位，不会访问此位置。',
                                  'For display only; this location will not be accessed.',
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return context.tr(
                                    '请输入${_access.fieldLabel}',
                                    'Enter ${context.l10n.agentAccessFieldLabel(_access)}',
                                  );
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            _FormLabel(
                              context.tr('模型', 'Model'),
                              key: _modelSection,
                            ),
                            const SizedBox(height: 7),
                            TextFormField(
                              key: const ValueKey('agent-model-field'),
                              controller: _modelController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: 'claude-sonnet-5',
                                helperText: context.tr(
                                  '可留空，真实接入时由运行时决定。',
                                  'Optional; the runtime determines this when connected.',
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            _FormLabel(context.tr('备注', 'Note')),
                            const SizedBox(height: 7),
                            TextFormField(
                              controller: _noteController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: context.tr(
                                  '这个 Agent 的用途或限制',
                                  'Purpose or limitations of this Agent',
                                ),
                              ),
                            ),
                            const SizedBox(height: 20),
                            SectionHeader(
                              title: context.tr('权限示意', 'Permissions'),
                              subtitle: context.tr(
                                '仅记录界面状态，不申请系统权限',
                                'UI state only; no system permissions are requested',
                              ),
                            ),
                            const SizedBox(height: 10),
                            SurfaceCard(
                              padding: const EdgeInsets.fromLTRB(16, 5, 8, 5),
                              child: Column(
                                children: [
                                  _PermissionRow(
                                    title: context.tr(
                                      '工作区读写',
                                      'Workspace read/write',
                                    ),
                                    subtitle: context.tr(
                                      '读取项目与生成文件',
                                      'Read projects and create files',
                                    ),
                                    value: _workspaceAccess,
                                    onChanged: (value) {
                                      setState(() => _workspaceAccess = value);
                                    },
                                  ),
                                  const SoftDivider(),
                                  _PermissionRow(
                                    title: context.tr('命令执行', 'Run commands'),
                                    subtitle: context.tr(
                                      '运行 CLI 或启动子进程',
                                      'Run a CLI or start a child process',
                                    ),
                                    value: _commandAccess,
                                    onChanged: (value) {
                                      setState(() => _commandAccess = value);
                                    },
                                  ),
                                  const SoftDivider(),
                                  _PermissionRow(
                                    title: context.tr('网络访问', 'Network access'),
                                    subtitle: context.tr(
                                      '远程 SSH、HTTP 桥接或本地端口',
                                      'Remote SSH, HTTP bridge, or local ports',
                                    ),
                                    value: _networkAccess,
                                    onChanged: (value) {
                                      setState(() => _networkAccess = value);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                            InfoBanner(
                              icon: Icons.lock_outline_rounded,
                              title: context.tr(
                                '生产版本需要逐项授权',
                                'Production builds require per-permission authorization',
                              ),
                              body: context.tr(
                                '真实接入时应把工作区、命令和网络能力拆分为'
                                    '显式授权，并为高风险操作保留人工确认。',
                                'When connected, workspace, command, and network capabilities should be authorized separately, with manual confirmation for high-impact actions.',
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
                decoration: BoxDecoration(
                  color: context.magpie.canvas.withValues(alpha: 0.94),
                  border: Border(top: BorderSide(color: context.magpie.line)),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        key: const ValueKey('save-agent-button'),
                        onPressed: _save,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          _isEditing
                              ? context.tr('保存更改', 'Save changes')
                              : context.tr('创建 Agent', 'Create Agent'),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormLabel extends StatelessWidget {
  const _FormLabel(this.label, {super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: context.magpie.ink,
        fontSize: 12.5,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _RuntimeOption extends StatelessWidget {
  const _RuntimeOption({
    required this.runtime,
    required this.selected,
    required this.onTap,
  });

  final AgentRuntime runtime;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = agentAccent(context, runtime);

    return Material(
      color: selected ? context.magpie.mintSoft : context.magpie.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? context.magpie.jade : context.magpie.line,
          width: selected ? 1.3 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(agentIcon(runtime), size: 18, color: accent),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      runtime.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.magpie.ink,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      size: 15,
                      color: context.magpie.jade,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.agentRuntimeDescription(runtime),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: context.magpie.muted,
                  fontSize: 9,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccessOption extends StatelessWidget {
  const _AccessOption({
    required this.access,
    required this.selected,
    required this.onTap,
  });

  final AgentAccess access;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final icon = switch (access) {
      AgentAccess.localCli => Icons.terminal_rounded,
      AgentAccess.ssh => Icons.lan_outlined,
      AgentAccess.termux => Icons.android_rounded,
      AgentAccess.httpBridge => Icons.http_rounded,
    };

    return Material(
      color: selected ? context.magpie.mintSoft : context.magpie.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: selected ? context.magpie.jade : context.magpie.line,
          width: selected ? 1.3 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Icon(
                icon,
                size: 17,
                color: selected ? context.magpie.jade : context.magpie.muted,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.agentAccess(access),
                      style: TextStyle(
                        color: context.magpie.ink,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.agentAccessBlurb(access),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.magpie.faint,
                        fontSize: 8.5,
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PermissionRow extends StatelessWidget {
  const _PermissionRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: context.magpie.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 10.5),
                ),
              ],
            ),
          ),
        ),
        Switch(value: value, onChanged: onChanged),
      ],
    );
  }
}

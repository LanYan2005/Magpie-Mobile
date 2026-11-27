import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/magpie_l10n.dart';
import '../core/magpie_motion.dart';
import '../core/magpie_theme.dart';
import '../core/magpie_tokens.dart';
import '../data/demo_data.dart';
import '../models/magpie_models.dart';
import '../state/magpie_store.dart';
import 'primitives.dart';

class SheetSurface extends StatelessWidget {
  const SheetSurface({
    required this.child,
    this.padding = const EdgeInsets.fromLTRB(16, 8, 16, 16),
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.9,
      ),
      decoration: BoxDecoration(
        color: context.tokens.card,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(MagpieMetrics.popRadius),
        ),
        border: Border(top: BorderSide(color: context.magpie.line)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class SheetHandle extends StatelessWidget {
  const SheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 32,
        height: 3,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: context.magpie.lineStrong,
          borderRadius: BorderRadius.circular(99),
        ),
      ),
    );
  }
}

class SheetTitle extends StatelessWidget {
  const SheetTitle({
    required this.title,
    this.subtitle,
    this.icon,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          IconTile(
            icon: icon!,
            size: 42,
            iconSize: 19,
            radius: 13,
            background: context.magpie.mintSoft,
            foreground: context.magpie.jade,
            borderColor: context.magpie.mint,
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.headlineMedium?.copyWith(fontSize: 21),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        ?trailing,
      ],
    );
  }
}

Future<void> showSandboxSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: MagpieMotion.overlays(context),
    builder: (sheetContext) {
      return SheetSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            SheetTitle(
              title: context.tr('沙箱与权限边界', 'Sandbox and permission boundaries'),
              subtitle: context.tr(
                '真实接入前必须处理的系统差异',
                'Platform differences to account for before real integration',
              ),
              icon: Icons.shield_outlined,
              trailing: RoundIconButton(
                icon: Icons.close_rounded,
                onPressed: () => Navigator.of(sheetContext).pop(),
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _SandboxNote(
                      icon: Icons.terminal_rounded,
                      accent: context.magpie.jade,
                      background: context.magpie.mintSoft,
                      platform: 'ANDROID · TERMUX',
                      title: context.tr(
                        'Termux 不是系统级安全沙箱',
                        'Termux is not an OS-level security sandbox',
                      ),
                      body: context.tr(
                        'Termux 提供的是用户空间 Linux 环境，并不等于 Android '
                            '的系统级隔离。真实接入时应使用独立工作资料（Work Profile）'
                            '或专用目录，并通过 SAF / scoped storage 只授权项目路径。',
                        'Termux provides a user-space Linux environment, not Android '
                            'system-level isolation. For real integration, use a separate '
                            'Work Profile or dedicated directory and grant access only to '
                            'project paths through SAF / scoped storage.',
                      ),
                    ),
                    SizedBox(height: 10),
                    _SandboxNote(
                      icon: Icons.phone_iphone_rounded,
                      accent: context.magpie.cobalt,
                      background: context.magpie.cobaltSoft,
                      platform: 'IOS',
                      title: context.tr(
                        '文件与后台能力受到更严格限制',
                        'File and background capabilities are more restricted',
                      ),
                      body: context.tr(
                        'iOS App 只能访问自身容器，以及用户通过文件 App / Finder '
                            '明确共享的目录。后台常驻、本地端口与外部进程管理均受系统约束，'
                            '不能照搬 Termux 的接入方式。',
                        'iOS apps can access only their own container and directories '
                            'explicitly shared through the Files app / Finder. Background '
                            'services, local ports, and external process management are '
                            'restricted by the system; the Termux integration model does not apply.',
                      ),
                    ),
                    SizedBox(height: 10),
                    _SandboxNote(
                      icon: Icons.extension_outlined,
                      accent: context.magpie.jade,
                      background: context.magpie.mintSoft,
                      platform: 'SKILLS · MCP',
                      title: context.tr(
                        '只管理与导出配置',
                        'Manage and export configurations only',
                      ),
                      body: context.tr(
                        'Skills 可在 Magpie 内查看、编辑演示内容并导出清单；'
                            'MCP 远程 HTTP(S) 配置可导出。stdio 本地服务只保存参数，'
                            '不会在 Android/iOS 上启动，也不读写其他 App 的私有目录。',
                        'Skills can be viewed, have demo content edited, and be exported '
                            'as a manifest in Magpie. Remote MCP HTTP(S) settings can be '
                            'exported. Local stdio services only store parameters: they are '
                            'not launched on Android/iOS and do not access other apps’ private directories.',
                      ),
                    ),
                    SizedBox(height: 10),
                    _SandboxNote(
                      icon: Icons.science_outlined,
                      accent: context.magpie.amber,
                      background: context.magpie.amberSoft,
                      platform: 'THIS PROTOTYPE',
                      title: context.tr(
                        '当前仅展示界面状态',
                        'This prototype only displays interface states',
                      ),
                      body: context.tr(
                        '本原型不会申请存储、终端、网络或悬浮窗权限，不会打开文件选择器，'
                            '不会启动进程，也不会向任何 MCP / 模型端点发起请求。',
                        'This prototype does not request storage, terminal, network, or '
                            'overlay permissions; open a file picker; start processes; or '
                            'send requests to any MCP or model endpoint.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(sheetContext).pop(),
                child: Text(context.tr('我知道了', 'Got it')),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _SandboxNote extends StatelessWidget {
  const _SandboxNote({
    required this.icon,
    required this.accent,
    required this.background,
    required this.platform,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final Color accent;
  final Color background;
  final String platform;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: context.tokens.card,
        borderRadius: BorderRadius.circular(MagpieMetrics.listRadius),
        border: Border.all(color: context.tokens.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: accent),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: context.tokens.fg,
                    fontSize: MagpieType.rowName,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              MagpieBadge(label: platform),
            ],
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.only(left: 22),
            child: Text(
              body,
              style: TextStyle(
                color: context.tokens.muted,
                fontSize: MagpieType.rowSub,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> showSkillEditorSheet(
  BuildContext context,
  MagpieStore store, {
  SkillResource? skill,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: MagpieMotion.overlays(context),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: _SkillEditorSheet(store: store, skill: skill),
      );
    },
  );
}

class _SkillEditorSheet extends StatefulWidget {
  const _SkillEditorSheet({required this.store, this.skill});

  final MagpieStore store;
  final SkillResource? skill;

  @override
  State<_SkillEditorSheet> createState() => _SkillEditorSheetState();
}

class _SkillEditorSheetState extends State<_SkillEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _instructionsController;
  late final String _originalDescription;
  late final String _originalInstructions;

  bool get _isEditing => widget.skill != null;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    _nameController = TextEditingController(text: widget.skill?.name ?? '');
    _originalDescription =
        widget.skill?.localizedDescription(context.l10n) ?? '';
    _originalInstructions =
        widget.skill?.localizedInstructions(context.l10n) ?? '';
    _descriptionController = TextEditingController(text: _originalDescription);
    _instructionsController = TextEditingController(
      text: _originalInstructions,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final base = widget.skill;
    widget.store.upsertSkill(
      SkillResource(
        id: base?.id ?? widget.store.newId('skill'),
        name: _nameController.text.trim(),
        description:
            _descriptionController.text.trim() == _originalDescription.trim() &&
                base != null
            ? base.description
            : _descriptionController.text.trim(),
        origin: base?.origin ?? ResourceOrigin.local,
        version: base?.version ?? 'v0.1',
        permissions: base?.permissions ?? const ['读取工作区'],
        enabled: base?.enabled ?? true,
        toolCount: base?.toolCount ?? 1,
        instructions:
            _instructionsController.text.trim() ==
                    _originalInstructions.trim() &&
                base != null
            ? base.instructions
            : _instructionsController.text.trim(),
      ),
    );
    showDemoToast(
      context,
      _isEditing
          ? context.tr(
              '已更新 Skill 演示内容（未写入文件）',
              'Skill demo content updated (not written to a file)',
            )
          : context.tr(
              '已新增 Skill 演示配置（未写入文件）',
              'Skill demo configuration added (not written to a file)',
            ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return SheetSurface(
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              SheetTitle(
                title: _isEditing
                    ? context.tr('编辑 Skill', 'Edit Skill')
                    : context.tr('新增 Skill', 'Add Skill'),
                subtitle: context.tr(
                  '仅在 Magpie 内管理演示内容',
                  'Manage demo content in Magpie only',
                ),
                icon: Icons.extension_outlined,
                trailing: MagpieBadge(
                  label: context.tr('演示', 'Demo'),
                  tone: MagpieBadgeTone.accent,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('skill-name-field'),
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: context.tr('名称', 'Name'),
                  hintText: context.tr('例如 code-review', 'e.g. code-review'),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.tr('请输入 Skill 名称', 'Enter a Skill name');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 11),
              TextFormField(
                key: const ValueKey('skill-description-field'),
                controller: _descriptionController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: context.tr('简介', 'Description'),
                  hintText: context.tr(
                    '一句话说明这个 Skill 做什么',
                    'Briefly describe what this Skill does',
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.tr('请输入简介', 'Enter a description');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 11),
              TextFormField(
                key: const ValueKey('skill-instructions-field'),
                controller: _instructionsController,
                minLines: 4,
                maxLines: 7,
                decoration: InputDecoration(
                  labelText: context.tr('演示内容', 'Demo content'),
                  hintText: context.tr(
                    '写入流程说明或提示词，仅用于界面演示',
                    'Enter workflow notes or prompts for display only',
                  ),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 13),
              InfoBanner(
                icon: Icons.edit_note_rounded,
                title: context.tr(
                  '只编辑内存中的演示内容',
                  'Edit in-memory demo content only',
                ),
                body: context.tr(
                  '不会读取或写入任何目录，不会解析 Skill 包，也不会执行 Skill。'
                      'Android/iOS 都不会通过 Termux 或其他桥接启动它。',
                  'No directories are read or written. Skill packages are not parsed '
                      'or executed. Nothing is launched through Termux or another bridge on Android/iOS.',
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('save-skill-button'),
                  onPressed: _save,
                  child: Text(
                    _isEditing
                        ? context.tr('保存演示内容', 'Save demo content')
                        : context.tr('新增 Skill', 'Add Skill'),
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

Future<void> showExportSkillSheet(BuildContext context, MagpieStore store) {
  final manifest = const JsonEncoder.withIndent('  ').convert({
    'kind': 'magpie.skills.manifest',
    'demo': true,
    'note': '仅由界面在内存中生成，未写入文件',
    'skills': [
      for (final skill in store.skills)
        {
          'name': skill.name,
          'description': skill.description,
          'origin': skill.origin.label,
          'version': skill.version,
          'enabled': skill.enabled,
          'permissions': skill.permissions,
          'toolCount': skill.toolCount,
          'instructions': skill.instructions,
        },
    ],
  });

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: MagpieMotion.overlays(context),
    builder: (sheetContext) {
      return SheetSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            SheetTitle(
              title: context.tr('导出 Skills 清单', 'Export Skills manifest'),
              subtitle: context.tr(
                '${store.skills.length} 个 Skill · 演示预览',
                '${store.skills.length} Skills · demo preview',
              ),
              icon: Icons.ios_share_rounded,
              trailing: DemoBadge(label: context.tr('演示', 'Demo')),
            ),
            const SizedBox(height: 16),
            InfoBanner(
              icon: Icons.lock_outline_rounded,
              title: context.tr('导出仍为演示', 'Demo export only'),
              body: context.tr(
                '这里只生成一份内存中的清单预览。不会写入文件，'
                    '不会打开系统分享面板，也不会复制到剪贴板。',
                'This only generates an in-memory manifest preview. No file is written, '
                    'the system share sheet is not opened, and nothing is copied to the clipboard.',
              ),
              tint: context.magpie.amberSoft,
              accent: context.magpie.amber,
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxHeight: 220),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.magpie.canvas,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.magpie.line),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  manifest,
                  style: TextStyle(
                    color: context.magpie.inkSoft,
                    fontSize: 10,
                    height: 1.5,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('confirm-export-skills-button'),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  showDemoToast(
                    context,
                    context.tr(
                      '演示环境：未写入文件，也未打开分享面板',
                      'Demo only: no file written and share sheet not opened',
                    ),
                  );
                },
                icon: const Icon(Icons.archive_outlined, size: 16),
                label: Text(context.tr('确认导出（演示）', 'Confirm export (demo)')),
              ),
            ),
          ],
        ),
      );
    },
  );
}

class _SelectRow extends StatelessWidget {
  const _SelectRow({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(
        color: selected ? context.magpie.jade : context.magpie.line,
      ),
    );
    return Semantics(
      selected: selected,
      button: true,
      label: '$title. $subtitle',
      child: AnimatedContainer(
        duration: MagpieMotion.duration(context, MagpieMotion.selection),
        decoration: ShapeDecoration(
          color: selected ? context.magpie.mintSoft : context.magpie.paper,
          shape: shape,
        ),
        child: Material(
          color: Colors.transparent,
          shape: shape,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            excludeFromSemantics: true,
            child: Padding(
              padding: const EdgeInsets.all(13),
              child: Row(
                children: [
                  Icon(
                    icon,
                    size: 19,
                    color: selected
                        ? context.magpie.jade
                        : context.magpie.muted,
                  ),
                  const SizedBox(width: 11),
                  Expanded(
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
                  Icon(
                    selected
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_off_rounded,
                    size: 18,
                    color: selected
                        ? context.magpie.jade
                        : context.magpie.faint,
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

Future<void> showMcpEditorSheet(
  BuildContext context,
  MagpieStore store, {
  McpServerConfig? server,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: MagpieMotion.overlays(context),
    builder: (sheetContext) {
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: _McpEditorSheet(store: store, server: server),
      );
    },
  );
}

class _McpEditorSheet extends StatefulWidget {
  const _McpEditorSheet({required this.store, this.server});

  final MagpieStore store;
  final McpServerConfig? server;

  @override
  State<_McpEditorSheet> createState() => _McpEditorSheetState();
}

class _McpEditorSheetState extends State<_McpEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _endpointController;
  late final TextEditingController _authController;
  late final String _originalDescription;
  late final String _originalAuthReference;
  late McpTransport _transport;

  bool get _isEditing => widget.server != null;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_initialized) return;
    _initialized = true;
    final server = widget.server;
    _nameController = TextEditingController(text: server?.name ?? '');
    _originalDescription = server?.localizedDescription(context.l10n) ?? '';
    _descriptionController = TextEditingController(text: _originalDescription);
    _endpointController = TextEditingController(text: server?.endpoint ?? '');
    _originalAuthReference = server == null
        ? ''
        : context.l10n.reference(server.authReference);
    _authController = TextEditingController(text: _originalAuthReference);
    _transport = server?.transport ?? McpTransport.streamableHttp;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _endpointController.dispose();
    _authController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final base = widget.server;
    final isStdio = _transport.isStdio;
    final description = _descriptionController.text.trim();
    widget.store.upsertMcpServer(
      McpServerConfig(
        id: base?.id ?? widget.store.newId('mcp'),
        name: _nameController.text.trim(),
        description: description == _originalDescription && base != null
            ? base.description
            : description.isEmpty
            ? (isStdio
                  ? 'stdio 配置示例：仅保存参数，不启动进程。'
                  : '远程 HTTP 配置示例：仅保存参数，不发起连接。')
            : description,
        transport: _transport,
        remote: _transport.isRemote,
        status: isStdio ? McpStatus.offline : McpStatus.needsSetup,
        endpoint: _endpointController.text.trim(),
        permissions: base?.permissions ?? const ['工具调用（待确认）'],
        toolCount: base?.toolCount ?? 0,
        enabled: base?.enabled ?? false,
        authReference: _authController.text.trim().isEmpty
            ? (base != null &&
                      _originalAuthReference ==
                          context.l10n.reference(base.authReference)
                  ? base.authReference
                  : '未设置')
            : _authController.text.trim() == _originalAuthReference &&
                  base != null
            ? base.authReference
            : _authController.text.trim(),
      ),
    );
    showDemoToast(
      context,
      isStdio
          ? context.tr(
              '已保存 stdio 配置（仅管理，不启动进程）',
              'stdio settings saved (managed only; process not started)',
            )
          : context.tr(
              '已保存远程 MCP 配置（不会发起连接）',
              'Remote MCP settings saved (no connection made)',
            ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isStdio = _transport.isStdio;
    return SheetSurface(
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SheetHandle(),
              SheetTitle(
                title: _isEditing
                    ? context.tr('编辑 MCP 配置', 'Edit MCP settings')
                    : context.tr('新增 MCP 配置', 'Add MCP settings'),
                subtitle: context.tr(
                  '只管理配置清单，不握手、不启动进程',
                  'Manage configuration only; no handshake or process launch',
                ),
                icon: Icons.hub_outlined,
                trailing: DemoBadge(
                  label: context.tr('配置演示', 'Configuration demo'),
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                key: const ValueKey('mcp-name-field'),
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: context.tr('名称', 'Name'),
                  hintText: context.tr(
                    '例如 notion-remote',
                    'e.g. notion-remote',
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return context.tr('请输入 MCP 名称', 'Enter an MCP name');
                  }
                  return null;
                },
              ),
              const SizedBox(height: 11),
              TextFormField(
                key: const ValueKey('mcp-endpoint-field'),
                controller: _endpointController,
                keyboardType: isStdio ? TextInputType.text : TextInputType.url,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: isStdio
                      ? context.tr('启动命令（仅记录）', 'Launch command (record only)')
                      : context.tr('远程地址', 'Remote URL'),
                  hintText: isStdio
                      ? 'npx -y @modelcontextprotocol/server-filesystem /workspace'
                      : 'https://mcp.example.com/mcp',
                  helperText: isStdio
                      ? context.tr(
                          '只保存命令文本，不在 Android/iOS 上启动。',
                          'Command text is stored only; not launched on Android/iOS.',
                        )
                      : context.tr(
                          '仅保存配置，不会探测或连接该地址。',
                          'Settings are stored only; this address is not probed or contacted.',
                        ),
                ),
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return isStdio
                        ? context.tr('请输入命令占位文本', 'Enter a command placeholder')
                        : context.tr(
                            '请输入 http:// 或 https:// 地址',
                            'Enter an http:// or https:// URL',
                          );
                  }
                  if (!isStdio &&
                      !text.startsWith('http://') &&
                      !text.startsWith('https://')) {
                    return context.tr(
                      '远程配置需要 http:// 或 https:// 地址',
                      'Remote settings require an http:// or https:// URL',
                    );
                  }
                  return null;
                },
              ),
              const SizedBox(height: 11),
              TextFormField(
                key: const ValueKey('mcp-description-field'),
                controller: _descriptionController,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: context.tr('说明（可选）', 'Description (optional)'),
                  hintText: context.tr(
                    '一句话描述这个 MCP 的用途',
                    'Briefly describe what this MCP is for',
                  ),
                ),
              ),
              const SizedBox(height: 11),
              TextFormField(
                key: const ValueKey('mcp-auth-field'),
                controller: _authController,
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: context.tr('密钥引用（可选）', 'Key reference (optional)'),
                  hintText: 'env:MCP_TOKEN',
                  helperText: context.tr(
                    '仅保存占位引用，不会读取环境变量或明文密钥。',
                    'Placeholder reference only; environment variables and plaintext secrets are not read.',
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.tr('传输方式', 'Transport'),
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              for (final transport in McpTransport.values) ...[
                _SelectRow(
                  key: ValueKey(
                    transport == McpTransport.stdio
                        ? 'mcp-transport-stdio'
                        : transport == McpTransport.sse
                        ? 'mcp-transport-sse'
                        : 'mcp-transport-http',
                  ),
                  selected: _transport == transport,
                  icon: transport.isStdio
                      ? Icons.dns_outlined
                      : Icons.language_rounded,
                  title: transport.isStdio
                      ? context.tr('stdio（本地）', 'stdio (local)')
                      : '${transport.label}（${context.tr('远程', 'remote')}）',
                  subtitle: transport.isStdio
                      ? context.tr(
                          '只保存启动命令，不启动进程',
                          'Store the launch command only; do not start a process',
                        )
                      : context.tr(
                          '远程 HTTP(S) 配置，可导出',
                          'Remote HTTP(S) settings; can be exported',
                        ),
                  onTap: () {
                    setState(() => _transport = transport);
                  },
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 5),
              InfoBanner(
                icon: isStdio ? Icons.terminal_rounded : Icons.wifi_off_rounded,
                title: isStdio
                    ? context.tr(
                        'stdio 在 Android/iOS 上只管理配置',
                        'stdio settings are managed only on Android/iOS',
                      )
                    : context.tr(
                        '不会探测或连接该地址',
                        'This address will not be probed or contacted',
                      ),
                body: isStdio
                    ? context.tr(
                        '不会启动本地进程，不读写其他 App 的私有目录，'
                            '也不会通过 Termux 做桥接执行。',
                        'No local process is started, no other app’s private directories '
                            'are accessed, and no execution is bridged through Termux.',
                      )
                    : context.tr(
                        '只保存配置清单；远程 HTTP(S) 配置可通过导出查看预览。',
                        'Only the configuration manifest is stored. Remote HTTP(S) settings can be previewed via export.',
                      ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  key: const ValueKey('save-mcp-button'),
                  onPressed: _save,
                  child: Text(
                    _isEditing
                        ? context.tr('保存配置', 'Save settings')
                        : context.tr('新增 MCP 配置', 'Add MCP settings'),
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

Future<void> showMcpExportSheet(BuildContext context, MagpieStore store) {
  final remoteServers = store.remoteMcpServers;
  final manifest = const JsonEncoder.withIndent('  ').convert({
    'kind': 'magpie.mcp.remote.manifest',
    'demo': true,
    'note': '仅包含远程 HTTP(S) 配置；仅由界面在内存中生成，未写入文件',
    'servers': [
      for (final server in remoteServers)
        {
          'name': server.name,
          'transport': server.transport.label,
          'endpoint': server.endpoint,
          'authReference': server.authReference,
          'permissions': server.permissions,
          'enabled': server.enabled,
        },
    ],
  });

  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: MagpieMotion.overlays(context),
    builder: (sheetContext) {
      return SheetSurface(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SheetHandle(),
            SheetTitle(
              title: context.tr('导出远程 MCP 配置', 'Export remote MCP settings'),
              subtitle: context.tr(
                '${remoteServers.length} 个远程 HTTP(S) 配置 · 演示预览',
                '${remoteServers.length} remote HTTP(S) settings · demo preview',
              ),
              icon: Icons.ios_share_rounded,
              trailing: DemoBadge(label: context.tr('演示', 'Demo')),
            ),
            const SizedBox(height: 16),
            InfoBanner(
              icon: Icons.lock_outline_rounded,
              title: context.tr(
                '仅导出远程配置，且仍为演示',
                'Remote settings only; demo export',
              ),
              body: context.tr(
                'stdio 本地服务只保留在本机配置中，不进入导出清单。'
                    '这里只生成内存预览，不会写入文件或打开分享面板。',
                'Local stdio services stay in local settings and are excluded from the '
                    'export manifest. This only generates an in-memory preview; no file is '
                    'written and no share sheet is opened.',
              ),
              tint: context.magpie.amberSoft,
              accent: context.magpie.amber,
            ),
            const SizedBox(height: 12),
            if (remoteServers.isEmpty)
              SurfaceCard(
                padding: EdgeInsets.zero,
                child: EmptyState(
                  icon: Icons.cloud_off_outlined,
                  title: context.tr('还没有远程 MCP', 'No remote MCP settings yet'),
                  body: context.tr(
                    '新增 SSE 或 Streamable HTTP 配置后即可预览导出清单。',
                    'Add SSE or Streamable HTTP settings to preview the export manifest.',
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 220),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.magpie.canvas,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.magpie.line),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    manifest,
                    style: TextStyle(
                      color: context.magpie.inkSoft,
                      fontSize: 10,
                      height: 1.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('confirm-export-mcp-button'),
                onPressed: () {
                  Navigator.of(sheetContext).pop();
                  showDemoToast(
                    context,
                    context.tr(
                      '演示环境：未写入文件，也未发起远程连接',
                      'Demo only: no file written and no remote connection made',
                    ),
                  );
                },
                icon: const Icon(Icons.archive_outlined, size: 16),
                label: Text(context.tr('确认导出（演示）', 'Confirm export (demo)')),
              ),
            ),
          ],
        ),
      );
    },
  );
}

Future<void> showSkillDetailSheet(
  BuildContext context,
  MagpieStore store,
  SkillResource skill,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: MagpieMotion.overlays(context),
    builder: (sheetContext) {
      return SheetSurface(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle(),
              SheetTitle(
                title: skill.name,
                subtitle:
                    '${context.l10n.resourceOrigin(skill.origin)} ${context.tr('资源', 'resource')} · ${skill.version}',
                icon: Icons.extension_outlined,
                trailing: StatusPill(
                  label: skill.enabled
                      ? context.tr('已启用', 'Enabled')
                      : context.tr('已暂停', 'Paused'),
                  color: skill.enabled
                      ? context.magpie.jade
                      : context.magpie.muted,
                ),
              ),
              const SizedBox(height: 18),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  skill.localizedDescription(context.l10n),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  for (final permission in context.l10n.permissions(
                    skill.permissions,
                  )) ...[
                    TagChip(
                      label: permission,
                      icon: Icons.key_outlined,
                      color: context.magpie.inkSoft,
                      background: context.magpie.canvas,
                      borderColor: context.magpie.line,
                    ),
                    const SizedBox(width: 6),
                  ],
                  TagChip(
                    label: context.tr(
                      '${skill.toolCount} 个工具',
                      '${skill.toolCount} tools',
                    ),
                    icon: Icons.build_outlined,
                    color: context.magpie.muted,
                    background: context.magpie.paper,
                    borderColor: context.magpie.line,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.tr('演示内容', 'Demo content'),
                  style: Theme.of(context).textTheme.labelMedium,
                ),
              ),
              const SizedBox(height: 7),
              Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxHeight: 180),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: context.magpie.canvas,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: context.magpie.line),
                ),
                child: SingleChildScrollView(
                  child: Text(
                    skill.localizedInstructions(context.l10n).isEmpty
                        ? context.tr('暂无演示内容', 'No demo content yet')
                        : skill.localizedInstructions(context.l10n),
                    style: TextStyle(
                      color: context.magpie.inkSoft,
                      fontSize: 11,
                      height: 1.55,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              InfoBanner(
                icon: Icons.folder_off_outlined,
                title: context.tr(
                  '只管理 Magpie 内的演示内容',
                  'Manage demo content in Magpie only',
                ),
                body: context.tr(
                  '内容仅保存在当前演示会话，不会读取或执行 Skill，'
                      '也不会读写其他 App 的私有目录。',
                  'Content is kept in the current demo session only. Skills are not '
                      'read or executed, and other apps’ private directories are not accessed.',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      child: Text(context.tr('关闭', 'Close')),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      key: const ValueKey('edit-skill-button'),
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (context.mounted) {
                            showSkillEditorSheet(context, store, skill: skill);
                          }
                        });
                      },
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(context.tr('编辑演示内容', 'Edit demo content')),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> showConnectionTestSheet(
  BuildContext context,
  ProviderConfig provider,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    sheetAnimationStyle: MagpieMotion.overlays(context),
    builder: (sheetContext) {
      final latency = provider.latencyMs ?? 0;
      return SheetSurface(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SheetHandle(),
              SheetTitle(
                title: context.tr('连接测试', 'Connection test'),
                subtitle: provider.name,
                icon: Icons.speed_rounded,
                trailing: DemoBadge(label: context.tr('演示', 'Demo')),
              ),
              const SizedBox(height: 18),
              _TestStep(
                label: context.tr('配置结构校验', 'Configuration validation'),
                detail: context.tr(
                  '端点、模型与密钥引用格式',
                  'Endpoint, model, and key reference format',
                ),
                done: true,
              ),
              _TestStep(
                label: context.tr('端点解析', 'Endpoint resolution'),
                detail: provider.endpoint,
                done: true,
              ),
              _TestStep(
                label: context.tr('模拟往返', 'Simulated round trip'),
                detail: latency > 0
                    ? context.tr(
                        '$latency ms（静态示例值）',
                        '$latency ms (static demo value)',
                      )
                    : context.tr('跳过 · 尚未配置', 'Skipped · not configured'),
                done: latency > 0,
              ),
              _TestStep(
                label: context.tr('模型列表', 'Model list'),
                detail: context.tr(
                  '${provider.models.length} 个演示模型',
                  '${provider.models.length} demo models',
                ),
                done: provider.models.isNotEmpty,
                last: true,
              ),
              const SizedBox(height: 12),
              InfoBanner(
                icon: Icons.wifi_off_rounded,
                title: context.tr('没有发起网络请求', 'No network request was made'),
                body: context.tr(
                  '上述结果全部来自本地演示数据，不会访问 provider.endpoint。',
                  'All results above come from local demo data. provider.endpoint is not contacted.',
                ),
                tint: context.magpie.amberSoft,
                accent: context.magpie.amber,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(sheetContext).pop(),
                  child: Text(context.tr('完成', 'Done')),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _TestStep extends StatelessWidget {
  const _TestStep({
    required this.label,
    required this.detail,
    required this.done,
    this.last = false,
  });

  final String label;
  final String detail;
  final bool done;
  final bool last;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: done ? context.magpie.mint : context.magpie.canvas,
                shape: BoxShape.circle,
                border: Border.all(
                  color: done ? context.magpie.jade : context.magpie.lineStrong,
                ),
              ),
              child: Icon(
                done ? Icons.check_rounded : Icons.remove_rounded,
                size: 13,
                color: done ? context.magpie.jade : context.magpie.faint,
              ),
            ),
            if (!last)
              Container(width: 1, height: 28, color: context.magpie.line),
          ],
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: context.magpie.ink,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Padding(
                  padding: EdgeInsets.only(bottom: last ? 0 : 13),
                  child: Text(
                    detail,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10.5,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

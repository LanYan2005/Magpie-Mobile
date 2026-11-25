import 'package:flutter/material.dart';

import '../core/domain_style.dart';
import '../core/magpie_l10n.dart';
import '../core/magpie_theme.dart';
import '../models/magpie_models.dart';
import '../state/magpie_store.dart';
import '../widgets/app_canvas.dart';
import '../widgets/primitives.dart';

class ProviderEditorPage extends StatefulWidget {
  const ProviderEditorPage({this.provider, super.key});

  final ProviderConfig? provider;

  @override
  State<ProviderEditorPage> createState() => _ProviderEditorPageState();
}

class _ProviderEditorPageState extends State<ProviderEditorPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _endpointController;
  late final TextEditingController _keyReferenceController;
  late final TextEditingController _modelsController;
  late final TextEditingController _noteController;
  late ProviderKind _kind;
  late bool _defaultRoute;

  bool get _isEditing => widget.provider != null;

  @override
  void initState() {
    super.initState();
    final provider = widget.provider;
    _nameController = TextEditingController(text: provider?.name ?? '');
    _endpointController = TextEditingController(text: provider?.endpoint ?? '');
    _keyReferenceController = TextEditingController(
      text: provider?.keyReference ?? '',
    );
    _modelsController = TextEditingController(
      text: provider?.models.join(', ') ?? '',
    );
    _noteController = TextEditingController(text: provider?.note ?? '');
    _kind = provider?.kind ?? ProviderKind.openAiCompatible;
    _defaultRoute = provider?.isDefaultRoute ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _endpointController.dispose();
    _keyReferenceController.dispose();
    _modelsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _save() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final store = MagpieScope.of(context);
    final models = _modelsController.text
        .split(RegExp(r'[,，]'))
        .map((model) => model.trim())
        .where((model) => model.isNotEmpty)
        .toList();
    final provider = ProviderConfig(
      id: widget.provider?.id ?? store.newId('provider'),
      name: _nameController.text.trim(),
      kind: _kind,
      endpoint: _endpointController.text.trim(),
      health: widget.provider?.health ?? ProviderHealth.needsSetup,
      models: models.isEmpty ? const ['team-default'] : models,
      keyReference: _keyReferenceController.text.trim().isEmpty
          ? '未设置'
          : _keyReferenceController.text.trim(),
      note: _noteController.text.trim().isEmpty
          ? '演示配置，尚未接入真实服务。'
          : _noteController.text.trim(),
      latencyMs: widget.provider?.latencyMs,
      isDefaultRoute: _defaultRoute,
    );
    store.upsertProvider(provider);
    showDemoToast(
      context,
      _isEditing
          ? context.tr('已更新演示供应商', 'Demo provider updated')
          : context.tr('已添加演示供应商（未连接）', 'Demo provider added (not connected)'),
    );
    Navigator.of(context).pop(provider);
  }

  @override
  Widget build(BuildContext context) {
    return AppCanvas(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
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
                            PageTopBar(
                              title: _isEditing
                                  ? context.tr('编辑供应商', 'Edit provider')
                                  : context.tr('添加供应商', 'Add provider'),
                              onBack: () => Navigator.of(context).pop(),
                            ),
                            const SizedBox(height: 18),
                            DemoBadge(
                              label: context.tr(
                                '本地演示配置',
                                'Local demo configuration',
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              _isEditing
                                  ? context.tr(
                                      '调整演示配置',
                                      'Edit demo configuration',
                                    )
                                  : context.tr('新增一条模型路由', 'Add a model route'),
                              style: Theme.of(
                                context,
                              ).textTheme.displayMedium?.copyWith(fontSize: 30),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              context.tr(
                                '以下内容仅保存在当前应用会话，不会上传、不会读取环境变量，也不会连接填写的地址。',
                                'The following details stay in this app session. Nothing is uploaded, environment variables are not read, and the entered address is not contacted.',
                              ),
                              style: Theme.of(
                                context,
                              ).textTheme.bodyMedium?.copyWith(fontSize: 13),
                            ),
                            const SizedBox(height: 22),
                            _FieldLabel(context.tr('供应商类型', 'Provider type')),
                            const SizedBox(height: 8),
                            LayoutBuilder(
                              builder: (context, constraints) {
                                final width = (constraints.maxWidth - 8) / 2;
                                return Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    for (final kind in ProviderKind.values)
                                      SizedBox(
                                        width: width,
                                        child: _KindOption(
                                          kind: kind,
                                          selected: _kind == kind,
                                          onTap: () {
                                            setState(() => _kind = kind);
                                          },
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            _FieldLabel(context.tr('显示名称', 'Display name')),
                            const SizedBox(height: 7),
                            TextFormField(
                              controller: _nameController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: context.tr(
                                  '例如 团队中转站',
                                  'e.g. Team gateway',
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return context.tr(
                                    '请输入供应商名称',
                                    'Enter a provider name',
                                  );
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            _FieldLabel(context.tr('接入地址', 'Endpoint')),
                            const SizedBox(height: 7),
                            TextFormField(
                              controller: _endpointController,
                              keyboardType: TextInputType.url,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: 'https://gateway.example.com/v1',
                                helperText: context.tr(
                                  '可以是 https 地址或 localhost 占位地址。',
                                  'Use an HTTPS URL or a localhost placeholder.',
                                ),
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return context.tr(
                                    '请输入接入地址',
                                    'Enter an endpoint',
                                  );
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 15),
                            _FieldLabel(context.tr('密钥引用', 'Key reference')),
                            const SizedBox(height: 7),
                            TextFormField(
                              controller: _keyReferenceController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: 'env:OPENAI_API_KEY',
                                helperText: context.tr(
                                  '只保存引用名。请勿在这里输入真实密钥。',
                                  'Stores a reference only. Do not enter a real API key here.',
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            _FieldLabel(context.tr('模型列表', 'Models')),
                            const SizedBox(height: 7),
                            TextFormField(
                              controller: _modelsController,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                hintText: 'gpt-5.1, gpt-5-mini',
                                helperText: context.tr(
                                  '使用英文逗号或中文逗号分隔；留空将使用示例模型。',
                                  'Separate with commas; leave blank to use a demo model.',
                                ),
                              ),
                            ),
                            const SizedBox(height: 15),
                            _FieldLabel(context.tr('备注', 'Notes')),
                            const SizedBox(height: 7),
                            TextFormField(
                              controller: _noteController,
                              maxLines: 3,
                              decoration: InputDecoration(
                                hintText: context.tr(
                                  '这条路由的用途或限制',
                                  'Purpose or limitations of this route',
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                            SurfaceCard(
                              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          context.tr(
                                            '设为默认路由',
                                            'Set as default route',
                                          ),
                                          style: TextStyle(
                                            color: context.magpie.ink,
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          context.tr(
                                            '仅更新演示状态',
                                            'Updates demo state only',
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
                                    value: _defaultRoute,
                                    onChanged: (value) {
                                      setState(() => _defaultRoute = value);
                                    },
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            InfoBanner(
                              icon: Icons.shield_outlined,
                              title: context.tr(
                                '不会保存敏感凭据',
                                'Sensitive credentials are not stored',
                              ),
                              body: context.tr(
                                '本原型没有安全存储、网络层或真实鉴权实现。生产版本应使用系统 Keychain / Keystore 与最小权限策略。',
                                'This prototype has no secure storage, network layer, or real authentication. Production versions should use the system Keychain / Keystore and least-privilege policies.',
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
                        key: const ValueKey('save-provider-button'),
                        onPressed: _save,
                        icon: const Icon(Icons.check_rounded, size: 18),
                        label: Text(
                          _isEditing
                              ? context.tr('保存更改', 'Save changes')
                              : context.tr('添加供应商', 'Add provider'),
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

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

class _KindOption extends StatelessWidget {
  const _KindOption({
    required this.kind,
    required this.selected,
    required this.onTap,
  });

  final ProviderKind kind;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = providerAccent(context, kind);

    return Material(
      color: selected ? context.magpie.mintSoft : context.magpie.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
          child: Row(
            children: [
              Icon(providerIcon(kind), size: 18, color: accent),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.providerKindShort(kind),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.magpie.ink,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.providerKind(kind),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: context.magpie.faint,
                        fontSize: 8.5,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: context.magpie.jade,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

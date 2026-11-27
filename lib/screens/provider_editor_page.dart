import 'package:flutter/material.dart';

import '../core/magpie_l10n.dart';
import '../core/magpie_theme.dart';
import '../gateway/gateway_controller.dart';
import '../gateway/gateway_scope.dart';
import '../widgets/app_canvas.dart';
import '../widgets/primitives.dart';

class ProviderEditorPage extends StatefulWidget {
  const ProviderEditorPage({required this.provider, super.key});

  final UpstreamProvider provider;

  @override
  State<ProviderEditorPage> createState() => _ProviderEditorPageState();
}

class _ProviderEditorPageState extends State<ProviderEditorPage> {
  late final _name = TextEditingController(text: widget.provider.name);
  GatewayIssue? _issue;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save(GatewayController gateway) async {
    FocusScope.of(context).unfocus();
    final provider = widget.provider;
    final saved = await gateway.renameProvider(provider.id, _name.text);
    if (!mounted) return;
    if (!saved) {
      setState(() => _issue = gateway.issue ?? GatewayIssue.saveFailed);
      return;
    }
    Navigator.of(context).pop(provider.id);
  }

  @override
  Widget build(BuildContext context) {
    final gateway = GatewayScope.of(context);
    return AppCanvas(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            padding: pagePadding,
            children: [
              PageTopBar(
                title: context.tr('编辑供应商名称', 'Edit provider name'),
                onBack: () => Navigator.of(context).pop(),
              ),
              const SizedBox(height: 18),
              MagpieList(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: TextField(
                      key: const ValueKey('provider-name'),
                      controller: _name,
                      enabled: gateway.canConfigure,
                      maxLength: 100,
                      textInputAction: TextInputAction.done,
                      onSubmitted: gateway.canConfigure
                          ? (_) => _save(gateway)
                          : null,
                      decoration: InputDecoration(
                        labelText: context.tr('供应商名称', 'Provider name'),
                        hintText: context.tr('例如：团队 API', 'e.g. Team API'),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                context.tr(
                  '可为现有供应商添加多个账号；首个账号在创建时配置。',
                  'Add more accounts to an existing provider; configure the first account when creating it.',
                ),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (_issue case final issue?) ...[
                const SizedBox(height: 12),
                Text(
                  context.l10n.gatewayIssue(issue),
                  style: TextStyle(color: context.magpie.amber),
                ),
              ],
              const SizedBox(height: 20),
              FilledButton(
                key: const ValueKey('save-provider-button'),
                onPressed: gateway.canConfigure ? () => _save(gateway) : null,
                child: Text(context.tr('保存名称', 'Save name')),
              ),
              if (!gateway.canConfigure) ...[
                const SizedBox(height: 8),
                Text(
                  context.tr('请停止本机网关后再编辑。', 'Stop the local gateway to edit.'),
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

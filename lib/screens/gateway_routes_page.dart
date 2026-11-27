import 'package:flutter/material.dart';

import '../core/magpie_l10n.dart';
import '../core/magpie_theme.dart';
import '../gateway/gateway_controller.dart';
import '../gateway/gateway_presets.dart';
import '../gateway/gateway_scope.dart';
import '../gateway/gateway_upstream.dart';
import '../gateway/provider_model_client.dart';
import '../widgets/app_canvas.dart';
import '../widgets/magpie_icon.dart';
import '../widgets/primitives.dart';

class ProviderAccountEditor extends StatefulWidget {
  const ProviderAccountEditor({
    required String this.providerId,
    this.account,
    super.key,
  }) : preset = null;

  const ProviderAccountEditor.createProvider({this.preset, super.key})
    : providerId = null,
      account = null;

  final String? providerId;
  final ProviderAccount? account;
  final ProviderPreset? preset;

  @override
  State<ProviderAccountEditor> createState() => _ProviderAccountEditorState();
}

enum _Action { save, fetch, test }

class _ProviderAccountEditorState extends State<ProviderAccountEditor> {
  late final _name = TextEditingController(
    text: widget.account?.name ?? widget.preset?.name,
  );
  late final _baseUrl = TextEditingController(text: _savedBaseUrl);
  late final _models = TextEditingController(
    text: widget.account?.models.join('\n'),
  );
  final _key = TextEditingController();
  late var _protocol =
      widget.account?.protocol ??
      widget.preset?.protocol ??
      GatewayProtocol.chat;
  late var _requiresKey =
      widget.account?.requiresKey ?? !(widget.preset?.isLocal ?? false);
  List<String> _listedModels = const [];
  bool? _selected;
  var _clearKey = false;
  _Action? _busy;
  String? _testModel;
  String? _message;
  var _isError = false;

  ProviderAccount? get _account => widget.account;
  bool get _creating => widget.providerId == null;
  bool get _preset => widget.preset != null && !widget.preset!.isLocal;
  bool get _supportsProbe => _protocol != GatewayProtocol.systemOne;
  String? get _savedBaseUrl =>
      _account?.protocol.baseUrlFromEndpoint(_account!.endpoint).toString();

  Uri? get _endpoint {
    if (_preset) {
      final preset = widget.preset!;
      return preset.protocol.endpointFromBaseUrl(preset.baseUrl!);
    }
    if (_account?.protocol == _protocol &&
        _baseUrl.text.trim() == _savedBaseUrl) {
      return _account!.endpoint;
    }
    return _protocol.endpointFromBaseUrl(_baseUrl.text);
  }

  List<String> get _modelIds => _models.text
      .split('\n')
      .map((model) => model.trim())
      .where((model) => model.isNotEmpty)
      .toSet()
      .toList();
  String? get _chosenModel =>
      _modelIds.contains(_testModel) ? _testModel : _modelIds.firstOrNull;

  @override
  void dispose() {
    _name.dispose();
    _baseUrl.dispose();
    _models.dispose();
    _key.dispose();
    super.dispose();
  }

  bool _useForGateway(GatewayController gateway) {
    final selected = gateway.selectedAccountId(_protocol);
    return _selected ??
        (selected == null ? _account == null : selected == _account?.id);
  }

  bool _hasDraftKey(GatewayController gateway, Uri? endpoint) =>
      !_requiresKey ||
      _key.text.trim().isNotEmpty ||
      (!_clearKey &&
          endpoint != null &&
          _account?.endpoint == endpoint &&
          _account?.protocol == _protocol &&
          gateway.hasAccountKey(_account!));

  void _update([VoidCallback? change, bool resetList = false]) => setState(() {
    change?.call();
    if (resetList) _listedModels = const [];
    _message = null;
  });

  void _pickModels() async {
    final listed = _listedModels;
    final selected = _modelIds.toSet();
    var query = '';
    final picked = await showDialog<Set<String>>(
      context: context,
      builder: (dialog) => StatefulBuilder(
        builder: (context, setDialogState) {
          final matches = listed
              .where((id) => id.toLowerCase().contains(query))
              .toList();
          return AlertDialog(
            title: Text(context.tr('选择模型', 'Choose models')),
            content: SizedBox(
              width: 420,
              height: 300,
              child: Column(
                children: [
                  TextField(
                    onChanged: (text) =>
                        setDialogState(() => query = text.trim().toLowerCase()),
                    decoration: InputDecoration(
                      labelText: context.tr('搜索模型', 'Search models'),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: matches.length,
                      itemBuilder: (context, index) {
                        final id = matches[index];
                        return CheckboxListTile(
                          key: ValueKey(('provider-model', id)),
                          contentPadding: EdgeInsets.zero,
                          title: Text(id),
                          value: selected.contains(id),
                          onChanged: (on) => setDialogState(() {
                            if (on == true) {
                              selected.add(id);
                            } else {
                              selected.remove(id);
                            }
                          }),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialog),
                child: Text(context.tr('取消', 'Cancel')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialog, selected),
                child: Text(context.tr('应用', 'Apply')),
              ),
            ],
          );
        },
      ),
    );
    if (mounted && picked != null) {
      _update(() => _models.text = picked.join('\n'));
    }
  }

  Future<void> _run(GatewayController gateway, _Action action) async {
    if (_busy != null || !gateway.canConfigure) return;
    final endpoint = _endpoint;
    if (endpoint == null) {
      _show(
        context.tr(
          '请填写 API 根地址，例如 https://api.example.com/v1。仅支持 HTTPS 或其他端口的 HTTP 127.0.0.1。',
          'Enter an API base URL such as https://api.example.com/v1. Use HTTPS or HTTP 127.0.0.1 on another port.',
        ),
        error: true,
      );
      return;
    }
    if ((_creating || action != _Action.save) &&
        !_hasDraftKey(gateway, endpoint)) {
      _show(context.tr('请填写 API 密钥。', 'Enter an API key.'), error: true);
      return;
    }
    if (action != _Action.save && !_supportsProbe) return;
    final model = _chosenModel;
    if (action == _Action.test && model == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = action;
      _message = null;
    });
    try {
      switch (action) {
        case _Action.save:
          final saved = _creating
              ? await gateway.createProvider(
                      providerName: _name.text,
                      accountName: _protocol.label,
                      protocol: _protocol,
                      endpoint: endpoint.toString(),
                      requiresKey: _requiresKey,
                      apiKey: _key.text,
                      models: _modelIds,
                      selected: _useForGateway(gateway),
                    ) !=
                    null
              : await gateway.saveAccount(
                  providerId: widget.providerId!,
                  accountId: _account?.id,
                  name: _name.text,
                  protocol: _protocol,
                  endpoint: endpoint.toString(),
                  requiresKey: _requiresKey,
                  apiKey: _key.text,
                  models: _modelIds,
                  selected: _useForGateway(gateway),
                  clearKey: _clearKey,
                );
          if (!mounted) return;
          if (saved) {
            _key.clear();
            Navigator.of(context).pop(true);
          } else {
            _show(
              context.l10n.gatewayIssue(
                gateway.issue ?? GatewayIssue.saveFailed,
              ),
              error: true,
            );
          }
        case _Action.fetch:
          final models = await gateway.fetchProviderModels(
            protocol: _protocol,
            endpoint: endpoint,
            apiKey: _key.text,
            requiresKey: _requiresKey,
            account: _clearKey ? null : _account,
          );
          if (!mounted) return;
          _listedModels = models;
          if (_creating && models.isNotEmpty) {
            _models.text = models.join('\n');
          }
          _show(
            models.isEmpty
                ? context.tr(
                    '供应商未返回可用的模型 ID。',
                    'The provider returned no usable model IDs.',
                  )
                : context.tr(
                    '已获取 ${models.length} 个模型。保存后才会加入目录。',
                    'Fetched ${models.length} models. Save to add them to the catalog.',
                  ),
          );
        case _Action.test:
          await gateway.testProviderModel(
            protocol: _protocol,
            endpoint: endpoint,
            apiKey: _key.text,
            requiresKey: _requiresKey,
            model: model!,
            account: _clearKey ? null : _account,
          );
          if (mounted) {
            _show(
              context.tr(
                '模型已成功响应测试请求。',
                'The model responded to the test request.',
              ),
            );
          }
      }
    } on GatewayIssue catch (issue) {
      if (mounted) _show(context.l10n.gatewayIssue(issue), error: true);
    } on ProviderProbeException catch (error) {
      if (mounted) _show(_probeError(error), error: true);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  void _show(String message, {bool error = false}) => setState(() {
    _message = message;
    _isError = error;
  });

  String _probeError(ProviderProbeException error) => switch (error.failure) {
    ProviderProbeFailure.unsupported => context.tr(
      '此 API 类型的模型操作尚未接入。',
      'Model actions are not available for this API type.',
    ),
    ProviderProbeFailure.invalidModel => context.tr(
      '模型 ID 格式无效。',
      'The model ID is invalid.',
    ),
    ProviderProbeFailure.network => context.tr(
      '连接供应商失败，请检查 Base URL 和网络。',
      'Connection failed. Check the Base URL and network.',
    ),
    ProviderProbeFailure.timeout => context.tr(
      '供应商响应超时。',
      'The provider did not respond in time.',
    ),
    ProviderProbeFailure.http => context.tr(
      '供应商请求失败（HTTP ${error.statusCode}）。',
      'Provider request failed (HTTP ${error.statusCode}).',
    ),
    ProviderProbeFailure.invalidResponse => context.tr(
      '供应商未返回符合所选 API 类型的响应。',
      'The provider response did not match the selected API type.',
    ),
  };

  String _apiType(GatewayProtocol protocol) => switch (protocol) {
    GatewayProtocol.chat => 'OpenAI compatible',
    GatewayProtocol.responses => 'OpenAI Responses',
    GatewayProtocol.anthropic => 'Anthropic compatible',
    GatewayProtocol.gemini => 'Gemini compatible',
    GatewayProtocol.systemOne => 'System One',
  };

  @override
  Widget build(BuildContext context) {
    final gateway = GatewayScope.of(context);
    final canEdit = gateway.canConfigure && _busy == null;
    final canProbe = canEdit && _supportsProbe;
    final models = _modelIds;
    final chosenModel = _chosenModel;
    final endpoint = _endpoint;
    return AppCanvas(
      child: PopScope(
        canPop: _busy != _Action.save,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: ListView(
              key: const ValueKey('provider-account-editor-scroll'),
              padding: pagePadding,
              children: [
                PageTopBar(
                  backIcon: MagpieGlyph.back,
                  title:
                      widget.preset?.name ??
                      (_creating
                          ? context.tr('自定义供应商', 'Custom provider')
                          : _account == null
                          ? context.tr('添加账号', 'Add account')
                          : context.tr('协议配置', 'Protocol settings')),
                  onBack: () {
                    if (_busy != _Action.save) Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 16),
                MagpieList(
                  clip: false,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!_preset)
                            TextField(
                              key: ValueKey(
                                _creating
                                    ? 'provider-name'
                                    : 'provider-account-name',
                              ),
                              controller: _name,
                              enabled: canEdit,
                              maxLength: 100,
                              textInputAction: TextInputAction.next,
                              decoration: InputDecoration(
                                labelText: context.tr('名称', 'Name'),
                              ),
                            ),
                          if (_preset) ...[
                            const SizedBox(height: 6),
                            Text(
                              context.tr(
                                '此供应商的 API 类型与地址已由目录配置。',
                                'The API type and base URL are set by this provider preset.',
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          if (!_preset) ...[
                            const SizedBox(height: 8),
                            Text(
                              context.tr('API 类型', 'API type'),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              key: const ValueKey('provider-account-protocol'),
                              spacing: 6,
                              runSpacing: 4,
                              children: [
                                for (final protocol in GatewayProtocol.values)
                                  ChoiceChip(
                                    key: ValueKey(
                                      'provider-api-${protocol.name}',
                                    ),
                                    label: Text(_apiType(protocol)),
                                    selected: _protocol == protocol,
                                    onSelected: canEdit
                                        ? (selected) {
                                            if (!selected) return;
                                            _update(() {
                                              _protocol = protocol;
                                              _key.clear();
                                              _selected = null;
                                              _clearKey = false;
                                            }, true);
                                          }
                                        : null,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            TextField(
                              key: ValueKey(
                                _preset
                                    ? 'provider-preset-base-url'
                                    : 'gateway-route-base-url',
                              ),
                              controller: _baseUrl,
                              enabled: canEdit,
                              keyboardType: TextInputType.url,
                              autocorrect: false,
                              enableSuggestions: false,
                              onChanged: (_) =>
                                  _update(() => _clearKey = false),
                              decoration: InputDecoration(
                                labelText: context.tr('Base URL', 'Base URL'),
                                hintText: _protocol == GatewayProtocol.gemini
                                    ? 'https://api.example.com/v1beta'
                                    : 'https://api.example.com/v1',
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              context.tr(
                                '填写 API 根地址，保留版本前缀（如 /v1）。',
                                'Enter the API root, including any version prefix such as /v1.',
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 4),
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: TextButton(
                                key: const ValueKey('provider-detect-apis'),
                                onPressed: null,
                                child: Text(
                                  context.tr('检测 API', 'Detect APIs'),
                                ),
                              ),
                            ),
                            Text(
                              context.tr(
                                '自动检测尚未接入，请手动选择 API 类型。',
                                'API detection is not available yet. Select an API type manually.',
                              ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: 12),
                          ],
                          if (_preset) ...[
                            const SizedBox(height: 12),
                            Text(
                              'API key',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                          if (_requiresKey) ...[
                            TextField(
                              key: const ValueKey('gateway-route-key'),
                              controller: _key,
                              enabled: canEdit,
                              obscureText: true,
                              autocorrect: false,
                              enableSuggestions: false,
                              enableIMEPersonalizedLearning: false,
                              onChanged: (_) => _update(),
                              decoration: InputDecoration(
                                labelText: context.tr('API 密钥', 'API key'),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _account?.credentialId != null &&
                                      _account?.endpoint == endpoint &&
                                      _account?.protocol == _protocol
                                  ? context.tr(
                                      '留空保留系统凭据存储中的密钥。',
                                      'Leave blank to keep the key in system credential storage.',
                                    )
                                  : context.tr(
                                      '密钥保存在系统凭据存储中。',
                                      'The key is saved in system credential storage.',
                                    ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 16),
                          if (!_preset || _listedModels.isNotEmpty)
                            TextField(
                              key: const ValueKey('provider-account-models'),
                              controller: _models,
                              enabled: canEdit,
                              minLines: 2,
                              maxLines: 5,
                              autocorrect: false,
                              enableSuggestions: false,
                              onChanged: (_) => _update(),
                              decoration: InputDecoration(
                                labelText: context.tr(
                                  '模型（每行一个）',
                                  'Models (one per line)',
                                ),
                              ),
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: [
                              OutlinedButton(
                                key: const ValueKey('provider-fetch-models'),
                                onPressed: canProbe
                                    ? () => _run(gateway, _Action.fetch)
                                    : null,
                                child: Text(context.tr('获取模型', 'Fetch models')),
                              ),
                              if (_listedModels.isNotEmpty)
                                TextButton(
                                  key: const ValueKey('provider-pick-models'),
                                  onPressed: canEdit ? _pickModels : null,
                                  child: Text(
                                    context.tr('选择模型', 'Choose models'),
                                  ),
                                ),
                            ],
                          ),
                          if (models.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              key: ValueKey((
                                'provider-test-model-picker',
                                chosenModel,
                              )),
                              initialValue: chosenModel,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: context.tr('测试模型', 'Model to test'),
                              ),
                              items: [
                                for (final model in models)
                                  DropdownMenuItem(
                                    value: model,
                                    child: Text(
                                      model,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                              ],
                              onChanged: canProbe
                                  ? (model) => _update(() => _testModel = model)
                                  : null,
                            ),
                            const SizedBox(height: 4),
                          ],
                          ...[
                            Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: OutlinedButton(
                                key: const ValueKey('provider-test-model'),
                                onPressed: canProbe && chosenModel != null
                                    ? () => _run(gateway, _Action.test)
                                    : null,
                                child: Text(context.tr('测试模型', 'Test model')),
                              ),
                            ),
                            Text(
                              _supportsProbe
                                  ? context.tr(
                                      '获取与测试会连接当前 Base URL。测试只发送一条简短的固定提示。',
                                      'Fetch and test contact this Base URL. The test sends one short, fixed prompt.',
                                    )
                                  : context.tr(
                                      'System One 的获取模型与测试尚未接入。模型可手填。',
                                      'Fetch and test are not available for System One. You can enter model IDs manually.',
                                    ),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                          const SizedBox(height: 8),
                          ExpansionTile(
                            title: Text(context.tr('高级设置', 'Advanced')),
                            tilePadding: EdgeInsets.zero,
                            children: [
                              SwitchListTile(
                                contentPadding: EdgeInsets.zero,
                                value: _requiresKey,
                                title: Text(
                                  context.tr(
                                    '需要 API 密钥',
                                    'Requires an API key',
                                  ),
                                ),
                                onChanged: canEdit
                                    ? (value) => _update(() {
                                        _requiresKey = value;
                                        if (!value) _key.clear();
                                      })
                                    : null,
                              ),
                              if (_requiresKey &&
                                  _account?.credentialId != null &&
                                  _account?.endpoint == endpoint &&
                                  _account?.protocol == _protocol)
                                CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: _clearKey,
                                  title: Text(
                                    context.tr(
                                      '留空时清除已有密钥',
                                      'Clear the saved key when left blank',
                                    ),
                                  ),
                                  onChanged: canEdit
                                      ? (value) => _update(
                                          () => _clearKey = value ?? false,
                                        )
                                      : null,
                                ),
                              SwitchListTile(
                                key: const ValueKey(
                                  'provider-account-selected',
                                ),
                                contentPadding: EdgeInsets.zero,
                                value: _useForGateway(gateway),
                                title: Text(
                                  context.tr(
                                    '用于此协议的网关转发',
                                    'Use for gateway forwarding on this protocol',
                                  ),
                                ),
                                subtitle:
                                    gateway.selectedAccountId(_protocol) !=
                                            null &&
                                        gateway.selectedAccountId(_protocol) !=
                                            _account?.id
                                    ? Text(
                                        context.tr(
                                          '开启后将替换此协议已选账号。',
                                          'Turning this on replaces the selected account for this protocol.',
                                        ),
                                      )
                                    : null,
                                onChanged: canEdit
                                    ? (value) =>
                                          _update(() => _selected = value)
                                    : null,
                              ),
                            ],
                          ),
                          if (_busy != null) const LinearProgressIndicator(),
                          if (_message case final message?) ...[
                            const SizedBox(height: 8),
                            Semantics(
                              liveRegion: true,
                              child: Text(
                                message,
                                style: TextStyle(
                                  color: _isError ? context.magpie.amber : null,
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          FilledButton(
                            key: const ValueKey('gateway-route-save'),
                            onPressed: canEdit
                                ? () => _run(gateway, _Action.save)
                                : null,
                            child: Text(
                              _creating
                                  ? context.tr('保存供应商', 'Save provider')
                                  : context.tr('保存账号', 'Save account'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

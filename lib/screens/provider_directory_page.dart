import 'package:flutter/material.dart';

import '../core/magpie_l10n.dart';
import '../gateway/gateway_presets.dart';
import '../gateway/gateway_scope.dart';
import '../widgets/app_canvas.dart';
import '../widgets/magpie_icon.dart';
import '../widgets/primitives.dart';
import '../widgets/provider_icon.dart';
import 'gateway_routes_page.dart';

class ProviderDirectoryPage extends StatefulWidget {
  const ProviderDirectoryPage({super.key});

  @override
  State<ProviderDirectoryPage> createState() => _ProviderDirectoryPageState();
}

class _ProviderDirectoryPageState extends State<ProviderDirectoryPage> {
  String _query = '';

  Future<void> _openEditor([ProviderPreset? preset]) async {
    final saved = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProviderAccountEditor.createProvider(preset: preset),
      ),
    );
    if (mounted && saved == true) Navigator.of(context).pop();
  }

  String _heading(ProviderPresetGroup group) => switch (group) {
    ProviderPresetGroup.vendor => context.tr('原厂供应商', 'Vendors'),
    ProviderPresetGroup.relay => context.tr('中转服务', 'Relays'),
    ProviderPresetGroup.local => context.tr('本机服务', 'On this machine'),
    ProviderPresetGroup.remote => context.tr(
      '另一台电脑的 Magpie',
      "Another computer's magpie",
    ),
  };

  @override
  Widget build(BuildContext context) {
    final canEdit = GatewayScope.of(context).canConfigure;
    final query = _query.trim().toLowerCase();
    final groups = <ProviderPresetGroup, List<ProviderPreset>>{
      for (final group in ProviderPresetGroup.values) group: [],
    };
    for (final preset in ProviderPreset.directory) {
      if ([
        preset.id,
        preset.name,
        _heading(preset.group),
      ].any((text) => text.toLowerCase().contains(query))) {
        groups[preset.group]!.add(preset);
      }
    }
    return AppCanvas(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListView(
            key: const ValueKey('provider-directory-scroll'),
            padding: pagePadding,
            children: [
              PageTopBar(
                title: context.tr('添加供应商', 'Add provider'),
                onBack: () => Navigator.of(context).pop(),
                backIcon: MagpieGlyph.back,
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('provider-directory-search'),
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  prefixIcon: const MagpieIcon(MagpieGlyph.search),
                  labelText: context.tr('搜索供应商目录', 'Search provider directory'),
                ),
              ),
              const SizedBox(height: 12),
              MagpieList(
                children: [
                  MagpieRow(
                    key: const ValueKey('provider-directory-custom'),
                    title: context.tr('自定义供应商', 'Custom provider'),
                    subtitle: context.tr(
                      '选择 API 类型，填写 Base URL、密钥与模型',
                      'Choose an API type, then enter a Base URL, key and models',
                    ),
                    leading: const MagpieIcon(MagpieGlyph.plus, size: 20),
                    trailing: const MagpieIcon(
                      MagpieGlyph.chevronRight,
                      matchTextDirection: true,
                    ),
                    onTap: canEdit ? () => _openEditor() : null,
                    enabled: canEdit,
                    dense: false,
                  ),
                ],
              ),
              if (groups.values.every((presets) => presets.isEmpty))
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    context.tr('目录中没有匹配项。', 'No directory entries match.'),
                  ),
                ),
              for (final entry in groups.entries)
                if (entry.value.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  SectionHeader(title: _heading(entry.key)),
                  const SizedBox(height: 8),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final columnWidth = MediaQuery.textScalerOf(
                        context,
                      ).scale(164);
                      final columns =
                          ((constraints.maxWidth + 8) / (columnWidth + 8))
                              .floor()
                              .clamp(1, 4);
                      final width =
                          (constraints.maxWidth - (columns - 1) * 8) / columns;
                      return Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final preset in entry.value)
                            SizedBox(
                              width: width,
                              child: MagpieList(
                                children: [
                                  MagpieRow(
                                    key: ValueKey(
                                      'provider-preset-${preset.id}',
                                    ),
                                    title: preset.name,
                                    subtitle: preset.baseUrl == null
                                        ? context.tr(
                                            '远程配对尚未接入',
                                            'Remote pairing is not available yet',
                                          )
                                        : null,
                                    leading: ProviderIcon(
                                      presetId: preset.id,
                                      size: 19,
                                    ),
                                    onTap: canEdit && preset.baseUrl != null
                                        ? () => _openEditor(preset)
                                        : null,
                                    enabled: canEdit && preset.baseUrl != null,
                                    dense: false,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

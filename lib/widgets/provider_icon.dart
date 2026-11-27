import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../gateway/gateway_presets.dart';
import 'magpie_icon.dart';

/// Bundled provider artwork, resolved by directory ID or exact endpoint host.
class ProviderIcon extends StatelessWidget {
  const ProviderIcon({
    this.presetId,
    this.hosts = const [],
    this.size,
    this.color,
    super.key,
  });

  final String? presetId;
  final Iterable<String> hosts;
  final double? size;
  final Color? color;

  static final _byHost = <String, String>{
    for (final preset in ProviderPreset.directory)
      // Loopback hosts don't identify the service running on the port.
      if (preset.baseUrl != null && !preset.isLocal)
        Uri.parse(preset.baseUrl!).host: preset.id,
  };

  // Upstream displays `-color` assets as images and mono assets as masks.
  static const _color = {
    'anthropic',
    'google',
    'deepseek',
    'mistral',
    'qwen',
    'together',
    'fireworks',
    'siliconflow',
  };
  static const _mono = {
    'openai',
    'xai',
    'moonshot',
    'groq',
    'openrouter',
    'vercel',
    'ollama',
    'lmstudio',
    'remote',
  };

  String? _resolve() {
    final id = presetId ?? _resolveHosts();
    return _color.contains(id) || _mono.contains(id) ? id : null;
  }

  String? _resolveHosts() {
    String? id;
    for (final host in hosts) {
      final next = _byHost[host.toLowerCase()];
      // Don't assign a brand to a mixed-vendor or partly unknown provider.
      if (next == null || (id != null && next != id)) return null;
      id = next;
    }
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final logo = _resolve();
    if (logo == null) {
      return MagpieIcon(MagpieGlyph.provider, size: size, color: color);
    }
    final theme = IconTheme.of(context);
    final dimension = size ?? theme.size ?? 24;
    final foreground =
        color ?? theme.color ?? Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(
      'assets/upstream/vendors/$logo.svg',
      width: dimension,
      height: dimension,
      colorFilter: _color.contains(logo)
          ? null
          : ColorFilter.mode(
              foreground.withValues(alpha: foreground.a * (theme.opacity ?? 1)),
              BlendMode.srcIn,
            ),
      excludeFromSemantics: true,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Standalone SVGs copied from Magpie's GUI. See THIRD_PARTY_NOTICES.md.
enum MagpieGlyph {
  agents('nav-agents'),
  sessions('nav-sessions'),
  library('nav-library'),
  artifacts('nav-artifacts'),
  providers('nav-providers'),
  routing('nav-routing'),
  routingGroups('nav-groups'),
  gateway('nav-gateway'),
  usage('nav-usage'),
  masking('nav-masking'),
  plugins('nav-plugins'),
  sidebarOpen('sidebar-open'),
  sidebarClosed('sidebar-closed'),
  settings('settings'),
  magpie('magpie'),
  back('back'),
  search('search'),
  plus('plus'),
  cross('cross'),
  eye('eye'),
  eyeOff('eye-off'),
  pencil('pencil'),
  chevronRight('chevron-right'),
  provider('provider-generic');

  const MagpieGlyph(this.filename);
  final String filename;

  String get asset => 'assets/upstream/ui/$filename.svg';
}

class MagpieIcon extends StatelessWidget {
  const MagpieIcon(
    this.glyph, {
    this.size,
    this.color,
    this.matchTextDirection = false,
    super.key,
  });

  final MagpieGlyph glyph;
  final double? size;
  final Color? color;
  final bool matchTextDirection;

  @override
  Widget build(BuildContext context) {
    final theme = IconTheme.of(context);
    final dimension = size ?? theme.size ?? 24;
    final foreground =
        color ?? theme.color ?? Theme.of(context).colorScheme.onSurface;
    return SvgPicture.asset(
      glyph.asset,
      width: dimension,
      height: dimension,
      // Match Icon: inherit the enclosing control's foreground and opacity.
      theme: SvgTheme(
        currentColor: foreground.withValues(
          alpha: foreground.a * (theme.opacity ?? 1),
        ),
      ),
      matchTextDirection: matchTextDirection,
      excludeFromSemantics: true,
    );
  }
}

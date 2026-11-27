import 'package:flutter/material.dart';

import '../core/magpie_l10n.dart';
import '../core/magpie_motion.dart';
import '../core/magpie_theme.dart';
import '../core/magpie_tokens.dart';
import 'magpie_icon.dart';

// SafeArea owns system insets; this is just the scroll content margin.
const pagePadding = EdgeInsets.fromLTRB(12, 8, 12, 16);

// Kept for pages that still use the former bottom dock spacing.
EdgeInsets dockPagePadding(BuildContext context) => pagePadding.copyWith(
  bottom: pagePadding.bottom + MediaQuery.viewPaddingOf(context).bottom,
);

/// Upstream's `.list`: a compact white/charcoal group with 12px corners.
class MagpieList extends StatelessWidget {
  const MagpieList({required this.children, this.clip = true, super.key});

  final List<Widget> children;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      clipBehavior: clip ? Clip.antiAlias : Clip.none,
      decoration: BoxDecoration(
        color: t.card,
        border: Border.all(color: t.line),
        borderRadius: BorderRadius.circular(MagpieMetrics.listRadius),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

/// Upstream's `.row` with compact / relaxed density and optional action.
class MagpieRow extends StatelessWidget {
  const MagpieRow({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
    this.dense = true,
    this.enabled = true,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool dense;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final row = ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: dense ? MagpieMetrics.rowCompact : MagpieMetrics.rowRelaxed,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: MagpieMetrics.rowPadH,
          vertical: MagpieMetrics.rowPadV,
        ),
        child: Row(
          children: [
            if (leading != null) ...[
              leading!,
              const SizedBox(width: MagpieMetrics.rowGap),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: MagpieType.rowName,
                      fontWeight: FontWeight.w500,
                      color: enabled ? t.fg : t.muted,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: MagpieType.rowSub,
                        color: t.muted,
                        height: 1.25,
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
          ],
        ),
      ),
    );
    return Material(
      color: Colors.transparent,
      child: InkWell(onTap: enabled ? onTap : null, child: row),
    );
  }
}

/// Compact 25px pill used for model, status and selection fields.
class MagpieField extends StatelessWidget {
  const MagpieField({
    required this.label,
    this.icon,
    this.onTap,
    this.selected = false,
    super.key,
  });

  final String label;
  final IconData? icon;
  final VoidCallback? onTap;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Material(
      color: selected ? t.sel : t.pill,
      borderRadius: BorderRadius.circular(MagpieMetrics.fieldRadius),
      child: InkWell(
        borderRadius: BorderRadius.circular(MagpieMetrics.fieldRadius),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: MagpieMetrics.fieldHeight,
            minWidth: MagpieMetrics.touchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: MagpieMetrics.fieldPadH,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 14, color: selected ? t.accent : t.muted),
                  const SizedBox(width: 4),
                ],
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: MagpieType.field,
                      color: selected ? t.accent : t.fg2,
                    ),
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 3),
                  Icon(Icons.expand_more_rounded, size: 14, color: t.muted),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Tiny status badge matching upstream `.badge`.
class MagpieBadge extends StatelessWidget {
  const MagpieBadge({
    required this.label,
    this.tone = MagpieBadgeTone.neutral,
    super.key,
  });

  final String label;
  final MagpieBadgeTone tone;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final (background, foreground) = switch (tone) {
      MagpieBadgeTone.neutral => (t.pill, t.muted),
      MagpieBadgeTone.accent => (t.accentSoft, t.accent),
      MagpieBadgeTone.success => (t.greenSoft, t.green),
      MagpieBadgeTone.warning => (t.amberSoft, t.amber),
      MagpieBadgeTone.error => (t.redSoft, t.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(MagpieMetrics.badgeRadius),
      ),
      child: Text(
        label.toUpperCase(),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: MagpieType.badge,
          fontWeight: FontWeight.w600,
          letterSpacing: .4,
          color: foreground,
        ),
      ),
    );
  }
}

enum MagpieBadgeTone { neutral, accent, success, warning, error }

/// Compact segmented selector; selected option has a raised card thumb.
class MagpieSegmented extends StatelessWidget {
  const MagpieSegmented({
    required this.labels,
    required this.index,
    required this.onChanged,
    super.key,
  });

  final List<String> labels;
  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: t.pill,
        borderRadius: BorderRadius.circular(MagpieMetrics.segmentRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < labels.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: 1),
              child: Material(
                color: i == index ? t.card : Colors.transparent,
                elevation: i == index ? 1 : 0,
                borderRadius: BorderRadius.circular(
                  MagpieMetrics.segmentThumbRadius,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    MagpieMetrics.segmentThumbRadius,
                  ),
                  onTap: () => onChanged(i),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      minHeight: MagpieMetrics.touchTarget,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Center(
                        child: Text(
                          labels[i],
                          style: TextStyle(
                            fontSize: MagpieType.field,
                            color: i == index ? t.fg : t.ctlFg,
                            fontWeight: i == index
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class PageHeader extends StatelessWidget {
  const PageHeader({
    required this.title,
    required this.subtitle,
    this.action,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.displayMedium,
                ),
              ),
            ),
            if (action != null) ...[const SizedBox(width: 12), action!],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontSize: 15, height: 1.6),
        ),
      ],
    );
  }
}

class SurfaceCard extends StatelessWidget {
  const SurfaceCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.borderColor,
    this.radius = 24,
    this.onTap,
    this.clip = true,
    this.shadow = false,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final Color? borderColor;
  final double radius;
  final VoidCallback? onTap;
  final bool clip;
  final bool shadow;

  @override
  Widget build(BuildContext context) {
    final colors = context.magpie;
    final borderRadius = BorderRadius.circular(radius);
    final decoration = BoxDecoration(
      color: color ?? colors.paper,
      borderRadius: borderRadius,
      border: Border.all(color: borderColor ?? colors.line),
      boxShadow: shadow
          ? [
              BoxShadow(
                color: colors.shadow.withValues(
                  alpha: colors.isDark ? 0.18 : 0.035,
                ),
                blurRadius: 24,
                offset: const Offset(0, 7),
              ),
            ]
          : null,
    );

    if (onTap == null) {
      return Container(decoration: decoration, padding: padding, child: child);
    }

    return DecoratedBox(
      decoration: decoration,
      child: PressableSurface(
        borderRadius: borderRadius,
        onTap: onTap!,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class PressableSurface extends StatefulWidget {
  const PressableSurface({
    required this.child,
    required this.onTap,
    this.borderRadius,
    this.excludeFromSemantics = false,
    super.key,
  });

  final Widget child;
  final VoidCallback onTap;
  final BorderRadius? borderRadius;
  final bool excludeFromSemantics;

  @override
  State<PressableSurface> createState() => _PressableSurfaceState();
}

class _PressableSurfaceState extends State<PressableSurface> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.magpie;
    final animated = AnimatedContainer(
      duration: MagpieMotion.duration(context, MagpieMotion.feedback),
      curve: MagpieMotion.curve,
      decoration: BoxDecoration(
        color: _pressed
            ? colors.interactionOverlay(const {WidgetState.pressed})
            : Colors.transparent,
        borderRadius: widget.borderRadius,
      ),
      child: widget.child,
    );
    return Listener(
      onPointerDown: (_) {
        if (!context.reduceMotion) setState(() => _pressed = true);
      },
      onPointerUp: (_) {
        if (_pressed) setState(() => _pressed = false);
      },
      onPointerCancel: (_) {
        if (_pressed) setState(() => _pressed = false);
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        excludeFromSemantics: widget.excludeFromSemantics,
        child: AnimatedScale(
          scale: _pressed && !context.reduceMotion ? 0.985 : 1,
          duration: MagpieMotion.duration(context, MagpieMotion.feedback),
          curve: MagpieMotion.curve,
          child: ClipRRect(
            borderRadius: widget.borderRadius ?? BorderRadius.zero,
            child: animated,
          ),
        ),
      ),
    );
  }
}

/// Shared sliding selection for the floating dock and segmented controls.
class SelectionTrack extends StatelessWidget {
  const SelectionTrack({
    required this.index,
    required this.count,
    this.selectedIndex,
    required this.color,
    required this.radius,
    super.key,
  });

  final int index;
  final int count;
  final int? selectedIndex;
  final Color color;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final alignment = AlignmentDirectional(-1 + index * 2 / (count - 1), 0);
    final indicator = FractionallySizedBox(
      widthFactor: 1 / count,
      heightFactor: 1,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(radius),
          border: context.magpie.highContrast
              ? Border.all(color: context.magpie.lineStrong)
              : null,
        ),
      ),
    );
    return IgnorePointer(
      child: Stack(
        children: [
          if (selectedIndex != null)
            for (var i = 0; i < count; i++)
              Align(
                alignment: AlignmentDirectional(-1 + i * 2 / (count - 1), 0),
                child: FractionallySizedBox(
                  widthFactor: 1 / count,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(radius),
                      border: Border.all(
                        color: context.magpie.lineStrong.withValues(
                          alpha: selectedIndex == i ? 0.8 : 0,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          context.reduceMotion
              ? Align(alignment: alignment, child: indicator)
              : AnimatedAlign(
                  duration: MagpieMotion.duration(
                    context,
                    MagpieMotion.selection,
                  ),
                  alignment: alignment,
                  curve: MagpieMotion.curve,
                  child: indicator,
                ),
        ],
      ),
    );
  }
}

class DemoBadge extends StatelessWidget {
  const DemoBadge({this.label, this.compact = false, super.key});

  final String? label;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 9,
        vertical: compact ? 3.5 : 4.5,
      ),
      decoration: BoxDecoration(
        color: context.magpie.amberSoft,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: context.magpie.amber.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: context.magpie.amber,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label ?? context.tr('演示', 'Demo'),
              style: TextStyle(
                color: context.magpie.amber,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({
    required this.label,
    required this.color,
    this.background,
    this.compact = true,
    super.key,
  });

  final String label;
  final Color color;
  final Color? background;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: background ?? color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 5,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w700,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TagChip extends StatelessWidget {
  const TagChip({
    required this.label,
    this.icon,
    this.color,
    this.background,
    this.borderColor,
    super.key,
  });
  final String label;
  final IconData? icon;
  final Color? color;
  final Color? background;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final foreground = color ?? context.magpie.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background ?? context.magpie.canvas,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor ?? foreground.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: foreground),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class IconTile extends StatelessWidget {
  const IconTile({
    this.icon,
    this.iconWidget,
    this.size = 44,
    this.iconSize = 20,
    this.background,
    this.foreground,
    this.radius = 14,
    this.borderColor,
    super.key,
  }) : assert((icon == null) != (iconWidget == null));
  final IconData? icon;
  final Widget? iconWidget;
  final double size;
  final double iconSize;
  final Color? background;
  final Color? foreground;
  final double radius;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: background ?? context.magpie.canvas,
      borderRadius: BorderRadius.circular(radius),
      border: borderColor == null ? null : Border.all(color: borderColor!),
    ),
    child: iconWidget == null
        ? Icon(icon, size: iconSize, color: foreground ?? context.magpie.ink)
        : Center(
            child: IconTheme.merge(
              data: IconThemeData(
                size: iconSize,
                color: foreground ?? context.magpie.ink,
              ),
              child: iconWidget!,
            ),
          ),
  );
}

class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    this.icon,
    this.glyph,
    required this.onPressed,
    this.tooltip,
    this.filled = false,
    this.size = 44,
    super.key,
  }) : assert((icon == null) != (glyph == null));

  final IconData? icon;
  final MagpieGlyph? glyph;
  final VoidCallback onPressed;
  final String? tooltip;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size / 2);
    final button = Semantics(
      button: true,
      label: tooltip,
      child: Material(
        color: filled ? context.magpie.jade : context.magpie.paper,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: filled
              ? BorderSide.none
              : BorderSide(color: context.magpie.line),
        ),
        clipBehavior: Clip.antiAlias,
        child: PressableSurface(
          borderRadius: radius,
          onTap: onPressed,
          child: SizedBox(
            width: size < 44 ? 44 : size,
            height: size < 44 ? 44 : size,
            child: glyph == null
                ? Icon(
                    icon,
                    size: 20,
                    color: filled ? context.magpie.onJade : context.magpie.ink,
                  )
                : Center(
                    child: MagpieIcon(
                      glyph!,
                      size: 20,
                      color: filled ? context.magpie.onJade : context.magpie.ink,
                      matchTextDirection: true,
                    ),
                  ),
          ),
        ),
      ),
    );
    return tooltip == null
        ? button
        : Tooltip(message: tooltip!, excludeFromSemantics: true, child: button);
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    this.subtitle,
    this.trailing,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontSize: 19),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 3),
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

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    required this.icon,
    required this.title,
    required this.body,
    this.tint,
    this.accent,
    this.onTap,
    this.actionLabel,
    super.key,
  });

  final IconData icon;
  final String title;
  final String body;
  final Color? tint;
  final Color? accent;
  final VoidCallback? onTap;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    final accent = this.accent ?? context.magpie.jade;
    final tint = this.tint ?? context.magpie.mintSoft;
    return Container(
      decoration: BoxDecoration(
        color: tint,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accent.withValues(alpha: 0.14)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(15),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconTile(
                  icon: icon,
                  size: 34,
                  iconSize: 17,
                  radius: 11,
                  background: accent.withValues(alpha: 0.1),
                  foreground: accent,
                  borderColor: accent.withValues(alpha: 0.08),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: accent,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        body,
                        style: TextStyle(
                          color: context.magpie.inkSoft,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                      if (actionLabel != null) ...[
                        const SizedBox(height: 7),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                actionLabel!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 3),
                            Icon(arrowIcon, size: 12, color: accent),
                          ],
                        ),
                      ],
                    ],
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

const arrowIcon = Icons.arrow_forward_rounded;

class PageTopBar extends StatelessWidget {
  const PageTopBar({
    required this.title,
    required this.onBack,
    this.trailing,
    this.backIcon,
    super.key,
  });

  final String title;
  final VoidCallback onBack;
  final MagpieGlyph? backIcon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RoundIconButton(
          icon: backIcon == null ? Icons.arrow_back_rounded : null,
          glyph: backIcon,
          tooltip: context.tr('返回', 'Back'),
          onPressed: onBack,
          size: 42,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        ?trailing,
      ],
    );
  }
}

class MetricBlock extends StatelessWidget {
  const MetricBlock({
    required this.value,
    required this.label,
    this.color,
    this.labelColor,
    this.align = CrossAxisAlignment.start,
    this.valueSize = 19,
    super.key,
  });

  final String value;
  final String label;
  final Color? color;
  final Color? labelColor;
  final CrossAxisAlignment align;
  final double valueSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.magpie;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: align,
      children: [
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: color ?? colors.ink,
            fontSize: valueSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: labelColor ?? colors.muted,
            fontSize: 12,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
      ],
    );
  }
}

class KeyValueRow extends StatelessWidget {
  const KeyValueRow({
    required this.label,
    required this.value,
    this.monospace = false,
    this.valueColor,
    super.key,
  });

  final String label;
  final String value;
  final bool monospace;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 12),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                color: valueColor ?? context.magpie.inkSoft,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.45,
                fontFamily: monospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SoftDivider extends StatelessWidget {
  const SoftDivider({this.height = 1, this.indent = 0, super.key});

  final double height;
  final double indent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: height, horizontal: indent),
      child: const Divider(height: 1, thickness: 1),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    this.icon,
    this.iconWidget,
    required this.title,
    required this.body,
    this.action,
    super.key,
  }) : assert((icon == null) != (iconWidget == null));

  final IconData? icon;
  final Widget? iconWidget;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 24),
      child: Column(
        children: [
          IconTile(
            icon: icon,
            iconWidget: iconWidget,
            size: 54,
            iconSize: 24,
            radius: 18,
            background: context.magpie.canvas,
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 5),
          Text(
            body,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

class ChoicePill extends StatelessWidget {
  const ChoicePill({
    required this.label,
    required this.selected,
    required this.onTap,
    this.count,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(99);
    return Semantics(
      selected: selected,
      button: true,
      label: count == null ? label : '$label $count',
      child: AnimatedContainer(
        duration: MagpieMotion.duration(context, MagpieMotion.selection),
        decoration: ShapeDecoration(
          color: selected ? context.magpie.mint : context.magpie.paper,
          shape: StadiumBorder(
            side: BorderSide(
              color: selected ? context.magpie.jade : context.magpie.line,
            ),
          ),
        ),
        child: PressableSurface(
          onTap: onTap,
          borderRadius: radius,
          excludeFromSemantics: true,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 44),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
              child: Align(
                widthFactor: 1,
                child: Text(
                  count == null ? label : '$label $count',
                  style: TextStyle(
                    color: selected
                        ? context.magpie.jadeDeep
                        : context.magpie.muted,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class SectionSpacer extends StatelessWidget {
  const SectionSpacer({this.height = 24, super.key});

  final double height;

  @override
  Widget build(BuildContext context) => SizedBox(height: height);
}

void showDemoToast(BuildContext context, String message) {
  final messenger = ScaffoldMessenger.of(context);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: context.magpie.jade,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 12,
                color: context.magpie.onJade,
              ),
            ),
            const SizedBox(width: 9),
            Expanded(child: Text(message)),
          ],
        ),
      ),
      snackBarAnimationStyle: MagpieMotion.overlays(context),
    );
}

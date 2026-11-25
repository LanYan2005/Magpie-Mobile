import 'package:flutter/material.dart';

import '../core/magpie_theme.dart';

class AppCanvas extends StatelessWidget {
  const AppCanvas({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(color: context.magpie.canvas, child: child);
  }
}

class BrandLockup extends StatelessWidget {
  const BrandLockup({this.compact = false, super.key});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).textTheme;
    final colors = context.magpie;
    final size = compact ? 30.0 : 38.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Keep the verified upstream silhouette black in both appearances.
        Container(
          width: size,
          height: size,
          padding: const EdgeInsets.all(4),
          decoration: ShapeDecoration(
            color: colors.brandPlate,
            shape: ContinuousRectangleBorder(
              borderRadius: BorderRadius.circular(size * 0.44),
              side: BorderSide(color: colors.line),
            ),
          ),
          child: Image.asset(
            'assets/brand/magpie.png',
            fit: BoxFit.contain,
            excludeFromSemantics: true,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            'Magpie',
            style: compact ? type.titleMedium : type.titleLarge,
          ),
        ),
      ],
    );
  }
}

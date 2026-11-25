import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../core/magpie_l10n.dart';
import '../core/magpie_motion.dart';
import '../core/magpie_theme.dart';
import '../widgets/app_canvas.dart';
import '../widgets/primitives.dart';
import 'agents_page.dart';
import 'overview_page.dart';
import 'providers_page.dart';
import 'resources_page.dart';
import 'settings_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell>
    with SingleTickerProviderStateMixin {
  late final _transition = AnimationController(
    vsync: this,
    duration: MagpieMotion.tab,
    value: 1,
  );
  late final _pages = <Widget>[
    OverviewPage(onNavigate: _select, onOpenSettings: _openSettings),
    const ProvidersPage(),
    const AgentsPage(),
    const ResourcesPage(),
  ];
  final _visited = <int>{0};
  int _index = 0;

  void _select(int index) {
    if (index == _index) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _index = index;
      _visited.add(index);
    });
    if (context.reduceMotion) {
      _transition.value = 1;
    } else {
      _transition.forward(from: 0);
    }
  }

  void _openSettings() => Navigator.of(
    context,
  ).push(MagpiePageRoute<void>(context, builder: (_) => const SettingsPage()));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) _transition.value = 1;
  }

  @override
  void dispose() {
    _transition.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppCanvas(
      child: Scaffold(
        key: const ValueKey('magpie-app-shell'),
        backgroundColor: Colors.transparent,
        // Preserve a clear content/navigation hierarchy with a floating dock.
        extendBody: true,
        body: AnimatedBuilder(
          animation: _transition,
          child: IndexedStack(
            index: _index,
            sizing: StackFit.expand,
            children: [
              for (var i = 0; i < _pages.length; i++)
                TickerMode(
                  enabled: _index == i,
                  child: ExcludeFocus(
                    excluding: _index != i,
                    child: _visited.contains(i)
                        ? _pages[i]
                        : const SizedBox.shrink(),
                  ),
                ),
            ],
          ),
          builder: (context, child) {
            final progress = MagpieMotion.curveFor(
              context,
            ).transform(_transition.value);
            if (progress == 1 || context.reduceMotion) {
              return _TabPosition(opacity: 1, offset: 0, child: child!);
            }
            return _TabPosition(
              opacity: 0.70 + 0.30 * progress,
              offset: 6 * (1 - progress),
              child: child!,
            );
          },
        ),
        bottomNavigationBar: _BottomDock(index: _index, onSelected: _select),
      ),
    );
  }
}

class _TabPosition extends StatelessWidget {
  const _TabPosition({
    required this.opacity,
    required this.offset,
    required this.child,
  });
  final double opacity;
  final double offset;
  final Widget child;

  @override
  Widget build(BuildContext context) => Transform.translate(
    key: const ValueKey('tab-transition'),
    offset: Offset(0, offset),
    child: Opacity(
      opacity: opacity,
      alwaysIncludeSemantics: true,
      child: child,
    ),
  );
}

class _BottomDock extends StatelessWidget {
  const _BottomDock({required this.index, required this.onSelected});

  final int index;
  final ValueChanged<int> onSelected;

  static const _destinations = [
    ('nav-overview', Icons.dashboard_outlined, Icons.dashboard_rounded),
    ('nav-providers', Icons.layers_outlined, Icons.layers_rounded),
    ('nav-agents', Icons.people_outline_rounded, Icons.people_rounded),
    ('nav-resources', Icons.inventory_2_outlined, Icons.inventory_2_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.magpie;
    final solid =
        colors.highContrast ||
        MediaQuery.maybeOf(context)?.accessibleNavigation == true;
    final shape = BorderRadius.circular(MagpieShape.dock);
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: shape,
              boxShadow: [
                BoxShadow(
                  color: colors.shadow.withValues(
                    alpha: colors.isDark ? 0.32 : 0.10,
                  ),
                  blurRadius: 20,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: shape,
              child: Stack(
                children: [
                  if (!solid)
                    Positioned.fill(
                      child: ExcludeSemantics(
                        child: BackdropFilter(
                          filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: colors.paper.withValues(
                        alpha: solid || context.reduceMotion ? 1 : 0.82,
                      ),
                      borderRadius: shape,
                      border: Border.all(
                        color: solid ? colors.lineStrong : colors.line,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: SelectionTrack(
                              key: const ValueKey('dock-selection'),
                              index: index,
                              count: _destinations.length,
                              selectedIndex: index,
                              color: colors.mint,
                              radius: 24,
                            ),
                          ),
                          Row(
                            children: [
                              for (var i = 0; i < _destinations.length; i++)
                                Expanded(
                                  child: _DockItem(
                                    destination: _destinations[i],
                                    label: _destinationLabel(context, i),
                                    selected: index == i,
                                    onTap: () => onSelected(i),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _destinationLabel(BuildContext context, int index) =>
      switch (index) {
        0 => context.tr('概览', 'Overview'),
        1 => context.tr('供应商', 'Providers'),
        2 => 'Agents',
        3 => 'Skills / MCP',
        _ => '',
      };
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.destination,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final (String, IconData, IconData) destination;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (key, icon, selectedIcon) = destination;
    final colors = context.magpie;
    final color = selected ? colors.jadeDeep : colors.muted;
    return Semantics(
      button: true,
      label: label,
      selected: selected,
      onTap: onTap,
      child: Material(
        key: ValueKey(key),
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(24),
        child: InkWell(
          onTap: onTap,
          excludeFromSemantics: true,
          borderRadius: BorderRadius.circular(24),
          splashFactory: NoSplash.splashFactory,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 62, minWidth: 62),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 5),
              child: ExcludeSemantics(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedSwitcher(
                      duration: MagpieMotion.duration(
                        context,
                        MagpieMotion.selection,
                      ),
                      child: Icon(
                        selected ? selectedIcon : icon,
                        key: ValueKey(selected),
                        color: color,
                        size: 21,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 10.5,
                        height: 1.2,
                        fontWeight: selected
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/magpie_l10n.dart';
import '../core/magpie_motion.dart';
import '../core/magpie_theme.dart';
import '../core/magpie_tokens.dart';
import '../widgets/app_canvas.dart';
import '../widgets/magpie_icon.dart';
import '../widgets/primitives.dart';
import 'agents_page.dart';
import 'gateway_page.dart';
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
  static const _wideBreakpoint = 700.0;
  static const _sidebarWidth = 224.0;
  static const _drawerMaxWidth = 272.0;

  late final _transition = AnimationController(
    vsync: this,
    duration: MagpieMotion.tab,
    value: 1,
  );
  final _toggleFocus = FocusNode(debugLabel: 'sidebar toggle');
  final _sidebarNavigation = GlobalKey<_SectionNavState>();
  final _bottomNavigation = GlobalKey<_SectionNavState>();
  static const _bottomSections = <MagpieSection>[
    MagpieSection.agents,
    MagpieSection.resources,
    MagpieSection.providers,
    MagpieSection.gateway,
    MagpieSection.plugins,
  ];
  final _visited = {MagpieSection.agents};
  var _section = MagpieSection.agents;
  bool _wideSidebarOpen = true;
  bool _drawerOpen = false;
  bool? _wasWide;

  void _restoreToggleFocus() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _toggleFocus.requestFocus();
    });
  }

  void _closeSidebar(bool wide) {
    setState(() {
      if (wide) {
        _wideSidebarOpen = false;
      } else {
        _drawerOpen = false;
      }
    });
    _restoreToggleFocus();
  }

  void _toggleSidebar(bool wide) {
    if (wide ? _wideSidebarOpen : _drawerOpen) {
      _closeSidebar(wide);
    } else {
      setState(() {
        if (wide) {
          _wideSidebarOpen = true;
        } else {
          _drawerOpen = true;
        }
      });
    }
  }

  void _select(MagpieSection section) {
    if (section != _section) {
      setState(() {
        _section = section;
        _visited.add(section);
      });
      if (context.reduceMotion) {
        _transition.value = 1;
      } else {
        _transition.forward(from: 0);
      }
    } else {
      (_bottomNavigation.currentState ?? _sidebarNavigation.currentState)
          ?._revealSelection();
    }
    if (_drawerOpen) _closeSidebar(false);
  }

  void _openSettings() {
    if (_drawerOpen) _closeSidebar(false);
    Navigator.of(context).push(
      MagpiePageRoute<void>(context, builder: (_) => const SettingsPage()),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) _transition.value = 1;
  }

  @override
  void dispose() {
    _transition.dispose();
    _toggleFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AppCanvas(
    child: Scaffold(
      key: const ValueKey('magpie-app-shell'),
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= _wideBreakpoint;
            // Drawer visibility is temporary. Entering a wide layout discards
            // it without changing the remembered docked-sidebar preference.
            if ((wide && _drawerOpen) ||
                (!wide && _wasWide == true && _wideSidebarOpen)) {
              _drawerOpen = false;
              _restoreToggleFocus();
            }
            _wasWide = wide;
            final sidebarOpen = wide ? _wideSidebarOpen : _drawerOpen;
            return PopScope<Object?>(
              canPop: !sidebarOpen,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop && sidebarOpen) _closeSidebar(wide);
              },
              child: CallbackShortcuts(
                bindings: {
                  if (sidebarOpen)
                    const SingleActivator(LogicalKeyboardKey.escape): () =>
                        _closeSidebar(wide),
                },
                child: Column(
                  children: [
                    _TopBar(
                      section: _section,
                      sidebarOpen: sidebarOpen,
                      toggleFocus: _toggleFocus,
                      onToggle: () => _toggleSidebar(wide),
                      onSettings: _openSettings,
                    ),
                    Expanded(
                      child: Stack(
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: wide && sidebarOpen ? _sidebarWidth : 0,
                                child: wide && sidebarOpen
                                    ? _Sidebar(
                                        section: _section,
                                        onSelect: _select,
                                        navigationKey: _sidebarNavigation,
                                      )
                                    : null,
                              ),
                              Expanded(
                                child: ExcludeSemantics(
                                  excluding: _drawerOpen,
                                  child: ExcludeFocus(
                                    excluding: _drawerOpen,
                                    child: _pageStack(),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_drawerOpen) ...[
                            Positioned.fill(
                              child: ModalBarrier(
                                key: const ValueKey('sidebar-scrim'),
                                color: context.magpie.modalScrim,
                                semanticsLabel: context.l10n.closeSidebar,
                                onDismiss: () => _closeSidebar(false),
                              ),
                            ),
                            PositionedDirectional(
                              start: 0,
                              top: 0,
                              bottom: 0,
                              width: math.min(
                                _drawerMaxWidth,
                                math.max(0.0, constraints.maxWidth - 48),
                              ),
                              child: _Sidebar(
                                section: _section,
                                onSelect: _select,
                                navigationKey: _sidebarNavigation,
                                autofocus: true,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if (!wide)
                      ExcludeFocus(
                        excluding: _drawerOpen,
                        child: ExcludeSemantics(
                          excluding: _drawerOpen,
                          child: IgnorePointer(
                            ignoring: _drawerOpen,
                            child: _mobileBottomNavigation(),
                          ),
                        ),
                      )
                    else if (!sidebarOpen)
                      _SectionNav(
                        section: _section,
                        onSelect: _select,
                        horizontal: true,
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    ),
  );

  Widget _mobileBottomNavigation() => Material(
    key: const ValueKey('mobile-bottom-navigation'),
    color: context.magpie.paper,
    child: DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: context.magpie.line)),
      ),
      child: SizedBox(
        height: MagpieMetrics.tabBarHeight,
        child: _SectionNav(
          key: _bottomNavigation,
          section: _section,
          onSelect: _select,
          horizontal: true,
          bottom: true,
          sections: _bottomSections,
        ),
      ),
    ),
  );

  Widget _pageStack() => AnimatedBuilder(
    animation: _transition,
    child: IndexedStack(
      index: _section.index,
      sizing: StackFit.expand,
      children: [
        for (final section in MagpieSection.values)
          TickerMode(
            enabled: _section == section,
            child: ExcludeFocus(
              excluding: _section != section,
              child: PrimaryScrollController.none(
                child: _visited.contains(section)
                    ? _pageFor(section)
                    : const SizedBox.shrink(),
              ),
            ),
          ),
      ],
    ),
    builder: (context, child) {
      final progress = MagpieMotion.curveFor(
        context,
      ).transform(_transition.value);
      return Transform.translate(
        key: const ValueKey('tab-transition'),
        offset: Offset(0, 6 * (1 - progress)),
        child: Opacity(
          opacity: 0.70 + 0.30 * progress,
          alwaysIncludeSemantics: true,
          child: child,
        ),
      );
    },
  );

  Widget _pageFor(MagpieSection section) => switch (section) {
    MagpieSection.agents => const AgentsPage(),
    MagpieSection.resources => const ResourcesPage(),
    MagpieSection.providers => const ProvidersPage(),
    MagpieSection.gateway => const GatewayPage(),
    _ => _UnavailableSectionPage(section: section),
  };
}

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.section,
    required this.sidebarOpen,
    required this.toggleFocus,
    required this.onToggle,
    required this.onSettings,
  });

  final MagpieSection section;
  final bool sidebarOpen;
  final FocusNode toggleFocus;
  final VoidCallback onToggle;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    final colors = context.magpie;
    final l10n = context.l10n;
    return Material(
      color: colors.paper,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: colors.line)),
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(4, 4, 4, 5),
          child: Row(
            children: [
              Semantics(
                expanded: sidebarOpen,
                child: IconButton(
                  key: const ValueKey('sidebar-toggle'),
                  focusNode: toggleFocus,
                  tooltip: sidebarOpen ? l10n.hideSidebar : l10n.showSidebar,
                  onPressed: onToggle,
                  icon: MagpieIcon(
                    sidebarOpen
                        ? MagpieGlyph.sidebarOpen
                        : MagpieGlyph.sidebarClosed,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Row(
                    children: [
                      MagpieIcon(
                        MagpieGlyph.magpie,
                        size: 19,
                        color: colors.ink,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'magpie  /  ${l10n.navigationLabel(section)}',
                          style: Theme.of(context).textTheme.titleSmall,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                key: const ValueKey('open-settings-button'),
                tooltip: l10n.settingsTool,
                onPressed: onSettings,
                icon: const MagpieIcon(MagpieGlyph.settings),
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({
    required this.section,
    required this.onSelect,
    required this.navigationKey,
    this.autofocus = false,
  });

  final MagpieSection section;
  final ValueChanged<MagpieSection> onSelect;
  final GlobalKey<_SectionNavState> navigationKey;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    final colors = context.magpie;
    return Material(
      key: const ValueKey('section-sidebar'),
      color: colors.paper,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: BorderDirectional(end: BorderSide(color: colors.line)),
        ),
        child: _SectionNav(
          key: navigationKey,
          section: section,
          onSelect: onSelect,
          horizontal: false,
          autofocus: autofocus,
        ),
      ),
    );
  }
}

class _NavigationGroup {
  const _NavigationGroup(this.label, this.sections);

  final String Function(MagpieL10n) label;
  final List<MagpieSection> sections;
}

final _navigationGroups = [
  _NavigationGroup((l10n) => l10n.text('使用', 'Work'), const [
    MagpieSection.agents,
    MagpieSection.sessions,
    MagpieSection.resources,
    MagpieSection.artifacts,
  ]),
  _NavigationGroup((l10n) => l10n.text('模型', 'Models'), const [
    MagpieSection.providers,
    MagpieSection.routing,
    MagpieSection.routingGroups,
    MagpieSection.gateway,
  ]),
  _NavigationGroup((l10n) => l10n.text('观测', 'Insights'), const [
    MagpieSection.usage,
    MagpieSection.redaction,
  ]),
  _NavigationGroup((l10n) => l10n.text('扩展', 'Extend'), const [
    MagpieSection.plugins,
  ]),
];

class _SectionNav extends StatefulWidget {
  const _SectionNav({
    required this.section,
    required this.onSelect,
    required this.horizontal,
    this.autofocus = false,
    this.bottom = false,
    this.sections,
    super.key,
  });

  final MagpieSection section;
  final ValueChanged<MagpieSection> onSelect;
  final bool horizontal;
  final bool autofocus;
  final bool bottom;
  final List<MagpieSection>? sections;

  @override
  State<_SectionNav> createState() => _SectionNavState();
}

class _SectionNavState extends State<_SectionNav> {
  final _viewport = GlobalKey();
  final _buttons = {
    for (final section in MagpieSection.values) section: GlobalKey(),
  };
  (MagpieSection, Locale, TextScaler, BoxConstraints)? _layout;

  void _revealSelection() {
    final target = _buttons[widget.section]?.currentContext;
    final button = target?.findRenderObject() as RenderBox?;
    final viewport = _viewport.currentContext?.findRenderObject() as RenderBox?;
    if (target == null || button == null || viewport == null) return;
    final topLeft = button.localToGlobal(Offset.zero, ancestor: viewport);
    final Axis axis = widget.horizontal ? Axis.horizontal : Axis.vertical;
    final (start, end, extent) = axis == Axis.horizontal
        ? (topLeft.dx, topLeft.dx + button.size.width, viewport.size.width)
        : (topLeft.dy, topLeft.dy + button.size.height, viewport.size.height);
    if (start >= 0 && end <= extent) return;
    Scrollable.ensureVisible(
      target,
      alignment: 0.5,
      duration: MagpieMotion.duration(context, MagpieMotion.selection),
      curve: MagpieMotion.curveFor(context),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scaler = MediaQuery.textScalerOf(context);
    final horizontal = widget.horizontal;
    return LayoutBuilder(
      builder: (context, constraints) {
        final layout = (widget.section, l10n.locale, scaler, constraints);
        if (_layout != layout) {
          _layout = layout;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted && _layout == layout) _revealSelection();
          });
        }
        if (widget.bottom) {
          return Row(
            children: [
              for (final section in widget.sections!)
                Expanded(child: _buildBottomButton(context, section)),
            ],
          );
        }
        final buttons = [
          for (final group in _navigationGroups) ...[
            if (!horizontal) _buildGroupLabel(context, group),
            for (final section in group.sections)
              _buildButton(context, section),
          ],
        ];
        return SingleChildScrollView(
          key: _viewport,
          primary: false,
          scrollDirection: horizontal ? Axis.horizontal : Axis.vertical,
          padding: horizontal
              ? const EdgeInsets.symmetric(horizontal: 2)
              : const EdgeInsetsDirectional.fromSTEB(8, 8, 9, 8),
          child: horizontal
              ? Row(spacing: 2, children: buttons)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  spacing: 2,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
                      child: Semantics(
                        header: true,
                        child: Text(
                          l10n.navigationTitle,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ),
                    const Divider(height: 1),
                    ...buttons,
                  ],
                ),
        );
      },
    );
  }

  Widget _buildButton(BuildContext context, MagpieSection section) {
    final selected = section == widget.section;
    final horizontal = widget.horizontal;
    final colors = context.magpie;
    final style = TextButton.styleFrom(
      alignment: horizontal
          ? Alignment.center
          : AlignmentDirectional.centerStart,
      foregroundColor: selected ? colors.ink : colors.muted,
      backgroundColor: selected ? context.tokens.sel : Colors.transparent,
      minimumSize: const Size(44, 44),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
      side: BorderSide(
        color: selected ? colors.lineStrong : Colors.transparent,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      animationDuration: MagpieMotion.duration(context, MagpieMotion.feedback),
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
    final label = Text(context.l10n.navigationLabel(section));
    final key = ValueKey('${horizontal ? 'nav' : 'sidebar'}-${section.name}');
    void onPressed() => widget.onSelect(section);
    return Semantics(
      key: _buttons[section],
      selected: selected,
      child: horizontal && !widget.bottom
          ? TextButton(
              key: key,
              onPressed: onPressed,
              style: style,
              child: label,
            )
          : TextButton.icon(
              key: key,
              autofocus: widget.autofocus && selected,
              onPressed: onPressed,
              style: style,
              icon: MagpieIcon(_glyphFor(section), size: 18),
              label: label,
            ),
    );
  }

  Widget _buildBottomButton(BuildContext context, MagpieSection section) {
    final selected = section == widget.section;
    final t = context.tokens;
    final label = context.l10n.navigationLabel(section);
    return Semantics(
      selected: selected,
      label: label,
      child: InkWell(
        key: ValueKey('nav-${section.name}'),
        onTap: () => widget.onSelect(section),
        child: ExcludeSemantics(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MagpieIcon(
                  _glyphFor(section),
                  size: MagpieMetrics.webIcon,
                  color: selected ? t.accent : t.ctlFg,
                ),
                const SizedBox(height: 2),
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: MagpieType.tabLabel,
                      color: selected ? t.fg : t.ctlFg,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupLabel(BuildContext context, _NavigationGroup group) {
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(12, 10, 12, 4),
      child: Semantics(
        header: true,
        child: Text(
          group.label(context.l10n),
          style: Theme.of(context).textTheme.labelMedium,
        ),
      ),
    );
  }

  MagpieGlyph _glyphFor(MagpieSection section) => switch (section) {
    MagpieSection.agents => MagpieGlyph.agents,
    MagpieSection.sessions => MagpieGlyph.sessions,
    MagpieSection.resources => MagpieGlyph.library,
    MagpieSection.artifacts => MagpieGlyph.artifacts,
    MagpieSection.providers => MagpieGlyph.providers,
    MagpieSection.routing => MagpieGlyph.routing,
    MagpieSection.routingGroups => MagpieGlyph.routingGroups,
    MagpieSection.gateway => MagpieGlyph.gateway,
    MagpieSection.usage => MagpieGlyph.usage,
    MagpieSection.redaction => MagpieGlyph.masking,
    MagpieSection.plugins => MagpieGlyph.plugins,
  };
}

class _UnavailableSectionPage extends StatelessWidget {
  const _UnavailableSectionPage({required this.section});

  final MagpieSection section;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return SingleChildScrollView(
      key: ValueKey('unavailable-${section.name}'),
      padding: pagePadding,
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Semantics(
                header: true,
                child: Text(
                  l10n.navigationLabel(section),
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              const SizedBox(height: 12),
              SurfaceCard(
                radius: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.notImplemented,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(l10n.sectionUnavailable(section)!),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

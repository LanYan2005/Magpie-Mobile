import 'package:flutter/material.dart';

import 'magpie_theme.dart';

abstract final class MagpieMotion {
  static const feedback = Duration(milliseconds: 100);
  static const selection = Duration(milliseconds: 180);
  static const tab = Duration(milliseconds: 160);
  static const route = Duration(milliseconds: 260);
  static const routeBack = Duration(milliseconds: 210);
  static const pageEntrance = Duration(milliseconds: 240);
  static const curve = Curves.easeOutCubic;

  static Curve curveFor(BuildContext context) =>
      context.reduceMotion ? Curves.linear : curve;

  static Duration duration(BuildContext context, Duration duration) =>
      context.reduceMotion ? Duration.zero : duration;

  static AnimationStyle overlays(BuildContext context) => context.reduceMotion
      ? AnimationStyle.noAnimation
      : const AnimationStyle(
          duration: Duration(milliseconds: 240),
          reverseDuration: Duration(milliseconds: 200),
        );
}

/// Retains Flutter's platform route behavior (including iOS swipe back) in
/// normal motion, and removes the route transition when reduced motion is set.
class MagpiePageRoute<T> extends MaterialPageRoute<T> {
  MagpiePageRoute(BuildContext context, {required super.builder})
    : _initialReduceMotion = context.reduceMotion;

  final bool _initialReduceMotion;

  bool get _instant {
    final currentContext = navigator?.context;
    return currentContext == null
        ? _initialReduceMotion
        : MediaQuery.maybeDisableAnimationsOf(currentContext) ??
              _initialReduceMotion;
  }

  @override
  Duration get transitionDuration =>
      _instant ? Duration.zero : MagpieMotion.route;

  @override
  Duration get reverseTransitionDuration =>
      _instant ? Duration.zero : MagpieMotion.routeBack;

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (_instant || context.reduceMotion) return child;
    return super.buildTransitions(
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

/// Compact Android motion with no extra dependency.
class MagpieAndroidPageTransitionsBuilder extends PageTransitionsBuilder {
  const MagpieAndroidPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (context.reduceMotion) return child;
    final slide = Tween<Offset>(
      begin: const Offset(0, 0.018),
      end: Offset.zero,
    ).chain(CurveTween(curve: MagpieMotion.curve));
    return FadeTransition(
      opacity: CurvedAnimation(
        parent: animation,
        curve: const Interval(0, 0.78, curve: Curves.easeOut),
      ),
      child: SlideTransition(position: animation.drive(slide), child: child),
    );
  }
}

/// Retains Flutter's interactive native iOS edge-swipe transition.
class MagpieCupertinoPageTransitionsBuilder extends PageTransitionsBuilder {
  const MagpieCupertinoPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    // Keep Cupertino's edge-swipe recognizer even when entrance animation is
    // disabled; the route's controller still follows the user's gesture.
    return CupertinoPageTransitionsBuilder().buildTransitions(
      route,
      context,
      animation,
      secondaryAnimation,
      child,
    );
  }
}

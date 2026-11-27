import 'package:flutter/material.dart';

import 'gateway_page.dart';

/// Former overview entry point, backed by the same live gateway page.
class OverviewPage extends StatelessWidget {
  const OverviewPage({required this.onNavigate, super.key});

  final ValueChanged<int> onNavigate;

  @override
  Widget build(BuildContext context) => const GatewayPage();
}

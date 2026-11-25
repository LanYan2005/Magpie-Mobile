import 'package:flutter/widgets.dart';

import 'gateway_controller.dart';

class GatewayScope extends InheritedNotifier<GatewayController> {
  const GatewayScope({
    required GatewayController controller,
    required super.child,
    super.key,
  }) : super(notifier: controller);

  static GatewayController of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<GatewayScope>()!.notifier!;
}

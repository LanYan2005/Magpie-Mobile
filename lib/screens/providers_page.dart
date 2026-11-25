import 'package:flutter/material.dart';

import '../core/magpie_l10n.dart';
import '../widgets/primitives.dart';
import 'gateway_routes_page.dart';

class ProvidersPage extends StatelessWidget {
  const ProvidersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: SingleChildScrollView(
        padding: dockPagePadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeader(
                  title: context.tr('供应商', 'Providers'),
                  subtitle: context.tr(
                    '配置本机网关实际转发的上游。五种协议各支持一个上游，不支持多账号或跨协议转发。',
                    'Configure the upstreams used by the local gateway. Each of the five protocols supports one upstream, with no multi-account support or cross-protocol forwarding.',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  context.tr(
                    '停止网关后可编辑。未配置的协议不会回退到其他上游。',
                    'Stop the gateway to edit. Unconfigured protocols do not fall back to another upstream.',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 16),
                const GatewayRouteList(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

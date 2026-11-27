import 'package:flutter/material.dart';

import '../core/magpie_l10n.dart';
import '../core/magpie_motion.dart';
import '../core/magpie_tokens.dart';
import '../gateway/gateway_controller.dart';
import '../gateway/gateway_scope.dart';
import '../state/app_language.dart';
import '../state/magpie_store.dart';
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _part = 0;

  Future<void> _resetDemoData() async {
    final confirmed = await showDialog<bool>(
      context: context,
      animationStyle: MagpieMotion.overlays(context),
      builder: (dialogContext) => AlertDialog(
        title: Text(dialogContext.tr('重置演示数据？', 'Reset demo data?')),
        content: Text(
          dialogContext.tr(
            '会恢复 Agent、Skill、MCP 和内部供应商示例的初始数据，不影响网关上游配置。',
            'This restores the initial Agent, Skill, MCP, and internal provider examples. Gateway upstream settings are not affected.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(dialogContext.tr('取消', 'Cancel')),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(dialogContext.tr('重置', 'Reset')),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    MagpieScope.of(context).resetDemoData();
    showDemoToast(context, context.tr('演示数据已恢复为初始示例', 'Demo data restored.'));
  }

  @override
  Widget build(BuildContext context) {
    final t = context.tr;
    final tokens = context.tokens;
    final parts = [
      t('通用', 'General'),
      t('用量', 'Usage'),
      t('网络', 'Network'),
      t('模型', 'Models'),
      t('隐私', 'Privacy'),
      t('插件', 'Plugins'),
      t('关于', 'About'),
    ];
    return Scaffold(
      backgroundColor: tokens.bg,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        tooltip: t('返回', 'Back'),
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back_rounded, size: 19),
                        constraints: const BoxConstraints(
                          minWidth: MagpieMetrics.touchTarget,
                          minHeight: MagpieMetrics.touchTarget,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            t('设置', 'Settings'),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: tokens.fg,
                            ),
                          ),
                        ),
                      ),
                      MagpieBadge(label: t('移动端', 'Mobile')),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Wrap(
                    spacing: 2,
                    runSpacing: 2,
                    children: [
                      for (var i = 0; i < parts.length; i++)
                        Semantics(
                          selected: _part == i,
                          child: TextButton(
                            key: ValueKey('settings-part-$i'),
                            onPressed: () => setState(() => _part = i),
                            style: TextButton.styleFrom(
                              foregroundColor: _part == i
                                  ? tokens.fg
                                  : tokens.ctlFg,
                              backgroundColor: _part == i
                                  ? tokens.pill
                                  : Colors.transparent,
                              minimumSize: const Size(44, 44),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  MagpieMetrics.fieldRadius,
                                ),
                              ),
                              textStyle: const TextStyle(
                                fontSize: MagpieType.sectionLabel,
                                fontWeight: FontWeight.w600,
                                letterSpacing: .5,
                              ),
                            ),
                            child: Text(parts[i].toUpperCase()),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: SingleChildScrollView(
                    key: PageStorageKey('settings-part-$_part-scroll'),
                    padding: pagePadding,
                    child: _content(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _content(BuildContext context) {
    final t = context.tr;
    return switch (_part) {
      0 => _general(context),
      1 => _SettingsGroup(
        title: t('用量记录', 'Usage records'),
        children: [
          _SettingsRow(
            icon: Icons.bar_chart_rounded,
            title: t('请求、Token 与费用', 'Requests, tokens and cost'),
            detail: t(
              '当前本机网关尚未采集用量与调用历史，暂无统计数据。',
              'The local gateway does not collect usage or call history yet. No statistics are available.',
            ),
            status: t('未接入', 'Not connected'),
          ),
        ],
      ),
      2 => _network(context),
      3 => _models(context),
      4 => _privacy(context),
      5 => _SettingsGroup(
        title: t('插件运行时', 'Plugin runtime'),
        children: [
          _SettingsRow(
            icon: Icons.extension_outlined,
            title: t('桌面插件', 'Desktop plugins'),
            detail: t(
              '移动端尚未接入原版 Go 核心与插件运行时。Skills 与 MCP 目前仅管理配置和演示导出。',
              'The upstream Go core and plugin runtime are not connected on mobile. Skills and MCP currently manage settings and demo exports only.',
            ),
            status: t('未接入', 'Not connected'),
          ),
        ],
      ),
      _ => _about(context),
    };
  }

  Widget _general(BuildContext context) {
    final t = context.tr;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsGroup(
          title: t('语言 / Language', 'Language / 语言'),
          children: const [_LanguageSelector()],
        ),
        _SettingsGroup(
          title: t('平台支持', 'Platform support'),
          children: [
            _SettingsRow(
              icon: Icons.devices_outlined,
              title: t(
                'Android + iOS\n共用界面',
                'Shared interface\nfor Android + iOS',
              ),
              detail: t(
                '共用 Flutter 界面，基础安全区与系统返回使用 Flutter 默认行为。',
                'Shared Flutter interface with basic safe areas and default Flutter back navigation.',
              ),
            ),
            _SettingsRow(
              icon: Icons.info_outline_rounded,
              title: t('平台适配尚未接入', 'Platform integrations are not connected'),
              detail: t(
                '系统级导航适配、后台任务与文件选择仍待接入。网关仅在当前应用进程内运行。',
                'Platform-specific navigation, background tasks and file selection are pending. The gateway runs in the current app process.',
              ),
              status: t('部分', 'Partial'),
            ),
          ],
        ),
        _platformChecklist(context),
        _SettingsGroup(
          title: t('演示数据', 'Demo data'),
          children: [
            _SettingsRow(
              icon: Icons.restart_alt_rounded,
              title: t('重置演示数据', 'Reset demo data'),
              detail: t(
                '恢复当前会话中的示例，保留网关上游配置。',
                'Restore session examples and keep gateway upstream settings.',
              ),
              onTap: () => _resetDemoData(),
            ),
          ],
        ),
      ],
    );
  }

  Widget _platformChecklist(BuildContext context) {
    final t = context.tr;
    return _SettingsGroup(
      title: t('平台适配清单', 'Platform integration checklist'),
      children: [
        _SettingsRow(
          icon: Icons.android_rounded,
          title: t(
            'Android 边到边与返回手势',
            'Android edge-to-edge and back gestures',
          ),
          detail: t(
            '目前使用 SafeArea 与 Flutter 默认行为，专门的平台适配待实现。',
            'Uses SafeArea and Flutter defaults. Dedicated platform integration is pending.',
          ),
          status: t('待接入', 'Pending'),
        ),
        _SettingsRow(
          icon: Icons.phone_iphone_rounded,
          title: t('iOS 安全区与导航手势', 'iOS safe areas and navigation gestures'),
          detail: t(
            '基础安全区已支持，深度导航适配待实现。',
            'Basic safe areas are supported. Deeper navigation integration is pending.',
          ),
          status: t('部分', 'Partial'),
        ),
        _SettingsRow(
          icon: Icons.sync_outlined,
          title: t('后台任务与本地端口', 'Background tasks and local ports'),
          detail: t(
            '本机网关绑定回环地址，后台持续运行与 Termux 桥接尚未接入。stdio MCP 仅保存配置。',
            'The gateway binds to loopback. Background execution and the Termux bridge are pending. stdio MCP only saves settings.',
          ),
          status: t('部分', 'Partial'),
        ),
        _SettingsRow(
          icon: Icons.folder_open_outlined,
          title: t('文件选择与资源导出', 'File selection and resource export'),
          detail: t(
            'Skills / MCP 仅管理配置与演示导出，不读写其他 App 私有目录。',
            'Skills / MCP manage settings and demo exports only, without accessing other apps’ private folders.',
          ),
          status: t('演示', 'Demo'),
        ),
        _SettingsRow(
          icon: Icons.vpn_key_outlined,
          title: 'Keychain / Keystore',
          detail: t(
            '上游密钥已通过系统安全存储接入，读取或写入失败会由控制器报告。',
            'Upstream keys use system secure storage. The controller reports read or write failures.',
          ),
          status: t('已接入', 'Connected'),
        ),
      ],
    );
  }

  Widget _network(BuildContext context) {
    final t = context.tr;
    final gateway = GatewayScope.of(context);
    return _SettingsGroup(
      title: t('本机网络', 'Local network'),
      children: [
        _SettingsRow(
          icon: Icons.hub_outlined,
          title: t('监听地址', 'Listener address'),
          detail: 'http://${gateway.address}',
          status: gateway.state == GatewayState.running
              ? t('运行中', 'Running')
              : t('未运行', 'Not running'),
        ),
        _SettingsRow(
          icon: Icons.route_outlined,
          title: t('上游转发', 'Upstream forwarding'),
          detail: t(
            '仅已启动的本机网关会按协议转发至已保存的上游。请在网关栏目启停服务。',
            'Only the running gateway forwards requests to saved protocol upstreams. Start or stop the listener in Gateway.',
          ),
        ),
        _SettingsRow(
          icon: Icons.lan_outlined,
          title: t('局域网共享', 'LAN sharing'),
          detail: t(
            '当前仅监听 127.0.0.1，尚未接入局域网共享。',
            'Currently listens on 127.0.0.1 only. LAN sharing is not implemented.',
          ),
          status: t('未接入', 'Not connected'),
        ),
      ],
    );
  }

  Widget _models(BuildContext context) {
    final t = context.tr;
    final gateway = GatewayScope.of(context);
    return _SettingsGroup(
      title: t('模型与协议', 'Models and protocols'),
      children: [
        _SettingsRow(
          icon: Icons.route_outlined,
          title: t('协议路由', 'Protocol routes'),
          detail: t(
            '${gateway.configuredCount}/5 种协议路由已配置 · ${gateway.readyCount} 条就绪。请在供应商和路由栏目管理。',
            '${gateway.configuredCount}/5 protocol routes configured · ${gateway.readyCount} ready. Manage these in Providers and Routing.',
          ),
        ),
        _SettingsRow(
          icon: Icons.swap_horiz_rounded,
          title: t('跨协议转换与账号池', 'Protocol conversion and account pools'),
          detail: t(
            '移动端按所选协议转发，跨协议转换与账号池调度尚未接入。',
            'Mobile forwards using the selected protocol. Cross-protocol conversion and account pool scheduling are not connected.',
          ),
          status: t('未接入', 'Not connected'),
        ),
      ],
    );
  }

  Widget _privacy(BuildContext context) {
    final t = context.tr;
    return _SettingsGroup(
      title: t('凭据与数据', 'Credentials and data'),
      children: [
        _SettingsRow(
          icon: Icons.vpn_key_outlined,
          title: t('上游密钥', 'Upstream keys'),
          detail: t(
            '密钥通过 Keychain / Keystore 保存，供应商配置仅保存凭据引用。',
            'Keys are saved through Keychain / Keystore. Provider settings store credential references only.',
          ),
        ),
        _SettingsRow(
          icon: Icons.key_outlined,
          title: t('本机客户端密钥', 'Local client key'),
          detail: t(
            '每次启动网关生成新密钥，仅保留在当前进程内存。',
            'A new client key is generated on each gateway start and kept in process memory.',
          ),
        ),
        _SettingsRow(
          icon: Icons.shield_outlined,
          title: t('请求脱敏', 'Request redaction'),
          detail: t(
            '本机网关尚未实现请求脱敏。',
            'Request redaction is not implemented in the local gateway yet.',
          ),
          status: t('未接入', 'Not connected'),
        ),
        _SettingsRow(
          icon: Icons.folder_off_outlined,
          title: t(
            '查看 Termux 与 iOS 沙箱边界',
            'View Termux and iOS sandbox boundaries',
          ),
          detail: t(
            '查看本地资源管理与平台权限的支持范围。',
            'Review local resource management and platform permission support.',
          ),
          onTap: () => showSandboxSheet(context),
        ),
      ],
    );
  }

  Widget _about(BuildContext context) {
    final t = context.tr;
    final store = MagpieScope.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SettingsGroup(
          title: 'Magpie Mobile',
          children: [
            _SettingsRow(
              icon: Icons.flutter_dash_rounded,
              title: t(
                'Magpie · 移动端原型 0.1.0',
                'Magpie · Mobile prototype 0.1.0',
              ),
              detail: t(
                'Android + iOS 共用 Flutter 界面，本机网关运行于应用进程。',
                'Shared Flutter interface for Android and iOS, with an in-process local gateway.',
              ),
            ),
            _SettingsRow(
              icon: Icons.cloud_off_outlined,
              title: t('Magpie 服务连接', 'Magpie service connection'),
              detail: t(
                '原版 Go 核心、远程账号和配置同步尚未接入。',
                'The upstream Go core, remote accounts and configuration sync are not connected.',
              ),
              status: t('未接入', 'Not connected'),
            ),
            _SettingsRow(
              icon: Icons.storage_outlined,
              title: t('本地示例数据', 'Local example data'),
              detail: t(
                '${store.agents.length} Agent · ${store.skills.length} Skill · ${store.mcpServers.length} MCP，仅保存在当前会话。',
                '${store.agents.length} Agents · ${store.skills.length} Skills · ${store.mcpServers.length} MCP, kept in this session only.',
              ),
              status: t('演示', 'Demo'),
            ),
          ],
        ),
        _platformChecklist(context),
      ],
    );
  }
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector();

  @override
  Widget build(BuildContext context) {
    final language = AppLanguageScope.of(context);
    final tokens = context.tokens;
    final english = context.l10n.isEnglish;
    return Padding(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          for (final (code, label, selected) in [
            ('zh', '简体中文', !english),
            ('en', 'English', english),
          ])
            Expanded(
              child: Semantics(
                selected: selected,
                child: TextButton(
                  key: ValueKey('language-$code'),
                  onPressed: () => language.select(Locale(code)),
                  style: TextButton.styleFrom(
                    minimumSize: const Size(44, 44),
                    backgroundColor: selected ? tokens.sel : Colors.transparent,
                    foregroundColor: selected ? tokens.accent : tokens.ctlFg,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        MagpieMetrics.fieldRadius,
                      ),
                    ),
                    textStyle: const TextStyle(
                      fontSize: MagpieType.field,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  child: Text(label),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(2, 4, 2, 6),
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: TextStyle(
                color: context.tokens.ctlFg,
                fontSize: MagpieType.sectionLabel,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        MagpieList(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0)
                Divider(height: 1, thickness: 1, color: context.tokens.line2),
              children[i],
            ],
          ],
        ),
      ],
    ),
  );
}

/// Platform and privacy explanations stay readable at narrow widths and large
/// text sizes, while using the same spacing and type ramp as upstream rows.
class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    required this.detail,
    this.status,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final String? status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: MagpieMetrics.touchTarget,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Icon(icon, size: 17, color: tokens.ctlFg),
                ),
                const SizedBox(width: MagpieMetrics.rowGap),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              color: tokens.fg,
                              fontSize: MagpieType.rowName,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (status != null) MagpieBadge(label: status!),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        detail,
                        style: TextStyle(
                          color: tokens.fg2,
                          fontSize: MagpieType.rowSub,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
                if (onTap != null) ...[
                  const SizedBox(width: 5),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 17,
                    color: tokens.muted,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

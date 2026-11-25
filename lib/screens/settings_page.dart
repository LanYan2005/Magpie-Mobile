import 'package:flutter/material.dart';

import '../core/magpie_l10n.dart';
import '../core/magpie_motion.dart';
import '../core/magpie_theme.dart';
import '../state/app_language.dart';
import '../state/magpie_store.dart';
import '../widgets/app_canvas.dart';
import '../widgets/primitives.dart';
import '../widgets/sheets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  Future<void> _resetDemoData(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      animationStyle: MagpieMotion.overlays(context),
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(dialogContext.tr('重置演示数据？', 'Reset demo data?')),
          content: Text(
            dialogContext.tr(
              '会恢复 Agent、Skill、MCP 和内部供应商示例的初始数据，不影响网关上游配置。',
              'This restores the initial Agent, Skill, MCP, and internal provider examples. Gateway upstream settings are not affected.'
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
        );
      },
    );
    if (confirmed != true || !context.mounted) return;
    MagpieScope.of(context).resetDemoData();
    showDemoToast(context, context.tr('演示数据已恢复为初始示例', 'Demo data restored.'));
  }

  @override
  Widget build(BuildContext context) {
    final store = MagpieScope.of(context);
    final t = context.tr;
    return AppCanvas(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: pagePadding,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    PageTopBar(
                      title: t('设置', 'Settings'),
                      onBack: () => Navigator.of(context).pop(),
                      trailing: DemoBadge(label: t('UI 原型', 'UI Prototype')),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      t('语言 / Language', 'Language / 语言'),
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    _LanguageSelector(language: AppLanguageScope.of(context)),
                    const SizedBox(height: 14),
                    _PlatformHero(),
                    const SizedBox(height: 14),
                    InfoBanner(
                      icon: Icons.phone_iphone_rounded,
                      title: t(
                        '平台适配尚未接入',
                        'Platform integrations are not connected',
                      ),
                      body: t(
                        '当前是 Android + iOS 共用的一套 Flutter 界面。系统返回手势、边到边布局、后台任务、文件选择与安全存储均未做平台实现。',
                        'This shared Flutter interface runs on Android and iOS. Platform-specific back gestures, edge-to-edge layout, background tasks, file selection, and secure storage are not implemented.',
                      ),
                      tint: context.magpie.amberSoft,
                      accent: context.magpie.amber,
                    ),
                    const SizedBox(height: 22),
                    SectionHeader(
                      title: t('原型状态', 'Prototype status'),
                      subtitle: t(
                        '所有值均来自本地演示',
                        'All values come from local demo data',
                      ),
                    ),
                    const SizedBox(height: 10),
                    SurfaceCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 4,
                      ),
                      child: Column(
                        children: [
                          _SettingRow(
                            icon: Icons.cloud_off_outlined,
                            title: t(
                              'Magpie 服务连接',
                              'Magpie service connection',
                            ),
                            subtitle: t(
                              '原版 Go 核心、账号和远程配置尚未接入',
                              'Upstream Go core, accounts and remote settings are not connected',
                            ),
                            trailing: _tag(
                              context,
                              t('未接入', 'Not connected'),
                              context.magpie.muted,
                            ),
                          ),
                          const SoftDivider(),
                          _SettingRow(
                            icon: Icons.storage_outlined,
                            title: t('数据来源', 'Data source'),
                            subtitle: t(
                              '${store.providers.length} 供应商 · ${store.agents.length} Agent · ${store.skills.length} Skill · ${store.mcpServers.length} MCP',
                              '${store.providers.length} providers · ${store.agents.length} Agents · ${store.skills.length} Skills · ${store.mcpServers.length} MCP',
                            ),
                            trailing: _tag(
                              context,
                              t('本地内存', 'Local memory'),
                              context.magpie.jade,
                              background: context.magpie.mintSoft,
                            ),
                          ),
                          const SoftDivider(),
                          _SettingRow(
                            icon: Icons.wifi_off_rounded,
                            title: t('网络请求', 'Network requests'),
                            subtitle: t(
                              '仅已启动的本机网关会按协议转发至该协议保存的上游',
                              'Only the running local gateway forwards requests to the upstream saved for that protocol',
                            ),
                            trailing: _tag(
                              context,
                              t('按需', 'On demand'),
                              context.magpie.jade,
                              background: context.magpie.mintSoft,
                            ),
                          ),
                          const SoftDivider(),
                          _SettingRow(
                            icon: Icons.lock_outline_rounded,
                            title: t(
                              '凭据与系统权限',
                              'Credentials and system permissions',
                            ),
                            subtitle: t(
                              '网关上游密钥仅保留在进程内存；不申请存储或终端权限',
                              'Gateway upstream keys stay in process memory; no storage or terminal permission is requested',
                            ),
                            trailing: _tag(
                              context,
                              t('未请求', 'Not requested'),
                              context.magpie.jade,
                              background: context.magpie.mintSoft,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SectionHeader(
                      title: t('平台适配清单', 'Platform integration checklist'),
                      subtitle: t(
                        '真实交付前仍需补齐的能力',
                        'Capabilities to complete before production',
                      ),
                    ),
                    const SizedBox(height: 10),
                    SurfaceCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 4,
                      ),
                      child: Column(
                        children: [
                          _SettingRow(
                            icon: Icons.android_rounded,
                            title: t(
                              'Android 边到边与返回手势',
                              'Android edge-to-edge and back gestures',
                            ),
                            subtitle: t(
                              '目前仅使用 SafeArea 与 Flutter 默认行为',
                              'Currently uses SafeArea and Flutter defaults',
                            ),
                            trailing: _tag(
                              context,
                              t('未接入', 'Not connected'),
                              context.magpie.amber,
                              background: context.magpie.amberSoft,
                            ),
                          ),
                          const SoftDivider(),
                          _SettingRow(
                            icon: Icons.phone_iphone_rounded,
                            title: t(
                              'iOS 安全区与导航手势',
                              'iOS safe areas and navigation gestures',
                            ),
                            subtitle: t(
                              '基础安全区已支持，深度适配未接入',
                              'Basic safe areas are supported; deeper integration is pending',
                            ),
                            trailing: _tag(
                              context,
                              t('部分', 'Partial'),
                              context.magpie.amber,
                              background: context.magpie.amberSoft,
                            ),
                          ),
                          const SoftDivider(),
                          _SettingRow(
                            icon: Icons.sync_outlined,
                            title: t(
                              '后台任务与本地端口',
                              'Background tasks and local ports',
                            ),
                            subtitle: t(
                              '不启动 Termux 桥接；stdio MCP 只保存配置',
                              'No Termux bridge is started; stdio MCP settings are only saved',
                            ),
                            trailing: _tag(
                              context,
                              t('未接入', 'Not connected'),
                              context.magpie.muted,
                            ),
                          ),
                          const SoftDivider(),
                          _SettingRow(
                            icon: Icons.folder_open_outlined,
                            title:
                                'Skills / MCP ${t('管理与导出', 'management and export')}',
                            subtitle: t(
                              '仅管理配置与演示导出；不读写其他 App 私有目录',
                              'Manages settings and demo exports only; does not access other apps’ private folders',
                            ),
                            trailing: _tag(
                              context,
                              t('演示', 'Demo'),
                              context.magpie.amber,
                              background: context.magpie.amberSoft,
                            ),
                          ),
                          const SoftDivider(),
                          _SettingRow(
                            icon: Icons.vpn_key_outlined,
                            title: 'Keychain / Keystore',
                            subtitle: t(
                              '真实凭据存储尚未实现',
                              'Secure credential storage is not implemented',
                            ),
                            trailing: _tag(
                              context,
                              t('未接入', 'Not connected'),
                              context.magpie.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SectionHeader(
                      title: t('安全与隐私', 'Security and privacy'),
                      subtitle: t(
                        '本原型刻意不请求高风险能力',
                        'This prototype deliberately avoids sensitive capabilities',
                      ),
                    ),
                    const SizedBox(height: 10),
                    SurfaceCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 4,
                      ),
                      child: Column(
                        children: [
                          _SettingRow(
                            icon: Icons.key_off_outlined,
                            title: t('零凭据', 'No credentials'),
                            subtitle: t(
                              '示例只使用 env: 变量名，不包含真实密钥',
                              'Examples use env: variable names only; no real keys are included',
                            ),
                          ),
                          const SoftDivider(),
                          _SettingRow(
                            icon: Icons.folder_off_outlined,
                            title: t('零文件系统访问', 'No filesystem access'),
                            subtitle: t(
                              '不读取目录、不写入导出文件、不解析 Skill 包，不访问其他 App 的私有目录',
                              'Does not read directories, write export files, parse Skill packages, or access other apps’ private folders',
                            ),
                          ),
                          const SoftDivider(),
                          _SettingRow(
                            icon: Icons.shield_outlined,
                            title: t(
                              '查看 Termux 与 iOS 沙箱边界',
                              'View Termux and iOS sandbox boundaries',
                            ),
                            subtitle: t(
                              '真实接入前需要明确系统限制',
                              'System constraints should be understood before integration',
                            ),
                            onTap: () => showSandboxSheet(context),
                            trailing: Icon(
                              Icons.chevron_right_rounded,
                              size: 19,
                              color: context.magpie.faint,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    SurfaceCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.restart_alt_rounded,
                                size: 19,
                                color: context.magpie.ink,
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  t('演示数据', 'Demo data'),
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            t(
                              '新增内容仅存在于当前会话。重置不会访问磁盘或网络。',
                              'New items exist only in this session. Reset does not access disk or network.',
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _resetDemoData(context),
                              icon: const Icon(
                                Icons.restart_alt_rounded,
                                size: 16,
                              ),
                              label: Text(t('重置演示数据', 'Reset demo data')),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 26),
                    Center(
                      child: Column(
                        children: [
                          const BrandLockup(compact: true),
                          const SizedBox(height: 12),
                          Text(
                            t(
                              'Magpie · UI 原型 0.1.0',
                              'Magpie · UI Prototype 0.1.0',
                            ),
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(fontSize: 10),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            t(
                              'Flutter 3.38 · Android + iOS · 本地演示',
                              'Flutter 3.38 · Android + iOS · Local demo',
                            ),
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  fontSize: 9.5,
                                  color: context.magpie.faint,
                                ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static Widget _tag(
    BuildContext context,
    String label,
    Color color, {
    Color? background,
  }) => TagChip(
    label: label,
    color: color,
    background: background ?? context.magpie.canvas,
    borderColor: context.magpie.line,
  );
}

class _LanguageSelector extends StatelessWidget {
  const _LanguageSelector({required this.language});
  final AppLanguage language;

  @override
  Widget build(BuildContext context) {
    final english = context.l10n.isEnglish;
    return SurfaceCard(
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          Expanded(
            child: _languageButton(
              context,
              'language-zh',
              '简体中文',
              !english,
              () => language.select(const Locale('zh')),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _languageButton(
              context,
              'language-en',
              'English',
              english,
              () => language.select(const Locale('en')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _languageButton(
    BuildContext context,
    String key,
    String label,
    bool selected,
    VoidCallback onPressed,
  ) => Semantics(
    selected: selected,
    child: OutlinedButton(
      key: ValueKey(key),
      onPressed: selected ? null : onPressed,
      child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
    ),
  );
}

class _PlatformHero extends StatelessWidget {
  const _PlatformHero();
  @override
  Widget build(BuildContext context) {
    final t = context.tr;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF171D1B), Color(0xFF172521), Color(0xFF1C3E35)],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF101C19).withValues(alpha: 0.18),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -55,
            bottom: -70,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFD3EDE1).withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(21),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'SHARED SHELL',
                      style: TextStyle(
                        color: const Color(0xFFD3EDE1).withValues(alpha: 0.9),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    DemoBadge(
                      label: t('平台适配未接入', 'Platform integration pending'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  t(
                    'Android + iOS\n共用界面',
                    'Shared interface\nfor Android + iOS',
                  ),
                  style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontSize: 27,
                    height: 1.15,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  t(
                    '一套 Flutter UI 覆盖两端，统一信息架构与交互语言。系统级差异尚未接入。',
                    'One Flutter UI for both platforms, with consistent information architecture and interaction patterns. Platform-specific behavior is not yet integrated.',
                  ),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.58),
                    fontSize: 11.5,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 16),
                const Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _HeroChip(icon: Icons.android_rounded, label: 'Android'),
                    _HeroChip(icon: Icons.phone_iphone_rounded, label: 'iOS'),
                    _HeroChip(
                      icon: Icons.flutter_dash_rounded,
                      label: 'Flutter',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: 0.07),
      borderRadius: BorderRadius.circular(9),
      border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: context.magpie.mint),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 19, color: context.magpie.muted),
        ),
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: context.magpie.ink,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 10.5, height: 1.45),
              ),
            ],
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 9),
          Padding(padding: const EdgeInsets.only(top: 2), child: trailing!),
        ],
      ],
    );
    if (onTap == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: content,
      );
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: content,
      ),
    );
  }
}
